import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/main.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/screens/helm_screen.dart';
import 'package:monstrous_sea/src/screens/rest_screen.dart';
import 'package:monstrous_sea/src/services/storage_service.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';
import 'package:monstrous_sea/src/widgets/armory_view.dart';
import 'package:monstrous_sea/src/widgets/ink_button.dart';

GameController navigator({StorageService? storage}) {
  final controller = GameController(
    session: GameSession(rng: SeededGameRng(42)),
    autoSave: false,
    storage: storage,
  )..dispatch(const BeginFirstVoyage('Navigator'));
  return controller;
}

void ordinaryLoot(GameController controller) {
  controller.session.phase = SessionPhase.loot;
  controller.session.hasDefeatedCurrentEncounter = true;
  controller.session.currentMonster = null;
  controller.session.pendingLoot = [randomConsumable(1, SeededGameRng(8))];
}

void main() {
  setUpAll(() => InkTheme.disableGoogleFonts = true);

  for (final command in [
    const TakeLootItem(0),
    const TakeAllLoot(),
    const LeaveRemainingLoot(),
  ]) {
    test(
      'resolved ordinary loot opens helm in one notification: ${command.runtimeType}',
      () {
        final controller = navigator();
        addTearDown(controller.dispose);
        ordinaryLoot(controller);
        final phases = <SessionPhase>[];
        controller.addListener(() => phases.add(controller.phase));
        controller.dispatch(command);
        expect(phases, [SessionPhase.helm]);
        expect(controller.currentCourseOptions, hasLength(3));
        expect(controller.seaChart.currentLeg, 1);
      },
    );
  }

  test('full belt keeps loot decisions; empty loot continues directly', () {
    final controller = navigator();
    addTearDown(controller.dispose);
    ordinaryLoot(controller);
    for (var i = 0; i < controller.ship!.maxCargo; i++) {
      controller.ship!.addCargo(randomConsumable(1, SeededGameRng(i)));
    }
    controller.dispatch(const TakeAllLoot());
    expect(controller.phase, SessionPhase.loot);
    expect(controller.pendingLoot, hasLength(1));
    controller.dispatch(const LeaveRemainingLoot());
    expect(controller.phase, SessionPhase.helm);
    ordinaryLoot(controller);
    controller.session.pendingLoot.clear();
    controller.dispatch(const LeaveRemainingLoot());
    expect(controller.phase, SessionPhase.helm);
  });

  test('real battle rewards resume with the same supplies and gold without a second award', () async {
    final directory = await Directory.systemTemp.createTemp(
      'monstrous-loot-resume-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final storage = StorageService(baseDirectory: directory);
    final controller = navigator(storage: storage);
    addTearDown(controller.dispose);
    controller.currentMonster!.currentHp = 0;
    controller.dispatch(
      FireWeaponVolley(controller.ship!.equippedWeapons.first.weaponType),
    );
    expect(controller.phase, SessionPhase.loot);
    final gold = controller.ship!.gold;
    final banner = controller.lastGoldSalvaged;
    final supplies = controller.pendingLoot.map((item) => item.name).toList();
    expect(banner, greaterThan(0));
    await controller.persistState();
    final restored = GameController(storage: storage, autoSave: false);
    addTearDown(restored.dispose);
    await restored.initializeStorage();
    expect(restored.phase, SessionPhase.loot);
    expect(restored.lastGoldSalvaged, banner);
    expect(restored.pendingLoot.map((item) => item.name), supplies);
    restored.dispatch(const TakeAllLoot());
    expect(restored.phase, SessionPhase.helm);
    expect(restored.ship!.gold, gold);
  });

  test(
    'old rest checkpoint is upgraded once and retains offered headings on disk',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'monstrous-old-rest-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final storage = StorageService(baseDirectory: directory);
      final old = navigator(storage: storage);
      addTearDown(old.dispose);
      old.session.phase = SessionPhase.restArea;
      old.session.currentMonster = null;
      old.session.hasDefeatedCurrentEncounter = true;
      await old.persistState();
      final restored = GameController(storage: storage);
      addTearDown(restored.dispose);
      await restored.initializeStorage();
      expect(restored.phase, SessionPhase.helm);
      expect(restored.isCurrentEncounterDefeated, isTrue);
      final offers = restored.seaChart.toJson()['courseOptions'];
      final again = GameController(storage: storage, autoSave: false);
      addTearDown(again.dispose);
      await again.initializeStorage();
      expect(again.phase, SessionPhase.helm);
      expect(again.seaChart.toJson()['courseOptions'], offers);
    },
  );

  test('direct course flow retains emergency triage with its original cost and cap', () {
    final controller = navigator();
    addTearDown(controller.dispose);
    ordinaryLoot(controller);
    controller.ship!.currentHp = 5;
    controller.ship!.gold = 100;
    controller.dispatch(const LeaveRemainingLoot());
    expect(controller.phase, SessionPhase.helm);
    expect(controller.canEmergencyRepairAtSea, isTrue);
    final floor = (controller.ship!.maxHp * 0.25).ceil();
    final cost = (floor - 5) * 2;
    controller.dispatch(const RepairShip(1.0));
    expect(controller.ship!.currentHp, floor);
    expect(controller.ship!.gold, 100 - cost);
    expect(controller.canEmergencyRepairAtSea, isFalse);
  });

  for (var region = 0; region < 3; region++) {
    test(
      'Titan rewards route directly to stronghold/final resolution in region $region',
      () {
        final controller = navigator();
        addTearDown(controller.dispose);
        ordinaryLoot(controller);
        controller.seaChart.timesCompleted = region;
        controller.seaChart.currentLeg = controller.seaChart.totalLegs;
        controller.ship!.blessings[HardpointType.signature] =
            const HardpointBlessing(
              power: OceanPower.brinemother,
              slot: HardpointType.signature,
              tier: 2,
            );
        controller.dispatch(const TakeAllLoot());
        expect(
          controller.phase,
          region == 2
              ? SessionPhase.expeditionVictory
              : SessionPhase.stronghold,
        );
        expect(controller.ship!.blessings[HardpointType.signature]!.tier, 2);
        expect(controller.pendingLoot, isEmpty);
      },
    );
  }

  for (final scale in [1.15, 1.3]) {
    testWidgets(
      'ordinary rewards show course controls without rest at $scale',
      (tester) async {
        tester.view.physicalSize = const Size(1100, 850);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = navigator();
        addTearDown(controller.dispose);
        ordinaryLoot(controller);
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: GameOrchestratorView(controller: controller),
          ),
        );
        await tester.tap(find.text('TAKE ALL SPOILS'));
        await tester.pumpAndSettle();
        expect(find.byType(HelmScreen), findsOneWidget);
        expect(find.byType(RestScreen), findsNothing);
        expect(find.byType(ArmoryView), findsNothing);
        expect(find.text('CONSULT SEA CHART').hitTestable(), findsOneWidget);
        expect(find.text('STEER THIS HEADING').hitTestable(), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'outgoing helm holds its offers during fade and ignores duplicate clicks',
    (tester) async {
      final controller = navigator();
      addTearDown(controller.dispose);
      ordinaryLoot(controller);
      controller.dispatch(const LeaveRemainingLoot());
      final state = controller.seaChart.toJson();
      state['courseOptions'] = [
        for (final bearing in NavigationalBearing.values)
          {
            'bearing': bearing.name,
            'nodeType': EncounterNodeType.shipwreckSalvage.name,
            'difficultyLevel': 1,
            'lookoutCall': 'Original offer ${bearing.name}',
          },
      ];
      controller.seaChart.restoreFromJson(state);
      await tester.pumpWidget(MonstrousSeaApp(controller: controller));
      await tester.pumpAndSettle();
      final steer = tester.widget<InkButton>(
        find
            .byWidgetPredicate(
              (w) => w is InkButton && w.label == 'STEER THIS HEADING',
            )
            .first,
      );
      final before = controller.currentLeg;
      steer.onPressed!();
      steer.onPressed!();
      // Simulate chart changes while AnimatedSwitcher retains the old screen.
      controller.seaChart.ensureCourseOptions(controller.session.rng);
      controller.notify();
      await tester.pump(const Duration(milliseconds: 50));
      expect(controller.currentLeg, before + 1);
      expect(find.textContaining('Original offer'), findsNWidgets(3));
      expect(find.textContaining('Awaiting the navigator'), findsNothing);
      await tester.pumpAndSettle();
      expect(find.byType(HelmScreen), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Reckless heading is visibly disabled with a persistent explanation',
    (tester) async {
      final controller = navigator();
      addTearDown(controller.dispose);
      ordinaryLoot(controller);
      controller.session.activeQuirk = BloodlineTrait.fromId(
        BloodlineTraitId.recklessHelmsman,
      );
      controller.dispatch(const LeaveRemainingLoot());
      await tester.pumpWidget(MonstrousSeaApp(controller: controller));
      await tester.pumpAndSettle();
      expect(
        find.text('Reckless Helmsman refuses to steer Dead Ahead!'),
        findsOneWidget,
      );
      final disabled = tester.widget<InkButton>(
        find.byWidgetPredicate(
          (w) => w is InkButton && w.label == 'HEADING UNAVAILABLE',
        ),
      );
      expect(disabled.onPressed, isNull);
      expect(disabled.semanticHint, contains('Reckless Helmsman'));
      expect(
        find.byTooltip('Reckless Helmsman refuses to steer Dead Ahead!'),
        findsOneWidget,
      );
    },
  );

  test(
    'shipwreck checkpoint persists exact receipt and overflow through disk',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'monstrous-navigation-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final storage = StorageService(baseDirectory: directory);
      final controller = navigator(storage: storage);
      addTearDown(controller.dispose);
      controller.session.phase = SessionPhase.shipwreck;
      controller.session.currentShipwreckName = 'Saved Wreck';
      controller.session.hasSalvagedCurrentWreck = true;
      controller.session.wreckSalvageReceipt = [
        '3 Sea Glass',
        'Recovered Blast Pack.',
      ];
      controller.session.pendingLoot = [randomConsumable(1, SeededGameRng(3))];
      controller.profile.metaInventory.seaGlass = 3;
      await controller.persistState();
      final restored = GameController(storage: storage, autoSave: false);
      addTearDown(restored.dispose);
      await restored.initializeStorage();
      expect(restored.phase, SessionPhase.shipwreck);
      expect(
        restored.session.wreckSalvageReceipt,
        controller.session.wreckSalvageReceipt,
      );
      expect(
        restored.pendingLoot.single.name,
        controller.pendingLoot.single.name,
      );
      restored.dispatch(const SalvageShipwreck(ShipwreckChoice.munitions));
      expect(restored.profile.metaInventory.seaGlass, 3);
    },
  );
}
