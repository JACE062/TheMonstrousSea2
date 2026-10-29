import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/battle/monstrous_sea_battle_game.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/screens/battle_screen.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';
import 'package:monstrous_sea/src/widgets/svg_asset_view.dart';

Future<void> mountBattle(
  WidgetTester tester,
  GameController controller, {
  double textScale = 1.15,
  Key? captureKey,
}) async {
  InkTheme.disableGoogleFonts = true;
  final game = MonstrousSeaBattleGame(
    ship: controller.ship!,
    monster: controller.currentMonster!,
  );
  await tester.runAsync(() async {
    for (final path in [
      SvgAssetView.pathForShip(controller.ship!.shipClass),
      SvgAssetView.pathForSpecies(controller.currentMonster!.species),
    ]) {
      if (path.endsWith('.svg')) {
        await SvgAssetLoader(path).loadBytes(null);
      } else {
        await game.images.load(path);
      }
    }
  });
  await tester.pumpWidget(
    RepaintBoundary(
      key: captureKey,
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: ListenableBuilder(
          listenable: controller,
          builder: (context, child) =>
              BattleScreen(controller: controller, game: game),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
  expect(game.isLoaded, isTrue);
}

void main() {
  testWidgets('Serpent HUD shows effective dodge after Pin and Flare', (
    WidgetTester tester,
  ) async {
    final session = GameSession(rng: SeededGameRng(42));
    final controller = GameController(session: session, autoSave: false);
    controller.dispatch(const NameCaptain('Ahab'));
    controller.dispatch(const ChooseShip(ShipClass.standard));
    controller.dispatch(const VentureOutToSea());
    final monster = createMonster(
      MonsterSpecies.serpent,
      level: 1,
      rng: SeededGameRng(42),
      isApex: true,
    );
    session.currentMonster = monster;
    await mountBattle(tester, controller);
    expect(find.textContaining('Dodge: 30%'), findsOneWidget);
    monster.isPinnedThisTurn = true;
    controller.notify();
    await tester.pump();
    expect(find.textContaining('Dodge: 15%'), findsOneWidget);
    monster.spotterFlareTurns = 1;
    controller.notify();
    await tester.pump();
    expect(find.textContaining('Dodge: 0%'), findsOneWidget);
    monster.tickSpotterFlare();
    monster.isPinnedThisTurn = false;
    controller.notify();
    await tester.pump();
    expect(find.textContaining('Dodge: 30%'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets(
    'BattleScreen renders ship and monster status, and fires weapon volley',
    (WidgetTester tester) async {
      final controller = GameController(
        session: GameSession(rng: SeededGameRng(42)),
        autoSave: false,
      );

      // Commission ship
      controller.dispatch(const NameCaptain('Ahab'));
      controller.dispatch(const ChooseShip(ShipClass.standard));

      // Venture out to sea to initiate battle encounter
      controller.dispatch(const VentureOutToSea());
      expect(controller.phase, SessionPhase.battle);
      expect(controller.currentMonster, isNotNull);

      final monsterName = controller.currentMonster!.name;

      await mountBattle(tester, controller);

      // Verify BattleScreen HUD
      expect(find.byType(BattleScreen), findsOneWidget);
      expect(find.text(controller.ship!.name), findsOneWidget);
      expect(find.text(monsterName), findsOneWidget);
      expect(find.text('Naval Cannon Battery'), findsOneWidget);

      // Fire weapon volley
      await tester.ensureVisible(find.text('Naval Cannon Battery'));
      await tester.tap(find.text('Naval Cannon Battery'));
      // Finish the full volley and enemy response before disposing the scene.
      for (var frame = 0; frame < 100 && controller.isPlayingEvents; frame++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      await tester.pump();
      expect(controller.isPlayingEvents, isFalse);

      // Verify combat log recorded actions
      expect(controller.combatLog.isNotEmpty, isTrue);
    },
  );

  testWidgets('Defeating monster transitions to LootScreen', (
    WidgetTester tester,
  ) async {
    final controller = GameController(
      session: GameSession(rng: _HitRng()),
      autoSave: false,
    );

    controller.dispatch(const NameCaptain('Ahab'));
    controller.dispatch(const ChooseShip(ShipClass.standard));
    controller.dispatch(const VentureOutToSea());

    // Reduce monster HP to 1 and AC to 0 to guarantee hit and defeat on next volley
    final monster = controller.currentMonster!;
    monster.currentHp = 1;
    monster.armorClass = 0;

    await mountBattle(tester, controller);

    // Fire Cannon volley to finish monster
    await tester.ensureVisible(find.text('Naval Cannon Battery'));
    await tester.tap(find.text('Naval Cannon Battery'));
    // Complete the fatal volley and the battle-ending presentation delay.
    for (var frame = 0; frame < 100 && controller.isPlayingEvents; frame++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tester.pump();
    expect(controller.isPlayingEvents, isFalse);

    // Session transitions to loot
    expect(controller.phase, SessionPhase.loot);
  });
}

class _HitRng extends SeededGameRng {
  _HitRng() : super(42);
  @override
  int d100() => 1;
}
