import 'package:monstrous_core/monstrous_core.dart';
import 'bot_strategy.dart';

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
        final classes = ShipClass.values;
        return ChooseShip(classes[rng.nextInt(classes.length)]);

      case SessionPhase.port:
        final roll = rng.nextInt(3);
        final ship = session.ship;
        if (roll == 0 && ship != null && ship.currentHp < ship.maxHp) {
          if (ship.gold >= calculateRepairCost(ship, 0.5)) {
            return const RepairShip(0.5);
          }
        } else if (roll == 1) {
          return const VisitMerchant();
        }
        return const VentureOutToSea();

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
        } else if (actionRoll == 7) {
          return const ExecuteShipSpecialAction();
        } else if (actionRoll == 8) {
          final consumableIndex =
              ship.cargo.indexWhere((item) => item is Consumable);
          if (consumableIndex >= 0) {
            return UseConsumableItem(consumableIndex);
          }
        } else if (actionRoll == 9) {
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
        final anyUsable = ship.equippedWeaponTypes
            .where((type) => isWeaponTypeUsableAtRange(type, session.combatRange))
            .toList();
        if (anyUsable.isNotEmpty) {
          return FireWeaponVolley(anyUsable.first);
        }
        return const ExecuteShipSpecialAction();

      case SessionPhase.loot:
        final ship = session.ship;
        if (session.pendingLoot.isNotEmpty &&
            ship != null &&
            ship.cargo.length < ship.maxCargo) {
          return const TakeAllLoot();
        }
        return const LeaveRemainingLoot();

      case SessionPhase.restArea:
        final advance = rng.nextInt(2) == 0;
        return advance
            ? const AdvanceToNextBattle()
            : const ReturnToPort();

      case SessionPhase.respiteIsland:
        if (!session.hasChosenIslandDuty) {
          final choice = rng.nextInt(3);
          if (choice == 0) return const CareenHullAtIsland();
          if (choice == 1) return const DrillGunnersAtIsland();
          return const ForageShoalsAtIsland();
        }
        return const DepartIsland();

      case SessionPhase.shipwreck:
        final choices = ShipwreckChoice.values;
        return SalvageShipwreck(choices[rng.nextInt(choices.length)]);

      case SessionPhase.smuggler:
        return const DepartSmuggler();

      case SessionPhase.shrine:
        if (!session.hasCommunedAtCurrentShrine) {
          return const CommuneWithShrine(ShrineChoice.ancientRunes);
        }
        return const DepartShrine();

      case SessionPhase.helm:
        final bearings = NavigationalBearing.values;
        return SteerCourse(bearings[rng.nextInt(bearings.length)]);

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
