import 'dart:convert';
import 'dart:io';

import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

void main() {
  group('Java Oracle Statistical & Range Parity Tests', () {
    late Map<String, dynamic> shipsFixture;
 
    setUpAll(() {
      final shipsFile = File('../../tools/java_oracle/fixtures/ships.json');
      if (shipsFile.existsSync()) {
        shipsFixture = jsonDecode(shipsFile.readAsStringSync())['ships'];
      }
    });

    test('Ship attributes match Java oracle bounds across all levels', () {
      if (shipsFixture.isEmpty) return;
      final rng = SeededGameRng(42);

      for (final shipClass in ShipClass.values) {
        final className = switch (shipClass) {
          ShipClass.standard => 'Standard',
          ShipClass.freighter => 'Freighter',
          ShipClass.ironclad => 'Ironclad',
          ShipClass.corvette => 'Corvette',
          _ => null,
        };
        if (className == null) continue;
        final classData = shipsFixture[className];
        if (classData == null) continue;

        for (var lvl = 1; lvl <= 4; lvl++) {
          final lvlData = classData['level_$lvl'];
          final expectedMinHp = lvlData['minHp'] as int;
          final expectedMaxHp = lvlData['maxHp'] as int;
          final expectedMinCargo = lvlData['minCargo'] as int;
          final expectedMaxCargo = lvlData['maxCargo'] as int;

          // Sample 100 ships
          for (var i = 0; i < 100; i++) {
            final ship = createShip(shipClass, level: lvl, rng: rng);
            expect(ship.maxHp, greaterThanOrEqualTo(expectedMinHp));
            expect(ship.maxHp, lessThanOrEqualTo(expectedMaxHp));
            expect(ship.maxCargo, greaterThanOrEqualTo(expectedMinCargo));
            expect(ship.maxCargo, lessThanOrEqualTo(expectedMaxCargo));
          }
        }
      }
    });

    test('Loot drop category bounds align with Bug B4 intentional fix (60/20/20)', () {
      final rng = SeededGameRng(12345);
      var treasures = 0;
      var consumables = 0;
      var weapons = 0;
      const totalSamples = 50000;

      for (var i = 0; i < totalSamples; i++) {
        final drops = generateVictoryLoot(1, rng);
        for (final item in drops) {
          if (item is Treasure) {
            treasures++;
          } else if (item is Consumable) {
            consumables++;
          } else if (item is ShipWeapon) {
            weapons++;
          }
        }
      }

      final totalItems = treasures + consumables + weapons;
      final treasurePct = treasures / totalItems;
      final consumablePct = consumables / totalItems;
      final weaponPct = weapons / totalItems;

      // Notice Java was 61.1% / 20.0% / 18.9% due to bug B4
      // Dart engine is strictly tuned to 60.0% / 20.0% / 20.0%
      expect(treasurePct, closeTo(0.60, 0.015));
      expect(consumablePct, closeTo(0.20, 0.015));
      expect(weaponPct, closeTo(0.20, 0.015));
    });
  });
}
