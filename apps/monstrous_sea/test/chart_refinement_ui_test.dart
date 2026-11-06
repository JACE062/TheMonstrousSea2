import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_sea/src/screens/helm_screen.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';
import 'package:monstrous_sea/src/widgets/ink_button.dart';
import 'package:monstrous_sea/src/widgets/nautical_chart.dart';
import 'package:monstrous_sea/src/widgets/painters/sea_chart_water_painter.dart';

import 'chart_focus_ui_test.dart'
    show chartFocusController, mountChartFocus, captureChartFocusProof;

const _nemesisCall =
    'Dark dread chills the salt air... Behemoth Mako — Jack Sparrow’s Undertaker East-Northeast (Larboard Tack)!';

void main() {
  setUpAll(
    () => InkTheme.disableGoogleFonts = const String.fromEnvironment(
      'artFontCache',
    ).isEmpty,
  );
  for (final (size, scale) in [
    (const Size(2546, 1424), 1.15),
    (const Size(1920, 1080), 1.15),
    (const Size(1280, 850), 1.3),
    (const Size(360, 900), 1.3),
    (const Size(800, 480), 1.3),
  ]) {
    testWidgets(
      'readable map and all reports without a nested scroll at $size / $scale',
      (tester) async {
        final c = chartFocusController(legs: 6);
        addTearDown(c.dispose);
        c.ship!
          ..maxHp = 140
          ..currentHp = 137
          ..gold = 17;
        final state = c.seaChart.toJson();
        (state['courseOptions'] as List).first['lookoutCall'] = _nemesisCall;
        c.seaChart.restoreFromJson(state);
        final before = c.seaChart.toJson();
        final key = GlobalKey();
        await mountChartFocus(
          tester,
          HelmScreen(controller: c),
          key,
          size,
          scale: scale,
        );
        expect(find.text('TRAVELLED WATERS'), findsNothing);
        expect(find.textContaining('Drag to explore'), findsNothing);
        expect(find.byKey(const ValueKey('helm-courses-scroll')), findsNothing);
        expect(
          tester.widget<Text>(find.text(_nemesisCall)).style!.fontSize,
          greaterThanOrEqualTo(17),
        );
        expect(
          tester
              .widget<InkButton>(
                find.byKey(const ValueKey('helm-inspect-vessel')),
              )
              .isPrimary,
          isTrue,
        );
        expect(
          tester.widget<Text>(find.text('17g')).style!.color,
          InkTheme.goldAccent,
        );
        expect(
          tester.widget<Text>(find.text('137/140')).style!.color,
          InkTheme.verdigrisGreen,
        );
        final chart = tester.widget<NauticalChart>(find.byType(NauticalChart));
        final mapRect = tester.getRect(
          find.byKey(const ValueKey('nautical-map-viewport')),
        );
        if (const String.fromEnvironment('artFontCache').isNotEmpty &&
            size.width >= 1920) {
          expect(
            chart.coursePanel,
            isNotNull,
            reason: 'Ordinary desktop reports should all fit at the real selected font/scale.',
          );
        }
        if (chart.coursePanel != null) {
          for (final button in find.text('STEER THIS HEADING').evaluate()) {
            final rect = tester.getRect(find.byWidget(button.widget));
            expect(mapRect.contains(rect.topLeft), isTrue);
            expect(mapRect.contains(rect.bottomRight), isTrue);
          }
          expect(
            find.text('STEER THIS HEADING').hitTestable(),
            findsNWidgets(3),
          );
        }
        for (final tool in [
          'zoom-out-chart',
          'zoom-in-chart',
          'fit-nautical-route',
          'locate-chart-vessel',
        ]) {
          final rect = tester.getRect(find.byKey(ValueKey(tool)));
          expect(mapRect.contains(rect.center), isTrue);
        }
        for (final tooltip in tester.widgetList<Tooltip>(
          find.descendant(
            of: find.byType(NauticalChart),
            matching: find.byType(Tooltip),
          ),
        )) {
          expect(tooltip.message, isNot(contains('(Home)')));
          expect(tooltip.message, isNot(contains('(End)')));
        }
        await captureChartFocusProof(
          tester,
          key,
          'refined-${size.width.toInt()}x${size.height.toInt()}-$scale',
        );
        c.ship!.currentHp = 20;
        c.notify();
        await tester.pumpAndSettle();
        expect(
          tester.widget<Text>(find.text('20/140')).style!.color,
          InkTheme.crimsonAccent,
        );
        expect(c.seaChart.toJson(), before);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final flat in [true, false]) {
    testWidgets(
      'long ${flat ? 'horizontal' : 'diagonal'} route retains legible markers at maximum zoom-out',
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
        final viewer = tester.widget<InteractiveViewer>(
          find.byType(InteractiveViewer),
        );
        final camera = viewer.transformationController!;
        final point =
            tester.getTopLeft(find.byType(InteractiveViewer)) +
            const Offset(400, 100);
        for (var i = 0; i < 6; i++) {
          await tester.sendEventToBinding(
            PointerScrollEvent(
              position: point,
              scrollDelta: const Offset(0, 500),
            ),
          );
          await tester.pumpAndSettle();
        }
        expect(camera.value.getMaxScaleOnAxis(), closeTo(.9, .001));
        expect(
          tester.getRect(find.byKey(const ValueKey('voyage-marker-39'))).width,
          greaterThanOrEqualTo(41),
        );
        await captureChartFocusProof(
          tester,
          key,
          'minimum-${flat ? 'horizontal' : 'diagonal'}',
        );
        await tester.tap(find.byKey(const ValueKey('fit-nautical-route')));
        await tester.pumpAndSettle();
        final centered = camera.value.clone();
        await tester.tap(find.byKey(const ValueKey('locate-chart-vessel')));
        await tester.pumpAndSettle();
        expect(camera.value.storage[12], isNot(centered.storage[12]));
        expect(camera.value.getMaxScaleOnAxis(), 1);
        expect(c.seaChart.toJson(), before);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'first and subsequent pointer tooltips appear without a warm-up delay',
    (tester) async {
      await mountChartFocus(
        tester,
        Scaffold(
          body: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Tooltip(
                message: 'First chart annotation',
                child: SizedBox(
                  key: ValueKey('first-note'),
                  width: 80,
                  height: 80,
                ),
              ),
              Tooltip(
                message: 'Second chart annotation',
                child: SizedBox(
                  key: ValueKey('second-note'),
                  width: 80,
                  height: 80,
                ),
              ),
            ],
          ),
        ),
        GlobalKey(),
        const Size(600, 500),
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: const Offset(1, 1));
      for (final (key, text) in [
        ('first-note', 'First chart annotation'),
        ('second-note', 'Second chart annotation'),
      ]) {
        await mouse.moveTo(tester.getCenter(find.byKey(ValueKey(key))));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 30));
        expect(find.text(text, findRichText: true), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'water markings cover distant quadrants and follow world panning',
    (tester) async {
      Future<ui.Image> render(Offset pan) async {
        final camera = TransformationController(
          Matrix4.identity()..setTranslationRaw(pan.dx, pan.dy, 0),
        );
        final recorder = ui.PictureRecorder();
        SeaChartWaterPainter(
          camera: camera,
          worldOffset: Offset.zero,
        ).paint(Canvas(recorder), const Size(600, 400));
        final picture = recorder.endRecording();
        final image = await picture.toImage(600, 400);
        picture.dispose();
        camera.dispose();
        return image;
      }

      await tester.runAsync(() async {
        final first = await render(Offset.zero);
        final shifted = await render(const Offset(37, 23));
        final distant = await render(const Offset(-20000, 18000));
        try {
          final a = (await first.toByteData())!.buffer.asUint8List();
          final b = (await shifted.toByteData())!.buffer.asUint8List();
          final far = (await distant.toByteData())!.buffer.asUint8List();
          var matched = 0, compared = 0;
          for (var y = 100; y < 200; y++) {
            for (var x = 100; x < 200; x++) {
              final i = (y * 600 + x) * 4;
              final j = ((y + 23) * 600 + x + 37) * 4;
              compared++;
              if ((a[i + 3] - b[j + 3]).abs() <= 4) matched++;
            }
          }
          expect(
            matched / compared,
            greaterThan(.98),
            reason: 'An identical world patch translates with the route.',
          );
          for (var quadrant = 0; quadrant < 4; quadrant++) {
            var wavePixels = 0;
            for (
              var y = (quadrant ~/ 2) * 200;
              y < (quadrant ~/ 2 + 1) * 200;
              y++
            ) {
              for (
                var x = (quadrant % 2) * 300;
                x < (quadrant % 2 + 1) * 300;
                x++
              ) {
                final i = (y * 600 + x) * 4;
                if (far[i + 3] > 5 && far[i + 2] > far[i] * .65) wavePixels++;
              }
            }
            expect(
              wavePixels,
              greaterThan(15),
              reason: 'Waves must reach every distant viewport quadrant.',
            );
          }
        } finally {
          first.dispose();
          shifted.dispose();
          distant.dispose();
        }
      });
    },
  );
}
