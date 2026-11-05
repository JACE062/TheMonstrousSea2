import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

// Condition/cargo and overflow regressions superseding selectable strongbox,
// timbers and hold rewards live in wreck_lifecycle_test.dart.
GameSession _navigation() => GameSession(rng: SeededGameRng(42))
  ..dispatch(const BeginFirstVoyage('Navigator'))
  ..phase = SessionPhase.restArea;

void main() {
  test(
    'Blood Oath locks alternatives but keeps the Nemesis course available',
    () {
      final session = _navigation();
      session.seaChart.currentLeg = session.seaChart.midpointHavenLeg;
    session.seaChart.currentDestination = CourseDestination.midpointHaven;
      session.activeQuirk = BloodlineTrait.fromId(BloodlineTraitId.bloodOath);
      session.profile.activeNemesis = NemesisRecord.createFromDefeat(
        killer: createShark(level: 2, rng: session.rng),
        captainName: 'Predecessor',
        regionIndex: 0,
        rng: session.rng,
      );
      session.dispatch(const TakeHelm());
      for (final option in session.seaChart.currentCourseOptions) {
        expect(
          session.courseRestriction(option.bearing),
          option.isNemesis ? isNull : contains('Blood Oath'),
        );
      }
    },
  );

  test(
    'course restriction agrees with engine and exempts guaranteed convergence',
    () {
      final session = _navigation();
      session.activeQuirk = BloodlineTrait.fromId(
        BloodlineTraitId.recklessHelmsman,
      );
      session.dispatch(const TakeHelm());
      expect(
        session.courseRestriction(NavigationalBearing.deadAhead),
        contains('Reckless Helmsman'),
      );
      final before = session.seaChart.toJson();
      expect(
        () =>
            session.dispatch(const SteerCourse(NavigationalBearing.deadAhead)),
        throwsStateError,
      );
      expect(session.seaChart.toJson(), before);
      expect(
        session.courseRestriction(NavigationalBearing.larboardTack),
        isNull,
      );
      for (final target in [
        session.seaChart.regionTitanLeg,
      ]) {
        session.seaChart.currentLeg = target - 1;
        session.seaChart.clearPendingCourses();
        session.seaChart.ensureCourseOptions(session.rng);
        expect(session.seaChart.currentCourseOptions, hasLength(1));
        expect(
          session.courseRestriction(NavigationalBearing.deadAhead),
          isNull,
        );
      }
      session.seaChart.currentLeg = session.seaChart.midpointHavenLeg - 1;
      session.seaChart.clearPendingCourses();
      final midpoint = session.seaChart.ensureCourseOptions(session.rng);
      expect(midpoint, hasLength(3));
      final haven = midpoint.singleWhere((o) => o.destination == CourseDestination.midpointHaven);
      expect(session.courseRestriction(haven.bearing), isNull);
      expect(session.courseRestriction(NavigationalBearing.deadAhead), contains('Reckless'));
    },
  );
}
