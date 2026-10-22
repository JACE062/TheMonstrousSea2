import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sea/src/game_controller.dart';
import 'package:monstrous_sea/src/screens/death_screen.dart';
import 'package:monstrous_sea/src/screens/port_screen.dart';
import 'package:monstrous_sea/src/screens/victory_screen.dart';

void main() {
  group('Caldera Dilemma & VictoryScreen', () {
    testWidgets(
      'Shatter the Core concludes the ancestral quest and marks font shattered',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final controller = GameController(
          session: GameSession(rng: SeededGameRng(42)),
          autoSave: false,
        );
        controller.dispatch(const NameCaptain('Aurelius'));
        controller.profile.unlockedBlueprints.add(BlueprintId.ironclad.name);
        controller.dispatch(const ChooseShip(ShipClass.ironclad));

        // Simulate Region 3 Titan kill rewards & Victory phase
        controller.session.profile.metaInventory.add(leviathanCore: 1);
        controller.session.phase = SessionPhase.expeditionVictory;

        await tester.pumpWidget(
          MaterialApp(home: VictoryScreen(controller: controller)),
        );
        await tester.pumpAndSettle();

        expect(find.text(EldritchLore.calderaTitle), findsOneWidget);
        expect(find.text(EldritchLore.calderaClimax[CalderaClimaxChoice.shatterCore]!.promptTitle), findsOneWidget);
        expect(
          find.text(EldritchLore.calderaClimax[CalderaClimaxChoice.claimCore]!.promptTitle),
          findsOneWidget,
        );

        final shatterBtn = find.text('SHATTER THE CORE');
        expect(shatterBtn, findsOneWidget);

        await tester.tap(shatterBtn);
        await tester.pumpAndSettle();

        expect(controller.phase, SessionPhase.ended);
        expect(controller.session.profile.hasShatteredFont, isTrue);
        expect(controller.session.profile.hasUnlockedCovenant, isFalse);
        expect(
          controller.session.profile.metaInventory.leviathanCore,
          equals(0),
        );
      },
    );

    testWidgets(
      'Claim the Core unlocks Covenant and prepares heir succession',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final controller = GameController(
          session: GameSession(rng: SeededGameRng(42)),
          autoSave: false,
        );
        controller.dispatch(const NameCaptain('Cyrus'));
        controller.profile.unlockedBlueprints.add(BlueprintId.ironclad.name);
        controller.dispatch(const ChooseShip(ShipClass.ironclad));

        controller.session.profile.metaInventory.add(leviathanCore: 1);
        controller.session.phase = SessionPhase.expeditionVictory;

        await tester.pumpWidget(
          MaterialApp(home: VictoryScreen(controller: controller)),
        );
        await tester.pumpAndSettle();

        final claimBtn = find.text('CLAIM THE CORE');
        expect(claimBtn, findsOneWidget);

        await tester.tap(claimBtn);
        await tester.pumpAndSettle();

        expect(controller.phase, SessionPhase.death);
        expect(controller.session.profile.hasUnlockedCovenant, isTrue);
        expect(controller.session.profile.ascensionLoopCount, equals(1));
        expect(
          controller.session.profile.metaInventory.leviathanCore,
          equals(1),
        );
      },
    );
  });

  group('DeathScreen Caldera Adaptation', () {
    testWidgets(
      'Displays the returning-ship subtitle after the Core is claimed',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final controller = GameController(
          session: GameSession(rng: SeededGameRng(42)),
          autoSave: false,
        );
        controller.dispatch(const NameCaptain('Nautilus'));
        controller.profile.unlockedBlueprints.add(BlueprintId.clipper.name);
        controller.dispatch(const ChooseShip(ShipClass.clipper));
        controller.session.profile.metaInventory.add(leviathanCore: 1);

        // Trigger Claim Core from Victory phase
        controller.session.phase = SessionPhase.expeditionVictory;
        controller.dispatch(
          const ResolveCalderaClimax(CalderaClimaxChoice.claimCore),
        );
        expect(controller.phase, SessionPhase.death);

        await tester.pumpWidget(
          MaterialApp(home: DeathScreen(controller: controller)),
        );
        await tester.pumpAndSettle();

        expect(find.text(EldritchLore.claimSuccessionTitle), findsOneWidget);
        expect(find.text(EldritchLore.claimSuccessionSubtitle), findsOneWidget);
      },
    );
  });

  group('PortScreen Blueprints: Ancestral Armament Tiers', () {
    testWidgets(
      'Upgrades ancestral Signature Armament Tiers without offering an extra mount',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final controller = GameController(
          session: GameSession(rng: SeededGameRng(42)),
          autoSave: false,
        );
        controller.dispatch(const NameCaptain('Hector'));
        controller.dispatch(const ChooseShip(ShipClass.standard));

        await tester.pumpWidget(
          MaterialApp(
            home: PortScreen(controller: controller, onOpenChart: () {}),
          ),
        );
        await tester.pumpAndSettle();

        // Open Blueprints dialog
        await tester.tap(find.text('BLUEPRINTS'));
        await tester.pumpAndSettle();

        // Check Reserve Auxiliary Hardpoint section
        expect(
          find.text('RESERVE AUXILIARY HARDPOINT EXPANSION'),
          findsNothing,
        );
        expect(controller.session.profile.hasExpandedAuxiliarySlot, isFalse);

        // Standard is unlocked by default, check Tier 1 status
        expect(find.text('SIGNATURE ARMAMENT: TIER 1'), findsOneWidget);
        expect(find.text('1.00x DMG'), findsOneWidget);

        // Provide materials for Tier 2 Signature Armament (1 Beak, 10 Sea Glass, 8 Bone)
        controller.session.profile.metaInventory.add(
          krakenBeak: 1,
          seaGlass: 10,
          monsterBone: 8,
        );

        // Close and reopen dialog to refresh state
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('BLUEPRINTS'));
        await tester.pumpAndSettle();

        final upgradeTier2Btn = find.widgetWithText(InkWell, 'UPGRADE TIER 2');
        expect(upgradeTier2Btn, findsOneWidget);

        await tester.tap(upgradeTier2Btn);
        await tester.pumpAndSettle();

        expect(
          controller.session.profile.armamentTierFor(BlueprintId.standard),
          equals(2),
        );
        expect(find.text('SIGNATURE ARMAMENT: TIER 2'), findsOneWidget);
        expect(find.text('1.25x DMG'), findsOneWidget);

        // Now upgrade to Tier 3 (2 Beaks, 1 Serpent Scale, 8 Iron, 6 Barnacles)
        controller.session.profile.metaInventory.add(
          krakenBeak: 2,
          serpentScale: 1,
          depthWroughtIron: 8,
          abyssalBarnacles: 6,
        );

        // Close and reopen to refresh
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('BLUEPRINTS'));
        await tester.pumpAndSettle();

        final upgradeTier3Btn = find.widgetWithText(InkWell, 'UPGRADE TIER 3');
        expect(upgradeTier3Btn, findsOneWidget);

        await tester.tap(upgradeTier3Btn);
        await tester.pumpAndSettle();

        expect(
          controller.session.profile.armamentTierFor(BlueprintId.standard),
          equals(3),
        );
        expect(find.text('SIGNATURE ARMAMENT: TIER 3'), findsOneWidget);
        expect(find.text('1.45x DMG'), findsOneWidget);
        expect(find.text('MAX TIER'), findsOneWidget);
      },
    );
  });

  group('PortScreen Covenant Altar: Pacts, Relics & Monuments', () {
    testWidgets('Covenant banner appears and opens 3-tab Covenant dialog', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = GameController(
        session: GameSession(rng: SeededGameRng(42)),
        autoSave: false,
      );
      controller.dispatch(const NameCaptain('CovenantMaster'));
      controller.dispatch(const ChooseShip(ShipClass.standard));

      // Before covenant unlock: no banner, no COVENANT action button
      await tester.pumpWidget(
        MaterialApp(
          home: PortScreen(controller: controller, onOpenChart: () {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('COVENANT ALTAR OF THE DEEP'), findsNothing);
      expect(find.text('COVENANT'), findsNothing);

      // Unlock Covenant in profile
      controller.session.profile.hasUnlockedCovenant = true;
      controller.session.profile.ascensionLoopCount = 1;
      controller.session.profile.metaInventory.add(
        krakenBeak: 5,
        serpentScale: 5,
        leviathanCore: 2,
        primordialCinders: 10,
        seaGlass: 50,
        monsterBone: 50,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PortScreen(controller: controller, onOpenChart: () {}),
        ),
      );
      await tester.pumpAndSettle();

      // Banner and button now exist
      expect(find.text('COVENANT ALTAR OF THE DEEP'), findsOneWidget);
      expect(find.text('COVENANT'), findsOneWidget);
      expect(find.text('COMMUNE'), findsOneWidget);

      // Open dialog via COMMUNE button
      await tester.tap(find.text('COMMUNE'));
      await tester.pumpAndSettle();

      expect(find.text('ABYSSAL COVENANT ALTAR'), findsOneWidget);
      // Strictly verify Pact Burden terminology (never Heat)
      expect(find.textContaining('PACT BURDEN'), findsWidgets);
      expect(find.textContaining('Heat'), findsNothing);

      // Tab 1: Toggle Abyssal Vigor (Burden +1)
      final vigorSwitch = find.text('ABYSSAL VIGOR');
      expect(vigorSwitch, findsOneWidget);
      await tester.tap(vigorSwitch);
      await tester.pumpAndSettle();

      expect(
        controller.session.profile.activePacts,
        contains(CovenantPactId.abyssalVigor),
      );
      expect(controller.session.profile.totalPactBurden, equals(1));
      expect(find.textContaining('+1 PACT BURDEN'), findsOneWidget);

      // Toggle Apex Emergence (Burden +2)
      final apexSwitch = find.text('APEX EMERGENCE');
      expect(apexSwitch, findsOneWidget);
      await tester.tap(apexSwitch);
      await tester.pumpAndSettle();

      expect(
        controller.session.profile.activePacts,
        contains(CovenantPactId.apexEmergence),
      );
      expect(controller.session.profile.totalPactBurden, equals(3));
      expect(find.textContaining('+3 PACT BURDEN'), findsOneWidget);

      // Switch to TAB 2: ELDRITCH RELICS
      final relicsTab = find.text('ELDRITCH RELICS');
      expect(relicsTab, findsOneWidget);
      await tester.tap(relicsTab);
      await tester.pumpAndSettle();

      expect(find.textContaining('ABYSSAL SIPHON RAM'), findsOneWidget);
      expect(find.textContaining('GHOSTWAKE RAIL-CULVERIN'), findsOneWidget);
      expect(find.textContaining('CALDERA BRIMSTONE MORTAR'), findsOneWidget);
      expect(find.textContaining('KRAKEN-SINEW DRAG WINCH'), findsOneWidget);

      // Unlock Clipper blueprint so Ghostwake Culverin can be forged
      controller.session.profile.unlockedBlueprints.add(
        BlueprintId.clipper.name,
      );
      await tester.tap(relicsTab);
      await tester.pumpAndSettle();

      final forgeCulverinBtn = find.widgetWithText(InkWell, 'FORGE RELIC');
      expect(forgeCulverinBtn, findsWidgets);

      await tester.tap(forgeCulverinBtn.first);
      await tester.pumpAndSettle();

      expect(
        controller.session.profile.isEldritchRelicUnlocked(
          EldritchRelicId.ghostwakeCulverin,
        ),
        isTrue,
      );
      expect(find.text('FORGED'), findsOneWidget);

      // Switch to TAB 3: CURSED MONUMENTS
      final monumentsTab = find.text('CURSED MONUMENTS');
      expect(monumentsTab, findsOneWidget);
      await tester.tap(monumentsTab);
      await tester.pumpAndSettle();

      expect(find.textContaining('OBSIDIAN TIDE-OBELISK'), findsOneWidget);
      expect(find.textContaining('IDOL OF THE COILED DEEP'), findsOneWidget);
      expect(find.textContaining('BRAZIER OF THE ETERNAL RIM'), findsOneWidget);
      expect(find.text('RANK 0'), findsNWidgets(3));

      // Upgrade Obsidian Obelisk to Rank 1
      final upgradeMonBtn = find.widgetWithText(InkWell, 'UPGRADE (Rank 1)');
      expect(upgradeMonBtn, findsWidgets);

      await tester.tap(upgradeMonBtn.first);
      await tester.pumpAndSettle();

      expect(
        controller.session.profile.monumentRank(
          HarborMonumentId.obsidianObelisk,
        ),
        equals(1),
      );
      expect(find.text('RANK 1'), findsOneWidget);
    });
  });
}
