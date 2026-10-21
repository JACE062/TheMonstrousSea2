import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/screens/helm_screen.dart';

void main() {
  group('HelmScreen Widget Tests', () {
    testWidgets('renders quarterdeck header, prevailing gale, and 3 course options',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = GameController(
        session: GameSession(rng: SeededGameRng(777)),
        autoSave: false,
      );

      controller.dispatch(const NameCaptain('Ahab'));
      controller.dispatch(const ChooseShip(ShipClass.standard));

      // Transition to Helm
      controller.dispatch(const TakeHelm());
      expect(controller.phase, SessionPhase.helm);
      expect(controller.currentCourseOptions.length, equals(3));

      var chartOpened = false;

      await tester.pumpWidget(MaterialApp(
        home: HelmScreen(
          controller: controller,
          onOpenChart: () => chartOpened = true,
        ),
      ));
      await tester.pumpAndSettle();

      // Verify quarterdeck header and gale notice
      expect(find.text('THE QUARTERDECK • SETTING COURSE'), findsOneWidget);
      expect(find.textContaining('PREVAILING OFFSHORE GALE'), findsOneWidget);
      expect(find.textContaining('LOOKOUT OBSERVATIONS & COURSES'), findsOneWidget);

      // Verify the 3 headings
      expect(find.textContaining('LARBOARD TACK'), findsOneWidget);
      expect(find.textContaining('DEAD AHEAD'), findsOneWidget);
      expect(find.textContaining('STARBOARD TACK'), findsOneWidget);

      // Test chart consultation
      final chartFinder = find.text('CONSULT SEA CHART');
      expect(chartFinder, findsOneWidget);
      await tester.tap(chartFinder);
      await tester.pumpAndSettle();
      expect(chartOpened, isTrue);

      // Tap steer on the Dead Ahead course
      final steerButtons = find.text('STEER THIS HEADING');
      expect(steerButtons, findsNWidgets(3));
      await tester.ensureVisible(steerButtons.at(1));
      await tester.tap(steerButtons.at(1));
      await tester.pumpAndSettle();

      // Verify course was steered and encounter begun
      expect(controller.phase, isNot(equals(SessionPhase.helm)));
      expect(controller.seaChart.currentLeg, equals(1));
      expect(controller.voyageLog.length, equals(1));
    });
  });
}
