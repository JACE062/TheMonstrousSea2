import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/playtest/playtest_config.dart';
import 'package:monstrous_sea/src/services/storage_service.dart';

void main() {
  for (final blueprint in BlueprintId.values) {
    for (var region = 0; region < 3; region++) {
      test(
        '$blueprint can fight the real region $region Titan with its selected build',
        () {
          final controller = createPlaytestController(
            PlaytestConfig(
              blueprint: blueprint,
              hullTier: 3,
              armamentTier: 2,
              gold: 1234,
              region: region,
              destination: PlaytestDestination.titan,
              hardpoints: const {
                HardpointType.broadside: PlaytestHardpoint(
                  mark: 3,
                  power: OceanPower.magmaVentLord,
                  blessingTier: 1,
                ),
                HardpointType.signature: PlaytestHardpoint(
                  mark: 2,
                  power: OceanPower.brinemother,
                  blessingTier: 2,
                ),
                HardpointType.utility: PlaytestHardpoint(
                  mark: 3,
                  power: OceanPower.earthshakerTitan,
                  blessingTier: 3,
                ),
              },
            ),
          );
          addTearDown(controller.dispose);
          final ship = controller.ship!;
          expect(controller.autoSave, isFalse);
          expect(controller.phase, SessionPhase.battle);
          expect(controller.seaChart.currentRegionIndex, region);
          expect(controller.seaChart.currentLeg, controller.seaChart.totalLegs);
          expect(controller.seaChart.isRegionTitan, isTrue);
          expect(
            controller.currentMonster!.species,
            [
              MonsterSpecies.kraken,
              MonsterSpecies.worldSerpent,
              MonsterSpecies.ancientLeviathan,
            ][region],
          );
          expect(controller.currentMonster!.currentIntent, isNotNull);
          expect(
            controller.lastEvents.whereType<BattleStarted>(),
            hasLength(1),
          );
          expect(ship.blueprintId, blueprint.name);
          expect(ship.level, 3);
          expect(ship.gold, 1234);
          expect(ship.currentHp, ship.maxHp);
          expect(ship.markForHardpoint(HardpointType.broadside), 3);
          expect(ship.markForHardpoint(HardpointType.signature), 2);
          expect(ship.markForHardpoint(HardpointType.utility), 3);
          expect(ship.blessings[HardpointType.signature]!.tier, 2);
          expect(
            ship.blessings[HardpointType.utility]!.power,
            OceanPower.earthshakerTitan,
          );
          expect(controller.profile.armamentTierFor(blueprint), 2);
          if (region == 1) {
            expect(controller.currentMonster!.isObscured, isTrue);
            expect(ship.currentEvasion, (ship.baseEvasion - 10).clamp(0, 100));
          }
          // Normal rewards and region/ending routing continue after the shortcut.
          controller.currentMonster!.currentHp = 0;
          controller.dispatch(
            FireWeaponVolley(ship.equippedWeapons.first.weaponType),
          );
          expect(controller.phase, SessionPhase.loot);
          controller.dispatch(const LeaveRemainingLoot());
          expect(
            controller.phase,
            region == 2
                ? SessionPhase.expeditionVictory
                : SessionPhase.stronghold,
          );
          expect(ship.blessings[HardpointType.signature]!.tier, 2);
          expect(controller.profile.lineageTracker.history, isEmpty);
        },
      );
    }
  }

  for (var region = 0; region < 3; region++) {
    test('region $region starts at the helm with the chosen build intact', () {
      final controller = createPlaytestController(
        PlaytestConfig(
          blueprint: BlueprintId.clipper,
          hullTier: 4,
          region: region,
          hardpoints: const {
            HardpointType.utility: PlaytestHardpoint(
              mark: 2,
              power: OceanPower.tempestSovereign,
              blessingTier: 3,
            ),
          },
        ),
      );
      addTearDown(controller.dispose);
      expect(controller.phase, SessionPhase.helm);
      expect(controller.seaChart.currentRegionIndex, region);
      expect(controller.seaChart.currentLeg, 0);
      expect(controller.currentCourseOptions, hasLength(3));
      expect(controller.ship!.level, 4);
      expect(controller.ship!.markForHardpoint(HardpointType.utility), 2);
      final course = controller.currentCourseOptions.first;
      controller.dispatch(SteerCourse(course.bearing));
      expect(controller.seaChart.currentLeg, 1);
      expect(controller.ship!.blessings[HardpointType.utility]!.tier, 3);
    });
  }

  test(
    'temper controls alter weapon damage, rather than only the mark label',
    () {
      final base = createPlaytestController(
        PlaytestConfig(destination: PlaytestDestination.titan),
      );
      final tempered = createPlaytestController(
        PlaytestConfig(
          destination: PlaytestDestination.titan,
          hardpoints: const {
            HardpointType.broadside: PlaytestHardpoint(mark: 3),
            HardpointType.signature: PlaytestHardpoint(mark: 2),
          },
        ),
      );
      addTearDown(base.dispose);
      addTearDown(tempered.dispose);
      final broadside = base.ship!.equippedWeapons
          .firstWhere((w) => !w.isSignature)
          .damage;
      final signature = base.ship!.equippedWeapons
          .firstWhere((w) => w.isSignature)
          .damage;
      expect(
        tempered.ship!.equippedWeapons.firstWhere((w) => !w.isSignature).damage,
        ((broadside * 1.2).round() / 1.2 * 1.4).round(),
      );
      expect(
        tempered.ship!.equippedWeapons.firstWhere((w) => w.isSignature).damage,
        (signature * 1.2).round(),
      );
    },
  );

  test('Caldera shortcut grants only the test Core and both endings work', () {
    for (final choice in CalderaClimaxChoice.values) {
      final controller = createPlaytestController(
        PlaytestConfig(destination: PlaytestDestination.caldera),
      );
      addTearDown(controller.dispose);
      expect(controller.phase, SessionPhase.expeditionVictory);
      expect(controller.seaChart.currentRegionIndex, 2);
      expect(controller.profile.metaInventory.leviathanCore, 1);
      expect(controller.currentMonster, isNull);
      controller.dispatch(ResolveCalderaClimax(choice));
      expect(controller.session.calderaOutcome, choice);
      expect(controller.session.hasReadCalderaOutcome, isFalse);
      controller.dispatch(const AcknowledgeCalderaOutcome());
      expect(controller.session.hasReadCalderaOutcome, isTrue);
    }
  });

  test('relaunch is reproducible and state is independent', () {
    final config = PlaytestConfig(
      region: 1,
      destination: PlaytestDestination.titan,
      seed: 998,
    );
    final first = createPlaytestController(config);
    final second = createPlaytestController(config);
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    expect(
      first.ship!.equippedWeapons.map((w) => w.damage).toList(),
      second.ship!.equippedWeapons.map((w) => w.damage).toList(),
    );
    expect(first.currentMonster!.maxHp, second.currentMonster!.maxHp);
    expect(
      first.currentMonster!.currentIntent!.id,
      second.currentMonster!.currentIntent!.id,
    );
    first.ship!.gold = 0;
    first.profile.hasUnlockedCovenant = true;
    expect(second.ship!.gold, 250);
    expect(second.profile.hasUnlockedCovenant, isFalse);
  });

  test('scenario actions leave the live save root untouched', () async {
    final production = await StorageService.defaultSaveDirectory();
    final controller = createPlaytestController(
      PlaytestConfig(destination: PlaytestDestination.caldera),
    );
    addTearDown(controller.dispose);
    expect(
      controller.storage.baseDirectory!.absolute.path,
      isNot(production.absolute.path),
    );
    expect(
      controller.storage.baseDirectory!.path,
      contains('TheMonstrousSea2_Playtests'),
    );
    controller.dispatch(
      const ResolveCalderaClimax(CalderaClimaxChoice.claimCore),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(
      await Directory(controller.storage.baseDirectory!.path).exists(),
      isFalse,
    );
    expect(controller.autoSave, isFalse);
  });

  test('invalid configuration is rejected before building a session', () {
    expect(() => PlaytestConfig(region: 3), throwsRangeError);
    expect(() => PlaytestConfig(hullTier: 5), throwsRangeError);
    expect(() => PlaytestConfig(gold: -1), throwsRangeError);
    expect(
      () => PlaytestConfig(
        hardpoints: const {
          HardpointType.broadside: PlaytestHardpoint(blessingTier: 4),
        },
      ),
      throwsRangeError,
    );
  });
}
