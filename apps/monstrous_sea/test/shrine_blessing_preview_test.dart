import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/widgets/shrine_blessing_preview.dart';
import 'package:monstrous_sea/src/widgets/mechanic_text.dart';

BlessingEffectComparison stat(ShrineBlessingPreview p, String id) =>
    p.stats.singleWhere((s) => s.id == id);

void main() {
  for (final power in OceanPower.values) {
    for (final slot in blessingHardpoints) {
      for (final tier in [0, 1, 2, 3]) {
        test('$power $slot tier $tier preview agrees with real dedication', () {
          for (final blueprint in BlueprintId.values) {
            for (final region in [0, 1, 2]) {
              final s = GameSession(rng: SeededGameRng(42));
              s.profile.unlockedBlueprints.add(blueprint.name);
              s.dispatch(const NameCaptain('Blessing witness'));
              s.dispatch(ChooseShip(blueprint.shipClass));
              s.phase = SessionPhase.shrine;
              s.shrineManifestedPowers = [power];
              s.ship!.captainBoonId = BloodlineTraitId.skilledCarpenter;
              s.ship!.captainQuirkId = BloodlineTraitId.exactingShipwright;
              s.ship!.currentHp -= 7;
              s.ship!.hardpointMarks[slot] = 3;
              if (tier > 0) {
                s.ship!.blessings[slot] = HardpointBlessing(
                  power: power,
                  slot: slot,
                  tier: tier,
                );
              }
              final before = jsonEncode({
                'profile': s.profile.toJson(),
                'ship': s.ship!.toJson(),
                'chart': s.seaChart.toJson(),
              });
              final preview = ShrineBlessingPreview(
                s.ship!,
                power,
                slot,
                regionIndex: region,
              );
              expect(preview.isLocked, tier == 3);
              expect(preview.next?.tier, tier == 3 ? null : tier + 1);
              expect(preview.displayed.power, power);
              expect(preview.stats, isNotEmpty);
              expect(
                preview.prospectiveShip.captainBoonId,
                s.ship!.captainBoonId,
              );
              expect(
                preview.prospectiveShip.captainQuirkId,
                s.ship!.captainQuirkId,
              );
              expect(
                jsonEncode({
                  'profile': s.profile.toJson(),
                  'ship': s.ship!.toJson(),
                  'chart': s.seaChart.toJson(),
                }),
                before,
              );
              if (tier < 3) {
                expect(preview.stats.every((s) => s.next != s.current), isTrue);
                s.dispatch(AcceptShrineBlessing(power, slot));
                expect(
                  s.ship!.blessings[slot]!.toJson(),
                  preview.next!.toJson(),
                );
                expect(s.ship!.toJson(), preview.prospectiveShip.toJson());
                expect(s.hasCommunedAtCurrentShrine, isTrue);
                final settled = jsonEncode(s.ship!.toJson());
                s.dispatch(AcceptShrineBlessing(power, slot));
                expect(jsonEncode(s.ship!.toJson()), settled);
              } else {
                expect(preview.stats.every((s) => s.next == null), isTrue);
                expect(
                  () => s.dispatch(AcceptShrineBlessing(power, slot)),
                  throwsStateError,
                );
              }
            }
          }
        });
      }
    }
  }
  test('other powers remain locked without a replacement forecast', () {
    final ship = createFlagshipFromBlueprint(
      BlueprintId.standard,
      rng: SeededGameRng(5),
    );
    for (final slot in blessingHardpoints) {
      for (final power in OceanPower.values) {
        ship.blessings[slot] = HardpointBlessing(
          power: power,
          slot: slot,
          tier: 2,
        );
        final other = OceanPower.values.firstWhere((p) => p != power);
        final before = jsonEncode(ship.toJson());
        final preview = ShrineBlessingPreview(ship, other, slot);
        expect(preview.next, isNull);
        expect(preview.displayed.power, power);
        expect(preview.stats.every((s) => s.next == null), isTrue);
        expect(jsonEncode(ship.toJson()), before);
      }
    }
  });
  test('higher existing dedications prevent false shared-potency gains', () {
    for (final power in [
      OceanPower.magmaVentLord,
      OceanPower.tempestSovereign,
      OceanPower.brinemother,
    ]) {
      final ship = createFlagshipFromBlueprint(
        BlueprintId.standard,
        rng: SeededGameRng(5),
      );
      ship.blessings[HardpointType.broadside] = HardpointBlessing(
        power: power,
        slot: HardpointType.broadside,
        tier: 1,
      );
      ship.blessings[HardpointType.signature] = HardpointBlessing(
        power: power,
        slot: HardpointType.signature,
        tier: 3,
      );
      final preview = ShrineBlessingPreview(
        ship,
        power,
        HardpointType.broadside,
      );
      expect(
        preview.stats.any(
          (s) => ['burn-fire', 'arc-shock', 'corroded-damage'].contains(s.id),
        ),
        isFalse,
      );
      expect(
        stat(preview, 'damage').next,
        power == OceanPower.magmaVentLord ? '+20%' : '+18%',
      );
    }
  });
  test('regional Burning, wake amplification and linked help agree', () {
    final ship = createFlagshipFromBlueprint(
      BlueprintId.standard,
      rng: SeededGameRng(5),
    );
    ship.blessings[HardpointType.broadside] = const HardpointBlessing(
      power: OceanPower.magmaVentLord,
      slot: HardpointType.broadside,
      tier: 1,
    );
    ship.blessings[HardpointType.utility] = const HardpointBlessing(
      power: OceanPower.magmaVentLord,
      slot: HardpointType.utility,
      tier: 2,
    );
    final preview = ShrineBlessingPreview(
      ship,
      OceanPower.magmaVentLord,
      HardpointType.utility,
      regionIndex: 2,
    );
    expect(stat(preview, 'burn-fire').current, '12');
    expect(stat(preview, 'burn-fire').next, '18');
    expect(stat(preview, 'wake-burn').next, '+50%');
    expect(
      MechanicContext(
        ship: preview.prospectiveShip,
        blessing: preview.next,
        regionIndex: 2,
      ).explanation('Burning'),
      contains('27 Fire damage'),
    );
  });
  test(
    'intrinsic Mortar shell crush and Culverin penetration are preserved',
    () {
      final mortar = createFlagshipFromBlueprint(
        BlueprintId.bombardier,
        rng: SeededGameRng(5),
      );
      final earth = ShrineBlessingPreview(
        mortar,
        OceanPower.earthshakerTitan,
        HardpointType.signature,
      );
      expect(earth.stats.any((s) => s.id.startsWith('carapace-')), isFalse);
      final clipper = createFlagshipFromBlueprint(
        BlueprintId.clipper,
        rng: SeededGameRng(5),
      );
      final acid = ShrineBlessingPreview(
        clipper,
        OceanPower.brinemother,
        HardpointType.signature,
      );
      expect(stat(acid, 'bypass-0').current, '50%');
      expect(stat(acid, 'bypass-0').next, '100%');
    },
  );
  test(
    'Tier III additions are compared separately from unchanged triggers',
    () {
      final ship = createFlagshipFromBlueprint(
        BlueprintId.standard,
        rng: SeededGameRng(5),
      );
      for (final power in OceanPower.values) {
        ship.blessings[HardpointType.signature] = HardpointBlessing(
          power: power,
          slot: HardpointType.signature,
          tier: 2,
        );
        final preview = ShrineBlessingPreview(
          ship,
          power,
          HardpointType.signature,
        );
        final id = switch (power) {
          OceanPower.magmaVentLord => 'burn-turns',
          OceanPower.tempestSovereign => 'static-hit',
          OceanPower.brinemother => 'unarmored',
          OceanPower.earthshakerTitan => 'windup-stun',
        };
        expect(stat(preview, id).next, switch (power) {
          OceanPower.magmaVentLord => '3 turns',
          OceanPower.tempestSovereign => '3',
          OceanPower.brinemother => '+15%',
          OceanPower.earthshakerTitan => '1 action',
        });
      }
    },
  );
}
