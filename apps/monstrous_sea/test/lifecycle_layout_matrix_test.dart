import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/screens/intro_screen.dart';
import 'package:monstrous_sea/src/screens/captain_screen.dart';
import 'package:monstrous_sea/src/screens/death_screen.dart';
import 'package:monstrous_sea/src/screens/victory_screen.dart';
import 'package:monstrous_sea/src/screens/caldera_outcome_screen.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';
import 'package:monstrous_sea/src/widgets/ink_button.dart';
import 'package:monstrous_sea/src/widgets/typewriter_text.dart';
import 'package:monstrous_sea/src/widgets/painters/cartouche_border_painter.dart';

import 'chart_focus_ui_test.dart' show mountChartFocus;
import 'navigation_layout_matrix_test.dart' show shell;

enum LifePage {
  introOpening,
  introComplete,
  captainFirst,
  captainReturning,
  captainInvalid,
  captainKeyboard,
  deathNemesis,
  deathTitan,
  deathNoOffers,
  deathKeyboard,
  claimSuccession,
  finalChoice,
  outcomeClaim,
  outcomeShatter,
  huntEnded,
  huntEndedMenu,
  huntExitError,
}

class _LifecycleBinding extends AutomatedTestWidgetsFlutterBinding {
  int exitCalls = 0;
  @override
  Future<ui.AppExitResponse> exitApplication(
    ui.AppExitType type, [
    int exitCode = 0,
  ]) async {
    exitCalls++;
    return ui.AppExitResponse.cancel;
  }
}

const longName = 'Alexandrina Waverley-Montgomery of the Saltbound Watch';

bool isDeath(LifePage page) => [
  LifePage.deathNemesis,
  LifePage.deathTitan,
  LifePage.deathNoOffers,
  LifePage.deathKeyboard,
  LifePage.claimSuccession,
].contains(page);

GameController fixture(
  LifePage page, {
  String name = longName,
  BlueprintId hull = BlueprintId.standard,
  MonsterSpecies titan = MonsterSpecies.kraken,
  int boon = 0,
  int quirk = 0,
}) {
  final c = GameController(
    session: GameSession(rng: SeededGameRng(42)),
    autoSave: false,
  );
  if (page.name.startsWith('intro') || page.name.startsWith('captain')) {
    c.profile.hasBegunFirstVoyage = page == LifePage.captainReturning;
    return c;
  }
  c.dispatch(BeginFirstVoyage(name));
  c.profile.unlockedBlueprints.add(hull.name);
  c.profile.activeBlueprintId = hull.name;
  c.session.ship = createFlagshipFromBlueprint(hull, rng: SeededGameRng(11));
  c.ship!.name = '$name’s Bloodbound Flagship';
  c.ship!.gold = 1234567;
  c.session.monstersDefeatedThisLife = 12345;
  final ending = !isDeath(page) || page == LifePage.claimSuccession;
  if (ending) {
    c.profile.metaInventory.add(leviathanCore: 1);
    c.session.phase = SessionPhase.expeditionVictory;
    if (page != LifePage.finalChoice) {
      final claim =
          page == LifePage.outcomeClaim || page == LifePage.claimSuccession;
      c.dispatch(
        ResolveCalderaClimax(
          claim
              ? CalderaClimaxChoice.claimCore
              : CalderaClimaxChoice.shatterCore,
        ),
      );
      if (page == LifePage.claimSuccession || page.name.startsWith('hunt')) {
        c.dispatch(const AcknowledgeCalderaOutcome());
      }
    }
  } else {
    final species = page == LifePage.deathTitan ? titan : MonsterSpecies.squid;
    final region = species == MonsterSpecies.worldSerpent
        ? 1
        : species == MonsterSpecies.ancientLeviathan
        ? 2
        : 0;
    for (var i = 0; i < region; i++) {
      c.seaChart.advanceRegion(SeededGameRng(30 + i));
    }
    c.session.currentMonster = createMonster(
      species,
      level: region * 4 + 5,
      isApex: !species.isRegionTitan,
      rng: SeededGameRng(9),
    );
    c.ship!.currentHp = 0;
    c.dispatch(const ExecuteShipSpecialAction());
  }
  if (page == LifePage.deathNoOffers) {
    c.pendingHeirCandidates.clear();
    c.lineage.history.clear();
    c.lineage.captainsLost = 0;
    c.lineage.totalMonstersDefeated = 0;
    c.profile.activeNemesis = null;
  } else if (isDeath(page)) {
    final quirks = BloodlineTrait.allQuirks
        .where(
          (q) => c.activeNemesis != null || q.id != BloodlineTraitId.bloodOath,
        )
        .toList();
    c.pendingHeirCandidates
      ..clear()
      ..addAll(
        List.generate(
          3,
          (i) => HeirCandidate(
            defaultName:
                '$name ${['the Ever-Watchful', 'the Relentless', 'the Far-Sighted'][i]}',
            boon: BloodlineTrait
                .allBoons[(boon + i) % BloodlineTrait.allBoons.length],
            quirk: quirks[(quirk + i) % quirks.length],
          ),
        ),
      );
  }
  return c;
}

String snapshot(GameController c) => jsonEncode({
  'profile': c.profile.toJson(),
  'ship': c.ship?.toJson(),
  'chart': c.seaChart.toJson(),
  'phase': c.phase.name,
  'name': c.captainName,
  'offers': c.pendingHeirCandidates.map((h) => h.toJson()).toList(),
  'outcome': c.session.calderaOutcome?.name,
  'read': c.session.hasReadCalderaOutcome,
});

Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
  const prefix = String.fromEnvironment('lifecycleProofPath');
  if (prefix.isEmpty) return;
  await tester.pump();
  await tester.runAsync(() async {
    final picture =
        await (key.currentContext!.findRenderObject() as RenderRepaintBoundary)
            .toImage();
    try {
      final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
      await File('$prefix-$name.png').writeAsBytes(bytes!.buffer.asUint8List());
    } finally {
      picture.dispose();
    }
  });
}

Future<void> review(
  WidgetTester tester,
  LifePage page,
  Size size, {
  double scale = 1.15,
  int boon = 0,
  int quirk = 0,
  String name = longName,
  BlueprintId hull = BlueprintId.standard,
  MonsterSpecies titan = MonsterSpecies.kraken,
  bool proof = false,
}) async {
  final c = fixture(
    page,
    name: name,
    hull: hull,
    titan: titan,
    boon: boon,
    quirk: quirk,
  );
  addTearDown(c.dispose);
  final before = snapshot(c);
  final binding = TestWidgetsFlutterBinding.instance as _LifecycleBinding;
  final exitsBefore = binding.exitCalls;
  var starts = 0;
  final screen = switch (page) {
    LifePage.introOpening ||
    LifePage.introComplete => IntroScreen(onStart: () => starts++),
    LifePage.captainFirst ||
    LifePage.captainReturning ||
    LifePage.captainInvalid ||
    LifePage.captainKeyboard => CaptainScreen(controller: c),
    LifePage.finalChoice => VictoryScreen(controller: c),
    LifePage.outcomeClaim ||
    LifePage.outcomeShatter => CalderaOutcomeScreen(controller: c),
    LifePage.huntEnded ||
    LifePage.huntEndedMenu ||
    LifePage.huntExitError => HuntEndedScreen(
      controller: c,
      onReturnToMenu: page == LifePage.huntEndedMenu ? () => starts++ : null,
    ),
    _ => DeathScreen(controller: c),
  };
  // Prime the shared game fonts without settling an endlessly animated intro.
  await mountChartFocus(
    tester,
    const SizedBox.shrink(),
    GlobalKey(),
    size,
    scale: scale,
  );
  final ticking = ValueNotifier(page != LifePage.introOpening);
  addTearDown(ticking.dispose);
  final key = GlobalKey();
  await tester.pumpWidget(
    RepaintBoundary(
      key: key,
      child: MaterialApp(
        theme: InkTheme.themeData,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: ValueListenableBuilder(
          valueListenable: ticking,
          builder: (_, enabled, child) =>
              TickerMode(enabled: enabled, child: child!),
          child: shell(c, screen),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
  if (page == LifePage.introComplete) {
    await tester.pump(const Duration(seconds: 60));
    await tester.pump(const Duration(milliseconds: 700));
    ticking.value = false;
    await tester.pump();
  }
  if (page == LifePage.captainInvalid) {
    await tester.enterText(find.byType(TextField), '  ');
    await tester.ensureVisible(find.text('BEGIN FIRST VOYAGE'));
    await tester.tap(find.text('BEGIN FIRST VOYAGE'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Enter a name for the first captain.'), findsOneWidget);
    if (!InkTheme.disableGoogleFonts) {
      final error = find.text('Enter a name for the first captain.');
      for (final text
          in find
              .descendant(of: error, matching: find.byType(RichText))
              .evaluate()) {
        expect(
          (text.renderObject! as RenderParagraph).didExceedMaxLines,
          isFalse,
          reason: 'Captain validation must remain fully readable.',
        );
      }
    }
  } else if (page.name.startsWith('captain')) {
    await tester.enterText(find.byType(TextField), name);
    await tester.pump(const Duration(milliseconds: 300));
  }
  if (page == LifePage.huntExitError) {
    await tester.ensureVisible(find.text('EXIT GAME'));
    await tester.tap(find.text('EXIT GAME'));
    await tester.pump();
    await tester.pump();
    expect(
      find.text('The game could not close. Please try Exit Game again.'),
      findsOneWidget,
    );
  }
  final keyboard =
      page == LifePage.captainKeyboard || page == LifePage.deathKeyboard;
  if (keyboard) {
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();
  }
  expect(tester.takeException(), isNull);
  final label =
      '${page.name}-${hull.name}-${titan.name}-${size.width.toInt()}-$scale';
  if (proof) await capture(tester, key, label);
  for (final element in find.byType(InkButton).evaluate().toList()) {
    final target = find.byElementPredicate((e) => identical(e, element));
    await tester.ensureVisible(target);
    await tester.pump();
    final button = element.widget as InkButton;
    expect(target.hitTestable(), findsOneWidget, reason: button.label);
    final bounds = tester.getRect(target);
    expect(bounds.left, greaterThanOrEqualTo(0));
    expect(bounds.right, lessThanOrEqualTo(size.width));
    expect(bounds.top, greaterThanOrEqualTo(0));
    expect(
      bounds.bottom,
      lessThanOrEqualTo(size.height - (keyboard ? 240 : 0)),
    );
    if (!InkTheme.disableGoogleFonts) {
      for (final text
          in find
              .descendant(of: target, matching: find.byType(RichText))
              .evaluate()) {
        expect(
          (text.renderObject! as RenderParagraph).didExceedMaxLines,
          isFalse,
          reason: 'Clipped action: ${button.label}',
        );
      }
    }
  }
  if (isDeath(page)) {
    for (final candidate in c.pendingHeirCandidates) {
      final target = find.text(candidate.defaultName).first;
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        candidate.defaultName,
      );
      if (proof && identical(candidate, c.pendingHeirCandidates.first)) {
        await capture(tester, key, '$label-selected-heir');
      }
      if (size.width < 500) {
        expect(
          tester.getSize(target).width,
          greaterThan(200),
          reason: 'Selected heir names need readable width beside the badge.',
        );
      }
      for (final description in [
        candidate.boon.description,
        candidate.quirk.description,
      ]) {
        final text = find.text(description).first;
        if (size.width < 500) {
          final paragraph = tester.renderObject<RenderParagraph>(text);
          expect(
            paragraph.constraints.maxWidth,
            greaterThan(200),
            reason: 'Compact trait descriptions need the full card width.',
          );
        }
        await Scrollable.ensureVisible(tester.element(text), alignment: .5);
        await tester.pump();
        expect(text.hitTestable(), findsOneWidget);
      }
    }
    await tester.ensureVisible(find.byType(TextField));
    await tester.enterText(find.byType(TextField), name);
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      name,
    );
  }
  if (page.name.startsWith('intro')) {
    final footer = find.widgetWithText(InkButton, 'EMBARK UPON THE HUNT');
    final rect = tester.getRect(footer);
    final border = find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is CartoucheBorderPainter,
    );
    final frame = tester.getRect(border).deflate(12);
    expect(
      frame.contains(rect.topLeft) && frame.contains(rect.bottomRight),
      isTrue,
    );
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable).first);
    scroll.position.jumpTo(scroll.position.maxScrollExtent);
    await tester.pump();
    expect(
      tester.getRect(footer),
      rect,
      reason: 'Embark stays fixed as prose scrolls.',
    );
    if (page == LifePage.introComplete) {
      final writer = tester.widget<TypewriterText>(find.byType(TypewriterText));
      expect(find.text(writer.text), findsOneWidget);
    }
  }
  if (proof) await capture(tester, key, '$label-content');
  expect(starts, 0);
  expect(
    binding.exitCalls,
    exitsBefore + (page == LifePage.huntExitError ? 1 : 0),
  );
  expect(
    snapshot(c),
    before,
    reason: 'Layout review must not select a fate, create an heir or rewrite saves.',
  );
  expect(tester.takeException(), isNull);
  await tester.pumpWidget(const SizedBox.shrink());
}

void main() {
  _LifecycleBinding();
  setUpAll(() async {
    InkTheme.disableGoogleFonts = const String.fromEnvironment('artFontCache')
        .isEmpty;
    if (InkTheme.disableGoogleFonts) {
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
          File(
            '${sdk.path}/bin/cache/artifacts/material_fonts/roboto-$face.ttf',
          ).readAsBytes().then(ByteData.sublistView),
        );
      }
      await loader.load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    }
  });
  const sizes = [Size(360, 900), Size(800, 480), Size(1280, 850)];
  for (final page in LifePage.values) {
    for (final size in sizes) {
      testWidgets(
        '115% ${page.name} $size',
        (tester) => review(tester, page, size, proof: size.width == 360),
      );
    }
  }
  for (final size in sizes) {
    testWidgets(
      '130% captainInvalid $size',
      (tester) => review(
        tester,
        LifePage.captainInvalid,
        size,
        scale: 1.3,
        proof: true,
      ),
    );
  }
  for (var boon = 0; boon < BloodlineTrait.allBoons.length; boon++) {
    for (var quirk = 0; quirk < BloodlineTrait.allQuirks.length; quirk++) {
      for (final size in [sizes.first, sizes.last]) {
        testWidgets(
          '115% heir pair $boon/$quirk $size',
          (tester) => review(
            tester,
            LifePage.deathNemesis,
            size,
            boon: boon,
            quirk: quirk,
          ),
        );
      }
    }
  }
  for (final page in [
    LifePage.introComplete,
    LifePage.captainKeyboard,
    LifePage.deathKeyboard,
    LifePage.claimSuccession,
    LifePage.finalChoice,
    LifePage.outcomeClaim,
    LifePage.outcomeShatter,
    LifePage.huntEndedMenu,
  ]) {
    for (final size in sizes) {
      testWidgets(
        '130% ${page.name} $size',
        (tester) =>
            review(tester, page, size, scale: 1.3, proof: size.width == 360),
      );
    }
  }
  for (final hull in BlueprintId.values.where(
    (h) => h != BlueprintId.standard,
  )) {
    for (final size in [sizes.first, sizes.last]) {
      testWidgets(
        '115% ${hull.name} death $size',
        (tester) => review(tester, LifePage.deathNemesis, size, hull: hull),
      );
    }
  }
  for (final titan in [
    MonsterSpecies.worldSerpent,
    MonsterSpecies.ancientLeviathan,
  ]) {
    for (final size in sizes) {
      testWidgets(
        '115% ${titan.name} death $size',
        (tester) => review(tester, LifePage.deathTitan, size, titan: titan),
      );
    }
  }
  for (final page in [
    LifePage.captainFirst,
    LifePage.deathNemesis,
    LifePage.finalChoice,
  ]) {
    for (final size in sizes) {
      testWidgets(
        '115% ${page.name} unbroken name $size',
        (tester) =>
            review(tester, page, size, name: List.filled(80, 'W').join()),
      );
    }
  }
}
