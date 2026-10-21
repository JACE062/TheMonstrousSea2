import '../../model/enums.dart';
import '../../rng/game_rng.dart';

/// Procedural generator for Captain, Ship, and Monster names.
class NameForge {
  const NameForge._();

  // Ship adjectives (from original Java and expanded)
  static const List<String> standardShipAdjectives = [
    'Trusty',
    'Modest',
    'Faithful',
    'Reliable',
    'Seasoned',
    'Weathered',
    'Simple',
    'Dependable',
    'Sturdy',
    'Valiant',
    'Resolute',
    'Undaunted',
  ];

  static const List<String> freighterAdjectives = [
    'Plentiful',
    'Golden',
    'Bountiful',
    'Hefty',
    'Heavy-Laden',
    'Abundant',
    'Opulent',
    'Colossal',
    'Well-Stocked',
    'Laden',
    'Prosperous',
    'Gilded',
  ];

  static const List<String> ironcladAdjectives = [
    'Titanic',
    'Unyielding',
    'Indomitable',
    'Steadfast',
    'Dauntless',
    'Dreadnought',
    'Adamant',
    'Resolute',
    'Ironforged',
    'Impenetrable',
    'Bulwark',
    'Bastion',
  ];

  static const List<String> corvetteAdjectives = [
    'Swift',
    'Elusive',
    'Wily',
    'Phantom',
    'Nimble',
    'Slippery',
    'Gale-Forged',
    'Dancing',
    'Darting',
    'Tempest',
    'Shadow',
    'Fleetfoot',
  ];

  // Monster titles/names by species (from original Java and expanded)
  static const List<String> sharkNames = [
    'Thrashing Great White',
    'Bloodthirsty Bull Shark',
    'Colossal Tiger Shark',
    'Frenzied Maw',
    'Behemoth Mako',
    'Jagged Lurker',
    'Fang of the Abyss',
    'Terror of the Tides',
    'Ragefin',
    'Bloodrage Shark',
    'Apex Shredder',
    'Crimson Hunter',
  ];

  static const List<String> serpentNames = [
    'Slithery Devil',
    'Eerie Elainaling',
    'False Seaweed',
    'Elusive Eell',
    'Writhing Curse',
    'Lurking Coil',
    'Twisting Terror',
    'Vanishing Viper',
    'Mire Serpent',
    'Darting Death',
    'Abyssal Constrictor',
    'Tide Coiler',
  ];

  static const List<String> jellyfishNames = [
    'Pulsating Jellyfish',
    'Venom-Inflicter',
    'Ghostly-Tendriled Creature',
    'Medusa’s Grasp',
    'Nerveburn Jelly',
    'Venomous Shroud',
    'Drifting Wraith',
    'Abyssal Stinger',
    'Floating Veil',
    'Bioluminescent Terror',
    'Phantasmal Bell',
  ];

  static const List<String> squidNames = [
    'Gargantuan Squid',
    'Krakenling',
    'Many-tentacled beast',
    'Inkborn Terror',
    'Hundred-Limbed Horror',
    'Grasping Abyss',
    'Suffocating Embrace',
    'Razor Tendrils',
    'Inky Death',
    'Depth Lurker',
    'Cephalopod Tyrant',
  ];

  static const List<String> crustaceanNames = [
    'Colossal Lobster',
    'Island-Shell Crab',
    'Radioactive Isopod',
    'Living Fortress',
    'Adamantine-Carapace Titan',
    'Chitinous Colossus',
    'Stoneclaw Leviathan',
    'Aegis-Lobster',
    'Shellbound Menace',
    'Abyssal Scuttler',
    'Terrorclaw',
    'Unbreakable One',
    'Mutant Shellback',
    'Hulking Razorclaw',
    'Iron Carapace',
  ];

  static const List<String> krakenTitles = [
    'The Kraken',
    'Terror of the Deep',
    'The Scourge of Sailors',
    'Ancient Leviathan',
    'Abyssal Sovereign',
    'The Undying Horror',
  ];

  // Captain name parts
  static const List<String> captainFirstNames = [
    'Edward',
    'Anne',
    'Bartholomew',
    'Mary',
    'William',
    'Henry',
    'Grace',
    'Francis',
    'Jack',
    'Samuel',
    'Charles',
    'Thomas',
    'James',
    'Benjamin',
    'Arthur',
    'Barnaby',
    'Thaddeus',
    'Gideon',
    'Cornelius',
    'Silas',
    'Ezekiel',
    'Tobias',
  ];

  static const List<String> captainLastNames = [
    'Teach',
    'Bonny',
    'Roberts',
    'Read',
    'Kidd',
    'Morgan',
    "O'Malley",
    'Drake',
    'Sparrow',
    'Bellamy',
    'Vane',
    'Rackham',
    'Avery',
    'Blackwood',
    'Flint',
    'Hawkins',
    'Silver',
    'Morton',
    'Cross',
    'Storm',
    'Holloway',
    'Vanderbilt',
  ];

  static const List<String> captainEpithets = [
    'The Fearless',
    'Iron-Gut',
    'Sea Dog',
    'Storm-Chaser',
    'The Cunning',
    'One-Eye',
    'The Relentless',
    'The Grim',
    'Barnacle',
    'Wave-Crest',
    'The Unsinkable',
    'Old Salt',
    'The Bold',
    'Ghost of the Reeds',
  ];

  /// Generates a procedural captain name, optionally appending an epithet.
  static String generateCaptainName(GameRng rng, {bool includeEpithet = false}) {
    final first = captainFirstNames[rng.nextInt(captainFirstNames.length)];
    final last = captainLastNames[rng.nextInt(captainLastNames.length)];
    if (includeEpithet) {
      final epithet = captainEpithets[rng.nextInt(captainEpithets.length)];
      return '$first $last, $epithet';
    }
    return '$first $last';
  }

  /// Generates a procedural ship name for the given [shipClass].
  static String generateShipName(ShipClass shipClass, GameRng rng) {
    final List<String> adjectives;
    switch (shipClass) {
      case ShipClass.standard:
        adjectives = standardShipAdjectives;
      case ShipClass.freighter || ShipClass.corsair:
        adjectives = freighterAdjectives;
      case ShipClass.ironclad || ShipClass.bombardier:
        adjectives = ironcladAdjectives;
      case ShipClass.corvette || ShipClass.clipper:
        adjectives = corvetteAdjectives;
    }
    final adj = adjectives[rng.nextInt(adjectives.length)];
    return '$adj ${shipClass.displayName}';
  }

  /// Generates a procedural monster name for the given [species].
  static String generateMonsterName(MonsterSpecies species, GameRng rng) {
    switch (species) {
      case MonsterSpecies.shark:
        return sharkNames[rng.nextInt(sharkNames.length)];
      case MonsterSpecies.serpent:
        return serpentNames[rng.nextInt(serpentNames.length)];
      case MonsterSpecies.jellyfish:
        return jellyfishNames[rng.nextInt(jellyfishNames.length)];
      case MonsterSpecies.squid:
        return squidNames[rng.nextInt(squidNames.length)];
      case MonsterSpecies.crustacean:
        return crustaceanNames[rng.nextInt(crustaceanNames.length)];
      case MonsterSpecies.kraken:
        return krakenTitles[rng.nextInt(krakenTitles.length)];
      case MonsterSpecies.worldSerpent:
        return 'Jörmungandr, The World Serpent';
      case MonsterSpecies.ancientLeviathan:
        return 'The Ancient Leviathan';
    }
  }

  /// Generates a title specifically for The Kraken.
  static String generateKrakenTitle(GameRng rng) {
    return krakenTitles[rng.nextInt(krakenTitles.length)];
  }
}
