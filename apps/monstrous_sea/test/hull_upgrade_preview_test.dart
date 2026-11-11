import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/widgets/hull_upgrade_preview.dart';

void main() {
  for (final blueprint in BlueprintId.values) {
    for (var tier = 1; tier <= 4; tier++) {
      test(
        '$blueprint hull tier $tier preview matches the purchased refit',
        () {
          for (final mark in [1, 2, 3]) {
            for (final ancestralTier in [1, 3]) {
              for (final wounded in [false, true]) {
                final s = GameSession(rng: SeededGameRng(21))
                  ..dispatch(const BeginFirstVoyage('Hull witness'));
                final ship = createFlagshipFromBlueprint(
                  blueprint,
                  armamentTier: ancestralTier,
                  rng: s.rng,
                );
                for (final slot in blessingHardpoints) {
                  while (ship.markForHardpoint(slot) < mark) {
                    temperShipHardpoint(ship, slot);
                  }
                  ship.blessings[slot] = HardpointBlessing(
                    power: OceanPower.magmaVentLord,
                    slot: slot,
                    tier: 3,
                  );
                }
              while (ship.level < tier) {
                upgradeShipState(ship);
              }
                ship.currentHp = ship.maxHp - (wounded ? 37 : 0);
                ship.gold = 1000;
                s.ship = ship;
                s.activeBoon = BloodlineTrait.skilledCarpenter;
                s.activeQuirk = BloodlineTrait.exactingShipwright;
                s.phase = SessionPhase.stronghold;
                final before = jsonEncode(ship.toJson());
                final profileBefore = jsonEncode(s.profile.toJson());
                final chartBefore = jsonEncode(s.seaChart.toJson());
                final preview = HullUpgradePreview(ship);
                expect(jsonEncode(ship.toJson()), before);
                expect(jsonEncode(s.profile.toJson()), profileBefore);
                expect(jsonEncode(s.seaChart.toJson()), chartBefore);
                expect(preview.currentTier, tier);
                expect(preview.cost, calculateShipUpgradeCost(tier));
                if (tier == 4) {
                  expect(preview.isMaximum, isTrue);
                  expect(
                    preview.stats.every((stat) => stat.next == null),
                    isTrue,
                  );
                  continue;
                }
                final missingHull = ship.maxHp - ship.currentHp;
                final events = s.dispatch(const UpgradeShip());
                expect(events.whereType<ShipUpgraded>(), hasLength(1));
                expect(ship.level, preview.nextTier);
                expect(ship.gold, 1000 - preview.cost);
                expect(ship.maxHp - ship.currentHp, missingHull);
                final values = <String, String>{
                  'hull': '${ship.currentHp}/${ship.maxHp}',
                  'evasion': '${ship.baseEvasion}%',
                  'reduction': '${ship.baseDmgReduction}',
                  'fortify': '+${ship.fortifyDamageReductionGain}',
                  'trap': '${ship.tetherTrapDamage}',
                  for (final (i, weapon) in ship.equippedWeapons.indexed)
                    'weapon-$i': '${weapon.damage}',
                };
                for (final stat in preview.stats) {
                  expect(
                    stat.next,
                    values[stat.id],
                    reason: '${stat.label}, Mk $mark, ancestral $ancestralTier',
                  );
                  expect(stat.current, isNot(stat.next));
                }
                expect(ship.markForHardpoint(HardpointType.utility), mark);
                expect(ship.blessings.length, 3);
                expect(
                  preview.stats.any(
                    (stat) =>
                        stat.label.contains('weight') ||
                        stat.label.contains('Armor Class'),
                  ),
                  isFalse,
                );
              }
            }
          }
        },
      );
    }
  }

  test('capped evasion does not advertise a gain and level-scaled utility is included', () {
    final ship = createFlagshipFromBlueprint(
      BlueprintId.corsair,
      rng: SeededGameRng(4),
    )..baseEvasion = 50;
    temperShipHardpoint(ship, HardpointType.utility);
    final preview = HullUpgradePreview(ship);
    expect(preview.stats.any((stat) => stat.id == 'evasion'), isFalse);
    final trap = preview.stats.singleWhere((stat) => stat.id == 'trap');
    expect(trap.current, '19');
    expect(trap.next, '25');
  });
}
