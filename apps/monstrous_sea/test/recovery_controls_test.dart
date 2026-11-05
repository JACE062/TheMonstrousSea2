import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/main.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/screens/helm_screen.dart';
import 'package:monstrous_sea/src/screens/shipwreck_screen.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';
import 'package:monstrous_sea/src/widgets/hull_patch_kit_button.dart';
import 'package:monstrous_sea/src/widgets/ink_button.dart';
import 'package:monstrous_sea/src/widgets/paid_repair_view.dart';
import 'package:monstrous_sea/src/widgets/parchment_scaffold.dart';
import 'package:monstrous_sea/src/widgets/voyage_shipwright_view.dart';

class _RecoveryFontCache extends PathProviderPlatform {
  _RecoveryFontCache(this.path);
  final String path;
  @override
  Future<String?> getApplicationSupportPath() async => path;
}

Future<void> _fonts(WidgetTester tester) async {
  const cache = String.fromEnvironment('artFontCache');
  if (cache.isEmpty) return;
  final previous = PathProviderPlatform.instance;
  PathProviderPlatform.instance = _RecoveryFontCache(cache);
  addTearDown(() => PathProviderPlatform.instance = previous);
  await tester.runAsync(() async {
    await (FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    InkTheme.themeData;
    await GoogleFonts.pendingFonts([InkTheme.titleLarge, InkTheme.titleMedium,
      InkTheme.subtitle, InkTheme.body, InkTheme.bodyBold, InkTheme.caption,
      InkTheme.statLabel, InkTheme.statValue]);
  });
}

Future<void> _proof(WidgetTester tester, GlobalKey boundary, String name) async {
  const prefix = String.fromEnvironment('recoveryProofPath');
  if (prefix.isEmpty) return;
  await tester.runAsync(() async {
    final image = await (boundary.currentContext!.findRenderObject() as RenderRepaintBoundary).toImage();
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('$prefix-$name.png').writeAsBytes(data!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

GameController _loot({bool carried = false, bool wreck = false}) {
  final controller = GameController(
    session: GameSession(rng: SeededGameRng(7)),
    autoSave: false,
  )..dispatch(const BeginFirstVoyage('Recovery controls'));
  controller.session.phase = SessionPhase.loot;
  controller.session.hasDefeatedCurrentEncounter = true;
  controller.ship!
    ..maxHp = 91
    ..currentHp = 1;
  for (var i = 0; i < controller.ship!.maxCargo; i++) {
    controller.ship!.cargo.add(
      generateConsumable(
        carried && i == 0
            ? ConsumableType.hullPatchKit
            : ConsumableType.blastPack,
        RarityLevel.common,
        id: 'belt-$i',
      ),
    );
  }
  controller.session.pendingLoot = [
    generateConsumable(
      carried ? ConsumableType.blastPack : ConsumableType.hullPatchKit,
      RarityLevel.common,
      id: 'pending',
    ),
  ];
  if (wreck) {
    controller.session.currentShipwreckName = 'Cleared Derelict';
    controller.session.currentWreck = WreckEncounter(
      id: 'cleared',
      sighting: const WreckSighting(
        seed: 81,
        condition: WreckCondition.fresh,
        clearClue: true,
      ),
      stage: WreckStage.recovery,
      threatCleared: true,
      cargo: const WreckCargo(seaGlass: 3, iron: 1, gold: 20, supplies: []),
    );
  }
  return controller;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const fontCache = String.fromEnvironment('artFontCache');
  setUpAll(() => InkTheme.disableGoogleFonts = fontCache.isEmpty);

  testWidgets('small purse can buy partial work without opening a new allowance', (tester) async {
    tester.view.physicalSize = const Size(360, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = _loot();
    addTearDown(c.dispose);
    c.session.phase = SessionPhase.respiteIsland;
    c.seaChart.currentDestination = CourseDestination.midpointHaven;
    c.ship!..maxHp = 200..currentHp = 1..gold = 7;
    await _fonts(tester);
    final boundary = GlobalKey();
    await tester.pumpWidget(MaterialApp(theme: InkTheme.themeData,
      builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.3)), child: child!),
      home: RepaintBoundary(key: boundary, child: ParchmentScaffold(body: SingleChildScrollView(child: PaidRepairView(controller: c))))));
    await tester.pumpAndSettle();
    expect(c.session.paidRepairWork.isLatched, isFalse);
    final button = find.byKey(const ValueKey('paid-repair-affordable'));
    expect(button, findsOneWidget);
    await _proof(tester, boundary, 'small-purse-repair');
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(c.ship!.currentHp, 8);
    expect(c.ship!.gold, 0);
    expect(c.session.paidRepairWork.spentWork, 7);
    expect(c.session.paidRepairWork.totalWork, 50);
    expect(find.textContaining('21.5% HULL'), findsOneWidget);
    expect(find.byKey(const ValueKey('paid-repair-affordable')), findsNothing);
    expect(tester.takeException(), isNull);
  });
  for (final width in [360.0, 1280.0]) {
    for (final wreck in [false, true]) {
      testWidgets('full belt directly uses found kit, wreck=$wreck at $width', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = _loot(wreck: wreck);
        addTearDown(controller.dispose);
        final belt = controller.ship!.cargo.map((item) => item.id).toList();
        await _fonts(tester);
        final boundary = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            theme: InkTheme.themeData,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
            home: RepaintBoundary(key: boundary, child: GameOrchestratorView(controller: controller, skipIntro: true)),
          ),
        );
        await tester.pumpAndSettle();
        final patch = find.byKey(const ValueKey('hull-patch-pending-pending'));
        expect(patch, findsOneWidget);
        await _proof(tester, boundary, 'pending-$wreck-$width');
        final stale = tester.widget<InkButton>(patch).onPressed!;
        await tester.ensureVisible(patch);
        await tester.tap(patch);
        await tester.pumpAndSettle();
        expect(controller.ship!.currentHp, 28);
        expect(controller.ship!.cargo.map((item) => item.id).toList(), belt);
        expect(controller.pendingLoot, isEmpty);
        expect(() => stale(), throwsStateError);
        if (wreck) {
          expect(controller.phase, SessionPhase.shipwreck);
          expect(find.byType(ShipwreckScreen), findsOneWidget);
          expect(find.text('RECOVER CARGO'), findsOneWidget);
          expect(controller.profile.metaInventory.seaGlass, 0);
        } else {
          expect(controller.phase, SessionPhase.helm);
          expect(find.byType(HelmScreen), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }

    testWidgets(
      'carried kit frees a slot without automatically taking loot at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = _loot(carried: true);
        addTearDown(controller.dispose);
        await _fonts(tester);
        await tester.pumpWidget(
          MaterialApp(
            theme: InkTheme.themeData,
            home: GameOrchestratorView(controller: controller, skipIntro: true),
          ),
        );
        await tester.pumpAndSettle();
        final patch = find.byKey(const ValueKey('hull-patch-carried-belt-0'));
        await tester.ensureVisible(patch);
        await tester.tap(patch);
        await tester.pumpAndSettle();
        expect(controller.phase, SessionPhase.loot);
        expect(controller.ship!.cargo, hasLength(2));
        expect(controller.pendingLoot.single.id, 'pending');
        expect(controller.ship!.currentHp, 28);
        controller.dispatch(const TakeAllLoot());
        expect(controller.phase, SessionPhase.helm);
        expect(controller.ship!.cargo, hasLength(3));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets(
    'full-hull feedback keeps kit and shop stock has no use shortcut',
    (tester) async {
      final controller = _loot();
      addTearDown(controller.dispose);
      controller.ship!.currentHp = 91;
      await _fonts(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: HullPatchKitButton(
            controller: controller,
            itemId: 'pending',
            fromPendingLoot: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final button = tester.widget<InkButton>(find.byType(InkButton));
      expect(button.onPressed, isNull);
      expect(find.text('HULL FULL · KEEP KIT'), findsOneWidget);
      controller.session.phase = SessionPhase.merchant;
      controller.session.merchantStock = [controller.pendingLoot.single];
      controller.notify();
      await tester.pumpAndSettle();
      expect(find.byType(InkButton), findsNothing);
      expect(controller.session.merchantStock, hasLength(1));
    },
  );

  testWidgets(
    'repair view does not latch; first purchase and upgrades preserve spent work',
    (tester) async {
      tester.view.physicalSize = const Size(360, 1300);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = _loot();
      addTearDown(controller.dispose);
      controller.session.phase = SessionPhase.respiteIsland;
      controller.seaChart.currentDestination = CourseDestination.midpointHaven;
      controller.ship!
        ..maxHp = 200
        ..currentHp = 1
        ..gold = 10000;
      await _fonts(tester);
      final boundary = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: InkTheme.themeData,
          home: RepaintBoundary(key: boundary, child: ParchmentScaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  VoyageShipwrightView(controller: controller),
                  PaidRepairView(controller: controller),
                ],
              ),
            ),
          )),
        ),
      );
      await tester.pumpAndSettle();
      expect(controller.session.paidRepairWork.isLatched, isFalse);
      expect(find.textContaining('25% HULL'), findsOneWidget);
      await _proof(tester, boundary, 'repair-before-purchase');
      await tester.ensureVisible(find.text('UPGRADE TIER · 100g'));
      await tester.tap(find.text('UPGRADE TIER · 100g'));
      await tester.pumpAndSettle();
      expect(controller.session.paidRepairWork.isLatched, isFalse);
      expect(find.textContaining('24.8% HULL'), findsOneWidget);
      final buy = find.byKey(const ValueKey('paid-repair-1.0'));
      await tester.ensureVisible(buy);
      await tester.tap(buy);
      await tester.pumpAndSettle();
      expect(controller.session.paidRepairWork.maximumHullBasis, 250);
      expect(controller.session.paidRepairWork.spentWork, 62);
      await tester.ensureVisible(find.text('UPGRADE TIER · 250g'));
      await tester.tap(find.text('UPGRADE TIER · 250g'));
      await tester.pumpAndSettle();
      expect(controller.session.paidRepairWork.totalWork, 62);
      expect(find.textContaining('0% HULL'), findsOneWidget);
      expect(tester.widget<InkButton>(buy).onPressed, isNull);
      expect(controller.ship!.currentHp, 163);
      expect(tester.takeException(), isNull);
    },
  );
}
