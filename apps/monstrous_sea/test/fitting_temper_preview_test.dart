import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/widgets/fitting_temper_preview.dart';

void main() {
  for (final blueprint in BlueprintId.values) {
    for (final level in [1, 4]) {
      for (final armamentTier in [1, 3]) {
        for (final slot in blessingHardpoints) {
          for (final mark in [1, 2, 3]) {
            test(
              '$blueprint hull $level armament $armamentTier $slot Mk $mark',
              () {
                final ship = createFlagshipFromBlueprint(
                  blueprint,
                  level: level,
                  armamentTier: armamentTier,
                  rng: SeededGameRng(7),
                );
                while (ship.markForHardpoint(slot) < mark) {
                  temperShipHardpoint(ship, slot);
                }
                ship.gold = 417;
                ship.blessings[slot] = HardpointBlessing(
                  power: OceanPower.magmaVentLord,
                  slot: slot,
                  tier: 3,
                );
                final before = jsonEncode(ship.toJson());
                final preview = FittingTemperPreview(ship, slot);
                expect(jsonEncode(ship.toJson()), before);
                expect(preview.isMaximum, mark == 3);
                expect(preview.cost, calculateHardpointTemperCost(mark));
                expect(preview.stats, isNotEmpty);
                if (mark == 3) {
                  expect(preview.nextMark, isNull);
                  expect(
                    preview.stats.every((stat) => stat.next == null),
                    isTrue,
                  );
                  return;
                }
                temperShipHardpoint(ship, slot);
                expect(preview.nextMark, ship.markLabelForHardpoint(slot));
                expect(ship.gold, 417);
                if (slot != HardpointType.utility) {
                  final weapon = ship.equippedWeapons.singleWhere(
                    (w) => w.isSignature == (slot == HardpointType.signature),
                  );
                  expect(preview.stats.single.next, weapon.damage);
                } else {
                  final values = switch (blueprint) {
                    BlueprintId.standard => [
                      (ship.bracedVolleyDamageBonus * 100).round(),
                    ],
                    BlueprintId.ironclad => [ship.fortifyDamageReductionGain],
                    BlueprintId.clipper => [ship.evasiveRiggingBonus],
                    BlueprintId.bombardier => [
                      ship.spotterFlareAccuracyBonus,
                      (ship.spotterFlareBlastBonus * 100).round(),
                    ],
                    BlueprintId.corsair => [ship.tetherTrapDamage],
                  };
                  expect(preview.stats.map((s) => s.next), values);
                }
              },
            );
          }
        }
      }
    }
  }

  test('Iron Plates shows the real rounded plateau at hull tier one', () {
    final ship = createFlagshipFromBlueprint(
      BlueprintId.ironclad,
      rng: SeededGameRng(11),
    );
    final preview = FittingTemperPreview(ship, HardpointType.utility);
    expect(preview.stats.single.current, 2);
    expect(preview.stats.single.next, 2);
    expect(ship.markForHardpoint(HardpointType.utility), 1);
  });
}
