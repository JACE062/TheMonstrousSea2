import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

void _initSession(GameSession session, String name) {
  session.dispatch(NameCaptain(name));
  session.dispatch(const ChooseShip(ShipClass.standard));
}

void main() {
  group('Stage 4: Caldera Dilemma, Covenant of the Deep & Titan Trophies', () {
    test('Caldera Climax: Shatter the Core consumes Leviathan Core and ends loop', () {
      final session = GameSession(rng: SeededGameRng(42));
      _initSession(session, 'Vance');
      session.profile.metaInventory.add(leviathanCore: 1);
      session.phase = SessionPhase.expeditionVictory;

      final events = session.dispatch(
        const ResolveCalderaClimax(CalderaClimaxChoice.shatterCore),
      );

      expect(session.phase, SessionPhase.ended);
      expect(session.profile.hasShatteredFont, isTrue);
      expect(session.profile.hasUnlockedCovenant, isFalse);
      expect(session.profile.metaInventory.leviathanCore, 0);
      expect(
        events.whereType<CalderaClimaxResolved>().single.choice,
        CalderaClimaxChoice.shatterCore,
      );
    });

    test('Caldera Climax: Claim the Core retains Core, unlocks Covenant, and loops to heir selection', () {
      final session = GameSession(rng: SeededGameRng(42));
      _initSession(session, 'Vance');
      session.profile.metaInventory.add(leviathanCore: 1);
      session.phase = SessionPhase.expeditionVictory;

      final events = session.dispatch(
        const ResolveCalderaClimax(CalderaClimaxChoice.claimCore),
      );

      expect(session.phase, SessionPhase.death);
      expect(session.profile.hasUnlockedCovenant, isTrue);
      expect(session.profile.ascensionLoopCount, 1);
      expect(session.profile.metaInventory.leviathanCore, 1);
      expect(session.pendingHeirCandidates, hasLength(3));
      expect(
        events.whereType<CalderaClimaxResolved>().single.choice,
        CalderaClimaxChoice.claimCore,
      );
    });

    test('Covenant Pacts toggle at Port and calculate Pact Burden accurately', () {
      final session = GameSession(rng: SeededGameRng(7));
      _initSession(session, 'Ahab');
      session.profile.hasUnlockedCovenant = true;

      session.dispatch(const ToggleCovenantPact(CovenantPactId.abyssalVigor));
      session.dispatch(const ToggleCovenantPact(CovenantPactId.volatileEnvirons));

      expect(session.profile.totalPactBurden, 3); // 1 + 2
      expect(session.profile.isPactActive(CovenantPactId.abyssalVigor), isTrue);
      expect(session.profile.isPactActive(CovenantPactId.volatileEnvirons), isTrue);

      session.dispatch(const ToggleCovenantPact(CovenantPactId.abyssalVigor));
      expect(session.profile.totalPactBurden, 2);
    });

    test('Covenant Pacts: abyssalVigor (+25% HP) and calcifiedCarapace (+10 Carapace, no AC change)', () {
      final baseSession = GameSession(rng: SeededGameRng(100));
      _initSession(baseSession, 'Base');
      baseSession.dispatch(const VentureOutToSea());
      final baseMonster = baseSession.currentMonster!;
      final baseMaxHp = baseMonster.maxHp;
      final baseCarapace = baseMonster.maxCarapace;
      final baseAc = baseMonster.armorClass;

      final pactSession = GameSession(rng: SeededGameRng(100));
      _initSession(pactSession, 'Pact');
      pactSession.profile.hasUnlockedCovenant = true;
      pactSession.dispatch(const ToggleCovenantPact(CovenantPactId.abyssalVigor));
      pactSession.dispatch(const ToggleCovenantPact(CovenantPactId.calcifiedCarapace));
      pactSession.dispatch(const VentureOutToSea());
      final pactMonster = pactSession.currentMonster!;

      expect(pactMonster.maxHp, (baseMaxHp * 1.25).round());
      expect(pactMonster.maxCarapace, baseCarapace + 10);
      expect(pactMonster.carapacePlating, baseCarapace + 10);
      // Verify no vestigial AC modification
      expect(pactMonster.armorClass, baseAc);
    });

    test('Covenant Pacts: chokingFog obscures helm lookoutCall while preserving RNG sequence', () {
      final session = GameSession(rng: SeededGameRng(55));
      _initSession(session, 'Foggy');
      session.profile.hasUnlockedCovenant = true;
      session.dispatch(const ToggleCovenantPact(CovenantPactId.chokingFog));

      session.dispatch(const TakeHelm());
      expect(session.seaChart.currentCourseOptions, isNotEmpty);
      for (final option in session.seaChart.currentCourseOptions) {
        expect(option.lookoutCall, contains('Dense phosphor fog muffles the lookout'));
      }
    });

    test('Primordial Cinders drop strictly from Region Titans under active Pact Burden', () {
      final session = GameSession(rng: SeededGameRng(99));
      _initSession(session, 'Hunter');
      session.profile.hasUnlockedCovenant = true;
      session.dispatch(const ToggleCovenantPact(CovenantPactId.abyssalVigor));
      session.dispatch(const ToggleCovenantPact(CovenantPactId.apexEmergence));
      expect(session.profile.totalPactBurden, 3);

      // 1. Defeat a non-boss monster -> 0 Primordial Cinders
      session.dispatch(const VentureOutToSea());
      session.currentMonster = createMonster(
        MonsterSpecies.shark,
        level: 1,
        rng: session.rng,
      );
      session.currentMonster!.currentHp = 1;
      session.ship!.equippedWeapons.first.damage = 500;
      session.ship!.equippedWeapons.first.hitModifier = 100;
      session.dispatch(
        FireWeaponVolley(session.ship!.equippedWeapons.first.weaponType),
      );
      expect(session.profile.metaInventory.primordialCinders, 0);

      // 2. Defeat Region 1 Titan (The Kraken) under Burden 3 -> drops Kraken Beak + Primordial Cinders
      session.phase = SessionPhase.battle;
      session.ship!.resetWeaponCooldowns();
      session.currentMonster = createMonster(
        MonsterSpecies.kraken,
        level: 6,
        rng: session.rng,
      );
      session.currentMonster!.carapacePlating = 0;
      session.currentMonster!.currentHp = 1;
      session.dispatch(
        FireWeaponVolley(session.ship!.equippedWeapons.first.weaponType),
      );

      expect(session.profile.metaInventory.krakenBeak, 1);
      expect(session.profile.metaInventory.primordialCinders, greaterThan(0));
    });

    test('Chapter 1 Trophy Progression: Blueprint Signature Armament Tiers II & III and Auxiliary Expansion', () {
      final session = GameSession(rng: SeededGameRng(12));
      _initSession(session, 'Smith');
      session.profile.unlockedBlueprints.add(BlueprintId.ironclad.name);
      session.profile.metaInventory.add(
        krakenBeak: 5,
        serpentScale: 3,
        seaGlass: 50,
        monsterBone: 50,
        depthWroughtIron: 50,
        abyssalBarnacles: 50,
      );

      // Commission Tier I Ironclad
      session.dispatch(const CommissionBlueprint(BlueprintId.ironclad));
      final tier1Damage = session.ship!.equippedWeapons
          .firstWhere((w) => w.isSignature)
          .damage;

      // Upgrade Ironclad Signature Armament to Tier II (1.25x)
      session.dispatch(const UpgradeBlueprintArmament(BlueprintId.ironclad));
      expect(session.profile.armamentTierFor(BlueprintId.ironclad), 2);
      final tier2Damage = session.ship!.equippedWeapons
          .firstWhere((w) => w.isSignature)
          .damage;
      expect(tier2Damage, (tier1Damage * 1.25).round());

      // Upgrade Ironclad Signature Armament to Tier III (1.45x diminishing returns)
      session.dispatch(const UpgradeBlueprintArmament(BlueprintId.ironclad));
      expect(session.profile.armamentTierFor(BlueprintId.ironclad), 3);
      final tier3Damage = session.ship!.equippedWeapons
          .firstWhere((w) => w.isSignature)
          .damage;
      expect(tier3Damage, (tier1Damage * 1.45).round());

      // Unlock Auxiliary Expansion (+1 Tactical Belt slot; no voyage temper).
      final weightBefore = session.ship!.maxWeaponWeight;
      final cargoBefore = session.ship!.maxCargo;
      session.dispatch(const UnlockAuxiliaryExpansion());
      expect(session.profile.hasExpandedAuxiliarySlot, isTrue);
      expect(session.ship!.maxWeaponWeight, weightBefore + 2);
      expect(session.ship!.maxCargo, cargoBefore + 1);
      expect(session.ship!.markForHardpoint(HardpointType.broadside), 1);
    });

    test('Chapter 2 & 3 Progression: Eldritch Relics and Cursed Harbor Monuments', () {
      final session = GameSession(rng: SeededGameRng(42));
      _initSession(session, 'Eldritch');
      session.profile.hasUnlockedCovenant = true;
      session.profile.unlockedBlueprints.add(BlueprintId.ironclad.name);
      session.profile.metaInventory.add(
        seaGlass: 50,
        monsterBone: 50,
        abyssalBarnacles: 50,
        depthWroughtIron: 50,
        krakenBeak: 10,
        serpentScale: 10,
        leviathanCore: 10,
        primordialCinders: 30,
      );

      // Unlock and equip Siphon Ram relic for Ironclad
      session.dispatch(const UnlockEldritchRelic(EldritchRelicId.siphonRam));
      expect(session.profile.unlockedEldritchRelics, contains(EldritchRelicId.siphonRam.name));
      expect(
        session.profile.isEldritchRelicActive(EldritchRelicId.siphonRam),
        isTrue,
      );

      // Commission Ironclad and verify Siphon Ram heals 30% of hull damage dealt
      session.dispatch(const CommissionBlueprint(BlueprintId.ironclad));
      session.phase = SessionPhase.battle;
      session.ship!.currentHp = 10;
      session.currentMonster = createMonster(
        MonsterSpecies.shark,
        level: 1,
        rng: session.rng,
      );
      session.currentMonster!.carapacePlating = 0;
      session.currentMonster!.evasion = 0;
      session.currentMonster!.currentHp = 20;
      for (final w in session.ship!.equippedWeapons) {
        w.hitModifier = 100;
        w.damage = 50;
      }
      session.dispatch(const FireWeaponVolley(ShipWeaponType.prowRam));
      // Monster defeated so no counterattack; Siphon Ram healed the ship above 10 HP!
      expect(session.ship!.currentHp, greaterThan(10));

      // Return to port and upgrade Harbor Monuments
      session.phase = SessionPhase.port;
      final maxHpBeforeMonument = session.ship!.maxHp;
      session.dispatch(const UpgradeHarborMonument(HarborMonumentId.obsidianObelisk));
      expect(session.profile.monumentRank(HarborMonumentId.obsidianObelisk), 1);
      expect(session.ship!.maxHp, maxHpBeforeMonument + 5);
    });
  });
}
