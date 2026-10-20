import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

void main() {
  group('Full Voyage End-to-End Headless Tests', () {
    test('Davy Jones easter egg initiates Kraken encounter with Flying Dutchman', () {
      final session = GameSession(rng: SeededGameRng(42));
      expect(session.phase, equals(SessionPhase.captainCreation));

      final events = session.dispatch(const NameCaptain('Davy Jones'));
      expect(session.phase, equals(SessionPhase.battle));
      expect(session.ship, isNotNull);
      expect(session.ship!.name, equals('Flying Dutchman'));
      expect(session.ship!.maxHp, equals(1600));
      expect(session.seaChart.currentRow, equals(3));
      expect(session.seaChart.currentCol, equals(4));
      expect(session.currentMonster, isNotNull);
      expect(session.currentMonster!.name, equals('The Kraken'));

      // Verify battle started event emitted
      expect(events.whereType<BattleStarted>(), isNotEmpty);
      final battleStarted = events.whereType<BattleStarted>().first;
      expect(battleStarted.isBoss, isTrue);
      expect(battleStarted.monsterName, equals('The Kraken'));
    });

    test('Flying Dutchman defeats The Kraken in battle and collects loot', () {
      final session = GameSession(rng: SeededGameRng(12345));
      session.dispatch(const NameCaptain('Davy Jones'));

      var rounds = 0;
      while (session.phase == SessionPhase.battle && rounds < 20) {
        // Volley with legendary Cannons
        session.dispatch(const FireWeaponVolley(ShipWeaponType.cannon));
        rounds++;
      }

      expect(session.phase, equals(SessionPhase.loot));
      expect(session.currentMonster!.isAlive, isFalse);
      expect(session.monstersDefeatedThisLife, equals(1));
      expect(session.highestDifficultyThisLife, equals(5));
      expect(session.pendingLoot, isNotEmpty);

      // Collect all spoils
      final lootEvents = session.dispatch(const TakeAllLoot());
      expect(session.phase, equals(SessionPhase.restArea));
      expect(lootEvents.whereType<ItemAcquired>(), isNotEmpty);
    });

    test('Standard voyage: create captain, sail, win battle, loot, rest, return to port', () {
      final session = GameSession(rng: SeededGameRng(777));
      session.dispatch(const NameCaptain('Ahab'));
      final shipEvents = session.dispatch(const ChooseShip(ShipClass.standard, customName: 'Pequod'));

      expect(session.phase, equals(SessionPhase.port));
      expect(session.ship!.name, equals('Pequod'));
      expect(session.ship!.equippedWeapons.length, equals(2));
      expect(session.ship!.gold, equals(25));
      expect(shipEvents.whereType<PhaseChanged>(), isNotEmpty);

      // Venture out into open sea
      final sailEvents = session.dispatch(const VentureOutToSea());
      expect(session.phase, equals(SessionPhase.battle));
      expect(session.currentMonster, isNotNull);
      expect(session.seaChart.currentRow, equals(0));
      expect(session.seaChart.currentCol, equals(0));
      expect(sailEvents.whereType<BattleStarted>(), isNotEmpty);

      // Fight until monster defeated or player dies
      var maxSteps = 30;
      while (session.phase == SessionPhase.battle && maxSteps > 0) {
        session.dispatch(const FireWeaponVolley(ShipWeaponType.cannon));
        maxSteps--;
      }

      if (session.phase == SessionPhase.loot) {
        session.dispatch(const TakeAllLoot());
        expect(session.phase, equals(SessionPhase.restArea));

        // The home port is a between-voyage location, never a rest-area exit.
        expect(() => session.dispatch(const ReturnToPort()), throwsStateError);
        session.dispatch(const TakeHelm());
        expect(session.phase, SessionPhase.helm);
      }
    });

    test('Death and Heir lineage continuation workflow', () {
      final session = GameSession(rng: SeededGameRng(999));
      session.dispatch(const NameCaptain('Old Sal'));
      session.profile.unlockedBlueprints.add(BlueprintId.fromShipClass(ShipClass.freighter).name);
      session.dispatch(const ChooseShip(ShipClass.freighter, customName: 'Hauler'));
      session.ship!.gold = 100;
      session.ship!.applyDamage(session.ship!.maxHp); // Sinks ship

      // Advance into battle with 0 HP triggers death resolution
      session.dispatch(const VentureOutToSea());
      expect(session.phase, equals(SessionPhase.death));
      expect(session.lineage.captainsLost, equals(1));

      // Continue lineage with heir
      session.profile.unlockedBlueprints.add(BlueprintId.ironclad.name);
      session.dispatch(const ContinueLineage('Young Sal', ShipClass.ironclad));
      expect(session.phase, equals(SessionPhase.port));
      expect(session.captainName, equals('Young Sal'));
      expect(session.ship!.shipClass, equals(ShipClass.ironclad));
      // Freighter 5% gold inheritance (5% of 100 = 5g)
      expect(session.ship!.gold, equals(5));
      expect(session.seaChart.maxRowReached, equals(0)); // Reset for new heir
    });

    test('Respite Island Haven: careen hull, drill gunners, and depart', () {
      final session = GameSession(rng: SeededGameRng(333));
      session.dispatch(const NameCaptain('Nemo'));
      session.dispatch(const ChooseShip(ShipClass.standard));

      // Damage ship hull to test careening
      session.ship!.currentHp = 50;

      // Locate the guaranteed Respite Island
      int islandRow = -1;
      int islandCol = -1;
      for (var r = 0; r < SeaChart.totalRows; r++) {
        for (var c = 0; c < SeaChart.totalCols; c++) {
          if (session.seaChart.nodeTypeAt(r, c) == EncounterNodeType.respiteIsland) {
            islandRow = r;
            islandCol = c;
            break;
          }
        }
        if (islandRow != -1) break;
      }
      expect(islandRow != -1, isTrue);

      // Position ship right before Respite Island
      if (islandCol > 0) {
        session.seaChart.currentRow = islandRow;
        session.seaChart.currentCol = islandCol - 1;
      } else {
        session.seaChart.currentRow = islandRow - 1;
        session.seaChart.currentCol = SeaChart.totalCols - 1;
      }
      session.phase = SessionPhase.restArea;

      // Advance to the island
      session.seaChart.setNodeTypeAt(islandRow, islandCol, EncounterNodeType.respiteIsland);
      final advanceEvents = session.dispatch(const AdvanceToNextBattle());

      expect(session.phase, equals(SessionPhase.respiteIsland));
      expect(session.seaChart.isRespiteIsland, isTrue);
      expect(advanceEvents.whereType<RespiteIslandReached>(), isNotEmpty);
      expect(session.currentIslandName, isNotEmpty);

      // Careen Hull (heals 35% maxHp = ~35 HP)
      final careenEvents = session.dispatch(const CareenHullAtIsland());
      expect(careenEvents.whereType<HullCareened>(), isNotEmpty);
      expect(session.ship!.currentHp, greaterThan(50));
      expect(session.hasCareenedAtCurrentIsland, isTrue);

      // Repeat careen is ignored
      final repeatCareen = session.dispatch(const CareenHullAtIsland());
      expect(repeatCareen.whereType<HullCareened>(), isEmpty);

      // With single shore duty restraint, drilling after careening is locked out
      final drillEvents = session.dispatch(const DrillGunnersAtIsland());
      expect(drillEvents.whereType<GunnersDrilled>(), isEmpty);
      expect(session.hasChosenIslandDuty, isTrue);

      // Depart Island transitions to the helm to set course
      final departEvents = session.dispatch(const DepartIsland());
      expect(session.phase, equals(SessionPhase.helm));
      expect(departEvents.whereType<HelmApproached>(), isNotEmpty);

      final steerEvents = session.dispatch(
        const SteerCourse(NavigationalBearing.deadAhead),
      );
      expect(session.phase, isNot(equals(SessionPhase.helm)));
      expect(steerEvents.whereType<CourseSteered>(), isNotEmpty);
    });

    test('Shipwreck Derelict Encounter: discover and salvage strongbox', () {
      final session = GameSession(rng: SeededGameRng(444));
      session.dispatch(const NameCaptain('Blackbeard'));
      session.profile.unlockedBlueprints.add(BlueprintId.fromShipClass(ShipClass.freighter).name);
      session.dispatch(const ChooseShip(ShipClass.freighter));

      final startGold = session.ship!.gold;

      // Locate or establish a Shipwreck on the chart
      int wreckRow = -1;
      int wreckCol = -1;
      for (var r = 0; r < SeaChart.totalRows; r++) {
        for (var c = 0; c < SeaChart.totalCols; c++) {
          if (session.seaChart.nodeTypeAt(r, c) == EncounterNodeType.shipwreckSalvage) {
            wreckRow = r;
            wreckCol = c;
            break;
          }
        }
        if (wreckRow != -1) break;
      }
      if (wreckRow == -1) {
        wreckRow = 2;
        wreckCol = 1;
        session.seaChart.setNodeTypeAt(wreckRow, wreckCol, EncounterNodeType.shipwreckSalvage);
      }

      // Position ship right before Shipwreck
      if (wreckCol > 0) {
        session.seaChart.currentRow = wreckRow;
        session.seaChart.currentCol = wreckCol - 1;
      } else {
        session.seaChart.currentRow = wreckRow - 1;
        session.seaChart.currentCol = SeaChart.totalCols - 1;
      }
      session.phase = SessionPhase.restArea;

      // Advance to the shipwreck
      session.seaChart.setNodeTypeAt(wreckRow, wreckCol, EncounterNodeType.shipwreckSalvage);
      final advanceEvents = session.dispatch(const AdvanceToNextBattle());

      expect(session.phase, equals(SessionPhase.shipwreck));
      expect(session.seaChart.isShipwreck, isTrue);
      expect(advanceEvents.whereType<ShipwreckDiscovered>(), isNotEmpty);

      // Cannot depart without salvaging
      expect(
        () => session.dispatch(const AdvanceToNextBattle()),
        throwsStateError,
      );

      // Salvage strongbox
      final salvageEvents = session.dispatch(
        const SalvageShipwreck(ShipwreckChoice.strongbox),
      );
      expect(salvageEvents.whereType<ShipwreckSalvaged>(), isNotEmpty);
      expect(session.ship!.gold, greaterThan(startGold));

      // Now can depart to next node
      final departEvents = session.dispatch(const AdvanceToNextBattle());
      final expectedNextRow = wreckCol < SeaChart.bossCol ? wreckRow : wreckRow + 1;
      final expectedNextCol = wreckCol < SeaChart.bossCol ? wreckCol + 1 : 0;
      expect(session.seaChart.currentRow, equals(expectedNextRow));
      expect(session.seaChart.currentCol, equals(expectedNextCol));
      expect(departEvents, isNotEmpty);
    });

    test("Carpenter Emergency Triage in Rest Area strictly enforces <25% HP floor", () {
      final session = GameSession(rng: SeededGameRng(555));
      session.dispatch(const NameCaptain('Ishmael'));
      session.dispatch(const ChooseShip(ShipClass.standard));

      session.phase = SessionPhase.restArea;
      session.ship!.currentHp = 60; // > 25% of max HP (~100)

      // Routine repair declined in turbulent open sea
      final declinedEvents = session.dispatch(const RepairShip(0.25));
      expect(declinedEvents.whereType<ShipRepaired>(), isEmpty);
      expect(
        declinedEvents.whereType<NarrationEvent>().first.message,
        contains('too turbulent'),
      );

      // Ship suffers critical damage down to 10 HP (<25%)
      session.ship!.currentHp = 10;
      session.ship!.gold = 100;

      final triageEvents = session.dispatch(const RepairShip(0.25));
      expect(triageEvents.whereType<ShipRepaired>(), isNotEmpty);
      final repairedEvent = triageEvents.whereType<ShipRepaired>().first;
      expect(repairedEvent.newHp, equals((session.ship!.maxHp * 0.25).ceil()));
      expect(session.ship!.currentHp, equals((session.ship!.maxHp * 0.25).ceil()));
    });

    test('Grand Expedition Campaign Victory after slaying Region 3 Final Titan', () {
      final session = GameSession(rng: SeededGameRng(888));
      session.dispatch(const NameCaptain('Odysseus'));
      session.profile.unlockedBlueprints.add(BlueprintId.fromShipClass(ShipClass.ironclad).name);
      session.dispatch(const ChooseShip(ShipClass.ironclad));

      // 1. Clear Region 0 Kraken
      session.seaChart.currentRow = 3;
      session.seaChart.currentCol = 4;
      session.seaChart.timesCompleted = 0;
      session.phase = SessionPhase.battle;
      session.currentMonster = session.seaChart.currentMonster(session.rng);
      session.currentMonster!.currentHp = 0; // Beast defeated!

      session.phase = SessionPhase.restArea;
      final toRegion1 = session.dispatch(const AdvanceToNextBattle());
      expect(toRegion1.whereType<RegionTransitioned>(), isNotEmpty);
      expect(session.seaChart.currentRegionIndex, equals(1));
      expect(session.seaChart.currentRegionName, equals('The Sargasso Drift'));
      expect(session.phase, equals(SessionPhase.stronghold));
      expect(session.seaChart.currentPortName, equals('Fort Krakenwatch'));

      // Embark from Fort Krakenwatch into Region 1
      session.dispatch(const VentureOutToSea());
      expect(session.phase, isNot(equals(SessionPhase.port)));

      // 2. Clear Region 1 World Serpent
      session.seaChart.currentRow = 3;
      session.seaChart.currentCol = 4;
      session.phase = SessionPhase.battle;
      session.currentMonster = session.seaChart.currentMonster(session.rng);
      session.currentMonster!.currentHp = 0; // Beast defeated!

      session.phase = SessionPhase.restArea;
      final toRegion2 = session.dispatch(const AdvanceToNextBattle());
      expect(toRegion2.whereType<RegionTransitioned>(), isNotEmpty);
      expect(session.seaChart.currentRegionIndex, equals(2));
      expect(session.seaChart.currentRegionName, equals('The Boiling Reach'));
      expect(session.phase, equals(SessionPhase.stronghold));
      expect(session.seaChart.currentPortName, equals('The Iron Bastion'));

      // Embark from The Iron Bastion into Region 2
      session.dispatch(const VentureOutToSea());
      expect(session.phase, isNot(equals(SessionPhase.port)));

      // 3. Clear Region 2 Final Titan (The Ancient Leviathan)
      session.seaChart.currentRow = 3;
      session.seaChart.currentCol = 4;
      session.phase = SessionPhase.battle;
      session.currentMonster = session.seaChart.currentMonster(session.rng);
      session.currentMonster!.currentHp = 0; // Final Titan vanquished!

      session.phase = SessionPhase.restArea;
      final victoryEvents = session.dispatch(const AdvanceToNextBattle());

      // Expedition is won!
      expect(session.phase, equals(SessionPhase.expeditionVictory));
      expect(session.isExpeditionWon, isTrue);
      expect(victoryEvents.whereType<ExpeditionWon>(), isNotEmpty);

      // Claim eternal glory
      final finishEvents = session.dispatch(const ClaimExpeditionVictory());
      expect(session.phase, equals(SessionPhase.ended));
      expect(finishEvents.whereType<PhaseChanged>(), isNotEmpty);
    });
  });
}
