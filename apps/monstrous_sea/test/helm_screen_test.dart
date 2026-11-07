import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/screens/helm_screen.dart';

void main() {
  group('HelmScreen Widget Tests', () {
    testWidgets(
      'combines map, region, logbook and three course options',
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

        // Transition to an ordinary heading choice after the opening fight.
        controller.session.phase = SessionPhase.restArea;
        controller.seaChart.currentLeg = 1;
        controller.dispatch(const TakeHelm());
        expect(controller.phase, SessionPhase.helm);
        expect(controller.currentCourseOptions.length, equals(3));

        await tester.pumpWidget(
          MaterialApp(home: HelmScreen(controller: controller)),
        );
        await tester.pumpAndSettle();

        // The header identifies the region without a wind/routing explanation.
        expect(find.text('NAUTICAL SEA CHART'), findsOneWidget);
        expect(find.text(controller.seaChart.currentRegionName), findsOneWidget);
        expect(find.textContaining('FRESH WESTERLIES'), findsNothing);
        expect(
          find.textContaining('LOOKOUT OBSERVATIONS & COURSES'),
          findsOneWidget,
        );

        // Verify the 3 headings
        expect(find.textContaining('LARBOARD TACK'), findsOneWidget);
        expect(find.textContaining('DEAD AHEAD'), findsOneWidget);
        expect(find.textContaining('STARBOARD TACK'), findsOneWidget);

        // Test chart consultation
        expect(find.text('CONSULT SEA CHART'), findsNothing);
        final chartFinder = find.byKey(const ValueKey('helm-voyage-log'));
        expect(chartFinder, findsOneWidget);
        await tester.tap(chartFinder);
        await tester.pumpAndSettle();
        expect(find.text('DEAD-RECKONING VOYAGE LOG'), findsOneWidget);
        await tester.tap(find.text('CLOSE LOGBOOK'));
        await tester.pumpAndSettle();

        // Tap steer on the Dead Ahead course
        final steerButtons = find.text('STEER THIS HEADING');
        expect(steerButtons, findsNWidgets(3));
        await tester.ensureVisible(steerButtons.at(1));
        await tester.tap(steerButtons.at(1));
        await tester.pumpAndSettle();

        // Verify course was steered and encounter begun
        expect(controller.phase, isNot(equals(SessionPhase.helm)));
        expect(controller.seaChart.currentLeg, equals(2));
        expect(controller.voyageLog.length, equals(1));
      },
    );
  });
}
