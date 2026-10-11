import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/screens/battle_screen.dart';

void main() {
  testWidgets('BattleScreen renders ship and monster status, and fires weapon volley',
      (WidgetTester tester) async {
    final controller = GameController(session: GameSession(rng: SeededGameRng(42)));

    // Commission ship
    controller.dispatch(const NameCaptain('Ahab'));
    controller.dispatch(const ChooseShip(ShipClass.standard));

    // Venture out to sea to initiate battle encounter
    controller.dispatch(const VentureOutToSea());
    expect(controller.phase, SessionPhase.battle);
    expect(controller.currentMonster, isNotNull);

    final monsterName = controller.currentMonster!.name;

    await tester.pumpWidget(
      MaterialApp(
        home: BattleScreen(controller: controller),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Verify BattleScreen HUD
    expect(find.byType(BattleScreen), findsOneWidget);
    expect(find.text(controller.ship!.name), findsOneWidget);
    expect(find.text(monsterName), findsOneWidget);
    expect(find.text('Cannon (2/2)'), findsOneWidget);

    // Fire weapon volley
    await tester.tap(find.text('Cannon (2/2)'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // Verify combat log recorded actions
    expect(controller.combatLog.isNotEmpty, isTrue);
  });

  testWidgets('Defeating monster transitions to LootScreen',
      (WidgetTester tester) async {
    final controller = GameController(session: GameSession(rng: SeededGameRng(42)));

    controller.dispatch(const NameCaptain('Ahab'));
    controller.dispatch(const ChooseShip(ShipClass.standard));
    controller.dispatch(const VentureOutToSea());

    // Reduce monster HP to 1 and AC to 0 to guarantee hit and defeat on next volley
    final monster = controller.currentMonster!;
    monster.currentHp = 1;
    monster.armorClass = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: BattleScreen(controller: controller),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Fire Cannon volley to finish monster
    await tester.tap(find.text('Cannon (2/2)'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // Session transitions to loot
    expect(controller.phase, SessionPhase.loot);
  });
}
