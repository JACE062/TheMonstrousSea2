import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

const hunts = NavigationTuning(
  huntWeight: 100,
  wreckWeight: 0,
  coveWeight: 0,
  ketchWeight: 0,
  shrineWeight: 0,
  superstitiousExtraShrineWeight: 0,
);
const shrines = NavigationTuning(
  huntWeight: 0,
  wreckWeight: 0,
  coveWeight: 0,
  ketchWeight: 0,
  shrineWeight: 100,
  superstitiousExtraShrineWeight: 0,
);

Map<int, List<CourseOption>> plan(SeaChart chart) =>
    (chart.toJson()['regionalPlan'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(
        int.parse(key),
        (value as List)
            .map(
              (o) => CourseOption.fromJson(Map<String, dynamic>.from(o as Map)),
            )
            .toList(),
      ),
    );

NemesisRecord nemesis(int region) => NemesisRecord(
  species: MonsterSpecies.shark,
  baseName: 'Shark',
  moniker: 'Old Red',
  predecessorCaptain: 'Reed',
  regionIndex: region,
  level: 3 + region * 4,
  bonusHp: 10,
  bonusCarapace: 2,
  bountyGold: 50,
  bountySeaGlass: 2,
  bountyMonsterBone: 2,
  bountyBarnacles: 1,
);

void main() {
  for (var region = 0; region < 3; region++) {
    test(
      'region $region stages deterministic cadence, services and separate Titan',
      () {
        final a = SeaChart(timesCompleted: region, rng: SeededGameRng(17));
        final b = SeaChart(timesCompleted: region, rng: SeededGameRng(17));
        a.ensureCourseOptions(SeededGameRng(99));
        b.ensureCourseOptions(SeededGameRng(99));
        expect(a.toJson(), b.toJson());
        final groups = plan(a);
        expect(groups.length, [11, 13, 15][region]);
        final midpoint = groups[a.midpointHavenLeg]!;
        expect(midpoint, hasLength(3));
        final haven = midpoint.singleWhere(
          (o) => o.destination == CourseDestination.midpointHaven,
        );
        expect(haven.bearing, isNot(NavigationalBearing.deadAhead));
        expect(haven.isIdentified, isTrue);
        expect(
          midpoint.where((o) => o.destination == CourseDestination.ordinary),
          hasLength(2),
        );
        final prep = groups[a.totalLegs]!;
        expect(prep.map((o) => o.destination), [
          CourseDestination.repairRefit,
          CourseDestination.specialistMerchant,
        ]);
        expect(prep.map((o) => o.bearing), [
          NavigationalBearing.larboardTack,
          NavigationalBearing.starboardTack,
        ]);
        expect(prep.every((o) => o.isIdentified && !o.isNemesis), isTrue);
        expect(
          groups[a.regionTitanLeg]!.single.nodeType,
          EncounterNodeType.regionTitan,
        );
        expect(
          groups[a.regionTitanLeg]!.single.difficultyLevel,
          5 + region * 4,
        );
        expect(
          groups.values
              .expand((g) => g)
              .any((o) => o.nodeType == EncounterNodeType.ancientShrine),
          isTrue,
        );
      },
    );

    test(
      'region $region commits offered difficulty for every bearing and reload',
      () {
        for (final bearing in NavigationalBearing.values) {
          final chart = SeaChart(
            timesCompleted: region,
            currentLeg: 2,
            currentRow: 3,
            currentCol: 3,
            rng: SeededGameRng(12),
            tuning: hunts,
          );
          final offers = chart.ensureCourseOptions(SeededGameRng(20));
          final chosen = offers.singleWhere((o) => o.bearing == bearing);
          chart.steerCourse(bearing);
          expect(chart.currentDifficulty, chosen.difficultyLevel);
          expect(chart.currentDifficulty, 2 + region * 4);
          expect(
            chart.isRegionTitan,
            isFalse,
            reason: 'Old boss coordinate is not an encounter authority',
          );
          if (chosen.nodeType == EncounterNodeType.beastCombat) {
            expect(
              chart.currentMonster(SeededGameRng(3)).level,
              chosen.difficultyLevel,
            );
          }
          final restored = SeaChart()..restoreFromJson(chart.toJson());
          expect(restored.currentDifficulty, chart.currentDifficulty);
          expect(
            restored.voyageLog.last.difficultyLevel,
            chart.currentDifficulty,
          );
          expect(restored.toJson(), chart.toJson());
        }
      },
    );

    test(
      'region $region reserves sole Vendetta after midpoint, shrine elsewhere',
      () {
        final target = nemesis(region);
        final chart = SeaChart(timesCompleted: region, tuning: hunts);
        chart.ensureCourseOptions(
          SeededGameRng(42),
          target,
          true,
          false,
          false,
          true,
        );
        final groups = plan(chart);
        final compelled = groups[chart.midpointHavenLeg + 1]!.single;
        expect(compelled.isNemesis, isTrue);
        expect(compelled.bearing, NavigationalBearing.deadAhead);
        expect(compelled.difficultyLevel, target.level);
        expect(
          groups[chart.midpointHavenLeg]!.any((o) => o.isNemesis),
          isFalse,
        );
        expect(groups[chart.totalLegs]!.any((o) => o.isNemesis), isFalse);
        expect(
          groups.values
              .expand((g) => g)
              .where((o) => o.nodeType == EncounterNodeType.ancientShrine),
          hasLength(1),
        );
      },
    );
  }

  test(
    'missing-only shrine correction varies by leg and retains all-hunt groups',
    () {
      final correctedLegs = <int>{};
      for (var seed = 0; seed < 40; seed++) {
        final chart = SeaChart(tuning: hunts);
        chart.ensureCourseOptions(SeededGameRng(seed), null, true);
        final groups = plan(chart);
        final corrected = groups.entries
            .where(
              (e) => e.value.any(
                (o) => o.nodeType == EncounterNodeType.ancientShrine,
              ),
            )
            .single;
        correctedLegs.add(corrected.key);
        expect(corrected.key, isNot(chart.totalLegs));
        expect(
          corrected.value
              .singleWhere((o) => o.nodeType == EncounterNodeType.ancientShrine)
              .lookoutCall,
          contains('fog'),
        );
        expect(
          groups.values.any(
            (g) =>
                g.length == 3 &&
                g.every((o) => o.nodeType == EncounterNodeType.beastCombat),
          ),
          isTrue,
        );
      }
      expect(correctedLegs.length, greaterThan(3));
    },
  );

  test(
    'natural extra shrines survive without correction or extra RNG on reload',
    () {
      final chart = SeaChart(tuning: shrines, currentLeg: 2);
      chart.ensureCourseOptions(SeededGameRng(2));
      final original = chart.toJson();
      expect(
        plan(chart).values
            .expand((g) => g)
            .where((o) => o.nodeType == EncounterNodeType.ancientShrine)
            .length,
        greaterThan(9),
      );
      final restored = SeaChart(tuning: shrines)..restoreFromJson(original);
      expect(restored.ensureCourseOptions(_NoDraw()), hasLength(3));
      expect(restored.toJson(), original);
    },
  );

  test('redraw preserves midpoint service/bearing and original hidden shrine accounting', () {
    final chart = SeaChart(tuning: hunts, currentLeg: 4);
    chart.ensureCourseOptions(SeededGameRng(5));
    final before = chart.toJson()['regionalPlan'];
    final haven = chart.currentCourseOptions.singleWhere(
      (o) => o.destination == CourseDestination.midpointHaven,
    );
    chart.redrawOrdinaryCourses(SeededGameRng(18), null, true, false);
    expect(
      chart.currentCourseOptions.singleWhere(
        (o) => o.destination == CourseDestination.midpointHaven,
      ),
      same(haven),
    );
    expect(chart.toJson()['regionalPlan'], before);
    chart.currentLeg = chart.totalLegs - 1;
    chart.clearPendingCourses();
    chart.ensureCourseOptions(SeededGameRng(8));
    expect(
      () => chart.redrawOrdinaryCourses(SeededGameRng(9), null, false, false),
      throwsStateError,
    );
  });

  test('ordinary Nemesis retains exact side offer on redraw', () {
    final target = nemesis(0);
    final chart = SeaChart(currentLeg: 5);
    chart.ensureCourseOptions(SeededGameRng(30), target);
    final offered = chart.currentCourseOptions.singleWhere((o) => o.isNemesis);
    expect(offered.bearing, isNot(NavigationalBearing.deadAhead));
    chart.redrawOrdinaryCourses(SeededGameRng(8), target, false, true);
    expect(
      chart.currentCourseOptions.singleWhere((o) => o.isNemesis),
      same(offered),
    );
  });

  test('island-departure replacements keep exact future opportunities after reload', () {
    const coves = NavigationTuning(
      huntWeight: 0,
      wreckWeight: 0,
      coveWeight: 100,
      ketchWeight: 0,
      shrineWeight: 0,
      superstitiousExtraShrineWeight: 0,
    );
    final chart = SeaChart(tuning: coves, currentLeg: 2);
    chart.setNodeTypeAt(0, 0, EncounterNodeType.respiteIsland);
    chart.ensureCourseOptions(SeededGameRng(19));
    final expected = chart.currentCourseOptions.map((o) => o.toJson()).toList();
    expect(
      chart.currentCourseOptions.any(
        (o) => o.nodeType == EncounterNodeType.beastCombat,
      ),
      isTrue,
    );
    final restored = SeaChart(tuning: coves)..restoreFromJson(chart.toJson());
    restored.clearPendingCourses();
    expect(
      restored.ensureCourseOptions(_NoDraw()).map((o) => o.toJson()).toList(),
      expected,
    );
  });

  test('runes reveal the stored next-group clues without changing hidden groups or RNG', () {
    final chart = SeaChart(currentLeg: 5);
    chart.ensureCourseOptions(SeededGameRng(33), null, true);
    final original = chart.toJson()['regionalPlan'];
    chart.revealRow(6);
    chart.clearPendingCourses();
    final offered = chart.ensureCourseOptions(_NoDraw());
    expect(offered.every((o) => o.isIdentified), isTrue);
    expect(
      offered.any((o) => o.lookoutCall.contains('completely obscured')),
      isFalse,
    );
    expect(chart.toJson()['regionalPlan'], original);
  });
}

class _NoDraw implements GameRng {
  @override
  int d(int n) => throw StateError('Reload consumed gameplay randomness');
  @override
  int d20() => throw StateError('Reload consumed gameplay randomness');
  @override
  int nextInt(int max) =>
      throw StateError('Reload consumed gameplay randomness');
  @override
  int nextIntRange(int min, int max) =>
      throw StateError('Reload consumed gameplay randomness');
  @override
  int d100() => throw StateError('Reload consumed gameplay randomness');
  @override
  double nextDouble() =>
      throw StateError('Reload consumed gameplay randomness');
}
