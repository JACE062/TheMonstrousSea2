import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

void main() {
  group('Escalating Region Lengths & Waypoint Formulas', () {
    test('Region 1 (The Siren Shoals) is 10 legs with Haven @ 5 and Kraken @ 10', () {
      final chart = SeaChart();
      expect(chart.currentRegionIndex, 0);
      expect(chart.totalLegs, 10);
      expect(chart.midpointHavenLeg, 5);
      expect(chart.regionTitanLeg, 10);
      expect(SeaChart.totalLegsForRegion(0), 10);
      expect(SeaChart.midpointHavenLegForRegion(0), 5);
    });

    test('Region 2 (The Sargasso Drift) is 12 legs with Haven @ 6 and Serpent @ 12', () {
      final chart = SeaChart(timesCompleted: 1);
      expect(chart.currentRegionIndex, 1);
      expect(chart.totalLegs, 12);
      expect(chart.midpointHavenLeg, 6);
      expect(chart.regionTitanLeg, 12);
      expect(SeaChart.totalLegsForRegion(1), 12);
      expect(SeaChart.midpointHavenLegForRegion(1), 6);
    });

    test('Region 3 (The Boiling Reach) is 14 legs with Haven @ 7 and Leviathan @ 14', () {
      final chart = SeaChart(timesCompleted: 2);
      expect(chart.currentRegionIndex, 2);
      expect(chart.totalLegs, 14);
      expect(chart.midpointHavenLeg, 7);
      expect(chart.regionTitanLeg, 14);
      expect(SeaChart.totalLegsForRegion(2), 14);
      expect(SeaChart.midpointHavenLegForRegion(2), 7);
    });
  });

  group('Grand Haven vs. Secluded Cove Careening & Rest Actions', () {
    test('Grand Midpoint Haven careen restores 30% max HP and allows Shipwright refit', () {
      final session = GameSession(rng: SeededGameRng(123));
      session.dispatch(const ChooseShip(ShipClass.standard));
      session.seaChart.currentLeg = session.seaChart.midpointHavenLeg; // Leg 5 in R1
      session.seaChart.setNodeTypeAt(
        session.seaChart.currentRow,
        session.seaChart.currentCol,
        EncounterNodeType.respiteIsland,
      );
      session.phase = SessionPhase.respiteIsland;

      expect(session.isCurrentIslandHaven, isTrue);

      // Damage ship heavily: down to 20 HP of 90-110 max HP
      final maxHp = session.ship!.maxHp;
      session.ship!.currentHp = 20;

      final events = session.dispatch(const CareenHullAtIsland());
      expect(session.hasCareenedAtCurrentIsland, isTrue);
      expect(events.any((e) => e is HullCareened), isTrue);

      final careenedEvent = events.whereType<HullCareened>().first;
      expect(careenedEvent.repairedHp, (maxHp * 0.30).round());
      expect(session.ship!.currentHp, 20 + (maxHp * 0.30).round());
    });

    test('Secluded Cove careen restores 20% max HP and rejects Shipwright refit', () {
      final session = GameSession(rng: SeededGameRng(456));
      session.dispatch(const ChooseShip(ShipClass.standard));
      session.seaChart.currentLeg = 2; // Procedural cove on Leg 2, not Haven (Leg 5)
      session.seaChart.setNodeTypeAt(
        session.seaChart.currentRow,
        session.seaChart.currentCol,
        EncounterNodeType.respiteIsland,
      );
      session.phase = SessionPhase.respiteIsland;

      expect(session.isCurrentIslandHaven, isFalse);

      final maxHp = session.ship!.maxHp;
      session.ship!.currentHp = 20;

      final events = session.dispatch(const CareenHullAtIsland());
      expect(session.hasCareenedAtCurrentIsland, isTrue);

      final careenedEvent = events.whereType<HullCareened>().first;
      expect(careenedEvent.repairedHp, (maxHp * 0.20).round());
      expect(session.ship!.currentHp, 20 + (maxHp * 0.20).round());

      // Attempting to upgrade ship tier at a secluded cove is disallowed
      final upgradeEvents = session.dispatch(const UpgradeShip());
      expect(
        upgradeEvents.any((e) =>
            e is NarrationEvent &&
            e.message.contains('No traveling shipwright dwells on this secluded atoll')),
        isTrue,
      );
    });

    test('Haven forage awards 40-60 gold while Cove forage awards 25-35 gold', () {
      final session = GameSession(rng: SeededGameRng(789));
      session.dispatch(const ChooseShip(ShipClass.standard));

      // Test Cove on Leg 3
      session.seaChart.currentLeg = 3;
      session.phase = SessionPhase.respiteIsland;
      session.hasForagedAtCurrentIsland = false;
      session.ship!.gold = 0;

      final coveEvents = session.dispatch(const ForageShoalsAtIsland());
      final coveForaged = coveEvents.whereType<IslandForaged>().first;
      expect(coveForaged.goldFound, inInclusiveRange(25, 35));

      // Reset shore duty & test Haven on Leg 5
      session.seaChart.currentLeg = 5;
      session.hasForagedAtCurrentIsland = false;
      session.ship!.gold = 0;

      final havenEvents = session.dispatch(const ForageShoalsAtIsland());
      final havenForaged = havenEvents.whereType<IslandForaged>().first;
      expect(havenForaged.goldFound, inInclusiveRange(40, 60));
    });
  });

  group('Region Environmental Hazards in Combat', () {
    test('Region 2 (Sargasso Drift): Tangled Kelp (-10% evasion) & Phosphor Haze (monster obscured)', () {
      final session = GameSession(rng: SeededGameRng(999));
      session.profile.unlockedBlueprints.add(BlueprintId.fromShipClass(ShipClass.corvette).name);
      session.dispatch(const ChooseShip(ShipClass.corvette));
      session.seaChart.timesCompleted = 1; // Region 2
      expect(session.seaChart.currentRegionIndex, 1);

      final baseEvasion = session.ship!.baseEvasion;
      expect(baseEvasion, greaterThanOrEqualTo(10));

      // Steer into a beast combat encounter
      session.seaChart.setNodeTypeAt(0, 1, EncounterNodeType.beastCombat);
      session.seaChart.currentLeg = 0;
      session.phase = SessionPhase.helm;

      session.dispatch(const SteerCourse(NavigationalBearing.deadAhead));

      expect(session.phase, SessionPhase.battle);
      // Corvette evasion reduced by 10%
      expect(session.ship!.currentEvasion, baseEvasion - 10);
      // Monster starts obscured
      expect(session.currentMonster!.isObscured, isTrue);
    });

    test('Region 3 (Boiling Reach): Thermal Caldera Scald deals 10 thermal damage every 3 rounds', () {
      final session = GameSession(rng: SeededGameRng(1001));
      session.profile.unlockedBlueprints.add(BlueprintId.fromShipClass(ShipClass.ironclad).name);
      session.dispatch(const ChooseShip(ShipClass.ironclad));
      session.seaChart.timesCompleted = 2; // Region 3
      expect(session.seaChart.currentRegionIndex, 2);

      session.phase = SessionPhase.battle;
      session.currentMonster = createShark(level: 3, rng: session.rng);
      session.currentMonster!.currentHp = 1000; // Keep monster alive during volley
      session.currentMonster!.usableWeapons.clear(); // Disarm so only environmental hazard damages the ship
      session.battleRound = 3; // Round 3 concluding triggers scald

      final initialHp = session.ship!.currentHp;

      // Fire weapon to trigger monster response turn & end-of-round hazard
      final events = session.dispatch(const FireWeaponVolley(ShipWeaponType.cannon));

      // ThermalScaldOccurred should be emitted with 10 damage
      final scaldEvents = events.whereType<ThermalScaldOccurred>();
      expect(scaldEvents.isNotEmpty, isTrue);
      expect(scaldEvents.first.damage, 10);
      expect(scaldEvents.first.remainingHp, session.ship!.currentHp);
      expect(session.ship!.currentHp, initialHp - 10);
    });
  });

  group('Apex / Elite Predator Enhancements & Loot', () {
    test('Apex monster has +30% HP, universal barnacle carapace, and species apex buffs', () {
      final rng = SeededGameRng(42);
      final normalShark = createMonster(MonsterSpecies.shark, level: 3, rng: rng);
      final apexShark = createMonster(
        MonsterSpecies.shark,
        level: 3,
        rng: rng,
        isApex: true,
      );

      expect(apexShark.isApex, isTrue);
      expect(apexShark.apexTitle, contains('Apex'));
      expect(apexShark.maxHp, (normalShark.maxHp * 1.30).round());
      expect(apexShark.carapacePlating, 20 + 5 * 3); // Universal barnacle carapace
      expect(apexShark.maxCarapace, 20 + 5 * 3);
      expect(apexShark.frenzyStacks, 1); // Shark-specific frenzy start

      // Test Apex Serpent
      final apexSerpent = createMonster(
        MonsterSpecies.serpent,
        level: 3,
        rng: rng,
        isApex: true,
      );
      expect(apexSerpent.carapacePlating, 35);
      expect(apexSerpent.evasion, 30);

      // Test Apex Jellyfish
      final apexJelly = createMonster(
        MonsterSpecies.jellyfish,
        level: 3,
        rng: rng,
        isApex: true,
      );
      expect(apexJelly.carapacePlating, 35);
      expect(
        apexJelly.usableWeapons.where((w) => w.monsterWeaponType == MonsterWeaponType.stingingTendrils).length,
        2,
      );

      // Test Apex Squid
      final apexSquid = createMonster(
        MonsterSpecies.squid,
        level: 3,
        rng: rng,
        isApex: true,
      );
      expect(apexSquid.carapacePlating, 35);
      expect(apexSquid.numberOfTentacles, 5 * 3 + 5);
      expect(apexSquid.obscuredAcMod, 25);

      // Test Apex Crustacean
      final normalCrust = createMonster(MonsterSpecies.crustacean, level: 3, rng: rng);
      final apexCrust = createMonster(
        MonsterSpecies.crustacean,
        level: 3,
        rng: rng,
        isApex: true,
      );
      expect(apexCrust.carapacePlating, normalCrust.carapacePlating + 35 + 25);
    });

    test('Apex victory awards +1 drop item and +50% doubloons', () {
      final normalGold = calculateVictoryGold(3, SeededGameRng(42), isApex: false);
      final apexGold = calculateVictoryGold(3, SeededGameRng(42), isApex: true);

      expect(apexGold, (normalGold * 1.5).round());

      final normalLoot = generateVictoryLoot(3, SeededGameRng(42), BalanceConfig.standard, false);
      final apexLoot = generateVictoryLoot(3, SeededGameRng(42), BalanceConfig.standard, true);

      expect(apexLoot.length, normalLoot.length + 1);
    });
  });
}
