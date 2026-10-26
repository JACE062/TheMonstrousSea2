import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

void main() {
  group('Stage 1 Roguelite Flow: Profile, Succession & Nemesis', () {
    late SeededGameRng rng;

    setUp(() {
      rng = SeededGameRng(42);
    });

    test('Captain demise creates Nemesis and generates 3 Heir candidates', () {
      final profile = ProfileData();
      final session = GameSession(rng: rng, profile: profile);

      session.dispatch(const NameCaptain('Captain Barnaby'));
      session.dispatch(const ChooseShip(ShipClass.standard, customName: 'Sea Hound'));
      session.dispatch(const VentureOutToSea());

      expect(session.phase, SessionPhase.battle);
      expect(session.currentMonster, isNotNull);

      // Force fatal ship death in battle
      session.ship!.applyDamage(session.ship!.maxHp);
      final events = session.dispatch(const ExecuteShipSpecialAction());

      expect(session.phase, SessionPhase.death);

      // Verify Nemesis creation on profile
      expect(profile.activeNemesis, isNotNull);
      expect(profile.activeNemesis!.species, session.currentMonster!.species);
      expect(profile.activeNemesis!.predecessorCaptain, 'Captain Barnaby');
      expect(profile.activeNemesis!.moniker, contains('Barnaby'));

      // Verify NemesisSpawned event emitted
      expect(events.whereType<NemesisSpawned>().isNotEmpty, isTrue);

      // Verify 3 Heir candidates generated
      expect(session.pendingHeirCandidates.length, 3);
      for (final candidate in session.pendingHeirCandidates) {
        expect(candidate.defaultName, isNotEmpty);
        expect(candidate.boon, isNotNull);
        expect(candidate.quirk, isNotNull);
      }

      // Since there is an active Nemesis, one of the candidate quirks should be Blood Oath
      final hasBloodOath = session.pendingHeirCandidates.any(
        (c) => c.quirk.id == BloodlineTraitId.bloodOath,
      );
      expect(hasBloodOath, isTrue);
    });

    test('ContinueLineage activates traits, clears pending candidates, and emits HeirSelected', () {
      final profile = ProfileData();
      final session = GameSession(rng: rng, profile: profile);

      session.dispatch(const NameCaptain('Captain Barnaby'));
      session.dispatch(const ChooseShip(ShipClass.standard, customName: 'Sea Hound'));
      session.dispatch(const VentureOutToSea());

      // Slay ship in battle
      session.ship!.applyDamage(session.ship!.maxHp);
      session.dispatch(const ExecuteShipSpecialAction());
      expect(session.phase, SessionPhase.death);

      final chosenCandidate = session.pendingHeirCandidates.first;
      session.profile.unlockedBlueprints.add(BlueprintId.ironclad.name);
      final events = session.dispatch(ContinueLineage(
        'Captain Cordelia Vane',
        ShipClass.ironclad,
        boon: chosenCandidate.boon,
        quirk: chosenCandidate.quirk,
      ));

      expect(session.phase, SessionPhase.port);
      expect(session.captainName, 'Captain Cordelia Vane');
      expect(session.ship!.shipClass, ShipClass.ironclad);
      expect(session.activeBoon, chosenCandidate.boon);
      expect(session.activeQuirk, chosenCandidate.quirk);
      expect(session.pendingHeirCandidates, isEmpty);

      final heirEvent = events.whereType<HeirSelected>().first;
      expect(heirEvent.heirName, 'Captain Cordelia Vane');
      expect(heirEvent.chosenClass, ShipClass.ironclad);
      expect(heirEvent.boon, chosenCandidate.boon);
      expect(heirEvent.quirk, chosenCandidate.quirk);
    });

    test('Defeating monsters awards meta-currencies to ProfileData', () {
      final profile = ProfileData();
      final session = GameSession(rng: rng, profile: profile);

      session.dispatch(const NameCaptain('Captain Alistair'));
      session.dispatch(const ChooseShip(ShipClass.standard, customName: 'Sea Hound'));
      session.dispatch(const VentureOutToSea());

      expect(session.phase, SessionPhase.battle);
      expect(profile.metaInventory.monsterBone, 0);

      // Slay monster
      session.currentMonster!.applyDamage(session.currentMonster!.maxHp);
      final events = session.dispatch(FireWeaponVolley(session.ship!.equippedWeapons.first.weaponType));

      expect(session.phase, SessionPhase.loot);
      expect(profile.metaInventory.monsterBone, greaterThan(0));

      final awardEvents = events.whereType<MetaCurrenciesAwarded>();
      expect(awardEvents, isNotEmpty);
      expect(awardEvents.first.monsterBone, greaterThan(0));
    });

    test('Nemesis encounter spawns empowered beast, slaying it grants bounty and clears activeNemesis', () {
      final profile = ProfileData();
      final session = GameSession(rng: rng, profile: profile);

      // Create Nemesis on profile in region 0
      final fakeKiller = createMonster(MonsterSpecies.shark, level: 2, rng: rng);
      final nemesis = NemesisRecord.createFromDefeat(
        killer: fakeKiller,
        captainName: 'Predecessor John',
        regionIndex: 0,
        rng: rng,
      );
      profile.activeNemesis = nemesis;

      session.dispatch(const NameCaptain('Heir Thomas'));
      session.dispatch(const ChooseShip(ShipClass.standard, customName: 'Sea Hound'));
      session.dispatch(const VentureOutToSea());

      // Slay initial monster to reach rest area and helm
      session.currentMonster!.applyDamage(session.currentMonster!.maxHp);
      session.dispatch(FireWeaponVolley(session.ship!.equippedWeapons.first.weaponType));
      session.dispatch(const TakeAllLoot());
      expect(session.phase, SessionPhase.restArea);

      // The first eligible Nemesis course follows the midpoint Haven.
      session.seaChart.currentLeg = session.seaChart.midpointHavenLeg;
      session.dispatch(const TakeHelm());

      expect(session.phase, SessionPhase.helm);
      final nemesisCourse = session.seaChart.currentCourseOptions.firstWhere((c) => c.isNemesis);
      expect(nemesisCourse.isApex, isTrue);
      expect(nemesisCourse.apexTitle, nemesis.moniker);

      // Steer toward Nemesis
      final steerEvents = session.dispatch(SteerCourse(nemesisCourse.bearing));

      expect(session.phase, SessionPhase.battle);
      expect(session.isNemesisBattle, isTrue);
      expect(session.currentMonster!.name, nemesis.moniker);
      expect(session.currentMonster!.isApex, isTrue);
      expect(steerEvents.whereType<NemesisSpawned>(), isNotEmpty);

      // Slay the Nemesis
      final startingGold = session.ship!.gold;
      session.currentMonster!.applyDamage(session.currentMonster!.maxHp);
      final killEvents = session.dispatch(FireWeaponVolley(session.ship!.equippedWeapons.first.weaponType));

      // Verify Nemesis bounty awarded and cleared
      expect(killEvents.whereType<NemesisSlain>(), isNotEmpty);
      expect(session.ship!.gold, greaterThan(startingGold));
      expect(profile.metaInventory.seaGlass, greaterThanOrEqualTo(nemesis.bountySeaGlass));
      expect(profile.metaInventory.monsterBone, greaterThanOrEqualTo(nemesis.bountyMonsterBone));
      expect(profile.activeNemesis, isNull);
      expect(session.isNemesisBattle, isFalse);
    });

    test('Quirk: Reckless Helmsman disables Dead Ahead and keeps passive evasion separate', () {
      final session = GameSession(rng: rng);
      session.dispatch(const NameCaptain('Captain Daredevil'));
      session.dispatch(const ChooseShip(ShipClass.standard, customName: 'Sea Hound'));
      session.activeQuirk = BloodlineTrait.recklessHelmsman;

      // Reach helm
      session.dispatch(const VentureOutToSea());
      session.currentMonster!.applyDamage(session.currentMonster!.maxHp);
      session.dispatch(FireWeaponVolley(session.ship!.equippedWeapons.first.weaponType));
      session.dispatch(const TakeAllLoot());
      session.dispatch(const TakeHelm());
      expect(session.phase, SessionPhase.helm);

      // Attempting Dead Ahead throws StateError
      expect(
        () => session.dispatch(const SteerCourse(NavigationalBearing.deadAhead)),
        throwsStateError,
      );

      // Passive captain evasion is separate from consumable/maneuver boosts.
      final initialEvasion = session.ship!.baseEvasion;
      session.dispatch(const SteerCourse(NavigationalBearing.larboardTack));
      expect(session.ship!.currentEvasion, initialEvasion);
      expect(session.ship!.captainEvasionBonus, 10);
    });

    test('Quirk: Blood Oath compels wheel onto Nemesis bearing', () {
      final profile = ProfileData();
      final session = GameSession(rng: rng, profile: profile);
      session.dispatch(const NameCaptain('Avenger Roland'));
      session.dispatch(const ChooseShip(ShipClass.standard, customName: 'Sea Hound'));
      session.activeQuirk = BloodlineTrait.bloodOath;

      final killer = createMonster(MonsterSpecies.shark, level: 2, rng: rng);
      final nemesis = NemesisRecord.createFromDefeat(
        killer: killer,
        captainName: 'Father Roland',
        regionIndex: 0,
        rng: rng,
      );
      profile.activeNemesis = nemesis;

      // Reach the helm after the midpoint Haven.
      session.dispatch(const VentureOutToSea());
      session.currentMonster!.applyDamage(session.currentMonster!.maxHp);
      session.dispatch(FireWeaponVolley(session.ship!.equippedWeapons.first.weaponType));
      session.dispatch(const TakeAllLoot());

      session.seaChart.currentLeg = session.seaChart.midpointHavenLeg;
      session.dispatch(const TakeHelm());
      expect(session.phase, SessionPhase.helm);

      final nemesisCourse = session.seaChart.currentCourseOptions.firstWhere((c) => c.isNemesis);
      final otherBearing = NavigationalBearing.values.firstWhere((b) => b != nemesisCourse.bearing);

      // Attempting to steer away throws StateError
      expect(
        () => session.dispatch(SteerCourse(otherBearing)),
        throwsStateError,
      );

      // Steering toward Nemesis succeeds
      expect(
        () => session.dispatch(SteerCourse(nemesisCourse.bearing)),
        returnsNormally,
      );
    });

    test('Boon: Drillmaster permits two quick items without advancing combat', () {
      final session = GameSession(rng: rng);
      session.dispatch(const NameCaptain('Drillmaster Jack'));
      session.dispatch(const ChooseShip(ShipClass.standard, customName: 'Sea Hound'));
      session.dispatch(const VentureOutToSea());
      session.activeBoon = BloodlineTrait.drillmaster;

      for (var i = 0; i < 3; i++) {
        session.ship!.addCargo(generateConsumable(ConsumableType.hullPatchKit, RarityLevel.common));
      }
      session.ship!.currentHp = 10;
      final monsterHpBefore = session.currentMonster!.currentHp;
      final shipHpBefore = session.ship!.currentHp;

      for (var i = 0; i < 2; i++) {
        final index = session.ship!.cargo.indexWhere((item) => item is Consumable);
        session.dispatch(UseConsumableItem(index));
      }
      expect(session.currentMonster!.currentHp, monsterHpBefore);
      expect(session.ship!.currentHp, greaterThan(shipHpBefore));
      expect(session.quickConsumablesUsedThisTurn, 2);
      expect(session.battleRound, 1);
      expect(() => session.dispatch(const UseConsumableItem(0)), throwsStateError);
    });

    test('Quirk: Superstitious forbids one power and permits the other dedication', () {
      final session = GameSession(rng: rng);
      session.dispatch(const NameCaptain('Superstitious Mary'));
      session.dispatch(const ChooseShip(ShipClass.standard, customName: 'Sea Hound'));
      session.activeQuirk = BloodlineTrait.superstitious;

      session.phase = SessionPhase.shrine;
      session.shrineManifestedPowers = [OceanPower.magmaVentLord, OceanPower.tempestSovereign];
      final forbidden = session.forbiddenShrinePower!;
      expect(() => session.dispatch(AcceptShrineBlessing(forbidden, HardpointType.broadside)), throwsStateError);
      expect(session.hasCommunedAtCurrentShrine, isFalse);
      final allowed = session.shrineManifestedPowers.firstWhere((power) => power != forbidden);
      session.dispatch(AcceptShrineBlessing(allowed, HardpointType.broadside));
      expect(session.ship!.blessings[HardpointType.broadside]!.power, allowed);
      expect(session.hasCommunedAtCurrentShrine, isTrue);
    });

    test('VoyageSaveData snapshots and restores GameSession completely', () {
      final session = GameSession(rng: rng);
      session.dispatch(const NameCaptain('Captain Ulysses'));
      session.profile.unlockedBlueprints.add(BlueprintId.fromShipClass(ShipClass.corvette).name);
      session.dispatch(const ChooseShip(ShipClass.corvette, customName: 'Thunderer'));
      session.dispatch(const VentureOutToSea());
      session.activeBoon = BloodlineTrait.veteranCannoneer;
      session.activeQuirk = BloodlineTrait.exactingShipwright;

      final snapshot = VoyageSaveData.fromSession(session);
      expect(snapshot.captainName, 'Captain Ulysses');
      expect(snapshot.ship.shipClass, ShipClass.corvette);
      expect(snapshot.activeBoonId, BloodlineTraitId.veteranCannoneer);
      expect(snapshot.activeQuirkId, BloodlineTraitId.exactingShipwright);

      // Create fresh session and restore
      final restoredSession = GameSession(rng: SeededGameRng(999));
      snapshot.restoreToSession(restoredSession);

      expect(restoredSession.captainName, 'Captain Ulysses');
      expect(restoredSession.ship!.shipClass, ShipClass.corvette);
      expect(restoredSession.activeBoon?.id, BloodlineTraitId.veteranCannoneer);
      expect(restoredSession.activeQuirk?.id, BloodlineTraitId.exactingShipwright);
      expect(restoredSession.phase, session.phase);
    });
  });
}
