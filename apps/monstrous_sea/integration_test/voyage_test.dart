import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/main.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/screens/battle_screen.dart';
import 'package:monstrous_sea/src/screens/captain_screen.dart';
import 'package:monstrous_sea/src/screens/intro_screen.dart';
import 'package:monstrous_sea/src/screens/loot_screen.dart';
import 'package:monstrous_sea/src/screens/port_screen.dart';
import 'package:monstrous_sea/src/screens/rest_screen.dart';
import 'package:monstrous_sea/src/screens/sea_chart_screen.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';

/// Hit rolls are fixed so this smoke test checks UI transitions, not balance.
class _VoyageRng extends SeededGameRng {
  _VoyageRng() : super(42);
  @override
  int d100() => 1;
}

Future<void> _animate(WidgetTester tester, [int frames = 10]) async {
  for (var frame = 0; frame < frames; frame++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  InkTheme.disableGoogleFonts = true;

  testWidgets(
    'First voyage: prologue, captain name, Standard combat, loot, rest and accurate chart',
    (tester) async {
      // Isolate the test from the player's real profile and checkpoint files.
      final controller = GameController(
        session: GameSession(rng: _VoyageRng()),
        autoSave: false,
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(MonstrousSeaApp(controller: controller));
      await tester.pump();
      expect(find.byType(IntroScreen), findsOneWidget);
      await tester.tap(find.text('EMBARK UPON THE HUNT'));
      await _animate(tester, 3);
      expect(find.byType(CaptainScreen), findsOneWidget);
      expect(find.text('CHOOSE STARTING VESSEL'), findsNothing);
      await tester.enterText(find.byType(TextField), 'Captain Horatio');
      await tester.ensureVisible(find.text('BEGIN FIRST VOYAGE'));
      await tester.tap(find.text('BEGIN FIRST VOYAGE'));
      await _animate(tester);
      expect(controller.ship!.resolvedBlueprintId, BlueprintId.standard);
      expect(controller.seaChart.currentLeg, 1);
      expect(find.byType(PortScreen), findsNothing);
      expect(find.byType(BattleScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('emergency-pass')), findsNothing);

      for (
        var round = 0;
        round < 15 && controller.phase == SessionPhase.battle;
        round++
      ) {
        await tester.tap(find.text('Naval Cannon Battery'));
        await _animate(tester);
      }
      expect(controller.phase, SessionPhase.loot);
      expect(find.byType(LootScreen), findsOneWidget);
      // Leave spoils through the real action so the test does not depend on drops.
      final proceed = find.text(
        controller.pendingLoot.isEmpty
            ? 'PROCEED TO NEXT REST'
            : 'LEAVE LEFTOVER & PROCEED',
      );
      await tester.ensureVisible(proceed);
      await tester.tap(proceed);
      await _animate(tester, 3);
      expect(find.byType(RestScreen), findsOneWidget);
      await tester.ensureVisible(find.text('CONSULT SEA CHART'));
      await tester.tap(find.text('CONSULT SEA CHART'));
      await _animate(tester, 3);
      expect(find.byType(SeaChartScreen), findsOneWidget);
      expect(find.text('DEFEATED'), findsOneWidget);
      expect(find.text('VESSEL'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
