import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';
import 'package:monstrous_sea/src/widgets/hull_upgrade_preview.dart';
import 'package:monstrous_sea/src/widgets/ink_button.dart';
import 'package:monstrous_sea/src/widgets/voyage_shipwright_view.dart';

import 'chart_focus_ui_test.dart' show mountChartFocus, captureChartFocusProof;
import 'shipwright_purse_test.dart' show atVoyageShipwright;
import 'navigation_layout_matrix_test.dart' show shell;

Finder statValue(String id) => find.byKey(ValueKey('hull-upgrade-$id'));
String statText(WidgetTester tester, String id) => tester
    .widgetList<Text>(
      find.descendant(of: statValue(id), matching: find.byType(Text)),
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
          testWidgets('$blueprint $phase hull preview ${size.width}/$scale', (
            tester,
          ) async {
            final c = atVoyageShipwright(phase: phase);
            addTearDown(c.dispose);
            c.session.ship = createFlagshipFromBlueprint(
              blueprint,
              level: 2,
              rng: SeededGameRng(14),
            )..gold = 1000;
            c.ship!.currentHp -= 37;
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
            if (phase == SessionPhase.stronghold && scale == 1.15) {
              await captureChartFocusProof(
                tester,
                key,
                'hull-summary-${blueprint.name}-${size.width.toInt()}',
              );
            }
            final preview = HullUpgradePreview(c.ship!);
            for (final stat in preview.stats) {
              await tester.ensureVisible(statValue(stat.id));
              await tester.pumpAndSettle();
              expect(
                statText(tester, stat.id),
                '${stat.current} → ${stat.next}',
              );
              final rect = tester.getRect(statValue(stat.id));
              expect(rect.left, greaterThanOrEqualTo(0));
              expect(rect.right, lessThanOrEqualTo(size.width));
            }
            final upgrade = find.byKey(const ValueKey('hull-upgrade'));
            await tester.ensureVisible(upgrade);
            await tester.pumpAndSettle();
            expect(upgrade.hitTestable(), findsOneWidget);
            for (final paragraph in find.byType(RichText).evaluate()) {
              expect(
                (paragraph.renderObject! as RenderParagraph).didExceedMaxLines,
                isFalse,
              );
            }
            expect(c.ship!.toJson(), before);
            if (phase == SessionPhase.stronghold && scale == 1.15) {
              await captureChartFocusProof(
                tester,
                key,
                'hull-${blueprint.name}-${size.width.toInt()}',
              );
            }
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
  }

  testWidgets(
    'successive hull purchases refresh exact effects, costs and maximum state',
    (tester) async {
      final c = atVoyageShipwright(phase: SessionPhase.stronghold, gold: 850);
      addTearDown(c.dispose);
      c.session.ship = createFlagshipFromBlueprint(
        BlueprintId.ironclad,
        rng: SeededGameRng(5),
      )..gold = 850;
      c.ship!.currentHp -= 37;
      for (final slot in blessingHardpoints) {
        temperShipHardpoint(c.ship!, slot);
        temperShipHardpoint(c.ship!, slot);
      }
      final missingHull = c.ship!.maxHp - c.ship!.currentHp;
      await mountChartFocus(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: VoyageShipwrightView(controller: c),
          ),
        ),
        GlobalKey(),
        const Size(360, 900),
        scale: 1.3,
      );
      final upgrade = find.byKey(const ValueKey('hull-upgrade'));
      for (final tier in [2, 3, 4]) {
        final preview = HullUpgradePreview(c.ship!);
        final expectedHull = preview.stats
            .singleWhere((stat) => stat.id == 'hull')
            .next!;
        await tester.ensureVisible(upgrade);
        await tester.tap(upgrade);
        await tester.pumpAndSettle();
        expect(c.ship!.level, tier);
        expect(c.ship!.maxHp - c.ship!.currentHp, missingHull);
        expect(statText(tester, 'hull').split(' → ').first, expectedHull);
        expect(c.ship!.markForHardpoint(HardpointType.utility), 3);
      }
      expect(c.ship!.gold, 0);
      expect(tester.widget<InkButton>(upgrade).onPressed, isNull);
      expect(tester.widget<InkButton>(upgrade).label, 'MAXIMUM HULL TIER');
      expect(statText(tester, 'hull'), '${c.ship!.currentHp}/${c.ship!.maxHp}');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('poor captains can read hull comparisons before they can buy', (
    tester,
  ) async {
    final c = atVoyageShipwright(phase: SessionPhase.respiteIsland, gold: 99);
    addTearDown(c.dispose);
    await mountChartFocus(
      tester,
      Scaffold(
        body: SingleChildScrollView(child: VoyageShipwrightView(controller: c)),
      ),
      GlobalKey(),
      const Size(360, 900),
      scale: 1.15,
    );
    final upgrade = find.byKey(const ValueKey('hull-upgrade'));
    expect(statText(tester, 'hull'), contains('→'));
    expect(tester.widget<InkButton>(upgrade).onPressed, isNull);
    c.ship!.gold = 100;
    c.notify();
    await tester.pumpAndSettle();
    expect(tester.widget<InkButton>(upgrade).onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });
}
