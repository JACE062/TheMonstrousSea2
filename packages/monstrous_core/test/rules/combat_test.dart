import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

class QueueGameRng implements GameRng {
  QueueGameRng({
    List<int>? d20Rolls,
    List<int>? d100Rolls,
    List<int>? nextIntValues,
  })  : _d20Rolls = List.of(d20Rolls ?? []),
        _d100Rolls = List.of(d100Rolls ?? []),
        _nextIntValues = List.of(nextIntValues ?? []);

  final List<int> _d20Rolls;
  final List<int> _d100Rolls;
  final List<int> _nextIntValues;

  int defaultD20 = 10;
  int defaultD100 = 50;
  int defaultNextInt = 0;

  @override
  int d20() => _d20Rolls.isNotEmpty ? _d20Rolls.removeAt(0) : defaultD20;

  @override
  int d100() => _d100Rolls.isNotEmpty ? _d100Rolls.removeAt(0) : defaultD100;

  @override
  int nextInt(int maxExclusive) =>
      _nextIntValues.isNotEmpty ? _nextIntValues.removeAt(0) : defaultNextInt;

  @override
  int nextIntRange(int minInclusive, int maxInclusive) => minInclusive;

  @override
  double nextDouble() => 0.5;

  @override
  int d(int n) => 1;
}

ShipState createTestShip({
  ShipClass shipClass = ShipClass.standard,
  int level = 1,
  int maxHp = 100,
  int armorClass = 10,
  int baseEvasion = 0,
  int baseDmgReduction = 0,
  int dmgReductionMod = 0,
  List<ShipWeapon>? weapons,
}) {
  return ShipState(
    id: 'test-ship',
    name: 'HMS Vanguard',
    level: level,
    maxHp: maxHp,
    armorClass: armorClass,
    shipClass: shipClass,
    maxCargo: 20,
    maxWeaponWeight: 20,
    baseEvasion: baseEvasion,
    baseDmgReduction: baseDmgReduction,
    dmgReductionMod: dmgReductionMod,
    equippedWeapons: weapons,
  );
}

MonsterState createTestMonster({
  MonsterSpecies species = MonsterSpecies.shark,
  int level = 1,
  int maxHp = 100,
  int armorClass = 10,
  bool isObscured = false,
  int obscuredAcMod = 4,
  int numberOfTentacles = 0,
  List<MonsterWeapon>? weapons,
}) {
  return MonsterState(
    id: 'test-monster',
    name: 'Leviathan',
    level: level,
    maxHp: maxHp,
    armorClass: armorClass,
    species: species,
    isObscured: isObscured,
    obscuredAcMod: obscuredAcMod,
    numberOfTentacles: numberOfTentacles,
    usableWeapons: weapons,
  );
}

ShipWeapon createTestShipWeapon({
  String id = 'w-1',
  String name = 'Heavy Cannon',
  ShipWeaponType type = ShipWeaponType.cannon,
  int damage = 20,
  int hitModifier = 80,
  int chargeTime = 0,
  int chargeCountdown = 0,
  DamageType damageType = DamageType.piercing,
  StatusEffect? statusEffect,
  int equipWeight = 1,
}) {
  return ShipWeapon(
    id: id,
    name: name,
    description: 'A reliable naval cannon',
    value: 100,
    rarity: RarityLevel.common,
    damage: damage,
    hitModifier: hitModifier,
    chargeTime: chargeTime,
    chargeCountdown: chargeCountdown,
    damageType: damageType,
    statusEffect: statusEffect,
    equipWeight: equipWeight,
    weaponType: type,
  );
}

MonsterWeapon createTestMonsterWeapon({
  String id = 'mw-1',
  String name = 'Razor Jaws',
  MonsterWeaponType type = MonsterWeaponType.jaws,
  int damage = 15,
  int hitModifier = 80,
  int chargeTime = 1,
  int chargeCountdown = 0,
  DamageType damageType = DamageType.piercing,
  StatusEffect? statusEffect,
}) {
  return MonsterWeapon(
    id: id,
    name: name,
    description: 'Crushing serrated teeth',
    rarity: RarityLevel.common,
    damage: damage,
    hitModifier: hitModifier,
    chargeTime: chargeTime,
    chargeCountdown: chargeCountdown,
    damageType: damageType,
    statusEffect: statusEffect,
    monsterWeaponType: type,
  );
}

void main() {
  group('calculateAttack Tests', () {
    test('d100 roll > hitChance results in miss', () {
      final ship = createTestShip();
      final weapon = createTestShipWeapon(hitModifier: 75);
      final monster = createTestMonster();

      // d100 = 85 > 75 -> miss!
      final rng = QueueGameRng(d100Rolls: [85]);
      final (result, events) = calculateAttack(ship, weapon, monster, rng);

      expect(result.didHit, isFalse);
      expect(result.damage, equals(0));
      expect(monster.currentHp, equals(100));

      expect(events.length, equals(2));
      expect(events[0], isA<AttackAttempted>());
      final attempted = events[0] as AttackAttempted;
      expect(attempted.roll, equals(85));
      expect(attempted.targetAc, equals(75));

      expect(events[1], isA<AttackMissed>());
      final missed = events[1] as AttackMissed;
      expect(missed.targetName, equals(monster.name));
    });

    test('d100 roll <= hitChance results in hit dealing damage', () {
      final ship = createTestShip();
      final weapon = createTestShipWeapon(damage: 25, hitModifier: 80);
      final monster = createTestMonster();

      // d100 = 40 <= 80 -> hit!
      final rng = QueueGameRng(d100Rolls: [40]);
      final (result, events) = calculateAttack(ship, weapon, monster, rng);

      expect(result.didHit, isTrue);
      expect(result.damage, equals(25));
      expect(monster.currentHp, equals(75));

      expect(events.length, equals(2));
      expect(events[0], isA<AttackAttempted>());
      expect(events[1], isA<AttackHit>());
      final hit = events[1] as AttackHit;
      expect(hit.damage, equals(25));
      expect(hit.remainingHp, equals(75));
    });

    test('obscured monster reduces hitChance', () {
      final ship = createTestShip();
      final weapon = createTestShipWeapon(hitModifier: 80);
      // Accuracy = 80 - 20 (obscured) = 60%
      final monster = createTestMonster(
        isObscured: true,
        obscuredAcMod: 20,
      );

      // d100 = 70 -> misses 60% hitChance
      final rng = QueueGameRng(d100Rolls: [70]);
      final (result, events) = calculateAttack(ship, weapon, monster, rng);

      expect(result.didHit, isFalse);
      final attempted = events[0] as AttackAttempted;
      expect(attempted.targetAc, equals(60));
    });

    test('applying status effects on hit', () {
      final ship = createTestShip();
      final weapon = createTestShipWeapon(
        statusEffect: StatusEffect.burn,
        hitModifier: 80,
      );
      final monster = createTestMonster();

      final rng = QueueGameRng(d100Rolls: [30]);
      final (result, _) = calculateAttack(ship, weapon, monster, rng);

      expect(result.didHit, isTrue);
      expect(monster.hasStatus(StatusEffect.burn), isTrue);
    });

    test('defeating combatant emits CombatantDefeated', () {
      final ship = createTestShip();
      final weapon = createTestShipWeapon(damage: 100, hitModifier: 80);
      final monster = createTestMonster(maxHp: 50);

      final rng = QueueGameRng(d100Rolls: [20]);
      final (_, events) = calculateAttack(ship, weapon, monster, rng);

      expect(monster.isAlive, isFalse);
      expect(events.any((e) => e is CombatantDefeated), isTrue);
    });
  });

  group('Ironclad FortifyTrait Tests', () {
    test('mitigates incoming hit damage and emits DamageReduced', () {
      final ironclad = createTestShip(
        shipClass: ShipClass.ironclad,
        baseDmgReduction: 6,
      );
      final monster = createTestMonster();
      final monsterWeapon = createTestMonsterWeapon(damage: 20, hitModifier: 80);

      const traits = [FortifyTrait()];
      // d100 = 50 <= 80 -> hit
      final rng = QueueGameRng(d100Rolls: [50]);
      final (result, events) =
          calculateAttack(monster, monsterWeapon, ironclad, rng, traits);

      expect(result.didHit, isTrue);
      expect(result.nullifiedDamage, equals(6));
      expect(ironclad.currentHp, equals(100 - (20 - 6)));

      final reducedEvent =
          events.firstWhere((e) => e is DamageReduced) as DamageReduced;
      expect(reducedEvent.shipName, equals(ironclad.name));
      expect(reducedEvent.nullifiedAmount, equals(6));

      final hitEvent = events.firstWhere((e) => e is AttackHit) as AttackHit;
      expect(hitEvent.damage, equals(14));
    });

    test('completely nullifies damage when reduction exceeds attack damage', () {
      final ironclad = createTestShip(
        shipClass: ShipClass.ironclad,
        baseDmgReduction: 15,
      );
      final monster = createTestMonster();
      final monsterWeapon = createTestMonsterWeapon(damage: 10, hitModifier: 80);

      const traits = [FortifyTrait()];
      final rng = QueueGameRng(d100Rolls: [50]);
      final (result, _) =
          calculateAttack(monster, monsterWeapon, ironclad, rng, traits);

      expect(result.nullifiedDamage, equals(10));
      expect(ironclad.currentHp, equals(100)); // took 0 damage
    });

    test('fortify special action stacks damage reduction', () {
      final ironclad = createTestShip(
        shipClass: ShipClass.ironclad,
        baseDmgReduction: 4,
        dmgReductionMod: 3,
      );
      const trait = FortifyTrait();
      final rng = QueueGameRng();

      trait.executeSpecialAction(ironclad, createTestMonster(), rng);
      expect(ironclad.currentDmgReduction, equals(7));

      trait.executeSpecialAction(ironclad, createTestMonster(), rng);
      expect(ironclad.currentDmgReduction, equals(10));
    });
  });

  group('Corvette EvasionTrait Tests', () {
    test('successfully evades attack when d100 <= currentEvasion', () {
      final corvette = createTestShip(
        shipClass: ShipClass.corvette,
        baseEvasion: 25,
      );
      final monster = createTestMonster();
      final monsterWeapon = createTestMonsterWeapon(damage: 30, hitModifier: 80);

      const traits = [EvasionTrait()];
      // 1st d100 = 50 (hit), 2nd d100 = 20 (<= 25 evasion)
      final rng = QueueGameRng(d100Rolls: [50, 20]);
      final (result, events) =
          calculateAttack(monster, monsterWeapon, corvette, rng, traits);

      expect(result.didHit, isTrue);
      expect(result.wasEvaded, isTrue);
      expect(corvette.currentHp, equals(100)); // undamaged

      expect(events.any((e) => e is AttackEvaded), isTrue);
      final evadedEvent =
          events.firstWhere((e) => e is AttackEvaded) as AttackEvaded;
      expect(evadedEvent.wasManeuver, isFalse);
    });

    test('evasive maneuvers doubles evasion and resets after dodge', () {
      final corvette = createTestShip(
        shipClass: ShipClass.corvette,
        baseEvasion: 20,
      );
      const trait = EvasionTrait();
      final rng = QueueGameRng();

      trait.executeSpecialAction(corvette, createTestMonster(), rng);
      expect(corvette.currentEvasion, equals(40));

      final monster = createTestMonster();
      final monsterWeapon = createTestMonsterWeapon(damage: 30, hitModifier: 80);

      // 1st d100 = 50 (hit), 2nd d100 = 35 (<= 40, dodged thanks to maneuver!)
      final attackRng = QueueGameRng(d100Rolls: [50, 35]);
      final (result, events) =
          calculateAttack(monster, monsterWeapon, corvette, attackRng, [trait]);

      expect(result.wasEvaded, isTrue);
      final evadedEvent =
          events.firstWhere((e) => e is AttackEvaded) as AttackEvaded;
      expect(evadedEvent.wasManeuver, isTrue);

      // Evasion resets to base after dodging
      expect(corvette.currentEvasion, equals(20));
    });
  });

  group('Squid & Kraken TentacleTrait Tests', () {
    test('slicing damage severs tentacles based on damage', () {
      final squid = createTestMonster(
        species: MonsterSpecies.squid,
        numberOfTentacles: 10,
      );
      final ship = createTestShip();
      // 15 slicing damage -> ceil(15 / 10) = 2 tentacles severed
      final bladeLauncher = createTestShipWeapon(
        damage: 15,
        damageType: DamageType.slicing,
        hitModifier: 80,
      );

      const traits = [TentacleTrait()];
      final rng = QueueGameRng(d100Rolls: [50]);
      final (result, events) =
          calculateAttack(ship, bladeLauncher, squid, rng, traits);

      expect(result.tentaclesSevered, equals(2));
      expect(squid.numberOfTentacles, equals(8));

      final severedEvent =
          events.firstWhere((e) => e is TentaclesSevered) as TentaclesSevered;
      expect(severedEvent.countSevered, equals(2));
      expect(severedEvent.remainingTentacles, equals(8));
    });

    test('slicing damage severs tentacles on The Kraken as well', () {
      final kraken = createTestMonster(
        species: MonsterSpecies.kraken,
        numberOfTentacles: 25,
      );
      final ship = createTestShip();
      final bladeLauncher = createTestShipWeapon(
        damage: 30,
        damageType: DamageType.slicing,
        hitModifier: 80,
      );

      const traits = [TentacleTrait()];
      final rng = QueueGameRng(d100Rolls: [50]);
      final (result, _) =
          calculateAttack(ship, bladeLauncher, kraken, rng, traits);

      expect(result.tentaclesSevered, equals(3));
      expect(kraken.numberOfTentacles, equals(22));
    });

    test('non-slicing damage does not sever tentacles', () {
      final squid = createTestMonster(
        species: MonsterSpecies.squid,
        numberOfTentacles: 10,
      );
      final ship = createTestShip();
      final cannon = createTestShipWeapon(
        damage: 30,
        damageType: DamageType.piercing,
        hitModifier: 80,
      );

      const traits = [TentacleTrait()];
      final rng = QueueGameRng(d100Rolls: [50]);
      final (result, events) =
          calculateAttack(ship, cannon, squid, rng, traits);

      expect(result.tentaclesSevered, equals(0));
      expect(squid.numberOfTentacles, equals(10));
      expect(events.any((e) => e is TentaclesSevered), isFalse);
    });
  });

  group('Crustacean CarapaceTrait Tests', () {
    test('absorbs piercing/kinetic damage point-for-point and emits CarapaceAbsorbed', () {
      final crustacean = createTestMonster(species: MonsterSpecies.crustacean)
        ..carapacePlating = 50
        ..maxCarapace = 50;
      final ship = createTestShip();
      final cannon = createTestShipWeapon(
        damage: 20,
        damageType: DamageType.piercing,
        hitModifier: 80,
      );

      const traits = [CarapaceTrait()];
      final rng = QueueGameRng(d100Rolls: [50]);
      final (result, events) =
          calculateAttack(ship, cannon, crustacean, rng, traits);

      expect(result.didHit, isTrue);
      expect(result.carapaceAbsorbed, equals(20));
      expect(result.nullifiedDamage, equals(20));
      expect(crustacean.currentHp, equals(100)); // absorbed by shell
      expect(crustacean.carapacePlating, equals(30)); // 50 - 20 absorbed
      expect(result.wasCarapaceShattered, isFalse);

      expect(events.any((e) => e is CarapaceAbsorbed), isTrue);
      final absorbedEvent =
          events.firstWhere((e) => e is CarapaceAbsorbed) as CarapaceAbsorbed;
      expect(absorbedEvent.absorbedAmount, equals(20));
    });

    test('blast damage reduces carapace plating and emits CarapaceDamaged', () {
      final crustacean = createTestMonster(species: MonsterSpecies.crustacean)
        ..carapacePlating = 50
        ..maxCarapace = 50;
      final ship = createTestShip();
      final torpedo = createTestShipWeapon(
        damage: 30,
        damageType: DamageType.blast,
        hitModifier: 80,
      );

      const traits = [CarapaceTrait()];
      final rng = QueueGameRng(d100Rolls: [50]);
      final (result, events) =
          calculateAttack(ship, torpedo, crustacean, rng, traits);

      expect(result.didHit, isTrue);
      // 30 * 1.5 = 45 bonus blast damage against carapace
      expect(result.carapaceDamaged, equals(45));
      expect(crustacean.carapacePlating, equals(5)); // 50 - 45
      expect(result.wasCarapaceShattered, isFalse);
      expect(crustacean.currentHp, equals(100)); // absorbed into plating

      expect(events.any((e) => e is CarapaceDamaged), isTrue);
      final damagedEvent =
          events.firstWhere((e) => e is CarapaceDamaged) as CarapaceDamaged;
      expect(damagedEvent.damageDealt, equals(45));
      expect(damagedEvent.remainingCarapace, equals(5));
      expect(damagedEvent.wasShattered, isFalse);
    });

    test('blast damage completely shatters carapace when damage exceeds plating', () {
      final crustacean = createTestMonster(species: MonsterSpecies.crustacean)
        ..carapacePlating = 20
        ..maxCarapace = 50;
      final ship = createTestShip();
      final torpedo = createTestShipWeapon(
        damage: 35,
        damageType: DamageType.blast,
        hitModifier: 80,
      );

      const traits = [CarapaceTrait()];
      final rng = QueueGameRng(d100Rolls: [50]);
      final (result, events) =
          calculateAttack(ship, torpedo, crustacean, rng, traits);

      expect(result.didHit, isTrue);
      expect(result.carapaceDamaged, equals(20));
      expect(crustacean.carapacePlating, equals(0)); // shattered!
      expect(result.wasCarapaceShattered, isTrue);
      // 20 absorbed by plating, remaining 15 penetrates to HP!
      expect(crustacean.currentHp, equals(100 - 15));

      final damagedEvent =
          events.firstWhere((e) => e is CarapaceDamaged) as CarapaceDamaged;
      expect(damagedEvent.wasShattered, isTrue);
    });

    test('fire damage bypasses carapace completely', () {
      final crustacean = createTestMonster(species: MonsterSpecies.crustacean)
        ..carapacePlating = 50
        ..maxCarapace = 50;
      final ship = createTestShip();
      final flamethrower = createTestShipWeapon(
        damage: 25,
        damageType: DamageType.fire,
        hitModifier: 80,
      );

      const traits = [CarapaceTrait()];
      final rng = QueueGameRng(d100Rolls: [50]);
      final (result, _) =
          calculateAttack(ship, flamethrower, crustacean, rng, traits);

      expect(result.didHit, isTrue);
      expect(result.nullifiedDamage, equals(0)); // 0 absorbed!
      expect(crustacean.currentHp, equals(100 - 25)); // full damage directly to HP
      expect(crustacean.carapacePlating, equals(50));
    });
  });

  group('Shark FrenzyTrait Tests', () {
    test('shock damage disrupts shark frenzy and resets stacks', () {
      final shark = createTestMonster(species: MonsterSpecies.shark)
        ..frenzyStacks = 2;
      final ship = createTestShip();
      final railgun = createTestShipWeapon(
        damage: 20,
        damageType: DamageType.shock,
        hitModifier: 80,
      );

      const traits = [SharkFrenzyTrait()];
      final rng = QueueGameRng(d100Rolls: [50]);
      final (result, events) =
          calculateAttack(ship, railgun, shark, rng, traits);

      expect(result.didHit, isTrue);
      expect(result.disruptedFrenzy, isTrue);
      expect(shark.frenzyStacks, equals(0));
      expect(events.any((e) => e is SharkFrenzyDisrupted), isTrue);
    });
  });

  group('executeShipWeaponVolley Tests', () {
    test('fires all ready weapons of matching type and resets charges', () {
      final w1 = createTestShipWeapon(
        id: 'c-1',
        type: ShipWeaponType.cannon,
        damage: 10,
        chargeTime: 0,
        chargeCountdown: 0,
      );
      final w2 = createTestShipWeapon(
        id: 'c-2',
        type: ShipWeaponType.cannon,
        damage: 15,
        chargeTime: 1,
        chargeCountdown: 0,
      );
      final w3 = createTestShipWeapon(
        id: 'c-3',
        type: ShipWeaponType.cannon,
        damage: 20,
        chargeTime: 2,
        chargeCountdown: 1, // On cooldown!
      );
      final ship = createTestShip(weapons: [w1, w2, w3]);
      final monster = createTestMonster(maxHp: 100, armorClass: 8);

      final rng = QueueGameRng(d100Rolls: [50, 50]);
      final events =
          executeShipWeaponVolley(ship, ShipWeaponType.cannon, monster, rng);

      // w1 and w2 fired; w3 did not
      expect(w1.chargeCountdown, equals(0));
      expect(w2.chargeCountdown, equals(1)); // reset to chargeTime
      expect(w3.chargeCountdown, equals(1)); // remained on cooldown

      expect(monster.currentHp, equals(100 - (10 + 15)));
      final hitEvents = events.whereType<AttackHit>().toList();
      expect(hitEvents.length, equals(2));
    });

    test('stops volley immediately if monster dies mid-volley', () {
      final w1 = createTestShipWeapon(
        id: 'c-1',
        type: ShipWeaponType.cannon,
        damage: 50,
      );
      final w2 = createTestShipWeapon(
        id: 'c-2',
        type: ShipWeaponType.cannon,
        damage: 50,
      );
      final ship = createTestShip(weapons: [w1, w2]);
      final monster = createTestMonster(maxHp: 40, armorClass: 8);

      final rng = QueueGameRng(d100Rolls: [50]);
      final events =
          executeShipWeaponVolley(ship, ShipWeaponType.cannon, monster, rng);

      expect(monster.isAlive, isFalse);
      final hitEvents = events.whereType<AttackHit>().toList();
      expect(hitEvents.length, equals(1)); // only 1 shot fired
      expect(events.any((e) => e is CombatantDefeated), isTrue);
    });
  });

  group('updateStatusEffects Tests', () {
    test('BURN deals 5 * difficulty damage and wears off on d100 > 75', () {
      final monster = createTestMonster(maxHp: 100);
      monster.addStatus(StatusEffect.burn);

      // Roll 80 (> 75) -> wears off!
      final rng = QueueGameRng(d100Rolls: [80]);
      final (canAct, events) = updateStatusEffects(monster, 2, rng);

      expect(canAct, isTrue);
      expect(monster.currentHp, equals(90)); // took 5 * 2 = 10 damage
      expect(monster.hasStatus(StatusEffect.burn), isFalse);

      final ticked = events.firstWhere((e) => e is StatusEffectTicked) as StatusEffectTicked;
      expect(ticked.effectName, equals('Burn'));
      expect(ticked.damage, equals(10));
      expect(ticked.woreOff, isTrue);
    });

    test('BURN persists on d100 <= 75', () {
      final monster = createTestMonster(maxHp: 100);
      monster.addStatus(StatusEffect.burn);

      // Roll 50 (<= 75) -> persists
      final rng = QueueGameRng(d100Rolls: [50]);
      final (canAct, events) = updateStatusEffects(monster, 3, rng);

      expect(canAct, isTrue);
      expect(monster.currentHp, equals(85)); // took 5 * 3 = 15 damage
      expect(monster.hasStatus(StatusEffect.burn), isTrue);

      final ticked = events.firstWhere((e) => e is StatusEffectTicked) as StatusEffectTicked;
      expect(ticked.woreOff, isFalse);
    });

    test('STUN clears for ship after 1 turn and prevents action', () {
      final ship = createTestShip();
      ship.addStatus(StatusEffect.stun);

      final rng = QueueGameRng();
      final (canAct, events) = updateStatusEffects(ship, 1, rng);

      expect(canAct, isFalse);
      expect(ship.hasStatus(StatusEffect.stun), isFalse); // Cleared!

      final ticked = events.firstWhere((e) => e is StatusEffectTicked) as StatusEffectTicked;
      expect(ticked.effectName, equals('Stun'));
      expect(ticked.damage, equals(0));
      expect(ticked.woreOff, isTrue);
    });

    test('STUN on monster wears off on d100 > 50 and allows action', () {
      final monster = createTestMonster();
      monster.addStatus(StatusEffect.stun);

      // Roll 60 (> 25) -> wears off after denying action this turn
      final rng = QueueGameRng(d100Rolls: [60]);
      final (canAct, events) = updateStatusEffects(monster, 1, rng);

      expect(canAct, isFalse); // Stun denies action this turn!
      expect(monster.hasStatus(StatusEffect.stun), isFalse); // But clears for next turn

      final ticked = events.firstWhere((e) => e is StatusEffectTicked) as StatusEffectTicked;
      expect(ticked.woreOff, isTrue);
    });

    test('STUN on monster persists on low d100 and denies action', () {
      final monster = createTestMonster();
      monster.addStatus(StatusEffect.stun);

      // Roll 20 (<= 25) -> remains stunned
      final rng = QueueGameRng(d100Rolls: [20]);
      final (canAct, events) = updateStatusEffects(monster, 1, rng);

      expect(canAct, isFalse);
      expect(monster.hasStatus(StatusEffect.stun), isTrue);

      final ticked = events.firstWhere((e) => e is StatusEffectTicked) as StatusEffectTicked;
      expect(ticked.woreOff, isFalse);
    });

    test('Status effect fatality emits CombatantDefeated and prevents action', () {
      final monster = createTestMonster(maxHp: 8);
      monster.addStatus(StatusEffect.burn);

      final rng = QueueGameRng(d100Rolls: [50]);
      final (canAct, events) = updateStatusEffects(monster, 2, rng); // 10 damage > 8 hp

      expect(canAct, isFalse);
      expect(monster.isAlive, isFalse);
      expect(events.any((e) => e is CombatantDefeated), isTrue);
    });

    test('Fortify boost increases damage reduction and resetCombatBoosts restores base stats', () {
      final ship = createTestShip(
        shipClass: ShipClass.ironclad,
        baseDmgReduction: 5,
        dmgReductionMod: 3,
      );
      const trait = FortifyTrait();
      final dummyMonster = createTestMonster();
      final rng = QueueGameRng();

      expect(ship.currentDmgReduction, 5);
      trait.executeSpecialAction(ship, dummyMonster, rng);
      expect(ship.currentDmgReduction, 8);
      trait.executeSpecialAction(ship, dummyMonster, rng);
      expect(ship.currentDmgReduction, 11);

      // Post-combat reset
      ship.resetCombatBoosts();
      expect(ship.currentDmgReduction, 5);
    });
  });

  group('Combat Range Bands & Hardpoint Mounts', () {
    test('CombatRange navigation closer and farther behave correctly', () {
      expect(CombatRange.long.closer, CombatRange.medium);
      expect(CombatRange.medium.closer, CombatRange.short);
      expect(CombatRange.short.closer, CombatRange.short);

      expect(CombatRange.short.farther, CombatRange.medium);
      expect(CombatRange.medium.farther, CombatRange.long);
      expect(CombatRange.long.farther, CombatRange.long);
    });

    test('Standard Cannon suffers -15% accuracy at Long Range', () {
      final ship = createTestShip();
      final monster = createTestMonster();
      final cannon = createTestShipWeapon(type: ShipWeaponType.cannon, hitModifier: 80);

      final medChance = calculateHitChance(ship, cannon, monster, range: CombatRange.medium);
      final longChance = calculateHitChance(ship, cannon, monster, range: CombatRange.long);
      final shortChance = calculateHitChance(ship, cannon, monster, range: CombatRange.short);

      expect(medChance, 80);
      expect(shortChance, 80);
      expect(longChance, 65); // 80 - 15 = 65%
    });

    test('Culverins and Mortars deal 100% anchor damage at Long Range and 85% at Medium Range', () {
      final ship = createTestShip();
      final monster = createTestMonster(maxHp: 200);
      final culverin = createTestShipWeapon(
        type: ShipWeaponType.precisionCulverin,
        damage: 40,
        hitModifier: 95,
      );
      final mortar = createTestShipWeapon(
        type: ShipWeaponType.heavyMortar,
        damage: 40,
        hitModifier: 95,
      );

      final rng = QueueGameRng(d100Rolls: [10, 10, 10, 10]);

      final (culverinLong, _) = calculateAttack(
        ship,
        culverin,
        monster,
        rng,
        const [],
        0,
        1.0,
        CombatRange.long,
      );
      expect(culverinLong.damage, 40); // 40 * 1.00 = 40 at Long anchor range

      final (mortarLong, _) = calculateAttack(
        ship,
        mortar,
        monster,
        rng,
        const [],
        0,
        1.0,
        CombatRange.long,
      );
      expect(mortarLong.damage, 40); // 40 * 1.00 = 40 at Long anchor range

      final (mortarMed, _) = calculateAttack(
        ship,
        mortar,
        monster,
        rng,
        const [],
        0,
        1.0,
        CombatRange.medium,
      );
      expect(mortarMed.damage, 34); // 40 * 0.85 = 34 at Medium range
    });

    test('Prow Ram deals 100% anchor damage at Short Range and 125% kinetic charge from Medium Range', () {
      final ship = createTestShip();
      final monster = createTestMonster(maxHp: 200);
      final ram = createTestShipWeapon(
        type: ShipWeaponType.prowRam,
        damage: 50,
        hitModifier: 95,
      );

      final rng = QueueGameRng(d100Rolls: [10, 10]);
      final (ramShort, _) = calculateAttack(
        ship,
        ram,
        monster,
        rng,
        const [],
        0,
        1.0,
        CombatRange.short,
      );
      expect(ramShort.damage, 50); // 50 * 1.00 = 50 at Short anchor range

      final (ramMedCharge, _) = calculateAttack(
        ship,
        ram,
        monster,
        rng,
        const [],
        0,
        1.0,
        CombatRange.medium,
      );
      expect(ramMedCharge.damage, 63); // 50 * 1.25 = 62.5 -> 63 kinetic charge from Medium
    });

    test('Point-blank Mortar at Short Range triggers 25% backfire splash to own hull', () {
      final ship = createTestShip(maxHp: 100);
      final monster = createTestMonster(maxHp: 200);
      final mortar = createTestShipWeapon(
        type: ShipWeaponType.heavyMortar,
        damage: 40,
        hitModifier: 95,
      );

      final rng = QueueGameRng(d100Rolls: [10]);
      final (_, events) = calculateAttack(
        ship,
        mortar,
        monster,
        rng,
        const [],
        0,
        1.0,
        CombatRange.short,
      );

      // 40 * 0.70 (Short range mult) = 28 base damage; 28 * 0.25 = 7 splash damage to own hull
      expect(ship.currentHp, 93);
      expect(events.any((e) => e is MortarBackfireOccurred), isTrue);
      final backfireEvent = events.whereType<MortarBackfireOccurred>().first;
      expect(backfireEvent.damage, 7);
    });

    test('EvasionTrait receives +15% at Long Range and -15% at Short Range', () {
      final ship = createTestShip(shipClass: ShipClass.corvette, baseEvasion: 30);
      final monster = createTestMonster();
      final monsterAttack = createTestMonsterWeapon(damage: 20, hitModifier: 95);
      const trait = EvasionTrait();

      // Long range: effective evasion is 30 + 15 = 45%. A roll of 40 evades!
      final rngLong = QueueGameRng(d100Rolls: [10, 40]); // hit roll 10, dodge roll 40
      final (resultLong, eventsLong) = calculateAttack(
        monster,
        monsterAttack,
        ship,
        rngLong,
        [trait],
        0,
        1.0,
        CombatRange.long,
      );
      expect(resultLong.wasEvaded, isTrue);
      expect(eventsLong.any((e) => e is AttackEvaded), isTrue);

      // Short range: effective evasion is 30 - 15 = 15%. A roll of 20 fails to evade!
      final rngShort = QueueGameRng(d100Rolls: [10, 20]); // hit roll 10, dodge roll 20
      final (resultShort, eventsShort) = calculateAttack(
        monster,
        monsterAttack,
        ship,
        rngShort,
        [trait],
        0,
        1.0,
        CombatRange.short,
      );
      expect(resultShort.wasEvaded, isFalse);
      expect(eventsShort.any((e) => e is AttackEvaded), isFalse);
    });

    test('Ship canEquipWeapon checks hardpoint slots rather than weapon weight', () {
      final ship = createTestShip();
      ship.hardpoints.clear();
      ship.hardpoints.addAll([
        const HardpointSlot(id: 'broadside_1', name: 'Port Broadside', type: HardpointType.broadside),
        const HardpointSlot(id: 'broadside_2', name: 'Starboard Broadside', type: HardpointType.broadside),
      ]);
      ship.equippedWeapons.clear();

      // Weapons with heavy legacy weight (e.g. 5 each) can still be equipped if hardpoint slots exist
      final w1 = createTestShipWeapon(id: 'w1', name: 'Siege Gun 1', equipWeight: 5);
      final w2 = createTestShipWeapon(id: 'w2', name: 'Siege Gun 2', equipWeight: 5);
      final w3 = createTestShipWeapon(id: 'w3', name: 'Siege Gun 3', equipWeight: 5);

      expect(ship.canEquipWeapon(w1), isTrue);
      ship.equipWeapon(w1);
      expect(ship.equippedWeapons.length, 1);

      expect(ship.canEquipWeapon(w2), isTrue);
      ship.equipWeapon(w2);
      expect(ship.equippedWeapons.length, 2);

      // 3rd weapon cannot be equipped because all 2 hardpoints are occupied
      expect(ship.canEquipWeapon(w3), isFalse);
    });
  });
}
