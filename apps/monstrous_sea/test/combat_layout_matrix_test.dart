import 'dart:convert';
import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/screens/battle_screen.dart';
import 'package:monstrous_sea/src/battle/monstrous_sea_battle_game.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';
import 'package:monstrous_sea/src/widgets/ink_button.dart';
import 'package:monstrous_sea/src/widgets/combat_stats.dart';
import 'package:monstrous_sea/src/widgets/mechanic_text.dart';
import 'package:monstrous_sea/src/widgets/hull_gauge.dart';

import 'chart_focus_ui_test.dart' show mountChartFocus, captureChartFocusProof;
import 'navigation_layout_matrix_test.dart' show shell;

enum BattleCase {
  ready,
  dense,
  cooldowns,
  combination,
  recovery,
  beltSpent,
  emptyBelt,
  windup,
  release,
  longRange,
  storm,
  wake,
}

GameController fighter(
  BlueprintId blueprint,
  BattleCase state, {
  BloodlineTrait? boon,
  BloodlineTrait? quirk,
}) {
  final c = GameController(
    session: GameSession(rng: SeededGameRng(42)),
    autoSave: false,
  )..dispatch(const BeginFirstVoyage('Alexandrina Waverley-Montgomery'));
  c.session.activeBoon = boon;
  c.session.activeQuirk = quirk;
  c.session.ship = createFlagshipFromBlueprint(
    blueprint,
    level: 4,
    rng: SeededGameRng(11),
  );
  final ship = c.ship!;
  ship.currentHp = ship.maxHp ~/ 3;
  ship.maxCargo += 2;
  for (final slot in blessingHardpoints) {
    ship.hardpointMarks[slot] = 3;
  }
  ship.blessings.addAll({
    HardpointType.broadside: const HardpointBlessing(
      power: OceanPower.earthshakerTitan,
      slot: HardpointType.broadside,
      tier: 3,
    ),
    HardpointType.signature: const HardpointBlessing(
      power: OceanPower.brinemother,
      slot: HardpointType.signature,
      tier: 3,
    ),
    HardpointType.utility: const HardpointBlessing(
      power: OceanPower.earthshakerTitan,
      slot: HardpointType.utility,
      tier: 3,
    ),
  });
  if (state != BattleCase.emptyBelt) {
    for (var i = 0; i < ship.maxCargo; i++) {
      ship.cargo.add(
        generateConsumable(
          ConsumableType.values[i % ConsumableType.values.length],
          RarityLevel.common,
        ),
      );
    }
  }
  final species = switch (state) {
    BattleCase.windup || BattleCase.release => MonsterSpecies.kraken,
    BattleCase.cooldowns => MonsterSpecies.crustacean,
    BattleCase.longRange => MonsterSpecies.serpent,
    BattleCase.storm => MonsterSpecies.shark,
    BattleCase.wake => MonsterSpecies.jellyfish,
    _ => MonsterSpecies.squid,
  };
  final monster =
      createMonster(
          species,
          level: 9,
          isApex: !species.isRegionTitan,
          rng: SeededGameRng(9),
        )
        ..currentIntent = MonsterIntent.fromId(
          state == BattleCase.windup
              ? MonsterIntentId.bossKrakenWindup
              : state == BattleCase.release
              ? MonsterIntentId.bossKrakenCatastrophe
              : switch (species) {
                  MonsterSpecies.crustacean =>
                    MonsterIntentId.crustaceanHydraulicGuillotine,
                  MonsterSpecies.serpent =>
                    MonsterIntentId.serpentVenomSpitRecoil,
                  MonsterSpecies.shark => MonsterIntentId.sharkFrenziedJaws,
                  MonsterSpecies.jellyfish =>
                    MonsterIntentId.jellyfishNematocystCurtain,
                  _ => MonsterIntentId.squidSweepingTentacles,
                },
        );
  c.session.currentMonster = monster;
  c.session.combatRange = state == BattleCase.longRange
      ? CombatRange.long
      : CombatRange.medium;
  if (state == BattleCase.storm || state == BattleCase.wake) {
    final storm = state == BattleCase.storm;
    ship.blessings[HardpointType.utility] = HardpointBlessing(
      power: storm ? OceanPower.tempestSovereign : OceanPower.magmaVentLord,
      slot: HardpointType.utility,
      tier: 3,
    );
    if (storm) {
      ship.stormRiggingTurns = 2;
      monster.staticStacks = 2;
      monster.isElectroJolted = true;
      monster.frenzyStacks = 3;
    } else {
      ship.boilingWakeTurns = 2;
      monster.burnTurns = 3;
    }
  }
  if (state == BattleCase.dense) {
    // Renderable current-effect saturation; not a balance/loadout simulation.
    ship
      ..isGrappled = true
      ..tempAccuracyPenalty = 20
      ..pitchCoatingActive = true
      ..basaltBarrierHp = 35
      ..basaltAegisTurns = 2;
    ship.addStatus(StatusEffect.poison);
    ship.addStatus(StatusEffect.burn);
    ship.addStatus(StatusEffect.stun);
    if (blueprint == BlueprintId.ironclad) {
      ship
        ..currentDmgReduction += 8
        ..isAnchoredThisTurn = true;
    }
    if (blueprint == BlueprintId.standard) {
      ship
        ..isBracedByDrill = true
        ..gunneryDrillBuffActive = true;
    }
    monster
      ..isObscured = true
      ..corrodedStacks = 3
      ..corrodedTurns = 3
      ..tremorAccPenalty = 20;
    monster.addStatus(StatusEffect.poison);
    monster.addStatus(StatusEffect.burn);
    monster.addStatus(StatusEffect.stun);
    if (blueprint == BlueprintId.bombardier) {
      monster
        ..spotterFlareTurns = 2
        ..spotterFlareAccuracyBonus = 21
        ..spotterFlareBlastBonus = .35;
    }
    if (blueprint == BlueprintId.corsair) {
      monster.isPinnedThisTurn = true;
      ship.activeTetherTrapDistance = 1;
    }
  }
  if (state == BattleCase.cooldowns) {
    for (final weapon in ship.equippedWeapons) {
      weapon.chargeCountdown = 2;
    }
    ship.utilityCooldown = 2;
  }
  if (state == BattleCase.combination || state == BattleCase.recovery) {
    c.session.activeQuirk = BloodlineTrait.impatient;
    c.session.isImpatientCombinationPending = state == BattleCase.combination;
    c.session.isImpatientRecovering = state == BattleCase.recovery;
  }
  if (state == BattleCase.beltSpent) {
    c.session.quickConsumablesUsedThisTurn =
        boon?.id == BloodlineTraitId.drillmaster ? 2 : 1;
  }
  c.session.syncCaptainTraits();
  return c;
}

String snapshot(GameController c) => jsonEncode({
  'ship': c.ship!.toJson(),
  'monster': {
    'hp': c.currentMonster!.currentHp,
    'intent': c.currentMonster!.currentIntent?.id.name,
    'corroded': c.currentMonster!.corrodedStacks,
    'flare': c.currentMonster!.spotterFlareTurns,
    'shaken': c.currentMonster!.tremorAccPenalty,
  },
  'shipEffects': c.ship!.statusEffects.map((s) => s.name).toList(),
  'monsterEffects': c.currentMonster!.statusEffects.map((s) => s.name).toList(),
  'profile': c.profile.toJson(),
  'chart': c.seaChart.toJson(),
  'quick': c.session.quickConsumablesUsedThisTurn,
  'range': c.combatRange.name,
  'pending': c.session.isImpatientCombinationPending,
  'recovery': c.session.isImpatientRecovering,
});

Future<void> review(
  WidgetTester tester,
  BlueprintId blueprint,
  BattleCase state,
  Size size, {
  BloodlineTrait? boon,
  BloodlineTrait? quirk,
  double scale = 1.15,
  bool capture = false,
  bool dialogs = false,
}) async {
  final c = fighter(blueprint, state, boon: boon, quirk: quirk);
  addTearDown(c.dispose);
  final before = snapshot(c);
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
    shell(
      c,
      ListenableBuilder(
        listenable: c,
        builder: (context, _) => BattleScreen(controller: c, game: game),
      ),
    ),
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
  expect(tester.takeException(), isNull);
  expect(find.byType(ShipCombatStats), findsOneWidget);
  expect(find.byType(MonsterCombatStats), findsOneWidget);
  final footer = find.byKey(const ValueKey('battle-dock-footer'));
  final footerRect = tester.getRect(footer);
  final hud = find.byKey(const ValueKey('combat-status-scroll'));
  final dock = find
      .ancestor(of: footer, matching: find.byType(Container))
      .first;
  expect(
    tester.getRect(hud).bottom,
    lessThanOrEqualTo(tester.getRect(dock).top),
    reason: 'HUD and command dock overlap.',
  );
  // Vitality is visible before the optional status details are scrolled.
  for (final gauge in find.byType(HullGauge).evaluate()) {
    expect(
      tester.getRect(find.byWidget(gauge.widget)).bottom,
      lessThanOrEqualTo(tester.getRect(hud).bottom),
    );
  }
  final sprites = game.children
      .whereType<PositionComponent>()
      .where((node) => node.anchor == Anchor.center && node.size.x > 0)
      .toList();
  expect(sprites, hasLength(2), reason: 'Both combatants must be mounted.');
  for (final sprite in sprites) {
    expect(sprite.isMounted, isTrue);
    final top = sprite.position.y - sprite.size.y / 2;
    final bottom = sprite.position.y + sprite.size.y / 2;
    // Flame coordinates start at the battle body, below the normal debug bar.
    final bodyTop = tester
        .getTopLeft(find.byKey(const ValueKey('combat-arena')))
        .dy;
    expect(top + bodyTop, greaterThanOrEqualTo(tester.getRect(hud).bottom));
    expect(bottom + bodyTop, lessThanOrEqualTo(tester.getRect(dock).top));
  }
  final sideLookout = find.byKey(const ValueKey('lookout-side'));
  if (sideLookout.evaluate().isNotEmpty && !InkTheme.disableGoogleFonts) {
    final viewport = tester.getRect(sideLookout);
    for (final text
        in find
            .descendant(of: sideLookout, matching: find.byType(Text))
            .evaluate()) {
      expect(
        tester.getRect(find.byWidget(text.widget)).bottom,
        lessThanOrEqualTo(viewport.bottom),
        reason: 'The brief desktop lookout must fit without scrolling.',
      );
    }
  }
  if (capture) {
    await captureChartFocusProof(
      tester,
      key,
      '${blueprint.name}-${state.name}-${size.width.toInt()}-$scale',
    );
  }
  final buttons = find.byType(InkButton).evaluate().toList();
  for (final element in buttons) {
    final target = find.byElementPredicate((e) => identical(e, element));
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    expect(
      target.hitTestable(),
      findsOneWidget,
      reason: (element.widget as InkButton).label,
    );
    final bounds = tester.getRect(target);
    expect(bounds.left, greaterThanOrEqualTo(0));
    expect(bounds.right, lessThanOrEqualTo(size.width));
    expect(bounds.top, greaterThanOrEqualTo(0));
    expect(bounds.bottom, lessThanOrEqualTo(size.height));
    if (!InkTheme.disableGoogleFonts) {
      for (final node
          in find
              .descendant(of: target, matching: find.byType(RichText))
              .evaluate()) {
        expect(
          (node.renderObject! as RenderParagraph).didExceedMaxLines,
          isFalse,
          reason:
              'Combat label clipped: ${(element.widget as InkButton).label}',
        );
      }
    }
  }
  for (final effect
      in find
          .descendant(of: hud, matching: find.byType(MechanicTooltip))
          .evaluate()
          .toList()) {
    final target = find.byElementPredicate((e) => identical(e, effect));
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    expect(
      target.hitTestable(),
      findsOneWidget,
      reason: 'Every active stat/effect must remain reachable.',
    );
  }
  for (final order in HelmOrder.values) {
    final target = find.byKey(ValueKey('helm-${order.name}'));
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    expect(target.hitTestable(), findsOneWidget);
  }
  expect(
    tester.getRect(footer),
    footerRect,
    reason: 'Belt must remain fixed while commands scroll.',
  );
  if (c.ship!.cargo.isNotEmpty) {
    await tester.ensureVisible(find.byKey(const ValueKey('belt-help')));
    await tester.pumpAndSettle();
  }
  expect(
    find.byKey(const ValueKey('belt-help')).hitTestable(),
    c.ship!.cargo.isEmpty ? findsNothing : findsOneWidget,
  );
  if (capture) {
    await tester.ensureVisible(find.byKey(const ValueKey('weapon-cards')));
    await tester.pumpAndSettle();
    await captureChartFocusProof(
      tester,
      key,
      '${blueprint.name}-${state.name}-${size.width.toInt()}-$scale-scrolled',
    );
  }
  if (dialogs) {
    for (final stat in [
      'ship-stat-evasion',
      if (blueprint != BlueprintId.bombardier) 'monster-stat-obscurity',
      if (blueprint == BlueprintId.bombardier) 'monster-stat-illuminated',
    ]) {
      final target = find.byKey(ValueKey(stat));
      await tester.ensureVisible(target);
      await tester.longPress(target);
      await tester.pumpAndSettle();
      final help = find.byKey(const ValueKey('mechanic-help-action'));
      expect(help, findsOneWidget);
      final bounds = tester.getRect(help);
      expect(bounds.left, greaterThanOrEqualTo(0));
      expect(bounds.right, lessThanOrEqualTo(size.width));
      expect(bounds.top, greaterThanOrEqualTo(0));
      expect(bounds.bottom, lessThanOrEqualTo(size.height));
      if (capture && stat != 'ship-stat-evasion') {
        await captureChartFocusProof(
          tester,
          key,
          '${blueprint.name}-status-help-${size.width.toInt()}-$scale',
        );
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(help, findsNothing);
    }
    for (final target in [
      find.byKey(const ValueKey('belt-help')),
      find.byTooltip('Inspect monster intent'),
      find.byTooltip('Combat Chronicle'),
    ]) {
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final dialog = find.byType(Dialog);
      expect(dialog, findsOneWidget);
      final bounds = tester.getRect(dialog);
      expect(bounds.left, greaterThanOrEqualTo(0));
      expect(bounds.right, lessThanOrEqualTo(size.width));
      expect(bounds.bottom, lessThanOrEqualTo(size.height));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(dialog, findsNothing);
    }
  }
  expect(
    snapshot(c),
    before,
    reason: 'Layout/scroll review must not resolve combat or consume supplies.',
  );
  expect(tester.takeException(), isNull);
  await tester.pumpWidget(const SizedBox.shrink());
}

void main() {
  setUpAll(() async {
    InkTheme.disableGoogleFonts = const String.fromEnvironment('artFontCache')
        .isEmpty;
    if (InkTheme.disableGoogleFonts) {
      // Ahem's square glyphs do not represent either player font mode. Use
      // Flutter's bundled fallback offline; cached game-font runs remain the
      // typography/ellipsis oracle for the illustrated UI.
      final config = File('.dart_tool/package_config.json').absolute;
      final packages =
          (jsonDecode(await config.readAsString()) as Map)['packages'] as List;
      final testPackage = packages.cast<Map>().singleWhere(
        (p) => p['name'] == 'flutter_test',
      );
      final sdk = Directory.fromUri(
        config.uri.resolve(testPackage['rootUri'] as String),
      ).parent.parent;
      final fonts = Directory('${sdk.path}/bin/cache/artifacts/material_fonts');
      final loader = FontLoader('Roboto');
      for (final face in ['regular', 'bold', 'italic', 'bolditalic']) {
        loader.addFont(
          File('${fonts.path}/roboto-$face.ttf')
              .readAsBytes()
              .then(ByteData.sublistView),
        );
      }
      await loader.load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    }
  });
  for (final ship in BlueprintId.values) {
    for (final boon in BloodlineTrait.allBoons) {
      for (final quirk in BloodlineTrait.allQuirks) {
        testWidgets('115% ${ship.name} ${boon.id.name}/${quirk.id.name}', (
          tester,
        ) async {
          await review(
            tester,
            ship,
            BattleCase.dense,
            const Size(1280, 900),
            boon: boon,
            quirk: quirk,
          );
        });
      }
    }
    for (final size in [
      const Size(360, 900),
      const Size(800, 600),
      const Size(1280, 900),
    ]) {
      testWidgets('115% ${ship.name} dense status at $size', (tester) async {
        await review(
          tester,
          ship,
          BattleCase.dense,
          size,
          boon: BloodlineTrait.quartermaster,
          quirk: BloodlineTrait.impatient,
          capture: true,
        );
      });
    }
    testWidgets('115% ${ship.name} ready at compact width', (tester) async {
      await review(tester, ship, BattleCase.ready, const Size(360, 900));
    });
    for (final state in BattleCase.values.where(
      (s) => s != BattleCase.dense && s != BattleCase.ready,
    )) {
      for (final size in [
        const Size(360, 900),
        const Size(800, 600),
        const Size(1672, 952),
      ]) {
        testWidgets('115% ${ship.name} ${state.name} at $size', (tester) async {
          await review(
            tester,
            ship,
            state,
            size,
            boon: BloodlineTrait.drillmaster,
            quirk: BloodlineTrait.skirmisher,
            capture:
                (size.width == 1672 &&
                    (state == BattleCase.windup ||
                        state == BattleCase.recovery)) ||
                (state == BattleCase.cooldowns && size.width == 360),
          );
        });
      }
    }
    for (final size in [
      const Size(360, 900),
      const Size(800, 600),
      const Size(1672, 952),
    ]) {
      testWidgets('130% ${ship.name} dense and dialogs at $size', (
        tester,
      ) async {
        await review(
          tester,
          ship,
          BattleCase.dense,
          size,
          boon: BloodlineTrait.quartermaster,
          quirk: BloodlineTrait.impatient,
          scale: 1.3,
          dialogs: true,
          capture: size.width == 1672,
        );
      });
    }
  }
}
