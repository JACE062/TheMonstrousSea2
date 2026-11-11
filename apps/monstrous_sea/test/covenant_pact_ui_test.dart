import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/screens/port_screen.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';
import 'package:monstrous_sea/src/widgets/covenant_pact_preview.dart';
import 'package:monstrous_sea/src/widgets/covenant_pact_offer.dart';
import 'package:monstrous_sea/src/widgets/mechanic_text.dart';

import 'ancestral_armament_ui_test.dart' show values;
import 'chart_focus_ui_test.dart' show mountChartFocus, captureChartFocusProof;
import 'home_layout_matrix_test.dart' show home, Wealth, press;
import 'navigation_layout_matrix_test.dart' show shell;

GameController pactHome(String state) {
  final c = home(Wealth.rich, BlueprintId.standard);
  c.dispatch(const ChooseShip(ShipClass.standard));
  c.profile.activePacts.addAll(switch (state) {
    'one' => [CovenantPactId.abyssalVigor],
    'mixed' => [
      CovenantPactId.feedingFrenzy,
      CovenantPactId.brittleOak,
      CovenantPactId.volatileEnvirons,
    ],
    'all' => CovenantPactId.values,
    _ => <CovenantPactId>[],
  });
  return c;
}

Future<void> openPacts(
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
}

void main() {
  setUpAll(
    () => InkTheme.disableGoogleFonts = const String.fromEnvironment(
      'artFontCache',
    ).isEmpty,
  );
  for (final state in ['none', 'one', 'mixed', 'all']) {
    for (final size in [
      const Size(360, 900),
      const Size(800, 480),
      const Size(1280, 900),
    ]) {
      for (final scale in [1.15, 1.3]) {
        testWidgets('pacts $state $size/$scale', (tester) async {
          final c = pactHome(state);
          addTearDown(c.dispose);
          final before = jsonEncode({
            'profile': c.profile.toJson(),
            'ship': c.ship!.toJson(),
            'chart': c.seaChart.toJson(),
          });
          final key = GlobalKey();
          await openPacts(tester, c, key, size, scale);
          for (final id in CovenantPactId.values) {
            final preview = CovenantPactPreview(c.profile, id);
            final offer = find.byKey(ValueKey('pact-offer-${id.name}'));
            final toggle = find.byKey(ValueKey('pact-toggle-${id.name}'));
            await tester.ensureVisible(toggle);
            await tester.pumpAndSettle();
            expect(tester.widget<Checkbox>(toggle).value, preview.isActive);
            expect(toggle.hitTestable(), findsOneWidget);
            final bounds = tester.getRect(toggle);
            expect(bounds.left, greaterThanOrEqualTo(0));
            expect(bounds.right, lessThanOrEqualTo(size.width));
            expect(bounds.top, greaterThanOrEqualTo(0));
            expect(bounds.bottom, lessThanOrEqualTo(size.height));
            for (final stat in preview.stats) {
              final field = find.byKey(ValueKey('pact-${id.name}-${stat.id}'));
              await tester.ensureVisible(field);
              await tester.pumpAndSettle();
              expect(
                values(tester, 'pact-${id.name}-${stat.id}'),
                '${stat.current} → ${stat.next}',
              );
              expect(field.hitTestable(), findsOneWidget);
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
            if (state == 'none' && size.height == 900 && scale == 1.15) {
              await tester.ensureVisible(offer);
              await tester.pumpAndSettle();
              await captureChartFocusProof(
                tester,
                key,
                'pact-${id.name}-${size.width.toInt()}',
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

  for (final id in CovenantPactId.values) {
    testWidgets(
      '$id activation and removal refresh comparisons without spending or changing the vessel',
      (tester) async {
        final c = pactHome('none');
        addTearDown(c.dispose);
        final before = jsonEncode({
          'profile': c.profile.toJson(),
          'ship': c.ship!.toJson(),
          'chart': c.seaChart.toJson(),
        });
        final resources = c.metaInventory.toJson();
        final ship = jsonEncode(c.ship!.toJson());
        final chart = jsonEncode(c.seaChart.toJson());
        await openPacts(tester, c, GlobalKey(), const Size(360, 900), 1.3);
        for (final activate in [true, false]) {
          final preview = CovenantPactPreview(c.profile, id);
          final toggle = find.byKey(ValueKey('pact-toggle-${id.name}'));
          await tester.ensureVisible(toggle);
          await tester.pumpAndSettle();
          await tester.tap(toggle);
          await tester.pumpAndSettle();
          expect(c.profile.isPactActive(id), activate);
          expect(c.profile.totalPactBurden, preview.nextBurden);
          expect(tester.widget<Checkbox>(toggle).value, activate);
          final updated = CovenantPactPreview(c.profile, id);
          for (final stat in updated.stats) {
            expect(
              values(tester, 'pact-${id.name}-${stat.id}'),
              '${stat.current} → ${stat.next}',
            );
          }
          expect(c.metaInventory.toJson(), resources);
          expect(jsonEncode(c.ship!.toJson()), ship);
          expect(jsonEncode(c.seaChart.toJson()), chart);
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
      },
    );
  }

  for (final term in ['Carapace', 'Frenzy']) {
    for (final width in [360.0, 1280.0]) {
      testWidgets('pact $term help at $width/130% does not toggle the pact', (
        tester,
      ) async {
        final c = pactHome('none');
        addTearDown(c.dispose);
        final before = jsonEncode(c.profile.toJson());
        await openPacts(tester, c, GlobalKey(), Size(width, 900), 1.3);
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
        expect(jsonEncode(c.profile.toJson()), before);
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('locked Covenant offer remains readable with a disabled toggle', (
    tester,
  ) async {
    var toggles = 0;
    final preview = CovenantPactPreview(
      ProfileData(),
      CovenantPactId.abyssalVigor,
    );
    await mountChartFocus(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: CovenantPactOffer(preview: preview, onToggle: () => toggles++),
        ),
      ),
      GlobalKey(),
      const Size(360, 900),
      scale: 1.3,
    );
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).onChanged, isNull);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(toggles, 0);
    expect(tester.takeException(), isNull);
  });
}
