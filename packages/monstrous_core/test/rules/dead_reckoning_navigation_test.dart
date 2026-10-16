import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

void main() {
  group('Dead-Reckoning Navigation & Helm Courses', () {
    test('SeaChart generates 3 distinct course options with bearings', () {
      final chart = SeaChart(rng: SeededGameRng(1234));
      final options = chart.ensureCourseOptions(SeededGameRng(1234));

      expect(options.length, equals(3));
      expect(
        options.map((o) => o.bearing).toList(),
        containsAll([
          NavigationalBearing.larboardTack,
          NavigationalBearing.deadAhead,
          NavigationalBearing.starboardTack,
        ]),
      );

      for (final option in options) {
        expect(option.lookoutCall, isNotEmpty);
        expect(option.difficultyLevel, greaterThanOrEqualTo(1));
      }
    });

    test('Steering along headings logs voyage legs into voyageLog', () {
      final chart = SeaChart(rng: SeededGameRng(42));
      expect(chart.currentLeg, equals(0));
      expect(chart.voyageLog, isEmpty);

      // Leg 1: Steer Larboard Tack
      final opt1 = chart.steerCourse(NavigationalBearing.larboardTack);
      expect(chart.currentLeg, equals(1));
      expect(chart.voyageLog.length, equals(1));
      expect(chart.voyageLog.first.bearing, equals(NavigationalBearing.larboardTack));
      expect(chart.voyageLog.first.nodeType, equals(opt1.nodeType));

      // Leg 2: Steer Starboard Tack
      final opt2 = chart.steerCourse(NavigationalBearing.starboardTack);
      expect(chart.currentLeg, equals(2));
      expect(chart.voyageLog.length, equals(2));
      expect(chart.voyageLog[1].bearing, equals(NavigationalBearing.starboardTack));
      expect(chart.voyageLog[1].nodeType, equals(opt2.nodeType));
    });

    test('Leg 5 guarantees convergence on Respite Island Haven as single direct landfall heading', () {
      final chart = SeaChart(rng: SeededGameRng(99));
      chart.currentLeg = 4; // Preparing for leg 5

      final options = chart.generateCourseOptions(SeededGameRng(99));
      expect(options.length, equals(1));
      final opt = options.first;
      expect(opt.bearing, equals(NavigationalBearing.deadAhead));
      expect(opt.nodeType, equals(EncounterNodeType.respiteIsland));
      expect(opt.isIdentified, isTrue);
      expect(opt.lookoutCall, contains('Landfall dead ahead'));
    });

    test('Leg 10 guarantees convergence on Regional Titan as single direct heading', () {
      final chart = SeaChart(rng: SeededGameRng(101));
      chart.currentLeg = 9; // Preparing for leg 10

      final options = chart.generateCourseOptions(SeededGameRng(101));
      expect(options.length, equals(1));
      final opt = options.first;
      expect(opt.bearing, equals(NavigationalBearing.deadAhead));
      expect(opt.nodeType, equals(EncounterNodeType.regionTitan));
      expect(opt.isIdentified, isTrue);
      expect(opt.lookoutCall, isNotEmpty);
    });

    test('GameSession workflow: Port -> Helm -> SteerCourse -> Encounter', () {
      final session = GameSession(rng: SeededGameRng(555));
      session.dispatch(const NameCaptain('Drake'));
      session.dispatch(const ChooseShip(ShipClass.corvette));
      expect(session.phase, equals(SessionPhase.port));

      // Take Helm from Port
      final helmEvents = session.dispatch(const TakeHelm());
      expect(session.phase, equals(SessionPhase.helm));
      expect(helmEvents.whereType<HelmApproached>(), isNotEmpty);
      expect(session.seaChart.currentCourseOptions.length, equals(3));

      // Steer Larboard Tack into Leg 1
      final steerEvents = session.dispatch(
        const SteerCourse(NavigationalBearing.larboardTack),
      );
      expect(session.seaChart.currentLeg, equals(1));
      expect(steerEvents.whereType<CourseSteered>(), isNotEmpty);

      // Verify encounter started
      expect(session.phase, isNot(equals(SessionPhase.helm)));
      expect(session.phase, isNot(equals(SessionPhase.port)));
    });
  });
}
