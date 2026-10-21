import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/screens/helm_screen.dart';

import '../test/wreck_feedback_test.dart' show fullWreck, mountWreck;

Future<void> capture(WidgetTester tester, Key key, String filename) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('build/$filename.png').writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  for (final scale in [1.15, 1.3]) {
    testWidgets('Native navigation and wreck feedback at $scale', (
      tester,
    ) async {
      final controller = fullWreck();
      const key = ValueKey('navigation-review');
      await mountWreck(tester, controller, scale, captureKey: key);
      await capture(tester, key, 'wreck-receipt-native-$scale');
      await tester.ensureVisible(find.text('STOW SUPPLY'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await capture(tester, key, 'wreck-feedback-native-$scale');
      controller.dispatch(const LeaveRemainingLoot());
      controller.dispatch(const TakeHelm());
      controller.session.activeQuirk = BloodlineTrait.fromId(
        BloodlineTraitId.recklessHelmsman,
      );
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: HelmScreen(controller: controller, onOpenChart: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await capture(tester, key, 'helm-arrival-native-$scale');
      await tester.ensureVisible(find.text('HEADING UNAVAILABLE'));
      await tester.pumpAndSettle();
      expect(
        find.text('Reckless Helmsman refuses to steer Dead Ahead!'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await capture(tester, key, 'helm-feedback-native-$scale');
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    });
  }
}
