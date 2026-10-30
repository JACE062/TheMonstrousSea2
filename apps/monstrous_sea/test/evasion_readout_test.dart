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

const _font = String.fromEnvironment('reviewFontPath');

GameController _battle({
  bool region2 = true,
  bool volatile = false,
  bool reckless = false,
  bool apexShark = false,
}) {
  final session = GameSession(
    rng: SeededGameRng(42),
    profile: ProfileData(
      activePacts: {if (volatile) CovenantPactId.volatileEnvirons},
    ),
  );
  final controller = GameController(session: session, autoSave: false)
    ..dispatch(const NameCaptain('Evasion review'));
  session.profile.unlockedBlueprints.add(BlueprintId.clipper.name);
  session.activeQuirk = reckless ? BloodlineTrait.recklessHelmsman : null;
  controller.dispatch(const ChooseShip(ShipClass.clipper));
  if (region2) session.seaChart.advanceRegion(session.rng);
  if (apexShark) {
    final chart = session.seaChart.toJson()
      ..['currentRow'] = 0
      ..['currentCol'] = 0
      ..['currentLeg'] = 0
      ..['courseOptions'] = [
        {
          'bearing': NavigationalBearing.deadAhead.name,
          'nodeType': EncounterNodeType.beastCombat.name,
          'difficultyLevel': 5,
          'lookoutCall': 'A beast ahead.',
          'monsterSpecies': MonsterSpecies.shark.name,
          'isIdentified': true,
          'isApex': true,
          'isNemesis': false,
        },
      ];
    session.seaChart.restoreFromJson(chart);
    session.phase = SessionPhase.helm;
    controller.dispatch(const SteerCourse(NavigationalBearing.deadAhead));
    expect(controller.phase, SessionPhase.battle);
    return controller;
  }
  session.seaChart
    ..currentLeg = session.seaChart.totalLegs - 1
    ..currentRow = SeaChart.bossRow
    ..currentCol = SeaChart.bossCol - 1;
  session.phase = SessionPhase.restArea;
  controller.dispatch(const TakeHelm());
  controller.dispatch(const SteerCourse(NavigationalBearing.deadAhead));
  expect(controller.phase, SessionPhase.battle);
  return controller;
}

Future<MonstrousSeaBattleGame> _mount(
  WidgetTester tester,
  GameController controller, {
  GlobalKey? captureKey,
}) async {
  final size = tester.view.physicalSize / tester.view.devicePixelRatio;
  final game = MonstrousSeaBattleGame(
    ship: controller.ship!,
    monster: controller.currentMonster!,
  );
  await tester.runAsync(() async {
    game.onGameResize(Vector2(size.width, size.height));
    // ignore: invalid_use_of_internal_member
    await game.load();
  });
  await tester.pumpWidget(
    RepaintBoundary(
      key: captureKey,
      child: MaterialApp(
        theme: InkTheme.themeData.copyWith(
          textTheme: InkTheme.themeData.textTheme.apply(
            fontFamily: _font.isEmpty ? null : 'EvasionReview',
          ),
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(1.3)),
          child: child!,
        ),
        home: ListenableBuilder(
          listenable: controller,
          builder: (context, _) =>
              BattleScreen(controller: controller, game: game),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
  game.pauseEngine();
  await tester.pumpAndSettle();
  return game;
}

String _stats(WidgetTester tester, String side) =>
    tester.widget<Text>(find.byKey(ValueKey('$side-combat-stats'))).data!;

void main() {
  setUpAll(() async {
    InkTheme.disableGoogleFonts = true;
    if (_font.isNotEmpty) {
      await (FontLoader(
        'EvasionReview',
      )..addFont(File(_font).readAsBytes().then(ByteData.sublistView))).load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    }
  });

  for (final width in [360.0, 1280.0]) {
    for (final volatile in [false, true]) {
      for (final reckless in [false, true]) {
        testWidgets(
          'actual Sargasso/Quirk dodge at $width / $volatile / $reckless',
          (tester) async {
            tester.view.physicalSize = Size(width, 1000);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final controller = _battle(volatile: volatile, reckless: reckless);
            final expected = (volatile ? 5 : 15) + (reckless ? 10 : 0);
            expect(controller.ship!.effectiveEvasion, expected);
            final key = GlobalKey();
            await _mount(tester, controller, captureKey: key);
            expect(_stats(tester, 'ship'), contains('Evade: $expected%'));
            expect(_stats(tester, 'monster'), contains('Dodge: 30%'));
            if (_font.isNotEmpty && volatile && reckless) {
              final boundary = tester.renderObject<RenderRepaintBoundary>(
                find.byKey(key),
              );
              await tester.runAsync(() async {
                final image = await boundary.toImage();
                final bytes = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                await File('build/evasion-hud-${width.toInt()}.png')
                    .writeAsBytes(bytes!.buffer.asUint8List());
                image.dispose();
              });
            }
            // Idle synchronization must refresh derived captain context too.
            controller.session.activeQuirk = reckless
                ? null
                : BloodlineTrait.recklessHelmsman;
            controller.notify();
            await tester.pump();
            expect(
              _stats(tester, 'ship'),
              contains('Evade: ${controller.ship!.effectiveEvasion}%'),
            );
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox.shrink());
            controller.dispose();
          },
        );
      }
    }
  }

  for (final width in [360.0, 1280.0]) {
    testWidgets('actual Sargasso Apex shark accuracy and dodge at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = _battle(apexShark: true);
      addTearDown(controller.dispose);
      final monster = controller.currentMonster!;
      expect(monster.isApex, isTrue);
      expect(monster.species, MonsterSpecies.shark);
      expect(monster.obscurityAccuracyPenalty, 10);
      final key = GlobalKey();
      await _mount(tester, controller, captureKey: key);
      expect(_stats(tester, 'ship'), contains('Evade: 15%'));
      expect(_stats(tester, 'monster'), contains('Dodge: 0%'));
      expect(
        _stats(tester, 'monster'),
        contains('Obscurity: -10% shot accuracy'),
      );
      expect(controller.combatLog.join(), contains('-10% ship evasion'));
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Tooltip &&
              (w.message?.contains(
                    'Opening shot accuracy: 85% before 0% target dodge.',
                  ) ??
                  false),
        ),
        findsOneWidget,
      );
      if (_font.isNotEmpty) {
        await tester.runAsync(() async {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(key),
          );
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('.dart_tool/sargasso-hud-${width.toInt()}.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      // Clearing removes the accuracy penalty without adding dodge.
      monster.isObscured = false;
      controller.notify();
      await tester.pump();
      expect(_stats(tester, 'monster'), contains('Dodge: 0%'));
      expect(_stats(tester, 'monster'), isNot(contains('Obscurity:')));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets(
    'HUD applies cap, Pin and real Flare zero rather than hiding it',
    (tester) async {
      final controller = _battle(reckless: true);
      controller.ship!.currentEvasion = 100;
      final monster = controller.currentMonster!;
      await _mount(tester, controller);
      expect(_stats(tester, 'ship'), contains('Evade: 95%'));
      monster.isPinnedThisTurn = true;
      controller.notify();
      await tester.pump();
      expect(_stats(tester, 'monster'), contains('Dodge: 15%'));
      monster
        ..evasion = 0
        ..spotterFlareTurns = 2;
      controller.notify();
      await tester.pump();
      expect(_stats(tester, 'monster'), contains('Dodge: 0%'));
      controller.ship!
        ..currentEvasion = 0
        ..captainQuirkId = null;
      controller.notify();
      await tester.pump();
      expect(_stats(tester, 'ship'), contains('Evade: 0%'));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    },
  );

  testWidgets(
    'captured dodge updates at effects and barrier depletion, not future live state',
    (tester) async {
      final controller = _battle(region2: false);
      final ship = controller.ship!;
      ship.blessings[HardpointType.utility] = const HardpointBlessing(
        slot: HardpointType.utility,
        power: OceanPower.earthshakerTitan,
        tier: 3,
      );
      final game = await _mount(tester, controller);
      expect(_stats(tester, 'ship'), contains('Evade: 25%'));
      ship
        ..captainQuirkId = BloodlineTraitId.recklessHelmsman
        ..basaltBarrierHp = 35
        ..basaltAegisTurns = 2;
      final activated = CombatEffectsChanged.capture(ship);
      ship
        ..captainQuirkId = null
        ..basaltBarrierHp = 0
        ..basaltAegisTurns = 0
        ..currentEvasion = 7;
      final expired = CombatEffectsChanged.capture(ship);
      controller.setIsPlayingEvents(true);
      await tester.pump();
      expect(_stats(tester, 'ship'), contains('Evade: 25%'));
      game.presentation.apply(activated);
      await tester.pump();
      expect(_stats(tester, 'ship'), contains('Evade: 55%'));
      expect(
        BattlePresentation.effectReadouts(game.presentation.ship)['Evasion'],
        'Evasion 55%',
      );
      game.presentation.apply(
        DamageReduced(
          shipName: ship.name,
          nullifiedAmount: 35,
          defense: DefenseKind.barrier,
          remainingBarrierHp: 0,
        ),
      );
      await tester.pump();
      expect(_stats(tester, 'ship'), contains('Evade: 35%'));
      game.presentation.apply(expired);
      await tester.pump();
      expect(_stats(tester, 'ship'), contains('Evade: 7%'));
      expect(tester.takeException(), isNull);
      controller.setIsPlayingEvents(false);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    },
  );
}
