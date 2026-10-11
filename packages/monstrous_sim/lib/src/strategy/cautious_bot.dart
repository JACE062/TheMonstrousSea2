import 'package:monstrous_core/monstrous_core.dart';
import 'bot_strategy.dart';

/// Defensive bot that prioritizes survivability, frequent hull repairs,
/// and tactical retreats when hull integrity drops below critical thresholds.
class CautiousBot implements BotStrategy {
  const CautiousBot();

  @override
  String get name => 'Cautious';

  @override
  Command decideNextAction(GameSession session) {
    switch (session.phase) {
      case SessionPhase.captainCreation:
        if (session.captainName.isEmpty) {
          return const NameCaptain('Captain Cautious');
        }
        return const ChooseShip(ShipClass.ironclad);

      case SessionPhase.port:
        final ship = session.ship;
        final hasTreasure = ship?.cargo.any((item) => item is Treasure) ?? false;
        if (hasTreasure) {
          return const VisitMerchant();
        }
        if (ship != null && ship.currentHp < ship.maxHp) {
          if (ship.gold >= calculateRepairCost(ship, 1.0)) {
            return const RepairShip(1.0);
          } else if (ship.gold >= calculateRepairCost(ship, 0.5)) {
            return const RepairShip(0.5);
          } else if (ship.gold >= calculateRepairCost(ship, 0.25)) {
            return const RepairShip(0.25);
          } else if (ship.gold >= calculateRepairCost(ship, 0.1)) {
            return const RepairShip(0.1);
          }
        }
        return const VentureOutToSea();

      case SessionPhase.battle:
        final ship = session.ship!;
        final hpRatio = ship.currentHp / ship.maxHp;

        // Flee if critical health (< 20%)
        if (hpRatio < 0.20) {
          return const FleeEncounter();
        }

        // Fire ready weapons
        final readyWeapons = ship.equippedWeapons.where((w) => w.isReady).toList();
        if (readyWeapons.isNotEmpty) {
          // If haven't fortified yet and under 50% HP, fortify once
          if (hpRatio < 0.50 &&
              ship.currentDmgReduction == ship.baseDmgReduction &&
              ship.shipClass == ShipClass.ironclad) {
            return const ExecuteShipSpecialAction();
          }

          readyWeapons.sort((a, b) => b.damage.compareTo(a.damage));
          return FireWeaponVolley(readyWeapons.first.weaponType);
        }

        // Check for consumable
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
        final ship = session.ship;
        final hpRatio = ship != null ? ship.currentHp / ship.maxHp : 1.0;

        // Emergency retreat to port only when severely damaged
        if (hpRatio < 0.25) {
          return const ReturnToPort();
        }
        return const AdvanceToNextBattle();

      case SessionPhase.merchant:
        final ship = session.ship;
        final hasTreasure = ship?.cargo.any((item) => item is Treasure) ?? false;
        if (hasTreasure) {
          return const SellAllTreasure();
        }
        if (ship != null && ship.cargo.length >= ship.maxCargo && ship.cargo.isNotEmpty) {
          return const SellCargoItem(0);
        }
        return const LeaveMerchant();

      case SessionPhase.death:
        return const AbandonHunt();

      case SessionPhase.ended:
        throw StateError('Simulation session already ended');
    }
  }
}
