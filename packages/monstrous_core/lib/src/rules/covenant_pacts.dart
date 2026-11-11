import '../model/enums.dart';

/// Existing pact parameters shared by the resolver and home-port previews.
abstract final class CovenantPactEffects {
  static const monsterHpMultiplier = 1.25;
  static const extraCarapace = 10;
  static const monsterAttackMultiplier = 1.15;
  static const automaticSharkFrenzyThreshold = 0.60;
  static const shoreHealingMultiplier = 0.75;
  static const shipwrightRepairPriceMultiplier = 1.30;

  static int kelpEvasionPenalty(bool volatile) => volatile ? 20 : 10;
  static int scaldInterval(bool volatile) => volatile ? 2 : 3;
  static int scaldDamage(bool volatile) => volatile ? 15 : 10;
  static int apexChanceMultiplier(bool active) => active ? 2 : 1;

  static int titanCinders(MonsterSpecies? species, int burden) => burden > 0
      ? switch (species) {
          MonsterSpecies.kraken => 1 + (burden ~/ 2),
          MonsterSpecies.worldSerpent => 2 + (burden ~/ 2),
          MonsterSpecies.ancientLeviathan => 3 + burden,
          _ => 0,
        }
      : 0;
}
