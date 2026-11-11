import 'dart:convert';

import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

GameSession home(BlueprintId blueprint, int tier) {
  final s = GameSession(rng: SeededGameRng(15));
  s.profile.unlockedBlueprints.addAll(BlueprintId.values.map((b) => b.name));
  s.profile.blueprintArmamentTiers[blueprint.name] = tier;
  s.dispatch(const NameCaptain('Armament witness'));
  s.dispatch(ChooseShip(blueprint.shipClass));
  s.profile.metaInventory.add(
    seaGlass: 100,
    monsterBone: 100,
    krakenBeak: 10,
    serpentScale: 10,
    depthWroughtIron: 100,
    abyssalBarnacles: 100,
  );
  return s;
}

void main() {
  test('next-tier mounted damage preserves rounding and the tier cap', () {
    expect(BlueprintArmamentProgression.damageAfterUpgrade(20, 1), 25);
    expect(BlueprintArmamentProgression.damageAfterUpgrade(23, 2), 27);
    expect(BlueprintArmamentProgression.damageAfterUpgrade(27, 3), 27);
  });
  for (final blueprint in BlueprintId.values) {
    for (final tier in [1, 2]) {
      test(
        '$blueprint tier $tier ancestral purchase changes only the signature',
        () {
          final s = home(blueprint, tier);
          final broadside = s.ship!.equippedWeapons.singleWhere(
            (w) => !w.isSignature,
          );
          final beforeBroadside = jsonEncode(broadside.toJson());
          final signature = s.ship!.equippedWeapons.singleWhere(
            (w) => w.isSignature,
          );
          final beforeDamage = signature.damage;
          final expected =
              (beforeDamage /
                      BlueprintArmamentProgression.damageMultiplierForTier(
                        tier,
                      ) *
                      BlueprintArmamentProgression.damageMultiplierForTier(
                        tier + 1,
                      ))
                  .round();
          final events = s.dispatch(UpgradeBlueprintArmament(blueprint));
          expect(events.whereType<BlueprintArmamentUpgraded>(), hasLength(1));
          expect(s.profile.armamentTierFor(blueprint), tier + 1);
          expect(signature.damage, expected);
          expect(jsonEncode(broadside.toJson()), beforeBroadside);
          expect(s.ship!.markForHardpoint(HardpointType.signature), 1);
        },
      );
    }
  }

  test('inactive ancestral upgrades do not alter the commissioned vessel', () {
    final s = home(BlueprintId.standard, 1);
    final before = jsonEncode(s.ship!.toJson());
    s.dispatch(const UpgradeBlueprintArmament(BlueprintId.ironclad));
    expect(jsonEncode(s.ship!.toJson()), before);
    expect(s.profile.armamentTierFor(BlueprintId.ironclad), 2);
  });

  test(
    'ancestral purchase keeps any existing Standard broadside damage intact',
    () {
      final s = home(BlueprintId.standard, 1);
      final broadside = s.ship!.equippedWeapons.singleWhere(
        (w) => !w.isSignature,
      )..damage = 99;
      s.dispatch(const UpgradeBlueprintArmament(BlueprintId.standard));
      expect(broadside.damage, 99);
    },
  );

  test('home-only, affordability and maximum gates preserve materials on rejection', () {
    final s = home(BlueprintId.standard, 1);
    s.phase = SessionPhase.stronghold;
    final before = jsonEncode(s.profile.toJson());
    expect(
      () => s.dispatch(const UpgradeBlueprintArmament(BlueprintId.standard)),
      throwsStateError,
    );
    expect(jsonEncode(s.profile.toJson()), before);
    s.phase = SessionPhase.port;
    s.profile.metaInventory.seaGlass = 0;
    final poor = jsonEncode(s.profile.toJson());
    expect(
      () => s.dispatch(const UpgradeBlueprintArmament(BlueprintId.standard)),
      throwsStateError,
    );
    expect(jsonEncode(s.profile.toJson()), poor);
    s.profile.blueprintArmamentTiers[BlueprintId.standard.name] = 3;
    final maxed = jsonEncode(s.profile.toJson());
    expect(
      () => s.dispatch(const UpgradeBlueprintArmament(BlueprintId.standard)),
      throwsStateError,
    );
    expect(jsonEncode(s.profile.toJson()), maxed);
  });
}
