import 'package:monstrous_core/monstrous_core.dart';
import 'bot_strategy.dart';

/// Wealth-maximizing bot choosing the Freighter class to optimize cargo holds,
/// banking treasures at port, and avoiding unnecessary expenses.
class GreedyBot implements BotStrategy {
  const GreedyBot();

  @override
  String get name => 'Greedy';

  @override
  Command decideNextAction(GameSession session) {
    switch (session.phase) {
      case SessionPhase.captainCreation:
        if (session.captainName.isEmpty) {
          return const NameCaptain('Captain Midas');
        }
        return const ChooseShip(ShipClass.freighter);

      case SessionPhase.port:
        final ship = session.ship;
        final hasTreasure = ship?.cargo.any((item) => item is Treasure) ?? false;
        if (hasTreasure) {
          return const VisitMerchant();
        }
        // Minimal repair only if critically damaged and can afford
        if (ship != null && ship.currentHp < (ship.maxHp * 0.5)) {
          if (ship.gold >= calculateRepairCost(ship, 0.5)) {
            return const RepairShip(0.5);
          } else if (ship.gold >= calculateRepairCost(ship, 0.25)) {
            return const RepairShip(0.25);
          }
        }
        if (ship != null && ship.level < 4) {
          final cost = calculateShipUpgradeCost(ship.level);
          if (cost > 0 && ship.gold >= cost) {
            return const UpgradeShip();
          }
        }
        if (ship != null) {
          for (var i = 0; i < ship.cargo.length; i++) {
            final item = ship.cargo[i];
            if (item is ShipWeapon && ship.canEquipWeapon(item)) {
              return EquipCargoWeapon(i);
            }
          }
        }
        return const VentureOutToSea();

      case SessionPhase.battle:
        final ship = session.ship!;
        final hpRatio = ship.currentHp / ship.maxHp;

        // Fall back to longer range if critical health (< 20%)
        if (!ship.isGrappled &&
            session.lastHelmOrderThisTurn == HelmOrder.holdLine &&
            hpRatio < 0.20 &&
            session.combatRange != CombatRange.long) {
          return ChangeCombatRange(session.combatRange.farther);
        }

        final consumableIndex = ship.cargo.indexWhere((item) => item is Consumable);
        if (!session.usedQuickConsumableThisTurn && consumableIndex >= 0) {
          return UseConsumableItem(consumableIndex);
        }

        // Fire ready weapons
        final readyWeapons = ship.equippedWeapons
            .where((w) => w.isReady && isWeaponTypeUsableAtRange(w.weaponType, session.combatRange))
            .toList();
        if (readyWeapons.isNotEmpty) {
          readyWeapons.sort((a, b) => b.damage.compareTo(a.damage));
          return FireWeaponVolley(readyWeapons.first.weaponType);
        }

        final outOfRangeReadyWeapons = ship.equippedWeapons.where((w) => w.isReady).toList();
        if (!ship.isGrappled &&
            session.lastHelmOrderThisTurn == HelmOrder.holdLine &&
            outOfRangeReadyWeapons.isNotEmpty &&
            session.combatRange != CombatRange.short) {
          return ChangeCombatRange(session.combatRange.closer);
        }

        if (ship.isUtilityReady) {
          return const ExecuteShipSpecialAction();
        }

        return const BraceForImpact();

      case SessionPhase.loot:
        if (session.pendingLoot.isNotEmpty) {
          final ship = session.ship;
          if (ship != null && ship.cargo.length < ship.maxCargo) {
            return const TakeAllLoot();
          }
          return const LeaveRemainingLoot();
        }
        return const LeaveRemainingLoot();

      case SessionPhase.restArea:
        final ship = session.ship;
        final hpRatio = ship != null ? ship.currentHp / ship.maxHp : 1.0;

        // Return to port only when dangerously wounded
        if (hpRatio < 0.20) {
          return const ReturnToPort();
        }
        if (ship != null) {
          for (var i = 0; i < ship.cargo.length; i++) {
            final item = ship.cargo[i];
            if (item is ShipWeapon && ship.canEquipWeapon(item)) {
              return EquipCargoWeapon(i);
            }
          }
        }
        return const AdvanceToNextBattle();

      case SessionPhase.respiteIsland:
        final ship = session.ship;
        if (!session.hasChosenIslandDuty) {
          if (ship != null && ship.currentHp < ship.maxHp * 0.7) {
            return const CareenHullAtIsland();
          }
          return const DrillGunnersAtIsland();
        }
        return const DepartIsland();

      case SessionPhase.shipwreck:
        return const SalvageShipwreck(ShipwreckChoice.strongbox);

      case SessionPhase.smuggler:
        final hasTreasure = session.ship?.cargo.any((item) => item is Treasure) ?? false;
        if (hasTreasure) {
          return const SellAllTreasure();
        }
        return const DepartSmuggler();

      case SessionPhase.shrine:
        if (!session.hasCommunedAtCurrentShrine) {
          final ship = session.ship;
          if (ship != null && ship.currentHp > (ship.maxHp * 0.40)) {
            return const CommuneWithShrine(ShrineChoice.abyssalPact);
          }
          return const CommuneWithShrine(ShrineChoice.ancientRunes);
        }
        return const DepartShrine();

      case SessionPhase.helm:
        final options = session.seaChart.currentCourseOptions;
        final wreck = options
            .where((c) => c.nodeType == EncounterNodeType.shipwreckSalvage)
            .firstOrNull;
        if (wreck != null) return SteerCourse(wreck.bearing);
        final smuggler = options
            .where((c) => c.nodeType == EncounterNodeType.smugglerTrader)
            .firstOrNull;
        if (smuggler != null) return SteerCourse(smuggler.bearing);
        return const SteerCourse(NavigationalBearing.deadAhead);

      case SessionPhase.expeditionVictory:
        return const ClaimExpeditionVictory();

      case SessionPhase.merchant:
        final hasTreasure = session.ship?.cargo.any((item) => item is Treasure) ?? false;
        if (hasTreasure) {
          return const SellAllTreasure();
        }
        return const LeaveMerchant();

      case SessionPhase.death:
        return const AbandonHunt();

      case SessionPhase.ended:
        throw StateError('Simulation session already ended');
    }
  }
}
