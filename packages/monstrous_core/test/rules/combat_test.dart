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
  int hitModifier = 2,
  int chargeTime = 0,
  int chargeCountdown = 0,
  DamageType damageType = DamageType.piercing,
  StatusEffect? statusEffect,
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
    equipWeight: 2,
    weaponType: type,
  );
}

MonsterWeapon createTestMonsterWeapon({
  String id = 'mw-1',
  String name = 'Razor Jaws',
  MonsterWeaponType type = MonsterWeaponType.jaws,
  int damage = 15,
  int hitModifier = 1,
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
    test('d20 roll + hitMod < AC results in miss', () {
      final ship = createTestShip();
      final weapon = createTestShipWeapon(hitModifier: 2);
      final monster = createTestMonster(armorClass: 14);

      // d20 = 10, total = 10 + 2 = 12 < 14
      final rng = QueueGameRng(d20Rolls: [10]);
      final (result, events) = calculateAttack(ship, weapon, monster, rng);

      expect(result.didHit, isFalse);
      expect(result.damage, equals(0));
      expect(monster.currentHp, equals(100));

      expect(events.length, equals(2));
      expect(events[0], isA<AttackAttempted>());
      final attempted = events[0] as AttackAttempted;
      expect(attempted.roll, equals(12));
      expect(attempted.targetAc, equals(14));

      expect(events[1], isA<AttackMissed>());
      final missed = events[1] as AttackMissed;
      expect(missed.targetName, equals(monster.name));
    });

    test('d20 roll + hitMod >= AC results in hit dealing damage', () {
      final ship = createTestShip();
      final weapon = createTestShipWeapon(damage: 25, hitModifier: 2);
      final monster = createTestMonster(armorClass: 12);

      // d20 = 10, total = 10 + 2 = 12 >= 12
      final rng = QueueGameRng(d20Rolls: [10]);
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

    test('obscured monster uses effectiveArmorClass', () {
      final ship = createTestShip();
      final weapon = createTestShipWeapon(hitModifier: 2);
      // AC = 10 + 4 (obscured) = 14
      final monster = createTestMonster(
        armorClass: 10,
        isObscured: true,
        obscuredAcMod: 4,
      );

      // d20 = 10 + 2 = 12 -> misses effective AC 14
      final rng = QueueGameRng(d20Rolls: [10]);
      final (result, events) = calculateAttack(ship, weapon, monster, rng);

      expect(result.didHit, isFalse);
      final attempted = events[0] as AttackAttempted;
      expect(attempted.targetAc, equals(14));
    });

    test('applying status effects on hit', () {
      final ship = createTestShip();
      final weapon = createTestShipWeapon(
        statusEffect: StatusEffect.burn,
        hitModifier: 5,
      );
      final monster = createTestMonster(armorClass: 10);

      final rng = QueueGameRng(d20Rolls: [15]);
      final (result, _) = calculateAttack(ship, weapon, monster, rng);

      expect(result.didHit, isTrue);
      expect(monster.hasStatus(StatusEffect.burn), isTrue);
    });

    test('defeating combatant emits CombatantDefeated', () {
      final ship = createTestShip();
      final weapon = createTestShipWeapon(damage: 100);
      final monster = createTestMonster(maxHp: 50, armorClass: 8);

      final rng = QueueGameRng(d20Rolls: [10]);
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
        armorClass: 8,
      );
      final monster = createTestMonster();
      final monsterWeapon = createTestMonsterWeapon(damage: 20, hitModifier: 2);

      const traits = [FortifyTrait()];
      // d20 = 10 + 2 = 12 >= 8 -> hit
      final rng = QueueGameRng(d20Rolls: [10]);
      final (result, events) =
          calculateAttack(monster, monsterWeapon, ironclad, rng, traits);

      expect(result.didHit, isTrue);
      expect(result.nullifiedDamage, equals(6));
      expect(ironclad.currentHp, equals(100 - (20 - 6)));

      final reducedEvent = events.firstWhere((e) => e is DamageReduced) as DamageReduced;
      expect(reducedEvent.shipName, equals(ironclad.name));
      expect(reducedEvent.nullifiedAmount, equals(6));

      final hitEvent = events.firstWhere((e) => e is AttackHit) as AttackHit;
      expect(hitEvent.damage, equals(14));
    });

    test('completely nullifies damage when reduction exceeds attack damage', () {
      final ironclad = createTestShip(
        shipClass: ShipClass.ironclad,
        baseDmgReduction: 15,
        armorClass: 8,
      );
      final monster = createTestMonster();
      final monsterWeapon = createTestMonsterWeapon(damage: 10);

      const traits = [FortifyTrait()];
      final rng = QueueGameRng(d20Rolls: [10]);
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
        armorClass: 8,
      );
      final monster = createTestMonster();
      final monsterWeapon = createTestMonsterWeapon(damage: 30);

      const traits = [EvasionTrait()];
      // d20 = 15 (hit), d100 = 20 (<= 25 evasion)
      final rng = QueueGameRng(d20Rolls: [15], d100Rolls: [20]);
      final (result, events) =
          calculateAttack(monster, monsterWeapon, corvette, rng, traits);

      expect(result.didHit, isTrue);
      expect(result.wasEvaded, isTrue);
      expect(corvette.currentHp, equals(100)); // undamaged

      expect(events.any((e) => e is AttackEvaded), isTrue);
      final evadedEvent = events.firstWhere((e) => e is AttackEvaded) as AttackEvaded;
      expect(evadedEvent.wasManeuver, isFalse);
    });

    test('evasive maneuvers doubles evasion and resets after dodge', () {
      final corvette = createTestShip(
        shipClass: ShipClass.corvette,
        baseEvasion: 20,
        armorClass: 8,
      );
      const trait = EvasionTrait();
      final rng = QueueGameRng();

      trait.executeSpecialAction(corvette, createTestMonster(), rng);
      expect(corvette.currentEvasion, equals(40));

      final monster = createTestMonster();
      final monsterWeapon = createTestMonsterWeapon(damage: 30);

      // d20 = 15 (hit), d100 = 35 (<= 40, dodged thanks to maneuver!)
      final attackRng = QueueGameRng(d20Rolls: [15], d100Rolls: [35]);
      final (result, events) =
          calculateAttack(monster, monsterWeapon, corvette, attackRng, [trait]);

      expect(result.wasEvaded, isTrue);
      final evadedEvent = events.firstWhere((e) => e is AttackEvaded) as AttackEvaded;
      expect(evadedEvent.wasManeuver, isTrue);

      // Evasion resets to base after dodging
      expect(corvette.currentEvasion, equals(20));
    });
  });

  group('Squid TentacleTrait Tests', () {
    test('slicing damage severs tentacles based on damage', () {
      final squid = createTestMonster(
        species: MonsterSpecies.squid,
        numberOfTentacles: 10,
        armorClass: 8,
      );
      final ship = createTestShip();
      // 15 slicing damage -> ceil(15 / 10) = 2 tentacles severed
      final bladeLauncher = createTestShipWeapon(
        damage: 15,
        damageType: DamageType.slicing,
      );

      const traits = [TentacleTrait()];
      final rng = QueueGameRng(d20Rolls: [15]);
      final (result, events) =
          calculateAttack(ship, bladeLauncher, squid, rng, traits);

      expect(result.tentaclesSevered, equals(2));
      expect(squid.numberOfTentacles, equals(8));

      final severedEvent =
          events.firstWhere((e) => e is TentaclesSevered) as TentaclesSevered;
      expect(severedEvent.countSevered, equals(2));
      expect(severedEvent.remainingTentacles, equals(8));
    });

    test('non-slicing damage does not sever tentacles', () {
      final squid = createTestMonster(
        species: MonsterSpecies.squid,
        numberOfTentacles: 10,
        armorClass: 8,
      );
      final ship = createTestShip();
      final cannon = createTestShipWeapon(
        damage: 30,
        damageType: DamageType.piercing,
      );

      const traits = [TentacleTrait()];
      final rng = QueueGameRng(d20Rolls: [15]);
      final (result, events) =
          calculateAttack(ship, cannon, squid, rng, traits);

      expect(result.tentaclesSevered, equals(0));
      expect(squid.numberOfTentacles, equals(10));
      expect(events.any((e) => e is TentaclesSevered), isFalse);
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

      final rng = QueueGameRng(d20Rolls: [15, 15]);
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

      final rng = QueueGameRng(d20Rolls: [15]);
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

      // Roll 60 (> 50) -> wears off
      final rng = QueueGameRng(d100Rolls: [60]);
      final (canAct, events) = updateStatusEffects(monster, 1, rng);

      expect(canAct, isTrue);
      expect(monster.hasStatus(StatusEffect.stun), isFalse);

      final ticked = events.firstWhere((e) => e is StatusEffectTicked) as StatusEffectTicked;
      expect(ticked.woreOff, isTrue);
    });

    test('STUN on monster persists on d100 <= 50 and denies action', () {
      final monster = createTestMonster();
      monster.addStatus(StatusEffect.stun);

      // Roll 40 (<= 50) -> remains stunned
      final rng = QueueGameRng(d100Rolls: [40]);
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
}
