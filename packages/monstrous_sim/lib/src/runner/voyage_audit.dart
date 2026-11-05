import 'package:monstrous_core/monstrous_core.dart';

import '../strategy/voyage_economy_bot.dart';

enum AuditMode { live, attritionReplay, harshReplay }

enum AuditBuild { fresh, progressed, carpenter, exacting, combined, noCove }

/// Rich full-campaign telemetry; deliberately does not use RunResult.won,
/// whose historical meaning is crossing the first Kraken boundary.
class VoyageAuditRunner {
  const VoyageAuditRunner({this.maxSteps = 4000});
  final int maxSteps;

  Map<String, dynamic> run({
    required int seed,
    required VoyagePolicy policy,
    required AuditBuild build,
    AuditMode mode = AuditMode.live,
    NavigationTuning? tuning,
  }) {
    final initialMaterials = build == AuditBuild.progressed
        ? MetaInventory(
            seaGlass: 6,
            monsterBone: 4,
            depthWroughtIron: 2,
            abyssalBarnacles: 1,
          )
        : MetaInventory();
    final s = GameSession(
      rng: SeededGameRng(seed),
      navigationTuning:
          tuning ??
          (build == AuditBuild.noCove
              ? const NavigationTuning(huntWeight: 71, coveWeight: 0)
              : NavigationTuning.provisional),
      profile: ProfileData(
        metaInventory: initialMaterials,
        blueprintArmamentTiers: {
          if (build == AuditBuild.progressed) 'standard': 2,
        },
      ),
    );
    s.dispatch(const BeginFirstVoyage('Economy audit'));
    if (build == AuditBuild.carpenter || build == AuditBuild.combined)
      s.activeBoon = BloodlineTrait.skilledCarpenter;
    if (build == AuditBuild.exacting || build == AuditBuild.combined)
      s.activeQuirk = BloodlineTrait.exactingShipwright;
    final bot = VoyageEconomyBot(policy);
    final totals = <String, int>{};
    void add(String key, int amount) =>
        totals.update(key, (v) => v + amount, ifAbsent: () => amount);
    final milestones = <Map<String, dynamic>>[];
    final receipts = <Map<String, dynamic>>[];
    final seenHelms = <String>{};
    final seenKits = <String>{};
    final startingMeta = s.profile.metaInventory.toJson();
    final result = <String, dynamic>{
      'seed': seed,
      'policy': policy.name,
      'build': build.name,
      'mode': mode.name,
      'startingMeta': startingMeta,
      'totals': totals,
      'milestones': milestones,
      'receipts': receipts,
    };
    Map<String, dynamic> snapshot(String kind) => {
      'kind': kind,
      'region': s.seaChart.currentRegionIndex + 1,
      'leg': s.seaChart.currentLeg,
      'hp': s.ship!.currentHp,
      'maxHp': s.ship!.maxHp,
      'gold': s.ship!.gold,
      'hullTier': s.ship!.level,
      'marks': {
        for (final slot in [
          HardpointType.broadside,
          HardpointType.signature,
          HardpointType.utility,
        ])
          slot.name: s.ship!.markForHardpoint(slot),
      },
      'repairWork': s.paidRepairWork.toJson(),
      'quotedRepairGold': s.paidRepairQuote(1)?.goldCost,
      'affordFirstFittingPlusQuotedRepairs':
          s.ship!.gold >=
          calculateHardpointTemperCost(1) +
              (s.paidRepairQuote(1)?.goldCost ?? 0),
      'affordFirstHullPlusQuotedRepairs':
          s.ship!.gold >=
          calculateShipUpgradeCost(1) + (s.paidRepairQuote(1)?.goldCost ?? 0),
      'blessingTiers': s.ship!.blessings.values.fold<int>(
        0,
        (v, b) => v + b.tier,
      ),
      'meta': s.profile.metaInventory.toJson(),
    };
    var steps = 0;
    String? error;
    try {
      while (s.phase != SessionPhase.death &&
          s.phase != SessionPhase.ended &&
          s.phase != SessionPhase.expeditionVictory &&
          steps < maxSteps) {
        steps++;
        if (s.phase == SessionPhase.helm &&
            seenHelms.add(
              '${s.seaChart.currentRegionIndex}:${s.seaChart.currentLeg}',
            )) {
          final shrines = s.seaChart.currentCourseOptions
              .where((o) => o.nodeType == EncounterNodeType.ancientShrine)
              .length;
          add('shrineOffers', shrines);
          if (shrines > 0) add('shrineOpportunities', 1);
        }
        // Economic counterfactual only: preserve income/service commands, replace
        // combat with explicit fixed wear. It never contributes live survival.
        if (mode != AuditMode.live &&
            s.phase == SessionPhase.battle &&
            s.currentMonster!.isAlive) {
          final region = s.seaChart.currentRegionIndex;
          final damage = s.seaChart.isRegionTitan
              ? [35, 50, 70][region]
              : (mode == AuditMode.harshReplay
                    ? [30, 40, 50]
                    : [15, 22, 30])[region];
          add('scriptedDamage', damage);
          if (damage >= s.ship!.currentHp) add('scriptedFatalShortfalls', 1);
          s.ship!.currentHp = (s.ship!.currentHp - damage).clamp(
            1,
            s.ship!.maxHp,
          );
          s.currentMonster!.currentHp = 0;
        }
        final phase = s.phase;
        final blessingTiers = s.ship!.blessings.values.fold<int>(
          0,
          (v, b) => v + b.tier,
        );
        final hp = s.ship!.currentHp;
        final maxHp = s.ship!.maxHp;
        final gold = s.ship!.gold;
        final work = s.paidRepairWork.spentWork;
        final ownedBefore = [...s.ship!.cargo, ...s.pendingLoot];
        final command = mode != AuditMode.live && s.phase == SessionPhase.battle
            ? FireWeaponVolley(s.ship!.equippedWeapons.first.weaponType)
            : bot.decideNextAction(s);
        final usedItem =
            command is UseConsumableItem &&
                command.cargoIndex < s.ship!.cargo.length
            ? s.ship!.cargo[command.cargoIndex]
            : null;
        final pendingIds = s.pendingLoot.map((i) => i.id).toSet();
        final events = s.dispatch(command);
        final goldChange = s.ship!.gold - gold;
        if (goldChange > 0) {
          add('goldEarned', goldChange);
          add(
            command is ChooseWreckRecovery
                ? 'goldCargo'
                : command is ForageShoalsAtIsland
                ? 'goldForage'
                : command is SellCargoItem || command is SellAllTreasure
                ? 'goldSales'
                : 'goldCombat',
            goldChange,
          );
        } else if (goldChange < 0) {
          add('goldSpent', -goldChange);
          add(
            command is UpgradeShip || command is TemperHardpoint
                ? 'spentUpgrades'
                : (command is RepairShip || command is BuyAffordablePaidRepairs)
                ? (phase == SessionPhase.helm ? 'spentTriage' : 'spentRepairs')
                : command is BuyMerchantMaterial
                ? 'spentMaterials'
                : 'spentSupplies',
            -goldChange,
          );
        }
        if ((command is RepairShip || command is BuyAffordablePaidRepairs) &&
            s.ship!.currentHp > hp) {
          add(
            phase == SessionPhase.helm ? 'triageHp' : 'paidRepairHp',
            s.ship!.currentHp - hp,
          );
          if (phase != SessionPhase.helm)
            add('normalRepairWork', s.paidRepairWork.spentWork - work);
        }
        if (command is UpgradeShip) add('refitHp', s.ship!.maxHp - maxHp);
        if (command is CareenHullAtIsland) {
          add('careenHp', s.ship!.currentHp - hp);
          add('careenDuties', 1);
        }
        if (command is DrillGunnersAtIsland) add('drillDuties', 1);
        if (command is ForageShoalsAtIsland) add('forageDuties', 1);
        if (command is AcceptShrineBlessing) {
          add(
            'dedications',
            s.ship!.blessings.values.fold<int>(0, (v, b) => v + b.tier) -
                blessingTiers,
          );
        }
        if (command is UseHullPatchKit ||
            usedItem is Consumable &&
                usedItem.type == ConsumableType.hullPatchKit) {
          add('kitsUsed', 1);
          add('kitHp', s.ship!.currentHp - hp);
          if (command is UseHullPatchKit &&
              command.fromPendingLoot &&
              s.ship!.cargo.length >= s.ship!.maxCargo)
            add('overflowKitsUsed', 1);
        } else if (usedItem is Consumable) {
          add('otherSuppliesUsed', 1);
        }
        final ownedAfter = [...s.ship!.cargo, ...s.pendingLoot];
        for (final item in ownedAfter.whereType<Consumable>().where(
          (i) => i.type == ConsumableType.hullPatchKit,
        )) {
          if (seenKits.add(item.id)) add('kitsAcquired', 1);
        }
        if (command is LeaveRemainingLoot) {
          add(
            'suppliesLeft',
            ownedBefore.where((i) => pendingIds.contains(i.id)).length,
          );
          add(
            'kitsLeft',
            ownedBefore
                .whereType<Consumable>()
                .where(
                  (i) =>
                      pendingIds.contains(i.id) &&
                      i.type == ConsumableType.hullPatchKit,
                )
                .length,
          );
        }
        if (command is SteerCourse &&
            s.seaChart.currentNodeType == EncounterNodeType.shipwreckSalvage)
          add('wreckVisits', 1);
        if (events.any((e) => e is BattleStarted) && s.currentWreck != null) {
          add('wreckFights', 1);
          if (s.currentWreck!.approachAmbush) add('approachAmbushes', 1);
        }
        if (phase != s.phase) {
          if (s.phase == SessionPhase.respiteIsland && s.isCurrentIslandHaven)
            milestones.add(snapshot('havenArrival'));
          if (s.phase == SessionPhase.battle && s.seaChart.isRegionTitan)
            milestones.add(snapshot('titanArrival'));
          if (s.phase == SessionPhase.shrine) add('shrineVisits', 1);

          if (phase == SessionPhase.respiteIsland)
            milestones.add(snapshot('shoreDeparture'));
          if (s.phase == SessionPhase.stronghold)
            milestones.add(snapshot('strongholdArrival'));
        }
        if (!result.containsKey('firstMax') &&
            s.ship!.level == 4 &&
            [
              HardpointType.broadside,
              HardpointType.signature,
              HardpointType.utility,
            ].every((slot) => s.ship!.markForHardpoint(slot) == 3))
          result['firstMax'] = snapshot('firstMax');
        for (final event in events) {
          if (event is LootDropped)
            receipts.add({
              ...snapshot('combatReceipt'),
              'bounty': event.goldSalvaged,
              'apex': s.currentMonster!.isApex,
              'species': s.currentMonster!.species.name,
              'node': s.seaChart.currentNodeType.name,
              'supplies': event.items.length,
            });
          if (event is MaterialPurchased)
            add(
              event.material == TradeMaterial.seaGlass
                  ? 'glassBought'
                  : 'ironBought',
              event.quantity,
            );
        }
        if (command is ChooseWreckRecovery &&
            s.currentWreck?.stage == WreckStage.receipt &&
            phase == SessionPhase.shipwreck &&
            events.isNotEmpty) {
          final cargo = s.currentWreck!.cargo;
          if (cargo != null &&
              !receipts.any((r) => r['wreckId'] == s.currentWreck!.id))
            receipts.add({
              ...snapshot('cargoReceipt'),
              'wreckId': s.currentWreck!.id,
              'condition': s.currentWreck!.condition.name,
              'fought': s.currentWreck!.threatCleared,
              'cargo': cargo.toJson(),
            });
        }
      }
    } catch (e, stack) {
      error = '$e\n$stack';
    }
    result.addAll({
      'steps': steps,
      'terminalPhase': s.phase.name,
      'complete': s.phase == SessionPhase.expeditionVictory,
      'krakenCrossed': s.seaChart.currentRegionIndex >= 1,
      'died': s.phase == SessionPhase.death,
      'stepLimited': steps >= maxSteps,
      'error': error,
      'final': snapshot('final'),
      'kitsCarried': s.ship!.cargo
          .whereType<Consumable>()
          .where((i) => i.type == ConsumableType.hullPatchKit)
          .length,
      'affordableBlueprints': [
        for (final bp in FlagshipBlueprint.catalog.values)
          if (bp.id != BlueprintId.standard &&
              s.profile.metaInventory.canAffordCost(bp.unlockCost))
            bp.id.name,
      ],
    });
    return result;
  }
}
