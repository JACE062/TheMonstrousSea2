import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

void main() {
  group('Flagship Blueprints & Hardpoint Architecture Tests', () {
    test('Catalog contains all 5 ancestral blueprints with distinct hardpoint layouts', () {
      expect(FlagshipBlueprint.catalog.length, equals(5));

      final standard = FlagshipBlueprint.catalog[BlueprintId.standard]!;
      expect(standard.name, 'Blueprint: Standard');
      expect(standard.unlockCost.isFree, isTrue);
      expect(standard.hardpoints.length, equals(3));
      expect(
        standard.hardpoints.map((h) => h.type),
        containsAll([HardpointType.broadside, HardpointType.auxiliary]),
      );

      final ironclad = FlagshipBlueprint.catalog[BlueprintId.ironclad]!;
      expect(ironclad.name, 'Blueprint: Ironclad');
      expect(ironclad.unlockCost.seaGlass, equals(15));
      expect(ironclad.unlockCost.monsterBone, equals(10));
      expect(ironclad.signatureWeaponId, equals('prow_ram'));
      expect(
        ironclad.hardpoints.any((h) => h.isSignature && h.type == HardpointType.prow),
        isTrue,
      );

      final clipper = FlagshipBlueprint.catalog[BlueprintId.clipper]!;
      expect(clipper.name, 'Blueprint: Clipper');
      expect(clipper.unlockCost.seaGlass, equals(15));
      expect(clipper.unlockCost.monsterBone, equals(10));
      expect(clipper.signatureWeaponId, equals('precision_culverin'));
      expect(
        clipper.hardpoints.any((h) => h.isSignature && h.type == HardpointType.prow),
        isTrue,
      );

      final bombardier = FlagshipBlueprint.catalog[BlueprintId.bombardier]!;
      expect(bombardier.name, 'Blueprint: Bombardier');
      expect(bombardier.unlockCost.depthWroughtIron, equals(8));
      expect(bombardier.unlockCost.abyssalBarnacles, equals(6));
      expect(bombardier.signatureWeaponId, equals('heavy_mortar'));
      expect(
        bombardier.hardpoints.any((h) => h.isSignature && h.type == HardpointType.mortar),
        isTrue,
      );

      final corsair = FlagshipBlueprint.catalog[BlueprintId.corsair]!;
      expect(corsair.name, 'Blueprint: Corsair');
      expect(corsair.unlockCost.depthWroughtIron, equals(8));
      expect(corsair.unlockCost.abyssalBarnacles, equals(6));
      expect(corsair.signatureWeaponId, equals('harpoon_winch'));
      expect(
        corsair.hardpoints.any((h) => h.isSignature && h.type == HardpointType.utility),
        isTrue,
      );
    });

    test('createFlagshipFromBlueprint equips signature and doctrine loadouts', () {
      final rng = SeededGameRng(100);

      final standard = createFlagshipFromBlueprint(BlueprintId.standard, level: 1, rng: rng);
      expect(standard.shipClass, equals(ShipClass.standard));
      expect(standard.equippedWeapons.length, equals(2));
      expect(
        standard.equippedWeapons.every((w) => w.weaponType == ShipWeaponType.cannon),
        isTrue,
      );

      final ironclad = createFlagshipFromBlueprint(BlueprintId.ironclad, level: 1, rng: rng);
      expect(ironclad.shipClass, equals(ShipClass.ironclad));
      expect(ironclad.baseDmgReduction, equals(3));
      expect(
        ironclad.equippedWeapons.any((w) => w.weaponType == ShipWeaponType.prowRam),
        isTrue,
      );
      expect(
        ironclad.equippedWeapons.any((w) => w.weaponType == ShipWeaponType.cannon),
        isTrue,
      );

      final clipper = createFlagshipFromBlueprint(BlueprintId.clipper, level: 1, rng: rng);
      expect(clipper.shipClass, equals(ShipClass.clipper));
      expect(clipper.baseEvasion, equals(25));
      expect(
        clipper.equippedWeapons.any((w) => w.weaponType == ShipWeaponType.precisionCulverin),
        isTrue,
      );

      final bombardier = createFlagshipFromBlueprint(BlueprintId.bombardier, level: 1, rng: rng);
      expect(bombardier.shipClass, equals(ShipClass.bombardier));
      expect(bombardier.equippedWeapons.length, equals(3));
      expect(
        bombardier.equippedWeapons.any((w) => w.weaponType == ShipWeaponType.heavyMortar),
        isTrue,
      );

      final corsair = createFlagshipFromBlueprint(BlueprintId.corsair, level: 1, rng: rng);
      expect(corsair.shipClass, equals(ShipClass.corsair));
      expect(corsair.maxCargo, equals(25));
      expect(
        corsair.equippedWeapons.any((w) => w.weaponType == ShipWeaponType.harpoonWinch),
        isTrue,
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

      // Culverin deals 20 piercing damage
      // 50% (10) damages carapace; 50% (10) penetrates straight to monster HP
      final (result, _) = calculateAttack(ship, culverin, crab, rng, defaultCombatTraits, 100);

      expect(result.didHit, isTrue);
      expect(result.carapaceDamaged, equals(10));
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

      // Heavy Mortar deals 20 blast damage with 2.0x multiplier = 40 damage directly to carapace!
      final (result, _) = calculateAttack(ship, mortar, crab, rng, defaultCombatTraits, 100);

      expect(result.didHit, isTrue);
      expect(result.carapaceDamaged, equals(40));
      expect(crab.carapacePlating, equals(10));

      // Test frenzy disruption on Shark
      final shark = createShark(level: 1, rng: rng);
      shark.frenzyStacks = 3;
      final (sharkResult, _) = calculateAttack(ship, mortar, shark, rng, defaultCombatTraits, 100);

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
  });
}
