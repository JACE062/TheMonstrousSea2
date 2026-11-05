import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/screens/loot_screen.dart';
import 'package:monstrous_sea/src/screens/merchant_screen.dart';
import 'package:monstrous_sea/src/screens/port_screen.dart';
import 'package:monstrous_sea/src/screens/shipwreck_screen.dart';
import 'package:monstrous_sea/src/screens/sea_chart_screen.dart';
import 'package:monstrous_sea/src/widgets/loot_supplies_view.dart';
import 'package:monstrous_sea/src/widgets/paid_repair_view.dart';
import 'package:monstrous_sea/src/widgets/parchment_scaffold.dart';
import 'package:monstrous_sea/src/widgets/svg_asset_view.dart';
import 'package:monstrous_sea/src/widgets/pilot_art.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';

class _FontRoot extends PathProviderPlatform {
  _FontRoot(this.path);
  final String path;
  @override
  Future<String?> getApplicationSupportPath() async => path;
}

Future<void> _fonts(WidgetTester tester) async {
  const path = String.fromEnvironment('artFontCache');
  if (path.isEmpty) return;
  final previous = PathProviderPlatform.instance;
  PathProviderPlatform.instance = _FontRoot(path);
  addTearDown(() => PathProviderPlatform.instance = previous);
  await tester.runAsync(() async {
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    InkTheme.themeData;
    await GoogleFonts.pendingFonts([
      InkTheme.titleLarge,
      InkTheme.titleMedium,
      InkTheme.subtitle,
      InkTheme.body,
      InkTheme.bodyBold,
      InkTheme.caption,
      InkTheme.statLabel,
      InkTheme.statValue,
    ]);
  });
}

Future<void> _proof(WidgetTester tester, GlobalKey key, String name) async {
  const prefix = String.fromEnvironment('followupProofPath');
  if (prefix.isEmpty) return;
  final context = key.currentContext!;
  await tester.runAsync(() async {
    for (final asset in [
      PilotArt.portHaven,
      PilotArt.standard,
      PilotArt.defeatedMonster,
      'assets/art/icon_blast_pack_map.png',
      'assets/art/icon_unstable_tincture_map_v4.png',
    ]) {
      await precacheImage(AssetImage(asset), context);
    }
  });
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final image = await (context.findRenderObject() as RenderRepaintBoundary)
        .toImage();
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('$prefix-$name.png').writeAsBytes(data!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

GameController _controller() => GameController(
  session: GameSession(rng: SeededGameRng(51)),
  autoSave: false,
)..dispatch(const BeginFirstVoyage('Followup UI'));
Future<void> _mount(
  WidgetTester tester,
  Widget screen,
  GlobalKey key,
  double width,
) async {
  tester.view.physicalSize = Size(width, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await _fonts(tester);
  await tester.pumpWidget(
    MaterialApp(
      theme: InkTheme.themeData,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(1.3)),
        child: child!,
      ),
      home: RepaintBoundary(key: key, child: screen),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(
    () => InkTheme.disableGoogleFonts = const String.fromEnvironment(
      'artFontCache',
    ).isEmpty,
  );
  for (final width in [360.0, 1280.0]) {
    for (final wreck in [false, true]) {
      testWidgets(
        'same supply menu and full-belt stowing, wreck=$wreck at $width',
        (tester) async {
          final c = _controller();
          addTearDown(c.dispose);
          c.session
            ..phase = wreck ? SessionPhase.shipwreck : SessionPhase.loot
            ..currentMonster = null
            ..hasDefeatedCurrentEncounter = true;
          c.ship!.cargo.addAll([
            for (final type in [
              ConsumableType.blastPack,
              ConsumableType.krakenInkBomb,
              ConsumableType.unstableTincture,
            ])
              generateConsumable(type, RarityLevel.common),
          ]);
          c.session.pendingLoot = [
            generateConsumable(
              ConsumableType.alchemicalPitch,
              RarityLevel.common,
            ),
          ];
          if (wreck) {
            c.session.currentWreck = WreckEncounter(
              id: 'shared',
              sighting: const WreckSighting(
                seed: 1,
                condition: WreckCondition.uncertain,
                clearClue: true,
              ),
              stage: WreckStage.receipt,
            );
            c.session.wreckSalvageReceipt = [
              '3 Sea Glass',
              '1 Depth-Wrought Iron',
              'Recovered Alchemical Pitch Flask.',
            ];
          }
          final before = c.session.profile.metaInventory.toJson();
          final key = GlobalKey();
          await _mount(
            tester,
            wreck
                ? ShipwreckScreen(controller: c, onOpenChart: () {})
                : LootScreen(controller: c),
            key,
            width,
          );
          expect(find.byType(LootSuppliesView), findsOneWidget);
          expect(find.text('SPOILS FLOATING IN THE WATER'), findsOneWidget);
          expect(find.textContaining('BELT FULL'), findsOneWidget);
          await tester.ensureVisible(find.text('SPOILS FLOATING IN THE WATER'));
          await _proof(tester, key, 'shared-loot-$wreck-$width');
          await tester.ensureVisible(find.text('Jettison').first);
          await tester.tap(find.text('Jettison').first);
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('Stow'));
          await tester.tap(find.text('Stow'));
          await tester.pumpAndSettle();
          expect(c.pendingLoot, isEmpty);
          expect(c.ship!.cargo, hasLength(3));
          expect(c.session.profile.metaInventory.toJson(), before);
          expect(c.phase, wreck ? SessionPhase.shipwreck : SessionPhase.helm);
          expect(tester.takeException(), isNull);
        },
      );
    }
    testWidgets('merchant keeps large art beside text at $width', (
      tester,
    ) async {
      final c = _controller();
      addTearDown(c.dispose);
      c.session
        ..phase = SessionPhase.merchant
        ..merchantReturnPhase = SessionPhase.stronghold;
      c.ship!.gold = 100;
      final kit = generateConsumable(
        ConsumableType.hullPatchKit,
        RarityLevel.common,
      );
      c.session.merchantStock = [
        kit,
        generateConsumable(ConsumableType.krakenInkBomb, RarityLevel.common),
        generateConsumable(ConsumableType.blastPack, RarityLevel.common),
      ];
      c.session.onSaleMerchantIndex = 1;
      final key = GlobalKey();
      await _mount(tester, MerchantScreen(controller: c), key, width);
      final art = find.byWidgetPredicate(
        (w) =>
            w is SvgAssetView && w.assetPath == SvgAssetView.pathForItem(kit),
      );
      expect(tester.getSize(art).width, 72);
      expect(
        tester.getRect(art).right,
        lessThan(tester.getRect(find.text(kit.name)).left),
      );
      await tester.ensureVisible(find.text('MERCHANT WARES FOR SALE'));
      await _proof(tester, key, 'merchant-$width');
      expect(tester.takeException(), isNull);
    });
    testWidgets('repair copy shows percentage and actual quote at $width', (
      tester,
    ) async {
      final c = _controller();
      addTearDown(c.dispose);
      c.session.phase = SessionPhase.respiteIsland;
      c.seaChart.currentDestination = CourseDestination.midpointHaven;
      c.ship!
        ..maxHp = 140
        ..currentHp = 137
        ..gold = 100;
      final key = GlobalKey();
      await _mount(
        tester,
        ParchmentScaffold(
          body: SingleChildScrollView(child: PaidRepairView(controller: c)),
        ),
        key,
        width,
      );
      expect(find.text('REPAIRS REMAINING: 25% HULL'), findsOneWidget);
      expect(find.text('REPAIR +3 HP · 3g'), findsOneWidget);
      expect(find.textContaining('normal HP'), findsNothing);
      expect(find.textContaining('Captain healing'), findsNothing);
      expect(find.textContaining('Refitting before'), findsNothing);
      expect(c.session.paidRepairWork.isLatched, isFalse);
      await _proof(tester, key, 'repair-$width');
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('home port has permanent progression and no supply shop', (
    tester,
  ) async {
    final c = _controller();
    addTearDown(c.dispose);
    c.session.phase = SessionPhase.port;
    await _mount(
      tester,
      PortScreen(controller: c, onOpenChart: () {}),
      GlobalKey(),
      1280,
    );
    expect(find.text('MERCHANT'), findsNothing);
    expect(find.text('BLUEPRINTS'), findsOneWidget);
  });
  testWidgets('full chart shows a cumulative wake and can locate the vessel', (
    tester,
  ) async {
    final c = _controller();
    addTearDown(c.dispose);
    final state = c.seaChart.toJson();
    final first = Map<String, dynamic>.from((state['voyageLog'] as List).first);
    state['voyageLog'] = [
      for (var i = 0; i < 9; i++)
        {
          ...first,
          'leg': i + 1,
          'bearing': i == 3 || i == 6
              ? NavigationalBearing.deadAhead.name
              : NavigationalBearing.larboardTack.name,
          'combatWon': i == 2 || i == 5,
        },
    ];
    state['currentLeg'] = 9;
    c.seaChart.restoreFromJson(state);
    final before = c.seaChart.toJson();
    final key = GlobalKey();
    await _mount(
      tester,
      SeaChartScreen(seaChart: c.seaChart, onClose: () {}),
      key,
      1280,
    );
    await _proof(tester, key, 'map-diagonal');
    await tester.tap(find.byKey(const ValueKey('locate-chart-vessel')));
    await tester.pumpAndSettle();
    await _proof(tester, key, 'map-locate');
    expect(c.seaChart.toJson(), before);
    expect(tester.takeException(), isNull);
  });
}
