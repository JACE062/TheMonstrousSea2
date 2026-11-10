import 'package:monstrous_sea/src/widgets/mechanic_text.dart';

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/battle/battle_presentation.dart';
import 'package:monstrous_sea/src/battle/monstrous_sea_battle_game.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/screens/battle_screen.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';

const _font = String.fromEnvironment('reviewFontPath');
const _gameFontCache = String.fromEnvironment('artFontCache');

class _StatsFontRoot extends PathProviderPlatform {
  _StatsFontRoot(this.path);
  final String path;
  @override
  Future<String?> getApplicationSupportPath() async => path;
}

GameController _battle({
  bool region2 = true,
  bool volatile = false,
  bool reckless = false,
  bool apexShark = false,
  ShipClass shipClass = ShipClass.clipper,
}) {
  final session = GameSession(
    rng: SeededGameRng(42),
    profile: ProfileData(
      activePacts: {if (volatile) CovenantPactId.volatileEnvirons},
    ),
  );
  final controller = GameController(session: session, autoSave: false)
    ..dispatch(const NameCaptain('Evasion review'));
  session.profile.unlockedBlueprints.add(shipClass.name);
  session.activeQuirk = reckless ? BloodlineTrait.recklessHelmsman : null;
  controller.dispatch(ChooseShip(shipClass));
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
    ..currentLeg = session.seaChart.regionTitanLeg - 1
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
  if (_gameFontCache.isNotEmpty) {
    final previous = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _StatsFontRoot(_gameFontCache);
    addTearDown(() => PathProviderPlatform.instance = previous);
    await tester.runAsync(() async {
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      InkTheme.themeData;
      await GoogleFonts.pendingFonts([
        InkTheme.titleLarge,
        InkTheme.titleMedium,
        InkTheme.subtitle,
        InkTheme.body,
        InkTheme.bodyBold,
        InkTheme.caption,
        InkTheme.statLabel,
        InkTheme.statValue,
      ]);
    });
  }
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

String _stats(WidgetTester tester, String side) => tester
    .widgetList<Text>(
      find.descendant(
        of: find.byKey(ValueKey('$side-combat-stats')),
        matching: find.byType(Text),
      ),
    )
    .map((text) => text.data!)
    .join(' ');

Finder helpText(String text) =>
    find.byWidgetPredicate((w) => w is MechanicText && w.text == text);

void main() {
  setUpAll(() async {
    InkTheme.disableGoogleFonts = _gameFontCache.isEmpty;
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
    testWidgets('status hover targets are independent at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = _battle(region2: false, shipClass: ShipClass.ironclad);
      addTearDown(controller.dispose);
      controller.ship!.currentDmgReduction = 6;
      controller.currentMonster!
        ..spotterFlareTurns = 1
        ..spotterFlareAccuracyBonus = 23
        ..spotterFlareBlastBonus = .4;
      final captureKey = GlobalKey();
      await _mount(tester, controller, captureKey: captureKey);
      final hp = controller.ship!.currentHp;
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      const flareHelp =
          'Suppresses Obscurity and dodge. Shots gain +23% accuracy; '
          'Blast damage taken increases by 40%.';
      const armorHelp =
          'Reduces each incoming hit by 6 damage. '
          'Fortification lasts for the rest of this battle.';
      Future<void> hover(String target, String help, String proof) async {
        await mouse.moveTo(Offset.zero);
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('mechanic-help-action')),
          findsNothing,
        );
        await tester.ensureVisible(find.byKey(ValueKey(target)));
        await tester.pumpAndSettle();
        await mouse.moveTo(tester.getCenter(find.byKey(ValueKey(target))));
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();
        expect(helpText(help), findsOneWidget, reason: 'Hover on $target');
        const prefix = String.fromEnvironment('statusTooltipProofPath');
        if (prefix.isNotEmpty) {
          await tester.runAsync(() async {
            final boundary =
                captureKey.currentContext!.findRenderObject()
                    as RenderRepaintBoundary;
            final image = await boundary.toImage();
            try {
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await File('$prefix-$proof-${width.toInt()}.png')
                  .writeAsBytes(bytes!.buffer.asUint8List());
            } finally {
              image.dispose();
            }
          });
        }
      }

      await hover('monster-stat-illuminated', flareHelp, 'illuminated');
      expect(
        find.byWidgetPredicate(
          (w) => w is MechanicText && w.text.contains('Current dodge chance'),
        ),
        findsNothing,
      );
      await hover('ship-stat-fortified', armorHelp, 'fortified');
      expect(helpText(flareHelp), findsNothing);
      expect(
        find.byWidgetPredicate(
          (w) => w is MechanicText && w.text.contains('Current dodge chance'),
        ),
        findsNothing,
      );
      await hover(
        'monster-stat-dodge',
        'Current dodge chance. Attack accuracy is a separate roll.',
        'dodge',
      );
      expect(helpText(armorHelp), findsNothing);
      await hover(
        'ship-stat-evasion',
        'Current dodge chance after captain, regional and active-effect modifiers, capped at 95%. Unavoidable attacks bypass dodge.',
        'evade',
      );
      await mouse.moveTo(Offset.zero);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.ensureVisible(
        find.byKey(const ValueKey('monster-stat-illuminated')),
      );
      await tester.pumpAndSettle();
      await tester.longPress(
        find.byKey(const ValueKey('monster-stat-illuminated')),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(helpText(flareHelp), findsOneWidget);
      expect(controller.ship!.currentHp, hp);
      expect(controller.phase, SessionPhase.battle);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

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
              w is MechanicTooltip &&
              w.message.contains(
                'Opening shot accuracy: 85%. Target dodge: 0%.',
              ),
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
        ..basaltAegisTurns = 2
        ..currentDmgReduction = 6;
      final activated = CombatEffectsChanged.capture(ship);
      ship
        ..captainQuirkId = null
        ..basaltBarrierHp = 0
        ..basaltAegisTurns = 0
        ..currentEvasion = 7
        ..currentDmgReduction = 0;
      final expired = CombatEffectsChanged.capture(ship);
      final monster = controller.currentMonster!
        ..spotterFlareTurns = 2
        ..spotterFlareAccuracyBonus = 30
        ..spotterFlareBlastBonus = .5;
      final flared = CombatEffectsChanged.capture(monster);
      monster
        ..spotterFlareTurns = 0
        ..spotterFlareAccuracyBonus = 99
        ..spotterFlareBlastBonus = 1;
      final unlit = CombatEffectsChanged.capture(monster);
      controller.setIsPlayingEvents(true);
      await tester.pump();
      expect(_stats(tester, 'ship'), contains('Evade: 25%'));
      expect(find.byKey(const ValueKey('ship-stat-fortified')), findsNothing);
      expect(
        find.byKey(const ValueKey('monster-stat-illuminated')),
        findsNothing,
      );
      game.presentation.apply(activated);
      await tester.pump();
      expect(_stats(tester, 'ship'), contains('Evade: 55%'));
      final armorTip = tester.widget<MechanicTooltip>(
        find.descendant(
          of: find.byKey(const ValueKey('ship-stat-fortified')),
          matching: find.byType(MechanicTooltip),
        ),
      );
      expect(armorTip.message, contains('6 damage'));
      game.presentation.apply(flared);
      await tester.pump();
      final flareTip = tester.widget<MechanicTooltip>(
        find.descendant(
          of: find.byKey(const ValueKey('monster-stat-illuminated')),
          matching: find.byType(MechanicTooltip),
        ),
      );
      expect(flareTip.message, contains('+30% accuracy'));
      expect(flareTip.message, contains('50%'));
      expect(flareTip.message, isNot(contains('99%')));
      game.presentation.apply(unlit);
      await tester.pump();
      expect(
        find.byKey(const ValueKey('monster-stat-illuminated')),
        findsNothing,
      );
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
      expect(find.byKey(const ValueKey('ship-stat-fortified')), findsNothing);
      expect(tester.takeException(), isNull);
      controller.setIsPlayingEvents(false);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    },
  );
}
