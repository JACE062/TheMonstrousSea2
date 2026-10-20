import 'package:monstrous_core/monstrous_core.dart';
import 'bot_strategy.dart';
import 'shrine_strategy.dart';

/// Stochastic bot that selects pseudo-randomly among legal game commands.
class RandomBot implements BotStrategy {
  RandomBot({GameRng? rng}) : rng = rng ?? SeededGameRng(777);

  final GameRng rng;

  @override
  String get name => 'Random';

  @override
  Command decideNextAction(GameSession session) {
    switch (session.phase) {
      case SessionPhase.captainCreation:
        if (session.captainName.isEmpty) {
          return const NameCaptain('Captain Fortuna');
        }
        final canonicalClasses =
            BlueprintId.values
                .where(session.profile.isBlueprintUnlocked)
                .map((b) => b.shipClass).toList();
        return ChooseShip(canonicalClasses[rng.nextInt(canonicalClasses.length)]);

      case SessionPhase.port:
      case SessionPhase.stronghold:
        final roll = rng.nextInt(3);
        final ship = session.ship;
        if (roll == 0 && ship != null && ship.currentHp < ship.maxHp) {
          if (ship.gold >= calculateRepairCost(ship, 0.5)) {
            return const RepairShip(0.5);
          }
        } else if (roll == 1) {
          return const VisitMerchant();
        }
        return session.phase == SessionPhase.stronghold
            ? const TakeHelm() : const VentureOutToSea();

      case SessionPhase.battle:
        final ship = session.ship!;
        final readyWeapons = ship.equippedWeapons
            .where((w) => w.isReady && isWeaponTypeUsableAtRange(w.weaponType, session.combatRange))
            .toList();

        // 70% attack if weapon ready, 10% special, 10% consumable, 10% range maneuver
        final actionRoll = rng.nextInt(10);
        if (actionRoll < 7 && readyWeapons.isNotEmpty) {
          final chosen = readyWeapons[rng.nextInt(readyWeapons.length)];
          return FireWeaponVolley(chosen.weaponType);
        } else if (actionRoll == 7 && ship.isUtilityReady) {
          return const ExecuteShipSpecialAction();
        } else if (actionRoll == 8 && !session.usedQuickConsumableThisTurn) {
          final consumableIndex =
              ship.cargo.indexWhere((item) => item is Consumable && !item.isDepleted);
          if (consumableIndex >= 0) {
            return UseConsumableItem(consumableIndex);
          }
        } else if (actionRoll == 9 &&
            !ship.isGrappled &&
            session.lastHelmOrderThisTurn == HelmOrder.holdLine) {
          final legalRanges = switch (session.combatRange) {
            CombatRange.long => const [CombatRange.medium],
            CombatRange.medium => const [CombatRange.short, CombatRange.long],
            CombatRange.short => const [CombatRange.medium],
          };
          return ChangeCombatRange(legalRanges[rng.nextInt(legalRanges.length)]);
        }

        if (readyWeapons.isNotEmpty) {
          return FireWeaponVolley(readyWeapons.first.weaponType);
        }
        if (ship.isUtilityReady) {
          return const ExecuteShipSpecialAction();
        }
        return const BraceForImpact();

      case SessionPhase.loot:
        final ship = session.ship;
        if (session.pendingLoot.isNotEmpty &&
            ship != null &&
            ship.cargo.length < ship.maxCargo) {
          return const TakeAllLoot();
        }
        return const LeaveRemainingLoot();

      case SessionPhase.restArea:
        final isBossDefeated = ((session.seaChart.currentRow == SeaChart.bossRow &&
                    session.seaChart.currentCol == SeaChart.bossCol) ||
                session.seaChart.currentLeg >= session.seaChart.totalLegs) &&
            session.currentMonster != null &&
            !session.currentMonster!.isAlive;
        if (isBossDefeated) {
          return const AdvanceToNextBattle();
        }
        return const TakeHelm();

      case SessionPhase.respiteIsland:
        if (!session.hasChosenIslandDuty) {
          final choice = rng.nextInt(3);
          if (choice == 0) return const CareenHullAtIsland();
          if (choice == 1) return const DrillGunnersAtIsland();
          return const ForageShoalsAtIsland();
        }
        return const DepartIsland();

      case SessionPhase.shipwreck:
        if (!session.hasSalvagedCurrentWreck) {
          final choices = ShipwreckChoice.values;
          return SalvageShipwreck(choices[rng.nextInt(choices.length)]);
        }
        return const TakeHelm();

      case SessionPhase.smuggler:
        return const DepartSmuggler();

      case SessionPhase.shrine:
        return chooseShrineBlessing(session, rng: rng);

      case SessionPhase.helm:
        final options = session.seaChart.currentCourseOptions;
        if (options.isNotEmpty) {
          return SteerCourse(options[rng.nextInt(options.length)].bearing);
        }
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
