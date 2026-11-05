import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/main.dart';
import 'package:monstrous_sea/src/battle/monstrous_sea_battle_game.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/screens/battle_screen.dart';
import 'package:monstrous_sea/src/screens/loot_screen.dart';
import 'package:monstrous_sea/src/screens/shipwreck_screen.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';

class _Hits extends SeededGameRng {
  _Hits() : super(1);
  @override
  int d100() => 1;
}

GameController _ambush() {
  final controller = GameController(
    autoSave: false,
    session: GameSession(
      rng: _Hits(),
      navigationTuning: const NavigationTuning(
        wrecks: WreckTuning(approachAmbushChance: 100),
      ),
    ),
  )..dispatch(const BeginFirstVoyage('Wreck playback'));
  final chart = controller.seaChart.toJson()
    ..['currentLeg'] = 2
    ..['courseOptions'] = [
      const CourseOption(
        bearing: NavigationalBearing.deadAhead,
        nodeType: EncounterNodeType.shipwreckSalvage,
        difficultyLevel: 2,
        lookoutCall: 'A fresh derelict ahead.',
        wreckSighting: WreckSighting(
          seed: 81,
          condition: WreckCondition.fresh,
          clearClue: true,
        ),
      ).toJson(),
    ];
  controller.seaChart.restoreFromJson(chart);
  controller.session.phase = SessionPhase.helm;
  controller.dispatch(const SteerCourse(NavigationalBearing.deadAhead));
  controller.currentMonster!
    ..currentHp = 1
    ..evasion = 0
    ..carapacePlating = 0;
  controller.ship!.equippedWeapons.first.damage = 1000;
  return controller;
}

void main() {
  setUpAll(() => InkTheme.disableGoogleFonts = true);

  for (final command in [const TakeAllLoot(), const LeaveRemainingLoot()]) {
    test('controller $command retains cleared wreck and never skips cargo', () {
      final controller = _ambush();
      addTearDown(controller.dispose);
      controller.currentMonster!.currentHp = 0;
      controller.dispatch(const FireWeaponVolley(ShipWeaponType.cannon));
      final earned = controller.profile.metaInventory.toJson();
      controller.dispatch(command);
      expect(controller.phase, SessionPhase.shipwreck);
      expect(controller.session.currentWreck!.stage, WreckStage.recovery);
      expect(controller.profile.metaInventory.toJson(), earned);
      expect(controller.seaChart.currentLeg, 3);
      controller.dispatch(
        ChooseWreckRecovery(
          controller.session.currentWreck!.id,
          WreckRecoveryChoice.recoverClearedCargo,
        ),
      );
      expect(controller.phase, SessionPhase.shipwreck);
      expect(controller.profile.metaInventory.seaGlass, greaterThan(0));
    });
  }

  testWidgets(
    'wreck victory completes playback, creature loot, then cargo recovery',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = _ambush();
      addTearDown(controller.dispose);
      late MonstrousSeaBattleGame game;
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            theme: InkTheme.themeData,
            home: GameOrchestratorView(controller: controller, skipIntro: true),
          ),
        );
        game =
            tester
                    .widget<GameWidget>(
                      find.byWidgetPredicate((w) => w is GameWidget),
                    )
                    .game
                as MonstrousSeaBattleGame;
        await game.toBeLoaded();
      });
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Naval Cannon Battery'));
      await tester.pump();
      expect(controller.phase, SessionPhase.loot);
      expect(controller.isPlayingEvents, isTrue);
      expect(find.byType(BattleScreen), findsOneWidget);
      expect(find.byType(LootScreen), findsNothing);
      expect(find.byType(ShipwreckScreen), findsNothing);
      for (var frame = 0; frame < 30 && controller.isPlayingEvents; frame++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      await tester.pump(const Duration(milliseconds: 500));
      expect(controller.isPlayingEvents, isFalse);
      expect(find.byType(BattleScreen), findsNothing);
      expect(find.byType(LootScreen), findsOneWidget);
      controller.dispatch(const LeaveRemainingLoot());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(ShipwreckScreen), findsOneWidget);
      expect(find.text('RECOVER CARGO'), findsOneWidget);
      expect(find.text('LINGER FOR DEEPER CARGO'), findsNothing);
      final before = controller.profile.metaInventory.toJson();
      await tester.ensureVisible(find.text('RECOVER CARGO'));
      await tester.tap(find.text('RECOVER CARGO'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('SALVAGE COMPLETE'), findsOneWidget);
      expect(
        controller.profile.metaInventory.seaGlass,
        greaterThan(before['seaGlass'] as int),
      );
      expect(controller.session.currentWreck!.stage, WreckStage.receipt);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
