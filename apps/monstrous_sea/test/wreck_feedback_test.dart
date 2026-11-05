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
import 'package:monstrous_sea/src/screens/shipwreck_screen.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';

class _WreckFontCache extends PathProviderPlatform {
  _WreckFontCache(this.path);
  final String path;
  @override
  Future<String?> getApplicationSupportPath() async => path;
}

Future<void> mountWreck(
  WidgetTester tester,
  GameController controller,
  double scale, {
  Key? captureKey,
}) async {
  const fontCache = String.fromEnvironment('artFontCache');
  InkTheme.disableGoogleFonts = fontCache.isEmpty;
  if (fontCache.isNotEmpty) {
    final previous = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _WreckFontCache(fontCache);
    addTearDown(() => PathProviderPlatform.instance = previous);
    await tester.runAsync(() async {
      await (FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      InkTheme.themeData;
      await GoogleFonts.pendingFonts([InkTheme.titleLarge, InkTheme.titleMedium,
        InkTheme.subtitle, InkTheme.body, InkTheme.bodyBold, InkTheme.caption,
        InkTheme.statLabel, InkTheme.statValue]);
    });
  }
  final boundary = captureKey ?? GlobalKey();
  await tester.pumpWidget(
    RepaintBoundary(
      key: boundary,
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: ListenableBuilder(
          listenable: controller,
          builder: (context, _) =>
              ShipwreckScreen(controller: controller, onOpenChart: () {}),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  const proof = String.fromEnvironment('wreckProofPath');
  if (proof.isNotEmpty && boundary is GlobalKey) {
    await tester.runAsync(() async {
      final image = await (boundary.currentContext!.findRenderObject() as RenderRepaintBoundary).toImage();
      try {
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final wreck = controller.session.currentWreck!;
        await File('$proof-${wreck.condition.name}-${wreck.stage.name}-${tester.view.physicalSize.width}-$scale.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
      } finally {
        image.dispose();
      }
    });
  }
}

GameController fullWreck() {
  final controller = GameController(
    session: GameSession(rng: SeededGameRng(42)),
    autoSave: false,
  )..dispatch(const BeginFirstVoyage('Salvager'));
  controller.session.phase = SessionPhase.shipwreck;
  controller.session.hasSalvagedCurrentWreck = true;
  controller.session.currentShipwreckName = 'The Forgotten Brig';
  controller.session.currentWreck = WreckEncounter(id: 'feedback-wreck',
    sighting: const WreckSighting(seed: 81, condition: WreckCondition.uncertain, clearClue: true),
    stage: WreckStage.receipt);
  for (var i = 0; i < controller.ship!.maxCargo; i++) {
    controller.ship!.addCargo(randomConsumable(1, SeededGameRng(i)));
  }
  controller.session.pendingLoot = [randomConsumable(1, SeededGameRng(55))];
  controller.session.wreckSalvageReceipt = [
    '3 Sea Glass',
    '1 Depth-Wrought Iron',
    'Recovered ${controller.pendingLoot.single.name}.',
  ];
  return controller;
}

void main() {
  for (final width in [360.0, 1280.0]) {
    for (final scale in [1.15, 1.3]) {
      testWidgets('salvage receipt and belt recovery at $width, text $scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = fullWreck();
        addTearDown(controller.dispose);
        await mountWreck(tester, controller, scale);
        expect(
          find.textContaining('3 Sea Glass\n1 Depth-Wrought Iron'),
          findsOneWidget,
        );
        expect(find.textContaining('BELT FULL'), findsOneWidget);
        final jettison = find.text('Jettison');
        await tester.ensureVisible(jettison.first);
        await tester.tap(jettison.first);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Stow'));
        await tester.tap(find.text('Stow'));
        await tester.pumpAndSettle();
        expect(controller.pendingLoot, isEmpty);
        expect(controller.phase, SessionPhase.shipwreck);
        await tester.ensureVisible(find.text('LEAVE WRECK & TAKE THE HELM'));
        await tester.tap(find.text('LEAVE WRECK & TAKE THE HELM'));
        await tester.pumpAndSettle();
        expect(controller.phase, SessionPhase.helm);
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final condition in WreckCondition.values) {
    testWidgets('$condition presents only its legal recovery choices and consistent Apex warning', (tester) async {
      tester.view.physicalSize = const Size(360, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = fullWreck();
      addTearDown(controller.dispose);
      controller.session.hasSalvagedCurrentWreck = false;
      controller.pendingLoot.clear();
      controller.session.currentWreck = WreckEncounter(id: 'assessment',
        sighting: WreckSighting(seed: 81, condition: condition, clearClue: true));
      await mountWreck(tester, controller, 1.3);
      expect(find.text('QUICK SALVAGE & LEAVE'), condition == WreckCondition.fresh ? findsNothing : findsOneWidget);
      expect(find.textContaining('An Apex predator may appear'), condition == WreckCondition.pickedClean ? findsNothing : findsOneWidget);
      expect(find.text('SAIL PAST EMPTY'), findsOneWidget);
      expect(find.text('SEARCH HOLD'), findsNothing);
      expect(find.text('CRACK CHEST'), findsNothing);
      expect(find.text('STRIP TIMBERS'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
