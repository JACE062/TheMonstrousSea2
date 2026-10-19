import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

void main() {
  group('Flagship Blueprints & Hardpoint Architecture Tests', () {
    test('Catalog contains all 5 ancestral blueprints with strict 3-hardpoint layouts (Broadside, Signature, Utility)', () {
      expect(FlagshipBlueprint.catalog.length, equals(5));

      for (final bp in FlagshipBlueprint.catalog.values) {
        expect(bp.hardpoints.length, equals(3));
        expect(
          bp.hardpoints.map((h) => h.type).toList(),
          equals([
            HardpointType.broadside,
            HardpointType.signature,
            HardpointType.utility,
          ]),
        );
      }

      final standard = FlagshipBlueprint.catalog[BlueprintId.standard]!;
      expect(standard.name, 'Blueprint: Standard');
      expect(standard.unlockCost.isFree, isTrue);
      expect(standard.baseCargo, equals(3));
      expect(standard.signatureWeaponId, equals('twin_chasers'));

      final ironclad = FlagshipBlueprint.catalog[BlueprintId.ironclad]!;
      expect(ironclad.name, 'Blueprint: Ironclad');
      expect(ironclad.unlockCost.seaGlass, equals(15));
      expect(ironclad.unlockCost.monsterBone, equals(10));
      expect(ironclad.baseCargo, equals(3));
      expect(ironclad.signatureWeaponId, equals('prow_ram'));

      final clipper = FlagshipBlueprint.catalog[BlueprintId.clipper]!;
      expect(clipper.name, 'Blueprint: Clipper');
      expect(clipper.unlockCost.seaGlass, equals(15));
      expect(clipper.unlockCost.monsterBone, equals(10));
      expect(clipper.baseCargo, equals(3));
      expect(clipper.signatureWeaponId, equals('precision_culverin'));

      final bombardier = FlagshipBlueprint.catalog[BlueprintId.bombardier]!;
      expect(bombardier.name, 'Blueprint: Bombardier');
      expect(bombardier.unlockCost.depthWroughtIron, equals(8));
      expect(bombardier.unlockCost.abyssalBarnacles, equals(6));
      expect(bombardier.baseCargo, equals(3));
      expect(bombardier.signatureWeaponId, equals('heavy_mortar'));

      final corsair = FlagshipBlueprint.catalog[BlueprintId.corsair]!;
      expect(corsair.name, 'Blueprint: Corsair');
      expect(corsair.unlockCost.depthWroughtIron, equals(8));
      expect(corsair.unlockCost.abyssalBarnacles, equals(6));
      expect(corsair.baseCargo, equals(4));
      expect(corsair.signatureWeaponId, equals('harpoon_winch'));
    });

    test('createFlagshipFromBlueprint equips Phase 3A Broadside (0T) and Signature (1T) weapons', () {
      final rng = SeededGameRng(100);

      final standard = createFlagshipFromBlueprint(BlueprintId.standard, level: 1, rng: rng);
      expect(standard.shipClass, equals(ShipClass.standard));
      expect(standard.maxCargo, equals(3));
      expect(standard.equippedWeapons.length, equals(2));
      expect(
        standard.equippedWeapons.map((w) => w.weaponType).toSet(),
        equals({ShipWeaponType.cannon, ShipWeaponType.twinChasers}),
      );

      final ironclad = createFlagshipFromBlueprint(BlueprintId.ironclad, level: 1, rng: rng);
      expect(ironclad.shipClass, equals(ShipClass.ironclad));
      expect(ironclad.baseDmgReduction, equals(3));
      expect(
        ironclad.equippedWeapons.map((w) => w.weaponType).toSet(),
        equals({ShipWeaponType.heavyCarronade, ShipWeaponType.prowRam}),
      );

      final clipper = createFlagshipFromBlueprint(BlueprintId.clipper, level: 1, rng: rng);
      expect(clipper.shipClass, equals(ShipClass.clipper));
      expect(clipper.baseEvasion, equals(25));
      expect(
        clipper.equippedWeapons.map((w) => w.weaponType).toSet(),
        equals({ShipWeaponType.swivelGun, ShipWeaponType.precisionCulverin}),
      );

      final bombardier = createFlagshipFromBlueprint(BlueprintId.bombardier, level: 1, rng: rng);
      expect(bombardier.shipClass, equals(ShipClass.bombardier));
      expect(bombardier.equippedWeapons.length, equals(2));
      expect(
        bombardier.equippedWeapons.map((w) => w.weaponType).toSet(),
        equals({ShipWeaponType.shrapnelHowitzer, ShipWeaponType.heavyMortar}),
      );
      expect(
        bombardier.equippedWeapons.firstWhere((w) => w.weaponType == ShipWeaponType.heavyMortar).chargeTime,
        equals(1),
      );

      final corsair = createFlagshipFromBlueprint(BlueprintId.corsair, level: 1, rng: rng);
      expect(corsair.shipClass, equals(ShipClass.corsair));
      expect(corsair.maxCargo, equals(4));
      expect(
        corsair.equippedWeapons.map((w) => w.weaponType).toSet(),
        equals({ShipWeaponType.chainShotBroadside, ShipWeaponType.harpoonWinch}),
      );
    });

    test('Profile meta-currency unlocking rules and deductions', () {
      final profile = ProfileData();
      expect(profile.isBlueprintUnlocked(BlueprintId.standard), isTrue);
      expect(profile.isBlueprintUnlocked(BlueprintId.ironclad), isFalse);

      // Cannot afford initially
      expect(profile.canUnlockBlueprint(BlueprintId.ironclad), isFalse);
      expect(profile.unlockBlueprint(BlueprintId.ironclad), isFalse);

      // Award common materials
      profile.metaInventory.add(seaGlass: 20, monsterBone: 15);
      expect(profile.canUnlockBlueprint(BlueprintId.ironclad), isTrue);

      final unlocked = profile.unlockBlueprint(BlueprintId.ironclad);
      expect(unlocked, isTrue);
      expect(profile.isBlueprintUnlocked(BlueprintId.ironclad), isTrue);
      expect(profile.metaInventory.seaGlass, equals(5)); // 20 - 15
      expect(profile.metaInventory.monsterBone, equals(5)); // 15 - 10

      // Cannot re-unlock already unlocked blueprint
      expect(profile.canUnlockBlueprint(BlueprintId.ironclad), isFalse);

      // Tier 2 Blueprint (Bombardier) requires rare materials
      profile.metaInventory.add(depthWroughtIron: 8, abyssalBarnacles: 6);
      expect(profile.canUnlockBlueprint(BlueprintId.bombardier), isTrue);
      expect(profile.unlockBlueprint(BlueprintId.bombardier), isTrue);
      expect(profile.isBlueprintUnlocked(BlueprintId.bombardier), isTrue);
      expect(profile.metaInventory.depthWroughtIron, equals(0));
      expect(profile.metaInventory.abyssalBarnacles, equals(0));
    });

    test('Combat: Precision Culverin critical strikes bypass 50% of monster Carapace', () {
      final rng = SeededGameRng(77);
      final culverin = generateShipWeapon(
        ShipWeaponType.precisionCulverin,
        1,
        RarityLevel.common,
        rng,
      );
      culverin.damage = 20;

      final ship = createFlagshipFromBlueprint(BlueprintId.clipper, rng: rng);
      final crab = createCrustacean(level: 1, rng: rng);
      crab.carapacePlating = 50;
      final initialHp = crab.currentHp;

      // Culverin deals 20 piercing damage at its Long anchor range (100%)
      // 50% (10) is absorbed by carapace; 50% (10) penetrates straight to monster HP
      final (result, _) = calculateAttack(
        ship,
        culverin,
        crab,
        rng,
        defaultCombatTraits,
        100,
        1.0,
        CombatRange.long,
      );

      expect(result.didHit, isTrue);
      expect(result.carapaceAbsorbed, equals(10));
      expect(crab.carapacePlating, equals(40));
      expect(crab.currentHp, equals(initialHp - 10));
    });

    test('Combat: Heavy Mortar delivers 2.0x blast damage vs Carapace and disrupts shark frenzy', () {
      final rng = SeededGameRng(88);
      final mortar = generateShipWeapon(
        ShipWeaponType.heavyMortar,
        1,
        RarityLevel.common,
        rng,
      );
      mortar.damage = 20;

      final ship = createFlagshipFromBlueprint(BlueprintId.bombardier, rng: rng);
      final crab = createCrustacean(level: 1, rng: rng);
      crab.carapacePlating = 50;

      // Heavy Mortar deals 20 blast damage at Long anchor range (100%) with 2.0x multiplier = 40 damage directly to carapace!
      final (result, _) = calculateAttack(
        ship,
        mortar,
        crab,
        rng,
        defaultCombatTraits,
        100,
        1.0,
        CombatRange.long,
      );

      expect(result.didHit, isTrue);
      expect(result.carapaceDamaged, equals(40));
      expect(crab.carapacePlating, equals(10));

      // Test frenzy disruption on Shark
      final shark = createShark(level: 1, rng: rng);
      shark.frenzyStacks = 3;
      final (sharkResult, _) = calculateAttack(
        ship,
        mortar,
        shark,
        rng,
        defaultCombatTraits,
        100,
        1.0,
        CombatRange.long,
      );

      expect(sharkResult.didHit, isTrue);
      expect(sharkResult.disruptedFrenzy, isTrue);
      expect(shark.frenzyStacks, equals(0));
    });

    test('Combat: Harpoon Winch severs tentacles on Squids and Krakens', () {
      final rng = SeededGameRng(99);
      final harpoon = generateShipWeapon(
        ShipWeaponType.harpoonWinch,
        1,
        RarityLevel.common,
        rng,
      );
      harpoon.damage = 25;

      final ship = createFlagshipFromBlueprint(BlueprintId.corsair, rng: rng);
      final squid = createSquid(level: 1, rng: rng);
      squid.numberOfTentacles = 8;

      // Harpoon deals 25 piercing damage; severs ceil(25 / 10) = 3 tentacles!
      final (result, _) = calculateAttack(ship, harpoon, squid, rng, defaultCombatTraits, 100);

      expect(result.didHit, isTrue);
      expect(result.tentaclesSevered, equals(3));
      expect(squid.numberOfTentacles, equals(5));
    });

    test('Session: UnlockBlueprint and CommissionBlueprint commands in GameSession', () {
      final rng = SeededGameRng(42);
      final session = GameSession(rng: rng);
      session.dispatch(const NameCaptain('Cyrus Black'));
      session.dispatch(const ChooseShip(ShipClass.standard));

      expect(session.phase, equals(SessionPhase.port));
      expect(session.ship!.blueprintId, equals('standard'));

      // Award materials for Ironclad
      session.profile.metaInventory.add(seaGlass: 15, monsterBone: 10);

      // Unlock Blueprint
      final unlockEvents = session.dispatch(const UnlockBlueprint(BlueprintId.ironclad));
      expect(unlockEvents.whereType<BlueprintUnlocked>(), isNotEmpty);
      expect(session.profile.isBlueprintUnlocked(BlueprintId.ironclad), isTrue);

      // Commission Blueprint at Port
      session.ship!.gold = 150;
      final commissionEvents = session.dispatch(const CommissionBlueprint(BlueprintId.ironclad));
      expect(commissionEvents.whereType<BlueprintCommissioned>(), isNotEmpty);

      // Ship is reconfigured into Ironclad
      expect(session.ship!.blueprintId, equals('ironclad'));
      expect(session.ship!.shipClass, equals(ShipClass.ironclad));
      expect(session.ship!.gold, equals(150));
      expect(
        session.ship!.equippedWeapons.any((w) => w.weaponType == ShipWeaponType.prowRam),
        isTrue,
      );
    });

    test('Phase 3A: Normalized Range Curves have a 100% anchor range and Prow Ram has 125% Medium kinetic charge', () {
      for (final bp in BlueprintId.values) {
        final broadside = bp.broadsideWeaponType;
        final signature = bp.signatureWeaponType;
        final broadsideMults = CombatRange.values
            .map((r) => weaponRangeDamageMultiplier(broadside, r))
            .toList();
        final signatureMults = CombatRange.values
            .where((r) => isWeaponTypeUsableAtRange(signature, r))
            .map((r) => weaponRangeDamageMultiplier(signature, r))
            .toList();
        expect(broadsideMults, contains(1.00));
        expect(signatureMults, contains(1.00));
      }
      expect(weaponRangeDamageMultiplier(ShipWeaponType.prowRam, CombatRange.short), equals(1.00));
      expect(weaponRangeDamageMultiplier(ShipWeaponType.prowRam, CombatRange.medium), equals(1.25));
      expect(isWeaponTypeUsableAtRange(ShipWeaponType.prowRam, CombatRange.long), isFalse);
    });

    test('Phase 3A: Corsair Drifting Tether-Trap sets distance 2 at Long, 1 at Medium, and 0 (instant detonation) at Short', () {
      final session = GameSession(rng: SeededGameRng(42));
      session.dispatch(const NameCaptain('Corsair Vane'));
      session.profile.unlockedBlueprints.add(BlueprintId.corsair.name);
      session.dispatch(const ChooseShip(ShipClass.corsair));
      session.dispatch(const VentureOutToSea());

      final monster = session.currentMonster!;
      monster.maxHp = 500;
      monster.currentHp = 500;
      monster.carapacePlating = 0;

      // 1. From Long Range -> sets activeTetherTrapDistance = 2, then drifts by 1 at round end (or 2 if monster moves)
      session.combatRange = CombatRange.long;
      monster.isPinnedThisTurn = true; // Keep monster stationary during its turn
      session.dispatch(const ExecuteShipSpecialAction());
      // Launched at distance 2 from Long, then ocean current drifted it by 1 at end of round -> distance 1!
      expect(session.ship!.activeTetherTrapDistance, equals(1));
      expect(session.ship!.utilityCooldown, equals(2));

      // Next round, ocean current drifts trap from 1 -> 0 and detonates, pinning monster!
      monster.isPinnedThisTurn = true;
      final hpBeforeDetonation = monster.currentHp;
      session.dispatch(const FireWeaponVolley(ShipWeaponType.chainShotBroadside));
      expect(session.ship!.activeTetherTrapDistance, isNull);
      expect(monster.currentHp, lessThan(hpBeforeDetonation));

      // 2. From Short Range -> instant detonation (distance 0) and Pins monster immediately!
      session.ship!.utilityCooldown = 0;
      session.combatRange = CombatRange.short;
      final hpBeforeShortTrap = monster.currentHp;
      final events = session.dispatch(const ExecuteShipSpecialAction());
      expect(session.ship!.activeTetherTrapDistance, isNull);
      expect(monster.currentHp, lessThan(hpBeforeShortTrap));
      expect(
        events.whereType<NarrationEvent>().any((e) => e.message.contains('SNARE!')),
        isTrue,
      );
    });

    test('Phase 3A: Bombardier Phosphor Spotter Flare clears Obscured, suppresses Evasion, and boosts Blast damage by +25%', () {
      final session = GameSession(rng: SeededGameRng(42));
      session.dispatch(const NameCaptain('Bombardier Locke'));
      session.profile.unlockedBlueprints.add(BlueprintId.bombardier.name);
      session.dispatch(const ChooseShip(ShipClass.bombardier));
      session.dispatch(const VentureOutToSea());

      final monster = session.currentMonster!;
      monster.maxHp = 500;
      monster.currentHp = 500;
      monster.carapacePlating = 0;
      monster.isObscured = true;
      monster.evasion = 30;
      monster.isPinnedThisTurn = true;

      session.dispatch(const ExecuteShipSpecialAction());
      expect(monster.isObscured, isFalse);
      // 2 turns applied, 1 decremented at end of round -> 1 turn remaining for player's next volley
      expect(monster.spotterFlareTurns, equals(1));

      final howitzer = session.ship!.equippedWeapons
          .firstWhere((w) => w.weaponType == ShipWeaponType.shrapnelHowitzer);
      howitzer.damage = 20;
      howitzer.hitModifier = 100;
      final (result, _) = calculateAttack(
        session.ship!,
        howitzer,
        monster,
        session.rng,
        defaultCombatTraits,
        100,
      );
      expect(result.didHit, isTrue);
      // 20 base * 1.25 (Spotter Flare +25% Blast) = 25 damage
      expect(result.damage, equals(25));
    });

    test('Phase 3A: Hardpoint Tempering (Mk I -> Mk II -> Mk III) and Quick-Action Tactical Belt (0T)', () {
      final session = GameSession(rng: SeededGameRng(42));
      session.dispatch(const NameCaptain('Temper Jack'));
      session.dispatch(const ChooseShip(ShipClass.standard));

      final ship = session.ship!;
      ship.gold = 300;
      final broadside = ship.equippedWeapons.firstWhere((w) => !w.isSignature);
      final baseDamage = broadside.damage;

      // Temper Broadside to Mk II (60g, 1.20x)
      final temper1 = session.dispatch(const TemperHardpoint(HardpointType.broadside));
      expect(temper1.whereType<HardpointTempered>().single.newMark, equals(2));
      expect(ship.gold, equals(240));
      expect(broadside.damage, equals((baseDamage * 1.20).round()));

      // Temper Broadside to Mk III (120g, 1.40x)
      final temper2 = session.dispatch(const TemperHardpoint(HardpointType.broadside));
      expect(temper2.whereType<HardpointTempered>().single.newMark, equals(3));
      expect(ship.gold, equals(120));

      // Add an Alchemical Pitch Flask to Tactical Belt and verify 0T Quick Action in battle
      final pitchFlask = generateConsumable(
        ConsumableType.alchemicalPitch,
        RarityLevel.common,
      );
      ship.addCargo(pitchFlask);

      session.dispatch(const VentureOutToSea());
      final roundBefore = session.battleRound;
      session.dispatch(const UseConsumableItem(0));
      // Quick Action does NOT end the player's turn (battleRound unchanged) and applies Pitch Coating!
      expect(session.battleRound, equals(roundBefore));
      expect(ship.pitchCoatingActive, isTrue);
      expect(session.usedQuickConsumableThisTurn, isTrue);
    });
  });
}
