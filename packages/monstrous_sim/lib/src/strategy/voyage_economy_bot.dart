import 'package:monstrous_core/monstrous_core.dart';

import 'bot_strategy.dart';
import 'cautious_bot.dart';
import 'shrine_strategy.dart';

enum VoyagePolicy { conservative, mixed, danger }

/// Audit policies buy through the same core commands as the player.
/// Construct a fresh instance per voyage: shop visits are policy memory only.
class VoyageEconomyBot implements BotStrategy {
  VoyageEconomyBot(this.policy);
  final VoyagePolicy policy;
  final Set<int> _visitedStrongholds = {};
  @override
  String get name => policy.name;
  @override
  Command decideNextAction(GameSession s) {
    final ship = s.ship!;
    if (s.canUseHullPatchOutsideBattle) {
      if (s.phase == SessionPhase.loot || s.phase == SessionPhase.shipwreck) {
        final pendingKit = s.pendingLoot
            .whereType<Consumable>()
            .where((i) => i.type == ConsumableType.hullPatchKit)
            .firstOrNull;
        if (pendingKit != null &&
            ship.maxHp - ship.currentHp >= s.hullPatchHealingHp &&
            s.hullPatchHealingHp > 0) {
          return UseHullPatchKit(pendingKit.id, fromPendingLoot: true);
        }
      }
      final kit = ship.cargo
          .whereType<Consumable>()
          .where((i) => i.type == ConsumableType.hullPatchKit)
          .firstOrNull;
      if (kit != null && ship.currentHp <= ship.maxHp * .65)
        return UseHullPatchKit(kit.id);
    }
    switch (s.phase) {
      case SessionPhase.helm:
        if (s.canEmergencyRepairAtSea && ship.gold >= s.emergencyRepairCost)
          return const RepairShip(.25);
        final offers = s.seaChart.currentCourseOptions
            .where((o) => s.courseRestriction(o.bearing) == null)
            .toList();
        if (offers.isEmpty) throw StateError('Audit helm has no legal offers');
        double rank(CourseOption o) {
          if (o.destination == CourseDestination.titan) return 1000;
          if (o.destination == CourseDestination.repairRefit)
            return ship.currentHp < ship.maxHp * .8 || ship.level < 4
                ? 200
                : 20;
          if (o.destination == CourseDestination.specialistMerchant) return 100;
          if (o.destination == CourseDestination.midpointHaven &&
              (ship.currentHp < ship.maxHp * .85 || ship.gold >= 80))
            return 200;
          return switch (o.nodeType) {
            EncounterNodeType.regionTitan => 1000,
            EncounterNodeType.beastCombat =>
              policy == VoyagePolicy.danger
                  ? (o.isApex ? 80 : 65)
                  : policy == VoyagePolicy.mixed
                  ? (o.isApex ? 45 : 65)
                  : (o.isApex ? 10 : 30),
            EncounterNodeType.shipwreckSalvage =>
              policy == VoyagePolicy.danger
                  ? 90
                  : policy == VoyagePolicy.mixed
                  ? (ship.currentHp > ship.maxHp * .65 ? 70 : 35)
                  : 60,
            EncounterNodeType.ancientShrine =>
              ship.blessings.values.fold<int>(0, (v, b) => v + b.tier) >= 9
                  ? 5
                  : policy == VoyagePolicy.danger
                  ? 40
                  : 85,
            EncounterNodeType.respiteIsland =>
              ship.currentHp < ship.maxHp * .7 ? 95 : 15,
            EncounterNodeType.smugglerTrader =>
              ship.currentHp < ship.maxHp * .6 ? 75 : 25,
          };
        }
        offers.sort((a, b) => rank(b).compareTo(rank(a)));
        return SteerCourse(offers.first.bearing);
      case SessionPhase.respiteIsland:
      case SessionPhase.stronghold:
        if (s.canUseVoyageShipwright) {
          final upgrade = _upgrade(s);
          if (upgrade != null) return upgrade;
        }
        if (s.phase == SessionPhase.respiteIsland &&
            !s.isRepairRefitStop &&
            !s.hasChosenIslandDuty) {
          return ship.currentHp < ship.maxHp * .8
              ? const CareenHullAtIsland()
              : const DrillGunnersAtIsland();
        }
        final repair = _repair(s);
        if (repair != null) return repair;
        if (s.phase == SessionPhase.stronghold &&
            _visitedStrongholds.add(s.seaChart.currentRegionIndex))
          return const VisitMerchant();
        return s.phase == SessionPhase.stronghold
            ? const TakeHelm()
            : const DepartIsland();
      case SessionPhase.merchant:
      case SessionPhase.smuggler:
        if (s.phase == SessionPhase.smuggler) {
          if (s.canClaimSmugglerGift &&
              s.smugglerStock.isNotEmpty &&
              ship.cargo.length < ship.maxCargo)
            return const ClaimSmugglerGift(0);
          final repair = _repair(s);
          if (repair != null) return repair;
        }
        final stock = s.phase == SessionPhase.smuggler
            ? s.smugglerStock
            : s.merchantStock;
        if (ship.cargo.length < ship.maxCargo &&
            ship.currentHp < ship.maxHp * .8) {
          final kitIndex = stock.indexWhere(
            (i) => i is Consumable && i.type == ConsumableType.hullPatchKit,
          );
          if (kitIndex >= 0) {
            final cost = s.phase == SessionPhase.smuggler
                ? stock[kitIndex].value
                : s.getMerchantAskingPrice(kitIndex);
            if (ship.gold >= cost + 25) return BuyMerchantItem(kitIndex);
          }
        }
        final materials = s.currentMaterialShipment;
        final reserve = ship.level < 4 ? 125 : 50;
        if (materials != null) {
          for (final m in [
            TradeMaterial.depthWroughtIron,
            TradeMaterial.seaGlass,
          ]) {
            if (materials.quantity(m) > 0 &&
                ship.gold >= reserve + s.materialUnitPrice(m))
              return BuyMerchantMaterial(materials.id, m);
          }
        }
        return s.phase == SessionPhase.smuggler
            ? const DepartSmuggler()
            : const LeaveMerchant();
      case SessionPhase.shipwreck:
        return wreckRecoveryAction(
          s,
          seekDanger:
              policy == VoyagePolicy.danger ||
              policy == VoyagePolicy.mixed && ship.currentHp > ship.maxHp * .65,
        );
      case SessionPhase.shrine:
        return chooseShrineBlessing(
          s,
          preferredPowers: const [
            OceanPower.earthshakerTitan,
            OceanPower.brinemother,
          ],
          preferredSlots: const [
            HardpointType.utility,
            HardpointType.broadside,
            HardpointType.signature,
          ],
        );
      case SessionPhase.battle:
        final forced = captainTraitAction(s);
        if (forced != null) return forced;
        if (!s.usedQuickConsumableThisTurn) {
          final kit = ship.cargo.indexWhere(
            (i) => i is Consumable && i.type == ConsumableType.hullPatchKit,
          );
          if (kit >= 0 && ship.currentHp <= ship.maxHp * .65)
            return UseConsumableItem(kit);
        }
        if (ship.isUtilityReady &&
            (s.seaChart.isRegionTitan || ship.currentHp < ship.maxHp * .5))
          return const ExecuteShipSpecialAction();
        return const CautiousBot().decideNextAction(s);
      case SessionPhase.loot:
        return s.pendingLoot.isNotEmpty && ship.cargo.length < ship.maxCargo
            ? const TakeAllLoot()
            : const LeaveRemainingLoot();
      case SessionPhase.restArea:
        return const TakeHelm();
      default:
        throw StateError('Audit stops before ${s.phase}');
    }
  }

  Command? _repair(GameSession s) {
    if (!s.hasPaidRepairService) return null;
    for (final fraction in [1.0, .25, .1, .02]) {
      final quote = s.paidRepairQuote(fraction);
      if (quote != null &&
          quote.restoredHp > 0 &&
          s.ship!.gold >= quote.goldCost)
        return RepairShip(fraction);
    }
    return null;
  }

  Command? _upgrade(GameSession s) {
    final ship = s.ship!;
    final candidates = <(Command, int)>[
      if (ship.markForHardpoint(HardpointType.broadside) == 1)
        (
          const TemperHardpoint(HardpointType.broadside),
          calculateHardpointTemperCost(1),
        ),
      if (ship.level == 1) (const UpgradeShip(), calculateShipUpgradeCost(1)),
      if (ship.markForHardpoint(HardpointType.broadside) == 2)
        (
          const TemperHardpoint(HardpointType.broadside),
          calculateHardpointTemperCost(2),
        ),
      for (final slot in [HardpointType.signature, HardpointType.utility])
        if (ship.markForHardpoint(slot) == 1)
          (TemperHardpoint(slot), calculateHardpointTemperCost(1)),
      if (ship.level == 2) (const UpgradeShip(), calculateShipUpgradeCost(2)),
      for (final slot in [HardpointType.signature, HardpointType.utility])
        if (ship.markForHardpoint(slot) == 2)
          (TemperHardpoint(slot), calculateHardpointTemperCost(2)),
      if (ship.level == 3) (const UpgradeShip(), calculateShipUpgradeCost(3)),
    ];
    if (candidates.isEmpty) return null;
    final (command, cost) = candidates.first;
    final reserve = ship.currentHp < ship.maxHp ? 20 : 0;
    return ship.gold >= cost + reserve ? command : null;
  }
}
