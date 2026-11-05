import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/screens/helm_screen.dart';
import 'package:monstrous_sea/src/widgets/nautical_chart.dart';
import 'package:monstrous_sea/src/widgets/pilot_art.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';

class _Fonts extends PathProviderPlatform {
  _Fonts(this.path);
  final String path;
  @override
  Future<String?> getApplicationSupportPath() async => path;
}

Future<void> _loadFonts(WidgetTester tester) async {
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

GameController _helm(int region) {
  final c = GameController(
    session: GameSession(rng: SeededGameRng(23)),
    autoSave: false,
  )..dispatch(const BeginFirstVoyage('Chart review'));
  for (var r = 0; r < region; r++) {
    c.seaChart.advanceRegion(c.session.rng);
  }
  for (
    var leg = c.seaChart.currentLeg;
    leg < c.seaChart.midpointHavenLeg - 1;
    leg++
  ) {
    c.seaChart.ensureCourseOptions(c.session.rng);
    c.seaChart.steerCourse(c.seaChart.currentCourseOptions.first.bearing);
    if (leg.isEven) c.seaChart.recordCurrentOutcome(combatWon: true);
  }
  c.session.phase = SessionPhase.restArea;
  c.dispatch(const TakeHelm());
  return c;
}

void main() {
  setUpAll(
    () => InkTheme.disableGoogleFonts = const String.fromEnvironment(
      'artFontCache',
    ).isEmpty,
  );
  test('cumulative tacks and straight-ahead preserve the ship offset without lanes', () {
    VoyageLegRecord entry(NavigationalBearing bearing, int leg) =>
        VoyageLegRecord(
          leg: leg,
          bearing: bearing,
          nodeType: EncounterNodeType.beastCombat,
          lookoutCall: 'Travelled',
          chartRow: 0,
          chartCol: 0,
        );
    final history = [
      entry(NavigationalBearing.larboardTack, 1),
      entry(NavigationalBearing.larboardTack, 2),
      entry(NavigationalBearing.deadAhead, 3),
      entry(NavigationalBearing.starboardTack, 4),
      entry(NavigationalBearing.deadAhead, 5),
    ];
    final route = NauticalRouteGeometry(history);
    expect(route.points, [
      Offset.zero,
      const Offset(92, -64),
      const Offset(184, -128),
      const Offset(276, -128),
      const Offset(368, -64),
      const Offset(460, -64),
    ]);
    expect(
      NauticalRouteGeometry(history.take(3)).points,
      route.points.take(4).toList(),
    );
    final diagonal = NauticalRouteGeometry([
      for (var i = 0; i < 40; i++)
        entry(NavigationalBearing.larboardTack, i + 1),
    ]);
    expect(diagonal.points.last, const Offset(3680, -2560));
    final metric = routeSegment(
      route.points[1],
      route.points[2],
    ).computeMetrics().single;
    for (var step = 0; step <= 10; step++) {
      final p = metric.getTangentForOffset(metric.length * step / 10)!.position;
      expect(p.dx, closeTo(92 + 92 * step / 10, .01));
      expect(p.dy, closeTo(-64 - 64 * step / 10, .01));
    }
  });
  testWidgets('map pan, zoom, locate and fit preserve the committed route', (
    tester,
  ) async {
    await _loadFonts(tester);
    final c = _helm(0);
    addTearDown(c.dispose);
    final before = c.seaChart.toJson();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 500, child: NauticalChart(chart: c.seaChart)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final map = find.byKey(const ValueKey('nautical-map-viewport'));
    final camera = tester
        .widget<InteractiveViewer>(map)
        .transformationController!;
    final fit = List<double>.from(camera.value.storage);
    await tester.drag(map, const Offset(-100, 30));
    await tester.pumpAndSettle();
    expect(camera.value.storage[12], isNot(closeTo(fit[12], .01)));
    final scaleBeforeScroll = camera.value.getMaxScaleOnAxis();
    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: tester.getCenter(map),
        scrollDelta: const Offset(0, -80),
      ),
    );
    await tester.pumpAndSettle();
    expect(camera.value.getMaxScaleOnAxis(), greaterThan(scaleBeforeScroll));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(c.seaChart.toJson(), before);
    await tester.tap(find.byKey(const ValueKey('locate-chart-vessel')));
    await tester.pumpAndSettle();
    expect(camera.value.getMaxScaleOnAxis(), 1);
    await tester.tap(find.byKey(const ValueKey('fit-nautical-route')));
    await tester.pumpAndSettle();
    expect(camera.value.storage, orderedEquals(fit));
    expect(c.seaChart.toJson(), before);
    expect(tester.takeException(), isNull);
  });
  for (final width in [360.0, 1280.0]) {
    for (var region = 0; region < 3; region++) {
      testWidgets(
        'integrated chart region $region at $width, scaled and reduced motion',
        (tester) async {
          tester.view.physicalSize = Size(width, 1100);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await _loadFonts(tester);
          final c = _helm(region);
          addTearDown(c.dispose);
          final before = c.seaChart.toJson();
          final boundary = GlobalKey();
          var opened = false;
          await tester.pumpWidget(
            MaterialApp(
              theme: InkTheme.themeData,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(1.3),
                  disableAnimations: true,
                ),
                child: child!,
              ),
              home: RepaintBoundary(
                key: boundary,
                child: HelmScreen(
                  controller: c,
                  onOpenChart: () => opened = true,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          if (const String.fromEnvironment('artFontCache').isNotEmpty) {
            final context = tester.element(find.byType(HelmScreen));
            await tester.runAsync(() async {
              for (final asset in [
                PilotArt.portHaven,
                PilotArt.standard,
                PilotArt.defeatedMonster,
              ]) {
                await precacheImage(AssetImage(asset), context);
              }
            });
            await tester.pumpAndSettle();
          }
          final chartRect = tester.getRect(find.text('TRAVELLED WATERS'));
          final choiceRect = tester.getRect(
            find.text('LOOKOUT OBSERVATIONS & COURSES'),
          );
          if (width > 900) {
            expect(chartRect.left, lessThan(choiceRect.left));
          } else {
            expect(chartRect.top, lessThan(choiceRect.top));
          }
          expect(find.textContaining('Font'), findsNothing);
          expect(tester.takeException(), isNull);
          expect(c.seaChart.toJson(), before);
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pumpAndSettle();
          expect(opened, isTrue);
          expect(c.seaChart.toJson(), before);
          const prefix = String.fromEnvironment('navigationProofPath');
          if (prefix.isNotEmpty) {
            await tester.runAsync(() async {
              final image =
                  await (boundary.currentContext!.findRenderObject()
                          as RenderRepaintBoundary)
                      .toImage();
              final data = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await File('$prefix-r$region-$width.png')
                  .writeAsBytes(data!.buffer.asUint8List());
              image.dispose();
            });
          }
        },
      );
    }
  }
  test('history labels never infer settlement from arrival', () {
    const arrival = VoyageLegRecord(
      leg: 2,
      bearing: NavigationalBearing.deadAhead,
      nodeType: EncounterNodeType.shipwreckSalvage,
      lookoutCall: 'Wreck',
      chartRow: 0,
      chartCol: 0,
    );
    expect(voyageOutcomeLabel(arrival), 'ARRIVED');
    expect(
      voyageOutcomeLabel(arrival.withOutcome(wreckPassed: true)),
      'PASSED WRECK',
    );
    expect(voyageOutcomeLabel(arrival.withOutcome(combatWon: true)), 'VICTORY');
    expect(
      voyageOutcomeLabel(
        arrival.withOutcome(combatWon: true, wreckRecovered: true),
      ),
      'VICTORY · CARGO RECOVERED',
    );
  });
}
