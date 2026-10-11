import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

/// Test helper implementing [GameRng] with deterministically scripted values.
class ScriptedGameRng implements GameRng {
  ScriptedGameRng({
    List<int>? d100Queue,
    List<int>? nextIntQueue,
    List<int>? nextIntRangeQueue,
  })  : _d100Queue = List.of(d100Queue ?? []),
        _nextIntQueue = List.of(nextIntQueue ?? []),
        _nextIntRangeQueue = List.of(nextIntRangeQueue ?? []);

  final List<int> _d100Queue;
  final List<int> _nextIntQueue;
  final List<int> _nextIntRangeQueue;

  int defaultD100 = 50;
  int defaultNextInt = 0;
  int defaultNextIntRange = 3;

  @override
  int d100() => _d100Queue.isNotEmpty ? _d100Queue.removeAt(0) : defaultD100;

  @override
  int nextInt(int maxExclusive) =>
      _nextIntQueue.isNotEmpty ? _nextIntQueue.removeAt(0) : defaultNextInt;

  @override
  int nextIntRange(int minInclusive, int maxInclusive) =>
      _nextIntRangeQueue.isNotEmpty
          ? _nextIntRangeQueue.removeAt(0)
          : defaultNextIntRange;

  @override
  int d(int n) => 1;

  @override
  int d20() => 10;

  @override
  double nextDouble() => 0.5;
}

void main() {
  group('Loot Drops Bug B1 Fix (Drop Count Range)', () {
    test('victory drop count is always in [minItemsDropped..maxItemsDropped]', () {
      final rng = SeededGameRng(42);
      const config = BalanceConfig.standard;

      for (var monsterLevel = 1; monsterLevel <= 8; monsterLevel++) {
        for (var i = 0; i < 200; i++) {
          final loot = generateVictoryLoot(monsterLevel, rng, config);
          expect(loot.length, greaterThanOrEqualTo(config.minItemsDropped));
          expect(loot.length, lessThanOrEqualTo(config.maxItemsDropped));
        }
      }
    });

    test('respects custom BalanceConfig drop count bounds', () {
      final rng = SeededGameRng(99);
      const customConfig = BalanceConfig(
        minItemsDropped: 5,
        maxItemsDropped: 10,
      );

      for (var i = 0; i < 100; i++) {
        final loot = generateVictoryLoot(3, rng, customConfig);
        expect(loot.length, greaterThanOrEqualTo(5));
        expect(loot.length, lessThanOrEqualTo(10));
      }
    });
  });

  group('Loot Drops Bug B4 Fix (Item Category Distribution)', () {
    test('exact boundary partition values for 60/20/20 category roll', () {
      // 0..59 -> Treasure
      final rngTreasureMin = ScriptedGameRng(nextIntQueue: [0]);
      expect(generateLootItem(1, rngTreasureMin), isA<Treasure>());

      final rngTreasureMax = ScriptedGameRng(nextIntQueue: [59]);
      expect(generateLootItem(1, rngTreasureMax), isA<Treasure>());

      // 60..79 -> Consumable
      final rngConsumableMin = ScriptedGameRng(nextIntQueue: [60]);
      expect(generateLootItem(1, rngConsumableMin), isA<Consumable>());

      final rngConsumableMax = ScriptedGameRng(nextIntQueue: [79]);
      expect(generateLootItem(1, rngConsumableMax), isA<Consumable>());

      // 80..99 -> ShipWeapon
      final rngWeaponMin = ScriptedGameRng(nextIntQueue: [80]);
      expect(generateLootItem(1, rngWeaponMin), isA<ShipWeapon>());

      final rngWeaponMax = ScriptedGameRng(nextIntQueue: [99]);
      expect(generateLootItem(1, rngWeaponMax), isA<ShipWeapon>());
    });

    test('Monte Carlo simulation confirms 60% treasure, 20% consumable, 20% weapon', () {
      final rng = SeededGameRng(12345);
      const sampleSize = 50000;
      var treasureCount = 0;
      var consumableCount = 0;
      var weaponCount = 0;

      for (var i = 0; i < sampleSize; i++) {
        final item = generateLootItem(2, rng);
        if (item is Treasure) {
          treasureCount++;
        } else if (item is Consumable) {
          consumableCount++;
        } else if (item is ShipWeapon) {
          weaponCount++;
        }
      }

      final treasureRate = treasureCount / sampleSize;
      final consumableRate = consumableCount / sampleSize;
      final weaponRate = weaponCount / sampleSize;

      // Allow tolerance of +/- 0.8%
      expect(treasureRate, closeTo(0.60, 0.008));
      expect(consumableRate, closeTo(0.20, 0.008));
      expect(weaponRate, closeTo(0.20, 0.008));
    });
  });

  group('Item Level Spread Calculations', () {
    test('level spread thresholds for monster level 5', () {
      const monsterLevel = 5;

      // <= 15: max(1, 5 - 3) = 2
      expect(calculateLootLevel(monsterLevel, ScriptedGameRng(d100Queue: [1])), 2);
      expect(calculateLootLevel(monsterLevel, ScriptedGameRng(d100Queue: [15])), 2);

      // <= 30: max(1, 5 - 2) = 3
      expect(calculateLootLevel(monsterLevel, ScriptedGameRng(d100Queue: [16])), 3);
      expect(calculateLootLevel(monsterLevel, ScriptedGameRng(d100Queue: [30])), 3);

      // <= 50: max(1, 5 - 1) = 4
      expect(calculateLootLevel(monsterLevel, ScriptedGameRng(d100Queue: [31])), 4);
      expect(calculateLootLevel(monsterLevel, ScriptedGameRng(d100Queue: [50])), 4);

      // <= 80: 5
      expect(calculateLootLevel(monsterLevel, ScriptedGameRng(d100Queue: [51])), 5);
      expect(calculateLootLevel(monsterLevel, ScriptedGameRng(d100Queue: [80])), 5);

      // <= 95: 5 + 1 = 6
      expect(calculateLootLevel(monsterLevel, ScriptedGameRng(d100Queue: [81])), 6);
      expect(calculateLootLevel(monsterLevel, ScriptedGameRng(d100Queue: [95])), 6);

      // <= 99: 5 + 2 = 7
      expect(calculateLootLevel(monsterLevel, ScriptedGameRng(d100Queue: [96])), 7);
      expect(calculateLootLevel(monsterLevel, ScriptedGameRng(d100Queue: [99])), 7);

      // > 99: 5 + 3 = 8
      expect(calculateLootLevel(monsterLevel, ScriptedGameRng(d100Queue: [100])), 8);
    });

    test('level floor clamps negative or 0 offsets to minimum level 1', () {
      const monsterLevel = 1;
      // 1 - 3 = -2 -> clamped to 1
      expect(calculateLootLevel(monsterLevel, ScriptedGameRng(d100Queue: [5])), 1);
      // 1 - 2 = -1 -> clamped to 1
      expect(calculateLootLevel(monsterLevel, ScriptedGameRng(d100Queue: [20])), 1);
      // 1 - 1 = 0 -> clamped to 1
      expect(calculateLootLevel(monsterLevel, ScriptedGameRng(d100Queue: [40])), 1);
    });
  });

  group('Treasure Value Scaling', () {
    test('generateTreasure generates correct rarity and gold for levels 1..6', () {
      final t1 = generateTreasure(1);
      expect(t1.rarity, RarityLevel.common);
      expect(t1.value, 10);

      final t2 = generateTreasure(2);
      expect(t2.rarity, RarityLevel.rare);
      expect(t2.value, 25);

      final t3 = generateTreasure(3);
      expect(t3.rarity, RarityLevel.epic);
      expect(t3.value, 75);

      final t4 = generateTreasure(4);
      expect(t4.rarity, RarityLevel.legendary);
      expect(t4.value, 250);

      // Level 5: 100 * (1.25^5).toInt() = 100 * 3 = 300
      final t5 = generateTreasure(5);
      expect(t5.rarity, RarityLevel.legendary);
      expect(t5.value, 300);

      // Level 6: 100 * (1.25^6).toInt() = 100 * 3.8146... = 300 or 100 * 3?
      // 1.25^6 = 3.814697265625 -> toInt() is 3 -> 300
      final t6 = generateTreasure(6);
      expect(t6.rarity, RarityLevel.legendary);
      expect(t6.value, 300);

      // Level 7: 1.25^7 = 4.768... -> toInt() is 4 -> 400
      final t7 = generateTreasure(7);
      expect(t7.rarity, RarityLevel.legendary);
      expect(t7.value, 400);
    });
  });

  group('Sorted Loot Drops', () {
    test('generateVictoryLoot returns items sorted by Item.compareTo', () {
      final rng = SeededGameRng(777);
      final loot = generateVictoryLoot(4, rng);

      for (var i = 0; i < loot.length - 1; i++) {
        expect(loot[i].compareTo(loot[i + 1]), lessThanOrEqualTo(0));
      }
    });
  });
}
