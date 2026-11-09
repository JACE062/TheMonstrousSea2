import 'dart:convert';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/playtest/playtest_host.dart';
import 'package:monstrous_sea/src/screens/helm_screen.dart';
import 'package:monstrous_sea/src/screens/sea_chart_screen.dart';
import 'package:monstrous_sea/src/settings/game_settings.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';
import 'package:monstrous_sea/src/widgets/battle_chronicle_dialog.dart';
import 'package:monstrous_sea/src/widgets/combat_log_view.dart';
import 'package:monstrous_sea/src/widgets/ink_button.dart';
import 'package:monstrous_sea/src/widgets/parchment_scaffold.dart';
import 'package:monstrous_sea/src/widgets/pause_menu.dart';
import 'package:monstrous_sea/src/widgets/voyage_log_view.dart';

import 'chart_focus_ui_test.dart'
    show chartFocusController, mountChartFocus, captureChartFocusProof;

enum LogCase {
  voyageEmpty,
  voyageHistory,
  voyageDetails,
  shoreLog,
  chronicleEmpty,
  chronicleShort,
  chronicleHistory,
  chronicleDetails,
  chronicleReading,
  chronicleLive,
  chronicleResize,
  chronicleWheel,
  chronicleKeyboard,
  chronicleScrollbar,
  voyageKeyboard,
}

const _captain = 'Alexandrina Waverley-Montgomery of the Saltbound Watch';
const _beast = 'Behemoth Mako — Alexandrina Waverley-Montgomery’s Undertaker';
const _detail =
    '$_captain orders the broadside. The iron volley tears through the swell toward $_beast. '
    'Carapace splinters, but the creature turns through the smoke. '
    'The lookout calls a new attack as the crew reloads the guns.';

GameController _fixture(
  LogCase mode, {
  CombatLogActor actor = CombatLogActor.ambient,
  bool critical = true,
}) {
  final c = chartFocusController(legs: 1);
  final state = c.seaChart.toJson();
  final first = Map<String, dynamic>.from((state['voyageLog'] as List).first);
  var index = 0;
  state['voyageLog'] = [
    if (mode != LogCase.voyageEmpty)
      for (var region = 0; region < 3; region++)
        for (var leg = 1; leg <= [11, 13, 15][region]; leg++)
          (() {
            final i = index++;
            final type = EncounterNodeType.values[i % 5];
            final titan = leg == [11, 13, 15][region];
            final wreck = !titan && type == EncounterNodeType.shipwreckSalvage;
            return {
              ...first,
              'regionIndex': region,
              'leg': leg,
              'bearing': NavigationalBearing.values[i % 3].name,
              'nodeType': (titan ? EncounterNodeType.regionTitan : type).name,
              'destination':
                  (titan
                          ? CourseDestination.titan
                          : leg == 5
                          ? CourseDestination.midpointHaven
                          : leg == [10, 12, 14][region]
                          ? (region.isEven
                                ? CourseDestination.repairRefit
                                : CourseDestination.specialistMerchant)
                          : CourseDestination.ordinary)
                      .name,
              'isNemesis': i == 0,
              'isApex': !titan && i.isEven,
              'monsterSpecies':
                  (titan
                          ? [
                              MonsterSpecies.kraken,
                              MonsterSpecies.worldSerpent,
                              MonsterSpecies.ancientLeviathan,
                            ][region]
                          : MonsterSpecies.values[i % 5])
                      .name,
              'combatWon':
                  titan ||
                  type == EncounterNodeType.beastCombat ||
                  (wreck && i.isEven),
              'wreckPassed': wreck && i.isOdd,
              'wreckRecovered': wreck && i.isEven,
              'lookoutCall': 'Recorded call $i. $_detail',
            };
          })(),
  ];
  if (mode == LogCase.voyageDetails) {
    final history = state['voyageLog'] as List;
    state['voyageLog'] = [history.first, history[2]];
  }
  c.seaChart.restoreFromJson(state);
  c.session.phase = mode.name.startsWith('chronicle')
      ? SessionPhase.battle
      : SessionPhase.helm;
  final count = mode == LogCase.chronicleEmpty
      ? 0
      : mode == LogCase.chronicleShort
      ? 3
      : 240;
  c.structuredCombatLog.clear();
  c.structuredCombatLog.addAll([
    for (var i = 0; i < count; i++)
      CombatLogEntry(
        message: i == count - 1 && mode == LogCase.chronicleDetails
            ? 'FULL ACCOUNT\n\n${List.filled(5, _detail).join('\n\n')}\n\nThe last echoes fade beneath the waves.'
            : 'Entry $i. ${List.filled(i % 4 + 1, _detail).join(' ')}',
        actor: i == count - 1 ? actor : CombatLogActor.values[i % 3],
        isCritical: i == count - 1 ? critical : i % 7 == 0,
      ),
  ]);
  return c;
}

String _snapshot(GameController c) => jsonEncode({
  'profile': c.profile.toJson(),
  'ship': c.ship!.toJson(),
  'chart': c.seaChart.toJson(),
  'phase': c.phase.name,
  'monsterHp': c.currentMonster!.currentHp,
  'playing': c.isPlayingEvents,
});

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void _within(Rect rect, Size size) {
  expect(rect.left, greaterThanOrEqualTo(0));
  expect(rect.right, lessThanOrEqualTo(size.width));
  expect(rect.top, greaterThanOrEqualTo(0));
  expect(rect.bottom, lessThanOrEqualTo(size.height));
}

void _readable(WidgetTester tester, Size size, String close) {
  expect(tester.takeException(), isNull);
  final dialog = find.byType(Dialog);
  _within(tester.getRect(dialog), size);
  final button = find.widgetWithText(InkButton, close);
  expect(button.hitTestable(), findsOneWidget);
  _within(tester.getRect(button), size);
  for (final text
      in find
          .descendant(of: dialog, matching: find.byType(RichText))
          .evaluate()) {
    final paragraph = text.renderObject! as RenderParagraph;
    expect(
      paragraph.didExceedMaxLines,
      isFalse,
      reason: paragraph.text.toPlainText(),
    );
    final rect = paragraph.localToGlobal(Offset.zero) & paragraph.size;
    expect(rect.left, greaterThanOrEqualTo(0));
    expect(rect.right, lessThanOrEqualTo(size.width));
  }
}

Finder _chronicleScroll() => find.descendant(
  of: find.byType(CombatLogView),
  matching: find.byType(Scrollable),
);
ScrollPosition _position(WidgetTester tester, Finder finder) =>
    tester.state<ScrollableState>(finder).position;

Future<void> _review(
  WidgetTester tester,
  LogCase mode,
  Size size, {
  double scale = 1.15,
  bool plain = false,
  bool proof = false,
  CombatLogActor actor = CombatLogActor.ambient,
  bool critical = true,
  TargetPlatform platform = TargetPlatform.windows,
}) async {
  final settings = GameSettings.instance;
  final oldPlain = settings.highLegibilityFont;
  settings.setHighLegibilityFont(plain);
  addTearDown(() => settings.setHighLegibilityFont(oldPlain));
  final c = _fixture(mode, actor: actor, critical: critical);
  addTearDown(c.dispose);
  final snapshot = _snapshot(c);
  final beforeLog = List<CombatLogEntry>.of(c.structuredCombatLog);
  final key = GlobalKey();
  final reading = CombatLogScrollState();
  final opener = FocusNode();
  addTearDown(opener.dispose);
  await mountChartFocus(
    tester,
    const SizedBox.shrink(),
    GlobalKey(),
    size,
    scale: scale,
  );
  final voyage = !mode.name.startsWith('chronicle');
  final close = voyage ? 'CLOSE LOGBOOK' : 'CLOSE';
  await tester.pumpWidget(
    RepaintBoundary(
      key: key,
      child: MaterialApp(
        theme: InkTheme.themeData.copyWith(platform: platform),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: PlaytestHost(
          gameBuilder: (_) => const SizedBox.shrink(),
          child: PauseMenuHost(
            controller: c,
            label: 'The Waverley-Montgomery Lineage',
            child: mode == LogCase.shoreLog
                ? SeaChartScreen(
                    seaChart: c.seaChart,
                    ship: c.ship,
                    isInPort: true,
                    onClose: () {},
                  )
                : voyage
                ? HelmScreen(controller: c)
                : ParchmentScaffold(
                    body: Center(
                      child: Builder(
                        builder: (context) => Focus(
                          focusNode: opener,
                          autofocus: true,
                          child: InkButton(
                            label: 'OPEN CHRONICLE',
                            onPressed: () => showBattleChronicle(
                              context,
                              c,
                              scrollState: reading,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final name =
      '${mode.name}-${size.width.toInt()}x${size.height.toInt()}-$scale-${plain ? 'plain' : 'ink'}-${actor.index}-$critical-${platform.name}';
  if (!voyage) {
    opener.requestFocus();
    await tester.pump();
  }
  await _tap(tester, find.text(voyage ? 'VOYAGE LOG' : 'OPEN CHRONICLE'));
  _readable(tester, size, close);
  final closeRect = tester.getRect(find.widgetWithText(InkButton, close));
  if (proof) await captureChartFocusProof(tester, key, '$name-open');
  if (voyage) {
    final scroll = find
        .descendant(of: find.byType(Dialog), matching: find.byType(Scrollable))
        .first;
    final position = _position(tester, scroll);
    expect(position.pixels, 0);
    if (mode == LogCase.voyageKeyboard) {
      Focus.of(tester.element(find.text(close))).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pumpAndSettle();
      expect(
        position.pixels,
        greaterThan(0),
        reason: 'Page Down should scroll the open logbook.',
      );
    }
    if (mode == LogCase.voyageEmpty) {
      expect(find.text('No travelled soundings recorded.'), findsOneWidget);
    } else {
      final records = c.seaChart.voyageLog.reversed;
      for (final record in [
        records.first,
        if (records.length > 19) records.elementAt(19),
        records.last,
      ]) {
        final text =
            'Region ${record.regionIndex + 1} · Leg ${record.leg} · ${record.bearing.displayName}';
        await tester.ensureVisible(find.text(text));
        await tester.pumpAndSettle();
        expect(find.text(text).hitTestable(), findsOneWidget);
        _readable(tester, size, close);
        expect(
          tester.getRect(find.widgetWithText(InkButton, close)),
          closeRect,
        );
      }
      final nemesis = find.descendant(
        of: find.byType(VoyageLogView),
        matching: find.text('NEMESIS'),
      );
      await tester.ensureVisible(nemesis);
      await tester.pumpAndSettle();
      expect(nemesis.hitTestable(), findsOneWidget);
      if (proof) await captureChartFocusProof(tester, key, '$name-oldest');
      // Keep underlying gameplay/chart records unchanged while reading.
      await tester.sendEventToBinding(
        PointerScrollEvent(
          position: tester.getCenter(scroll),
          scrollDelta: const Offset(0, -300),
        ),
      );
      await tester.pumpAndSettle();
      _readable(tester, size, close);
    }
  } else {
    if (mode == LogCase.chronicleEmpty) {
      expect(find.text('The open swell is calm... for now.'), findsOneWidget);
    } else {
      var position = _position(tester, _chronicleScroll());
      expect(position.extentAfter, 0);
      expect(
        find.textContaining(c.structuredCombatLog.last.message),
        findsOneWidget,
      );
      if (mode == LogCase.chronicleDetails) {
        // This account is taller than a compact viewport. Traverse its full
        // text and keep the close action fixed while reading either end.
        final last = find.textContaining(c.structuredCombatLog.last.message);
        final viewport = tester.getRect(_chronicleScroll());
        expect(
          tester.getRect(last).bottom,
          lessThanOrEqualTo(viewport.bottom + 1),
        );
        await tester.ensureVisible(last);
        await tester.pumpAndSettle();
        expect(
          tester.getRect(last).top,
          greaterThanOrEqualTo(tester.getRect(_chronicleScroll()).top - 1),
        );
        _readable(tester, size, close);
        expect(
          tester.getRect(find.widgetWithText(InkButton, close)),
          closeRect,
        );
        if (proof) {
          await captureChartFocusProof(tester, key, '$name-detail-start');
        }
      }
      if ([
        LogCase.chronicleReading,
        LogCase.chronicleLive,
        LogCase.chronicleResize,
        LogCase.chronicleWheel,
        LogCase.chronicleKeyboard,
        LogCase.chronicleScrollbar,
      ].contains(mode)) {
        final initial = position.pixels;
        if (mode == LogCase.chronicleWheel) {
          await tester.sendEventToBinding(
            PointerScrollEvent(
              position: tester.getCenter(_chronicleScroll()),
              scrollDelta: const Offset(0, -400),
            ),
          );
        } else if (mode == LogCase.chronicleKeyboard) {
          Focus.of(tester.element(find.text(close))).requestFocus();
          await tester.pump();
          await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
        } else if (mode == LogCase.chronicleScrollbar) {
          final rect = tester.getRect(_chronicleScroll());
          final mouse = await tester.startGesture(
            Offset(rect.right - 4, rect.bottom - 12),
            kind: PointerDeviceKind.mouse,
          );
          await mouse.moveBy(const Offset(0, -160));
          await mouse.up();
        } else {
          await tester.drag(_chronicleScroll(), const Offset(0, 600));
        }
        await tester.pumpAndSettle();
        expect(
          position.pixels,
          lessThan(initial),
          reason: 'History scroll must move the open Chronicle.',
        );
        expect(reading.followingLatest, isFalse);
        final offset = position.pixels;
        final latest = find.widgetWithText(InkButton, 'LATEST MESSAGES');
        expect(latest.hitTestable(), findsOneWidget);
        expect(
          tester.getRect(find.widgetWithText(InkButton, close)),
          closeRect,
        );
        if (proof) await captureChartFocusProof(tester, key, '$name-reading');
        expect(
          tester.getRect(latest).overlaps(tester.getRect(_chronicleScroll())),
          isFalse,
          reason:
              'Return-to-latest control must not cover the text being read.',
        );
        if (mode == LogCase.chronicleLive) {
          c.structuredCombatLog.add(
            const CombatLogEntry(
              message: 'A fresh lookout call arrives.',
              actor: CombatLogActor.ambient,
            ),
          );
          c.notify();
          await tester.pumpAndSettle();
          expect(position.pixels, closeTo(offset, .01));
        }
        if (mode == LogCase.chronicleResize) {
          for (final resized in [const Size(360, 600), size]) {
            tester.view.physicalSize = resized;
            await tester.pumpAndSettle();
            _readable(tester, resized, close);
            expect(reading.followingLatest, isFalse);
          }
        }
        final reopenOffset = position.pixels;
        await _tap(tester, find.byKey(const ValueKey('chronicle-close')));
        await _tap(tester, find.text('OPEN CHRONICLE'));
        position = _position(tester, _chronicleScroll());
        expect(position.pixels, closeTo(reopenOffset, .01));
        expect(reading.followingLatest, isFalse);
        await _tap(tester, find.text('LATEST MESSAGES'));
        expect(position.extentAfter, 0);
        expect(reading.followingLatest, isTrue);
        c.structuredCombatLog.add(
          const CombatLogEntry(
            message: 'The newest volley echoes across the water.',
            actor: CombatLogActor.ship,
          ),
        );
        c.notify();
        await tester.pumpAndSettle();
        expect(position.extentAfter, 0);
        expect(
          find.text('The newest volley echoes across the water.').hitTestable(),
          findsOneWidget,
        );
        expect(find.text('LATEST MESSAGES'), findsNothing);
        if (proof) await captureChartFocusProof(tester, key, '$name-latest');
      }
    }
  }
  await tester.sendKeyEvent(LogicalKeyboardKey.escape);
  await tester.pumpAndSettle();
  expect(find.byType(Dialog), findsNothing);
  expect(find.text('PAUSED'), findsNothing);
  if (!voyage) expect(opener.hasFocus, isTrue);
  expect(_snapshot(c), snapshot);
  expect(
    c.structuredCombatLog.take(beforeLog.length),
    orderedEquals(beforeLog),
  );
  expect(tester.takeException(), isNull);
  await tester.pumpWidget(const SizedBox.shrink());
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
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  const sizes = [Size(360, 900), Size(800, 480), Size(1280, 850)];
  for (final mode in LogCase.values) {
    for (final size in sizes) {
      testWidgets(
        '115% ${mode.name} $size',
        (tester) => _review(
          tester,
          mode,
          size,
          proof: size.width == 360 || mode == LogCase.chronicleReading,
        ),
      );
    }
  }
  for (final mode in LogCase.values) {
    for (final size in sizes) {
      testWidgets(
        'Plain 115% ${mode.name} $size',
        (tester) => _review(tester, mode, size, plain: true),
      );
    }
  }
  for (final plain in [false, true]) {
    for (final mode in [
      LogCase.voyageHistory,
      LogCase.voyageDetails,
      LogCase.shoreLog,
      LogCase.chronicleDetails,
      LogCase.chronicleReading,
      LogCase.chronicleKeyboard,
      LogCase.voyageKeyboard,
    ]) {
      for (final size in sizes) {
        testWidgets(
          '130% $plain ${mode.name} $size',
          (tester) => _review(
            tester,
            mode,
            size,
            scale: 1.3,
            plain: plain,
            proof:
                size.width == 800 &&
                [
                  LogCase.chronicleReading,
                  LogCase.voyageDetails,
                ].contains(mode),
          ),
        );
      }
    }
    for (final scale in [1.15, 1.3]) {
      for (final mode in [
        LogCase.voyageHistory,
        LogCase.chronicleReading,
        LogCase.chronicleDetails,
      ]) {
        testWidgets(
          'Mobile $scale $plain ${mode.name}',
          (tester) => _review(
            tester,
            mode,
            const Size(360, 760),
            scale: scale,
            plain: plain,
            platform: TargetPlatform.android,
          ),
        );
      }
    }
  }
  for (final actor in CombatLogActor.values) {
    for (final critical in [false, true]) {
      if (actor == CombatLogActor.ambient && critical) continue;
      for (final size in sizes) {
        testWidgets(
          'Long account ${actor.name} $critical $size',
          (tester) => _review(
            tester,
            LogCase.chronicleDetails,
            size,
            actor: actor,
            critical: critical,
          ),
        );
      }
    }
  }
}
