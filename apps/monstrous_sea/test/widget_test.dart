import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/main.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/screens/captain_screen.dart';
import 'package:monstrous_sea/src/screens/port_screen.dart';
import 'package:monstrous_sea/src/screens/sea_chart_screen.dart';

void main() {
  testWidgets('App renders IntroScreen and navigates to CaptainScreen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GameOrchestratorView(controller: GameController(autoSave: false)),
      ),
    );
    await tester.pump();

    // Verify Intro Screen title
    expect(find.text('THE MONSTROUS SEA'), findsOneWidget);
    expect(find.text('EMBARK UPON THE HUNT'), findsOneWidget);

    // Tap Embark
    await tester.tap(find.text('EMBARK UPON THE HUNT'));
    await tester.pumpAndSettle();

    // Verify Captain Screen
    expect(find.byType(CaptainScreen), findsOneWidget);
    expect(find.text('COMMISSION OF VOYAGE'), findsOneWidget);
  });

  testWidgets(
    'Commissioning ship navigates to PortScreen and opens Sea Chart',
    (WidgetTester tester) async {
      final controller = GameController(
        session: GameSession(rng: SeededGameRng(42)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: GameOrchestratorView(controller: controller, skipIntro: true),
        ),
      );
      await tester.pumpAndSettle();

      // Start with naming captain & choosing ship
      controller.dispatch(const NameCaptain('Captain Barnaby'));
      controller.dispatch(const ChooseShip(ShipClass.standard));
      await tester.pumpAndSettle();

      // Verify Port Screen
      expect(find.byType(PortScreen), findsOneWidget);
      expect(find.text('HUNTER\'S RESPITE'), findsOneWidget);
      expect(find.text('VENTURE OUT TO SEA'), findsOneWidget);

      // Tap SEA CHART
      await tester.ensureVisible(find.text('SEA CHART'));
      await tester.tap(find.text('SEA CHART'));
      await tester.pumpAndSettle();

      // Verify Sea Chart Screen
      expect(find.byType(SeaChartScreen), findsOneWidget);
      expect(find.text('NAUTICAL SEA CHART'), findsOneWidget);

      // Close Sea Chart
      await tester.ensureVisible(find.text('CLOSE SEA CHART'));
      await tester.tap(find.text('CLOSE SEA CHART'));
      await tester.pumpAndSettle();

      expect(find.byType(PortScreen), findsOneWidget);
    },
  );
}
