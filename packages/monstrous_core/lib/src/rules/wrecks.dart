import '../config/wreck_tuning.dart';
import '../content/consumables.dart';
import '../content/monsters.dart';
import '../model/combatant.dart';
import '../model/enums.dart';
import '../model/item.dart';
import '../model/wreck_encounter.dart';
import '../rng/game_rng.dart';

WreckSighting generateWreckSighting(GameRng rng, WreckTuning tuning) {
  final seed = rng.nextInt(1 << 30);
  final local = SeededGameRng(seed);
  final roll = local.nextInt(100);
  return WreckSighting(
    seed: seed,
    condition: roll < tuning.pickedCleanWeight
        ? WreckCondition.pickedClean
        : roll < tuning.pickedCleanWeight + tuning.uncertainWeight
        ? WreckCondition.uncertain
        : WreckCondition.fresh,
    clearClue: local.nextInt(100) < tuning.clearClueChance,
  );
}

bool wreckApproachAmbush(WreckEncounter wreck, WreckTuning tuning) =>
    SeededGameRng(wreck.sighting.seed ^ 0x217ad1).nextInt(100) <
    tuning.approachAmbushChance;

bool wreckCommittedFight(WreckEncounter wreck, WreckTuning tuning) =>
    SeededGameRng(wreck.sighting.seed ^ 0x56a371).nextInt(100) <
    (wreck.condition == WreckCondition.fresh
        ? tuning.freshFightChance
        : tuning.uncertainFightChance);

WreckThreat generateWreckThreat(
  WreckEncounter wreck,
  int region,
  int level, {
  required bool approach,
  required bool apexEmergence,
  required WreckTuning tuning,
}) {
  final rng = SeededGameRng(
    wreck.sighting.seed ^ (approach ? 0x7ad217 : 0x1973ac),
  );
  final pool = MonsterSpecies.values
      .where(
        (s) =>
            !s.isRegionTitan && (region > 0 || s != MonsterSpecies.crustacean),
      )
      .toList();
  final species = pool[rng.nextInt(pool.length)];
  // Eligibility comes first: forced approach fights can never become Apex.
  final isApex =
      !approach &&
      rng.nextInt(100) < tuning.apexChanceForRegion(region) * (apexEmergence ? 2 : 1);
  return WreckThreat(
    species: species,
    level: level,
    isApex: isApex,
    seed: rng.nextInt(1 << 30),
  );
}

MonsterState instantiateWreckThreat(WreckThreat threat) => createMonster(
  threat.species,
  level: threat.level,
  isApex: threat.isApex,
  rng: SeededGameRng(threat.seed),
);

WreckCargo generateWreckCargo(
  WreckEncounter wreck,
  WreckTuning tuning, {
  required bool quick,
}) {
  final profile = quick || wreck.condition == WreckCondition.pickedClean
      ? tuning.small
      : wreck.condition == WreckCondition.fresh
      ? tuning.fresh
      : tuning.deeper;
  final rng = SeededGameRng(
    wreck.sighting.seed ^ (quick ? 0x311a92 : 0x622c17),
  );
  final glass = rng.nextIntRange(profile.glassMin, profile.glassMax);
  final iron = rng.nextInt(100) < profile.ironChance
      ? rng.nextIntRange(1, profile.ironMax)
      : 0;
  final supplies = rng.nextInt(100) < profile.supplyChance
      ? [randomConsumable(1, rng, id: '${wreck.id}:cargo')]
      : <Consumable>[];
  final gold = rng.nextInt(100) < profile.goldChance
      ? rng.nextIntRange(profile.goldMin, profile.goldMax)
      : 0;
  return WreckCargo(
    seaGlass: glass,
    iron: iron,
    gold: gold,
    supplies: supplies,
  );
}
