import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/screens/port_screen.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';
import 'package:monstrous_sea/src/widgets/harbor_monument_preview.dart';
import 'package:monstrous_sea/src/widgets/ink_button.dart';

import 'ancestral_armament_ui_test.dart' show values;
import 'chart_focus_ui_test.dart' show mountChartFocus, captureChartFocusProof;
import 'home_layout_matrix_test.dart' show home, Wealth, press;
import 'navigation_layout_matrix_test.dart' show shell;

GameController monumentHome(int rank, {bool affordable = true}) {
  final c = home(affordable ? Wealth.rich : Wealth.poor, BlueprintId.standard);
  for (final id in HarborMonumentId.values) {
    c.profile.portCivicLevels[id.name] = rank;
  }
  c.dispatch(const ChooseShip(ShipClass.standard));
  c.ship!.currentHp -= 7;
  return c;
}

void main() {
  setUpAll(() {
    InkTheme.disableGoogleFonts = const String.fromEnvironment('artFontCache')
        .isEmpty;
  });
  for (final state in [
    (rank: 0, affordable: false),
    (rank: 0, affordable: true),
    (rank: 2, affordable: true),
    (rank: 100, affordable: true),
  ]) {
    for (final size in [
      const Size(360, 900),
      const Size(800, 480),
      const Size(1280, 900),
    ]) {
      for (final scale in [1.15, 1.3]) {
        testWidgets('monument preview $state $size/$scale', (tester) async {
          final c = monumentHome(state.rank, affordable: state.affordable);
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
          await press(tester, 'COMMUNE');
          await press(tester, 'CURSED MONUMENTS');
          for (final id in HarborMonumentId.values) {
            final preview = HarborMonumentPreview(c.profile, id);
            final offer = find.byKey(ValueKey('monument-offer-${id.name}'));
            final buy = find.byKey(ValueKey('monument-upgrade-${id.name}'));
            await tester.ensureVisible(buy);
            await tester.pumpAndSettle();
            expect(
              values(tester, 'monument-rank-${id.name}'),
              '${preview.currentRank} → ${preview.nextRank}',
            );
            expect(
              values(tester, 'monument-bonus-${id.name}'),
              '${preview.currentText} → ${preview.nextText}',
            );
            expect(
              tester.widget<InkButton>(buy).onPressed != null,
              state.affordable,
            );
            expect(buy.hitTestable(), findsOneWidget);
            final bounds = tester.getRect(buy);
            expect(bounds.left, greaterThanOrEqualTo(0));
            expect(bounds.right, lessThanOrEqualTo(size.width));
            expect(bounds.top, greaterThanOrEqualTo(0));
            expect(bounds.bottom, lessThanOrEqualTo(size.height));
            for (final node
                in find
                    .descendant(of: offer, matching: find.byType(RichText))
                    .evaluate()) {
              expect(
                (node.renderObject! as RenderParagraph).didExceedMaxLines,
                isFalse,
              );
            }
            if (state.rank == 2 && size.height == 900 && scale == 1.15) {
              await tester.ensureVisible(offer);
              await tester.pumpAndSettle();
              await captureChartFocusProof(
                tester,
                key,
                'monument-${id.name}-${size.width.toInt()}',
              );
            }
          }
          await press(tester, 'Close');
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

  for (final id in HarborMonumentId.values) {
    testWidgets(
      '$id successive purchases refresh ranks, bonuses, costs and affordability',
      (tester) async {
        final c = monumentHome(0);
        addTearDown(c.dispose);
        final beforeOtherBonuses = {
          for (final other in HarborMonumentId.values.where((m) => m != id))
            other: c.profile.monumentRank(other),
        };
        await mountChartFocus(
          tester,
          shell(c, PortScreen(controller: c, onOpenChart: () {})),
          GlobalKey(),
          const Size(360, 900),
          scale: 1.3,
        );
        await press(tester, 'COMMUNE');
        await press(tester, 'CURSED MONUMENTS');
        for (final rank in [1, 2]) {
          final preview = HarborMonumentPreview(c.profile, id);
          final inventory = MetaInventory.fromJson(c.metaInventory.toJson());
          inventory.spendCost(preview.cost);
          final buy = find.byKey(ValueKey('monument-upgrade-${id.name}'));
          await tester.ensureVisible(buy);
          await tester.pumpAndSettle();
          await tester.tap(buy);
          await tester.pumpAndSettle();
          expect(c.profile.monumentRank(id), rank);
          expect(c.metaInventory.toJson(), inventory.toJson());
          final refreshed = HarborMonumentPreview(c.profile, id);
          expect(
            values(tester, 'monument-rank-${id.name}'),
            '$rank → ${rank + 1}',
          );
          expect(
            values(tester, 'monument-bonus-${id.name}'),
            '${preview.nextText} → ${refreshed.nextText}',
          );
          final offer = find.byKey(ValueKey('monument-offer-${id.name}'));
          final nextCosts = switch (id) {
            HarborMonumentId.obsidianObelisk => [
              'Cost: 10 Sea Glass, 2 Kraken Beak, 2 Primordial Cinders',
              'Cost: 15 Sea Glass, 3 Kraken Beak, 3 Primordial Cinders',
            ],
            HarborMonumentId.serpentEffigy => [
              'Cost: 10 Monster Bone, 2 Serpent Scale, 2 Primordial Cinders',
              'Cost: 15 Monster Bone, 3 Serpent Scale, 3 Primordial Cinders',
            ],
            HarborMonumentId.calderaBrazier => [
              'Cost: 8 Depth Iron, 1 Leviathan Core, 4 Primordial Cinders',
              'Cost: 12 Depth Iron, 1 Leviathan Core, 6 Primordial Cinders',
            ],
          };
          expect(
            find.descendant(
              of: offer,
              matching: find.text(nextCosts[rank - 1]),
            ),
            findsOneWidget,
          );
          for (final other in beforeOtherBonuses.entries) {
            expect(c.profile.monumentRank(other.key), other.value);
          }
        }
        // An exact-cost next purchase must leave an unaffordable preview visible.
        final cost = HarborMonumentPreview(c.profile, id).cost;
        c.metaInventory
          ..seaGlass = cost.seaGlass
          ..monsterBone = cost.monsterBone
          ..depthWroughtIron = cost.depthWroughtIron
          ..abyssalBarnacles = cost.abyssalBarnacles
          ..krakenBeak = cost.krakenBeak
          ..serpentScale = cost.serpentScale
          ..leviathanCore = cost.leviathanCore
          ..primordialCinders = cost.primordialCinders;
        final buy = find.byKey(ValueKey('monument-upgrade-${id.name}'));
        await tester.ensureVisible(buy);
        await tester.tap(buy);
        await tester.pumpAndSettle();
        expect(c.profile.monumentRank(id), 3);
        expect(tester.widget<InkButton>(buy).onPressed, isNull);
        expect(values(tester, 'monument-rank-${id.name}'), '3 → 4');
        expect(tester.takeException(), isNull);
      },
    );
  }
}
