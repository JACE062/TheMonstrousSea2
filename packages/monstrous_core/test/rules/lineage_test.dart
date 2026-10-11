import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

void main() {
  group('CaptainRecord & LineageTracker Aggregation', () {
    test('tracks captain deaths, total monsters defeated, and highest difficulty', () {
      final tracker = LineageTracker();
      expect(tracker.captainsLost, 0);
      expect(tracker.totalMonstersDefeated, 0);
      expect(tracker.highestDifficultyReached, 0);
      expect(tracker.history, isEmpty);

      const r1 = CaptainRecord(
        captainName: 'Ahab',
        shipName: 'Pequod',
        shipClass: ShipClass.standard,
        monstersDefeated: 5,
        highestDifficultyReached: 2,
        causeOfDeath: 'Crushed by Giant Squid',
      );
      tracker.recordDeath(r1);

      expect(tracker.captainsLost, 1);
      expect(tracker.totalMonstersDefeated, 5);
      expect(tracker.highestDifficultyReached, 2);
      expect(tracker.history, [r1]);

      const r2 = CaptainRecord(
        captainName: 'Ishmael',
        shipName: 'Sea Sprite',
        shipClass: ShipClass.freighter,
        monstersDefeated: 12,
        highestDifficultyReached: 5,
        causeOfDeath: 'Drowned by The Kraken',
      );
      tracker.recordDeath(r2);

      expect(tracker.captainsLost, 2);
      expect(tracker.totalMonstersDefeated, 17);
      expect(tracker.highestDifficultyReached, 5);
      expect(tracker.history, [r1, r2]);

      const r3 = CaptainRecord(
        captainName: 'Queequeg',
        shipName: 'Iron Maiden',
        shipClass: ShipClass.ironclad,
        monstersDefeated: 3,
        highestDifficultyReached: 3,
        causeOfDeath: 'Venom from Sea Serpent',
      );
      tracker.recordDeath(r3);

      expect(tracker.captainsLost, 3);
      expect(tracker.totalMonstersDefeated, 20);
      // highest difficulty remains 5 (max of 2, 5, 3)
      expect(tracker.highestDifficultyReached, 5);
      expect(tracker.history.length, 3);
    });

    test('CaptainRecord.toString formats cleanly', () {
      const record = CaptainRecord(
        captainName: 'Redbeard',
        shipName: 'Stormchaser',
        shipClass: ShipClass.corvette,
        monstersDefeated: 7,
        highestDifficultyReached: 3,
        causeOfDeath: 'Electric Shock from Jellyfish',
      );

      final str = record.toString();
      expect(str, contains('Captain Redbeard'));
      expect(str, contains('The Stormchaser'));
      expect(str, contains('Corvette'));
      expect(str, contains('Monsters Defeated: 7'));
      expect(str, contains('Highest Difficulty: 3'));
      expect(str, contains('Fell to: Electric Shock from Jellyfish'));
    });
  });

  group('Heir Ship Succession', () {
    test('non-Freighter previous ship grants standard 25 gold and empty cargo', () {
      final tracker = LineageTracker();
      final previousShip = ShipState(
        id: 'ship_ironclad_prev',
        name: 'Iron Fort',
        level: 2,
        maxHp: 200,
        armorClass: 14,
        shipClass: ShipClass.ironclad,
        maxCargo: 10,
        maxWeaponWeight: 20,
        gold: 1500,
        cargo: [generateTreasure(3), generateTreasure(4)],
      );

      final heirShip = tracker.createHeirShip(
        heirName: 'James',
        chosenClass: ShipClass.corvette,
        previousShip: previousShip,
        rng: SeededGameRng(42),
        shipName: 'Swift Gull',
      );

      expect(heirShip.name, 'Swift Gull');
      expect(heirShip.shipClass, ShipClass.corvette);
      expect(heirShip.level, 1);
      // Non-freighter: starts with standard 25 gold
      expect(heirShip.gold, 25);
      // Cargo is empty
      expect(heirShip.cargo, isEmpty);
      // Starts with 2 Common Cannons equipped
      expect(heirShip.equippedWeapons.length, 2);
      for (final weapon in heirShip.equippedWeapons) {
        expect(weapon.weaponType, ShipWeaponType.cannon);
        expect(weapon.rarity, RarityLevel.common);
        expect(weapon.rarity.level, 1);
      }
    });

    test('Freighter previous ship carries over 5% gold and stashed cargo', () {
      final tracker = LineageTracker();
      final item1 = generateTreasure(2);
      final item2 = generateTreasure(3);
      final item3 = generateConsumable(ConsumableType.blastPack, RarityLevel.epic);

      final previousFreighter = ShipState(
        id: 'ship_freighter_prev',
        name: 'Bountiful Mule',
        level: 2,
        maxHp: 250,
        armorClass: 14,
        shipClass: ShipClass.freighter,
        maxCargo: 50,
        maxWeaponWeight: 10,
        gold: 1000,
        cargo: [item1, item2, item3],
      );

      final heirShip = tracker.createHeirShip(
        heirName: 'Sarah',
        chosenClass: ShipClass.standard,
        previousShip: previousFreighter,
        rng: SeededGameRng(123),
        shipName: 'Dawn Treader',
      );

      expect(heirShip.name, 'Dawn Treader');
      expect(heirShip.shipClass, ShipClass.standard);
      expect(heirShip.level, 1);
      // 5% of 1000g = 50g
      expect(heirShip.gold, 50);
      // Inherits stashed cargo
      expect(heirShip.cargo, [item1, item2, item3]);
      // Equipped with 2 Common Cannons
      expect(heirShip.equippedWeapons.length, 2);
      expect(heirShip.equippedWeapons.every((w) => w.weaponType == ShipWeaponType.cannon), isTrue);
    });

    test('Freighter inheritance caps at heir ship max cargo capacity', () {
      final tracker = LineageTracker();
      final cargoItems = List.generate(20, (i) => generateTreasure(1));

      final previousFreighter = ShipState(
        id: 'ship_freighter_full',
        name: 'Gilded Leviathan',
        level: 3,
        maxHp: 300,
        armorClass: 16,
        shipClass: ShipClass.freighter,
        maxCargo: 60,
        maxWeaponWeight: 15,
        gold: 200,
        cargo: cargoItems,
      );

      // Ironclad has low cargo capacity (5 + [5..7]*1 = 10..12)
      final heirShip = tracker.createHeirShip(
        heirName: 'Gareth',
        chosenClass: ShipClass.ironclad,
        previousShip: previousFreighter,
        rng: SeededGameRng(42),
      );

      expect(heirShip.cargo.length, heirShip.maxCargo);
      expect(heirShip.cargo.length, lessThan(cargoItems.length));
    });
  });

  group('Bug B5 Fix (Freighter Heir String Formatting)', () {
    test('formatFreighterCargoOverflowMessage prints clean ship display name', () {
      final ship = ShipState(
        id: 'test_ship',
        name: 'Royal Fortune',
        level: 1,
        maxHp: 100,
        armorClass: 10,
        shipClass: ShipClass.freighter,
        maxCargo: 30,
        maxWeaponWeight: 5,
      );

      final msg = formatFreighterCargoOverflowMessage(ship);

      expect(msg, 'Not all of the Cargo fits onto The Royal Fortune, would you like to drop Cargo to make room?');
      expect(msg, isNot(contains("Instance of 'ShipState'")));
      expect(msg, isNot(contains('ShipState@')));
    });
  });
}
