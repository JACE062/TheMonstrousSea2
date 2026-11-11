import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/screens/port_screen.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';
import 'package:monstrous_sea/src/widgets/eldritch_relic_preview.dart';
import 'package:monstrous_sea/src/widgets/ink_button.dart';
import 'package:monstrous_sea/src/widgets/mechanic_text.dart';

import 'ancestral_armament_ui_test.dart' show values;
import 'chart_focus_ui_test.dart' show mountChartFocus, captureChartFocusProof;
import 'home_layout_matrix_test.dart' show home, Wealth, press;
import 'navigation_layout_matrix_test.dart' show shell;

GameController relicHome(String state) {
  final c = home(
    state == 'poor' ? Wealth.poor : Wealth.rich,
    BlueprintId.standard,
  );
  if (state != 'locked') {
    c.profile.unlockedBlueprints.addAll(
      BlueprintId.values.map((id) => id.name),
    );
  }
  c.dispatch(const ChooseShip(ShipClass.standard));
  if (state == 'forged' || state == 'inactive') {
    for (final id in EldritchRelicId.values) {
      c.dispatch(UnlockEldritchRelic(id));
    }
    if (state == 'inactive') c.profile.activeEldritchRelics.clear();
  }
  return c;
}

Future<void> openRelics(
  WidgetTester tester,
  GameController c,
  GlobalKey key,
  Size size,
  double scale,
) async {
  await mountChartFocus(
    tester,
    shell(c, PortScreen(controller: c, onOpenChart: () {})),
    key,
    size,
    scale: scale,
  );
  await press(tester, 'COMMUNE');
  await press(tester, 'ELDRITCH RELICS');
}

void main() {
  setUpAll(
    () => InkTheme.disableGoogleFonts = const String.fromEnvironment(
      'artFontCache',
    ).isEmpty,
  );
  for (final state in ['locked', 'poor', 'ready', 'forged', 'inactive']) {
    for (final size in [
      const Size(360, 900),
      const Size(800, 480),
      const Size(1280, 900),
    ]) {
      for (final scale in [1.15, 1.3]) {
        testWidgets('relics $state $size/$scale', (tester) async {
          final c = relicHome(state);
          addTearDown(c.dispose);
          final before = jsonEncode({
            'profile': c.profile.toJson(),
            'ship': c.ship!.toJson(),
            'chart': c.seaChart.toJson(),
          });
          final key = GlobalKey();
          await openRelics(tester, c, key, size, scale);
          for (final id in EldritchRelicId.values) {
            final preview = EldritchRelicPreview(c.profile, id);
            final offer = find.byKey(ValueKey('relic-offer-${id.name}'));
            await tester.ensureVisible(offer);
            await tester.pumpAndSettle();
            for (final stat in preview.stats) {
              expect(
                values(tester, 'relic-${id.name}-${stat.id}'),
                '${stat.current}${stat.next == null ? '' : ' → ${stat.next}'}',
              );
            }
            final forge = find.byKey(ValueKey('relic-forge-${id.name}'));
            if (!preview.isForged) {
              expect(
                find.descendant(
                  of: offer,
                  matching: find.textContaining('Forge cost:'),
                ),
                findsOneWidget,
              );
            }
            if (state == 'locked' || preview.isForged) {
              expect(forge, findsNothing);
              expect(
                find.descendant(
                  of: offer,
                  matching: find.text(
                    preview.isForged
                        ? 'FORGED'
                        : 'REQUIRES ${preview.blueprintName.toUpperCase()}',
                  ),
                ),
                findsOneWidget,
              );
              if (preview.isForged) {
                expect(
                  find.descendant(
                    of: offer,
                    matching: find.text(
                      state == 'inactive'
                          ? 'Inactive'
                        : 'Active for ${preview.blueprintName}',
                    ),
                  ),
                  findsOneWidget,
                );
              }
            } else {
              await tester.ensureVisible(forge);
              await tester.pumpAndSettle();
              expect(
                tester.widget<InkButton>(forge).onPressed != null,
                state == 'ready',
              );
              expect(forge.hitTestable(), findsOneWidget);
              final rect = tester.getRect(forge);
              expect(rect.left, greaterThanOrEqualTo(0));
              expect(rect.right, lessThanOrEqualTo(size.width));
              expect(rect.top, greaterThanOrEqualTo(0));
              expect(rect.bottom, lessThanOrEqualTo(size.height));
            }
            for (final text
                in find
                    .descendant(of: offer, matching: find.byType(RichText))
                    .evaluate()) {
              expect(
                (text.renderObject! as RenderParagraph).didExceedMaxLines,
                isFalse,
              );
            }
            if (state == 'ready' && size.height == 900 && scale == 1.15) {
              await tester.ensureVisible(offer);
              await tester.pumpAndSettle();
              await captureChartFocusProof(
                tester,
                key,
                'relic-${id.name}-${size.width.toInt()}',
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

  for (final id in EldritchRelicId.values) {
    testWidgets(
      '$id forging refreshes effects, ownership and payment without changing the vessel',
      (tester) async {
        final c = relicHome('ready');
        addTearDown(c.dispose);
        final shipBefore = jsonEncode(c.ship!.toJson());
        final preview = EldritchRelicPreview(c.profile, id);
        final inventory = MetaInventory.fromJson(c.metaInventory.toJson());
        inventory.spendCost(preview.cost);
        await openRelics(tester, c, GlobalKey(), const Size(360, 900), 1.3);
        final forge = find.byKey(ValueKey('relic-forge-${id.name}'));
        await tester.ensureVisible(forge);
        await tester.pumpAndSettle();
        await tester.tap(forge);
        await tester.pumpAndSettle();
        expect(c.profile.isEldritchRelicActive(id), isTrue);
        expect(c.profile.isEldritchRelicUnlocked(id), isTrue);
        expect(c.metaInventory.toJson(), inventory.toJson());
        expect(jsonEncode(c.ship!.toJson()), shipBefore);
        expect(forge, findsNothing);
        final offer = find.byKey(ValueKey('relic-offer-${id.name}'));
        expect(
          find.descendant(of: offer, matching: find.text('FORGED')),
          findsOneWidget,
        );
        for (final stat in preview.stats) {
          expect(values(tester, 'relic-${id.name}-${stat.id}'), stat.next);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final term in ['Burning', 'Poison', 'Obscurity']) {
    for (final width in [360.0, 1280.0]) {
      testWidgets('relic $term keyword help at $width/130%', (tester) async {
        final c = relicHome('ready');
        addTearDown(c.dispose);
        await openRelics(tester, c, GlobalKey(), Size(width, 900), 1.3);
        final word = find.text(term);
        await tester.ensureVisible(word);
        await tester.pumpAndSettle();
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: Offset.zero);
        addTearDown(mouse.removePointer);
        await mouse.moveTo(tester.getCenter(word));
        await tester.pumpAndSettle();
        final help = find.text(const MechanicContext().explanation(term));
        expect(help, findsOneWidget);
        final rect = tester.getRect(help);
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(width));
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(rect.bottom, lessThanOrEqualTo(900));
        await mouse.moveTo(const Offset(5, 880));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();
        expect(help, findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
