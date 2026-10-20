import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/main.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/screens/stronghold_screen.dart';
import 'package:monstrous_sea/src/services/storage_service.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';

GameController atStronghold({int region = 0, StorageService? storage}) {
  final controller = GameController(
    session: GameSession(rng: SeededGameRng(42)),
    storage: storage,
    autoSave: false,
  );
  controller.dispatch(const BeginFirstVoyage('Reed'));
  controller.seaChart.timesCompleted = region;
  controller.seaChart.currentLeg = controller.seaChart.totalLegs;
  controller.session.currentMonster = null;
  controller.session.hasDefeatedCurrentEncounter = true;
  controller.session.phase = SessionPhase.restArea;
  controller.dispatch(const TakeHelm());
  controller.ship!.gold = 1000;
  controller.ship!.blessings[HardpointType.broadside] = const HardpointBlessing(
    power: OceanPower.brinemother,
    slot: HardpointType.broadside,
    tier: 2,
  );
  return controller;
}

class PausedCheckpointStorage extends StorageService {
  PausedCheckpointStorage(Directory directory)
    : super(baseDirectory: directory);
  final writing = Completer<void>();
  final release = Completer<void>();
  int? savedLevel;

  @override
  Future<void> saveVoyage(VoyageSaveData voyage) async {
    writing.complete();
    await release.future;
    savedLevel = voyage.ship.level;
    await super.saveVoyage(voyage);
  }
}

void main() {
  setUpAll(() => InkTheme.disableGoogleFonts = true);

  testWidgets(
    'stronghold offers voyage upgrades and returns from merchant without home actions',
    (tester) async {
      final controller = atStronghold();
      addTearDown(controller.dispose);
      await tester.pumpWidget(MonstrousSeaApp(controller: controller));
      await tester.pumpAndSettle();
      expect(find.text('FORT KRAKENWATCH'), findsOneWidget);
      expect(find.text('BLUEPRINTS'), findsNothing);
      expect(find.text('COVENANT'), findsNothing);
      final upgrade = find.text('UPGRADE TIER · 100g');
      await tester.ensureVisible(upgrade);
      await tester.tap(upgrade);
      await tester.pumpAndSettle();
      expect(controller.ship!.level, 2);
      expect(controller.ship!.gold, 900);
      final temper = find.textContaining(
        '${HardpointType.broadside.displayName} ·',
      );
      await tester.ensureVisible(temper.first);
      await tester.tap(temper.first);
      await tester.pumpAndSettle();
      expect(controller.ship!.markForHardpoint(HardpointType.broadside), 2);
      expect(controller.ship!.gold, 840);
      await tester.ensureVisible(find.text('MERCHANT'));
      await tester.tap(find.text('MERCHANT'));
      await tester.pumpAndSettle();
      final leave = find.text('LEAVE CHANDLERY & RETURN TO STRONGHOLD');
      await tester.ensureVisible(leave);
      await tester.tap(leave);
      await tester.pumpAndSettle();
      expect(controller.phase, SessionPhase.stronghold);
      final sail = find.text('SET SAIL FOR THE SARGASSO DRIFT');
      await tester.ensureVisible(sail);
      await tester.tap(sail);
      await tester.pumpAndSettle();
      expect(controller.phase, SessionPhase.helm);
      expect(controller.ship!.level, 2);
      expect(controller.ship!.blessings[HardpointType.broadside]!.tier, 2);
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [360.0, 1000.0]) {
    testWidgets('stronghold fits ${width}px at 130% text', (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = atStronghold(region: 1);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: InkTheme.themeData,
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(width, 1000),
              textScaler: const TextScaler.linear(1.3),
            ),
            child: StrongholdScreen(controller: controller, onOpenChart: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('THE IRON BASTION'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  test('stronghold and merchant checkpoints persist upgrades through fresh controller startup', () async {
    final directory = await Directory.systemTemp.createTemp('sea_stronghold_');
    addTearDown(() => directory.delete(recursive: true));
    for (final region in [0, 1]) {
      final storage = StorageService(baseDirectory: directory);
      final controller = atStronghold(region: region, storage: storage);
      addTearDown(controller.dispose);
      controller.dispatch(const UpgradeShip());
      controller.dispatch(const TemperHardpoint(HardpointType.signature));
      for (final merchant in [false, true]) {
        if (merchant) controller.dispatch(const VisitMerchant());
        await controller.persistState();
        expect(await storage.hasActiveVoyage(), isTrue);
        final loaded = GameController(storage: storage, autoSave: false);
        addTearDown(loaded.dispose);
        await loaded.initializeStorage();
        if (merchant) loaded.dispatch(const LeaveMerchant());
        expect(loaded.phase, SessionPhase.stronghold);
        expect(loaded.seaChart.currentRegionIndex, region + 1);
        expect(loaded.ship!.level, 2);
        expect(loaded.ship!.markForHardpoint(HardpointType.signature), 2);
        expect(loaded.ship!.blessings[HardpointType.broadside]!.tier, 2);
      }
    }
  });

  test(
    'an earlier delayed checkpoint cannot resurrect a voyage after death',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'sea_checkpoint_queue_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final storage = PausedCheckpointStorage(directory);
      final controller = atStronghold(storage: storage);
      addTearDown(controller.dispose);
      final first = controller.persistState();
      await storage.writing.future;
      controller.ship!.level = 4;
      controller.session.phase = SessionPhase.battle;
      controller.session.currentMonster = createShark(
        level: 1,
        rng: SeededGameRng(7),
      );
      controller.ship!.applyDamage(controller.ship!.maxHp);
      controller.dispatch(const ExecuteShipSpecialAction());
      final death = controller.persistState();
      storage.release.complete();
      await Future.wait([first, death]);
      expect(
        storage.savedLevel,
        1,
        reason: 'checkpoint state is captured before awaiting I/O',
      );
      expect(await storage.hasActiveVoyage(), isFalse);
      expect((await storage.loadProfile()).lineageTracker.captainsLost, 1);
    },
  );
}
