import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/screens/helm_screen.dart';
import 'package:monstrous_sea/src/screens/sea_chart_screen.dart';
import 'package:monstrous_sea/src/settings/game_settings.dart';
import 'package:monstrous_sea/src/playtest/playtest_host.dart';
import 'package:monstrous_sea/src/widgets/pause_menu.dart';
import 'package:monstrous_sea/src/widgets/nautical_chart.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';

import 'chart_focus_ui_test.dart' show mountChartFocus, captureChartFocusProof;

enum Situation {
  opening,
  ordinary,
  midpoint,
  preparation,
  titan,
  vendetta,
  fog,
  spent,
  lowHull,
  identified,
  longNemesis,
}

GameController navigator(
  Situation situation, {
  int region = 0,
  BloodlineTrait? boon,
  BloodlineTrait? quirk,
  int seed = 42,
}) {
  final c = GameController(
    session: GameSession(rng: SeededGameRng(seed)),
    autoSave: false,
  )..dispatch(const BeginFirstVoyage('Chart audit'));
  c.session.activeBoon = boon;
  c.session.activeQuirk = quirk;
  c.seaChart.reset(rng: SeededGameRng(seed));
  for (var i = 0; i < region; i++) {
    c.seaChart.advanceRegion(SeededGameRng(seed + i));
  }
  if (situation == Situation.fog) {
    c.profile.activePacts.add(CovenantPactId.chokingFog);
  }
  if (situation == Situation.vendetta || situation == Situation.longNemesis) {
    c.profile.activeNemesis = NemesisRecord.createFromDefeat(
      killer: createMonster(
        MonsterSpecies.crustacean,
        level: 4 + region * 4,
        rng: SeededGameRng(9),
      ),
      captainName: 'Alexandrina Waverley-Montgomery',
      regionIndex: region,
      rng: SeededGameRng(10),
    );
  }
  c.seaChart.currentLeg = switch (situation) {
    Situation.opening => 0,
    Situation.midpoint => c.seaChart.midpointHavenLeg - 1,
    Situation.preparation => c.seaChart.totalLegs - 1,
    Situation.titan => c.seaChart.totalLegs,
    Situation.vendetta || Situation.longNemesis => c.seaChart.midpointHavenLeg,
    _ => 2,
  };
  c.session
    ..phase = SessionPhase.restArea
    ..currentMonster = null
    ..hasDefeatedCurrentEncounter = true;
  c.ship!
    ..currentHp = situation == Situation.lowHull ? 10 : c.ship!.maxHp
    ..gold = 666;
  if (situation == Situation.spent) {
    c.session.stormSeerRedrawRegion = c.seaChart.timesCompleted;
  }
  c.dispatch(const TakeHelm());
  if (situation == Situation.identified) {
    final json = c.seaChart.toJson();
    json['courseOptions'] = c.currentCourseOptions
        .map((o) => o.copyWith(isIdentified: true).toJson())
        .toList();
    c.seaChart.restoreFromJson(json);
  }
  if (situation == Situation.longNemesis || situation == Situation.vendetta) {
    expect(c.currentCourseOptions.where((o) => o.isNemesis), hasLength(1));
    expect(
      c.currentCourseOptions,
      hasLength(situation == Situation.vendetta ? 1 : 3),
    );
  }
  return c;
}

Widget shell(GameController c, Widget screen) => PlaytestHost(
  gameBuilder: (_) => const SizedBox.shrink(),
  child: PauseMenuHost(controller: c, label: 'Layout audit', child: screen),
);

Future<void> checkHelm(
  WidgetTester tester,
  GameController c,
  Size size, {
  double scale = 1.15,
  String? capture,
  bool full = true,
}) async {
  final before = c.seaChart.toJson();
  final key = GlobalKey();
  await mountChartFocus(
    tester,
    shell(c, HelmScreen(controller: c)),
    key,
    size,
    scale: scale,
  );
  expect(tester.takeException(), isNull);
  final chart = tester.widget<NauticalChart>(find.byType(NauticalChart));
  final rect = tester.getRect(
    find.byKey(const ValueKey('nautical-map-viewport')),
  );
  if (capture != null) {
    await captureChartFocusProof(tester, key, capture);
  }
  // Hermetic Ahem glyph metrics are intentionally unlike the selected game fonts.
  // Require the desktop arrangement with real fonts; always check usable map/actions.
  if (full && !InkTheme.disableGoogleFonts) {
    expect(
      chart.coursePanel,
      isNotNull,
      reason: '115% desktop navigation should keep the full chart.',
    );
    expect(rect.height, greaterThan(size.height * .6));
    expect(find.byKey(const ValueKey('helm-page-scroll')), findsNothing);
  }
  final overlaid = chart.coursePanel != null;
  if (!overlaid) {
    final available = tester
        .getSize(find.byKey(const ValueKey('helm-page-scroll')))
        .height;
    expect(
      rect.height,
      greaterThanOrEqualTo((available - 140).clamp(220, double.infinity)),
      reason: 'Keep most of the page for the map and a visible report heading.',
    );
    if (available >= 360) {
      expect(
        find.textContaining('LOOKOUT OBSERVATION').hitTestable(),
        findsOneWidget,
      );
    }
  }
  final buttons = find.text('STEER THIS HEADING').evaluate().toList()
    ..addAll(find.text('HEADING UNAVAILABLE').evaluate());
  expect(buttons, hasLength(c.currentCourseOptions.length));
  for (final element in buttons) {
    final target = find.byWidget(element.widget);
    if (!overlaid) {
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
    }
    expect(target.hitTestable(), findsOneWidget);
    if (overlaid) {
      final button = tester.getRect(target);
      expect(rect.contains(button.topLeft), isTrue);
      expect(rect.contains(button.bottomRight), isTrue);
    }
  }
  for (final target in [
    find.byKey(const ValueKey('storm-seer-redraw')),
    find.textContaining('PATCH TO 25% ·'),
  ]) {
    if (target.evaluate().isEmpty) continue;
    if (!overlaid) {
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
    }
    expect(target.hitTestable(), findsOneWidget);
    if (overlaid) {
      final bounds = tester.getRect(target);
      expect(rect.contains(bounds.topLeft), isTrue);
      expect(rect.contains(bounds.bottomRight), isTrue);
      expect(
        bounds.bottom,
        lessThan(
          tester.getTopLeft(find.byKey(const ValueKey('zoom-out-chart'))).dy,
        ),
      );
    }
  }
  expect(c.seaChart.toJson(), before);
  expect(tester.takeException(), isNull);
}

void main() {
  setUpAll(
    () => InkTheme.disableGoogleFonts = const String.fromEnvironment(
      'artFontCache',
    ).isEmpty,
  );
  for (final boon in BloodlineTrait.allBoons) {
    for (final quirk in BloodlineTrait.allQuirks) {
      for (final situation in [Situation.ordinary, Situation.lowHull]) {
        testWidgets(
          '115% ${situation.name} traits ${boon.id.name} + ${quirk.id.name}',
          (tester) async {
            final c = navigator(situation, boon: boon, quirk: quirk);
            addTearDown(c.dispose);
            await checkHelm(tester, c, const Size(1672, 952));
          },
        );
      }
    }
  }
  for (var region = 0; region < 3; region++) {
    for (final state in Situation.values) {
      for (final size in [
        const Size(1280, 850),
        const Size(1672, 952),
        const Size(1920, 1080),
      ]) {
        testWidgets('115% region $region ${state.name} $size', (tester) async {
          final c = navigator(
            state,
            region: region,
            boon: BloodlineTrait.stormSeer,
            quirk: state == Situation.vendetta
                ? BloodlineTrait.bloodOath
                : BloodlineTrait.recklessHelmsman,
          );
          addTearDown(c.dispose);
          await checkHelm(
            tester,
            c,
            size,
            full: size.width >= 1672,
            capture:
                size.width == 1672 &&
                    region == 1 &&
                    [
                      Situation.midpoint,
                      Situation.vendetta,
                      Situation.longNemesis,
                      Situation.lowHull,
                    ].contains(state)
                ? '${state.name}-region2-115'
                : null,
          );
        });
      }
    }
  }
  for (final size in [
    const Size(360, 900),
    const Size(1280, 850),
    const Size(1672, 952),
  ]) {
    for (final scale in [1.15, 1.3]) {
      for (final state in [
        Situation.midpoint,
        Situation.longNemesis,
        Situation.lowHull,
      ]) {
        testWidgets('large/compact ${state.name} at $size / $scale', (
          tester,
        ) async {
          final c = navigator(
            state,
            region: 1,
            boon: BloodlineTrait.stormSeer,
            quirk: BloodlineTrait.recklessHelmsman,
          );
          addTearDown(c.dispose);
          await checkHelm(
            tester,
            c,
            size,
            scale: scale,
            full: false,
            capture: state == Situation.midpoint && size.width == 1280
                ? 'fallback-1280-$scale'
                : null,
          );
        });
      }
    }
  }
  for (final state in [
    Situation.midpoint,
    Situation.longNemesis,
    Situation.lowHull,
  ]) {
    testWidgets('high-legibility 115% ${state.name}', (tester) async {
      GameSettings.instance.setHighLegibilityFont(true);
      addTearDown(GameSettings.instance.resetDefaults);
      final c = navigator(
        state,
        region: 1,
        boon: BloodlineTrait.stormSeer,
        quirk: BloodlineTrait.recklessHelmsman,
      );
      addTearDown(c.dispose);
      await checkHelm(tester, c, const Size(1672, 952), full: false);
    });
  }
  for (var region = 0; region < 3; region++) {
    for (final size in [
      const Size(360, 900),
      const Size(1280, 850),
      const Size(1672, 952),
    ]) {
      testWidgets('115% port chart region $region at $size', (tester) async {
        final c = navigator(Situation.ordinary, region: region);
        addTearDown(c.dispose);
        final before = c.seaChart.toJson();
        final key = GlobalKey();
        await mountChartFocus(
          tester,
          shell(
            c,
            SeaChartScreen(
              seaChart: c.seaChart,
              ship: c.ship,
              isInPort: true,
              onClose: () {},
            ),
          ),
          key,
          size,
          scale: 1.15,
        );
        final map = tester.getRect(
          find.byKey(const ValueKey('nautical-map-viewport')),
        );
        expect(
          map.height,
          greaterThan(InkTheme.disableGoogleFonts ? 220 : size.height * .45),
        );
        expect(find.text('CLOSE SEA CHART').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        if (region == 2 && size.width == 1672) {
          await captureChartFocusProof(tester, key, 'stronghold-region3');
        }
        expect(c.seaChart.toJson(), before);
      });
    }
  }
}
