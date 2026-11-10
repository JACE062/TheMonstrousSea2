import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/main.dart';
import 'package:monstrous_sea/src/battle/monstrous_sea_battle_game.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/playtest/playtest_host.dart';
import 'package:monstrous_sea/src/playtest/playtest_screen.dart';
import 'package:monstrous_sea/src/screens/battle_screen.dart';
import 'package:monstrous_sea/src/screens/lineage_menu_screen.dart';
import 'package:monstrous_sea/src/screens/loot_screen.dart';
import 'package:monstrous_sea/src/screens/merchant_screen.dart';
import 'package:monstrous_sea/src/screens/rest_screen.dart';
import 'package:monstrous_sea/src/screens/shipwreck_screen.dart';
import 'package:monstrous_sea/src/services/lineage_store.dart';
import 'package:monstrous_sea/src/services/storage_service.dart';
import 'package:monstrous_sea/src/settings/game_settings.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';
import 'package:monstrous_sea/src/widgets/ink_button.dart';
import 'package:monstrous_sea/src/widgets/parchment_scaffold.dart';
import 'package:monstrous_sea/src/widgets/pause_menu.dart';
import 'package:monstrous_sea/src/widgets/pilot_art.dart';

import 'battle_art_recovery_test.dart' show ControlledArtworkBundle, combat;
import 'chart_focus_ui_test.dart' show mountChartFocus, captureChartFocusProof;
import 'lineage_menu_test.dart' show MemoryLineages;

enum SweepCase {
  startupLoading,
  startupError,
  lineageLoading,
  lineageOpening,
  lineageBranching,
  lineageBranchError,
  lineageSummaryError,
  lineageExitError,
  cancelLineage,
  rest,
  restCritical,
  restNoShip,
  wreckUnavailable,
  lootEmpty,
  materialsSoldOut,
  battleWaiting,
  artFailed,
  artRetrying,
  playtest,
  playtestInvalid,
  playtestKeyboard,
  playtestChoices,
  playtestActive,
}

class _Binding extends AutomatedTestWidgetsFlutterBinding {
  int exits = 0;
  @override
  Future<ui.AppExitResponse> exitApplication(
    ui.AppExitType type, [
    int exitCode = 0,
  ]) async {
    exits++;
    return ui.AppExitResponse.cancel;
  }
}

class _LoadingController extends GameController {
  _LoadingController() : super(autoSave: false);
  Completer<void>? gate;
  bool fail = false;
  int loads = 0;
  @override
  Future<void> initializeStorage() async {
    loads++;
    await gate?.future;
    if (fail) throw const FileSystemException('Fixture unavailable storage');
  }
}

class _Lineages extends MemoryLineages {
  Completer<void>? loadGate, openGate, branchGate;
  bool longSummary = false;
  @override
  Future<LineageCatalog> load() async {
    await loadGate?.future;
    return super.load();
  }

  @override
  Future<StorageService> open(String id) async {
    await openGate?.future;
    throw const FileSystemException('Fixture cancelled opening');
  }

  @override
  Future<LineageSlot> exploreOtherFate(String sourceId) async {
    branchCalls++;
    await branchGate?.future;
    throw const FileSystemException('Fixture branch unavailable');
  }

  @override
  Future<List<LineageSummary>> summaries() async {
    final original = await super.summaries();
    if (!longSummary) return original;
    return [
      for (final summary in original)
        LineageSummary(
          summary.slot,
          profile: summary.profile,
          error: 'This lineage could not be read. The existing save has been preserved. Retry to load the Waverley-Montgomery family’s recorded voyage again.',
        ),
    ];
  }
}

String _menuSnapshot(_Lineages store) => jsonEncode({
  'active': store.active,
  'slots': store.slots.map((s) => s.toJson()).toList(),
  'saves': {
    for (final entry in store.saves.entries)
      entry.key: {
        'profile': entry.value.profile.toJson(),
        'voyage': entry.value.voyage?.toJson(),
        'writes': entry.value.writes,
      },
  },
});
String _snapshot(GameController c) => jsonEncode({
  'profile': c.profile.toJson(),
  'ship': c.ship?.toJson(),
  'chart': c.seaChart.toJson(),
  'phase': c.phase.name,
  'monsterHp': c.currentMonster?.currentHp,
});

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _controls(WidgetTester tester, Size size) async {
  expect(tester.takeException(), isNull);
  for (final element in find.byType(InkButton).evaluate().toList()) {
    final finder = find.byElementPredicate((e) => identical(e, element));
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    final rect = tester.getRect(finder);
    expect(rect.left, greaterThanOrEqualTo(0));
    expect(rect.right, lessThanOrEqualTo(size.width));
    expect(rect.top, greaterThanOrEqualTo(0));
    expect(
      rect.bottom,
      lessThanOrEqualTo(size.height - tester.view.viewInsets.bottom),
    );
  }
  for (final element in find.byType(RichText).evaluate()) {
    final paragraph = element.renderObject! as RenderParagraph;
    final text = paragraph.text.toPlainText();
    if (text.contains('Select a lineage below')) continue;
    final target = find.byElementPredicate((e) => identical(e, element));
    if (find
        .ancestor(
          of: target,
          matching: find.byWidgetPredicate(
            (w) => w is Tooltip && w.message == text,
          ),
        )
        .evaluate()
        .isNotEmpty) {
      continue; // Compact names retain their complete text in prompt help.
    }
    expect(paragraph.didExceedMaxLines, isFalse, reason: 'Clipped: $text');
  }
  expect(tester.takeException(), isNull);
}

Future<void> _review(
  WidgetTester tester,
  SweepCase mode,
  Size size, {
  double scale = 1.15,
  bool plain = false,
  bool proof = false,
}) async {
  final settings = GameSettings.instance;
  final oldPlain = settings.highLegibilityFont;
  settings.setHighLegibilityFont(plain);
  addTearDown(() => settings.setHighLegibilityFont(oldPlain));
  await mountChartFocus(
    tester,
    const SizedBox.shrink(),
    GlobalKey(),
    size,
    scale: scale,
  );
  final key = GlobalKey();
  final store = _Lineages();
  final load = _LoadingController();
  addTearDown(load.dispose);
  final c = combat();
  addTearDown(c.dispose);
  c.ship!.name = 'The Unreturning Waverley-Montgomery Bloodbound Flagship';
  c.ship!.gold = 999999;
  c.ship!.cargo.clear();
  final frozen = [
    SweepCase.startupLoading,
    SweepCase.lineageLoading,
    SweepCase.lineageOpening,
    SweepCase.lineageBranching,
    SweepCase.battleWaiting,
  ].contains(mode);
  MonstrousSeaBattleGame? game;
  ControlledArtworkBundle? bundle;
  Future<void>? retry;
  Widget content;
  final exits = (TestWidgetsFlutterBinding.instance as _Binding).exits;
  if (mode.name.startsWith('startup')) {
    load.fail = mode == SweepCase.startupError;
    if (mode == SweepCase.startupLoading) load.gate = Completer<void>();
    content = GameOrchestratorView(
      controller: load,
      skipIntro: true,
      loadStorage: true,
    );
  } else if (mode.name.startsWith('lineage') ||
      mode == SweepCase.cancelLineage) {
    store.seed(
      List.filled(60, 'W').join(),
      completed: true,
      withSnapshot: true,
    );
    if (mode == SweepCase.lineageLoading) store.loadGate = Completer<void>();
    if (mode == SweepCase.lineageOpening) store.openGate = Completer<void>();
    if (mode == SweepCase.lineageBranching) {
      store.branchGate = Completer<void>();
    }
    store.longSummary = mode == SweepCase.lineageSummaryError;
    content = LineageMenuScreen(
      store: store,
      gameBuilder: (_, _) => const SizedBox.shrink(),
    );
  } else if (mode.name.startsWith('playtest')) {
    content = PlaytestScreen(
      gameBuilder: (test) => const ParchmentScaffold(
        body: Center(child: Text('Isolated playtest build')),
      ),
    );
  } else if ([
    SweepCase.artFailed,
    SweepCase.artRetrying,
    SweepCase.battleWaiting,
  ].contains(mode)) {
    bundle = ControlledArtworkBundle()..missing.add(PilotArt.standard);
    game = MonstrousSeaBattleGame(
      ship: c.ship!,
      monster: c.currentMonster!,
      assetBundle: bundle,
    );
    if (mode == SweepCase.battleWaiting) {
      c.session.currentMonster = null;
    } else {
      await tester.runAsync(() async {
        game!.onGameResize(Vector2(size.width, size.height));
        // ignore: invalid_use_of_internal_member
        await game.load();
      });
      game.pauseEngine();
    }
    content = BattleScreen(controller: c, game: game);
  } else {
    c.session.phase = SessionPhase.restArea;
    switch (mode) {
      case SweepCase.restCritical:
        c.ship!.currentHp = 1;
        content = RestScreen(controller: c, onOpenChart: () {});
      case SweepCase.restNoShip:
        c.session.ship = null;
        content = RestScreen(controller: c, onOpenChart: () {});
      case SweepCase.wreckUnavailable:
        content = ShipwreckScreen(controller: c, onOpenChart: () {});
      case SweepCase.lootEmpty:
        c.session.phase = SessionPhase.loot;
        c.session.pendingLoot.clear();
        content = LootScreen(controller: c);
      case SweepCase.materialsSoldOut:
        c.session.phase = SessionPhase.merchant;
        c.session.merchantStock.clear();
        c.session.merchantMaterials = MaterialShipment(
          id: 'empty-audit',
          seaGlass: 0,
          depthWroughtIron: 0,
        );
        content = MerchantScreen(controller: c);
      default:
        content = RestScreen(controller: c, onOpenChart: () {});
    }
  }
  final before = _snapshot(c),
      beforeLoad = _snapshot(load),
      beforeStore = _menuSnapshot(store);
  await tester.pumpWidget(
    RepaintBoundary(
      key: key,
      child: MaterialApp(
        theme: InkTheme.themeData.copyWith(platform: TargetPlatform.windows),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: PlaytestHost(
          gameBuilder: (_) => const SizedBox.shrink(),
          child: TickerMode(
            enabled: !frozen,
            child:
                mode.name.startsWith('lineage') ||
                    mode.name.startsWith('startup') ||
                    mode.name.startsWith('playtest') ||
                    mode == SweepCase.cancelLineage
                ? content
                : PauseMenuHost(
                    controller: c,
                    label: 'Isolated layout sweep',
                    child: content,
                  ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (game != null && mode != SweepCase.battleWaiting) {
    game.resumeEngine();
    await tester.pump(const Duration(milliseconds: 100));
    game.pauseEngine();
    await tester.runAsync(game.ready);
    game.update(0);
    await tester.pumpAndSettle();
  }
  if (mode == SweepCase.lineageOpening) {
    await _tap(tester, find.text('CONTINUE'));
  }
  if (mode == SweepCase.lineageBranching ||
      mode == SweepCase.lineageBranchError) {
    await _tap(tester, find.text('EXPLORE THE OTHER FATE'));
  }
  if (mode == SweepCase.lineageExitError) {
    await _tap(tester, find.text('EXIT GAME'));
  }
  if (mode == SweepCase.cancelLineage) {
    await _tap(tester, find.text('NEW LINEAGE'));
    await tester.enterText(
      find.byKey(const ValueKey('lineage-label')),
      List.filled(60, 'W').join(),
    );
    await tester.pumpAndSettle();
  }
  if (mode == SweepCase.playtestInvalid || mode == SweepCase.playtestKeyboard) {
    await tester.enterText(find.byKey(const ValueKey('playtest-gold')), '-12');
    await tester.enterText(
      find.byKey(const ValueKey('playtest-seed')),
      'not a seed',
    );
    await _tap(tester, find.text('LAUNCH PLAYTEST'));
    expect(
      find.text('Enter a whole number from 0 to 2147483647.'),
      findsOneWidget,
    );
    if (mode == SweepCase.playtestKeyboard) {
      tester.view.viewInsets = const FakeViewPadding(bottom: 240);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
    }
  }
  if (mode == SweepCase.playtestChoices) {
    await _tap(tester, find.byKey(const ValueKey('Region')));
    await _tap(tester, find.text(SeaChart.regionName(2)).last);
    await _tap(tester, find.byKey(const ValueKey('broadside dedication')));
    await _tap(tester, find.text(OceanPower.tempestSovereign.displayName).last);
  }
  if (mode == SweepCase.playtestActive) {
    await _tap(tester, find.text('LAUNCH PLAYTEST'));
    expect(find.textContaining('Progress is not saved'), findsOneWidget);
  }
  if (mode == SweepCase.artRetrying) {
    bundle!.missing.clear();
    bundle.pendingShip = Completer<ByteData>();
    retry = game!.retryArtwork();
    await tester.pumpAndSettle();
    expect(find.text('LOADING ART...'), findsOneWidget);
  }
  final name =
      '${mode.name}-${size.width.toInt()}x${size.height.toInt()}-$scale-${plain ? 'plain' : 'ink'}';
  if (proof) await captureChartFocusProof(tester, key, name);
  await _controls(tester, size);
  if (proof) await captureChartFocusProof(tester, key, '$name-controls');
  if (mode == SweepCase.startupError) {
    load.fail = false;
    await _tap(tester, find.text('RETRY'));
    expect(load.loads, 2);
    expect(find.text('Could not load your saved progress.'), findsNothing);
  }
  if (mode == SweepCase.cancelLineage) {
    await _tap(tester, find.text('CANCEL'));
    expect(find.byType(AlertDialog), findsNothing);
  }
  expect(_snapshot(c), before);
  expect(_snapshot(load), beforeLoad);
  expect(_menuSnapshot(store), beforeStore);
  expect(
    (TestWidgetsFlutterBinding.instance as _Binding).exits,
    exits + (mode == SweepCase.lineageExitError ? 1 : 0),
  );
  expect(tester.takeException(), isNull);
  await tester.pumpWidget(const SizedBox.shrink());
  load.gate?.complete();
  store.loadGate?.complete();
  store.openGate?.complete();
  store.branchGate?.complete();
  if (bundle?.pendingShip != null) {
    await tester.runAsync(() async {
      bundle!.pendingShip!.complete(await rootBundle.load(PilotArt.standard));
      await retry;
    });
  }
  await tester.pumpAndSettle();
}

void main() {
  _Binding();
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
  for (final mode in SweepCase.values) {
    for (final size in sizes) {
      testWidgets(
        '115% ${mode.name} $size',
        (tester) => _review(tester, mode, size, proof: size.width == 360),
      );
    }
  }
  for (final mode in SweepCase.values) {
    for (final size in sizes) {
      testWidgets(
        'Plain 115% ${mode.name} $size',
        (tester) => _review(tester, mode, size, plain: true),
      );
    }
  }
  for (final plain in [false, true]) {
    for (final mode in [
      SweepCase.startupError,
      SweepCase.lineageBranchError,
      SweepCase.lineageSummaryError,
      SweepCase.cancelLineage,
      SweepCase.rest,
      SweepCase.restCritical,
      SweepCase.artFailed,
      SweepCase.artRetrying,
      SweepCase.playtestInvalid,
      SweepCase.playtestKeyboard,
      SweepCase.playtestChoices,
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
                [SweepCase.artFailed, SweepCase.playtestInvalid].contains(mode),
          ),
        );
      }
    }
  }
}
