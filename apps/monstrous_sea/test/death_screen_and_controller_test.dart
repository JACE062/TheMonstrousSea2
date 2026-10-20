import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/screens/death_screen.dart';
import 'package:monstrous_sea/src/services/storage_service.dart';

void main() {
  late Directory tempDir;
  late StorageService storage;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('monstrous_sea_ctrl_test_');
    storage = StorageService(baseDirectory: tempDir);
  });

  tearDown(() async {
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  test(
    'GameController persists profile and voyage on dispatch and restores them',
    () async {
      final controller = GameController(
        session: GameSession(rng: SeededGameRng(42)),
        storage: storage,
        autoSave: true,
      );

      // Initial captain setup
      controller.dispatch(const NameCaptain('Captain Barnaby'));
      controller.dispatch(const ChooseShip(ShipClass.standard));
      expect(controller.phase, SessionPhase.port);

      // Profile should be saved
      await controller.persistState();
      final savedProfile = await storage.loadProfile();
      expect(savedProfile.lineageTracker.history, isEmpty);

      // Take helm
      controller.dispatch(const TakeHelm());
      expect(controller.phase, SessionPhase.helm);
      await controller.persistState();

      // Voyage snapshot should exist
      expect(await storage.hasActiveVoyage(), isTrue);

      // Steer course into battle
      final course = controller.currentCourseOptions.firstWhere(
        (c) => c.nodeType == EncounterNodeType.beastCombat,
        orElse: () => controller.currentCourseOptions.first,
      );
      controller.dispatch(SteerCourse(course.bearing));
      expect(controller.phase, SessionPhase.battle);

      // Sinking ship clears voyage and saves profile
      controller.ship!.applyDamage(controller.ship!.maxHp);
      controller.dispatch(const ExecuteShipSpecialAction());
      expect(controller.phase, SessionPhase.death);
      await controller.persistState();

      expect(await storage.hasActiveVoyage(), isFalse);
      final deathProfile = await storage.loadProfile();
      expect(deathProfile.lineageTracker.captainsLost, 1);
    },
  );

  testWidgets(
    'DeathScreen renders Nemesis banner and 3 selectable Heir candidate cards',
    (WidgetTester tester) async {
      final session = GameSession(rng: SeededGameRng(100));
      final controller = GameController(
        session: session,
        storage: storage,
        autoSave: false,
      );

      controller.dispatch(const NameCaptain('Old Ahab'));
      controller.dispatch(const ChooseShip(ShipClass.standard));
      controller.dispatch(const TakeHelm());

      // Advance until in battle
      while (controller.phase != SessionPhase.battle) {
        if (controller.phase == SessionPhase.helm) {
          final course = controller.currentCourseOptions.firstWhere(
            (c) => c.nodeType == EncounterNodeType.beastCombat || c.isNemesis,
            orElse: () => controller.currentCourseOptions.first,
          );
          controller.dispatch(SteerCourse(course.bearing));
        } else if (controller.phase == SessionPhase.shipwreck) {
          controller.dispatch(const SalvageShipwreck(ShipwreckChoice.timbers));
          controller.dispatch(const AdvanceToNextBattle());
        } else if (controller.phase == SessionPhase.respiteIsland) {
          controller.dispatch(const DepartIsland());
        } else if (controller.phase == SessionPhase.smuggler) {
          controller.dispatch(const DepartSmuggler());
        } else if (controller.phase == SessionPhase.shrine) {
          controller.dispatch(const CommuneWithShrine(ShrineChoice.leave));
        }
      }

      // Sink the ship
      controller.ship!.applyDamage(controller.ship!.maxHp);
      controller.dispatch(const ExecuteShipSpecialAction());

      expect(controller.phase, SessionPhase.death);
      expect(controller.activeNemesis, isNotNull);
      expect(controller.pendingHeirCandidates.length, 3);

      await tester.pumpWidget(
        MaterialApp(home: DeathScreen(controller: controller)),
      );
      await tester.pumpAndSettle();

      // Verify Nemesis banner
      expect(find.text("HEIR'S COMMISSIONED CLASS"), findsNothing);
      expect(find.text('FREIGHTER'), findsNothing);
      expect(find.text('CORVETTE'), findsNothing);
      expect(find.textContaining('NEMESIS ASCENDED:'), findsOneWidget);
      expect(find.textContaining('Vengeance Bounty:'), findsOneWidget);

      // Verify 3 candidate cards rendered (candidate 0 also populated in text field)
      final candidates = controller.pendingHeirCandidates;
      expect(
        find.text(candidates[0].defaultName),
        findsNWidgets(2),
      ); // Card title + text field
      expect(find.text(candidates[1].defaultName), findsOneWidget);
      expect(find.text(candidates[2].defaultName), findsOneWidget);

      // Verify Boons and Quirks rendered
      expect(find.text(candidates[0].boon.name), findsOneWidget);
      expect(find.text(candidates[0].quirk.name), findsOneWidget);

      // Select second candidate
      await tester.ensureVisible(find.text(candidates[1].defaultName));
      await tester.tap(find.text(candidates[1].defaultName));
      await tester.pumpAndSettle();

      // Name text field should have updated to candidate 1 default name
      expect(
        find.text(candidates[1].defaultName),
        findsNWidgets(2),
      ); // Card title + text field
      expect(
        find.text(candidates[0].defaultName),
        findsOneWidget,
      ); // Now only card title

      // Tap CONTINUE THE HUNT
      await tester.ensureVisible(find.text('CONTINUE THE HUNT'));
      await tester.tap(find.text('CONTINUE THE HUNT'));
      await tester.pumpAndSettle();

      // Session should have transitioned to Port with the chosen candidate's boon and quirk
      expect(controller.phase, SessionPhase.port);
      expect(controller.captainName, candidates[1].defaultName);
      expect(controller.activeBoon, candidates[1].boon);
      expect(controller.activeQuirk, candidates[1].quirk);
      expect(controller.ship!.shipClass, ShipClass.standard);
    },
  );

  for (final unlocked in [false, true]) {
    testWidgets(
      'Heir returns to a valid blueprint at port (active unlocked: $unlocked)',
      (tester) async {
        final controller = GameController(
          session: GameSession(rng: SeededGameRng(42)),
          storage: storage,
          autoSave: false,
        );
        addTearDown(controller.dispose);
        controller.dispatch(const NameCaptain('Old Ahab'));
        controller.dispatch(const ChooseShip(ShipClass.standard));
        controller.session.phase = SessionPhase.death;
        controller.profile.activeBlueprintId = BlueprintId.clipper.name;
        if (unlocked) {
          controller.profile.unlockedBlueprints.add(BlueprintId.clipper.name);
        }
        await tester.pumpWidget(
          MaterialApp(home: DeathScreen(controller: controller)),
        );
        await tester.pumpAndSettle();
        expect(find.text("HEIR'S COMMISSIONED CLASS"), findsNothing);
        for (final shipClass in ShipClass.values) {
          expect(find.text(shipClass.name.toUpperCase()), findsNothing);
        }
        await tester.enterText(find.byType(TextField), 'Rowan Tide');
        await tester.ensureVisible(find.text('CONTINUE THE HUNT'));
        await tester.tap(find.text('CONTINUE THE HUNT'));
        await tester.pumpAndSettle();
        expect(controller.phase, SessionPhase.port);
        expect(controller.captainName, 'Rowan Tide');
        expect(
          controller.ship!.shipClass,
          unlocked ? ShipClass.clipper : ShipClass.standard,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
