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
    frenzyStacks: 0,
  );
}

/// Factory function to create a [MonsterState] for a Serpent.
///
/// Stats:
/// - HP: `40 * level`
/// - AC: `6 + 2 * level`
/// - Weapons: Ram, Tail
/// - Evasion: `20`
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
    maxHp: 40 * level,
    armorClass: 6 + 2 * level,
    species: MonsterSpecies.serpent,
    usableWeapons: weapons,
    evasion: 20,
  );
}

/// Factory function to create a [MonsterState] for a Jellyfish.
///
/// Stats:
/// - HP: `30 * level` (glass cannon, fragile body)
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
    maxHp: 30 * level,
    armorClass: 4 + 2 * level,
    species: MonsterSpecies.jellyfish,
    usableWeapons: weapons,
  );
}

/// Factory function to create a [MonsterState] for a Squid.
///
/// Stats:
/// - HP: `45 * level`
/// - AC: `6 + 2 * level`
/// - Weapons: Ram, Tentacle
/// - Tentacles: `5 * level`
/// - Obscured AC Modifier: `20` (-20% hit chance)
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
    maxHp: 45 * level,
    armorClass: 6 + 2 * level,
    species: MonsterSpecies.squid,
    usableWeapons: weapons,
    numberOfTentacles: 5 * level,
    obscuredAcMod: 20,
  );
}

/// Factory function to create a [MonsterState] for a Crustacean.
///
/// Stats:
/// - HP: `45 * level`
/// - Carapace: `20 * level` (absorbs normal damage, shattered by blast, bypassed by fire)
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
    maxHp: 45 * level,
    carapacePlating: 20 * level,
    maxCarapace: 20 * level,
    armorClass: 10 + 2 * level,
    species: MonsterSpecies.crustacean,
    usableWeapons: weapons,
  );
}

/// Factory function to create The Kraken boss.
///
/// Stats:
/// - Species: [MonsterSpecies.kraken] (or optionally [MonsterSpecies.squid])
/// - Level: 5 (default) or 3 for Region 1
/// - HP: 300 (lvl 5) or 180 (lvl 3)
/// - AC: 18 (lvl 5) or 14 (lvl 3)
/// - Tentacles: 25 (lvl 5) or 15 (lvl 3)
/// - Obscured AC Modifier: 25
/// - Weapons: Ram, Tentacle
MonsterState createKraken({
  int level = 5,
  GameRng? rng,
  String? name,
  String? id,
  MonsterSpecies species = MonsterSpecies.kraken,
}) {
  final effectiveRng = rng ?? SeededGameRng(42);
  final hp = level == 5 ? 300 : (level == 3 ? 180 : 60 * level);
  final ac = level == 5 ? 18 : (6 + 2 * level);
  final tentacles = level == 3 ? 15 : 25;
  final obscured = level == 5 ? 25 : (5 * level);
  final weapons = <MonsterWeapon>[
    generateMonsterWeapon(MonsterWeaponType.ram, level, effectiveRng),
    generateMonsterWeapon(MonsterWeaponType.tentacle, level, effectiveRng),
  ];

  return MonsterState(
    id: id ?? 'the_kraken',
    name: name ?? 'The Kraken',
    level: level,
    maxHp: hp,
    armorClass: ac,
    species: species,
    usableWeapons: weapons,
    numberOfTentacles: tentacles,
    obscuredAcMod: obscured,
  );
}

/// Factory function to create The World Serpent (Jörmungandr) boss of Region 2.
///
/// Stats:
/// - Species: [MonsterSpecies.worldSerpent]
/// - Level: [level] (defaults to 5)
/// - HP: 260
/// - AC: 16
/// - Evasion: 30%
/// - Weapons: Ram, Tail
MonsterState createWorldSerpent({
  int level = 5,
  GameRng? rng,
  String? name,
  String? id,
}) {
  final effectiveRng = rng ?? SeededGameRng(42);
  final weapons = <MonsterWeapon>[
    generateMonsterWeapon(MonsterWeaponType.ram, level, effectiveRng),
    generateMonsterWeapon(MonsterWeaponType.tail, level, effectiveRng),
  ];

  return MonsterState(
    id: id ?? 'world_serpent',
    name: name ?? 'The World Serpent',
    level: level,
    maxHp: 260,
    armorClass: 16,
    species: MonsterSpecies.worldSerpent,
    usableWeapons: weapons,
    evasion: 30,
  );
}

/// Factory function to create The Ancient Leviathan final titan of Region 3.
///
/// Stats:
/// - Species: [MonsterSpecies.ancientLeviathan]
/// - Level: [level] (defaults to 7)
/// - HP: 450
/// - AC: 20
/// - Weapons: Ram, Jaws, Stinging Tendrils
MonsterState createAncientLeviathan({
  int level = 7,
  GameRng? rng,
  String? name,
  String? id,
}) {
  final effectiveRng = rng ?? SeededGameRng(42);
  final weapons = <MonsterWeapon>[
    generateMonsterWeapon(MonsterWeaponType.ram, level, effectiveRng),
    generateMonsterWeapon(MonsterWeaponType.jaws, level, effectiveRng),
    generateMonsterWeapon(MonsterWeaponType.stingingTendrils, level, effectiveRng),
  ];

  return MonsterState(
    id: id ?? 'ancient_leviathan',
    name: name ?? 'The Ancient Leviathan',
    level: level,
    maxHp: 450,
    armorClass: 20,
    species: MonsterSpecies.ancientLeviathan,
    usableWeapons: weapons,
  );
}

/// General dispatcher creating a [MonsterState] by [species].
MonsterState createMonster(
  MonsterSpecies species, {
  required int level,
  required GameRng rng,
  String? name,
  String? id,
  bool isApex = false,
}) {
  final MonsterState monster;
  switch (species) {
    case MonsterSpecies.shark:
      monster = createShark(level: level, rng: rng, name: name, id: id);
    case MonsterSpecies.serpent:
      monster = createSerpent(level: level, rng: rng, name: name, id: id);
    case MonsterSpecies.jellyfish:
      monster = createJellyfish(level: level, rng: rng, name: name, id: id);
    case MonsterSpecies.squid:
      monster = createSquid(level: level, rng: rng, name: name, id: id);
    case MonsterSpecies.crustacean:
      monster = createCrustacean(level: level, rng: rng, name: name, id: id);
    case MonsterSpecies.kraken:
      return createKraken(level: level, rng: rng, name: name, id: id);
    case MonsterSpecies.worldSerpent:
      return createWorldSerpent(level: level, rng: rng, name: name, id: id);
    case MonsterSpecies.ancientLeviathan:
      return createAncientLeviathan(level: level, rng: rng, name: name, id: id);
  }

  if (isApex) {
    applyApexEnhancements(monster, rng);
  }
  return monster;
}

/// Applies elite Apex predator enhancements, stat scaling, and affixes.
void applyApexEnhancements(MonsterState monster, GameRng rng) {
  monster.isApex = true;
  monster.maxHp = (monster.maxHp * 1.30).round();
  monster.currentHp = monster.maxHp;

  // Universal Apex Fortification: Encrusted Barnacle Carapace
  final baseApexCarapace = 20 + 5 * monster.level;
  monster.carapacePlating += baseApexCarapace;
  monster.maxCarapace += baseApexCarapace;

  switch (monster.species) {
    case MonsterSpecies.shark:
      monster.apexTitle = 'Apex Blood-Frenzy Megalodon';
      monster.frenzyStacks = 1;
    case MonsterSpecies.serpent:
      monster.apexTitle = 'Apex Phosphor Wyrm';
      monster.evasion = 30;
    case MonsterSpecies.jellyfish:
      monster.apexTitle = 'Apex Volcanic Shock-Bell';
      monster.usableWeapons.add(
        generateMonsterWeapon(MonsterWeaponType.stingingTendrils, monster.level, rng),
      );
    case MonsterSpecies.squid:
      monster.apexTitle = 'Apex Abyssal Krakenling';
      monster.numberOfTentacles += 5;
      monster.obscuredAcMod += 5;
    case MonsterSpecies.crustacean:
      monster.apexTitle = 'Apex Obsidian Carapace Drake';
      monster.carapacePlating += 25;
      monster.maxCarapace += 25;
    case MonsterSpecies.kraken:
    case MonsterSpecies.worldSerpent:
    case MonsterSpecies.ancientLeviathan:
      break;
  }

  if (monster.apexTitle != null) {
    monster.name = '${monster.apexTitle!} ${monster.name}';
  }
}

/// Creates a random sea monster for the given difficulty [level].
///
/// Crustaceans appear only at `level >= 2`.
MonsterState randomMonster({
  required int level,
  required GameRng rng,
  String? id,
  bool isApex = false,
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
  return createMonster(species, level: level, rng: rng, id: id, isApex: isApex);
}
