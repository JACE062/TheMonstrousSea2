import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/screens/shrine_screen.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';
import 'package:monstrous_sea/src/widgets/ink_button.dart';
import 'package:monstrous_sea/src/widgets/mechanic_text.dart';
import 'package:monstrous_sea/src/widgets/shrine_blessing_preview.dart';

import 'ancestral_armament_ui_test.dart' show values;
import 'chart_focus_ui_test.dart' show mountChartFocus, captureChartFocusProof;
import 'ocean_powers_ui_test.dart' show shrineController, selectPower;
import 'navigation_layout_matrix_test.dart' show shell;

GameController shrineBuild(OceanPower power, int tier) {
  final c = shrineController();
  c.session.shrineManifestedPowers = [power];
  for (final slot in blessingHardpoints) {
    if (tier > 0) {
      c.ship!.blessings[slot] = HardpointBlessing(
        power: power,
        slot: slot,
        tier: tier.clamp(1, 3),
      );
    }
  }
  if (tier == 4) {
    c.ship!.blessings[HardpointType.broadside] = HardpointBlessing(
      power: OceanPower.values.firstWhere((p) => p != power),
      slot: HardpointType.broadside,
      tier: 2,
    );
    c.ship!.blessings[HardpointType.signature] = HardpointBlessing(
      power: power,
      slot: HardpointType.signature,
      tier: 2,
    );
    c.ship!.blessings.remove(HardpointType.utility);
  }
  c.ship!.currentHp -= 7;
  return c;
}

String snapshot(GameController c) => jsonEncode({
  'profile': c.profile.toJson(),
  'ship': c.ship!.toJson(),
  'chart': c.seaChart.toJson(),
  'communion': c.hasCommunedAtCurrentShrine,
});

Future<void> open(
  WidgetTester tester,
  GameController c,
  GlobalKey key,
  Size size,
  double scale,
  OceanPower power,
) async {
  await mountChartFocus(
    tester,
    shell(c, ShrineScreen(controller: c, onOpenChart: () {})),
    key,
    size,
    scale: scale,
  );
  await selectPower(tester, power);
}

Future<void> inspect(
  WidgetTester tester,
  GameController c,
  OceanPower power,
  Size size, {
  GlobalKey? proof,
}) async {
  for (final slot in blessingHardpoints) {
    final preview = ShrineBlessingPreview(
      c.ship!,
      power,
      slot,
      regionIndex: c.seaChart.currentRegionIndex,
    );
    final card = find.byKey(ValueKey('hardpoint-${slot.name}'));
    final button = find.byKey(ValueKey('bless-${slot.name}'));
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    expect(button.hitTestable(), findsOneWidget);
    expect(
      tester.widget<InkButton>(button).onPressed == null,
      preview.isLocked,
    );
    final bounds = tester.getRect(button);
    expect(bounds.left, greaterThanOrEqualTo(0));
    expect(bounds.right, lessThanOrEqualTo(size.width));
    expect(bounds.top, greaterThanOrEqualTo(0));
    expect(bounds.bottom, lessThanOrEqualTo(size.height));
    expect(
      values(tester, 'shrine-tier-${slot.name}'),
      '${preview.current?.tierLabel ?? 'Undedicated'}${preview.next == null ? '' : ' → ${preview.next!.tierLabel}'}',
    );
    for (final stat in preview.stats) {
      final field = find.byKey(ValueKey('shrine-${slot.name}-${stat.id}'));
      await tester.ensureVisible(field);
      await tester.pumpAndSettle();
      // A Wrap's center can fall between its text runs; check visible bounds.
      final fieldBounds = tester.getRect(field);
      expect(fieldBounds.left, greaterThanOrEqualTo(0));
      expect(fieldBounds.right, lessThanOrEqualTo(size.width));
      expect(fieldBounds.top, greaterThanOrEqualTo(0));
      expect(fieldBounds.bottom, lessThanOrEqualTo(size.height));
      expect(
        values(tester, 'shrine-${slot.name}-${stat.id}'),
        '${stat.current}${stat.next == null ? '' : ' → ${stat.next}'}',
      );
    }
    for (final text
        in find
            .descendant(of: card, matching: find.byType(RichText))
            .evaluate()) {
      expect(
        (text.renderObject! as RenderParagraph).didExceedMaxLines,
        isFalse,
      );
    }
    if (proof != null) {
      await tester.ensureVisible(card);
      await tester.pumpAndSettle();
      await captureChartFocusProof(
        tester,
        proof,
        'blessing-${power.name}-${slot.name}-${size.width.toInt()}',
      );
    }
  }
  expect(tester.takeException(), isNull);
}

void main() {
  setUpAll(
    () => InkTheme.disableGoogleFonts = const String.fromEnvironment(
      'artFontCache',
    ).isEmpty,
  );
  for (final power in OceanPower.values) {
    for (final tier in [0, 1, 2, 3, 4]) {
      for (final size in [const Size(360, 900), const Size(1280, 900)]) {
        for (final scale in [1.15, 1.3]) {
          testWidgets('$power tier $tier blessing previews $size/$scale', (
            tester,
          ) async {
            final c = shrineBuild(power, tier);
            addTearDown(c.dispose);
            final before = snapshot(c);
            final key = GlobalKey();
            await open(tester, c, key, size, scale, power);
            await inspect(
              tester,
              c,
              power,
              size,
              proof: tier == 0 && scale == 1.15 ? key : null,
            );
            expect(snapshot(c), before);
          });
        }
      }
    }
    testWidgets('$power blessing previews on a short window at 130%', (
      tester,
    ) async {
      final c = shrineBuild(power, 0);
      addTearDown(c.dispose);
      final before = snapshot(c);
      const size = Size(800, 480);
      await open(tester, c, GlobalKey(), size, 1.3, power);
      await inspect(tester, c, power, size);
      expect(snapshot(c), before);
    });
    for (final slot in blessingHardpoints) {
      for (final tier in [0, 1, 2]) {
        testWidgets(
          '$power $slot tier $tier actual shrine choice matches preview',
          (tester) async {
            final c = shrineBuild(power, tier);
            addTearDown(c.dispose);
            final preview = ShrineBlessingPreview(c.ship!, power, slot);
            final profile = jsonEncode(c.profile.toJson());
            await open(
              tester,
              c,
              GlobalKey(),
              const Size(360, 900),
              1.3,
              power,
            );
            final accept = find.byKey(ValueKey('bless-${slot.name}'));
            await tester.ensureVisible(accept);
            await tester.pumpAndSettle();
            await tester.tap(accept);
            await tester.pumpAndSettle();
            expect(c.ship!.toJson(), preview.prospectiveShip.toJson());
            expect(jsonEncode(c.profile.toJson()), profile);
            expect(c.hasCommunedAtCurrentShrine, isTrue);
            expect(find.text('COMMUNION COMPLETE'), findsOneWidget);
            expect(find.byKey(ValueKey('bless-${slot.name}')), findsNothing);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
  for (final entry in [
    (
      power: OceanPower.magmaVentLord,
      slot: HardpointType.utility,
      term: 'Burning',
    ),
    (
      power: OceanPower.tempestSovereign,
      slot: HardpointType.signature,
      term: 'Static Charge',
    ),
    (
      power: OceanPower.brinemother,
      slot: HardpointType.broadside,
      term: 'Corroded',
    ),
    (
      power: OceanPower.earthshakerTitan,
      slot: HardpointType.broadside,
      term: 'Shaken',
    ),
  ]) {
    for (final width in [360.0, 1280.0]) {
      testWidgets(
        '${entry.term} shrine help uses the prospective build at $width/130%',
        (tester) async {
          final c = shrineBuild(entry.power, 2);
          addTearDown(c.dispose);
          final before = snapshot(c);
          final p = ShrineBlessingPreview(c.ship!, entry.power, entry.slot);
          final proof = GlobalKey();
          await open(tester, c, proof, Size(width, 900), 1.3, entry.power);
          final card = find.byKey(ValueKey('hardpoint-${entry.slot.name}'));
          final word = find
              .descendant(of: card, matching: find.text(entry.term))
              .first;
          await tester.ensureVisible(word);
          await tester.pumpAndSettle();
          final mouse = await tester.createGesture(
            kind: PointerDeviceKind.mouse,
          );
          await mouse.addPointer(location: Offset.zero);
          addTearDown(mouse.removePointer);
          await mouse.moveTo(tester.getCenter(word));
          await tester.pumpAndSettle();
          final expected = MechanicContext(
            ship: p.prospectiveShip,
            blessing: p.displayed,
          ).explanation(entry.term);
          final help = entry.term == 'Static Charge'
              ? find.textContaining('At 3 stacks, triggers')
              : find.text(expected);
          expect(help, findsOneWidget);
          final rect = tester.getRect(help);
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(width));
          expect(rect.top, greaterThanOrEqualTo(0));
          expect(rect.bottom, lessThanOrEqualTo(900));
          if (entry.term == 'Static Charge') {
            final parent = find.byKey(
              const ValueKey('mechanic-help-Static Charge'),
            );
            final link = find.descendant(
              of: parent,
              matching: find.text('Arc Discharge'),
            );
            await mouse.moveTo(tester.getCenter(link));
            await tester.pumpAndSettle();
            final nested = find.byKey(
              const ValueKey('mechanic-help-Arc Discharge'),
            );
            expect(nested, findsOneWidget);
            await mouse.moveTo(tester.getCenter(nested));
            await tester.pump(const Duration(seconds: 1));
            await tester.pumpAndSettle();
            await captureChartFocusProof(tester, proof, 'nested-shrine-$width');
            expect(nested, findsOneWidget);
            expect(find.textContaining('28 base Shock'), findsOneWidget);
          }
          await mouse.moveTo(const Offset(5, 880));
          await tester.pump(const Duration(milliseconds: 400));
          await tester.pumpAndSettle();
          expect(help, findsNothing);
          expect(snapshot(c), before);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
