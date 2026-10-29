import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';
import 'package:monstrous_sea/src/widgets/battle_chronicle_dialog.dart';
import 'package:monstrous_sea/src/widgets/battle_lookout.dart';
import 'package:monstrous_sea/src/widgets/combat_log_view.dart';
import 'package:monstrous_sea/src/widgets/pause_menu.dart';

void main() {
  setUp(() => InkTheme.disableGoogleFonts = true);
  tearDown(() => InkTheme.disableGoogleFonts = false);

  testWidgets('Inspect and Chronicle consume Esc before the Pause host', (
    tester,
  ) async {
    final game = GameController(autoSave: false);
    addTearDown(game.dispose);
    final monster = createSquid(level: 1, rng: SeededGameRng(42))
      ..currentIntent = MonsterIntent.fromId(
        MonsterIntentId.squidSweepingTentacles,
      );
    await tester.pumpWidget(
      MaterialApp(
        theme: InkTheme.themeData,
        home: PauseMenuHost(
          controller: game,
          label: 'Modal fixture',
          child: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  TextButton(
                    onPressed: () => showBattleChronicle(context, game),
                    child: const Text('OPEN CHRONICLE'),
                  ),
                  BattleLookout(
                    monster: monster,
                    currentRange: CombatRange.medium,
                    selectedHelmOrder: HelmOrder.holdLine,
                    conditional: false,
                    isResolving: false,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final opener in [
      find.text('OPEN CHRONICLE'),
      find.byTooltip('Inspect monster intent'),
    ]) {
      await tester.tap(opener);
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(find.text('PAUSED'), findsNothing);
    }
    // Focus returns to the host, whose next Escape remains functional.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('PAUSED'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  Future<void> mount(
    WidgetTester tester,
    GameController controller, {
    CombatLogScrollState? scrollState,
    FocusNode? focusNode,
    double scale = 1.15,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: InkTheme.themeData,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              focusNode: focusNode,
              onPressed: () => showBattleChronicle(
                context,
                controller,
                scrollState: scrollState,
              ),
              child: const Text('OPEN CHRONICLE'),
            ),
          ),
        ),
      ),
    );
  }

  GameController controller() {
    final result = GameController(autoSave: false);
    result.structuredCombatLog.addAll(
      List.generate(
        120,
        (i) => CombatLogEntry(
          message: 'Voyage action $i: The cannon volley strikes the beast.',
          actor: CombatLogActor.ship,
        ),
      ),
    );
    addTearDown(result.dispose);
    return result;
  }

  Finder logScroll() => find.descendant(
    of: find.byType(CombatLogView),
    matching: find.byType(Scrollable),
  );

  testWidgets(
    'latest follows live updates; history survives updates and reopen',
    (tester) async {
      final game = controller();
      final reading = CombatLogScrollState();
      await mount(tester, game, scrollState: reading);
      await tester.tap(find.text('OPEN CHRONICLE'));
      await tester.pumpAndSettle();
      var position = tester.state<ScrollableState>(logScroll()).position;
      expect(position.extentAfter, 0);

      game.structuredCombatLog.add(
        CombatLogEntry(message: 'New live volley', actor: CombatLogActor.ship),
      );
      game.notify();
      await tester.pumpAndSettle();
      expect(position.extentAfter, 0);
      expect(find.text('New live volley').hitTestable(), findsOneWidget);

      await tester.drag(logScroll(), const Offset(0, 250));
      await tester.pumpAndSettle();
      final offset = position.pixels;
      expect(find.text('LATEST MESSAGES'), findsOneWidget);
      game.structuredCombatLog.add(
        CombatLogEntry(
          message: 'New intent while reading',
          actor: CombatLogActor.monster,
        ),
      );
      game.notify();
      await tester.pumpAndSettle();
      expect(position.pixels, closeTo(offset, 0.01));

      await tester.tap(find.byKey(const ValueKey('chronicle-close')));
      await tester.pumpAndSettle();
      expect(find.byType(CombatLogView), findsNothing);
      await tester.tap(find.text('OPEN CHRONICLE'));
      await tester.pumpAndSettle();
      position = tester.state<ScrollableState>(logScroll()).position;
      expect(position.pixels, closeTo(offset, 0.01));
      expect(find.text('LATEST MESSAGES'), findsOneWidget);
      await tester.tap(find.text('LATEST MESSAGES'));
      await tester.pumpAndSettle();
      expect(position.extentAfter, 0);
      expect(
        find.text('New intent while reading').hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Esc closes the modal and restores prior focus', (tester) async {
    final game = controller();
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await mount(tester, game, focusNode: focus);
    focus.requestFocus();
    await tester.pump();
    await tester.tap(find.text('OPEN CHRONICLE'));
    await tester.pumpAndSettle();
    expect(focus.hasFocus, isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(focus.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(360, 600), const Size(1280, 720)]) {
    testWidgets('modal fits $size at large text', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final game = controller();
      await mount(tester, game, scale: 1.6);
      await tester.tap(find.text('OPEN CHRONICLE'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const ValueKey('chronicle-close')).hitTestable(),
        findsOneWidget,
      );
      final log = tester.getRect(find.byType(CombatLogView));
      expect(log.height, greaterThan(200));
      expect(log.width, lessThanOrEqualTo(860));
    });
  }
}
