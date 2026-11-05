import 'package:monstrous_core/monstrous_core.dart';

import '../strategy/voyage_economy_bot.dart';

/// Controlled comparison: identical actual creature/combat RNG and build,
/// with a forced normal wreck ambush versus the same normal hunt.
/// This measures the extra won cargo; it does not model whole-route survival.
Map<String, dynamic> auditMatchedEncounter({
  required int seed,
  required int region,
  required bool capped,
  required WreckCondition condition,
  bool combinedHealing = false,
}) {
  GameSession make(bool wreck) {
    final rng = _ResettableRng(seed);
    final s = GameSession(
      rng: rng,
      navigationTuning: const NavigationTuning(
        wrecks: WreckTuning(approachAmbushChance: 100),
      ),
    )..dispatch(const BeginFirstVoyage('Matched comparison'));
    if (combinedHealing) {
      s.activeBoon = BloodlineTrait.skilledCarpenter;
      s.activeQuirk = BloodlineTrait.exactingShipwright;
    }
    if (capped) {
      s.phase = SessionPhase.stronghold;
      s.ship!.gold = 1390;
      for (var i = 0; i < 3; i++) {
        s.dispatch(const UpgradeShip());
      }
      for (final slot in [
        HardpointType.broadside,
        HardpointType.signature,
        HardpointType.utility,
      ]) {
        s.dispatch(TemperHardpoint(slot));
        s.dispatch(TemperHardpoint(slot));
      }
    }
    for (var r = 0; r < region; r++) {
      s.seaChart.advanceRegion(rng);
    }
    s.seaChart.currentLeg = 2;
    final level = 2 + region * 4;
    final state = s.seaChart.toJson()
      ..['courseOptions'] = [
        CourseOption(
          bearing: NavigationalBearing.deadAhead,
          nodeType: wreck
              ? EncounterNodeType.shipwreckSalvage
              : EncounterNodeType.beastCombat,
          difficultyLevel: level,
          lookoutCall: 'Controlled comparison',
          monsterSpecies: wreck ? null : MonsterSpecies.shark,
          wreckSighting: wreck
              ? WreckSighting(seed: seed, condition: condition, clearClue: true)
              : null,
        ).toJson(),
      ];
    s.seaChart.restoreFromJson(state);
    s.phase = SessionPhase.helm;
    s.ship!
      ..gold = 0
      ..currentHp = s.ship!.maxHp;
    s.dispatch(const SteerCourse(NavigationalBearing.deadAhead));
    // Equal factories, opening intent and action RNG replace only setup noise.
    // Real subsequent damage, cooldowns, deaths and rewards remain core-owned.
    s.currentMonster = createMonster(
      MonsterSpecies.shark,
      level: level,
      rng: SeededGameRng(seed + 77),
    );
    s.currentMonster!.currentIntent = selectNextMonsterIntent(
      s.currentMonster!,
      s.combatRange,
      SeededGameRng(seed + 78),
      battleRound: 1,
    );
    rng.reset(seed + 79);
    return s;
  }

  final hunt = make(false), wreck = make(true);
  void fight(GameSession s) {
    final bot = VoyageEconomyBot(VoyagePolicy.mixed);
    var steps = 0;
    while (s.phase == SessionPhase.battle && steps++ < 500) {
      s.dispatch(bot.decideNextAction(s));
    }
    if (steps >= 500) throw StateError('Matched combat exceeded guard');
  }

  fight(hunt);
  fight(wreck);
  if (hunt.phase != wreck.phase ||
      hunt.ship!.currentHp != wreck.ship!.currentHp ||
      hunt.lastGoldSalvaged != wreck.lastGoldSalvaged) {
    throw StateError('Matched encounters diverged before cargo: seed $seed');
  }
  final huntMeta = hunt.profile.metaInventory.toJson();
  final wreckMeta = wreck.profile.metaInventory.toJson();
  final huntSupplies = hunt.pendingLoot
      .whereType<Consumable>()
      .map((i) => i.type.name)
      .join(',');
  final wreckSupplies = wreck.pendingLoot
      .whereType<Consumable>()
      .map((i) => i.type.name)
      .join(',');
  if (huntMeta.entries.any((entry) => wreckMeta[entry.key] != entry.value) ||
      huntSupplies != wreckSupplies) {
    throw StateError('Matched organic/tactical rewards diverged: seed $seed');
  }
  final won = hunt.phase == SessionPhase.loot;
  final result = <String, dynamic>{
    'seed': seed,
    'region': region + 1,
    'capped': capped,
    'combinedHealing': combinedHealing,
    'condition': condition.name,
    'won': won,
    'hp': hunt.ship!.currentHp,
    'maxHp': hunt.ship!.maxHp,
    'bountyEach': hunt.lastGoldSalvaged,
    'organicEach': hunt.profile.metaInventory.toJson(),
    'tacticalSuppliesEach': hunt.pendingLoot.length,
  };
  if (won) {
    wreck.dispatch(const LeaveRemainingLoot());
    wreck.dispatch(
      ChooseWreckRecovery(
        wreck.currentWreck!.id,
        WreckRecoveryChoice.recoverClearedCargo,
      ),
    );
    result['extraCargo'] = wreck.currentWreck!.cargo!.toJson();
  }
  return result;
}

class _ResettableRng extends SeededGameRng {
  _ResettableRng(int seed) : _delegate = SeededGameRng(seed);
  GameRng _delegate;
  void reset(int seed) => _delegate = SeededGameRng(seed);
  @override
  int nextInt(int maxExclusive) => _delegate.nextInt(maxExclusive);
  @override
  int nextIntRange(int minInclusive, int maxInclusive) =>
      _delegate.nextIntRange(minInclusive, maxInclusive);
  @override
  double nextDouble() => _delegate.nextDouble();
  @override
  int d(int n) => _delegate.d(n);
  @override
  int d20() => _delegate.d20();
  @override
  int d100() => _delegate.d100();
}
