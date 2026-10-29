import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/game_controller.dart';

import 'combat_flow_test.dart' show mountBattle;

void main() {
  for (final width in [360.0, 1280.0]) {
    for (final scale in [1.15, 1.3]) {
      testWidgets(
        'late-region sweep preview updates after severing at $width, scale $scale',
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final session = GameSession(rng: SeededGameRng(42));
          final controller = GameController(session: session, autoSave: false);
          controller.dispatch(const BeginFirstVoyage('Test'));
          final monster = createSquid(level: 12, rng: SeededGameRng(42))
            ..currentIntent = MonsterIntent.fromId(
              MonsterIntentId.squidSweepingTentacles,
            );
          session.currentMonster = monster;
          await mountBattle(tester, controller, textScale: scale);
          expect(find.textContaining('8 Tentacles'), findsOneWidget);
          expect(find.text('LOOKOUT'), findsOneWidget);
          expect(find.text('Sweeping Tentacles'), findsOneWidget);
          expect(find.textContaining('8 x 7 base Blast'), findsNothing);
          Future<void> inspectSweep(String summary) async {
            final inspect = find.byTooltip('Inspect monster intent');
            await tester.ensureVisible(inspect);
            await tester.pump(const Duration(milliseconds: 300));
            await tester.tap(inspect);
            await tester.pump(const Duration(milliseconds: 300));
            expect(find.textContaining(summary), findsOneWidget);
            await tester.tap(find.text('Close'));
            await tester.pump(const Duration(milliseconds: 300));
            expect(find.byType(AlertDialog), findsNothing);
          }

          await inspectSweep('8 x 7 base Blast (up to 56');
          monster.numberOfTentacles = 3;
          controller.notify();
          await tester.pump();
          expect(find.textContaining('3 Tentacles'), findsOneWidget);
          await inspectSweep('3 x 7 base Blast (up to 21');
          monster.numberOfTentacles = 0;
          controller.notify();
          await tester.pump();
          expect(find.text('Hold Line: No direct attack'), findsOneWidget);
          await inspectSweep('NO TENTACLES');
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          controller.dispose();
        },
      );
    }
  }
}
