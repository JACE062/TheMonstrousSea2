import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';
import 'package:monstrous_sea/src/widgets/ink_button.dart';
import 'package:monstrous_sea/src/widgets/voyage_shipwright_view.dart';
import 'package:monstrous_sea/src/widgets/fitting_temper_preview.dart';

import 'chart_focus_ui_test.dart' show mountChartFocus, captureChartFocusProof;
import 'shipwright_purse_test.dart' show atVoyageShipwright;
import 'navigation_layout_matrix_test.dart' show shell;

Finder value(HardpointType slot, int index) =>
    find.byKey(ValueKey('fitting-temper-${slot.name}-stat-$index'));
String valueText(WidgetTester tester, HardpointType slot, int index) => tester
    .widgetList<Text>(
      find.descendant(of: value(slot, index), matching: find.byType(Text)),
    )
    .map((text) => text.data!)
    .join(' → ');

void main() {
  setUpAll(() {
    InkTheme.disableGoogleFonts = const String.fromEnvironment('artFontCache')
        .isEmpty;
  });

  for (final blueprint in BlueprintId.values) {
    for (final phase in [SessionPhase.respiteIsland, SessionPhase.stronghold]) {
      for (final size in [const Size(360, 900), const Size(1280, 900)]) {
        for (final scale in [1.15, 1.3]) {
          testWidgets(
            '$blueprint $phase fitting previews ${size.width}/$scale',
            (tester) async {
              final c = atVoyageShipwright(phase: phase, gold: 1000);
              addTearDown(c.dispose);
              c.session.ship = createFlagshipFromBlueprint(
                blueprint,
                level: 2,
                rng: SeededGameRng(13),
              )..gold = 1000;
              final before = c.ship!.toJson();
              final key = GlobalKey();
              await mountChartFocus(
                tester,
                shell(
                  c,
                  Scaffold(
                    body: SingleChildScrollView(
                      child: VoyageShipwrightView(controller: c),
                    ),
                  ),
                ),
                key,
                size,
                scale: scale,
              );
              for (final slot in blessingHardpoints) {
                final preview = FittingTemperPreview(c.ship!, slot);
                for (final (i, stat) in preview.stats.indexed) {
                  await tester.ensureVisible(value(slot, i));
                  await tester.pumpAndSettle();
                  expect(
                    valueText(tester, slot, i),
                    '${stat.currentText} → ${stat.nextText}',
                  );
                  final rect = tester.getRect(value(slot, i));
                  expect(rect.left, greaterThanOrEqualTo(0));
                  expect(rect.right, lessThanOrEqualTo(size.width));
                }
                final buy = find.byKey(ValueKey('temper-${slot.name}'));
                await tester.ensureVisible(buy);
                await tester.pumpAndSettle();
                expect(buy.hitTestable(), findsOneWidget);
              }
              for (final paragraph in find.byType(RichText).evaluate()) {
                expect(
                  (paragraph.renderObject! as RenderParagraph)
                      .didExceedMaxLines,
                  isFalse,
                );
              }
              expect(c.ship!.toJson(), before);
              if (phase == SessionPhase.stronghold && scale == 1.15) {
                await tester.ensureVisible(
                  find.byKey(const ValueKey('temper-utility')),
                );
                await tester.pumpAndSettle();
                await captureChartFocusProof(
                  tester,
                  key,
                  'shipwright-${blueprint.name}-${size.width.toInt()}',
                );
              }
              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }
  }

  testWidgets('purchase updates previews, purse, affordability and max state', (
    tester,
  ) async {
    final c = atVoyageShipwright(phase: SessionPhase.stronghold, gold: 180);
    addTearDown(c.dispose);
    final key = GlobalKey();
    await mountChartFocus(
      tester,
      Scaffold(
        body: SingleChildScrollView(child: VoyageShipwrightView(controller: c)),
      ),
      key,
      const Size(360, 900),
      scale: 1.15,
    );
    final button = find.byKey(const ValueKey('temper-utility'));
    for (final mark in [2, 3]) {
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(c.ship!.markForHardpoint(HardpointType.utility), mark);
      expect(
        valueText(tester, HardpointType.utility, 0),
        mark == 2 ? '+24% → +28%' : '+28%',
      );
    }
    expect(c.ship!.gold, 0);
    expect(tester.widget<InkButton>(button).onPressed, isNull);
    expect(tester.widget<InkButton>(button).label, 'MAXIMUM TEMPERING');
    final broadside = find.byKey(const ValueKey('temper-broadside'));
    expect(tester.widget<InkButton>(broadside).onPressed, isNull);
    expect(valueText(tester, HardpointType.broadside, 0), contains('→'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('hull refitting refreshes the Iron Plates temper preview', (
    tester,
  ) async {
    final c = atVoyageShipwright(phase: SessionPhase.stronghold, gold: 160);
    addTearDown(c.dispose);
    c.session.ship = createFlagshipFromBlueprint(
      BlueprintId.ironclad,
      rng: SeededGameRng(11),
    )..gold = 160;
    await mountChartFocus(
      tester,
      Scaffold(
        body: SingleChildScrollView(child: VoyageShipwrightView(controller: c)),
      ),
      GlobalKey(),
      const Size(360, 900),
      scale: 1.15,
    );
    expect(valueText(tester, HardpointType.utility, 0), '+2 → +2');
    final hullUpgrade = find.text('UPGRADE TIER · 100g');
    await tester.ensureVisible(hullUpgrade);
    await tester.tap(hullUpgrade);
    await tester.pumpAndSettle();
    expect(valueText(tester, HardpointType.utility, 0), '+4 → +5');
    final temper = find.byKey(const ValueKey('temper-utility'));
    await tester.ensureVisible(temper);
    await tester.tap(temper);
    await tester.pumpAndSettle();
    expect(c.ship!.gold, 0);
    expect(c.ship!.fortifyDamageReductionGain, 5);
    expect(valueText(tester, HardpointType.utility, 0), '+5 → +6');
    expect(tester.takeException(), isNull);
  });
}
