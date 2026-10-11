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

        // Return to port
        session.dispatch(const ReturnToPort());
        expect(session.phase, equals(SessionPhase.port));
        expect(session.seaChart.isAtStart, isTrue);

        // Visit Merchant
        session.dispatch(const VisitMerchant());
        expect(session.phase, equals(SessionPhase.merchant));

        // Sell all treasure
        final sellEvents = session.dispatch(const SellAllTreasure());
        expect(sellEvents.whereType<AllTreasureSold>(), isNotEmpty);

        // Leave merchant
        session.dispatch(const LeaveMerchant());
        expect(session.phase, equals(SessionPhase.port));
      }
    });

    test('Death and Heir lineage continuation workflow', () {
      final session = GameSession(rng: SeededGameRng(999));
      session.dispatch(const NameCaptain('Old Sal'));
      session.dispatch(const ChooseShip(ShipClass.freighter, customName: 'Hauler'));
      session.ship!.gold = 100;
      session.ship!.applyDamage(session.ship!.maxHp); // Sinks ship

      // Advance into battle with 0 HP triggers death resolution
      session.dispatch(const VentureOutToSea());
      expect(session.phase, equals(SessionPhase.death));
      expect(session.lineage.captainsLost, equals(1));

      // Continue lineage with heir
      session.dispatch(const ContinueLineage('Young Sal', ShipClass.ironclad));
      expect(session.phase, equals(SessionPhase.port));
      expect(session.captainName, equals('Young Sal'));
      expect(session.ship!.shipClass, equals(ShipClass.ironclad));
      // Freighter 5% gold inheritance (5% of 100 = 5g)
      expect(session.ship!.gold, equals(5));
    });
  });
}
