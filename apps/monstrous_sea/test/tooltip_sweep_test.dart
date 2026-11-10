import 'dart:convert';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';
import 'package:monstrous_sea/src/widgets/mechanic_text.dart';
import 'package:monstrous_sea/src/widgets/parchment_scaffold.dart';

import 'chart_focus_ui_test.dart' show mountChartFocus, captureChartFocusProof;

Finder help(String term) => find.byKey(ValueKey('mechanic-help-$term'));
Rect painted(WidgetTester tester, Finder finder) =>
    Rect.fromPoints(tester.getTopLeft(finder), tester.getBottomRight(finder));
Rect frame(WidgetTester tester, String term) => painted(
  tester,
  find.ancestor(of: help(term), matching: find.byType(Container)).first,
);
Future<void> openWord(WidgetTester tester, String term) async {
  await tester.tap(find.text(term).last);
  await tester.pumpAndSettle();
  expect(help(term), findsOneWidget);
}

Future<GlobalKey> mount(
  WidgetTester tester,
  Widget child,
  Size size,
  double scale,
) async {
  final key = GlobalKey();
  await mountChartFocus(
    tester,
    ParchmentScaffold(body: child),
    key,
    size,
    scale: scale,
  );
  return key;
}

Future<void> loadSweepFonts() async {
  InkTheme.disableGoogleFonts = const String.fromEnvironment('artFontCache')
      .isEmpty;
  final config = File('.dart_tool/package_config.json').absolute;
  final packages =
      (jsonDecode(await config.readAsString()) as Map)['packages'] as List;
  final package = packages.cast<Map>().singleWhere(
    (p) => p['name'] == 'flutter_test',
  );
  final sdk = Directory.fromUri(
    config.uri.resolve(package['rootUri'] as String),
  ).parent.parent;
  final loader = FontLoader('Roboto');
  for (final face in ['regular', 'bold', 'italic', 'bolditalic']) {
    loader.addFont(
      File('${sdk.path}/bin/cache/artifacts/material_fonts/roboto-$face.ttf')
          .readAsBytes()
          .then(ByteData.sublistView),
    );
  }
  await loader.load();
}

void main() {
  setUpAll(loadSweepFonts);
  for (final scale in [1.15, 1.3]) {
    testWidgets('help closes when its source leaves an inner viewport $scale', (
      tester,
    ) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await mount(
        tester,
        Stack(
          children: [
            Positioned(
              left: 20,
              right: 20,
              top: 200,
              height: 180,
              child: SingleChildScrollView(
                controller: scroll,
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 80),
                    MechanicText('Pinned'),
                    SizedBox(height: 600),
                  ],
                ),
              ),
            ),
          ],
        ),
        const Size(1280, 850),
        scale,
      );
      await openWord(tester, 'Pinned');
      scroll.jumpTo(200);
      await tester.pumpAndSettle();
      expect(help('Pinned'), findsNothing);
      expect(tester.takeException(), isNull);
    });
    testWidgets('scaled keyword help clears its painted anchor $scale', (
      tester,
    ) async {
      final key = await mount(
        tester,
        const Padding(
          padding: EdgeInsets.only(left: 30, top: 180),
          child: MechanicText('Thermal Detonation'),
        ),
        const Size(1280, 850),
        scale,
      );
      await openWord(tester, 'Thermal Detonation');
      final target = painted(tester, find.text('Thermal Detonation').first);
      await captureChartFocusProof(tester, key, 'scaled-anchor-$scale');
      expect(
        frame(tester, 'Thermal Detonation').left,
        greaterThanOrEqualTo(target.right + 7.9),
      );
      expect(tester.takeException(), isNull);
    });
    testWidgets('open keyword help follows scrolling content $scale', (
      tester,
    ) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      final key = await mount(
        tester,
        SingleChildScrollView(
          controller: scroll,
          child: const Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 250),
                MechanicText('Static Charge'),
                SizedBox(height: 1200),
              ],
            ),
          ),
        ),
        const Size(1280, 850),
        scale,
      );
      await openWord(tester, 'Static Charge');
      final before = frame(tester, 'Static Charge');
      scroll.jumpTo(60);
      await tester.pumpAndSettle();
      await captureChartFocusProof(tester, key, 'scroll-$scale');
      expect(frame(tester, 'Static Charge').top, closeTo(before.top - 60, .1));
      scroll.jumpTo(800);
      await tester.pumpAndSettle();
      expect(help('Static Charge'), findsNothing);
      expect(tester.takeException(), isNull);
    });
    testWidgets('nested help uses free vertical space at tablet width $scale', (
      tester,
    ) async {
      final key = await mount(
        tester,
        const Padding(
          padding: EdgeInsets.only(left: 30, top: 80),
          child: MechanicText('Static Charge'),
        ),
        const Size(800, 900),
        scale,
      );
      for (final term in ['Static Charge', 'Arc Discharge', 'Stun']) {
        await openWord(tester, term);
      }
      await captureChartFocusProof(tester, key, 'vertical-chain-$scale');
      final cards = [
        'Static Charge',
        'Arc Discharge',
        'Stun',
      ].map((term) => frame(tester, term)).toList();
      for (var i = 0; i < cards.length; i++) {
        for (var j = i + 1; j < cards.length; j++) {
          expect(
            cards[i].overlaps(cards[j]),
            isFalse,
            reason: 'There is room to stack these cards without overlap.',
          );
        }
      }
      expect(tester.takeException(), isNull);
    });
    testWidgets('dense label gap preserves help and underlying clicks $scale', (
      tester,
    ) async {
      var clicks = 0;
      final key = await mount(
        tester,
        Padding(
          padding: const EdgeInsets.only(left: 30, top: 200),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MechanicTooltip(
                message: 'Deals extra damage to Carapace.',
                child: Text('Fortified'),
              ),
              const SizedBox(width: 4),
              MechanicTooltip(
                message: 'Neighbor help.',
                child: GestureDetector(
                  onTap: () => clicks++,
                  child: const Text('Evasion'),
                ),
              ),
            ],
          ),
        ),
        const Size(1280, 850),
        scale,
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      final first = painted(tester, find.text('Fortified'));
      final neighbor = painted(tester, find.text('Evasion'));
      await mouse.moveTo(first.center);
      await tester.pumpAndSettle();
      final card = frame(tester, 'action');
      final gap = Offset((neighbor.left + card.left) / 2, first.center.dy);
      expect(neighbor.contains(gap), isTrue);
      await mouse.moveTo(gap);
      await tester.pump(const Duration(milliseconds: 30));
      expect(find.text('Neighbor help.'), findsNothing);
      await mouse.down(gap);
      await mouse.up();
      await tester.pumpAndSettle();
      expect(clicks, 1, reason: 'Hover protection must not swallow clicks.');
      await mouse.moveTo(first.center);
      await tester.pumpAndSettle();
      await mouse.moveTo(gap);
      await tester.pump(const Duration(milliseconds: 30));
      await mouse.moveTo(Offset(card.left + 1, first.center.dy));
      await tester.pumpAndSettle();
      await mouse.moveTo(tester.getCenter(find.text('Carapace')));
      await tester.pumpAndSettle();
      expect(help('Carapace'), findsOneWidget);
      await captureChartFocusProof(tester, key, 'dense-handoff-$scale');
      expect(clicks, 1);
      expect(tester.takeException(), isNull);
    });
  }
}
