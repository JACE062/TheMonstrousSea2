import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';
import 'package:monstrous_sea/src/widgets/combat_stats.dart';
import 'package:monstrous_sea/src/widgets/ink_button.dart';
import 'package:monstrous_sea/src/widgets/mechanic_text.dart';
import 'package:monstrous_sea/src/widgets/parchment_scaffold.dart';
import 'package:monstrous_sea/src/widgets/pause_menu.dart';

import 'chart_focus_ui_test.dart' show mountChartFocus, captureChartFocusProof;

Finder card(String term) => find.byKey(ValueKey('mechanic-help-$term'));

Future<({GlobalKey key, GameController game, int Function() actions})>
mountHelp(WidgetTester tester, double width) async {
  final game = GameController(autoSave: false);
  addTearDown(game.dispose);
  var actions = 0;
  final key = GlobalKey();
  await mountChartFocus(
    tester,
    PauseMenuHost(
      controller: game,
      label: 'Tooltip review',
      child: ParchmentScaffold(
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Stack(
            children: [
              Positioned(
                top: 40,
                left: 0,
                child: SizedBox(
                  width: 180,
                  child: MechanicTooltip(
                    message: 'Applies Static Charge.',
                    child: InkButton(
                      label: 'FITTING A',
                      onPressed: () => actions++,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 400,
                left: 0,
                child: SizedBox(
                  width: 180,
                  child: MechanicTooltip(
                    message: 'Moves one range band away.',
                    child: InkButton(
                      label: 'FITTING B',
                      onPressed: () => actions++,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 700,
                left: 0,
                child: MechanicText('Burning and Critical Hits.'),
              ),
            ],
          ),
        ),
      ),
    ),
    key,
    Size(width, 900),
    scale: 1.15,
  );
  return (key: key, game: game, actions: () => actions);
}

Future<TestGesture> mouseFor(WidgetTester tester) async {
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await mouse.addPointer(location: Offset.zero);
  addTearDown(mouse.removePointer);
  return mouse;
}

Future<void> hover(
  WidgetTester tester,
  TestGesture mouse,
  Finder target,
) async {
  await mouse.moveTo(tester.getCenter(target));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    InkTheme.disableGoogleFonts = const String.fromEnvironment('artFontCache')
        .isEmpty;
    final config = File('.dart_tool/package_config.json').absolute;
    final packages =
        (jsonDecode(await config.readAsString()) as Map)['packages'] as List;
    final testPackage = packages.cast<Map>().singleWhere(
      (p) => p['name'] == 'flutter_test',
    );
    final sdk = Directory.fromUri(
      config.uri.resolve(testPackage['rootUri'] as String),
    ).parent.parent;
    final loader = FontLoader('Roboto');
    for (final face in ['regular', 'bold', 'italic', 'bolditalic']) {
      loader.addFont(
        File('${sdk.path}/bin/cache/artifacts/material_fonts/roboto-$face.ttf')
            .readAsBytes()
            .then(ByteData.sublistView),
      );
    }
    await loader.load();
  });
  for (final width in [360.0, 1280.0]) {
    testWidgets('mouse-clicked linked help closes on leaving at $width', (
      tester,
    ) async {
      final fixture = await mountHelp(tester, width);
      final mouse = await mouseFor(tester);
      await hover(tester, mouse, find.text('FITTING A'));
      await hover(tester, mouse, find.text('Static Charge'));
      await mouse.down(tester.getCenter(find.text('Static Charge').first));
      await mouse.up();
      await tester.pumpAndSettle();
      // Retained focus from navigating a link must not latch mouse help.
      Focus.of(tester.element(find.text('Static Charge').first)).requestFocus();
      await tester.pump();
      await captureChartFocusProof(tester, fixture.key, 'mouse-link-$width');
      await mouse.moveTo(const Offset(4, 890));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(card('Static Charge'), findsNothing);
      expect(card('action'), findsNothing);
      expect(fixture.actions(), 0);
    });
    testWidgets('switching fittings replaces the previous help at $width', (
      tester,
    ) async {
      final fixture = await mountHelp(tester, width);
      final mouse = await mouseFor(tester);
      await hover(tester, mouse, find.text('FITTING A'));
      await hover(tester, mouse, find.text('Static Charge'));
      expect(card('Static Charge'), findsOneWidget);
      await hover(tester, mouse, find.text('FITTING B'));
      expect(card('action'), findsOneWidget);
      expect(card('Static Charge'), findsNothing);
      expect(find.text('Moves one range band away.'), findsOneWidget);
      await mouse.moveTo(const Offset(4, 890));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(card('action'), findsNothing);
      expect(fixture.actions(), 0);
    });
    testWidgets('help has no close icon and keywords look linked at $width', (
      tester,
    ) async {
      final fixture = await mountHelp(tester, width);
      await tester.tap(find.text('Burning'));
      await tester.pumpAndSettle();
      expect(card('Burning'), findsOneWidget);
      expect(find.byTooltip('Close explanation'), findsNothing);
      final label = tester.widget<Text>(find.text('Burning').first);
      expect(label.style!.decoration, TextDecoration.underline);
      await captureChartFocusProof(tester, fixture.key, 'keyword-$width');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(card('Burning'), findsNothing);
      expect(find.text('PAUSED'), findsNothing);
    });
    testWidgets('hover gap, card reading and exit remain stable at $width', (
      tester,
    ) async {
      await mountHelp(tester, width);
      final mouse = await mouseFor(tester);
      await hover(tester, mouse, find.text('FITTING A'));
      final anchor = tester.getRect(
        find.widgetWithText(InkButton, 'FITTING A'),
      );
      final frame = tester.getRect(
        find
            .ancestor(of: card('action'), matching: find.byType(Container))
            .first,
      );
      final gap = frame.left > anchor.right
          ? Offset((frame.left + anchor.right) / 2, anchor.center.dy)
          : Offset(anchor.center.dx, (anchor.bottom + frame.top) / 2);
      await mouse.moveTo(gap);
      await tester.pump(const Duration(milliseconds: 100));
      expect(card('action'), findsOneWidget);
      await hover(tester, mouse, card('action'));
      await tester.pump(const Duration(seconds: 1));
      expect(card('action'), findsOneWidget);
      await mouse.moveTo(const Offset(4, 890));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(card('action'), findsNothing);
    });
    testWidgets('rapid fitting switches leave one branch at $width', (
      tester,
    ) async {
      final fixture = await mountHelp(tester, width);
      final mouse = await mouseFor(tester);
      for (var i = 0; i < 10; i++) {
        await hover(
          tester,
          mouse,
          find.text(i.isEven ? 'FITTING A' : 'FITTING B'),
        );
        expect(card('action'), findsOneWidget);
        expect(
          find.text(
            i.isEven ? 'Applies Static Charge.' : 'Moves one range band away.',
          ),
          i.isEven ? findsNothing : findsOneWidget,
        );
      }
      expect(fixture.actions(), 0);
      await mouse.moveTo(const Offset(4, 890));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(card('action'), findsNothing);
    });
    testWidgets(
      'touch help stays readable and outside tap closes its family at $width',
      (tester) async {
        final fixture = await mountHelp(tester, width);
        await tester.longPress(find.text('FITTING A'));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 1));
        expect(card('action'), findsOneWidget);
        await tester.tap(find.text('Static Charge').first);
        await tester.pumpAndSettle();
        expect(card('Static Charge'), findsOneWidget);
        await tester.tapAt(const Offset(4, 890));
        await tester.pumpAndSettle();
        expect(card('action'), findsNothing);
        expect(card('Static Charge'), findsNothing);
        expect(fixture.actions(), 0);
      },
    );
    testWidgets('F1 and nested keyboard help restore fitting focus at $width', (
      tester,
    ) async {
      final fixture = await mountHelp(tester, width);
      final focus = Focus.of(tester.element(find.text('FITTING A')));
      focus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.f1);
      await tester.pumpAndSettle();
      expect(card('action'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(card('Static Charge'), findsOneWidget);
      for (final term in ['Static Charge', 'action']) {
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(card(term), findsNothing);
        expect(find.text('PAUSED'), findsNothing);
      }
      expect(focus.hasPrimaryFocus, isTrue);
      expect(fixture.actions(), 0);
    });
    testWidgets('help retains an accessible dismiss action at $width', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      try {
        await mountHelp(tester, width);
        await tester.tap(find.text('Burning'));
        await tester.pumpAndSettle();
        final node = tester.getSemantics(
          find.byKey(const ValueKey('mechanic-dismiss-Burning')),
        );
        expect(
          node.getSemanticsData().hasAction(ui.SemanticsAction.dismiss),
          isTrue,
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(card('Burning'), findsNothing);
      } finally {
        handle.dispose();
      }
    });
    testWidgets('mouse long press does not latch help at $width', (
      tester,
    ) async {
      final fixture = await mountHelp(tester, width);
      final mouse = await mouseFor(tester);
      await hover(tester, mouse, find.text('FITTING A'));
      await mouse.down(tester.getCenter(find.text('FITTING A')));
      await tester.pump(const Duration(milliseconds: 700));
      await mouse.up();
      await tester.pumpAndSettle();
      await mouse.moveTo(const Offset(4, 890));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(card('action'), findsNothing);
      expect(fixture.actions(), 0);
    });
    testWidgets('hover help preserves the fitting click at $width', (
      tester,
    ) async {
      final fixture = await mountHelp(tester, width);
      final mouse = await mouseFor(tester);
      await hover(tester, mouse, find.text('FITTING B'));
      await mouse.down(tester.getCenter(find.text('FITTING B')));
      await mouse.up();
      await tester.pumpAndSettle();
      expect(fixture.actions(), 1);
      await mouse.moveTo(const Offset(4, 890));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(card('action'), findsNothing);
    });
    testWidgets('F1 can take over an already hovered fitting at $width', (
      tester,
    ) async {
      final fixture = await mountHelp(tester, width);
      final mouse = await mouseFor(tester);
      await hover(tester, mouse, find.text('FITTING A'));
      final focus = Focus.of(tester.element(find.text('FITTING A')));
      focus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.f1);
      await tester.pumpAndSettle();
      await mouse.moveTo(const Offset(4, 890));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(card('action'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(card('action'), findsNothing);
      expect(focus.hasPrimaryFocus, isTrue);
      expect(fixture.actions(), 0);
    });
  }
  testWidgets('linked siblings replace each other and the whole chain clears', (
    tester,
  ) async {
    final fixture = await mountHelp(tester, 1280);
    final mouse = await mouseFor(tester);
    for (final text in [
      'FITTING A',
      'Static Charge',
      'Arc Discharge',
      'Frenzy',
    ]) {
      await hover(tester, mouse, find.text(text).first);
    }
    expect(card('Frenzy'), findsOneWidget);
    await hover(tester, mouse, find.text('Stun').first);
    expect(card('Frenzy'), findsNothing);
    expect(card('Stun'), findsOneWidget);
    await mouse.moveTo(const Offset(4, 890));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    for (final term in ['action', 'Static Charge', 'Arc Discharge', 'Stun']) {
      expect(card(term), findsNothing);
    }
    expect(fixture.actions(), 0);
  });
  testWidgets('dodge help describes dodge without unrelated fittings', (
    tester,
  ) async {
    final key = GlobalKey();
    await mountChartFocus(
      tester,
      Scaffold(
        body: MonsterCombatStats(
          ship: createFlagshipFromBlueprint(
            BlueprintId.clipper,
            rng: SeededGameRng(3),
          ),
          monster: createSquid(level: 1, rng: SeededGameRng(2)),
        ),
      ),
      key,
      const Size(1280, 900),
      scale: 1.15,
    );
    final mouse = await mouseFor(tester);
    await hover(
      tester,
      mouse,
      find.byKey(const ValueKey('monster-stat-dodge')),
    );
    expect(find.textContaining('Current dodge chance.'), findsOneWidget);
    expect(find.textContaining('Spotter Flare'), findsNothing);
    expect(find.text('Pin'), findsNothing);
  });
}
