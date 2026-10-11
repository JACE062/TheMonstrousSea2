import '../model/combatant.dart';
import '../model/enums.dart';
import '../model/item.dart';
import '../rng/game_rng.dart';
import 'monster_weapons.dart';
import 'names/name_forge.dart';

int _monsterIdCounter = 0;

/// Factory function to create a [MonsterState] for a Shark.
///
/// Stats:
/// - HP: `40 * level`
/// - AC: `6 + 2 * level`
/// - Weapons: Ram, Jaws
MonsterState createShark({
  required int level,
  required GameRng rng,
  String? name,
  String? id,
}) {
  final monsterName =
      name ?? NameForge.generateMonsterName(MonsterSpecies.shark, rng);
  final monsterId = id ?? 'monster_shark_${++_monsterIdCounter}';
  final weapons = <MonsterWeapon>[
    generateMonsterWeapon(MonsterWeaponType.ram, level, rng),
    generateMonsterWeapon(MonsterWeaponType.jaws, level, rng),
  ];

  return MonsterState(
    id: monsterId,
    name: monsterName,
    level: level,
    maxHp: 40 * level,
    armorClass: 6 + 2 * level,
    species: MonsterSpecies.shark,
    usableWeapons: weapons,
  );
}

/// Factory function to create a [MonsterState] for a Serpent.
///
/// Stats:
/// - HP: `45 * level`
/// - AC: `6 + 2 * level`
/// - Weapons: Ram, Tail
MonsterState createSerpent({
  required int level,
  required GameRng rng,
  String? name,
  String? id,
}) {
  final monsterName =
      name ?? NameForge.generateMonsterName(MonsterSpecies.serpent, rng);
  final monsterId = id ?? 'monster_serpent_${++_monsterIdCounter}';
  final weapons = <MonsterWeapon>[
    generateMonsterWeapon(MonsterWeaponType.ram, level, rng),
    generateMonsterWeapon(MonsterWeaponType.tail, level, rng),
  ];

  return MonsterState(
    id: monsterId,
    name: monsterName,
    level: level,
    maxHp: 45 * level,
    armorClass: 6 + 2 * level,
    species: MonsterSpecies.serpent,
    usableWeapons: weapons,
  );
}

/// Factory function to create a [MonsterState] for a Jellyfish.
///
/// Stats:
/// - HP: `35 * level`
/// - AC: `4 + 2 * level`
/// - Weapons: Ram, Stinging Tendrils
MonsterState createJellyfish({
  required int level,
  required GameRng rng,
  String? name,
  String? id,
}) {
  final monsterName =
      name ?? NameForge.generateMonsterName(MonsterSpecies.jellyfish, rng);
  final monsterId = id ?? 'monster_jellyfish_${++_monsterIdCounter}';
  final weapons = <MonsterWeapon>[
    generateMonsterWeapon(MonsterWeaponType.ram, level, rng),
    generateMonsterWeapon(MonsterWeaponType.stingingTendrils, level, rng),
  ];

  return MonsterState(
    id: monsterId,
    name: monsterName,
    level: level,
    maxHp: 35 * level,
    armorClass: 4 + 2 * level,
    species: MonsterSpecies.jellyfish,
    usableWeapons: weapons,
  );
}

/// Factory function to create a [MonsterState] for a Squid.
///
/// Stats:
/// - HP: `50 * level`
/// - AC: `6 + 2 * level`
/// - Weapons: Ram, Tentacle
/// - Tentacles: `5 * level`
/// - Obscured AC Modifier: `2 * level`
MonsterState createSquid({
  required int level,
  required GameRng rng,
  String? name,
  String? id,
}) {
  final monsterName =
      name ?? NameForge.generateMonsterName(MonsterSpecies.squid, rng);
  final monsterId = id ?? 'monster_squid_${++_monsterIdCounter}';
  final weapons = <MonsterWeapon>[
    generateMonsterWeapon(MonsterWeaponType.ram, level, rng),
    generateMonsterWeapon(MonsterWeaponType.tentacle, level, rng),
  ];

  return MonsterState(
    id: monsterId,
    name: monsterName,
    level: level,
    maxHp: 50 * level,
    armorClass: 6 + 2 * level,
    species: MonsterSpecies.squid,
    usableWeapons: weapons,
    numberOfTentacles: 5 * level,
    obscuredAcMod: 2 * level,
  );
}

/// Factory function to create a [MonsterState] for a Crustacean.
///
/// Stats:
/// - HP: `60 * level`
/// - AC: `10 + 2 * level`
/// - Weapons: Ram, Claw (only if `level >= 2`)
MonsterState createCrustacean({
  required int level,
  required GameRng rng,
  String? name,
  String? id,
}) {
  final monsterName =
      name ?? NameForge.generateMonsterName(MonsterSpecies.crustacean, rng);
  final monsterId = id ?? 'monster_crustacean_${++_monsterIdCounter}';
  final weapons = <MonsterWeapon>[
    generateMonsterWeapon(MonsterWeaponType.ram, level, rng),
    if (level >= 2) generateMonsterWeapon(MonsterWeaponType.claw, level, rng),
  ];

  return MonsterState(
    id: monsterId,
    name: monsterName,
    level: level,
    maxHp: 60 * level,
    armorClass: 10 + 2 * level,
    species: MonsterSpecies.crustacean,
    usableWeapons: weapons,
  );
}

/// Factory function to create The Kraken boss.
///
/// Stats:
/// - Species: [MonsterSpecies.kraken] (or optionally [MonsterSpecies.squid])
/// - Level: 5
/// - HP: 300
/// - AC: 18
/// - Tentacles: 25
/// - Obscured AC Modifier: 8
/// - Weapons: Ram, Tentacle
MonsterState createKraken({
  GameRng? rng,
  String? name,
  String? id,
  MonsterSpecies species = MonsterSpecies.kraken,
}) {
  final effectiveRng = rng ?? SeededGameRng(42);
  final weapons = <MonsterWeapon>[
    generateMonsterWeapon(MonsterWeaponType.ram, 5, effectiveRng),
    generateMonsterWeapon(MonsterWeaponType.tentacle, 5, effectiveRng),
  ];

  return MonsterState(
    id: id ?? 'the_kraken',
    name: name ?? 'The Kraken',
    level: 5,
    maxHp: 300,
    armorClass: 18,
    species: species,
    usableWeapons: weapons,
    numberOfTentacles: 25,
    obscuredAcMod: 8,
  );
}

/// General dispatcher creating a [MonsterState] by [species].
MonsterState createMonster(
  MonsterSpecies species, {
  required int level,
  required GameRng rng,
  String? name,
  String? id,
}) {
  switch (species) {
    case MonsterSpecies.shark:
      return createShark(level: level, rng: rng, name: name, id: id);
    case MonsterSpecies.serpent:
      return createSerpent(level: level, rng: rng, name: name, id: id);
    case MonsterSpecies.jellyfish:
      return createJellyfish(level: level, rng: rng, name: name, id: id);
    case MonsterSpecies.squid:
      return createSquid(level: level, rng: rng, name: name, id: id);
    case MonsterSpecies.crustacean:
      return createCrustacean(level: level, rng: rng, name: name, id: id);
    case MonsterSpecies.kraken:
      return createKraken(rng: rng, name: name, id: id);
  }
}

/// Creates a random sea monster for the given difficulty [level].
///
/// Crustaceans appear only at `level >= 2`.
MonsterState randomMonster({
  required int level,
  required GameRng rng,
  String? id,
}) {
  final available = level == 1
      ? const [
          MonsterSpecies.shark,
          MonsterSpecies.serpent,
          MonsterSpecies.jellyfish,
          MonsterSpecies.squid,
        ]
      : const [
          MonsterSpecies.shark,
          MonsterSpecies.serpent,
          MonsterSpecies.jellyfish,
          MonsterSpecies.squid,
          MonsterSpecies.crustacean,
        ];
  final species = available[rng.nextInt(available.length)];
  return createMonster(species, level: level, rng: rng, id: id);
}
