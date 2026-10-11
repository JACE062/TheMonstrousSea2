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
        final readyWeapons = ship.equippedWeapons.where((w) => w.isReady).toList();

        // 70% attack if weapon ready, 10% special, 10% consumable, 10% flee
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
          return const FleeEncounter();
        }

        if (readyWeapons.isNotEmpty) {
          return FireWeaponVolley(readyWeapons.first.weaponType);
        }
        if (ship.equippedWeaponTypes.isNotEmpty) {
          return FireWeaponVolley(ship.equippedWeaponTypes.first);
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
