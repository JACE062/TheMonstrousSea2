import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

void main() {
  group('SeededGameRng Tests', () {
    test('deterministic values with identical seeds', () {
      final rng1 = SeededGameRng(42);
      final rng2 = SeededGameRng(42);

      for (var i = 0; i < 50; i++) {
        expect(rng1.d20(), equals(rng2.d20()));
        expect(rng1.d100(), equals(rng2.d100()));
        expect(rng1.nextIntRange(5, 15), equals(rng2.nextIntRange(5, 15)));
      }
    });

    test('d20 produces values in valid 1..20 bounds', () {
      final rng = SeededGameRng(100);
      for (var i = 0; i < 1000; i++) {
        final roll = rng.d20();
        expect(roll, greaterThanOrEqualTo(1));
        expect(roll, lessThanOrEqualTo(20));
      }
    });
  });

  group('BalanceConfig Defaults', () {
    test('contains expected standard values', () {
      const cfg = BalanceConfig.standard;
      expect(cfg.treasureDropWeight, equals(60));
      expect(cfg.consumableDropWeight, equals(20));
      expect(cfg.weaponDropWeight, equals(20));
    });
  });
}
