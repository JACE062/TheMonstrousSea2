import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/main.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/services/storage_service.dart';
import 'package:monstrous_sea/src/theme/ink_theme.dart';

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  InkTheme.disableGoogleFonts = true;

  for (final region in [0, 1]) {
    testWidgets(
      'region $region stronghold upgrades, reload, combat, death, and fresh heir',
      (tester) async {
        final directory = (await tester.runAsync(
          () => Directory.systemTemp.createTemp('sea2_native_stronghold_'),
        ))!;
        addTearDown(() => directory.delete(recursive: true));
        final storage = StorageService(baseDirectory: directory);
        var controller = GameController(
          session: GameSession(rng: SeededGameRng(42)),
          storage: storage,
          autoSave: false,
        );
        addTearDown(controller.dispose);
        controller.profile.blueprintArmamentTiers['standard'] = 2;
        controller.dispatch(const BeginFirstVoyage('Reed'));
        controller.seaChart.timesCompleted = region;
        controller.seaChart.currentLeg = controller.seaChart.midpointHavenLeg;
        controller.session.phase = SessionPhase.respiteIsland;
        controller.ship!.gold = 3000;
        controller.dispatch(const UpgradeShip());
        controller.dispatch(const TemperHardpoint(HardpointType.broadside));
        controller.ship!.blessings[HardpointType.broadside] =
            const HardpointBlessing(
              power: OceanPower.brinemother,
              slot: HardpointType.broadside,
              tier: 2,
            );
        // End the Titan fight deterministically; this test verifies the voyage
        // boundary and player controls rather than boss combat balance.
        controller.seaChart.currentLeg = controller.seaChart.totalLegs;
        controller.session.currentMonster = controller.seaChart.currentMonster(
          controller.session.rng,
        )..currentHp = 0;
        controller.session.phase = SessionPhase.battle;
        controller.dispatch(const FireWeaponVolley(ShipWeaponType.cannon));
        controller.dispatch(const LeaveRemainingLoot());
        controller.dispatch(const TakeHelm());
        final boundaryKey = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundaryKey,
            child: MonstrousSeaApp(controller: controller),
          ),
        );
        await settle(tester);
        expect(controller.phase, SessionPhase.stronghold);
        expect(find.text('BLUEPRINTS'), findsNothing);
        final upgrade = find.text('UPGRADE TIER · 250g');
        await tester.ensureVisible(upgrade);
        await tester.tap(upgrade);
        await settle(tester);
        final temper = find.textContaining(
          '${HardpointType.broadside.displayName} ·',
        );
        await tester.ensureVisible(temper.first);
        await tester.tap(temper.first);
        await settle(tester);
        expect(controller.ship!.level, 3);
        expect(controller.ship!.markForHardpoint(HardpointType.broadside), 3);

        await tester.ensureVisible(find.text('MERCHANT'));
        await settle(tester);
        await tester.runAsync(() async {
          final boundary =
              boundaryKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final screenshot = File('build/stronghold-review-region-$region.png');
          await screenshot.parent.create(recursive: true);
          await screenshot.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
          debugPrint('Stronghold visual review: ${screenshot.absolute.path}');
        });
        controller.dispatch(const VisitMerchant());
        await tester.runAsync(controller.persistState);
        final loaded = GameController(storage: storage, autoSave: false);
        addTearDown(loaded.dispose);
        await tester.runAsync(loaded.initializeStorage);
        controller = loaded;
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(MonstrousSeaApp(controller: controller));
        await settle(tester);
        final leave = find.text('LEAVE CHANDLERY & RETURN TO STRONGHOLD');
        await tester.ensureVisible(leave);
        await tester.tap(leave);
        await settle(tester);
        expect(controller.phase, SessionPhase.stronghold);
        expect(controller.ship!.level, 3);
        expect(controller.ship!.markForHardpoint(HardpointType.broadside), 3);
        expect(controller.ship!.blessings[HardpointType.broadside]!.tier, 2);
        controller.seaChart.setNodeTypeAt(0, 1, EncounterNodeType.beastCombat);
        final sail = find.text(
          'SET SAIL FOR ${controller.currentRegionName.toUpperCase()}',
        );
        await tester.ensureVisible(sail);
        await tester.tap(sail);
        await settle(tester);
        controller.dispatch(const SteerCourse(NavigationalBearing.deadAhead));
        await settle(tester);
        expect(controller.phase, SessionPhase.battle);
        expect(controller.ship!.level, 3);
        expect(controller.ship!.blessings[HardpointType.broadside]!.tier, 2);
        controller.ship!.applyDamage(controller.ship!.maxHp);
        controller.dispatch(const ExecuteShipSpecialAction());
        await settle(tester);
        expect(controller.phase, SessionPhase.death);
        expect(find.text('ABANDON HUNT'), findsNothing);
        await tester.ensureVisible(find.text('CONTINUE THE HUNT'));
        await tester.tap(find.text('CONTINUE THE HUNT'));
        await settle(tester);
        expect(controller.phase, SessionPhase.port);
        expect(controller.ship!.level, 1);
        expect(controller.ship!.hardpointMarks.values, everyElement(1));
        expect(controller.ship!.blessings, isEmpty);
        expect(controller.profile.armamentTierFor(BlueprintId.standard), 2);
        expect(find.text('BLUEPRINTS'), findsOneWidget);
        expect(find.text('VOYAGE SHIPWRIGHT'), findsNothing);
        await tester.runAsync(controller.persistState);
        expect(await tester.runAsync(storage.hasActiveVoyage), isFalse);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
