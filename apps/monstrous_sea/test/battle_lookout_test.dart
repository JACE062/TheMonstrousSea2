import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';
import 'package:monstrous_sea/src/widgets/battle_lookout.dart';

MonsterState _monster(MonsterIntentId id) =>
    createSquid(level: 12, rng: SeededGameRng(42))
      ..currentIntent = MonsterIntent.fromId(id);

Future<void> _mount(
  WidgetTester tester,
  MonsterState monster, {
  double width = 1280,
  CombatRange range = CombatRange.medium,
  HelmOrder order = HelmOrder.holdLine,
  bool conditional = false,
  bool resolving = false,
  List<String> actionNotes = const [],
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: InkTheme.themeData,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(1.3)),
        child: child!,
      ),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topRight,
          child: SizedBox(
            width: width < 600 ? width - 24 : 300,
            child: BattleLookout(
              monster: monster,
              currentRange: range,
              selectedHelmOrder: order,
              conditional: conditional,
              isResolving: resolving,
              actionNotes: actionNotes,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => InkTheme.disableGoogleFonts = true);

  for (final width in [360.0, 1280.0]) {
    testWidgets('sweep is compact and details scroll at $width / 130%', (
      tester,
    ) async {
      final monster = _monster(MonsterIntentId.squidSweepingTentacles);
      await _mount(tester, monster, width: width);
      expect(find.text('LOOKOUT'), findsOneWidget);
      expect(find.text('Sweeping Tentacles'), findsOneWidget);
      expect(find.text('Threatens: SHORT • MED'), findsOneWidget);
      expect(
        find.text('Hold Line: Threatened at Medium Range'),
        findsOneWidget,
      );
      expect(find.textContaining('8 x 7 base Blast'), findsNothing);
      await tester.tap(find.byTooltip('Inspect monster intent'));
      await tester.pumpAndSettle();
      expect(find.textContaining('8 x 7 base Blast (up to 56'), findsOneWidget);
      final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
      expect(dialog.backgroundColor, InkTheme.parchmentSurface);
      expect(dialog.surfaceTintColor, Colors.transparent);
      final shape = dialog.shape! as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(4));
      expect(
        shape.side,
        const BorderSide(color: InkTheme.inkPrimary, width: 2),
      );
      expect(
        find.textContaining('Sweep defenses apply to each strike.'),
        findsOneWidget,
      );
      expect(find.byType(SingleChildScrollView), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('charge uses strike range and collision assessment', (
    tester,
  ) async {
    await _mount(
      tester,
      _monster(MonsterIntentId.sharkBreachingLunge),
      order: HelmOrder.advance,
    );
    expect(find.text('Closes one band before attack'), findsOneWidget);
    expect(find.text('Advance: Head-on collision danger'), findsOneWidget);
    await tester.tap(find.byTooltip('Inspect monster intent'));
    await tester.pumpAndSettle();
    expect(find.textContaining('At strike: Short Range'), findsOneWidget);
    expect(find.textContaining('+30% Impact'), findsOneWidget);
  });

  testWidgets('recoil distinguishes strike and end range', (tester) async {
    await _mount(tester, _monster(MonsterIntentId.serpentFangedWhipRecoil));
    expect(find.text('Recoils one band after attack'), findsOneWidget);
    expect(find.text('Hold Line: Threatened at Medium Range'), findsOneWidget);
    await tester.tap(find.byTooltip('Inspect monster intent'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining(
        'At strike: Medium Range\nAfter response: Long Range',
      ),
      findsOneWidget,
    );
  });

  testWidgets('windup and release use the exact displayed intent', (
    tester,
  ) async {
    final monster = _monster(MonsterIntentId.bossKrakenWindup);
    await _mount(tester, monster);
    expect(find.text(monster.currentIntent!.name), findsOneWidget);
    expect(find.text('Windup 1/2 · no strike this turn'), findsOneWidget);
    expect(find.text('Threatens: NEXT TURN: ALL RANGES'), findsOneWidget);
    monster.currentIntent = MonsterIntent.fromId(
      MonsterIntentId.bossKrakenCatastrophe,
    );
    await _mount(tester, monster);
    expect(find.text(monster.currentIntent!.name), findsOneWidget);
    expect(find.text('Release 2/2 · strikes this turn'), findsOneWidget);
    expect(
      find.text('Hold Line: Release threatens all ranges'),
      findsOneWidget,
    );
    expect(find.textContaining('38 base Blast'), findsNothing);
    await tester.tap(find.byTooltip('Inspect monster intent'));
    await tester.pumpAndSettle();
    expect(find.textContaining('38 base Blast damage'), findsOneWidget);
  });

  testWidgets('conditional helm forecast does not promise safety', (
    tester,
  ) async {
    await _mount(
      tester,
      _monster(MonsterIntentId.squidSweepingTentacles),
      order: HelmOrder.fallBack,
      conditional: true,
    );
    expect(
      find.text('Fall Back only: Outside threat at Long Range'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('conditional-range-forecast')),
      findsOneWidget,
    );
    expect(find.textContaining('SAFE'), findsNothing);
    await tester.tap(find.byTooltip('Inspect monster intent'));
    await tester.pumpAndSettle();
    expect(find.textContaining('8 x 7 base Blast (up to 56'), findsOneWidget);
    expect(find.textContaining('Damage estimates precede'), findsOneWidget);
    expect(find.textContaining('Ram closes'), findsNothing);
    expect(find.textContaining('Skirmisher helm'), findsNothing);
  });

  for (final conditional in [false, true]) {
    testWidgets('action notes require conditional context: $conditional', (
      tester,
    ) async {
      const note =
          'Harpoon attacks before pulling. Check its response forecast.';
      await _mount(
        tester,
        _monster(MonsterIntentId.serpentFangedWhipRecoil),
        conditional: conditional,
        actionNotes: [note],
      );
      await tester.tap(find.byTooltip('Inspect monster intent'));
      await tester.pumpAndSettle();
      expect(find.text(note), conditional ? findsOneWidget : findsNothing);
      expect(find.textContaining('Ram closes'), findsNothing);
      expect(find.textContaining('Evasive Rigging opens'), findsNothing);
      expect(find.textContaining('Damage estimates precede'), findsOneWidget);
      expect(find.textContaining('Sweep defenses'), findsNothing);
    });
  }

  for (final intent in [
    MonsterIntentId.bossKrakenWindup,
    MonsterIntentId.serpentFangedWhipRecoil,
  ]) {
    testWidgets('no damage caveat without a damage estimate: $intent', (
      tester,
    ) async {
      await _mount(tester, _monster(intent), range: CombatRange.long);
      await tester.tap(find.byTooltip('Inspect monster intent'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Damage estimates precede'), findsNothing);
      expect(find.textContaining('Sweep defenses'), findsNothing);
      expect(find.text('Counterplay'), findsOneWidget);
    });
  }

  testWidgets('resolution suppresses result forecasts even in inspection', (
    tester,
  ) async {
    await _mount(
      tester,
      _monster(MonsterIntentId.bossKrakenCatastrophe),
      conditional: true,
      resolving: true,
      actionNotes: ['This note must wait for playback.'],
    );
    expect(find.text('Orders resolving…'), findsOneWidget);
    expect(find.textContaining('Hold Line:'), findsNothing);
    expect(
      find.byKey(const ValueKey('conditional-range-forecast')),
      findsNothing,
    );
    await tester.tap(find.byTooltip('Inspect monster intent'));
    await tester.pumpAndSettle();
    expect(find.textContaining('At strike:'), findsNothing);
    expect(find.textContaining('38 base Blast'), findsNothing);
    expect(find.text('This note must wait for playback.'), findsNothing);
  });

  testWidgets('inspection opens by keyboard and Esc returns focus', (
    tester,
  ) async {
    await _mount(
      tester,
      _monster(MonsterIntentId.squidSweepingTentacles),
      width: 360,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
  });
}
