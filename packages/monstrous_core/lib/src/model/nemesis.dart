import '../content/monsters.dart';
import '../rng/game_rng.dart';
import 'combatant.dart';
import 'enums.dart';

/// Represents an empowered sea beast that dealt the fatal blow to a predecessor captain.
///
/// Absorbs pact resonance and residual life force, ascending to an empowered Nemesis
/// with an infamy moniker, elevated durability, and high bounty.
class NemesisRecord {
  const NemesisRecord({
    required this.species,
    required this.baseName,
    required this.moniker,
    required this.predecessorCaptain,
    required this.regionIndex,
    required this.level,
    required this.bonusHp,
    required this.bonusCarapace,
    required this.bountyGold,
    required this.bountySeaGlass,
    required this.bountyMonsterBone,
    required this.bountyBarnacles,
  });

  factory NemesisRecord.createFromDefeat({
    required MonsterState killer,
    required String captainName,
    required int regionIndex,
    required GameRng rng,
  }) {
    final moniker = _generateMoniker(killer.species, killer.name, captainName, rng);
    final level = killer.level;
    final bonusHp = (killer.maxHp * 0.30).round();
    final bonusCarapace = 25 + (level * 5);

    return NemesisRecord(
      species: killer.species,
      baseName: killer.name,
      moniker: moniker,
      predecessorCaptain: captainName,
      regionIndex: regionIndex,
      level: level,
      bonusHp: bonusHp,
      bonusCarapace: bonusCarapace,
      bountyGold: 100 + (level * 50),
      bountySeaGlass: 5 + (level * 2),
      bountyMonsterBone: 6 + (level * 3),
      bountyBarnacles: 2 + level,
    );
  }

  factory NemesisRecord.fromJson(Map<String, dynamic> json) {
    final speciesName = json['species'] as String;
    final species = MonsterSpecies.values.firstWhere(
      (e) => e.name == speciesName,
      orElse: () => MonsterSpecies.shark,
    );

    return NemesisRecord(
      species: species,
      baseName: json['baseName'] as String,
      moniker: json['moniker'] as String,
      predecessorCaptain: json['predecessorCaptain'] as String,
      regionIndex: json['regionIndex'] as int,
      level: json['level'] as int,
      bonusHp: json['bonusHp'] as int,
      bonusCarapace: json['bonusCarapace'] as int,
      bountyGold: json['bountyGold'] as int,
      bountySeaGlass: json['bountySeaGlass'] as int,
      bountyMonsterBone: json['bountyMonsterBone'] as int,
      bountyBarnacles: json['bountyBarnacles'] as int,
    );
  }

  final MonsterSpecies species;
  final String baseName;
  final String moniker;
  final String predecessorCaptain;
  final int regionIndex;
  final int level;
  final int bonusHp;
  final int bonusCarapace;

  final int bountyGold;
  final int bountySeaGlass;
  final int bountyMonsterBone;
  final int bountyBarnacles;

  /// Spawns an empowered, apex-afflicted [MonsterState] corresponding to this nemesis.
  MonsterState instantiateMonster(GameRng rng) {
    final monster = createMonster(
      species,
      level: level,
      rng: rng,
      isApex: true,
    );

    monster.name = moniker;
    monster.maxHp += bonusHp;
    monster.currentHp = monster.maxHp;
    monster.carapacePlating += bonusCarapace;
    monster.maxCarapace = monster.carapacePlating;
    monster.apexTitle = 'Nemesis of the Bloodline';

    return monster;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'species': species.name,
        'baseName': baseName,
        'moniker': moniker,
        'predecessorCaptain': predecessorCaptain,
        'regionIndex': regionIndex,
        'level': level,
        'bonusHp': bonusHp,
        'bonusCarapace': bonusCarapace,
        'bountyGold': bountyGold,
        'bountySeaGlass': bountySeaGlass,
        'bountyMonsterBone': bountyMonsterBone,
        'bountyBarnacles': bountyBarnacles,
      };

  @override
  String toString() => '$moniker (Level $level $species in Region $regionIndex)';

  static String _generateMoniker(
    MonsterSpecies species,
    String baseName,
    String captainName,
    GameRng rng,
  ) {
    final templates = switch (species) {
      MonsterSpecies.shark => [
          '$baseName — The Butcher of Captain $captainName',
          '$baseName — $captainName\'s Undertaker',
          '$baseName — The Crimson Maw of $captainName',
        ],
      MonsterSpecies.serpent => [
          '$baseName — The Coils of $captainName\'s Doom',
          '$baseName — The Strangler of Captain $captainName',
          '$baseName — Siphon of $captainName\'s Life',
        ],
      MonsterSpecies.crustacean => [
          '$baseName — The Crusher of $captainName\'s Keel',
          '$baseName — The Iron-Shatterer of $captainName',
          '$baseName — Cleaver of Captain $captainName',
        ],
      MonsterSpecies.squid => [
          '$baseName — The Drowner of Captain $captainName',
          '$baseName — The Abyssal Maw of $captainName',
          '$baseName — The Grasp of $captainName\'s End',
        ],
      MonsterSpecies.jellyfish => [
          '$baseName — The Phosphor Shroud of $captainName',
          '$baseName — The Death-Sting of Captain $captainName',
          '$baseName — The Ghost of $captainName\'s Hubris',
        ],
      MonsterSpecies.kraken => [
          '$baseName — Leviathan Bane of Captain $captainName',
          '$baseName — Devourer of the $captainName Bloodline',
        ],
      MonsterSpecies.worldSerpent => [
          '$baseName — World-Eater of Captain $captainName',
          '$baseName — The Coils of $captainName\'s Ruin',
        ],
      MonsterSpecies.ancientLeviathan => [
          '$baseName — The Abyssal Maw of $captainName',
          '$baseName — Extinguisher of the $captainName Lineage',
        ],
    };

    return templates[rng.nextInt(templates.length)];
  }
}
