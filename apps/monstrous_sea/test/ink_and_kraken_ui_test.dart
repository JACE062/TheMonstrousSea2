import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/game_controller.dart';

import 'combat_flow_test.dart' show mountBattle;

GameController _controller(MonsterSpecies species) {
  final session = GameSession(rng: SeededGameRng(42));
  final controller = GameController(session: session, autoSave: false);
  controller.dispatch(const NameCaptain('Test'));
  controller.dispatch(const ChooseShip(ShipClass.standard));
  controller.dispatch(const VentureOutToSea());
  session.currentMonster =
      createMonster(species, level: 5, rng: SeededGameRng(42))
        ..isObscured = true
        ..currentIntent = MonsterIntent.fromId(
          MonsterIntentId.bossKrakenCatastrophe,
        );
  return controller;
}

void main() {
  for (final width in [360.0, 1280.0]) {
    for (final scale in [1.15, 1.3]) {
      testWidgets('Kraken ink and release at ${width}px, scale $scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = _controller(MonsterSpecies.kraken);
        await mountBattle(tester, controller, textScale: scale);
        expect(
          find.textContaining('Obscurity: -25pp shot accuracy'),
          findsOneWidget,
        );
        expect(find.textContaining('38 base Blast damage'), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Tooltip &&
                widget.message!.contains(
                  'Opening shot accuracy: 60% before 0% target dodge',
                ),
          ),
          findsOneWidget,
        );

        await tester.pumpWidget(const SizedBox.shrink());
        controller.dispose();
      });
    }
  }

  testWidgets('Flare removes ink HUD and updates shot accuracy', (
    tester,
  ) async {
    final controller = _controller(MonsterSpecies.squid);
    controller.session.ship = createFlagshipFromBlueprint(
      BlueprintId.bombardier,
      rng: SeededGameRng(42),
    );
    controller.currentMonster!.currentIntent = MonsterIntent.fromId(
      MonsterIntentId.squidInkShroudRecoil,
    );
    await mountBattle(tester, controller);
    expect(find.textContaining('Obscurity: -20pp'), findsOneWidget);
    controller.dispatch(const ExecuteShipSpecialAction());
    await tester.pump();
    expect(controller.currentMonster!.isObscured, isFalse);
    expect(find.text('OBSCURED'), findsNothing);
    expect(find.textContaining('Obscurity:'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Tooltip &&
            widget.message!.contains('Opening shot accuracy: 95%'),
      ),
      findsWidgets,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  test('real ink deployment log uses accuracy terminology', () {
    final controller = _controller(MonsterSpecies.kraken);
    controller.currentMonster!.isObscured = false;
    controller.currentMonster!.currentIntent = MonsterIntent.fromId(
      MonsterIntentId.squidInkShroudRecoil,
    );
    controller.dispatch(const ExecuteShipSpecialAction());
    final log = controller.combatLog.firstWhere(
      (entry) => entry.contains('dense ink cloud'),
    );
    expect(log, contains('25 percentage points'));
    expect(log, isNot(contains(' AC')));
    controller.dispose();
  });
}
