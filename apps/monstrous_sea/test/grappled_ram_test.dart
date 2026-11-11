import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/battle/monstrous_sea_battle_game.dart';
import 'package:monstrous_sea/src/screens/battle_screen.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';
import 'package:monstrous_sea/src/widgets/ink_button.dart';
import 'package:monstrous_sea/src/widgets/mechanic_text.dart';

import 'chart_focus_ui_test.dart' show mountChartFocus, captureChartFocusProof;
import 'combat_layout_matrix_test.dart' show fighter, BattleCase, snapshot;
import 'navigation_layout_matrix_test.dart' show shell;

void main() {
  setUpAll(() {
    InkTheme.disableGoogleFonts = const String.fromEnvironment('artFontCache')
        .isEmpty;
  });
  for (final range in [CombatRange.short, CombatRange.medium]) {
    for (final lateHelm in [false, true]) {
      for (final scale in [1.15, 1.3]) {
        testWidgets('Grappled Ram button $range/$lateHelm/$scale', (
          tester,
        ) async {
          final c = fighter(
            BlueprintId.ironclad,
            BattleCase.ready,
            quirk: lateHelm ? BloodlineTrait.skirmisher : null,
          );
          addTearDown(c.dispose);
          c.session.combatRange = range;
          c.ship!
            ..isGrappled = true
            ..utilityCooldown = 2;
          for (final weapon in c.ship!.equippedWeapons) {
            weapon.chargeCountdown = weapon.weaponType == ShipWeaponType.prowRam
                ? 0
                : 2;
          }
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
            initialRange: range,
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
          final ram = find.byKey(const ValueKey('hardpoint-signature'));
          final button = tester.widget<InkButton>(ram);
          final help = tester.widget<MechanicTooltip>(
            find
                .ancestor(of: ram, matching: find.byType(MechanicTooltip))
                .first,
          );
          if (range == CombatRange.medium) {
            expect(button.onPressed, isNull);
            expect(button.subtitle, 'GRAPPLED');
            expect(button.semanticLabel, contains('Grappled'));
            expect(help.message, contains('cannot close to Short Range'));
            expect(
              find.byKey(const ValueKey('emergency-pass')),
              findsOneWidget,
            );
          } else {
            expect(button.onPressed, isNotNull);
            expect(button.subtitle, contains('100% range damage'));
            expect(find.byKey(const ValueKey('emergency-pass')), findsNothing);
          }
          await tester.ensureVisible(ram);
          await tester.pumpAndSettle();
          await captureChartFocusProof(
            tester,
            key,
            'ram-${range.name}-$lateHelm-$scale',
          );
          expect(snapshot(c), before);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump(const Duration(seconds: 1));
        });
      }
    }
  }
}
