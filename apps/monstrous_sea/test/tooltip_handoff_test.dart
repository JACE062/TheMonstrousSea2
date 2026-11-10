import 'dart:convert';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';
import 'package:monstrous_sea/src/widgets/ink_button.dart';
import 'package:monstrous_sea/src/widgets/mechanic_text.dart';
import 'package:monstrous_sea/src/widgets/parchment_scaffold.dart';

import 'chart_focus_ui_test.dart' show mountChartFocus, captureChartFocusProof;

const signatureHelp =
    'Pierces 50% of Carapace. Opening shot accuracy: 95%. Target dodge: 0%.';
Finder get actionCard => find.byKey(const ValueKey('mechanic-help-action'));

Future<({GlobalKey key, int Function() clicks})> fixture(
  WidgetTester tester,
  Size size,
  double scale,
) async {
  final key = GlobalKey();
  var clicks = 0;
  Widget fitting(String label, String help) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: MechanicTooltip(
        hoverInset: 12,
        message: help,
        child: InkButton(
          label: label,
          subtitle: '95% accuracy · 85% range damage',
          onPressed: () => clicks++,
        ),
      ),
    ),
  );
  await mountChartFocus(
    tester,
    ParchmentScaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 60),
            SizedBox(
              height: 90,
              child: Row(
                children: [
                  fitting('Long-Barrel Swivel Guns', 'Broadside opening shot.'),
                  fitting('Precision Culverin', signatureHelp),
                ],
              ),
            ),
            const SizedBox(height: 16),
            MechanicText('Carapace'),
            const SizedBox(height: 16),
            const MechanicTooltip(
              message: 'Current dodge chance.',
              child: Text('Dodge: 0%'),
            ),
          ],
        ),
      ),
    ),
    key,
    size,
    scale: scale,
  );
  return (key: key, clicks: () => clicks);
}

Future<TestGesture> mouseFor(WidgetTester tester) async {
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await mouse.addPointer(location: Offset.zero);
  addTearDown(mouse.removePointer);
  return mouse;
}

void main() {
  setUpAll(() async {
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
  });
  for (final size in [const Size(800, 480), const Size(1280, 900)]) {
    for (final scale in [1.15, 1.3]) {
      testWidgets(
        'Signature to Carapace crosses the Broadside sliver $size/$scale',
        (tester) async {
          final view = await fixture(tester, size, scale);
          final mouse = await mouseFor(tester);
          final signature = tester.getRect(
            find.widgetWithText(InkButton, 'Precision Culverin'),
          );
          final broadside = tester.getRect(
            find.widgetWithText(InkButton, 'Long-Barrel Swivel Guns'),
          );
          await mouse.moveTo(signature.center);
          await tester.pumpAndSettle();
          final frame = tester.getRect(
            find
                .ancestor(of: actionCard, matching: find.byType(Container))
                .first,
          );
          final keyword = find
              .descendant(of: actionCard, matching: find.text('Carapace'))
              .first;
          final word = tester.getRect(keyword);
          expect(frame.right, lessThan(broadside.right));
          expect(broadside.right, lessThan(signature.left));
          expect(
            word.center.dy,
            inInclusiveRange(signature.top, signature.bottom),
          );
          final sliver = Offset(
            (frame.right + broadside.right) / 2,
            word.center.dy,
          );
          final suffix = '${size.width.toInt()}-$scale';
          await captureChartFocusProof(tester, view.key, 'signature-$suffix');
          for (final point in [
            Offset(signature.left + 20, word.center.dy),
            Offset(signature.left + 1, word.center.dy),
            sliver,
            Offset(frame.right - 1, word.center.dy),
          ]) {
            await mouse.moveTo(point);
            await tester.pump(const Duration(milliseconds: 30));
            expect(
              find.text('Broadside opening shot.'),
              findsNothing,
              reason: 'Crossing the button edge toward Signature help must not switch fitting.',
            );
            expect(actionCard, findsOneWidget);
          }
          // Keyword hit targets keep their whole surface, including their edges.
          await mouse.moveTo(Offset(word.left + 1, word.center.dy));
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('mechanic-help-Carapace')),
            findsOneWidget,
          );
          await captureChartFocusProof(tester, view.key, 'carapace-$suffix');
          // A deliberate move into the exposed Broadside interior still switches.
          expect(broadside.left + 14, lessThan(frame.left));
          await mouse.moveTo(Offset(broadside.left + 14, broadside.center.dy));
          await tester.pumpAndSettle();
          expect(find.text('Broadside opening shot.'), findsOneWidget);
          expect(
            find.byKey(const ValueKey('mechanic-help-Carapace')),
            findsNothing,
          );
          expect(view.clicks(), 0);
          expect(tester.takeException(), isNull);
        },
      );
      testWidgets(
        'fitting hover starts inside its edge but clicks stay full size $size/$scale',
        (tester) async {
          final view = await fixture(tester, size, scale);
          final mouse = await mouseFor(tester);
          final button = tester.getRect(
            find.widgetWithText(InkButton, 'Long-Barrel Swivel Guns'),
          );
          final edge = Offset(button.right - 1, button.center.dy);
          await mouse.moveTo(edge);
          await tester.pump(const Duration(milliseconds: 400));
          await tester.pumpAndSettle();
          expect(actionCard, findsNothing);
          await mouse.down(edge);
          await mouse.up();
          await tester.pumpAndSettle();
          expect(view.clicks(), 1);
          await mouse.moveTo(button.center);
          await tester.pumpAndSettle();
          expect(find.text('Broadside opening shot.'), findsOneWidget);
        },
      );
      testWidgets(
        'explicit fitting help still works outside the hover inset $size/$scale',
        (tester) async {
          final view = await fixture(tester, size, scale);
          final button = find.widgetWithText(
            InkButton,
            'Long-Barrel Swivel Guns',
          );
          final rect = tester.getRect(button);
          await tester.longPressAt(Offset(rect.right - 1, rect.center.dy));
          await tester.pumpAndSettle();
          expect(find.text('Broadside opening shot.'), findsOneWidget);
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
          final focus = Focus.of(
            tester.element(find.text('Long-Barrel Swivel Guns')),
          );
          focus.requestFocus();
          await tester.pump();
          await tester.sendKeyEvent(LogicalKeyboardKey.f1);
          await tester.pumpAndSettle();
          expect(find.text('Broadside opening shot.'), findsOneWidget);
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
          expect(actionCard, findsNothing);
          expect(view.clicks(), 0);
        },
      );
    }
  }
  testWidgets(
    'keywords use moderate weight, accuracy gold and a help cursor without underline',
    (tester) async {
      await fixture(tester, const Size(1280, 900), 1.15);
      final text = tester.widget<Text>(find.text('Carapace'));
      expect(text.style!.fontWeight, FontWeight.w600);
      expect(text.style!.color, InkTheme.goldAccent);
      expect(text.style!.decoration, TextDecoration.none);
      final link = find
          .ancestor(of: find.text('Carapace'), matching: find.byType(InkWell))
          .first;
      expect(tester.widget<InkWell>(link).mouseCursor, SystemMouseCursors.help);
    },
  );
  testWidgets('ordinary stat help retains its full hover target', (
    tester,
  ) async {
    await fixture(tester, const Size(1280, 900), 1.15);
    final mouse = await mouseFor(tester);
    final text = tester.getRect(find.text('Dodge: 0%'));
    await mouse.moveTo(Offset(text.left + 1, text.center.dy));
    await tester.pumpAndSettle();
    expect(find.text('Current dodge chance.'), findsOneWidget);
  });
}
