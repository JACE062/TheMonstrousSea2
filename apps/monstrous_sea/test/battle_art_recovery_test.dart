import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/battle/monstrous_sea_battle_game.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/screens/battle_screen.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';
import 'package:monstrous_sea/src/widgets/ink_button.dart';
import 'package:monstrous_sea/src/widgets/combat_log_view.dart';
import 'package:monstrous_sea/src/widgets/pilot_art.dart';

class ControlledArtworkBundle extends CachingAssetBundle {
  final Set<String> missing = {};
  final Set<String> corrupt = {};
  final Map<String, int> loads = {};
  Completer<ByteData>? pendingShip;

  @override
  Future<ByteData> load(String key) {
    loads.update(key, (count) => count + 1, ifAbsent: () => 1);
    if (missing.contains(key)) {
      throw FlutterError('Unable to load asset: "$key"');
    }
    if (key == PilotArt.standard && pendingShip != null) {
      return pendingShip!.future;
    }
    if (corrupt.contains(key)) return Future.value(ByteData(8));
    return rootBundle.load(key);
  }
}

GameController combat({
  BlueprintId blueprint = BlueprintId.standard,
  MonsterSpecies species = MonsterSpecies.shark,
}) {
  final controller = GameController(
    session: GameSession(rng: SeededGameRng(42)),
    autoSave: false,
  )..dispatch(const BeginFirstVoyage('Art Test'));
  controller.session.ship = createFlagshipFromBlueprint(
    blueprint,
    level: 1,
    rng: SeededGameRng(7),
  );
  controller.session.currentMonster = createMonster(
    species,
    level: 1,
    rng: SeededGameRng(8),
  )..currentIntent = MonsterIntent.fromId(MonsterIntentId.sharkBreachingLunge);
  controller.clearLog();
  controller.structuredCombatLog.add(CombatLogEntry(
    message: 'Encountered ${controller.currentMonster!.name} at Medium range.',
    actor: CombatLogActor.ambient,
  ));
  return controller;
}

Future<void> mountCold(
  WidgetTester tester,
  GameController controller,
  MonstrousSeaBattleGame game, {
  double scale = 1.15,
  Key? captureKey,
}) async {
  // Start the entire cold scene load in real async time. Starting its image
  // futures under the fake widget clock and awaiting them in runAsync deadlocks
  // the engine codec callback. No assets are preloaded into the scene cache.
  await tester.runAsync(() async {
    game.onGameResize(Vector2(1280, 900));
    // Test-only startup outside the fake clock; production uses GameWidget.
    // ignore: invalid_use_of_internal_member
    await game.load();
  });
  await tester.pumpWidget(
    RepaintBoundary(
      key: captureKey,
      child: MaterialApp(
        theme: InkTheme.themeData.copyWith(
          textTheme: InkTheme.themeData.textTheme.apply(
            fontFamily: _reviewFontPath.isEmpty ? null : 'ArtRecoveryReview',
          ),
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: BattleScreen(controller: controller, game: game),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
}

const _reviewFontPath = String.fromEnvironment('reviewFontPath');

Future<void> captureReview(
  WidgetTester tester,
  GlobalKey key,
  String name,
) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final output = File('build/art-recovery-$name.png');
    await output.parent.create(recursive: true);
    await output.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    InkTheme.disableGoogleFonts = true;
    if (_reviewFontPath.isNotEmpty) {
      final loader = FontLoader('ArtRecoveryReview')
        ..addFont(
          File(_reviewFontPath).readAsBytes().then(ByteData.sublistView),
        );
      await loader.load();
      final labels = FontLoader('Arial')
        ..addFont(File(_reviewFontPath).readAsBytes().then(ByteData.sublistView));
      await labels.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    }
  });

  testWidgets(
    'successive cold scenes load full bundled paths with no prewarming',
    (tester) async {
      for (final species in [
        MonsterSpecies.shark,
        MonsterSpecies.crustacean,
        MonsterSpecies.squid,
      ]) {
        final controller = combat(species: species);
        final bundle = ControlledArtworkBundle();
        final game = MonstrousSeaBattleGame(
          ship: controller.ship!,
          monster: controller.currentMonster!,
          assetBundle: bundle,
        );
        await mountCold(tester, controller, game);
        expect(game.isLoaded, isTrue);
        expect(game.isShipArtUnavailable, isFalse);
        expect(game.isMonsterArtUnavailable, isFalse);
        expect(bundle.loads[PilotArt.standard], 1);
        expect(
          bundle.loads.keys.any((path) => path.startsWith('assets/images/')),
          isFalse,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        controller.dispose();
      }
    },
  );

  for (final width in [360.0, 1280.0]) {
    for (final scale in [1.15, 1.3]) {
      testWidgets(
        'missing ship art stays playable and retries at $width / $scale',
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final controller = combat();
          addTearDown(controller.dispose);
          final bundle = ControlledArtworkBundle()
            ..missing.add(PilotArt.standard);
          final game = MonstrousSeaBattleGame(
            ship: controller.ship!,
            monster: controller.currentMonster!,
            assetBundle: bundle,
          );
          final captureKey = GlobalKey();
          await mountCold(
            tester,
            controller,
            game,
            scale: scale,
            captureKey: captureKey,
          );
          if (_reviewFontPath.isNotEmpty && width == 1280 && scale == 1.3) {
            await captureReview(tester, captureKey, 'missing');
          }
          expect(game.isLoaded, isTrue);
          expect(game.isShipArtUnavailable, isTrue);
          expect(game.isMonsterArtUnavailable, isFalse);
          expect(find.text('RETRY ART'), findsOneWidget);
          expect(find.byType(ErrorWidget), findsNothing);
          final round = controller.session.battleRound;
          await tester.tap(find.text('Naval Cannon Battery'));
          for (var tick = 0; tick < 100 && controller.isPlayingEvents; tick++) {
            await tester.pump(const Duration(milliseconds: 200));
          }
          await tester.pump();
          expect(controller.isPlayingEvents, isFalse);
          expect(controller.session.battleRound, greaterThan(round));
          final cannon = tester.widget<InkButton>(
            find.ancestor(
              of: find.text('Naval Cannon Battery'),
              matching: find.byType(InkButton),
            ),
          );
          expect(
            cannon.onPressed,
            isNotNull,
            reason: 'Failed art must not lock the action queue',
          );
          bundle.missing.clear();
          await tester.runAsync(game.retryArtwork);
          await tester.pump();
          expect(game.isShipArtUnavailable, isFalse);
          expect(bundle.loads[PilotArt.standard], 2);
          expect(find.text('RETRY ART'), findsNothing);
          if (_reviewFontPath.isNotEmpty && width == 1280 && scale == 1.3) {
            await captureReview(tester, captureKey, 'recovered');
          }
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }

  testWidgets('an undecodable PNG does not poison the image cache', (
    tester,
  ) async {
    final controller = combat();
    addTearDown(controller.dispose);
    final bundle = ControlledArtworkBundle()..corrupt.add(PilotArt.standard);
    final game = MonstrousSeaBattleGame(
      ship: controller.ship!,
      monster: controller.currentMonster!,
      assetBundle: bundle,
    );
    await mountCold(tester, controller, game);
    expect(game.isShipArtUnavailable, isTrue);
    expect(game.images.containsKey(PilotArt.standard), isFalse);
    bundle.corrupt.clear();
    await tester.runAsync(game.retryArtwork);
    await tester.pump();
    expect(game.isShipArtUnavailable, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'both missing illustrations remain recoverable after a failed retry',
    (tester) async {
      final controller = combat();
      addTearDown(controller.dispose);
      final bundle = ControlledArtworkBundle()
        ..missing.addAll([PilotArt.standard, PilotArt.shark]);
      final game = MonstrousSeaBattleGame(
        ship: controller.ship!,
        monster: controller.currentMonster!,
        assetBundle: bundle,
      );
      await mountCold(tester, controller, game);
      await tester.runAsync(game.retryArtwork);
      await tester.pump();
      expect(game.isShipArtUnavailable && game.isMonsterArtUnavailable, isTrue);
      expect(game.isRetryingArtwork, isFalse);
      bundle.missing.clear();
      await tester.runAsync(game.retryArtwork);
      await tester.pump();
      expect(
        game.isShipArtUnavailable || game.isMonsterArtUnavailable,
        isFalse,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('a pending retry can finish after the scene is removed', (
    tester,
  ) async {
    final controller = combat();
    addTearDown(controller.dispose);
    final bundle = ControlledArtworkBundle()..missing.add(PilotArt.standard);
    final game = MonstrousSeaBattleGame(
      ship: controller.ship!,
      monster: controller.currentMonster!,
      assetBundle: bundle,
    );
    await mountCold(tester, controller, game);
    bundle.missing.clear();
    bundle.pendingShip = Completer<ByteData>();
    final retry = game.retryArtwork();
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() async {
      bundle.pendingShip!.complete(await rootBundle.load(PilotArt.standard));
      await retry;
    });
    expect(tester.takeException(), isNull);
  });

  testWidgets('battle entry, action playback and reopening respect the Chronicle', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = combat();
    addTearDown(controller.dispose);
    controller.structuredCombatLog.insertAll(0, List.generate(120, (i) => CombatLogEntry(
      message: 'Earlier encounter action $i', actor: CombatLogActor.ship,
    )));
    final game = MonstrousSeaBattleGame(ship: controller.ship!, monster: controller.currentMonster!);
    final captureKey = GlobalKey();
    await mountCold(tester, controller, game, scale: 1.3, captureKey: captureKey);
    game.pauseEngine();
    await tester.pumpAndSettle();
    final scrollable = find.descendant(of: find.byType(CombatLogView), matching: find.byType(Scrollable));
    var position = tester.state<ScrollableState>(scrollable).position;
    expect(position.extentAfter, 0, reason: 'Entry should show the intent before any action');
    await tester.drag(scrollable, const Offset(0, 100));
    await tester.pumpAndSettle();
    final readingOffset = position.pixels;
    final count = controller.structuredCombatLog.length;
    game.resumeEngine();
    await tester.tap(find.text('Naval Cannon Battery'));
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    game.pauseEngine();
    await tester.pumpAndSettle();
    expect(controller.structuredCombatLog.length, greaterThan(count));
    expect(position.pixels, closeTo(readingOffset, 0.01));
    expect(find.text('LATEST MESSAGES'), findsOneWidget);
    if (_reviewFontPath.isNotEmpty) {
      await captureReview(tester, captureKey, 'chronicle-history');
    }
    await tester.tap(find.byTooltip('Chronicle Log'));
    await tester.pump();
    expect(find.byType(CombatLogView), findsNothing);
    await tester.tap(find.byTooltip('Chronicle Log'));
    await tester.pumpAndSettle();
    position = tester.state<ScrollableState>(scrollable).position;
    expect(position.extentAfter, 0);
    if (_reviewFontPath.isNotEmpty) {
      await captureReview(tester, captureKey, 'chronicle-latest');
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
