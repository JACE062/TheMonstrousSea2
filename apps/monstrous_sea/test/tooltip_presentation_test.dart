import 'dart:convert';
import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/battle/monstrous_sea_battle_game.dart';
import 'package:monstrous_sea/src/screens/battle_screen.dart';
import 'package:monstrous_sea/src/settings/game_settings.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';
import 'package:monstrous_sea/src/widgets/mechanic_text.dart';
import 'package:monstrous_sea/src/widgets/parchment_scaffold.dart';

import 'chart_focus_ui_test.dart' show mountChartFocus, captureChartFocusProof;
import 'combat_layout_matrix_test.dart' show fighter, BattleCase, snapshot;
import 'navigation_layout_matrix_test.dart' show shell;

Size paintedSize(WidgetTester tester, Finder finder) {
  final delta = tester.getBottomRight(finder) - tester.getTopLeft(finder);
  return Size(delta.dx, delta.dy);
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

  for (final plain in [false, true]) {
    for (final scale in [1.15, 1.3]) {
      testWidgets('keywords match surrounding text scale $plain/$scale', (
        tester,
      ) async {
        final settings = GameSettings.instance;
        final previous = settings.highLegibilityFont;
        settings.setHighLegibilityFont(plain);
        addTearDown(() => settings.setHighLegibilityFont(previous));
        await mountChartFocus(
          tester,
          const SizedBox.shrink(),
          GlobalKey(),
          const Size(1280, 900),
          scale: scale,
        );
        final key = GlobalKey();
        final styles = [InkTheme.body, InkTheme.caption];
        const terms = ['Carapace', 'Static Charge', 'Illuminated'];
        await mountChartFocus(
          tester,
          ParchmentScaffold(
            body: Column(
              children: [
                for (var i = 0; i < styles.length; i++)
                  for (final term in terms)
                    Row(
                      children: [
                        SizedBox(
                          width: 350,
                          child: MechanicText(
                            'Applies $term.',
                            key: ValueKey('linked-$i-$term'),
                            style: styles[i],
                          ),
                        ),
                        Text(
                          term,
                          key: ValueKey('reference-$i-$term'),
                          style: styles[i].copyWith(
                            fontWeight: FontWeight.w600,
                            color: InkTheme.goldAccent,
                          ),
                        ),
                      ],
                    ),
              ],
            ),
          ),
          key,
          const Size(1280, 900),
          scale: scale,
        );
        await captureChartFocusProof(tester, key, 'type-$plain-$scale');
        for (var i = 0; i < styles.length; i++) {
          for (final term in terms) {
            final linked = find.descendant(
              of: find.byKey(ValueKey('linked-$i-$term')),
              matching: find.text(term),
            );
            final reference = find.byKey(ValueKey('reference-$i-$term'));
            final actual = paintedSize(tester, linked);
            final expected = paintedSize(tester, reference);
            expect(
              actual.width,
              // WidgetSpan also scales letter spacing; allow subpixel glyph
              // metrics while rejecting the former 15–30% extra text scale.
              closeTo(expected.width, 1.5),
              reason: '$term must scale exactly once.',
            );
            expect(actual.height, closeTo(expected.height, 1));
            final text = tester.widget<Text>(linked);
            expect(text.style!.color, InkTheme.goldAccent);
            expect(text.style!.fontWeight, FontWeight.w600);
            expect(text.style!.decoration, TextDecoration.none);
          }
        }
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final hull in BlueprintId.values) {
    for (final scale in [1.15, 1.3]) {
      testWidgets(
        'fitting help keeps its effects without repeated dodge or forecasts $hull/$scale',
        (tester) async {
          final c = fighter(hull, BattleCase.ready);
          addTearDown(c.dispose);
          final before = snapshot(c);
          const size = Size(1280, 900);
          await mountChartFocus(
            tester,
            const SizedBox.shrink(),
            GlobalKey(),
            size,
            scale: scale,
          );
          final game = MonstrousSeaBattleGame(
            ship: c.ship!,
            monster: c.currentMonster!,
            initialRange: c.combatRange,
          );
          await tester.runAsync(() async {
            game.onGameResize(Vector2(size.width, size.height));
            // ignore: invalid_use_of_internal_member
            await game.load();
          });
          game.pauseEngine();
          final key = GlobalKey();
          await mountChartFocus(
            tester,
            shell(c, BattleScreen(controller: c, game: game)),
            key,
            size,
            scale: scale,
          );
          game.resumeEngine();
          await tester.pump(const Duration(milliseconds: 100));
          game.pauseEngine();
          await tester.runAsync(game.ready);
          game.update(0);
          await tester.pumpAndSettle();
          for (final slot in ['broadside', 'signature', 'utility']) {
            final target = find.byKey(ValueKey('hardpoint-$slot'));
            final tooltip = tester.widget<MechanicTooltip>(
              find
                  .ancestor(of: target, matching: find.byType(MechanicTooltip))
                  .first,
            );
            final label = find
                .descendant(of: target, matching: find.byType(Text))
                .first;
            await tester.ensureVisible(label);
            await tester.pumpAndSettle();
            Focus.of(tester.element(label)).requestFocus();
            await tester.pump();
            await tester.sendKeyEvent(LogicalKeyboardKey.f1);
            await tester.pumpAndSettle();
            if (hull == BlueprintId.clipper) {
              await captureChartFocusProof(
                tester,
                key,
                '${hull.name}-$slot-$scale',
              );
            }
            expect(
              tooltip.message,
              tooltip.message.trim(),
              reason: '$hull $slot must not end in an empty forecast line.',
            );
            expect(tooltip.message, isNot(contains('\n\n')));
            expect(tooltip.message, isNot(contains('Target dodge:')));
            expect(tooltip.message, isNot(contains('After action:')));
            if (slot != 'utility') {
              expect(tooltip.message, contains('Opening shot accuracy:'));
            } else if (hull == BlueprintId.clipper) {
              expect(tooltip.message, contains('Moves one range band away.'));
              expect(
                tooltip.message,
                contains('evasion until the next successful dodge.'),
              );
            }
            expect(
              find.byKey(const ValueKey('mechanic-help-action')),
              findsOneWidget,
            );
            await tester.sendKeyEvent(LogicalKeyboardKey.escape);
            await tester.pumpAndSettle();
          }
          expect(
            find.text('• Dodge: ${c.currentMonster!.effectiveEvasion}%'),
            findsOneWidget,
          );
          expect(snapshot(c), before);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump(const Duration(seconds: 1));
        },
      );
    }
  }
}
