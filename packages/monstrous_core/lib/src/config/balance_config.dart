/// Global balance parameters and tuning knobs for The Monstrous Sea.
///
/// Encapsulates all constants, drop rates, and progression multipliers
/// without hardcoding them into game logic.
class BalanceConfig {
  const BalanceConfig({
    this.treasureDropWeight = 60,
    this.consumableDropWeight = 20,
    this.weaponDropWeight = 20,
    this.minItemsDropped = 3,
    this.maxItemsDropped = 6,
    this.testingPriceExponentBase = 1.25,
    this.testingWeaponExponentBase = 1.25,
    this.baseFleeThresholdLevel1 = 60, // 40% chance (d100 > 60) per B3 fix
    this.fleePenaltyPerLevel = 5,
    this.maxFleeDifficultyLevel = 6,
    this.hardcodedFleeFloorThreshold = 95, // 5% chance
    this.monsterAttackProbability = 80, // 80% attack vs 20% special
    this.statusEffectTickDamageMultiplier = 5, // 5 * difficulty
    this.statusWearOffChance = 25, // 25% wear off each turn
    this.stunWearOffChanceMonster = 50, // 50% wear off
    this.krakenBossDifficulty = 5,
  });

  /// Standard configuration matching original game intent with bug fixes.
  static const standard = BalanceConfig();

  final int treasureDropWeight;
  final int consumableDropWeight;
  final int weaponDropWeight;
  final int minItemsDropped;
  final int maxItemsDropped;
  final double testingPriceExponentBase;
  final double testingWeaponExponentBase;
  final int baseFleeThresholdLevel1;
  final int fleePenaltyPerLevel;
  final int maxFleeDifficultyLevel;
  final int hardcodedFleeFloorThreshold;
  final int monsterAttackProbability;
  final int statusEffectTickDamageMultiplier;
  final int statusWearOffChance;
  final int stunWearOffChanceMonster;
  final int krakenBossDifficulty;
}
