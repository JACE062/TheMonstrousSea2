import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/playtest/playtest_host.dart';
import 'package:monstrous_sea/src/screens/lineage_menu_screen.dart';
import 'package:monstrous_sea/src/screens/port_screen.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';
import 'package:monstrous_sea/src/widgets/ink_button.dart';
import 'package:monstrous_sea/src/widgets/hull_gauge.dart';

import 'chart_focus_ui_test.dart' show mountChartFocus, captureChartFocusProof;
import 'navigation_layout_matrix_test.dart' show shell;
import 'lineage_menu_test.dart' show MemoryLineages;

enum HomePage { overview, blueprints, pacts, relics, monuments }

enum Wealth { poor, rich, owned, maxed }

enum MenuCase {
  empty,
  many,
  unreadable,
  catalogError,
  openError,
  ending,
  noSnapshot,
  alternate,
  wideLabel,
}

enum NameCase { empty, longLabel, invalid, keyboard, createError }

GameController home(
  Wealth wealth,
  BlueprintId blueprint, {
  bool covenant = true,
}) {
  final c = GameController(
    session: GameSession(rng: SeededGameRng(42)),
    autoSave: false,
  )..dispatch(const NameCaptain('Alexandrina Waverley-Montgomery'));
  if (wealth != Wealth.poor) {
    c.profile.metaInventory.add(
      seaGlass: 12345,
      monsterBone: 12345,
      depthWroughtIron: 12345,
      abyssalBarnacles: 12345,
      krakenBeak: 123,
      serpentScale: 123,
      leviathanCore: 123,
      primordialCinders: 12345,
    );
  }
  if (wealth == Wealth.owned || wealth == Wealth.maxed) {
    c.profile.unlockedBlueprints.addAll(BlueprintId.values.map((b) => b.name));
    for (final b in BlueprintId.values) {
      c.profile.blueprintArmamentTiers[b.name] = wealth == Wealth.maxed ? 3 : 2;
    }
    c.profile.hasExpandedAuxiliarySlot = true;
    c.profile.activePacts.addAll(CovenantPactId.values);
    c.profile.unlockedEldritchRelics.addAll(
      EldritchRelicId.values.map((r) => r.name),
    );
    c.profile.activeEldritchRelics.addAll(c.profile.unlockedEldritchRelics);
    for (final m in HarborMonumentId.values) {
      c.profile.portCivicLevels[m.name] = wealth == Wealth.maxed ? 10 : 2;
    }
  }
  c.profile.hasUnlockedCovenant = covenant;
  c.profile.ascensionLoopCount = wealth == Wealth.maxed ? 12 : 1;
  c.profile.unlockedBlueprints.add(blueprint.name);
  c.dispatch(CommissionBlueprint(blueprint));
  c.session.activeBoon = BloodlineTrait.quartermaster;
  c.session.activeQuirk = BloodlineTrait.exactingShipwright;
  c.session.syncCaptainTraits();
  final ship = c.ship!;
  ship.gold = wealth == Wealth.poor ? 0 : 12345;
  for (var i = 0; i < ship.maxCargo; i++) {
    ship.cargo.add(
      generateConsumable(
        ConsumableType.values[i % ConsumableType.values.length],
        RarityLevel.common,
      ),
    );
  }
  return c;
}

Future<void> press(WidgetTester tester, String label) async {
  final target = find.text(label).last;
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> controls(WidgetTester tester, Size size) async {
  expect(tester.takeException(), isNull);
  final dialogs = find.byType(AlertDialog);
  final scope = dialogs.evaluate().isEmpty
      ? find.byType(Scaffold).last
      : dialogs.last;
  final buttons = find
      .descendant(of: scope, matching: find.byType(InkButton))
      .evaluate()
      .toList();
  for (final element in buttons) {
    final target = find.byElementPredicate((e) => identical(e, element));
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    final button = element.widget as InkButton;
    expect(target.hitTestable(), findsOneWidget, reason: button.label);
    final bounds = tester.getRect(target);
    expect(bounds.left, greaterThanOrEqualTo(0), reason: button.label);
    expect(bounds.right, lessThanOrEqualTo(size.width), reason: button.label);
    expect(bounds.top, greaterThanOrEqualTo(0), reason: button.label);
    expect(bounds.bottom, lessThanOrEqualTo(size.height), reason: button.label);
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
  for (final element
      in find
          .descendant(of: scope, matching: find.byType(TextButton))
          .evaluate()
          .toList()) {
    final target = find.byElementPredicate((e) => identical(e, element));
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    expect(target.hitTestable(), findsOneWidget);
  }
  for (final element
      in find
          .descendant(of: scope, matching: find.byType(Checkbox))
          .evaluate()
          .toList()) {
    final target = find.byElementPredicate((e) => identical(e, element));
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    expect(target.hitTestable(), findsOneWidget);
  }
  if (dialogs.evaluate().isNotEmpty) {
    final bounds = tester.getRect(find.byType(Dialog).last);
    expect(bounds.left, greaterThanOrEqualTo(0));
    expect(bounds.right, lessThanOrEqualTo(size.width));
    expect(bounds.top, greaterThanOrEqualTo(0));
    expect(bounds.bottom, lessThanOrEqualTo(size.height));
  }
  expect(tester.takeException(), isNull);
}

Future<void> reviewHome(
  WidgetTester tester,
  HomePage page,
  Wealth wealth,
  Size size, {
  BlueprintId blueprint = BlueprintId.standard,
  double scale = 1.15,
  bool capture = false,
  BloodlineTrait? boon,
  BloodlineTrait? quirk,
}) async {
  final c = home(
    wealth,
    blueprint,
    covenant:
        page != HomePage.overview ||
        wealth == Wealth.owned ||
        wealth == Wealth.maxed,
  );
  if (boon != null) c.session.activeBoon = boon;
  if (quirk != null) c.session.activeQuirk = quirk;
  c.session.syncCaptainTraits();
  addTearDown(c.dispose);
  final before = jsonEncode({
    'profile': c.profile.toJson(),
    'ship': c.ship!.toJson(),
    'chart': c.seaChart.toJson(),
  });
  final key = GlobalKey();
  await mountChartFocus(
    tester,
    shell(c, PortScreen(controller: c, onOpenChart: () {})),
    key,
    size,
    scale: scale,
  );
  if (page == HomePage.blueprints) {
    await press(tester, 'BLUEPRINTS');
  } else if (page != HomePage.overview) {
    await press(tester, 'COMMUNE');
    await press(tester, switch (page) {
      HomePage.pacts => 'COVENANT PACTS',
      HomePage.relics => 'ELDRITCH RELICS',
      _ => 'CURSED MONUMENTS',
    });
  }
  if (page == HomePage.overview && size.width < 500) {
    expect(
      tester.getSize(find.text(c.seaChart.currentPortName.toUpperCase())).width,
      greaterThan(200),
      reason: 'The port title must not be squeezed beside purse controls.',
    );
    expect(
      tester.getSize(find.byType(HullGauge)).width,
      greaterThan(size.width * .6),
      reason: 'The compact vessel meter needs the full card width.',
    );
  }
  if (capture) {
    await captureChartFocusProof(
      tester,
      key,
      '${page.name}-${wealth.name}-${blueprint.name}-${size.width.toInt()}-$scale',
    );
  }
  await controls(tester, size);
  if (capture) {
    await captureChartFocusProof(
      tester,
      key,
      '${page.name}-${wealth.name}-${blueprint.name}-${size.width.toInt()}-$scale-controls',
    );
  }
  expect(
    jsonEncode({
      'profile': c.profile.toJson(),
      'ship': c.ship!.toJson(),
      'chart': c.seaChart.toJson(),
    }),
    before,
    reason: 'Opening, browsing and scrolling must not buy upgrades or change preparation.',
  );
  if (page != HomePage.overview) {
    await press(tester, 'Close');
    expect(find.byType(AlertDialog), findsNothing);
  }
}

String menuSnapshot(MemoryLineages store) => jsonEncode({
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

Future<void> reviewMenu(
  WidgetTester tester,
  MenuCase state,
  Size size, {
  double scale = 1.15,
  NameCase? name,
  bool capture = false,
}) async {
  final store = MemoryLineages();
  if (state != MenuCase.empty && state != MenuCase.catalogError) {
    final ending = [
      MenuCase.ending,
      MenuCase.noSnapshot,
      MenuCase.alternate,
    ].contains(state);
    final slot = store.seed(
      state == MenuCase.wideLabel
          ? List.filled(60, 'W').join()
          : 'The Waverley-Montgomery Family and its Everlasting Hunt',
      completed: ending,
      withSnapshot: state == MenuCase.ending || state == MenuCase.alternate,
    );
    if (state == MenuCase.alternate) {
      await store.exploreOtherFate(slot.id);
      store.active = slot.id;
    }
    if (state == MenuCase.many) {
      for (var i = 0; i < 15; i++) {
        store.seed(
          'Waverley-Montgomery descendants, the ${i + 2}th hunt into the sea',
        );
      }
    }
    if (state == MenuCase.unreadable) {
      store.unreadable.add(slot.id);
      store.seed('A readable lineage');
    }
  }
  store.failLoad = state == MenuCase.catalogError;
  store.failOpen = state == MenuCase.openError;
  store.failCreate = name == NameCase.createError;
  final before = menuSnapshot(store);
  final key = GlobalKey();
  await mountChartFocus(
    tester,
    PlaytestHost(
      gameBuilder: (_) => const SizedBox.shrink(),
      child: LineageMenuScreen(
        store: store,
        gameBuilder: (_, _) => const SizedBox.shrink(),
      ),
    ),
    key,
    size,
    scale: scale,
  );
  if (state == MenuCase.openError) await press(tester, 'CONTINUE');
  if (name != null) {
    await press(tester, 'NEW LINEAGE');
    if (name == NameCase.keyboard) {
      tester.view.viewInsets = const FakeViewPadding(bottom: 240);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
    }
    if (name == NameCase.longLabel || name == NameCase.createError) {
      await tester.enterText(
        find.byKey(const ValueKey('lineage-label')),
        'The Waverley-Montgomery Family and its Everlasting Hunt',
      );
      await tester.pumpAndSettle();
    }
    if (name == NameCase.invalid || name == NameCase.createError) {
      await press(tester, 'CREATE LINEAGE');
    }
  }
  await controls(tester, size);
  if (capture) {
    await captureChartFocusProof(
      tester,
      key,
      'menu-${state.name}-${name?.name ?? 'list'}-${size.width.toInt()}-$scale',
    );
  }
  expect(
    menuSnapshot(store),
    before,
    reason: 'Layout review must not create/open a save or write a profile.',
  );
  if (find.text('CANCEL').evaluate().isNotEmpty) await press(tester, 'CANCEL');
}

void main() {
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
  for (final page in HomePage.values) {
    for (final wealth in Wealth.values) {
      for (final size in sizes) {
        testWidgets('115% ${page.name} ${wealth.name} $size', (tester) async {
          await reviewHome(
            tester,
            page,
            wealth,
            size,
            capture:
                wealth == Wealth.rich && size.width != 800 ||
                wealth == Wealth.owned &&
                    page == HomePage.overview &&
                    size.width == 360,
          );
        });
      }
    }
  }
  for (final state in MenuCase.values) {
    for (final size in sizes) {
      testWidgets(
        '115% lineage ${state.name} $size',
        (tester) => reviewMenu(tester, state, size, capture: size.width == 360),
      );
    }
  }
  for (final name in NameCase.values) {
    for (final size in sizes) {
      testWidgets(
        '115% new lineage ${name.name} $size',
        (tester) => reviewMenu(
          tester,
          MenuCase.empty,
          size,
          name: name,
          capture: size.width == 360,
        ),
      );
    }
  }
  for (final hull in BlueprintId.values.where(
    (h) => h != BlueprintId.standard,
  )) {
    for (final page in [HomePage.overview, HomePage.blueprints]) {
      for (final wealth in [Wealth.owned, Wealth.maxed]) {
        for (final size in [sizes.first, sizes.last]) {
          testWidgets(
            '115% ${hull.name} ${page.name} ${wealth.name} $size',
            (tester) => reviewHome(
              tester,
              page,
              wealth,
              size,
              blueprint: hull,
              capture: page == HomePage.overview && wealth == Wealth.owned,
            ),
          );
        }
      }
    }
  }
  for (var i = 0; i < BloodlineTrait.allBoons.length; i++) {
    for (final size in [sizes.first, sizes.last]) {
      testWidgets(
        '115% home trait descriptions $i $size',
        (tester) => reviewHome(
          tester,
          HomePage.overview,
          Wealth.owned,
          size,
          boon: BloodlineTrait.allBoons[i],
          quirk: BloodlineTrait.allQuirks[i],
        ),
      );
    }
  }
  for (final page in HomePage.values) {
    for (final size in sizes) {
      testWidgets(
        '130% ${page.name} upgrades $size',
        (tester) => reviewHome(
          tester,
          page,
          Wealth.maxed,
          size,
          scale: 1.3,
          capture: size.width == 360,
        ),
      );
    }
  }
  for (final size in sizes) {
    testWidgets(
      '130% lineage list $size',
      (tester) => reviewMenu(tester, MenuCase.many, size, scale: 1.3),
    );
    for (final name in [NameCase.invalid, NameCase.keyboard]) {
      testWidgets(
        '130% new lineage ${name.name} $size',
        (tester) =>
            reviewMenu(tester, MenuCase.empty, size, scale: 1.3, name: name),
      );
    }
  }
}
