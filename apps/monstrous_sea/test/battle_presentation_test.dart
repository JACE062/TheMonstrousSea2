import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/battle/battle_presentation.dart';
import 'package:monstrous_sea/src/battle/monstrous_sea_battle_game.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/screens/battle_screen.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';
import 'package:monstrous_sea/src/widgets/hull_gauge.dart';

class _HitRng extends SeededGameRng {
  _HitRng() : super(42);
  @override
  int d100() => 1;
}

class _NoDodgeRng extends SeededGameRng {
  _NoDodgeRng() : super(42);
  @override
  int d100() => 50;
}

class _StunRng extends SeededGameRng {
  _StunRng() : super(42);
  bool forceStun = false;
  @override
  int nextInt(int max) => forceStun && max == 3 ? 2 : super.nextInt(max);
}

class _Steps {
  final pending = <Completer<void>>[];
  final durations = <Duration>[];
  Future<void> wait(Duration duration) {
    durations.add(duration);
    final step = Completer<void>();
    pending.add(step);
    return step.future;
  }

  void next() => pending.removeAt(0).complete();
}

GameController _controller({
  GameRng? rng,
  BlueprintId hull = BlueprintId.standard,
}) {
  final controller = GameController(
    session: GameSession(rng: rng ?? _HitRng()),
    autoSave: false,
  )..dispatch(const BeginFirstVoyage('Presentation'));
  if (hull != BlueprintId.standard) {
    controller.session.ship = createFlagshipFromBlueprint(hull, rng: _HitRng());
  }
  controller.session.currentMonster =
      createMonster(MonsterSpecies.serpent, level: 1, rng: _HitRng())
        ..name = controller
            .ship!
            .name // Explicit identity must survive equal names.
        ..maxHp = 1000
        ..currentHp = 1000
        ..evasion = 0
        ..currentIntent = MonsterIntent.fromId(MonsterIntentId.normalStrike);
  return controller;
}

const _fontPath = String.fromEnvironment('reviewFontPath');
const _capture = bool.fromEnvironment('captureCombatPresentation');

Future<void> _mount(
  WidgetTester tester,
  GameController controller,
  MonstrousSeaBattleGame game, {
  double scale = 1.15,
  bool reduced = false,
  GlobalKey? captureKey,
}) async {
  await tester.runAsync(() async {
    game.onGameResize(Vector2(1280, 900));
    // Start codec callbacks outside the fake widget clock.
    // ignore: invalid_use_of_internal_member
    await game.load();
  });
  game.feedbackFontFamily = _fontPath.isEmpty
      ? null
      : 'CombatPresentationReview';
  await tester.pumpWidget(
    MaterialApp(
      theme: InkTheme.themeData.copyWith(
        textTheme: InkTheme.themeData.textTheme.apply(
          fontFamily: _fontPath.isEmpty ? null : 'CombatPresentationReview',
        ),
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: reduced,
        ),
        child: child!,
      ),
      home: RepaintBoundary(
        key: captureKey,
        child: BattleScreen(controller: controller, game: game),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _captureFrame(
  WidgetTester tester,
  GlobalKey key,
  String name,
) async {
  if (!_capture) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/combat-presentation-$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    InkTheme.disableGoogleFonts = true;
    if (_fontPath.isNotEmpty) {
      for (final family in ['CombatPresentationReview', 'Arial']) {
        final loader = FontLoader(family)
          ..addFont(File(_fontPath).readAsBytes().then(ByteData.sublistView));
        await loader.load();
      }
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    }
  });

  for (final width in [1280.0, 600.0, 360.0]) {
    testWidgets('health statuses share a padded wrapping row at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = _controller();
      controller.ship!
        ..basaltBarrierHp = 10
        ..addStatus(StatusEffect.poison);
      controller.currentMonster!
        ..staticStacks = 2
        ..addStatus(StatusEffect.poison);
      final game = MonstrousSeaBattleGame(
        ship: controller.ship!,
        monster: controller.currentMonster!,
      );
      final key = GlobalKey();
      await _mount(tester, controller, game, scale: 1.3, captureKey: key);
      final gauges = find.byType(HullGauge);
      final poison = find.text('Poison');
      for (var side = 0; side < 2; side++) {
        final power = find.text(
          side == 0 ? 'Basalt Barrier: 10 HP' : 'Static Charge (2/3)',
        );
        final powerRect = tester.getRect(power);
        final poisonRect = tester.getRect(poison.at(side));
        final gaugeRect = tester.getRect(gauges.at(side));
        expect(powerRect.top - gaugeRect.bottom, greaterThanOrEqualTo(8));
        expect(poisonRect.left, greaterThanOrEqualTo(gaugeRect.left));
        expect(poisonRect.right, lessThanOrEqualTo(gaugeRect.right));
        if (width == 1280) {
          expect(poisonRect.top, powerRect.top);
          expect(poisonRect.left, greaterThan(powerRect.right));
        }
      }
      await _captureFrame(tester, key, 'status-row-${width.toInt()}');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    });
  }

  for (final shell in [10, 100]) {
    testWidgets('shell damage stays numeric with $shell starting plates', (
      tester,
    ) async {
      final controller = _controller(hull: BlueprintId.bombardier);
      controller.session.currentMonster =
          createMonster(MonsterSpecies.crustacean, level: 1, rng: _HitRng())
            ..maxHp = 1000
            ..currentHp = 1000
            ..maxCarapace = shell
            ..carapacePlating = shell;
      final steps = _Steps();
      final game = MonstrousSeaBattleGame(
        ship: controller.ship!,
        monster: controller.currentMonster!,
        playbackDelay: steps.wait,
      );
      final key = GlobalKey();
      await _mount(tester, controller, game, captureKey: key);
      controller.setIsPlayingEvents(true);
      final weapon = controller.ship!.equippedWeapons.firstWhere(
        (weapon) => weapon.weaponType == ShipWeaponType.heavyMortar,
      )..damage = 20;
      final (_, events) = calculateAttack(
        controller.ship!,
        weapon,
        controller.currentMonster!,
        _NoDodgeRng(),
        const [CarapaceTrait()],
      );
      final shellHit = events.whereType<CarapaceDamaged>().single;
      final fleshHit = events.whereType<AttackHit>().single;
      final playback = game.playEvents(events, () {});
      await tester.pump();
      expect(game.monster.carapacePlating, shell);
      steps.next();
      await tester.pump();
      expect(game.monster.carapacePlating, shellHit.remainingCarapace);
      expect(game.monster.currentHp, 1000);
      final shellLabel =
          'SHELL −${shellHit.damageDealt}${shellHit.wasShattered ? ' · BROKEN' : ''}';
      expect(game.presentation.announcement, contains(shellLabel));
      expect(
        game.children.whereType<BattleFeedback>().any(
          (cue) => cue.text == shellLabel,
        ),
        isTrue,
      );
      await _captureFrame(
        tester,
        key,
        'shell-${shellHit.wasShattered ? 'broken' : 'damaged'}',
      );
      steps.next();
      await tester.pump();
      expect(game.monster.currentHp, fleshHit.remainingHp);
      if (fleshHit.damage > 0) {
        expect(
          game.children.whereType<BattleFeedback>().any(
            (cue) => cue.text == '-${fleshHit.damage}',
          ),
          isTrue,
        );
        await _captureFrame(tester, key, 'shell-overflow-flesh');
      } else {
        expect(
          game.children.whereType<BattleFeedback>().any(
            (cue) => cue.text == '-0',
          ),
          isFalse,
        );
      }
      for (var index = 0; index < 30 && steps.pending.isNotEmpty; index++) {
        steps.next();
        await tester.pump();
      }
      await playback;
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    });
  }

  testWidgets(
    'Long helm then Ram impacts in 900 ms with overlapping movement labels',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = _controller(
        rng: _NoDodgeRng(),
        hull: BlueprintId.ironclad,
      );
      controller.session.combatRange = CombatRange.long;
      final weapon = controller.ship!.equippedWeapons.singleWhere(
        (weapon) => weapon.weaponType == ShipWeaponType.prowRam,
      )..damage = 20;
      final game = MonstrousSeaBattleGame(
        ship: controller.ship!,
        monster: controller.currentMonster!,
        initialRange: CombatRange.long,
      );
      final key = GlobalKey();
      await _mount(tester, controller, game, scale: 1.3, captureKey: key);
      await tester.tap(
        find.byTooltip(
          'Order helm to advance to ${CombatRange.medium.displayName}',
        ),
      );
      await tester.pump();
      await tester.tap(find.text(weapon.name));
      await tester.pump();
      expect(game.presentation.range, CombatRange.medium);
      await tester.pump(const Duration(milliseconds: 399));
      expect(game.presentation.range, CombatRange.medium);
      await tester.pump(const Duration(milliseconds: 1));
      expect(game.presentation.range, CombatRange.short);
      expect(game.monster.currentHp, 1000);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 99));
      expect(game.monster.currentHp, 1000);
      await tester.pump(const Duration(milliseconds: 1));
      expect(game.monster.currentHp, 975);
      final names = game.children
          .whereType<BattleFeedback>()
          .map((cue) => cue.text)
          .toList();
      expect(
        names,
        containsAll([
          'SHIP CLOSES · MEDIUM RANGE',
          'SHIP CLOSES · SHORT RANGE',
          weapon.name,
          '-25',
        ]),
      );
      await _captureFrame(tester, key, 'ram-feedback-stack');
      for (var frame = 0; frame < 100 && controller.isPlayingEvents; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(controller.isPlayingEvents, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    },
  );

  for (final reduced in [false, true]) {
    testWidgets(
      'feedback stack caps, expires and reflows independently (reduced=$reduced)',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = _controller();
        final steps = _Steps();
        final game = MonstrousSeaBattleGame(
          ship: controller.ship!,
          monster: controller.currentMonster!,
          playbackDelay: steps.wait,
        );
        final key = GlobalKey();
        await _mount(
          tester,
          controller,
          game,
          scale: 1.3,
          reduced: reduced,
          captureKey: key,
        );
        controller.setIsPlayingEvents(true);
        var complete = false;
        final playback = game.playEvents([
          for (var index = 1; index <= 4; index++)
            AttackHit(
              target: CombatSide.monster,
              targetName: 'monster',
              damage: index,
              damageType: 'Piercing',
              remainingHp: 1000 - index,
            ),
          const DamageReduced(shipName: 'ship', nullifiedAmount: 2),
          const CarapaceDamaged(
            monsterName: 'monster',
            damageDealt: 1,
            remainingCarapace: 0,
            wasShattered: true,
          ),
        ], () => complete = true);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        for (var index = 0; index < 3; index++) {
          steps.next();
          await tester.pump(const Duration(milliseconds: 100));
        }
        var cues = game.children.whereType<BattleFeedback>().toList();
        expect(cues.map((cue) => cue.text), containsAll(['-2', '-3', '-4']));
        expect(cues.map((cue) => cue.text), isNot(contains('-1')));
        expect(cues.length, 3);
        for (var index = 0; index < 2; index++) {
          expect(
            cues[index].bounds.bottom,
            lessThan(cues[index + 1].bounds.top),
          );
        }
        for (var index = 0; index < 15 && !complete; index++) {
          if (steps.pending.isNotEmpty) steps.next();
          await tester.pump();
        }
        expect(complete, isTrue);
        await playback;
        cues = game.children.whereType<BattleFeedback>().toList();
        expect(cues.length, 4, reason: 'Each combatant has its own stack');
        expect(cues.map((cue) => cue.text), isNot(contains('-2')));
        await _captureFrame(tester, key, 'feedback-stack-desktop-$reduced');
        tester.view.physicalSize = const Size(600, 1100);
        await tester.pump();
        await tester.pump();
        final survivors = game.children.whereType<BattleFeedback>().toList();
        for (final cue in survivors) {
          expect(cue.bounds.left, greaterThanOrEqualTo(0));
          expect(cue.bounds.right, lessThanOrEqualTo(600));
        }
        for (var first = 0; first < survivors.length; first++) {
          for (var second = first + 1; second < survivors.length; second++) {
            expect(
              survivors[first].bounds.overlaps(survivors[second].bounds),
              isFalse,
            );
          }
        }
        expect(survivors.map((cue) => cue.text), isNot(contains('-1')));
        expect(survivors.map((cue) => cue.text), isNot(contains('-2')));
        await _captureFrame(tester, key, 'feedback-stack-compact-$reduced');
        await tester.pump(const Duration(milliseconds: 1600));
        await tester.pump();
        expect(
          game.children.whereType<BattleFeedback>().map((cue) => cue.text),
          isNot(contains('-3')),
        );
        expect(
          game.children.whereType<BattleFeedback>().any(
            (cue) => cue.text.contains('SHELL'),
          ),
          isTrue,
        );
        await tester.pump(const Duration(seconds: 5));
        await tester.pump();
        expect(game.children.whereType<BattleFeedback>(), isEmpty);
        tester.view.physicalSize = const Size(1280, 1100);
        await tester.pump();
        expect(game.children.whereType<BattleFeedback>(), isEmpty);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        controller.dispose();
      },
    );
  }

  testWidgets(
    'quick actions retain labels and same-frame overflow never resurrects evicted cues',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = _controller();
      final game = MonstrousSeaBattleGame(
        ship: controller.ship!,
        monster: controller.currentMonster!,
        playbackDelay: (_) async {},
      );
      await _mount(tester, controller, game, reduced: true);
      controller.currentMonster!.addStatus(StatusEffect.poison);
      await game.playEvents([
        CombatEffectsChanged.capture(controller.currentMonster!),
      ], () {});
      await game.playEvents([
        const AttackHit(
          target: CombatSide.monster,
          targetName: 'monster',
          damage: 1,
          damageType: 'Piercing',
          remainingHp: 999,
        ),
      ], () {});
      await tester.pump();
      expect(
        game.children.whereType<BattleFeedback>().map((cue) => cue.text),
        containsAll(['Poison', '-1']),
      );
      await game.playEvents([
        for (var index = 2; index <= 7; index++)
          AttackHit(
            target: CombatSide.monster,
            targetName: 'monster',
            damage: index,
            damageType: 'Piercing',
            remainingHp: 1000 - index,
          ),
      ], () {});
      await tester.pump();
      await tester.pump();
      expect(game.children.whereType<BattleFeedback>().map((cue) => cue.text), [
        '-5',
        '-6',
        '-7',
      ]);
      game.feedbackTextScale = 1.5;
      tester.view.physicalSize = const Size(600, 1100);
      await tester.pump();
      expect(game.children.whereType<BattleFeedback>().map((cue) => cue.text), [
        '-5',
        '-6',
        '-7',
      ]);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    },
  );

  testWidgets(
    'weapon impact follows its name within 100 ms while the name remains visible',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = _controller(rng: _NoDodgeRng());
      final weapon = controller.ship!.equippedWeapons.firstWhere(
        (weapon) => weapon.weaponType == ShipWeaponType.cannon,
      )..damage = 20;
      final game = MonstrousSeaBattleGame(
        ship: controller.ship!,
        monster: controller.currentMonster!,
      );
      await _mount(tester, controller, game);
      await tester.tap(find.text('Naval Cannon Battery'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 99));
      expect(game.monster.currentHp, 1000);
      await tester.pump(const Duration(milliseconds: 1));
      expect(game.monster.currentHp, 980);
      expect(
        game.children.whereType<BattleFeedback>().any(
          (cue) => cue.text == weapon.name && cue.opacity == 1,
        ),
        isTrue,
      );
      for (var frame = 0; frame < 100 && controller.isPlayingEvents; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(controller.isPlayingEvents, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    },
  );

  testWidgets(
    'Stun tincture displays Stun without Pinned or a dodge reduction',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final rng = _StunRng();
      final controller = _controller(rng: rng);
      controller.currentMonster!.evasion = 30;
      final item = generateConsumable(
        ConsumableType.unstableTincture,
        RarityLevel.common,
      );
      controller.ship!.cargo.add(item);
      final steps = _Steps();
      final game = MonstrousSeaBattleGame(
        ship: controller.ship!,
        monster: controller.currentMonster!,
        playbackDelay: steps.wait,
      );
      await _mount(tester, controller, game);
      rng.forceStun = true;
      await tester.tap(find.text(item.name));
      await tester.pump();
      expect(find.text('Stun'), findsOneWidget);
      expect(find.textContaining('Pinned'), findsNothing);
      expect(game.monster.hasStatus(StatusEffect.stun), isTrue);
      expect(game.monster.isPinnedThisTurn, isFalse);
      expect(game.monster.effectiveEvasion, 30);
      expect(game.presentation.announcement, contains('Stun'));
      expect(game.presentation.announcement, isNot(contains('Pinned')));
      for (var step = 0; step < 100 && controller.isPlayingEvents; step++) {
        if (steps.pending.isNotEmpty) steps.next();
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(controller.isPlayingEvents, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    },
  );

  test('range feedback distinguishes movers from pull instigators', () {
    for (final movement in [
      (
        mover: CombatSide.monster,
        instigator: CombatSide.monster,
        text: 'BEAST RETREATS',
      ),
      (
        mover: CombatSide.ship,
        instigator: CombatSide.ship,
        text: 'SHIP RETREATS',
      ),
      (
        mover: CombatSide.ship,
        instigator: CombatSide.monster,
        text: 'BEAST PULLS SHIP',
      ),
      (
        mover: CombatSide.monster,
        instigator: CombatSide.ship,
        text: 'SHIP PULLS BEAST',
      ),
    ]) {
      final pulled = movement.mover != movement.instigator;
      final cue = BattlePresentation.rangeCue(
        CombatRangeChanged(
          previousRange: pulled ? CombatRange.long : CombatRange.short,
          newRange: CombatRange.medium,
          reason: 'Not parsed as presentation instructions',
          mover: movement.mover,
          instigator: movement.instigator,
        ),
      );
      expect(cue.anchor, movement.mover);
      expect(cue.text, '${movement.text} · MEDIUM RANGE');
    }
    final unknown = BattlePresentation.rangeCue(
      const CombatRangeChanged(
        previousRange: CombatRange.short,
        newRange: CombatRange.medium,
        reason: 'legacy event',
      ),
    );
    expect(unknown.anchor, isNull);
    expect(unknown.text, 'MEDIUM RANGE');
  });

  for (final (hull, weapon, expected) in [
    (
      BlueprintId.ironclad,
      ShipWeaponType.prowRam,
      [(CombatRange.short, 1000), (CombatRange.short, 975)],
    ),
    (
      BlueprintId.corsair,
      ShipWeaponType.harpoonWinch,
      [(CombatRange.medium, 980), (CombatRange.short, 980)],
    ),
  ]) {
    testWidgets('$weapon displays movement and impact in causal order', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = _controller(rng: _NoDodgeRng(), hull: hull);
      controller.ship!.equippedWeapons
              .singleWhere((candidate) => candidate.weaponType == weapon)
              .damage =
          20;
      final steps = _Steps();
      final game = MonstrousSeaBattleGame(
        ship: controller.ship!,
        monster: controller.currentMonster!,
        playbackDelay: steps.wait,
      );
      await _mount(tester, controller, game);
      final shown = <(CombatRange, int)>[];
      game.presentation.addListener(() {
        final state = (game.presentation.range, game.monster.currentHp);
        if (state != (CombatRange.medium, 1000) &&
            (shown.isEmpty || shown.last != state)) {
          shown.add(state);
        }
      });
      await tester.tap(find.text(weapon.displayName));
      await tester.pump();
      for (var step = 0; step < 100 && controller.isPlayingEvents; step++) {
        if (steps.pending.isNotEmpty) steps.next();
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(controller.isPlayingEvents, isFalse);
      expect(shown, expected);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    });
  }

  testWidgets('Kraken retreat is attributed to the beast at Medium range', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = _controller();
    controller.session.currentMonster = createMonster(
      MonsterSpecies.kraken,
      level: 5,
      rng: _HitRng(),
    );
    controller.session.combatRange = CombatRange.short;
    controller.clearLog();
    final steps = _Steps();
    final game = MonstrousSeaBattleGame(
      ship: controller.ship!,
      monster: controller.currentMonster!,
      initialRange: CombatRange.short,
      playbackDelay: steps.wait,
    );
    final key = GlobalKey();
    await _mount(tester, controller, game, captureKey: key);
    await tester.tap(find.byTooltip('Chronicle Log'));
    await tester.pump();
    controller.setIsPlayingEvents(true);
    final playback = game.playEvents([
      const CombatRangeChanged(
        previousRange: CombatRange.short,
        newRange: CombatRange.medium,
        reason: 'Retreat',
        mover: CombatSide.monster,
        instigator: CombatSide.monster,
      ),
    ], () {});
    await tester.pump(const Duration(milliseconds: 100));
    expect(game.presentation.range, CombatRange.medium);
    expect(
      game.presentation.announcement,
      '${game.monster.name}: BEAST RETREATS · MEDIUM RANGE',
    );
    await _captureFrame(tester, key, 'kraken-retreat');
    steps.next();
    await tester.pump();
    await playback;
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  test(
    'effect snapshots cannot advance HP, shell or limbs; identity is explicit',
    () {
      final controller = _controller();
      final ship = controller.ship!;
      final monster = controller.currentMonster!..carapacePlating = 20;
      final view = BattlePresentation(ship, monster, CombatRange.medium);
      monster
        ..currentHp = 2
        ..carapacePlating = 0
        ..numberOfTentacles = 3
        ..addStatus(StatusEffect.poison);
      view.apply(CombatEffectsChanged.capture(monster));
      expect(view.monster.currentHp, 1000);
      expect(view.monster.carapacePlating, 20);
      expect(view.monster.numberOfTentacles, 0);
      expect(view.monster.hasStatus(StatusEffect.poison), isTrue);
      view.apply(
        AttackHit(
          target: CombatSide.ship,
          targetName: monster.name,
          damage: 9,
          damageType: 'Piercing',
          remainingHp: ship.currentHp - 9,
        ),
      );
      expect(view.ship.currentHp, ship.currentHp - 9);
      expect(view.monster.currentHp, 1000);
      expect(identical(view.ship, ship), isFalse);
      expect(identical(view.monster, monster), isFalse);
      view.dispose();
      controller.dispose();
    },
  );

  for (final reduced in [false, true]) {
    testWidgets(
      'HUD stays at each impact through rebuilds (reduced=$reduced)',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = _controller();
        final steps = _Steps();
        final game = MonstrousSeaBattleGame(
          ship: controller.ship!,
          monster: controller.currentMonster!,
          playbackDelay: steps.wait,
        );
        await _mount(tester, controller, game, reduced: reduced);
        final initialShipHp = controller.ship!.currentHp;
        await tester.tap(find.text('Naval Cannon Battery'));
        await tester.pump();
        expect(controller.currentMonster!.currentHp, lessThan(1000));
        expect(controller.isPlayingEvents, isTrue);
        expect(
          game.presentation.monster.currentHp,
          1000,
          reason: 'attempt precedes impact',
        );
        tester.view.physicalSize = const Size(1000, 850);
        await tester.pump();
        await tester.runAsync(game.retryArtwork);
        await tester.pump();
        expect(game.presentation.monster.currentHp, 1000);
        expect(
          tester.widgetList<HullGauge>(find.byType(HullGauge)).last.currentHp,
          1000,
        );
        steps.next();
        await tester.pump();
        expect(
          game.presentation.monster.currentHp,
          controller.currentMonster!.currentHp,
        );
        expect(
          game.presentation.ship.currentHp,
          initialShipHp,
          reason: 'response is still pending',
        );
        for (
          var index = 0;
          index < 100 && controller.isPlayingEvents;
          index++
        ) {
          if (steps.pending.isNotEmpty) steps.next();
          await tester.pump(const Duration(milliseconds: 20));
        }
        expect(controller.isPlayingEvents, isFalse);
        expect(game.presentation.ship.currentHp, controller.ship!.currentHp);
        expect(game.presentation.range, controller.combatRange);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        controller.dispose();
      },
    );
  }

  testWidgets('twelve-hit sweep preserves each impact with bounded playback', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = _controller(rng: _NoDodgeRng());
    controller.ship!
      ..maxHp = 1000
      ..currentHp = 1000
      ..currentEvasion = 0
      ..currentDmgReduction = 1
      ..basaltBarrierHp = 10
      ..basaltAegisTurns = 2;
    controller.ship!.blessings[HardpointType.utility] = const HardpointBlessing(
      power: OceanPower.earthshakerTitan,
      slot: HardpointType.utility,
      tier: 1,
    );
    controller.session.currentMonster =
        createMonster(MonsterSpecies.kraken, level: 5, rng: _HitRng())
          ..currentIntent = MonsterIntent.fromId(
            MonsterIntentId.squidSweepingTentacles,
          );
    final steps = _Steps();
    final strikePauses = <Duration>[];
    final laterStrikePauses = <Duration>[];
    var currentStrike = 0;
    late final MonstrousSeaBattleGame game;
    game = MonstrousSeaBattleGame(
      ship: controller.ship!,
      monster: controller.currentMonster!,
      playbackDelay: (duration) {
        if (game.presentation.announcement.endsWith('/12')) {
          strikePauses.add(duration);
          currentStrike = int.parse(
            RegExp(r'(\d+)/12$')
                .firstMatch(game.presentation.announcement)!
                .group(1)!,
          );
        }
        if (currentStrike >= 2) laterStrikePauses.add(duration);
        return steps.wait(duration);
      },
    );
    final key = GlobalKey();
    await _mount(tester, controller, game, reduced: true, captureKey: key);
    final displayedHp = <int>[1000];
    game.presentation.addListener(() {
      if (displayedHp.last != game.ship.currentHp) {
        displayedHp.add(game.ship.currentHp);
      }
    });
    await tester.tap(find.text('Naval Cannon Battery'));
    await tester.pump();
    final expectedHp = <int>[1000];
    for (final hit in controller.lastEvents.whereType<AttackHit>().where(
      (hit) => hit.target == CombatSide.ship,
    )) {
      if (expectedHp.last != hit.remainingHp) expectedHp.add(hit.remainingHp);
    }
    expect(
      controller.lastEvents
          .whereType<AttackAttempted>()
          .where((event) => event.attacker == CombatSide.monster)
          .length,
      12,
    );
    for (var index = 0; index < 300 && controller.isPlayingEvents; index++) {
      if (steps.pending.isNotEmpty) steps.next();
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(controller.isPlayingEvents, isFalse);
    expect(displayedHp, expectedHp);
    expect(expectedHp.length, greaterThan(5));
    expect(
      strikePauses.first,
      greaterThanOrEqualTo(const Duration(milliseconds: 1400)),
    );
    expect(
      strikePauses
          .skip(1)
          .where((pause) => pause == const Duration(milliseconds: 90))
          .length,
      11,
      reason:
          'Keep the approved fast cadence after the opening tentacle strike',
    );
    expect(laterStrikePauses, isNotEmpty);
    expect(
      laterStrikePauses.every(
        (pause) => pause <= const Duration(milliseconds: 200),
      ),
      isTrue,
      reason: 'A new barrier/hull/status outcome must not slow a later tentacle back down',
    );
    expect(game.ship.basaltBarrierHp, controller.ship!.basaltBarrierHp);
    expect(
      steps.durations.fold<int>(
        0,
        (sum, duration) => sum + duration.inMilliseconds,
      ),
      // Only the opening strike gets reading pauses; later outcomes stay fast
      // even when their defense/reactive meaning first appears mid-sweep.
      lessThan(16000),
    );
    final cues = game.children.whereType<BattleFeedback>().toList();
    expect(cues.length, lessThanOrEqualTo(6));
    for (var first = 0; first < cues.length; first++) {
      for (var second = first + 1; second < cues.length; second++) {
        expect(cues[first].bounds.overlaps(cues[second].bounds), isFalse);
      }
    }
    await _captureFrame(tester, key, 'kraken-feedback-stack');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets(
    'ordinary labels remain readable while playback completes before their fade',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = _controller();
      final game = MonstrousSeaBattleGame(
        ship: controller.ship!,
        monster: controller.currentMonster!,
      );
      final key = GlobalKey();
      await _mount(tester, controller, game, captureKey: key);
      controller.setIsPlayingEvents(true);
      controller.currentMonster!
        ..addStatus(StatusEffect.poison)
        ..addStatus(StatusEffect.stun);
      final effects = CombatEffectsChanged.capture(controller.currentMonster!);
      var complete = false;
      final playback = game.playEvents([
        effects,
        const AttackHit(
          target: CombatSide.monster,
          targetName: 'monster',
          damage: 4,
          damageType: 'Piercing',
          remainingHp: 996,
        ),
      ], () => complete = true);
      await tester.pump();
      for (var frame = 0; frame < 10; frame++) {
        await tester.pump(const Duration(milliseconds: 40));
      }
      final label = game.children.whereType<BattleFeedback>().singleWhere(
        (cue) => cue.text == 'Poison · Stun',
      );
      expect(label.opacity, 1);
      await _captureFrame(tester, key, 'normal-label-solid');
      for (var frame = 0; frame < 12; frame++) {
        await tester.pump(const Duration(milliseconds: 40));
      }
      expect(
        label.opacity,
        1,
        reason: 'The longer solid interval survives arrival of the next cue',
      );
      await _captureFrame(tester, key, 'normal-label-solid-880ms');
      for (var frame = 0; frame < 8; frame++) {
        await tester.pump(const Duration(milliseconds: 40));
      }
      expect(label.opacity, greaterThan(0));
      expect(label.opacity, lessThan(1));
      expect(
        game.monster.currentHp,
        996,
        reason: 'Impact must not wait for the previous label to fade',
      );
      expect(complete, isTrue);
      expect(game.children.whereType<BattleFeedback>(), contains(label));
      await _captureFrame(tester, key, 'normal-label-fading');
      await tester.pump(const Duration(milliseconds: 700));
      expect(game.monster.currentHp, 996);
      await tester.pump(const Duration(milliseconds: 900));
      await playback;
      expect(complete, isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    },
  );

  for (final width in [1280.0, 600.0]) {
    testWidgets(
      'barrier then hull then status has readable state at $width / 130%',
      (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = _controller();
        controller.currentMonster!.name = 'Serpent';
        controller.clearLog();
        controller.ship!
          ..maxHp = 100
          ..currentHp = 100
          ..basaltBarrierHp = 10
          ..basaltAegisTurns = 2;
        final steps = _Steps();
        final game = MonstrousSeaBattleGame(
          ship: controller.ship!,
          monster: controller.currentMonster!,
          playbackDelay: steps.wait,
        );
        final key = GlobalKey();
        await _mount(tester, controller, game, scale: 1.3, captureKey: key);
        await tester.tap(find.byTooltip('Chronicle Log'));
        await tester.pump();
        controller.setIsPlayingEvents(true);
        controller.ship!
          ..currentHp = 96
          ..basaltBarrierHp = 0;
        final applied = controller.currentMonster!
          ..addStatus(StatusEffect.poison);
        final effects = CombatEffectsChanged.capture(applied);
        applied
          ..currentHp = 997
          ..removeStatus(StatusEffect.poison);
        final expired = CombatEffectsChanged.capture(applied);
        var complete = false;
        final playback = game.playEvents([
          const AttackAttempted(
            attacker: CombatSide.monster,
            attackerName: 'Serpent',
            weaponName: 'Strike',
            roll: 1,
            targetAc: 95,
          ),
          const DamageReduced(
            shipName: 'ship',
            nullifiedAmount: 10,
            defense: DefenseKind.barrier,
            remainingBarrierHp: 0,
          ),
          const AttackHit(
            target: CombatSide.ship,
            targetName: 'ship',
            damage: 4,
            damageType: 'Piercing',
            remainingHp: 96,
          ),
          effects,
          const StatusEffectTicked(
            target: CombatSide.monster,
            targetName: 'Serpent',
            effectName: 'Poison',
            damage: 3,
            remainingHp: 997,
            woreOff: true,
          ),
          expired,
        ], () => complete = true);
        await tester.pump(const Duration(milliseconds: 16));
        expect(game.presentation.ship.currentHp, 100);
        expect(game.presentation.ship.basaltBarrierHp, 10);
        steps.next();
        await tester.pump(const Duration(milliseconds: 16));
        expect(game.presentation.ship.basaltBarrierHp, 0);
        expect(game.presentation.ship.currentHp, 100);
        expect(
          game.presentation.monster.hasStatus(StatusEffect.poison),
          isFalse,
        );
        await _captureFrame(tester, key, 'barrier-${width.toInt()}');
        steps.next();
        await tester.pump(const Duration(milliseconds: 140));
        expect(game.presentation.ship.currentHp, 96);
        expect(
          tester.widgetList<HullGauge>(find.byType(HullGauge)).first.currentHp,
          96,
        );
        expect(
          game.presentation.monster.hasStatus(StatusEffect.poison),
          isFalse,
        );
        await tester.pump(const Duration(milliseconds: 140));
        await _captureFrame(tester, key, 'hull-${width.toInt()}');
        steps.next();
        await tester.pump(const Duration(milliseconds: 16));
        expect(find.text('Poison'), findsOneWidget);
        await _captureFrame(tester, key, 'status-${width.toInt()}');
        steps.next();
        await tester.pump();
        expect(game.monster.currentHp, 997);
        expect(find.text('Poison'), findsNothing);
        expect(game.presentation.announcement, contains('CLEARED'));
        steps.next();
        await tester.pump();
        await playback;
        expect(complete, isTrue);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        controller.dispose();
      },
    );
  }

  testWidgets('removing a scene cancels remaining impacts and completion', (
    tester,
  ) async {
    final controller = _controller();
    final steps = _Steps();
    final game = MonstrousSeaBattleGame(
      ship: controller.ship!,
      monster: controller.currentMonster!,
      playbackDelay: steps.wait,
    );
    await _mount(tester, controller, game);
    controller.setIsPlayingEvents(true);
    var completed = false;
    final playback = game.playEvents([
      const AttackHit(
        target: CombatSide.monster,
        targetName: 'monster',
        damage: 10,
        damageType: 'Piercing',
        remainingHp: 990,
      ),
      const AttackHit(
        target: CombatSide.monster,
        targetName: 'monster',
        damage: 10,
        damageType: 'Piercing',
        remainingHp: 980,
      ),
    ], () => completed = true);
    await tester.pump();
    expect(game.monster.currentHp, 990);
    await tester.pumpWidget(const SizedBox.shrink());
    steps.next();
    await tester.pump();
    await playback;
    expect(game.monster.currentHp, 990);
    expect(completed, isFalse);
    expect(tester.takeException(), isNull);
    controller.dispose();
  });
}
