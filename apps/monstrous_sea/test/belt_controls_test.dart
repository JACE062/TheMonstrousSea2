import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/battle/monstrous_sea_battle_game.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/screens/battle_screen.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';
import 'package:monstrous_sea/src/widgets/ink_button.dart';
import 'package:monstrous_sea/src/widgets/svg_asset_view.dart';

const _reviewFontPath = String.fromEnvironment('reviewFontPath');
const _helpKey = ValueKey('belt-help');

Future<void> mountBattle(
  WidgetTester tester,
  GameController controller, {
  double textScale = 1.15,
  Key? captureKey,
}) async {
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
        theme: _reviewFontPath.isEmpty
            ? InkTheme.themeData
            : InkTheme.themeData.copyWith(
                textTheme: InkTheme.themeData.textTheme.apply(
                  fontFamily: 'BeltReview',
                ),
              ),
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

GameController _battle({bool drillmaster = false}) {
  final controller = GameController(
    session: GameSession(rng: SeededGameRng(42)),
    autoSave: false,
  )..dispatch(const BeginFirstVoyage('Belt review'));
  if (drillmaster) controller.session.activeBoon = BloodlineTrait.drillmaster;
  controller.ship!.cargo.clear();
  return controller;
}

Consumable _item(ConsumableType type) =>
    generateConsumable(type, RarityLevel.common);

Finder _button(String label) => find.byWidgetPredicate(
  (widget) => widget is InkButton && widget.label == label,
);

InkButton _control(WidgetTester tester, String label) =>
    tester.widget<InkButton>(_button(label));

String _tooltip(WidgetTester tester, String label) => tester
    .widget<Tooltip>(
      find.ancestor(of: _button(label), matching: find.byType(Tooltip)),
    )
    .message!;

Future<void> _finishPlayback(WidgetTester tester) async {
  // Flame's continuously animated sea prevents pumpAndSettle from settling.
  for (var frame = 0; frame < 6; frame++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
}

Future<void> _dispose(WidgetTester tester, GameController controller) async {
  await tester.pumpWidget(const SizedBox.shrink());
  controller.dispose();
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  if (_reviewFontPath.isEmpty) return;
  // Paint the dialog's completed entrance transition before reading pixels.
  await tester.pump(const Duration(milliseconds: 350));
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final output = File('build/belt-$name.png');
      await output.parent.create(recursive: true);
      await output.writeAsBytes(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

void main() {
  setUpAll(() async {
    InkTheme.disableGoogleFonts = true;
    if (_reviewFontPath.isNotEmpty) {
      await (FontLoader('BeltReview')..addFont(
            File(_reviewFontPath).readAsBytes().then(ByteData.sublistView),
          ))
          .load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    }
  });

  testWidgets(
    'quick belt use targets its cargo index and keeps the round open',
    (tester) async {
      final controller = _battle();
      final treasure = generateTreasure(1);
      final patch = _item(ConsumableType.hullPatchKit);
      final pitch = _item(ConsumableType.alchemicalPitch);
      final ship = controller.ship!;
      ship.cargo.addAll([treasure, patch, pitch]);
      ship.currentHp = ship.maxHp ~/ 2;
      ship.tempAccuracyPenalty = 7;
      final initialHp = ship.currentHp;
      final monsterHp = controller.currentMonster!.currentHp;
      await mountBattle(tester, controller);

      expect(_control(tester, patch.name).compact, isTrue);
      expect(_control(tester, patch.name).subtitle, 'Repair 30% hull');
      expect(_tooltip(tester, patch.name), contains('30% of maximum hull'));
      expect(_tooltip(tester, patch.name), isNot(contains('Single-use')));
      expect(_tooltip(tester, patch.name), isNot(contains('turn')));
      final help = tester.widget<IconButton>(find.byKey(_helpKey));
      expect((help.icon as Icon).icon, Icons.help_outline);
      expect(help.tooltip, 'Belt help');
      expect(
        tester.getRect(find.byKey(_helpKey)).right,
        lessThanOrEqualTo(tester.getRect(_button(patch.name)).left),
      );
      expect(find.textContaining('BELT HELP'), findsNothing);
      expect(
        _control(tester, patch.name).semanticHint,
        _tooltip(tester, patch.name),
      );
      expect(find.text('SINGLE USE · 0T QUICK ACTION'), findsNothing);
      await tester.tap(_button(patch.name));
      await _finishPlayback(tester);

      expect(ship.cargo, [treasure, pitch]);
      expect(ship.currentHp, greaterThan(initialHp));
      expect(controller.session.quickConsumablesUsedThisTurn, 1);
      expect(
        ship.tempAccuracyPenalty,
        7,
        reason: 'A quick item must not resolve the monster turn.',
      );
      expect(controller.currentMonster!.currentHp, monsterHp);
      expect(controller.phase, SessionPhase.battle);
      expect(_control(tester, pitch.name).onPressed, isNull);
      expect(_tooltip(tester, pitch.name).toLowerCase(), contains('limit'));
      expect(
        _tooltip(tester, pitch.name),
        contains('Boost the next volley damage by 25%; hits apply Burn.'),
      );
      expect(_control(tester, pitch.name).semanticLabel, contains(pitch.name));

      await tester.tap(find.byKey(_helpKey));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('TACTICAL BELT'), findsOneWidget);
      expect(find.textContaining('1/1'), findsWidgets);
      expect(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.text(pitch.name),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await _dispose(tester, controller);
    },
  );

  testWidgets(
    'Drillmaster can use a second quick item before quota disables third',
    (tester) async {
      final controller = _battle(drillmaster: true);
      final patch = _item(ConsumableType.hullPatchKit);
      final pitch = _item(ConsumableType.alchemicalPitch);
      final ink = _item(ConsumableType.krakenInkBomb);
      controller.ship!.cargo.addAll([patch, pitch, ink]);
      await mountBattle(tester, controller);
      await tester.tap(_button(patch.name));
      await _finishPlayback(tester);
      expect(_control(tester, pitch.name).onPressed, isNotNull);
      await tester.tap(_button(pitch.name));
      await _finishPlayback(tester);
      expect(controller.ship!.pitchCoatingActive, isTrue);
      expect(controller.session.quickConsumablesUsedThisTurn, 2);
      expect(controller.ship!.cargo, [ink]);
      expect(_control(tester, ink.name).onPressed, isNull);
      await tester.tap(find.byKey(_helpKey));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('2/2'), findsWidgets);
      expect(find.textContaining('Drillmaster'), findsWidgets);
      expect(tester.takeException(), isNull);
      await _dispose(tester, controller);
    },
  );

  testWidgets(
    'depleted items explain their state and help is keyboard accessible',
    (tester) async {
      final controller = _battle();
      final spent = _item(ConsumableType.hullPatchKit)..usesLeft = 0;
      controller.ship!.cargo.add(spent);
      await mountBattle(tester, controller);
      expect(_control(tester, spent.name).onPressed, isNull);
      expect(_tooltip(tester, spent.name).toLowerCase(), contains('spent'));
      expect(
        _control(tester, spent.name).semanticHint!.toLowerCase(),
        contains('spent'),
      );

      bool helpFocused() =>
          FocusManager.instance.primaryFocus?.context
              ?.findAncestorWidgetOfExactType<IconButton>()
              ?.key ==
          _helpKey;
      for (var tab = 0; tab < 30 && !helpFocused(); tab++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      expect(
        helpFocused(),
        isTrue,
        reason: 'Belt rules need a keyboard entry point.',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(helpFocused(), isFalse);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();
      expect(
        helpFocused(),
        isTrue,
        reason: 'Traversal can leave the help button and return to it.',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('TACTICAL BELT'), findsOneWidget);
      expect(find.textContaining('does not end'), findsWidgets);
      expect(find.textContaining('single', findRichText: true), findsWidgets);
      expect(tester.takeException(), isNull);
      await _dispose(tester, controller);
    },
  );

  testWidgets(
    'playback disables items honestly while belt help remains usable',
    (tester) async {
      final controller = _battle();
      final patch = _item(ConsumableType.hullPatchKit);
      controller.ship!.cargo.add(patch);
      await mountBattle(tester, controller);
      await tester.tap(_button('Naval Cannon Battery'));
      await tester.pump();
      expect(_control(tester, patch.name).onPressed, isNull);
      expect(
        _tooltip(tester, patch.name),
        contains('Wait for the current action'),
      );
      expect(
        _control(tester, patch.name).semanticHint,
        contains('Wait for the current action'),
      );
      expect(
        tester.widget<IconButton>(find.byKey(_helpKey)).onPressed,
        isNotNull,
      );
      await tester.tap(find.byKey(_helpKey));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('TACTICAL BELT'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.text(patch.name),
        ),
        findsOneWidget,
      );
      await _finishPlayback(tester);
      expect(controller.ship!.cargo, [patch]);
      expect(tester.takeException(), isNull);
      await _dispose(tester, controller);
    },
  );

  for (final width in [360.0, 1280.0]) {
    for (final scale in [1.15, 1.3]) {
      testWidgets('compact belt and scrollable help fit $width at $scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = _battle();
        final items = [
          ConsumableType.hullPatchKit,
          ConsumableType.unstableTincture,
          ConsumableType.alchemicalPitch,
        ].map(_item).toList();
        controller.ship!.cargo.addAll(items);
        final key = GlobalKey();
        await mountBattle(
          tester,
          controller,
          textScale: scale,
          captureKey: key,
        );
        for (final item in items) {
          expect(_control(tester, item.name).compact, isTrue);
          expect(_control(tester, item.name).subtitle, isNotEmpty);
        }
        expect(find.byKey(_helpKey).hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        await _capture(tester, key, '${width.toInt()}-$scale-actions');
        await tester.tap(find.byKey(_helpKey));
        await tester.pump(const Duration(milliseconds: 300));
        final dialog = find.byType(Dialog);
        expect(find.text('TACTICAL BELT'), findsOneWidget);
        expect(
          find.descendant(of: dialog, matching: find.byType(Scrollable)),
          findsWidgets,
        );
        await _capture(tester, key, '${width.toInt()}-$scale-help');
        final lastItem = find.descendant(
          of: dialog,
          matching: find.text(items.last.name),
        );
        await tester.ensureVisible(lastItem);
        await tester.pump();
        expect(lastItem.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        await _capture(tester, key, '${width.toInt()}-$scale-help-bottom');
        await _dispose(tester, controller);
      });
    }
  }

  for (final width in [360.0, 1280.0]) {
    testWidgets('all six item effects stay available in help at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = _battle();
      // Deliberately exceed normal belt capacity to stress every effect label.
      final items = ConsumableType.values.map(_item).toList();
      controller.ship!.cargo.addAll(items);
      final key = GlobalKey();
      await mountBattle(tester, controller, textScale: 1.3, captureKey: key);
      for (final item in items) {
        expect(
          _control(tester, item.name).semanticHint,
          _tooltip(tester, item.name),
        );
        expect(_tooltip(tester, item.name), isNot(contains('Single-use')));
        expect(_tooltip(tester, item.name), isNot(contains('quick items used')));
      }
      expect(tester.takeException(), isNull);
      await _capture(tester, key, '${width.toInt()}-1.3-all-actions');
      await tester.tap(find.byKey(_helpKey));
      await tester.pump(const Duration(milliseconds: 300));
      final dialog = find.byType(Dialog);
      for (final item in items) {
        final name = find.descendant(
          of: dialog,
          matching: find.text(item.name),
        );
        await tester.ensureVisible(name);
        await tester.pump();
        expect(name.hitTestable(), findsOneWidget);
      }
      await _capture(tester, key, '${width.toInt()}-1.3-all-help-bottom');
      expect(tester.takeException(), isNull);
      await _dispose(tester, controller);
    });
  }
}
