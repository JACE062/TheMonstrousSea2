import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/screens/helm_screen.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';
import 'package:monstrous_sea/src/widgets/chart_camera.dart';
import 'package:monstrous_sea/src/widgets/chart_marginalia.dart';
import 'package:monstrous_sea/src/widgets/nautical_chart.dart';

import 'chart_focus_ui_test.dart'
    show chartFocusController, mountChartFocus, captureChartFocusProof;

void expectWithinWaters(NauticalCameraController camera) {
  final bounds = camera.bounds!;
  final scale = camera.value.getMaxScaleOnAxis();
  final start = camera.toScene(Offset.zero) - bounds.sceneOffset;
  final end =
      start +
      Offset(bounds.viewport.width / scale, bounds.viewport.height / scale);
  if (bounds.viewport.width / scale <= bounds.world.width) {
    expect(start.dx, greaterThanOrEqualTo(bounds.travelled.left - 120 - .01));
    expect(end.dx, lessThanOrEqualTo(bounds.travelled.right + 160 + .01));
  } else {
    expect((start.dx + end.dx) / 2, closeTo(bounds.world.center.dx, .01));
  }
  final extraHeight = bounds.viewport.height / .9;
  expect(
    start.dy,
    greaterThanOrEqualTo(bounds.travelled.top - extraHeight - .01),
  );
  expect(
    end.dy,
    lessThanOrEqualTo(bounds.travelled.bottom + extraHeight + .01),
  );
  expect(scale, inInclusiveRange(.9, 3.0));
  expect(camera.value.storage[10], closeTo(scale, .00001));
}

void main() {
  setUpAll(
    () => InkTheme.disableGoogleFonts = const String.fromEnvironment(
      'artFontCache',
    ).isEmpty,
  );

  for (final flat in [true, false]) {
    testWidgets(
      'drag inertia, keyboard, zoom and resize stay in ${flat ? 'horizontal' : 'diagonal'} travelled waters',
      (tester) async {
        final c = chartFocusController(flat: flat, legs: 40);
        addTearDown(c.dispose);
        final before = c.seaChart.toJson();
        final key = GlobalKey();
        await mountChartFocus(
          tester,
          Scaffold(body: NauticalChart(chart: c.seaChart)),
          key,
          const Size(1280, 850),
        );
        final map = find.byKey(const ValueKey('nautical-map-viewport'));
        final camera =
            tester.widget<InteractiveViewer>(map).transformationController!
                as NauticalCameraController;
        expectWithinWaters(camera);
        for (final delta in [
          const Offset(10000, 10000),
          const Offset(-10000, -10000),
          const Offset(10000, -10000),
          const Offset(-10000, 10000),
        ]) {
          await tester.fling(map, delta, 10000);
          await tester.pumpAndSettle();
          expectWithinWaters(camera);
        }
        for (var i = 0; i < 80; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        }
        await tester.pumpAndSettle();
        expectWithinWaters(camera);
        for (var i = 0; i < 10; i++) {
          await tester.tap(find.byKey(const ValueKey('zoom-out-chart')));
          await tester.pumpAndSettle();
        }
        expect(camera.value.getMaxScaleOnAxis(), closeTo(.9, .001));
        expectWithinWaters(camera);
        for (var i = 0; i < 10; i++) {
          await tester.tap(find.byKey(const ValueKey('zoom-in-chart')));
          await tester.pumpAndSettle();
        }
        expect(camera.value.getMaxScaleOnAxis(), closeTo(3, .001));
        expectWithinWaters(camera);
        final previousHeight = camera.bounds!.viewport.height;
        tester.view.physicalSize = const Size(820, 500);
        await tester.pumpAndSettle();
        expect(camera.bounds!.viewport.height, lessThan(previousHeight));
        expectWithinWaters(camera);
        await tester.tap(find.byKey(const ValueKey('locate-chart-vessel')));
        await tester.pumpAndSettle();
        expectWithinWaters(camera);
        expect(
          tester
              .getRect(find.byKey(const ValueKey('voyage-marker-39')))
              .overlaps(tester.getRect(map)),
          isTrue,
        );
        await captureChartFocusProof(
          tester,
          key,
          'bounds-${flat ? 'horizontal' : 'diagonal'}',
        );
        expect(c.seaChart.toJson(), before);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'short voyages lock the horizontal camera when the whole route fits',
    (tester) async {
      final c = chartFocusController(legs: 1);
      addTearDown(c.dispose);
      await mountChartFocus(
        tester,
        Scaffold(body: NauticalChart(chart: c.seaChart)),
        GlobalKey(),
        const Size(1000, 800),
      );
      final map = find.byType(InteractiveViewer);
      final camera =
          tester.widget<InteractiveViewer>(map).transformationController!
              as NauticalCameraController;
      final x = camera.value.storage[12];
      await tester.fling(map, const Offset(10000, 0), 10000);
      await tester.pumpAndSettle();
      expect(camera.value.storage[12], closeTo(x, .001));
      await tester.fling(map, const Offset(-10000, 0), 10000);
      await tester.pumpAndSettle();
      expect(camera.value.storage[12], closeTo(x, .001));
      expectWithinWaters(camera);
      expect(
        tester
            .getRect(find.byKey(const ValueKey('chart-home-port-label')))
            .overlaps(tester.getRect(map)),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'bearings occupy 30 percent with named home and non-interactive chart marginalia',
    (tester) async {
      final c = chartFocusController(legs: 16);
      addTearDown(c.dispose);
      c.seaChart.timesCompleted = 2;
      final before = c.seaChart.toJson();
      final key = GlobalKey();
      await mountChartFocus(
        tester,
        HelmScreen(controller: c),
        key,
        const Size(2536, 1417),
        scale: 1.15,
      );
      final chart = tester.widget<NauticalChart>(find.byType(NauticalChart));
      expect(chart.coursePanel, isNotNull);
      final width = tester.getSize(find.byType(NauticalChart)).width;
      final panelWidth = tester
          .getSize(find.byWidget(chart.coursePanel!))
          .width;
      expect(panelWidth / width, closeTo(.3, .00001));
      expect(find.text(SeaChart.strongholdName(0)), findsOneWidget);
      final home = tester.getRect(
        find.byKey(const ValueKey('chart-home-port-label')),
      );
      final viewport = tester.getRect(
        find.byKey(const ValueKey('nautical-map-viewport')),
      );
      expect(home.left, greaterThanOrEqualTo(viewport.left));
      expect(home.right, lessThanOrEqualTo(viewport.right));
      expect(find.text('DEPARTURE'), findsNothing);
      for (final label in [
        'Arrival',
        'Passed wreck',
        'Cargo recovered',
        'Skull: victory',
      ]) {
        expect(find.text(label), findsNothing);
      }
      final marginalia = find.byType(ChartMarginalia);
      expect(marginalia, findsOneWidget);
      final ignore = tester.widget<IgnorePointer>(
        find
            .descendant(of: marginalia, matching: find.byType(IgnorePointer))
            .first,
      );
      expect(ignore.ignoring, isTrue);
      expect(
        find.descendant(of: marginalia, matching: find.byType(Tooltip)),
        findsNothing,
      );
      expect(
        find.descendant(
          of: marginalia,
          matching: find.byType(ExcludeSemantics),
        ),
        findsWidgets,
      );
      await captureChartFocusProof(
        tester,
        key,
        'thirty-percent-and-marginalia',
      );
      expect(c.seaChart.toJson(), before);
      expect(tester.takeException(), isNull);
    },
  );
}
