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
        return const VentureOutToSea();

      case SessionPhase.battle:
        final ship = session.ship!;
        final hpRatio = ship.currentHp / ship.maxHp;

        // Flee if close to sinking to protect cargo
        if (hpRatio < 0.20) {
          return const FleeEncounter();
        }

        // Fire ready weapons
        final readyWeapons = ship.equippedWeapons.where((w) => w.isReady).toList();
        if (readyWeapons.isNotEmpty) {
          readyWeapons.sort((a, b) => b.damage.compareTo(a.damage));
          return FireWeaponVolley(readyWeapons.first.weaponType);
        }

        final consumableIndex = ship.cargo.indexWhere((item) => item is Consumable);
        if (consumableIndex >= 0) {
          return UseConsumableItem(consumableIndex);
        }

        if (ship.equippedWeaponTypes.isNotEmpty) {
          return FireWeaponVolley(ship.equippedWeaponTypes.first);
        }

        return const ExecuteShipSpecialAction();

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
        return const AdvanceToNextBattle();

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
