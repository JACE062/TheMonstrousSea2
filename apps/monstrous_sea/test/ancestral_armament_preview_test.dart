import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/widgets/ancestral_armament_preview.dart';

void main() {
  for (final blueprint in BlueprintId.values) {
    for (final tier in [1, 2, 3]) {
      test(
        '$blueprint tier $tier preview matches active and inactive purchases',
        () {
          final s = GameSession(rng: SeededGameRng(4));
          s.profile.unlockedBlueprints.addAll(
            BlueprintId.values.map((b) => b.name),
          );
          s.profile.blueprintArmamentTiers[blueprint.name] = tier;
          s.dispatch(const NameCaptain('Preview witness'));
          s.dispatch(ChooseShip(blueprint.shipClass));
          s.profile.metaInventory.add(
            seaGlass: 100,
            monsterBone: 100,
            krakenBeak: 10,
            serpentScale: 10,
            depthWroughtIron: 100,
            abyssalBarnacles: 100,
          );
          final profileBefore = jsonEncode(s.profile.toJson());
          final shipBefore = jsonEncode(s.ship!.toJson());
          final preview = AncestralArmamentPreview(
            s.profile,
            blueprint,
            activeShip: s.ship,
          );
          final inactive = AncestralArmamentPreview(s.profile, blueprint);
          expect(jsonEncode(s.profile.toJson()), profileBefore);
          expect(jsonEncode(s.ship!.toJson()), shipBefore);
          expect(inactive.mountedDamage, isEmpty);
          expect(preview.mountedDamage, hasLength(1));
          expect(
            preview.currentMultiplier,
            BlueprintArmamentProgression.damageMultiplierForTier(tier),
          );
          expect(preview.isMaximum, tier == 3);
          if (tier == 3) {
            expect(preview.nextTier, isNull);
            expect(preview.cost, isNull);
            expect(preview.mountedDamage.single.next, isNull);
          } else {
            final expectedInventory = MetaInventory.fromJson(
              s.profile.metaInventory.toJson(),
            );
            expect(expectedInventory.spendCost(preview.cost!), isTrue);
            final broadside = s.ship!.equippedWeapons.singleWhere(
              (w) => !w.isSignature,
            );
            final damageBefore = broadside.damage;
            s.dispatch(UpgradeBlueprintArmament(blueprint));
            expect(s.profile.armamentTierFor(blueprint), preview.nextTier);
            expect(
              s.profile.metaInventory.toJson(),
              expectedInventory.toJson(),
            );
            expect(
              s.ship!.equippedWeapons.singleWhere((w) => w.isSignature).damage,
              preview.mountedDamage.single.next,
            );
            expect(broadside.damage, damageBefore);
            expect(inactive.nextMultiplier, preview.nextMultiplier);
          }
        },
      );
    }
  }

  test(
    'other blueprints never borrow the active ship damage or create a new roll',
    () {
      final ship = createFlagshipFromBlueprint(
        BlueprintId.standard,
        rng: SeededGameRng(6),
      );
      final profile = ProfileData();
      final before = jsonEncode(ship.toJson());
      final preview = AncestralArmamentPreview(
        profile,
        BlueprintId.ironclad,
        activeShip: ship,
      );
      expect(preview.mountedDamage, isEmpty);
      expect(preview.currentMultiplierText, '1.00x');
      expect(preview.nextMultiplierText, '1.25x');
      expect(jsonEncode(ship.toJson()), before);
    },
  );
}
