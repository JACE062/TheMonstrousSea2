import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

void main() {
  group('MetaInventory Tests', () {
    test('initializes with zeros', () {
      final inv = MetaInventory();
      expect(inv.isEmpty, isTrue);
      expect(inv.seaGlass, 0);
      expect(inv.monsterBone, 0);
      expect(inv.depthWroughtIron, 0);
      expect(inv.abyssalBarnacles, 0);
      expect(inv.krakenBeak, 0);
      expect(inv.serpentScale, 0);
      expect(inv.leviathanCore, 0);
      expect(inv.primordialCinders, 0);
    });

    test('add and addAll increment balances correctly', () {
      final inv = MetaInventory();
      inv.add(seaGlass: 10, monsterBone: 5, krakenBeak: 1);

      expect(inv.isEmpty, isFalse);
      expect(inv.seaGlass, 10);
      expect(inv.monsterBone, 5);
      expect(inv.krakenBeak, 1);

      final other = MetaInventory(seaGlass: 5, abyssalBarnacles: 3);
      inv.addAll(other);

      expect(inv.seaGlass, 15);
      expect(inv.abyssalBarnacles, 3);
      expect(inv.krakenBeak, 1);
    });

    test('canAfford and spend validate balances correctly', () {
      final inv = MetaInventory(
        seaGlass: 20,
        depthWroughtIron: 5,
        krakenBeak: 1,
      );

      expect(inv.canAfford(seaGlass: 15, depthWroughtIron: 5), isTrue);
      expect(inv.canAfford(seaGlass: 25), isFalse);
      expect(inv.canAfford(serpentScale: 1), isFalse);

      final success = inv.spend(seaGlass: 10, krakenBeak: 1);
      expect(success, isTrue);
      expect(inv.seaGlass, 10);
      expect(inv.krakenBeak, 0);

      // Cannot spend more than balance
      final failed = inv.spend(depthWroughtIron: 10);
      expect(failed, isFalse);
      expect(inv.depthWroughtIron, 5); // Unchanged
    });

    test('toJson and fromJson preserve complete currency matrix', () {
      final original = MetaInventory(
        seaGlass: 42,
        monsterBone: 18,
        depthWroughtIron: 7,
        abyssalBarnacles: 4,
        krakenBeak: 2,
        serpentScale: 1,
        leviathanCore: 1,
        primordialCinders: 50,
      );

      final json = original.toJson();
      final restored = MetaInventory.fromJson(json);

      expect(restored.seaGlass, original.seaGlass);
      expect(restored.monsterBone, original.monsterBone);
      expect(restored.depthWroughtIron, original.depthWroughtIron);
      expect(restored.abyssalBarnacles, original.abyssalBarnacles);
      expect(restored.krakenBeak, original.krakenBeak);
      expect(restored.serpentScale, original.serpentScale);
      expect(restored.leviathanCore, original.leviathanCore);
      expect(restored.primordialCinders, original.primordialCinders);
    });
  });
}
