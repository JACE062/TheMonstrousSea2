import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/screens/helm_screen.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';
import 'package:monstrous_sea/src/widgets/nautical_chart.dart';

import 'chart_focus_ui_test.dart'
    show chartFocusController, mountChartFocus, captureChartFocusProof;

void main() {
  setUpAll(
    () => InkTheme.disableGoogleFonts = const String.fromEnvironment(
      'artFontCache',
    ).isEmpty,
  );

  for (final (size, scale, spent, triage) in [
    (const Size(2508, 1429), 1.15, false, false),
    (const Size(1672, 952), 1.15, false, false),
    (const Size(1920, 1080), 1.3, true, false),
    (const Size(1920, 1080), 1.3, false, true),
  ]) {
    testWidgets(
      'Storm-Seer keeps a full chart at $size / $scale / $spent / $triage',
      (tester) async {
        final c = chartFocusController(legs: 1);
        addTearDown(c.dispose);
        c.session.activeBoon = BloodlineTrait.stormSeer;
        if (spent) c.session.stormSeerRedrawRegion = c.seaChart.timesCompleted;
        c.ship!
          ..maxHp = 75
          ..currentHp = triage ? 10 : 75
          ..gold = 66;
        final state = c.seaChart.toJson();
        state['courseOptions'] = [
          for (final (bearing, call, type) in [
            (
              NavigationalBearing.larboardTack,
              'Sinewy emerald coils undulating gracefully through the ocean swell off the larboard bow!',
              EncounterNodeType.beastCombat,
            ),
            (
              NavigationalBearing.deadAhead,
              'A massive dark shadow and writhing tentacles drifting beneath the waves dead ahead!',
              EncounterNodeType.beastCombat,
            ),
            (
              NavigationalBearing.starboardTack,
              'A battered wreck with accessible flotsam and sealed lower holds East-Southeast (Starboard Tack). Approach may conceal a lurking creature.',
              EncounterNodeType.shipwreckSalvage,
            ),
          ])
            CourseOption(
              bearing: bearing,
              nodeType: type,
              difficultyLevel: 1,
              lookoutCall: call,
            ).toJson(),
        ];
        c.seaChart.restoreFromJson(state);
        final before = c.seaChart.toJson();
        final key = GlobalKey();
        await mountChartFocus(
          tester,
          HelmScreen(controller: c),
          key,
          size,
          scale: scale,
        );
        final chart = tester.widget<NauticalChart>(find.byType(NauticalChart));
        expect(
          chart.coursePanel,
          isNotNull,
          reason: 'Storm-Seer must not collapse the desktop chart.',
        );
        expect(find.byKey(const ValueKey('helm-page-scroll')), findsNothing);
        final map = tester.getRect(
          find.byKey(const ValueKey('nautical-map-viewport')),
        );
        expect(map.height, greaterThan(size.height * .7));
        final auxiliary = tester.getRect(
          find.byKey(const ValueKey('chart-auxiliary-panel')),
        );
        final courses = tester.getRect(find.byWidget(chart.coursePanel!));
        expect(auxiliary.overlaps(courses), isFalse);
        expect(
          courses.width,
          closeTo(tester.getSize(find.byType(NauticalChart)).width * .3, .01),
        );
        expect(
          auxiliary.bottom,
          lessThan(
            tester.getTopLeft(find.byKey(const ValueKey('zoom-out-chart'))).dy,
          ),
        );
        for (final target in [
          find.byKey(const ValueKey('storm-seer-redraw')),
          ...find
              .text('STEER THIS HEADING')
              .evaluate()
              .map((e) => find.byWidget(e.widget)),
        ]) {
          final rect = tester.getRect(target);
          expect(map.contains(rect.topLeft), isTrue);
          expect(map.contains(rect.bottomRight), isTrue);
        }
        expect(find.text('STEER THIS HEADING').hitTestable(), findsNWidgets(3));
        expect(
          find.byKey(const ValueKey('storm-seer-redraw')).hitTestable(),
          findsOneWidget,
        );
        if (triage) {
          expect(
            find.text('PATCH TO 25% · ${c.emergencyRepairCost}g').hitTestable(),
            findsOneWidget,
          );
        }
        await captureChartFocusProof(
          tester,
          key,
          'storm-${size.width.toInt()}-$scale-$spent-$triage',
        );
        expect(c.seaChart.toJson(), before);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final size in [const Size(360, 900), const Size(800, 480)]) {
    testWidgets(
      'constrained chart keeps support and all headings reachable at $size',
      (tester) async {
        final c = chartFocusController(legs: 1);
        addTearDown(c.dispose);
        c.session.activeBoon = BloodlineTrait.stormSeer;
        c.ship!
          ..currentHp = 10
          ..gold = 66;
        final before = c.seaChart.toJson();
        final key = GlobalKey();
        await mountChartFocus(
          tester,
          HelmScreen(controller: c),
          key,
          size,
          scale: 1.3,
        );
        expect(find.byKey(const ValueKey('helm-page-scroll')), findsOneWidget);
        expect(
          find.byKey(const ValueKey('chart-auxiliary-panel')),
          findsNothing,
        );
        for (final target in [
          find.byKey(const ValueKey('storm-seer-redraw')),
          ...find
              .text('STEER THIS HEADING')
              .evaluate()
              .map((e) => find.byWidget(e.widget)),
        ]) {
          await tester.ensureVisible(target);
          await tester.pumpAndSettle();
          expect(target.hitTestable(), findsOneWidget);
        }
        await captureChartFocusProof(
          tester,
          key,
          'compact-${size.width.toInt()}',
        );
        expect(c.seaChart.toJson(), before);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'resizing restores the full Storm-Seer chart without losing progress',
    (tester) async {
      final c = chartFocusController(legs: 1);
      addTearDown(c.dispose);
      c.session.activeBoon = BloodlineTrait.stormSeer;
      final before = c.seaChart.toJson();
      final key = GlobalKey();
      await mountChartFocus(
        tester,
        HelmScreen(controller: c),
        key,
        const Size(1920, 1080),
        scale: 1.15,
      );
      expect(
        find.byKey(const ValueKey('chart-auxiliary-panel')),
        findsOneWidget,
      );
      tester.view.physicalSize = const Size(800, 480);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('helm-page-scroll')), findsOneWidget);
      tester.view.physicalSize = const Size(1920, 1080);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('helm-page-scroll')), findsNothing);
      expect(
        find.byKey(const ValueKey('chart-auxiliary-panel')),
        findsOneWidget,
      );
      expect(c.seaChart.toJson(), before);
      expect(tester.takeException(), isNull);
    },
  );
}
