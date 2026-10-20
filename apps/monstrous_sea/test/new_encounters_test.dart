import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/screens/shrine_screen.dart';
import 'package:monstrous_sea/src/screens/smuggler_screen.dart';

void main() {
  group('New Encounter UI Screens', () {
    testWidgets('SmugglerScreen renders contraband wares, handles repair, and departs',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = GameController(
        session: GameSession(rng: SeededGameRng(123)),
      );

      controller.dispatch(const NameCaptain('Sparrow'));
      controller.dispatch(const ChooseShip(ShipClass.standard));

      controller.ship!.currentHp = 50;
      controller.ship!.gold = 200;

      // Position right before Smuggler
      controller.seaChart.currentRow = 1;
      controller.seaChart.currentCol = 1;
      controller.seaChart.setNodeTypeAt(1, 2, EncounterNodeType.smugglerTrader);
      controller.session.phase = SessionPhase.restArea;

      controller.dispatch(const AdvanceToNextBattle());
      expect(controller.phase, SessionPhase.smuggler);

      await tester.pumpWidget(MaterialApp(
        home: SmugglerScreen(
          controller: controller,
          onOpenChart: () {},
        ),
      ));
      await tester.pumpAndSettle();

      // Verify header and contraband elements
      expect(find.byType(SmugglerScreen), findsOneWidget);
      expect(find.textContaining('SMUGGLER'), findsWidgets);
      expect(find.textContaining('SEASONED OAK PLANKS'), findsOneWidget);
      expect(find.textContaining('CONTRABAND WARES'), findsOneWidget);

      // Tap Depart button
      controller.seaChart.setNodeTypeAt(1, 3, EncounterNodeType.beastCombat);
      final departFinder = find.text('DEPART SMUGGLER & CONTINUE EXPEDITION');
      expect(departFinder, findsOneWidget);
      await tester.ensureVisible(departFinder);
      await tester.tap(departFinder);
      await tester.pumpAndSettle();

      expect(controller.phase, SessionPhase.helm);
      controller.dispatch(const SteerCourse(NavigationalBearing.deadAhead));
      expect(controller.phase, isNot(equals(SessionPhase.helm)));
    });

    testWidgets('ShrineScreen renders inscription, handles rune consultation, and departs',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = GameController(
        session: GameSession(rng: SeededGameRng(456)),
      );

      controller.dispatch(const NameCaptain('Nemo'));
      controller.dispatch(const ChooseShip(ShipClass.corvette));

      // Position right before Shrine
      controller.seaChart.currentRow = 0;
      controller.seaChart.currentCol = 1;
      controller.seaChart.setNodeTypeAt(0, 2, EncounterNodeType.ancientShrine);
      controller.session.phase = SessionPhase.restArea;

      controller.dispatch(const AdvanceToNextBattle());
      expect(controller.phase, SessionPhase.shrine);

      await tester.pumpWidget(MaterialApp(
        home: ShrineScreen(
          controller: controller,
          onOpenChart: () {},
        ),
      ));
      await tester.pumpAndSettle();

      // Verify inscription and options
      expect(find.byType(ShrineScreen), findsOneWidget);
      expect(find.text('ANCIENT RUNIC INSCRIPTION'), findsOneWidget);
      expect(find.text('READ THE ANCIENT RUNES'), findsOneWidget);
      expect(find.text('1 · CHOOSE A PRIMORDIAL'), findsOneWidget);

      // Tap Consult Runes
      final meditateFinder = find.text('READ THE ANCIENT RUNES');
      await tester.ensureVisible(meditateFinder);
      await tester.tap(meditateFinder);
      await tester.pumpAndSettle();

      expect(controller.hasCommunedAtCurrentShrine, isTrue);
      expect(find.text('COMMUNION COMPLETE'), findsOneWidget);
      expect(find.text('DEPART SHRINE & SET SAIL'), findsOneWidget);

      // Depart shrine
      controller.seaChart.setNodeTypeAt(0, 3, EncounterNodeType.beastCombat);
      final departShrineFinder = find.text('DEPART SHRINE & SET SAIL');
      await tester.ensureVisible(departShrineFinder);
      await tester.tap(departShrineFinder);
      await tester.pumpAndSettle();

      expect(controller.phase, SessionPhase.helm);
      controller.dispatch(const SteerCourse(NavigationalBearing.deadAhead));
      expect(controller.phase, SessionPhase.battle);
    });
  });
}
