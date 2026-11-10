import 'dart:convert';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/battle/monstrous_sea_battle_game.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/playtest/playtest_screen.dart';
import 'package:monstrous_sea/src/screens/battle_screen.dart';
import 'package:monstrous_sea/src/screens/helm_screen.dart';
import 'package:monstrous_sea/src/screens/port_screen.dart';
import 'package:monstrous_sea/src/widgets/mechanic_text.dart';
import 'package:monstrous_sea/src/widgets/battle_lookout.dart';
import 'package:monstrous_sea/src/widgets/ocean_power_badges.dart';
import 'package:monstrous_sea/src/widgets/vessel_inspection.dart';
import 'package:monstrous_sea/src/widgets/parchment_scaffold.dart';

import 'chart_focus_ui_test.dart'
    show mountChartFocus, captureChartFocusProof, chartFocusController;
import 'combat_layout_matrix_test.dart' show fighter, BattleCase;
import 'encounter_layout_matrix_test.dart' as shore;
import 'home_layout_matrix_test.dart' as home;
import 'navigation_layout_matrix_test.dart' show shell;
import 'tooltip_sweep_test.dart' show loadSweepFonts, painted;

Finder cards() => find.byWidgetPredicate(
  (w) =>
      w is SingleChildScrollView &&
      w.key is ValueKey<String> &&
      (w.key! as ValueKey<String>).value.startsWith('mechanic-help-'),
);
Finder links(Finder scope) => find.descendant(
  of: scope,
  matching: find.byWidgetPredicate(
    (w) => w is InkWell && w.mouseCursor == SystemMouseCursors.help,
  ),
);

void checkCards(WidgetTester tester, Size size) {
  final rects = <Rect>[];
  for (final element in cards().evaluate()) {
    final card = find.byElementPredicate((e) => e == element);
    final rect = painted(
      tester,
      find.ancestor(of: card, matching: find.byType(Container)).first,
    );
    expect(rect.left, greaterThanOrEqualTo(11.9));
    expect(rect.top, greaterThanOrEqualTo(11.9));
    expect(rect.right, lessThanOrEqualTo(size.width - 11.9));
    expect(rect.bottom, lessThanOrEqualTo(size.height - 11.9));
    for (final previous in rects) {
      expect(
        rect.overlaps(previous),
        isFalse,
        reason:
            '${element.widget.key}: $rect overlaps $previous. '
            'Open cards: ${cards().evaluate().map((e) => e.widget.key).toList()}',
      );
    }
    rects.add(rect);
    for (final paragraph
        in find
            .descendant(of: card, matching: find.byType(RichText))
            .evaluate()) {
      expect(
        (paragraph.renderObject! as RenderParagraph).didExceedMaxLines,
        isFalse,
      );
    }
  }
  expect(rects, isNotEmpty);
}

Future<int> readBranch(WidgetTester tester, Size size) async {
  var depth = 1;
  checkCards(tester, size);
  for (var level = 0; level < 2; level++) {
    final childLinks = links(cards().last);
    if (childLinks.evaluate().isEmpty) break;
    await tester.ensureVisible(childLinks.first);
    await tester.pumpAndSettle();
    await tester.tap(childLinks.first);
    await tester.pumpAndSettle();
    depth++;
    expect(cards(), findsNWidgets(depth));
    checkCards(tester, size);
  }
  for (var i = 0; i < depth; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
  }
  expect(cards(), findsNothing);
  return depth;
}

Future<void> audit(
  WidgetTester tester,
  GlobalKey key,
  Size size,
  String name,
) async {
  var branches = 0, native = 0;
  final roots = links(find.byType(MaterialApp))
      .evaluate()
      .where((element) => ModalRoute.of(element)?.isCurrent != false)
      .toList();
  for (final element in roots) {
    if (!element.mounted || ModalRoute.of(element)?.isCurrent == false) {
      continue;
    }
    final target = find.byElementPredicate((e) => e == element);
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
    expect(cards(), findsOneWidget);
    if (branches == 0) {
      await captureChartFocusProof(tester, key, '$name-keyword');
    }
    branches += await readBranch(tester, size);
  }
  for (final element in find.byType(MechanicTooltip).evaluate().toList()) {
    if (!element.mounted || ModalRoute.of(element)?.isCurrent == false) {
      continue;
    }
    final target = find.byElementPredicate((e) => e == element);
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    // The dock can contain clipped rows; scroll its actual action into view.
    await tester.longPress(target);
    await tester.pumpAndSettle();
    expect(cards(), findsOneWidget);
    if (branches == 0) {
      await captureChartFocusProof(tester, key, '$name-action');
    }
    branches += await readBranch(tester, size);
  }
  for (final element in find.byType(Tooltip).evaluate().toList()) {
    if (!element.mounted || ModalRoute.of(element)?.isCurrent == false) {
      continue;
    }
    final tooltip = element.widget as Tooltip;
    if (tooltip.message == null || tooltip.message!.isEmpty) continue;
    final target = find.byElementPredicate((e) => e == element);
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    final rect = painted(tester, target);
    if (!(Offset.zero & size).contains(rect.center) ||
        target.hitTestable().evaluate().isEmpty) {
      continue;
    }
    final state = tester.state<TooltipState>(target);
    state.ensureTooltipVisible();
    await tester.pump(const Duration(milliseconds: 300));
    final text = find
        .byWidgetPredicate(
          (w) => w is Text && w.textSpan?.toPlainText() == tooltip.message,
        )
        .last;
    expect(text, findsOneWidget);
    final box = painted(tester, text);
    expect(box.left, greaterThanOrEqualTo(0));
    expect(box.top, greaterThanOrEqualTo(0));
    expect(box.right, lessThanOrEqualTo(size.width));
    expect(box.bottom, lessThanOrEqualTo(size.height));
    if (native == 0) await captureChartFocusProof(tester, key, '$name-native');
    native++;
    Tooltip.dismissAllToolTips();
    await tester.pumpAndSettle();
  }
  expect(
    branches + native,
    greaterThan(0),
    reason: '$name must actually exercise help.',
  );
  // Counts are retained in the expanded log, without changing gameplay state.
  // ignore: avoid_print
  print('$name: $branches linked cards, $native native targets');
  expect(tester.takeException(), isNull);
}

String snapshot(GameController c) => jsonEncode({
  'ship': c.ship?.toJson(),
  'profile': c.profile.toJson(),
  'chart': c.seaChart.toJson(),
  'phase': c.phase.name,
  'loot': c.pendingLoot.map((i) => i.id).toList(),
});

void main() {
  setUpAll(loadSweepFonts);
  const owners = [
    'merchant',
    'loot',
    'wreck',
    'haven',
    'stronghold',
    'shrine',
    'blueprints',
    'inspection',
    'chart',
    'badges',
    'battle',
    'battleReload',
    'intent',
    'playtest',
  ];
  for (final owner in owners) {
    for (final size in [
      const Size(360, 900),
      if (['blueprints', 'inspection', 'badges'].contains(owner))
        const Size(800, 480),
      const Size(1280, 850),
    ]) {
      for (final scale in [
        1.15,
        if (['inspection', 'chart', 'battle', 'badges'].contains(owner)) 1.3,
      ]) {
        testWidgets('$owner tooltip targets $size/$scale', (tester) async {
          final c = owner == 'chart'
              ? chartFocusController(legs: 16)
              : ['blueprints', 'inspection'].contains(owner)
              ? home.home(home.Wealth.owned, BlueprintId.bombardier)
              : ['battle', 'battleReload', 'badges', 'intent'].contains(owner)
              ? fighter(
                  BlueprintId.bombardier,
                  owner == 'battleReload'
                      ? BattleCase.cooldowns
                      : BattleCase.dense,
                )
              : shore.fixture(switch (owner) {
                  'merchant' => shore.EncounterCase.merchantFull,
                  'loot' => shore.EncounterCase.lootFull,
                  'wreck' => shore.EncounterCase.wreckReceipt,
                  'haven' => shore.EncounterCase.haven,
                  'stronghold' => shore.EncounterCase.stronghold,
                  _ => shore.EncounterCase.shrineCompare,
                }, power: OceanPower.tempestSovereign);
          addTearDown(c.dispose);
          if (owner == 'battleReload') c.ship!.utilityCooldown = 2;
          if (owner == 'intent') {
            c.currentMonster!.currentIntent = MonsterIntent.fromId(
              MonsterIntentId.sharkBreachingLunge,
            );
          }
          if (owner == 'inspection') {
            for (final slot in blessingHardpoints) {
              c.ship!.blessings[slot] = HardpointBlessing(
                power: OceanPower.tempestSovereign,
                slot: slot,
                tier: 3,
              );
            }
          }
          final before = snapshot(c);
          final key = GlobalKey();
          await mountChartFocus(
            tester,
            const SizedBox.shrink(),
            GlobalKey(),
            size,
            scale: scale,
          );
          MonstrousSeaBattleGame? game;
          if (owner == 'battle' || owner == 'battleReload') {
            game = MonstrousSeaBattleGame(
              ship: c.ship!,
              monster: c.currentMonster!,
              initialRange: c.combatRange,
            );
            await tester.runAsync(() async {
              game!.onGameResize(Vector2(size.width, size.height));
              // ignore: invalid_use_of_internal_member
              await game.load();
            });
            game.pauseEngine();
          }
          final page = switch (owner) {
            'blueprints' => PortScreen(controller: c, onOpenChart: () {}),
            'inspection' => Center(child: InspectVesselButton(controller: c)),
            'chart' => HelmScreen(controller: c),
            'battle' => BattleScreen(controller: c, game: game!),
            'battleReload' => BattleScreen(controller: c, game: game!),
            'intent' => ParchmentScaffold(
              body: MechanicScope(
                data: MechanicContext(ship: c.ship, monster: c.currentMonster),
                child: BattleLookout(
                  monster: c.currentMonster!,
                  currentRange: c.combatRange,
                  selectedHelmOrder: HelmOrder.holdLine,
                  conditional: false,
                  isResolving: false,
                ),
              ),
            ),
            'playtest' => PlaytestScreen(
              gameBuilder: (_) => const SizedBox.shrink(),
            ),
            'badges' => ParchmentScaffold(
              body: SingleChildScrollView(
                child: MechanicScope(
                  data: MechanicContext(
                    ship: c.ship,
                    monster: c.currentMonster,
                    regionIndex: 2,
                  ),
                  child: Column(
                    children: [
                      ShipPowerStatusBadges(ship: c.ship!),
                      MonsterPowerStatusBadges(monster: c.currentMonster!),
                      for (final power in OceanPower.values)
                        for (final slot in blessingHardpoints)
                          for (final tier in [1, 2, 3])
                            BlessingBadge(
                              blessing: HardpointBlessing(
                                power: power,
                                slot: slot,
                                tier: tier,
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ),
            _ => shore.screen(c),
          };
          await mountChartFocus(
            tester,
            shell(c, page),
            key,
            size,
            scale: scale,
          );
          if (game != null) {
            game.resumeEngine();
            await tester.pump(const Duration(milliseconds: 100));
            game.pauseEngine();
            await tester.runAsync(game.ready);
            game.update(0);
            await tester.pumpAndSettle();
          }
          if (owner == 'blueprints' ||
              owner == 'inspection' ||
              owner == 'shrine' ||
              owner == 'intent') {
            final target = owner == 'blueprints'
                ? find.text('BLUEPRINTS')
                : owner == 'inspection'
                ? find.text('INSPECT VESSEL')
                : owner == 'intent'
                ? find.byTooltip('Inspect monster intent')
                : find.byKey(const ValueKey('select-tempestSovereign'));
            await tester.ensureVisible(target);
            await tester.tap(target);
            await tester.pumpAndSettle();
          }
          try {
            await audit(
              tester,
              key,
              size,
              '$owner-${size.width.toInt()}-$scale',
            );
          } catch (_) {
            await captureChartFocusProof(
              tester,
              key,
              'failure-$owner-${size.width.toInt()}-$scale',
            );
            rethrow;
          }
          expect(snapshot(c), before);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump(const Duration(seconds: 1));
        });
      }
    }
  }
}
