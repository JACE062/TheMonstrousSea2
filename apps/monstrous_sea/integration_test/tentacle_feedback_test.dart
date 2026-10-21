import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/game_controller.dart';

import '../test/combat_flow_test.dart' show mountBattle;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  for (final scale in [1.15, 1.3]) {
    testWidgets('Native sweep feedback updates after severing at $scale', (
      tester,
    ) async {
      final controller = GameController(
        session: GameSession(rng: SeededGameRng(42)),
        autoSave: false,
      );
      controller.dispatch(const BeginFirstVoyage('Horatio'));
      final monster = createSquid(level: 5, rng: SeededGameRng(42))
        ..currentIntent = MonsterIntent.fromId(
          MonsterIntentId.squidSweepingTentacles,
        );
      controller.session.currentMonster = monster;
      const key = ValueKey('tentacle-review');
      await mountBattle(tester, controller, textScale: scale, captureKey: key);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('8 x 4 base Blast (up to 32'), findsOneWidget);
      monster.numberOfTentacles = 3;
      controller.notify();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('3 x 4 base Blast (up to 12'), findsOneWidget);
      expect(tester.takeException(), isNull);
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(key),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/tentacle-feedback-native-$scale.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    });
  }
}
