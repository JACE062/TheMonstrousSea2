import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

void main() {
  group('Ship Upgrade & Refit Tests', () {
    test('calculateShipUpgradeCost returns expected tier prices', () {
      expect(calculateShipUpgradeCost(1), equals(100));
      expect(calculateShipUpgradeCost(2), equals(250));
      expect(calculateShipUpgradeCost(3), equals(500));
      expect(calculateShipUpgradeCost(4), equals(0));
    });

    test('Ironclad upgrade expands HP, weight, and damage reduction', () {
      final session = GameSession(rng: SeededGameRng(42));
      session.dispatch(const NameCaptain('Iron Mike'));
      session.dispatch(const ChooseShip(ShipClass.ironclad));

      final ship = session.ship!;
      expect(ship.level, equals(1));
      expect(ship.maxWeaponWeight, equals(10));
      expect(ship.baseDmgReduction, equals(3));
      final initialHp = ship.maxHp;

      // Give gold and test level 2 upgrade
      ship.gold = 500;
      final events = session.dispatch(const UpgradeShip());

      expect(events.any((e) => e is ShipUpgraded), isTrue);
      final upgradedEvent = events.firstWhere((e) => e is ShipUpgraded) as ShipUpgraded;
      expect(upgradedEvent.newLevel, equals(2));
      expect(upgradedEvent.goldCost, equals(100));

      expect(ship.level, equals(2));
      expect(ship.gold, equals(500 - 100));
      expect(ship.maxHp, equals(initialHp + 75));
      expect(ship.maxWeaponWeight, equals(20));
      expect(ship.baseDmgReduction, equals(6));
      expect(ship.dmgReductionMod, equals(4));
    });

    test('Corvette upgrade expands HP, weight, and passive evasion', () {
      final session = GameSession(rng: SeededGameRng(42));
      session.dispatch(const NameCaptain('Swift Sally'));
      session.dispatch(const ChooseShip(ShipClass.corvette));

      final ship = session.ship!;
      expect(ship.level, equals(1));
      expect(ship.maxWeaponWeight, equals(5));
      expect(ship.baseEvasion, equals(10));

      ship.gold = 200;
      session.dispatch(const UpgradeShip());

      expect(ship.level, equals(2));
      expect(ship.gold, equals(100));
      expect(ship.maxWeaponWeight, equals(10));
      expect(ship.baseEvasion, equals(15));
    });

    test('Upgrade fails when lacking gold', () {
      final session = GameSession(rng: SeededGameRng(42));
      session.dispatch(const NameCaptain('Broke Bob'));
      session.dispatch(const ChooseShip(ShipClass.standard));

      session.ship!.gold = 25; // Needs 100
      final events = session.dispatch(const UpgradeShip());

      expect(events.any((e) => e is ShipUpgraded), isFalse);
      expect(events.any((e) => e is NarrationEvent && e.message.contains('Insufficient gold')), isTrue);
      expect(session.ship!.level, equals(1));
    });

    test('Upgrade caps at Level 4', () {
      final session = GameSession(rng: SeededGameRng(42));
      session.dispatch(const NameCaptain('Maximus'));
      session.dispatch(const ChooseShip(ShipClass.freighter));

      final ship = session.ship!;
      ship.gold = 5000;

      session.dispatch(const UpgradeShip()); // To Lvl 2
      session.dispatch(const UpgradeShip()); // To Lvl 3
      session.dispatch(const UpgradeShip()); // To Lvl 4
      expect(ship.level, equals(4));

      final events = session.dispatch(const UpgradeShip());
      expect(events.any((e) => e is NarrationEvent && e.message.contains('maximum naval refit tier')), isTrue);
      expect(ship.level, equals(4));
    });
  });
}
