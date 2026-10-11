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

MonsterWeapon createMonsterWeapon({
  String id = 'mw-1',
  String name = 'Claw',
  MonsterWeaponType type = MonsterWeaponType.claw,
  int damage = 10,
  int hitModifier = 2,
  int chargeTime = 0,
  int chargeCountdown = 0,
}) {
  return MonsterWeapon(
    id: id,
    name: name,
    description: 'A sharp weapon',
    rarity: RarityLevel.common,
    damage: damage,
    hitModifier: hitModifier,
    chargeTime: chargeTime,
    chargeCountdown: chargeCountdown,
    damageType: DamageType.piercing,
    monsterWeaponType: type,
  );
}

void main() {
  group('Monster AI Bug B2 Regression Tests', () {
    test('monster with all weapons on cooldown terminates cleanly without infinite loop', () {
      final w1 = createMonsterWeapon(
        id: 'w1',
        name: 'Ram',
        type: MonsterWeaponType.ram,
        chargeTime: 2,
        chargeCountdown: 2, // on cooldown
      );
      final w2 = createMonsterWeapon(
        id: 'w2',
        name: 'Jaws',
        type: MonsterWeaponType.jaws,
        chargeTime: 3,
        chargeCountdown: 1, // on cooldown
      );

      final shark = MonsterState(
        id: 'shark-1',
        name: 'Megalodon',
        level: 3,
        maxHp: 120,
        armorClass: 12,
        species: MonsterSpecies.shark,
        usableWeapons: [w1, w2],
      );

      final ship = ShipState(
        id: 'ship-1',
        name: 'HMS Steadfast',
        level: 2,
        maxHp: 100,
        armorClass: 10,
        shipClass: ShipClass.standard,
        maxCargo: 10,
        maxWeaponWeight: 14,
      );

      // d100 = 50 (<= 80 -> wants attack)
      final rng = QueueGameRng(d100Rolls: [50]);

      // Should terminate immediately and not hang
      final events = takeMonsterTurn(shark, ship, rng);

      expect(events.length, equals(1));
      expect(events.first, isA<MonsterHesitated>());
      final hesitated = events.first as MonsterHesitated;
      expect(hesitated.monsterName, equals(shark.name));

      // Weapons countdown decremented
      expect(w1.chargeCountdown, equals(1));
      expect(w2.chargeCountdown, equals(0));
    });

    test('squid with all weapons on cooldown uses ink cloud if not obscured', () {
      final tentacle = createMonsterWeapon(
        name: 'Tentacle',
        type: MonsterWeaponType.tentacle,
        chargeTime: 1,
        chargeCountdown: 1, // on cooldown
      );

      final squid = MonsterState(
        id: 'squid-1',
        name: 'Giant Squid',
        level: 2,
        maxHp: 100,
        armorClass: 10,
        species: MonsterSpecies.squid,
        numberOfTentacles: 5,
        obscuredAcMod: 4,
        isObscured: false,
        usableWeapons: [tentacle],
      );

      final ship = ShipState(
        id: 'ship-1',
        name: 'HMS Horizon',
        level: 1,
        maxHp: 100,
        armorClass: 10,
        shipClass: ShipClass.standard,
        maxCargo: 10,
        maxWeaponWeight: 10,
      );

      final rng = QueueGameRng(d100Rolls: [50]);
      final events = takeMonsterTurn(squid, ship, rng);

      expect(squid.isObscured, isTrue);
      expect(events.any((e) => e is InkCloudDeployed), isTrue);
      final inkEvent = events.firstWhere((e) => e is InkCloudDeployed) as InkCloudDeployed;
      expect(inkEvent.acBonus, equals(4));
      // Weapon cooldown decremented
      expect(tentacle.chargeCountdown, equals(0));
    });

    test('squid already obscured with all weapons on cooldown hesitates cleanly', () {
      final tentacle = createMonsterWeapon(
        type: MonsterWeaponType.tentacle,
        chargeTime: 2,
        chargeCountdown: 2,
      );

      final squid = MonsterState(
        id: 'squid-1',
        name: 'Giant Squid',
        level: 2,
        maxHp: 100,
        armorClass: 10,
        species: MonsterSpecies.squid,
        isObscured: true, // Already obscured!
        usableWeapons: [tentacle],
      );

      final ship = ShipState(
        id: 'ship-1',
        name: 'HMS Horizon',
        level: 1,
        maxHp: 100,
        armorClass: 10,
        shipClass: ShipClass.standard,
        maxCargo: 10,
        maxWeaponWeight: 10,
      );

      final rng = QueueGameRng(d100Rolls: [50]);
      final events = takeMonsterTurn(squid, ship, rng);

      expect(events.any((e) => e is MonsterHesitated), isTrue);
      expect(tentacle.chargeCountdown, equals(1));
    });
  });

  group('Squid Multi-Tentacle Attack Tests', () {
    test('strikes once for each intact tentacle', () {
      final tentacle = createMonsterWeapon(
        name: 'Tentacle',
        type: MonsterWeaponType.tentacle,
        damage: 8,
        hitModifier: 2,
      );

      final squid = MonsterState(
        id: 'squid-1',
        name: 'Kraken Spawn',
        level: 2,
        maxHp: 100,
        armorClass: 10,
        species: MonsterSpecies.squid,
        numberOfTentacles: 4, // 4 tentacles
        usableWeapons: [tentacle],
      );

      final ship = ShipState(
        id: 'ship-1',
        name: 'HMS Endurance',
        level: 1,
        maxHp: 100,
        armorClass: 8,
        shipClass: ShipClass.standard,
        maxCargo: 10,
        maxWeaponWeight: 10,
      );

      // d100 = 50 (attack), d20 = [15, 15, 15, 15] (all hit)
      final rng = QueueGameRng(
        d100Rolls: [50],
        d20Rolls: [15, 15, 15, 15],
      );

      final events = takeMonsterTurn(squid, ship, rng);

      final hitEvents = events.whereType<AttackHit>().toList();
      expect(hitEvents.length, equals(4)); // 4 hits!
      expect(ship.currentHp, equals(100 - (4 * 8))); // 68
    });

    test('flails uselessly when numberOfTentacles == 0', () {
      final tentacle = createMonsterWeapon(
        name: 'Tentacle',
        type: MonsterWeaponType.tentacle,
        damage: 8,
      );

      final squid = MonsterState(
        id: 'squid-1',
        name: 'De-tentacled Squid',
        level: 2,
        maxHp: 100,
        armorClass: 10,
        species: MonsterSpecies.squid,
        numberOfTentacles: 0, // No tentacles left!
        usableWeapons: [tentacle],
      );

      final ship = ShipState(
        id: 'ship-1',
        name: 'HMS Endurance',
        level: 1,
        maxHp: 100,
        armorClass: 10,
        shipClass: ShipClass.standard,
        maxCargo: 10,
        maxWeaponWeight: 10,
      );

      final rng = QueueGameRng(d100Rolls: [50]);
      final events = takeMonsterTurn(squid, ship, rng);

      expect(events.length, equals(1));
      expect(events.first, isA<AttackMissed>());
      expect(ship.currentHp, equals(100)); // No damage
    });
  });

  group('Ink Cloud Activation & AC Boost Tests', () {
    test('special action activates ink cloud boosting effectiveArmorClass', () {
      final ram = createMonsterWeapon(type: MonsterWeaponType.ram);
      final squid = MonsterState(
        id: 'squid-1',
        name: 'Cuttlefish',
        level: 2,
        maxHp: 100,
        armorClass: 10,
        obscuredAcMod: 5,
        species: MonsterSpecies.squid,
        isObscured: false,
        usableWeapons: [ram],
      );

      final ship = ShipState(
        id: 'ship-1',
        name: 'HMS Gallant',
        level: 1,
        maxHp: 100,
        armorClass: 10,
        shipClass: ShipClass.standard,
        maxCargo: 10,
        maxWeaponWeight: 10,
      );

      // d100 = 90 (> 80 -> triggers 20% special action chance)
      final rng = QueueGameRng(d100Rolls: [90]);
      final events = takeMonsterTurn(squid, ship, rng);

      expect(squid.isObscured, isTrue);
      expect(squid.effectiveArmorClass, equals(15)); // 10 + 5
      expect(events.length, equals(1));
      expect(events.first, isA<InkCloudDeployed>());
      final inkEvent = events.first as InkCloudDeployed;
      expect(inkEvent.acBonus, equals(5));
      expect(inkEvent.monsterName, equals(squid.name));
    });

    test('crustacean never uses special action and always attacks', () {
      final claw = createMonsterWeapon(
        type: MonsterWeaponType.claw,
        damage: 12,
        hitModifier: 2,
      );
      final crab = MonsterState(
        id: 'crab-1',
        name: 'Iron Crab',
        level: 2,
        maxHp: 120,
        armorClass: 14,
        species: MonsterSpecies.crustacean,
        usableWeapons: [claw],
      );

      final ship = ShipState(
        id: 'ship-1',
        name: 'HMS Gallant',
        level: 1,
        maxHp: 100,
        armorClass: 10,
        shipClass: ShipClass.standard,
        maxCargo: 10,
        maxWeaponWeight: 10,
      );

      // Even with d100 = 99 (which would be special action for other monsters)
      final rng = QueueGameRng(d100Rolls: [99], d20Rolls: [15]);
      final events = takeMonsterTurn(crab, ship, rng);

      // Crustacean attacks!
      expect(events.any((e) => e is AttackHit), isTrue);
      expect(ship.currentHp, equals(88));
    });
  });

  group('Cooldown and Weapon Cycling Tests', () {
    test('firing weapon puts it on cooldown and decrements other ready weapons', () {
      final w1 = createMonsterWeapon(
        id: 'w1',
        name: 'Tail Swipe',
        type: MonsterWeaponType.tail,
        chargeTime: 2,
        chargeCountdown: 0,
      );
      final w2 = createMonsterWeapon(
        id: 'w2',
        name: 'Bite',
        type: MonsterWeaponType.jaws,
        chargeTime: 3,
        chargeCountdown: 2,
      );

      final seaSerpent = MonsterState(
        id: 'serpent-1',
        name: 'Sea Serpent',
        level: 2,
        maxHp: 90,
        armorClass: 10,
        species: MonsterSpecies.serpent,
        usableWeapons: [w1, w2],
      );

      final ship = ShipState(
        id: 'ship-1',
        name: 'HMS Gallant',
        level: 1,
        maxHp: 100,
        armorClass: 10,
        shipClass: ShipClass.standard,
        maxCargo: 10,
        maxWeaponWeight: 10,
      );

      // rng nextInt = 0 (picks w1)
      final rng = QueueGameRng(d100Rolls: [50], nextIntValues: [0], d20Rolls: [15]);
      takeMonsterTurn(seaSerpent, ship, rng);

      expect(w1.chargeCountdown, equals(2)); // Put on cooldown
      expect(w2.chargeCountdown, equals(1)); // Decremented from 2 to 1
    });
  });
}
