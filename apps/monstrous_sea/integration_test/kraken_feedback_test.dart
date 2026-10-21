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
    testWidgets('Native Kraken feedback at $scale text', (tester) async {
      final controller = GameController(
        session: GameSession(rng: SeededGameRng(42)),
        autoSave: false,
      );
      controller.dispatch(const NameCaptain('Horatio'));
      controller.dispatch(const ChooseShip(ShipClass.standard));
      controller.dispatch(const VentureOutToSea());
      controller.session.currentMonster = createKraken(rng: SeededGameRng(42))
        ..isObscured = true
        ..currentIntent = MonsterIntent.fromId(
          MonsterIntentId.bossKrakenCatastrophe,
        );
      const key = ValueKey('native-combat-review');
      await mountBattle(tester, controller, textScale: scale, captureKey: key);
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        find.textContaining('Obscurity: -25pp shot accuracy'),
        findsOneWidget,
      );
      expect(find.textContaining('38 base Blast damage'), findsOneWidget);
      expect(tester.takeException(), isNull);
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(key),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/kraken-feedback-native-$scale.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    });
  }
}
