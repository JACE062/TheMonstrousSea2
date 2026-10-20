import 'dart:convert';

import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

void main() {
  const slots = [
    HardpointType.broadside,
    HardpointType.signature,
    HardpointType.utility,
  ];

  test('all 36 blessing previews expose their power, tier and mechanics', () {
    for (final power in OceanPower.values) {
      expect(power.domainLore, isNotEmpty);
      expect(power.synergySummary, isNotEmpty);
      for (final slot in slots) {
        var previousBonus = -1.0;
        for (var tier = 1; tier <= 3; tier++) {
          final blessing = HardpointBlessing(
            power: power,
            slot: slot,
            tier: tier,
          );
          expect(blessing.title, isNotEmpty);
          expect(blessing.description, isNotEmpty);
          expect(blessing.damageBonus, greaterThanOrEqualTo(previousBonus));
          previousBonus = blessing.damageBonus;
          final restored = HardpointBlessing.fromJson(blessing.toJson());
          expect(restored.power, power);
          expect(restored.slot, slot);
          expect(restored.tier, tier);
        }
      }
    }
  });

  test(
    'voyage serialization preserves dedications but excludes combat effects',
    () {
      final ship = createShip(
        ShipClass.standard,
        level: 1,
        rng: SeededGameRng(3),
      );
      for (var i = 0; i < slots.length; i++) {
        ship.blessings[slots[i]] = HardpointBlessing(
          power: OceanPower.values[i],
          slot: slots[i],
          tier: i + 1,
        );
      }
      ship.basaltBarrierHp = 25;
      ship.basaltAegisTurns = 2;
      ship.stormRiggingTurns = 2;
      ship.boilingWakeTurns = 3;
      final restored = ShipState.fromJson(
        jsonDecode(jsonEncode(ship.toJson())) as Map<String, dynamic>,
      );
      expect(
        restored.blessings.map((k, v) => MapEntry(k, v.toJson())),
        ship.blessings.map((k, v) => MapEntry(k, v.toJson())),
      );
      expect(restored.highestBlessingTier(OceanPower.brinemother), 3);
      expect(restored.highestBlessingTier(OceanPower.earthshakerTitan), 0);
      expect(restored.basaltBarrierHp, 0);
      expect(restored.basaltAegisTurns, 0);
      expect(restored.stormRiggingTurns, 0);
      expect(restored.boilingWakeTurns, 0);
      ship.resetCombatBoosts();
      expect(ship.blessings.length, 3);
      expect(ship.basaltBarrierHp, 0);
      expect(ship.basaltAegisTurns, 0);
      expect(ship.stormRiggingTurns, 0);
      expect(ship.boilingWakeTurns, 0);
      upgradeShipState(ship);
      expect(ship.blessings.length, 3);
    },
  );

  test(
    'legacy saves default to no dedications and unknown powers are skipped',
    () {
      final json = createShip(
        ShipClass.standard,
        level: 1,
        rng: SeededGameRng(3),
      ).toJson();
      json.remove('blessings');
      expect(ShipState.fromJson(json).blessings, isEmpty);
      json['blessings'] = {
        'broadside': {'power': 'futurePower', 'tier': 1},
      };
      expect(ShipState.fromJson(json).blessings, isEmpty);
    },
  );

  test(
    'base ram and howitzer types are corrected in factories and old saves',
    () {
      final rng = SeededGameRng(8);
      for (final entry in {
        ShipWeaponType.prowRam: DamageType.piercing,
        ShipWeaponType.shrapnelHowitzer: DamageType.slicing,
        ShipWeaponType.heavyMortar: DamageType.blast,
      }.entries) {
        final weapon = generateShipWeapon(
          entry.key,
          1,
          RarityLevel.common,
          rng,
        );
        expect(weapon.damageType, entry.value);
        final json = weapon.toJson()..['damageType'] = 'blast';
        expect(ShipWeapon.fromJson(json).damageType, entry.value);
      }
    },
  );
}
