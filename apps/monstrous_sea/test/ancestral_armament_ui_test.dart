import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/screens/port_screen.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';
import 'package:monstrous_sea/src/widgets/ink_button.dart';
import 'package:monstrous_sea/src/widgets/ancestral_armament_preview.dart';

import 'chart_focus_ui_test.dart' show mountChartFocus, captureChartFocusProof;
import 'home_layout_matrix_test.dart' show home, Wealth, press;
import 'navigation_layout_matrix_test.dart' show shell;

String values(WidgetTester tester, String key) => tester
    .widgetList<Text>(
      find.descendant(
        of: find.byKey(ValueKey(key)),
        matching: find.byType(Text),
      ),
    )
    .map((text) => text.data!)
    .join(' → ');

void main() {
  setUpAll(() {
    InkTheme.disableGoogleFonts = const String.fromEnvironment('artFontCache')
        .isEmpty;
  });
  for (final blueprint in BlueprintId.values) {
    for (final wealth in [
      Wealth.poor,
      Wealth.rich,
      Wealth.owned,
      Wealth.maxed,
    ]) {
      for (final size in [const Size(360, 900), const Size(1280, 900)]) {
        for (final scale in [1.15, 1.3]) {
          testWidgets('$blueprint $wealth ancestral preview ${size.width}/$scale', (
            tester,
          ) async {
            final c = home(wealth, blueprint);
            addTearDown(c.dispose);
            final before = jsonEncode({
              'profile': c.profile.toJson(),
              'ship': c.ship!.toJson(),
              'chart': c.seaChart.toJson(),
            });
            final key = GlobalKey();
            await mountChartFocus(
              tester,
              shell(c, PortScreen(controller: c, onOpenChart: () {})),
              key,
              size,
              scale: scale,
            );
            await press(tester, 'BLUEPRINTS');
            final preview = AncestralArmamentPreview(
              c.profile,
              blueprint,
              activeShip: c.ship,
            );
            final offer = find.byKey(
              ValueKey('ancestral-offer-${blueprint.name}'),
            );
            final multiplier = find.byKey(
              ValueKey('ancestral-multiplier-${blueprint.name}'),
            );
            await tester.ensureVisible(multiplier);
            await tester.pumpAndSettle();
            expect(
              values(tester, 'ancestral-multiplier-${blueprint.name}'),
              '${preview.currentMultiplierText}${preview.isMaximum ? '' : ' → ${preview.nextMultiplierText}'}',
            );
            expect(
              values(tester, 'ancestral-damage-${blueprint.name}-0'),
              '${preview.mountedDamage.single.current}${preview.isMaximum ? '' : ' → ${preview.mountedDamage.single.next}'}',
            );
            if (preview.isMaximum) {
              expect(
                find.byKey(ValueKey('ancestral-upgrade-${blueprint.name}')),
                findsNothing,
              );
              expect(
                find.descendant(of: offer, matching: find.text('MAX TIER')),
                findsOneWidget,
              );
            } else {
              final buy = find.byKey(
                ValueKey('ancestral-upgrade-${blueprint.name}'),
              );
              await tester.ensureVisible(buy);
              await tester.pumpAndSettle();
              expect(buy.hitTestable(), findsOneWidget);
              expect(
                tester.widget<InkButton>(buy).onPressed != null,
                wealth != Wealth.poor,
              );
            }
            for (final node
                in find
                    .descendant(of: offer, matching: find.byType(RichText))
                    .evaluate()) {
              expect(
                (node.renderObject! as RenderParagraph).didExceedMaxLines,
                isFalse,
              );
            }
            if (wealth == Wealth.rich && scale == 1.15) {
              await tester.ensureVisible(offer);
              await tester.pumpAndSettle();
              await captureChartFocusProof(
                tester,
                key,
                'ancestral-${blueprint.name}-${size.width.toInt()}',
              );
            }
            expect(
              jsonEncode({
                'profile': c.profile.toJson(),
                'ship': c.ship!.toJson(),
                'chart': c.seaChart.toJson(),
              }),
              before,
            );
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
  }

  testWidgets(
    'successive ancestral purchases refresh materials, damage and maximum state',
    (tester) async {
      final c = home(Wealth.rich, BlueprintId.standard);
      // The layout fixture commissions a vessel without leaving creation.
      c.dispatch(const ChooseShip(ShipClass.standard));
      expect(c.phase, SessionPhase.port);
      addTearDown(c.dispose);
      final broadsideBefore = c.ship!.equippedWeapons
          .singleWhere((w) => !w.isSignature)
          .damage;
      await mountChartFocus(
        tester,
        PortScreen(controller: c, onOpenChart: () {}),
        GlobalKey(),
        const Size(360, 900),
        scale: 1.3,
      );
      await press(tester, 'BLUEPRINTS');
      for (final tier in [2, 3]) {
        final preview = AncestralArmamentPreview(
          c.profile,
          BlueprintId.standard,
          activeShip: c.ship,
        );
        final expected = MetaInventory.fromJson(c.metaInventory.toJson());
        expected.spendCost(preview.cost!);
        final buy = find.byKey(const ValueKey('ancestral-upgrade-standard'));
        await tester.ensureVisible(buy);
        await tester.tap(buy);
        await tester.pumpAndSettle();
        expect(c.profile.armamentTierFor(BlueprintId.standard), tier);
        expect(c.metaInventory.toJson(), expected.toJson());
        expect(
          c.ship!.equippedWeapons.singleWhere((w) => w.isSignature).damage,
          preview.mountedDamage.single.next,
        );
        expect(
          c.ship!.equippedWeapons.singleWhere((w) => !w.isSignature).damage,
          broadsideBefore,
        );
        expect(
          values(
            tester,
            'ancestral-multiplier-standard',
          ).startsWith(tier == 2 ? '1.25x' : '1.45x'),
          isTrue,
        );
      }
      expect(
        find.byKey(const ValueKey('ancestral-upgrade-standard')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'inactive blueprint upgrades change its multiplier without commissioning a vessel',
    (tester) async {
      final c = home(Wealth.owned, BlueprintId.standard);
      c.dispatch(const ChooseShip(ShipClass.standard));
      expect(c.phase, SessionPhase.port);
      addTearDown(c.dispose);
      final before = jsonEncode(c.ship!.toJson());
      await mountChartFocus(
        tester,
        PortScreen(controller: c, onOpenChart: () {}),
        GlobalKey(),
        const Size(1280, 900),
        scale: 1.15,
      );
      await press(tester, 'BLUEPRINTS');
      expect(
        find.byKey(const ValueKey('ancestral-damage-ironclad-0')),
        findsNothing,
      );
      final buy = find.byKey(const ValueKey('ancestral-upgrade-ironclad'));
      await tester.ensureVisible(buy);
      await tester.tap(buy);
      await tester.pumpAndSettle();
      expect(c.profile.armamentTierFor(BlueprintId.ironclad), 3);
      expect(values(tester, 'ancestral-multiplier-ironclad'), '1.45x');
      expect(jsonEncode(c.ship!.toJson()), before);
      expect(tester.takeException(), isNull);
    },
  );
}
