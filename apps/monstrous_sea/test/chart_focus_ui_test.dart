import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/screens/helm_screen.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';
import 'package:monstrous_sea/src/widgets/armory_view.dart';
import 'package:monstrous_sea/src/widgets/nautical_chart.dart';
import 'package:monstrous_sea/src/widgets/pilot_art.dart';
import 'package:monstrous_sea/src/widgets/svg_asset_view.dart';

class _Fonts extends PathProviderPlatform {
  _Fonts(this.path);
  final String path;
  @override
  Future<String?> getApplicationSupportPath() async => path;
}

Future<void> _fonts(WidgetTester tester) async {
  const path = String.fromEnvironment('artFontCache');
  if (path.isEmpty) return;
  final previous = PathProviderPlatform.instance;
  PathProviderPlatform.instance = _Fonts(path);
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

Future<void> captureChartFocusProof(
  WidgetTester tester,
  GlobalKey key,
  String name,
) async {
  const prefix = String.fromEnvironment('mapFocusProofPath');
  if (prefix.isEmpty) return;
  await tester.runAsync(() async {
    for (final asset in [
      PilotArt.portHaven,
      PilotArt.standard,
      PilotArt.defeatedMonster,
      PilotArt.treasure,
      PilotArt.anchor,
      PilotArt.freighter,
      PilotArt.shark,
      PilotArt.squid,
      PilotArt.serpent,
    ]) {
      await precacheImage(AssetImage(asset), key.currentContext!);
    }
  });
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final image =
        await (key.currentContext!.findRenderObject() as RenderRepaintBoundary)
            .toImage();
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('$prefix-$name.png').writeAsBytes(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

GameController chartFocusController({bool flat = false, int legs = 12}) {
  final c = GameController(
    session: GameSession(rng: SeededGameRng(24)),
    autoSave: false,
  )..dispatch(const BeginFirstVoyage('Cartographer'));
  final state = c.seaChart.toJson();
  final first = Map<String, dynamic>.from((state['voyageLog'] as List).first);
  state['voyageLog'] = [
    for (var i = 0; i < legs; i++)
      {
        ...first,
        'leg': i % 12 + 1,
        'regionIndex': i ~/ 12,
        'bearing': flat || i % 4 == 0
            ? NavigationalBearing.deadAhead.name
            : i % 3 == 0
            ? NavigationalBearing.starboardTack.name
            : NavigationalBearing.larboardTack.name,
        'nodeType': i == 3
            ? EncounterNodeType.shipwreckSalvage.name
            : i == 4
            ? EncounterNodeType.respiteIsland.name
            : i == 6
            ? EncounterNodeType.ancientShrine.name
            : EncounterNodeType.beastCombat.name,
        'destination': i == 4
            ? CourseDestination.midpointHaven.name
            : CourseDestination.ordinary.name,
        'combatWon': i != 3 && i != 4 && i != 6,
        'wreckRecovered': i == 3,
        'lookoutCall': 'Recorded waters',
      },
  ];
  state['currentLeg'] = 6;
  state['courseOptions'] = [
    for (final bearing in NavigationalBearing.values)
      CourseOption(
        bearing: bearing,
        nodeType: EncounterNodeType.beastCombat,
        difficultyLevel: 3,
        lookoutCall: bearing == NavigationalBearing.larboardTack
            ? 'Dark dread chills the salt air… the beast that took your predecessor hunts off the larboard bow!'
            : 'A broad shadow cleaves the swells. The lookout calls a beast on this heading.',
        isNemesis: bearing == NavigationalBearing.larboardTack,
        isIdentified: bearing != NavigationalBearing.starboardTack,
      ).toJson(),
  ];
  c.seaChart.restoreFromJson(state);
  c.session.phase = SessionPhase.helm;
  return c;
}

Future<void> mountChartFocus(
  WidgetTester tester,
  Widget screen,
  GlobalKey key,
  Size size, {
  double scale = 1.3,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await _fonts(tester);
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
        home: screen,
      ),
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

  for (final size in [
    const Size(1280, 850),
    const Size(1600, 1000),
    const Size(360, 900),
    const Size(800, 480),
  ]) {
    testWidgets('unified chart and readable Nemesis reports at $size', (
      tester,
    ) async {
      final c = chartFocusController();
      addTearDown(c.dispose);
      final before = c.seaChart.toJson();
      final key = GlobalKey();
      await mountChartFocus(tester, HelmScreen(controller: c), key, size);
      expect(find.text('CONSULT SEA CHART'), findsNothing);
      final nemesis = tester.widget<Text>(find.text('NEMESIS'));
      expect(nemesis.style!.color, InkTheme.crimsonAccent);
      // An ordinary identified beast retains its own tag; fog stays unrevealed.
      expect(find.text('BEAST ENCOUNTER'), findsOneWidget);
      expect(find.text('STEER THIS HEADING'), findsNWidgets(3));
      final mapRect = tester.getRect(
        find.byKey(const ValueKey('nautical-map-viewport')),
      );
      final reportRect = tester.getRect(
        find.text('LOOKOUT OBSERVATIONS & COURSES'),
      );
      if (tester
              .widget<NauticalChart>(find.byType(NauticalChart))
              .coursePanel !=
          null) {
        expect(mapRect.contains(reportRect.topLeft), isTrue);
        expect(mapRect.height, greaterThan(size.height * .4));
        // Course wheel input scrolls its notes without changing the map camera.
        final camera = tester
            .widget<InteractiveViewer>(find.byType(InteractiveViewer))
            .transformationController!;
        final transform = List<double>.from(camera.value.storage);
        expect(find.byKey(const ValueKey('helm-courses-scroll')), findsNothing);
        await tester.sendEventToBinding(
          PointerScrollEvent(
            position: reportRect.center + const Offset(0, 60),
            scrollDelta: const Offset(0, 120),
          ),
        );
        await tester.pumpAndSettle();
        expect(camera.value.storage, orderedEquals(transform));
        final lastButton = tester.getRect(find.text('STEER THIS HEADING').last);
        expect(mapRect.contains(lastButton.bottomRight), isTrue);
      } else {
        expect(reportRect.top, greaterThan(mapRect.bottom));
      }
      await captureChartFocusProof(
        tester,
        key,
        'helm-${size.width.toInt()}x${size.height.toInt()}',
      );
      await tester.ensureVisible(find.byKey(const ValueKey('helm-voyage-log')));
      await tester.tap(find.byKey(const ValueKey('helm-voyage-log')));
      await tester.pumpAndSettle();
      expect(find.text('DEAD-RECKONING VOYAGE LOG'), findsOneWidget);
      await captureChartFocusProof(
        tester,
        key,
        'log-${size.width.toInt()}x${size.height.toInt()}',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('DEAD-RECKONING VOYAGE LOG'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('helm-inspect-vessel')));
      await tester.pumpAndSettle();
      expect(find.byType(ArmoryView), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(ArmoryView), findsNothing);
      expect(c.seaChart.toJson(), before);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'wheel zoom claims only map signals and stops at the height bound',
    (tester) async {
      final c = chartFocusController(flat: true, legs: 36);
      addTearDown(c.dispose);
      final before = c.seaChart.toJson();
      await mountChartFocus(
        tester,
        HelmScreen(controller: c),
        GlobalKey(),
        const Size(700, 900),
      );
      final scroll = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byKey(const ValueKey('helm-page-scroll')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      final map = find.byType(InteractiveViewer);
      final viewer = tester.widget<InteractiveViewer>(map);
      final camera = viewer.transformationController!;
      final center = tester.getCenter(map);
      final pageOffset = scroll.position.pixels;
      for (var i = 0; i < 8; i++) {
        await tester.sendEventToBinding(
          PointerScrollEvent(
            position: center,
            scrollDelta: const Offset(0, 350),
          ),
        );
        await tester.pumpAndSettle();
      }
      expect(scroll.position.pixels, pageOffset);
      expect(camera.value.getMaxScaleOnAxis(), closeTo(viewer.minScale, .001));
      expect(viewer.minScale, greaterThanOrEqualTo(.9));
      expect(46 * viewer.minScale, greaterThanOrEqualTo(41));
      expect(
        NauticalRouteGeometry(c.voyageLog).bounds.width * viewer.minScale,
        greaterThan(tester.getSize(map).width),
      );
      // Even at the limit, the parent must not consume the same wheel event.
      await tester.sendEventToBinding(
        PointerScrollEvent(position: center, scrollDelta: const Offset(0, 500)),
      );
      await tester.pumpAndSettle();
      expect(scroll.position.pixels, pageOffset);
      // Normal page scrolling remains available outside the map.
      await tester.sendEventToBinding(
        PointerScrollEvent(
          position: tester.getCenter(
            find.text('LOOKOUT OBSERVATIONS & COURSES'),
          ),
          scrollDelta: Offset(0, 140),
        ),
      );
      await tester.pumpAndSettle();
      expect(scroll.position.pixels, greaterThan(pageOffset));
      expect(c.seaChart.toJson(), before);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('harbor and recovered cargo use established illustrations', (
    tester,
  ) async {
    final c = chartFocusController(legs: 5);
    addTearDown(c.dispose);
    await mountChartFocus(
      tester,
      Scaffold(body: NauticalChart(chart: c.seaChart)),
      GlobalKey(),
      const Size(900, 900),
    );
    for (final (index, asset) in [
      (3, PilotArt.treasure),
      (4, PilotArt.portHaven),
    ]) {
      expect(
        find.descendant(
          of: find.byKey(ValueKey('voyage-marker-$index')),
          matching: find.byWidgetPredicate(
            (w) => w is SvgAssetView && w.assetPath == asset,
          ),
        ),
        findsOneWidget,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'shared tooltip is readable parchment at 130% and wraps on compact screens',
    (tester) async {
      const message =
          'Region 3 · Leg 14: Midpoint Haven · ARRIVED. A long observation remains readable in the ship’s log.';
      final key = GlobalKey();
      final tooltipKey = GlobalKey<TooltipState>();
      await mountChartFocus(
        tester,
        Scaffold(
          body: Center(
            child: Tooltip(
              key: tooltipKey,
              message: message,
              child: const Text('Chart annotation'),
            ),
          ),
        ),
        key,
        const Size(360, 600),
      );
      tooltipKey.currentState!.ensureTooltipVisible();
      await tester.pumpAndSettle();
      final label = tester.widget<RichText>(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText() == message,
        ),
      );
      expect(label.text.style!.color, InkTheme.inkPrimary);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is DecoratedBox &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).color ==
                  InkTheme.parchmentSurface,
        ),
        findsWidgets,
      );
      final rect = tester.getRect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText() == message,
        ),
      );
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(360));
      await captureChartFocusProof(tester, key, 'tooltip-360');
      expect(tester.takeException(), isNull);
    },
  );
}
