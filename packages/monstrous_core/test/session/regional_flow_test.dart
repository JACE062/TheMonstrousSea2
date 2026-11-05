import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

const _hunts = NavigationTuning(
  huntWeight: 100,
  wreckWeight: 0,
  coveWeight: 0,
  ketchWeight: 0,
  shrineWeight: 0,
  superstitiousExtraShrineWeight: 0,
);

GameSession _reload(GameSession session) {
  final restored = GameSession(
    rng: SeededGameRng(300),
    navigationTuning: _hunts,
    profile: ProfileData.fromJson(session.profile.toJson()),
  );
  VoyageSaveData.fromJson(VoyageSaveData.fromSession(session).toJson())
      .restoreToSession(restored);
  return restored;
}

void main() {
  test(
    'Region 2 leg-4 preview, actual level, poison and victory bounty agree',
    () {
      final session = GameSession(rng: _RewardRng(), navigationTuning: _hunts)
        ..dispatch(const BeginFirstVoyage('Difficulty regression'));
      session.seaChart.advanceRegion(session.rng);
      session.seaChart
        ..currentLeg = 3
        ..currentRow = 3
        ..currentCol = 3;
      session.phase = SessionPhase.restArea;
      session.ship!
        ..maxHp = 1000000
        ..currentHp = 1000000;
      session.dispatch(const TakeHelm());
      final offer = session.seaChart.currentCourseOptions.firstWhere(
        (o) => o.bearing == NavigationalBearing.deadAhead,
      );
      expect(offer.difficultyLevel, 6);
      session.dispatch(SteerCourse(offer.bearing));
      expect(session.currentMonster!.level, 6);
      expect(session.seaChart.isRegionTitan, isFalse);
      session.ship!.addStatus(StatusEffect.poison);
      final response = session.dispatch(const BraceForImpact());
      expect(
        response
            .whereType<StatusEffectTicked>()
            .singleWhere(
              (e) => e.target == CombatSide.ship && e.effectName == 'Poison',
            )
            .damage,
        30,
      );
      final before = session.ship!.gold;
      final expected = calculateVoyageVictoryGold(
        6,
        _RewardRng(),
        isApex: offer.isApex,
      );
      session.currentMonster!.currentHp = 0;
      session.dispatch(const FireWeaponVolley(ShipWeaponType.cannon));
      expect(session.ship!.gold - before, expected);
      expect(session.lastGoldSalvaged, expected);
    },
  );

  test(
    'Nemesis retains saved level for preview, combat and complete bounty',
    () {
      final target = NemesisRecord(
        species: MonsterSpecies.shark,
        baseName: 'Shark',
        moniker: 'Old Red',
        predecessorCaptain: 'Reed',
        regionIndex: 0,
        level: 2,
        bonusHp: 10,
        bonusCarapace: 2,
        bountyGold: 50,
        bountySeaGlass: 2,
        bountyMonsterBone: 2,
        bountyBarnacles: 1,
      );
      final session = GameSession(
        rng: _RewardRng(),
        navigationTuning: _hunts,
        profile: ProfileData(activeNemesis: target),
      )..dispatch(const BeginFirstVoyage('Vendetta'));
      session.activeQuirk = BloodlineTrait.bloodOath;
      session.phase = SessionPhase.restArea;
      session.seaChart.currentLeg = session.seaChart.midpointHavenLeg;
      session.dispatch(const TakeHelm());
      expect(session.seaChart.currentCourseOptions.single.difficultyLevel, 2);
      session.dispatch(const SteerCourse(NavigationalBearing.deadAhead));
      expect(session.currentMonster!.level, 2);
      final before = session.ship!.gold;
      session.currentMonster!.currentHp = 0;
      session.dispatch(const FireWeaponVolley(ShipWeaponType.cannon));
      expect(
        session.ship!.gold - before,
        calculateVoyageVictoryGold(2, _RewardRng(), isApex: true) + 50,
      );
      expect(session.profile.activeNemesis, isNull);
    },
  );
  for (final specialist in [
    CourseDestination.repairRefit,
    CourseDestination.specialistMerchant,
  ]) {
    test(
      'full three-region voyage through $specialist preserves cadence and checkpoints',
      () {
        var session = GameSession(
          rng: SeededGameRng(18),
          navigationTuning: _hunts,
        )..dispatch(const BeginFirstVoyage('Navigator'));
        session.ship!
          ..maxHp = 1000000
          ..currentHp = 1000000;
        for (var region = 0; region < 3; region++) {
          final chart = session.seaChart;
          final seen = <int, CourseDestination>{};
          var titanBattles = 0;
          for (var step = 0; step < 150; step++) {
            final current = session.seaChart;
            if (session.phase == SessionPhase.battle) {
              seen[current.currentLeg] = current.currentDestination;
              expect(session.currentMonster!.level, current.currentDifficulty);
              if (current.isRegionTitan) {
                titanBattles++;
                expect(current.currentLeg, [11, 13, 15][region]);
                expect(
                  session.currentMonster!.species,
                  [
                    MonsterSpecies.kraken,
                    MonsterSpecies.worldSerpent,
                    MonsterSpecies.ancientLeviathan,
                  ][region],
                );
                expect(current.voyageLog.last.difficultyLevel, 5 + region * 4);
              }
              // Resolve a real victory while keeping this a cadence/state test.
              session.currentMonster!.currentHp = 0;
              session.dispatch(const FireWeaponVolley(ShipWeaponType.cannon));
            } else if (session.phase == SessionPhase.loot) {
              session = _reload(session);
              final before = session.profile.metaInventory.toJson();
              session.dispatch(const LeaveRemainingLoot());
              expect(
                session.profile.metaInventory.toJson(),
                before,
                reason:
                    'Continuing a saved victory cannot award the kill twice',
              );
            } else if (session.phase == SessionPhase.restArea) {
              session.dispatch(const TakeHelm());
            } else if (session.phase == SessionPhase.helm) {
              final before = session.seaChart.toJson();
              session = _reload(session);
              expect(session.seaChart.toJson(), before);
              final options = session.seaChart.currentCourseOptions;
              final preferred = options
                  .where(
                    (o) =>
                        o.destination == CourseDestination.midpointHaven ||
                        o.destination == specialist,
                  )
                  .firstOrNull;
              session.dispatch(
                SteerCourse(
                  (preferred ??
                          options.firstWhere(
                            (o) => o.nodeType == EncounterNodeType.beastCombat,
                            orElse: () => options.first,
                          ))
                      .bearing,
                ),
              );
            } else if (session.phase == SessionPhase.respiteIsland) {
              seen[current.currentLeg] = current.currentDestination;
              if (session.isRepairRefitStop) {
                expect(
                  () => session.dispatch(const CareenHullAtIsland()),
                  throwsStateError,
                );
                expect(
                  () => session.dispatch(const DrillGunnersAtIsland()),
                  throwsStateError,
                );
                expect(
                  () => session.dispatch(const ForageShoalsAtIsland()),
                  throwsStateError,
                );
              } else {
                expect(session.isCurrentIslandHaven, isTrue);
                session.dispatch(const DrillGunnersAtIsland());
                session = _reload(session);
                expect(session.hasChosenIslandDuty, isTrue);
                final gold = session.ship!.gold;
                session.dispatch(const ForageShoalsAtIsland());
                expect(session.ship!.gold, gold);
              }
              session.dispatch(const DepartIsland());
            } else if (session.phase == SessionPhase.merchant) {
              seen[current.currentLeg] = current.currentDestination;
              expect(current.currentLeg, current.totalLegs);
              final stock = session.merchantStock
                  .map((item) => item.toJson())
                  .toList();
              session = _reload(session);
              expect(session.merchantReturnPhase, SessionPhase.helm);
              expect(
                session.merchantStock.map((item) => item.toJson()).toList(),
                stock,
              );
              session.dispatch(const LeaveMerchant());
              expect(
                session.seaChart.currentCourseOptions.single.destination,
                CourseDestination.titan,
              );
            } else if (session.phase == SessionPhase.stronghold ||
                session.phase == SessionPhase.expeditionVictory) {
              break;
            } else {
              fail('Unexpected phase ${session.phase}');
            }
          }
          expect(seen.keys.toSet(), {
            for (var leg = 1; leg <= chart.regionTitanLeg; leg++) leg,
          });
          expect(seen[chart.midpointHavenLeg], CourseDestination.midpointHaven);
          expect(seen[chart.totalLegs], specialist);
          expect(titanBattles, 1);
          expect(
            session.phase,
            region < 2
                ? SessionPhase.stronghold
                : SessionPhase.expeditionVictory,
          );
          if (region < 2) {
            session = _reload(session);
            expect(session.seaChart.currentRegionIndex, region + 1);
            expect(session.seaChart.currentLeg, 0);
            session.dispatch(const TakeHelm());
          }
        }
      },
    );
  }

  test('Reckless services are reachable and Vendetta cannot occupy midpoint or preparation', () {
    final session = GameSession(rng: SeededGameRng(3))
      ..dispatch(const BeginFirstVoyage('Reckless'));
    session.activeQuirk = BloodlineTrait.recklessHelmsman;
    session.phase = SessionPhase.restArea;
    session.seaChart.currentLeg = session.seaChart.midpointHavenLeg - 1;
    session.dispatch(const TakeHelm());
    final haven = session.seaChart.currentCourseOptions.singleWhere(
      (o) => o.destination == CourseDestination.midpointHaven,
    );
    expect(session.courseRestriction(haven.bearing), isNull);
    session.dispatch(SteerCourse(haven.bearing));
    expect(session.isCurrentIslandHaven, isTrue);
    session.seaChart.currentLeg = session.seaChart.totalLegs - 1;
    session.seaChart.clearPendingCourses();
    session.dispatch(const DepartIsland());
    expect(session.seaChart.currentCourseOptions, hasLength(2));
    for (final option in session.seaChart.currentCourseOptions) {
      expect(session.courseRestriction(option.bearing), isNull);
      expect(option.isNemesis, isFalse);
    }
  });
}

class _RewardRng extends SeededGameRng {
  _RewardRng() : super(8);
  @override
  int nextInt(int maxExclusive) =>
      maxExclusive == 50 ? 17 : super.nextInt(maxExclusive);
  @override
  int nextIntRange(int minInclusive, int maxInclusive) => minInclusive;
}
