import 'package:monstrous_core/monstrous_core.dart';
import 'bot_strategy.dart';

/// Aggressive bot prioritizing maximum raw damage output and rapid battle advancement.
/// Never retreats or flees from naval combat.
class RecklessBot implements BotStrategy {
  const RecklessBot();

  @override
  String get name => 'Reckless';

  @override
  Command decideNextAction(GameSession session) {
    switch (session.phase) {
      case SessionPhase.captainCreation:
        if (session.captainName.isEmpty) {
          return const NameCaptain('Captain Reckless');
        }
        return const ChooseShip(ShipClass.ironclad);

      case SessionPhase.port:
        final ship = session.ship;
        if (ship != null && ship.currentHp < ship.maxHp) {
          if (ship.gold >= calculateRepairCost(ship, 1.0)) {
            return const RepairShip(1.0);
          } else if (ship.gold >= calculateRepairCost(ship, 0.5)) {
            return const RepairShip(0.5);
          }
        }
        return const VentureOutToSea();

      case SessionPhase.battle:
        final ship = session.ship!;
        final readyWeapons = ship.equippedWeapons.where((w) => w.isReady).toList();

        if (readyWeapons.isNotEmpty) {
          readyWeapons.sort((a, b) => b.damage.compareTo(a.damage));
          return FireWeaponVolley(readyWeapons.first.weaponType);
        }

        final consumableIndex = ship.cargo.indexWhere((item) => item is Consumable);
        if (consumableIndex >= 0) {
          return UseConsumableItem(consumableIndex);
        }

        if (ship.shipClass == ShipClass.ironclad || ship.shipClass == ShipClass.corvette) {
          return const ExecuteShipSpecialAction();
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
