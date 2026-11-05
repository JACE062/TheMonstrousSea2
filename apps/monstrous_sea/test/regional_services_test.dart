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
import 'package:monstrous_sea/src/screens/helm_screen.dart';
import 'package:monstrous_sea/src/screens/respite_island_screen.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';

class _FontCache extends PathProviderPlatform {
  _FontCache(this.path);
  final String path;
  @override
  Future<String?> getApplicationSupportPath() async => path;
}

GameController _preparation() {
  final controller = GameController(
    session: GameSession(rng: SeededGameRng(14)),
    autoSave: false,
  )..dispatch(const BeginFirstVoyage('Preparation test'));
  controller.session.phase = SessionPhase.restArea;
  controller.seaChart.currentLeg = controller.seaChart.totalLegs - 1;
  controller.ship!.gold = 1000;
  controller.ship!.currentHp = 20;
  controller.dispatch(const TakeHelm());
  return controller;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const fontCache = String.fromEnvironment('artFontCache');
  setUpAll(() => InkTheme.disableGoogleFonts = fontCache.isEmpty);

  for (final width in [360.0, 1280.0]) {
    testWidgets(
      'final preparation and refit station are distinct services at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        if (fontCache.isNotEmpty) {
          final previous = PathProviderPlatform.instance;
          PathProviderPlatform.instance = _FontCache(fontCache);
          addTearDown(() => PathProviderPlatform.instance = previous);
          await tester.runAsync(() async {
            await (FontLoader('MaterialIcons')
                  ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
                .load();
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
        final controller = _preparation();
        addTearDown(controller.dispose);
        final boundary = GlobalKey();
        Widget app(Widget screen) => MaterialApp(
          theme: InkTheme.themeData,
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(width, 1200),
              textScaler: const TextScaler.linear(1.3),
            ),
            child: RepaintBoundary(key: boundary, child: screen),
          ),
        );
        await tester.pumpWidget(
          app(HelmScreen(controller: controller, onOpenChart: () {})),
        );
        await tester.pumpAndSettle();
        expect(find.text('STEER THIS HEADING'), findsNWidgets(2));
        expect(
          find.textContaining('Shipwright station to port'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Specialist merchant to starboard'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        const proofPrefix = String.fromEnvironment('navigationProofPath');
        Future<void> proof(String name) async {
          if (proofPrefix.isEmpty) return;
          await tester.runAsync(() async {
            final image =
                await (boundary.currentContext!.findRenderObject()
                        as RenderRepaintBoundary)
                    .toImage();
            try {
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await File('$proofPrefix-$name-$width.png')
                  .writeAsBytes(bytes!.buffer.asUint8List());
            } finally {
              image.dispose();
            }
          });
        }

        await proof('choices');
        controller.dispatch(
          const SteerCourse(NavigationalBearing.larboardTack),
        );
        expect(controller.session.isRepairRefitStop, isTrue);
        await tester.pumpWidget(
          app(RespiteIslandScreen(controller: controller, onOpenChart: () {})),
        );
        await tester.pumpAndSettle();
        expect(find.text('FINAL PREPARATION SHIPWRIGHT'), findsOneWidget);
        expect(find.text('VOYAGE SHIPWRIGHT'), findsOneWidget);
        expect(find.text('Gunnery & Battery Drills'), findsNothing);
        expect(find.text('FORAGE SHOALS'), findsNothing);
        expect(find.text('CAREEN HULL'), findsNothing);
        expect(tester.takeException(), isNull);
        await proof('refit');
        controller.dispatch(const DepartIsland());
        expect(
          controller.currentCourseOptions.single.destination,
          CourseDestination.titan,
        );
        controller.dispatch(const SteerCourse(NavigationalBearing.deadAhead));
        expect(controller.currentMonster!.species, MonsterSpecies.kraken);
      },
    );
  }
}
