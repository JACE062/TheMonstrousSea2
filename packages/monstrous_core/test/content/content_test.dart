import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

void main() {
  group('Ship Weapons Tests', () {
    final rng = SeededGameRng(42);

    test('Cannon stats and formula scaling', () {
      for (var level = 1; level <= 5; level++) {
        final weapon = generateShipWeapon(
          ShipWeaponType.cannon,
          level,
          RarityLevel.common,
          rng,
        );
        expect(weapon.weaponType, equals(ShipWeaponType.cannon));
        expect(weapon.equipWeight, equals(1));
        expect(weapon.chargeTime, equals(0));
        expect(weapon.damageType, equals(DamageType.piercing));
        expect(weapon.hitModifier, equals(85));
        expect(weapon.value, equals(20 * level));
        expect(weapon.statusEffect, isNull);
        expect(weapon.damage, inInclusiveRange(8 * level, 12 * level));
      }
    });

    test('TorpedoLauncher stats and formula scaling', () {
      for (var level = 1; level <= 5; level++) {
        final weapon = generateShipWeapon(
          ShipWeaponType.torpedoLauncher,
          level,
          RarityLevel.rare,
          rng,
        );
        expect(weapon.weaponType, equals(ShipWeaponType.torpedoLauncher));
        expect(weapon.equipWeight, equals(2));
        expect(weapon.chargeTime, equals(2));
        expect(weapon.damageType, equals(DamageType.blast));
        expect(weapon.hitModifier, equals(75));
        expect(weapon.value, equals(30 * level));
        expect(weapon.statusEffect, isNull);
        expect(weapon.damage, inInclusiveRange(18 * level, 24 * level));
      }
    });

    test('BladeLauncher stats and formula scaling', () {
      for (var level = 1; level <= 5; level++) {
        final weapon = generateShipWeapon(
          ShipWeaponType.bladeLauncher,
          level,
          RarityLevel.epic,
          rng,
        );
        expect(weapon.weaponType, equals(ShipWeaponType.bladeLauncher));
        expect(weapon.equipWeight, equals(2));
        expect(weapon.chargeTime, equals(2));
        expect(weapon.damageType, equals(DamageType.slicing));
        expect(weapon.hitModifier, equals(80));
        expect(weapon.value, equals(30 * level));
        expect(weapon.statusEffect, isNull);
        expect(weapon.damage, inInclusiveRange(16 * level, 22 * level));
      }
    });

    test('LightningRailgun stats, shock damage, and stun effect', () {
      for (var level = 1; level <= 5; level++) {
        final weapon = generateShipWeapon(
          ShipWeaponType.lightningRailgun,
          level,
          RarityLevel.legendary,
          rng,
        );
        expect(weapon.weaponType, equals(ShipWeaponType.lightningRailgun));
        expect(weapon.equipWeight, equals(3));
        expect(weapon.chargeTime, equals(2));
        expect(weapon.damageType, equals(DamageType.shock));
        expect(weapon.hitModifier, equals(80));
        expect(weapon.value, equals(50 * level));
        expect(weapon.statusEffect, equals(StatusEffect.stun));
        expect(weapon.damage, inInclusiveRange(16 * level, 22 * level));
      }
    });

    test('Flamethrower stats, fire damage, and burn effect', () {
      for (var level = 1; level <= 5; level++) {
        final weapon = generateShipWeapon(
          ShipWeaponType.flamethrower,
          level,
          RarityLevel.legendary,
          rng,
        );
        expect(weapon.weaponType, equals(ShipWeaponType.flamethrower));
        expect(weapon.equipWeight, equals(3));
        expect(weapon.chargeTime, equals(2));
        expect(weapon.damageType, equals(DamageType.fire));
        expect(weapon.hitModifier, equals(85));
        expect(weapon.value, equals(50 * level));
        expect(weapon.statusEffect, equals(StatusEffect.burn));
        expect(weapon.damage, inInclusiveRange(16 * level, 22 * level));
      }
    });

    test('randomShipWeapon generates valid weapons scaled to level', () {
      for (var i = 0; i < 20; i++) {
        final weapon = randomShipWeapon(3, rng);
        expect(ShipWeaponType.values.contains(weapon.weaponType), isTrue);
        expect(weapon.hitModifier, inInclusiveRange(75, 85));
        expect(weapon.rarity, equals(RarityLevel.epic));
      }
    });

    test('rarityForLevel helper maps correctly', () {
      expect(rarityForLevel(0), equals(RarityLevel.common));
      expect(rarityForLevel(1), equals(RarityLevel.common));
      expect(rarityForLevel(2), equals(RarityLevel.rare));
      expect(rarityForLevel(3), equals(RarityLevel.epic));
      expect(rarityForLevel(4), equals(RarityLevel.legendary));
      expect(rarityForLevel(10), equals(RarityLevel.legendary));
    });
  });

  group('Monster Weapons Tests', () {
    final rng = SeededGameRng(77);

    test('Ram: charge 0, blast [8..12] + 4*(L-1), hitMod 80', () {
      for (var level = 1; level <= 5; level++) {
        final weapon = generateMonsterWeapon(MonsterWeaponType.ram, level, rng);
        expect(weapon.monsterWeaponType, equals(MonsterWeaponType.ram));
        expect(weapon.chargeTime, equals(0));
        expect(weapon.damageType, equals(DamageType.blast));
        expect(weapon.hitModifier, equals(80));
        expect(weapon.value, equals(0));
        expect(weapon.statusEffect, isNull);
        expect(
          weapon.damage,
          inInclusiveRange(8 + 4 * (level - 1), 12 + 4 * (level - 1)),
        );
      }
    });

    test('Tail: charge 1, blast [14..18] + 5*(L-1), hitMod 75', () {
      for (var level = 1; level <= 5; level++) {
        final weapon =
            generateMonsterWeapon(MonsterWeaponType.tail, level, rng);
        expect(weapon.monsterWeaponType, equals(MonsterWeaponType.tail));
        expect(weapon.chargeTime, equals(1));
        expect(weapon.damageType, equals(DamageType.blast));
        expect(weapon.hitModifier, equals(75));
        expect(weapon.statusEffect, isNull);
        expect(
          weapon.damage,
          inInclusiveRange(14 + 5 * (level - 1), 18 + 5 * (level - 1)),
        );
      }
    });

    test('Jaws: charge 1, piercing [18..22] + 6*(L-1), hitMod 75', () {
      for (var level = 1; level <= 5; level++) {
        final weapon =
            generateMonsterWeapon(MonsterWeaponType.jaws, level, rng);
        expect(weapon.monsterWeaponType, equals(MonsterWeaponType.jaws));
        expect(weapon.chargeTime, equals(1));
        expect(weapon.damageType, equals(DamageType.piercing));
        expect(weapon.hitModifier, equals(75));
        expect(weapon.statusEffect, isNull);
        expect(
          weapon.damage,
          inInclusiveRange(18 + 6 * (level - 1), 22 + 6 * (level - 1)),
        );
      }
    });

    test('Claw: charge 0, slicing [8..12] + 4*(L-1), hitMod 80', () {
      for (var level = 1; level <= 5; level++) {
        final weapon =
            generateMonsterWeapon(MonsterWeaponType.claw, level, rng);
        expect(weapon.monsterWeaponType, equals(MonsterWeaponType.claw));
        expect(weapon.chargeTime, equals(0));
        expect(weapon.damageType, equals(DamageType.slicing));
        expect(weapon.hitModifier, equals(80));
        expect(weapon.statusEffect, isNull);
        expect(
          weapon.damage,
          inInclusiveRange(8 + 4 * (level - 1), 12 + 4 * (level - 1)),
        );
      }
    });

    test('Tentacle: charge 0, blast [2..4] flat, hitMod 70', () {
      for (var level = 1; level <= 5; level++) {
        final weapon =
            generateMonsterWeapon(MonsterWeaponType.tentacle, level, rng);
        expect(weapon.monsterWeaponType, equals(MonsterWeaponType.tentacle));
        expect(weapon.chargeTime, equals(0));
        expect(weapon.damageType, equals(DamageType.blast));
        expect(weapon.hitModifier, equals(70));
        expect(weapon.statusEffect, isNull);
        expect(weapon.damage, inInclusiveRange(2, 4));
      }
    });

    test('StingingTendrils: charge 2, shock [6..10] + 3*(L-1), hitMod 70, stuns', () {
      for (var level = 1; level <= 5; level++) {
        final weapon = generateMonsterWeapon(
          MonsterWeaponType.stingingTendrils,
          level,
          rng,
        );
        expect(
          weapon.monsterWeaponType,
          equals(MonsterWeaponType.stingingTendrils),
        );
        expect(weapon.chargeTime, equals(2));
        expect(weapon.damageType, equals(DamageType.shock));
        expect(weapon.hitModifier, equals(70));
        expect(weapon.statusEffect, equals(StatusEffect.stun));
        expect(
          weapon.damage,
          inInclusiveRange(6 + 3 * (level - 1), 10 + 3 * (level - 1)),
        );
      }
    });
  });

  group('Consumables Tests', () {
    final rng = SeededGameRng(101);

    test('generateConsumable ignores legacy rarity and remains single-use', () {
      for (final type in ConsumableType.values) {
        final common = generateConsumable(type, RarityLevel.common);
        expect(common.maxUses, equals(1));
        expect(common.usesLeft, equals(1));
        expect(common.value, equals(25));
        expect(common.type, equals(type));

        final rare = generateConsumable(type, RarityLevel.rare);
        expect(rare.maxUses, equals(1));
        expect(rare.value, equals(25));

        final epic = generateConsumable(type, RarityLevel.epic);
        expect(epic.maxUses, equals(1));
        expect(epic.value, equals(25));

        final leg = generateConsumable(type, RarityLevel.legendary);
        expect(leg.maxUses, equals(1));
        expect(leg.value, equals(25));
      }
    });

    test('Unstable Tincture inflicts random status effect with 0 direct dmg', () {
      final tincture =
          generateConsumable(ConsumableType.unstableTincture, RarityLevel.common);
      final observedEffects = <StatusEffect>{};

      for (var i = 0; i < 30; i++) {
        final result = resolveConsumableEffect(tincture, rng);
        expect(result.didHit, isTrue);
        expect(result.damage, equals(0));
        expect(result.damageType, equals(DamageType.venom));
        expect(result.statusEffect, isNotNull);
        observedEffects.add(result.statusEffect!);
      }

      expect(observedEffects.contains(StatusEffect.burn), isTrue);
      expect(observedEffects.contains(StatusEffect.poison), isTrue);
      expect(observedEffects.contains(StatusEffect.stun), isTrue);
    });

    test('Blast Pack: 75% hit rate and fixed 5 damage', () {
      final pack =
          generateConsumable(ConsumableType.blastPack, RarityLevel.epic);
      var hits = 0;
      var misses = 0;

      for (var i = 0; i < 1000; i++) {
        final result = resolveConsumableEffect(pack, rng);
        expect(result.damageType, equals(DamageType.blast));
        if (result.didHit) {
          hits++;
          expect(result.damage, equals(5));
        } else {
          misses++;
          expect(result.damage, equals(0));
        }
      }

      // Expected ~75% hits (750 / 1000)
      expect(hits, inInclusiveRange(700, 800));
      expect(misses, inInclusiveRange(200, 300));
    });

    test('Chakram: 75% hit rate and fixed 5 damage', () {
      final chakram =
          generateConsumable(ConsumableType.chakram, RarityLevel.rare);
      var hits = 0;

      for (var i = 0; i < 1000; i++) {
        final result = resolveConsumableEffect(chakram, rng);
        expect(result.damageType, equals(DamageType.slicing));
        if (result.didHit) {
          hits++;
          expect(result.damage, equals(5));
        } else {
          expect(result.damage, equals(0));
        }
      }

      expect(hits, inInclusiveRange(700, 800));
    });
  });

  group('Ships Generation Tests', () {
    final rng = SeededGameRng(303);

    test('Standard Ship formulas', () {
      for (var level = 1; level <= 4; level++) {
        final ship = createStandardShip(level: level, rng: rng);
        expect(ship.shipClass, equals(ShipClass.standard));
        expect(ship.level, equals(level));
        expect(ship.maxHp, inInclusiveRange(50 + 40 * level, 50 + 60 * level));
        expect(ship.armorClass, equals(8 + 2 * level));
        expect(
          ship.maxCargo,
          inInclusiveRange(5 + 10 * level, 5 + 20 * level),
        );
        expect(ship.maxWeaponWeight, equals(7 * level));
      }
    });

    test('Freighter formulas', () {
      for (var level = 1; level <= 4; level++) {
        final ship = createFreighter(level: level, rng: rng);
        expect(ship.shipClass, equals(ShipClass.freighter));
        expect(ship.level, equals(level));
        expect(ship.maxHp, inInclusiveRange(25 + 80 * level, 25 + 120 * level));
        expect(ship.armorClass, equals(6 + 2 * level));
        expect(
          ship.maxCargo,
          inInclusiveRange(20 * level, 40 * level),
        );
        expect(ship.maxWeaponWeight, equals(3 * level));
      }
    });

    test('Ironclad formulas', () {
      for (var level = 1; level <= 4; level++) {
        final ship = createIronclad(level: level, rng: rng);
        expect(ship.shipClass, equals(ShipClass.ironclad));
        expect(ship.level, equals(level));
        expect(ship.maxHp, inInclusiveRange(25 + 65 * level, 25 + 85 * level));
        expect(ship.armorClass, equals(10 + 2 * level));
        expect(ship.maxCargo, inInclusiveRange(5 + 5 * level, 5 + 7 * level));
        expect(ship.maxWeaponWeight, equals(10 * level));
        expect(ship.baseDmgReduction, equals(3 * level));
        expect(ship.dmgReductionMod, equals(2 * level));
      }
    });

    test('Corvette formulas and evasion cap', () {
      for (var level = 1; level <= 10; level++) {
        final ship = createCorvette(level: level, rng: rng);
        expect(ship.shipClass, equals(ShipClass.corvette));
        expect(ship.level, equals(level));
        expect(ship.maxHp, inInclusiveRange(40 + 30 * level, 40 + 50 * level));
        expect(ship.armorClass, equals(4 + 2 * level));
        expect(ship.maxCargo, inInclusiveRange(5 + 5 * level, 5 + 15 * level));
        expect(ship.maxWeaponWeight, equals(5 * level));
        expect(ship.baseEvasion, inInclusiveRange(0, 50));
        expect(ship.baseEvasion, equals((5 + 5 * level).clamp(0, 50)));
      }
    });

    test('Flying Dutchman (Davy Jones special) stats and loadout', () {
      final dutchman = createFlyingDutchman();
      expect(dutchman.name, equals('Flying Dutchman'));
      expect(dutchman.level, equals(4));
      expect(dutchman.shipClass, equals(ShipClass.ironclad));
      expect(dutchman.maxHp, equals(1600));
      expect(dutchman.currentHp, equals(1600));
      expect(dutchman.armorClass, equals(18));
      expect(dutchman.maxCargo, equals(300));
      expect(dutchman.maxWeaponWeight, equals(50));
      expect(dutchman.currentWeaponWeight, lessThanOrEqualTo(50));
      expect(dutchman.currentWeaponWeight, equals(32));

      // 8 Cannons + 6 Blade Launchers + 2 Railguns + 2 Flamethrowers = 18 weapons
      expect(dutchman.equippedWeapons.length, equals(18));
      for (final weapon in dutchman.equippedWeapons) {
        expect(weapon.rarity, equals(RarityLevel.legendary));
      }
    });

    test('createShip dispatcher creates correct subclasses', () {
      for (final shipClass in ShipClass.values) {
        final ship = createShip(shipClass, level: 2, rng: rng);
        expect(ship.shipClass, equals(shipClass));
      }
    });
  });

  group('Monsters Generation Tests', () {
    final rng = SeededGameRng(505);

    test('Shark: HP 40*L, AC 6 + 2*L, weapons Ram and Jaws', () {
      for (var level = 1; level <= 4; level++) {
        final shark = createShark(level: level, rng: rng);
        expect(shark.species, equals(MonsterSpecies.shark));
        expect(shark.level, equals(level));
        expect(shark.maxHp, equals(40 * level));
        expect(shark.armorClass, equals(6 + 2 * level));
        expect(shark.frenzyStacks, equals(0));
        final weaponTypes =
            shark.usableWeapons.map((w) => w.monsterWeaponType).toList();
        expect(weaponTypes, equals([MonsterWeaponType.ram, MonsterWeaponType.jaws]));
      }
    });

    test('Serpent: HP 40*L, AC 6 + 2*L, weapons Ram and Tail, evasion 20', () {
      for (var level = 1; level <= 4; level++) {
        final serpent = createSerpent(level: level, rng: rng);
        expect(serpent.species, equals(MonsterSpecies.serpent));
        expect(serpent.level, equals(level));
        expect(serpent.maxHp, equals(40 * level));
        expect(serpent.armorClass, equals(6 + 2 * level));
        expect(serpent.evasion, equals(20));
        final weaponTypes =
            serpent.usableWeapons.map((w) => w.monsterWeaponType).toList();
        expect(weaponTypes, equals([MonsterWeaponType.ram, MonsterWeaponType.tail]));
      }
    });

    test('Jellyfish: HP 30*L, AC 4 + 2*L, weapons Ram and Stinging Tendrils', () {
      for (var level = 1; level <= 4; level++) {
        final jellyfish = createJellyfish(level: level, rng: rng);
        expect(jellyfish.species, equals(MonsterSpecies.jellyfish));
        expect(jellyfish.level, equals(level));
        expect(jellyfish.maxHp, equals(30 * level));
        expect(jellyfish.armorClass, equals(4 + 2 * level));
        final weaponTypes =
            jellyfish.usableWeapons.map((w) => w.monsterWeaponType).toList();
        expect(
          weaponTypes,
          equals([MonsterWeaponType.ram, MonsterWeaponType.stingingTendrils]),
        );
      }
    });

    test('Squid: HP 45*L, AC 6 + 2*L, tentacles 5*L, obscuredAcMod 20', () {
      for (var level = 1; level <= 4; level++) {
        final squid = createSquid(level: level, rng: rng);
        expect(squid.species, equals(MonsterSpecies.squid));
        expect(squid.level, equals(level));
        expect(squid.maxHp, equals(45 * level));
        expect(squid.armorClass, equals(6 + 2 * level));
        expect(squid.numberOfTentacles, equals(5 * level));
        expect(squid.obscuredAcMod, equals(20));
        final weaponTypes =
            squid.usableWeapons.map((w) => w.monsterWeaponType).toList();
        expect(
          weaponTypes,
          equals([MonsterWeaponType.ram, MonsterWeaponType.tentacle]),
        );
      }
    });

    test('Crustacean: HP 45*L, Carapace 20*L, Claw only at level >= 2', () {
      final crustacean1 = createCrustacean(level: 1, rng: rng);
      expect(crustacean1.species, equals(MonsterSpecies.crustacean));
      expect(crustacean1.maxHp, equals(45));
      expect(crustacean1.carapacePlating, equals(20));
      expect(crustacean1.armorClass, equals(12));
      expect(crustacean1.usableWeapons.length, equals(1));
      expect(
        crustacean1.usableWeapons.first.monsterWeaponType,
        equals(MonsterWeaponType.ram),
      );

      final crustacean2 = createCrustacean(level: 2, rng: rng);
      expect(crustacean2.maxHp, equals(90));
      expect(crustacean2.carapacePlating, equals(40));
      expect(crustacean2.armorClass, equals(14));
      expect(crustacean2.usableWeapons.length, equals(2));
      final weaponTypes =
          crustacean2.usableWeapons.map((w) => w.monsterWeaponType).toList();
      expect(weaponTypes, equals([MonsterWeaponType.ram, MonsterWeaponType.claw]));
    });

    test('The Kraken: lvl 5, 300 HP, 18 AC, 25 tentacles, obscuredAcMod 25', () {
      final kraken = createKraken();
      expect(kraken.name, equals('The Kraken'));
      expect(kraken.level, equals(5));
      expect(kraken.maxHp, equals(300));
      expect(kraken.armorClass, equals(18));
      expect(kraken.numberOfTentacles, equals(25));
      expect(kraken.obscuredAcMod, equals(25));
      final weaponTypes =
          kraken.usableWeapons.map((w) => w.monsterWeaponType).toList();
      expect(
        weaponTypes,
        equals([MonsterWeaponType.ram, MonsterWeaponType.tentacle]),
      );
    });

    test('randomMonster excludes Crustacean at level 1 and allows at level >= 2', () {
      for (var i = 0; i < 50; i++) {
        final monsterLvl1 = randomMonster(level: 1, rng: rng);
        expect(monsterLvl1.species, isNot(equals(MonsterSpecies.crustacean)));
      }

      var generatedCrustaceanAtLvl2 = false;
      for (var i = 0; i < 100; i++) {
        final monster = randomMonster(level: 2, rng: rng);
        if (monster.species == MonsterSpecies.crustacean) {
          generatedCrustaceanAtLvl2 = true;
          break;
        }
      }
      expect(generatedCrustaceanAtLvl2, isTrue);
    });
  });

  group('NameForge Procedural Generation Tests', () {
    test('deterministic generation with identical seeds', () {
      final rng1 = SeededGameRng(999);
      final rng2 = SeededGameRng(999);

      for (var i = 0; i < 20; i++) {
        expect(
          NameForge.generateCaptainName(rng1, includeEpithet: true),
          equals(NameForge.generateCaptainName(rng2, includeEpithet: true)),
        );
        for (final shipClass in ShipClass.values) {
          expect(
            NameForge.generateShipName(shipClass, rng1),
            equals(NameForge.generateShipName(shipClass, rng2)),
          );
        }
        for (final species in MonsterSpecies.values) {
          expect(
            NameForge.generateMonsterName(species, rng1),
            equals(NameForge.generateMonsterName(species, rng2)),
          );
        }
      }
    });

    test('Captain names have valid formatting', () {
      final rng = SeededGameRng(123);
      final plain = NameForge.generateCaptainName(rng, includeEpithet: false);
      expect(plain.split(' ').length, greaterThanOrEqualTo(2));

      final withEpithet =
          NameForge.generateCaptainName(rng, includeEpithet: true);
      expect(withEpithet.contains(','), isTrue);
    });

    test('Ship names match class adjective tables', () {
      final rng = SeededGameRng(456);
      for (final shipClass in ShipClass.values) {
        final name = NameForge.generateShipName(shipClass, rng);
        expect(name.endsWith(shipClass.displayName), isTrue);
      }
    });

    test('Monster names generated for all species are non-empty', () {
      final rng = SeededGameRng(789);
      for (final species in MonsterSpecies.values) {
        final name = NameForge.generateMonsterName(species, rng);
        expect(name, isNotEmpty);
      }
      expect(NameForge.generateKrakenTitle(rng), isNotEmpty);
    });
  });
}
