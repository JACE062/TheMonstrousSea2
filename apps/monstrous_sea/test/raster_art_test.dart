import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:monstrous_sea/src/battle/monstrous_sea_battle_game.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/screens/battle_screen.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';
import 'package:monstrous_sea/src/widgets/pilot_art.dart';

class _ArtFontCache extends PathProviderPlatform {
  _ArtFontCache(this.path);
  final String path;

  @override
  Future<String?> getApplicationSupportPath() async => path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const fontCache = String.fromEnvironment('artFontCache');
  if (fontCache.isEmpty) {
    InkTheme.disableGoogleFonts = true;
  }

  setUp(() {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      final msg = details.exception.toString();
      if (msg.contains('Failed to load font') || msg.contains('google_fonts')) {
        return;
      }
      originalOnError?.call(details);
    };
  });

  test('The art bundle contains exactly the active illustrations', () async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final bundled = manifest.listAssets().where(
      (asset) => asset.startsWith('assets/art/'),
    );
    expect(bundled, unorderedEquals(PilotArt.allAssets));
  });

  for (final asset in PilotArt.allAssets) {
    test('$asset decodes from the bundle with real transparency', () async {
      final source = await rootBundle.load(asset);
      final codec = await ui.instantiateImageCodec(source.buffer.asUint8List());
      try {
        final frame = await codec.getNextFrame();
        try {
          expect(frame.image.width, greaterThanOrEqualTo(1024));
          expect(frame.image.height, greaterThanOrEqualTo(1024));
          final rgba = await frame.image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          final pixels = rgba!.buffer.asUint8List();
          var transparent = 0;
          var painted = 0;
          for (var i = 3; i < pixels.length; i += 4) {
            if (pixels[i] == 0) transparent++;
            if (pixels[i] > 200) painted++;
          }
          expect(transparent, greaterThan(pixels.length ~/ 40));
          expect(painted, greaterThan(pixels.length ~/ 40));
          // Near-zero alpha (1/255) in generated padding is visually clear.
          // Check all four corners while rejecting a visible background box.
          final width = frame.image.width;
          final height = frame.image.height;
          for (final pixel in [
            0,
            width - 1,
            (height - 1) * width,
            width * height - 1,
          ]) {
            expect(
              pixels[pixel * 4 + 3],
              lessThanOrEqualTo(2),
              reason: 'The cutout must not carry a paper box',
            );
          }
        } finally {
          frame.image.dispose();
        }
      } finally {
        codec.dispose();
      }
    });
  }

  for (final encounter in [
    (
      shipClass: ShipClass.freighter,
      species: MonsterSpecies.kraken,
      dutchman: false,
    ),
    (
      shipClass: ShipClass.freighter,
      species: MonsterSpecies.squid,
      dutchman: false,
    ),
    (
      shipClass: ShipClass.standard,
      species: MonsterSpecies.shark,
      dutchman: false,
    ),
    (
      shipClass: ShipClass.ironclad,
      species: MonsterSpecies.serpent,
      dutchman: false,
    ),
    (
      shipClass: ShipClass.corvette,
      species: MonsterSpecies.jellyfish,
      dutchman: false,
    ),
    (
      shipClass: ShipClass.ironclad,
      species: MonsterSpecies.crustacean,
      dutchman: true,
    ),
  ]) {
    final isBoss = encounter.species == MonsterSpecies.kraken;
    final sceneName =
        '${encounter.dutchman ? 'dutchman' : encounter.shipClass.name}-${encounter.species.name}';
    testWidgets('$sceneName loads both sprites and survives resize', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1100, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = GameController(
        session: GameSession(rng: SeededGameRng(42)),
      );
      controller.dispatch(const NameCaptain('Captain Ahab'));
      controller.dispatch(ChooseShip(encounter.shipClass));
      if (encounter.dutchman) controller.session.ship = createFlyingDutchman();
      controller.session.currentMonster = createMonster(
        encounter.species,
        level: 1,
        rng: SeededGameRng(11),
        name: isBoss ? 'Colossal Kraken' : 'Abyssal ${encounter.species.name}',
      );
      controller.session.phase = SessionPhase.battle;
      final shipArt = PilotArt.forShip(controller.ship!);
      final monsterArt = PilotArt.forMonster(controller.currentMonster!);

      final game = MonstrousSeaBattleGame(
        ship: controller.ship!,
        monster: controller.currentMonster!,
      );
      // Decode in real async time before Flame enters the widget-test clock.
      await tester.runAsync(() async {
        await game.images.load(shipArt);
        await game.images.load(monsterArt);
      });

      if (fontCache.isNotEmpty) {
        // Windows resolves path_provider through its platform interface.
        final previousProvider = PathProviderPlatform.instance;
        PathProviderPlatform.instance = _ArtFontCache(fontCache);
        addTearDown(() => PathProviderPlatform.instance = previousProvider);
        await tester.runAsync(() async {
          final icons = FontLoader('MaterialIcons')
            ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
          await icons.load();
          InkTheme.themeData;
          await GoogleFonts.pendingFonts([
            InkTheme.titleMedium,
            InkTheme.caption,
            InkTheme.statLabel,
            InkTheme.statValue,
          ]);
        });
      }

      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: InkTheme.themeData,
          home: RepaintBoundary(
            key: boundaryKey,
            child: BattleScreen(controller: controller, game: game),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(game.isLoaded, isTrue);
      game.pauseEngine();
      await tester.pump();

      expect(game.images.containsKey(shipArt), isTrue);
      expect(game.images.containsKey(monsterArt), isTrue);
      if (isBoss) expect(find.textContaining('25 Tentacles'), findsOneWidget);
      expect(tester.takeException(), isNull);

      Future<void> expectVisibleArt() async {
        final status = tester.getRect(
          find.byWidgetPredicate(
            (widget) => widget is Row && widget.key is GlobalKey,
          ),
        );
        final dock = tester.getRect(
          find.byWidgetPredicate(
            (widget) => widget is Container && widget.key is GlobalKey,
          ),
        );
        final sprites = game.children
            .whereType<PositionComponent>()
            .where(
              (component) =>
                  component.anchor == Anchor.center && component.width > 0,
            )
            .toList();
        expect(sprites, hasLength(2));
        for (final sprite in sprites) {
          expect(
            sprite.y - sprite.height / 2,
            greaterThanOrEqualTo(status.bottom + 8),
          );
          expect(sprite.y + sprite.height / 2, lessThanOrEqualTo(dock.top - 8));
        }
        // Inspect actual ink pixels too: logical bounds alone cannot detect
        // a renderer applying the centre anchor twice.
        await tester.runAsync(() async {
          final bounds = sprites
              .map(
                (sprite) => Rect.fromCenter(
                  center: Offset(sprite.x, sprite.y),
                  width: sprite.width,
                  height: sprite.height,
                ).inflate(max(sprite.width, sprite.height) * 0.05),
              )
              .toList();
          final recorder = ui.PictureRecorder();
          game.render(Canvas(recorder));
          final picture = recorder.endRecording();
          final width = game.size.x.ceil();
          final image = await picture.toImage(width, game.size.y.ceil());
          try {
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            );
            final rgba = bytes!.buffer.asUint8List();
            var ink = 0;
            var misplaced = 0;
            for (var i = 0; i < rgba.length; i += 4) {
              if (rgba[i + 3] > 200 &&
                  rgba[i] < 80 &&
                  rgba[i + 1] < 80 &&
                  rgba[i + 2] < 80) {
                ink++;
                final pixel = i ~/ 4;
                final point = Offset(
                  (pixel % width).toDouble(),
                  (pixel ~/ width).toDouble(),
                );
                if (!bounds.any((bound) => bound.contains(point))) misplaced++;
              }
            }
            expect(
              ink,
              greaterThan(100),
              reason: 'The scene must paint both illustrations',
            );
            expect(
              misplaced,
              0,
              reason: 'Painted ink must remain in the combatant bounds',
            );
          } finally {
            image.dispose();
            picture.dispose();
          }
        });
      }

      await expectVisibleArt();

      const configuredProof = String.fromEnvironment('artProofPath');
      final proofPath = isBoss
          ? configuredProof
          : configuredProof.replaceFirst('.png', '-$sceneName.png');
      Future<void> saveProof(String output) async {
        if (output.isEmpty) return;
        await tester.runAsync(() async {
          final boundary =
              boundaryKey.currentContext!.findRenderObject()
                  as RenderRepaintBoundary;
          final image = await boundary.toImage();
          try {
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await File(output).writeAsBytes(bytes!.buffer.asUint8List());
          } finally {
            image.dispose();
          }
        });
      }

      await saveProof(proofPath);

      tester.view.physicalSize = const Size(800, 600);
      await tester.pump();
      await tester.pump();
      expect(tester.takeException(), isNull);
      await expectVisibleArt();
      if (proofPath.isNotEmpty) {
        await saveProof(proofPath.replaceFirst('.png', '-compact.png'));
      }

      // The art must also fit after the chronicle changes the dock height.
      await tester.tap(find.byTooltip('Chronicle Log'));
      game.resumeEngine();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      game.pauseEngine();
      await tester.pump();
      expect(tester.takeException(), isNull);
      await expectVisibleArt();
      if (proofPath.isNotEmpty) {
        await saveProof(proofPath.replaceFirst('.png', '-compact-art.png'));
      }

      if (encounter.shipClass == ShipClass.freighter) {
        await tester.tap(find.textContaining('Chain-Shot Broadside'));
        final frameCount = isBoss ? 20 : 6;
        for (var frame = 0; frame < frameCount; frame++) {
          await tester.pump(const Duration(milliseconds: 500));
        }
        expect(controller.session.battleRound, 1);
        expect(controller.lastEvents.whereType<AttackAttempted>(), isNotEmpty);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    });
  }
}
