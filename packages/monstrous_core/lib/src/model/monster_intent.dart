import '../lore/monster_intent_lore.dart';
import 'enums.dart';

/// Unique identifiers for all telegraphed monster intents and boss wind-ups.
enum MonsterIntentId {
  normalStrike,
  // Shark
  sharkRiptideWake,
  sharkBreachingLunge,
  sharkFrenziedJaws,

  // Crustacean
  crustaceanCalcifyCarapace,
  crustaceanBrineJet,
  crustaceanTremorSlam,
  crustaceanHydraulicGuillotine,

  // Jellyfish
  jellyfishArcPulse,
  jellyfishNematocystCurtain,
  jellyfishNeurotoxinEmbrace,

  // Serpent
  serpentAbyssalUnderStrike,
  serpentVenomSpitRecoil,
  serpentFangedWhipRecoil,

  // Squid
  squidFeedingTentacleSnare,
  squidSweepingTentacles,
  squidConstrictingBeak,
  squidInkShroudRecoil,

  // Region Boss 2-Turn Wind-ups & Catastrophes
  bossKrakenWindup,
  bossKrakenCatastrophe,
  bossWorldSerpentWindup,
  bossWorldSerpentCatastrophe,
  bossLeviathanWindup,
  bossLeviathanCatastrophe;

  MonsterIntentLoreEntry get lore => switch (this) {
    MonsterIntentId.normalStrike => MonsterIntentLore.normalStrike,
    MonsterIntentId.sharkRiptideWake => MonsterIntentLore.sharkRiptideWake,
    MonsterIntentId.sharkBreachingLunge =>
      MonsterIntentLore.sharkBreachingLunge,
    MonsterIntentId.sharkFrenziedJaws => MonsterIntentLore.sharkFrenziedJaws,
    MonsterIntentId.crustaceanCalcifyCarapace =>
      MonsterIntentLore.crustaceanCalcifyCarapace,
    MonsterIntentId.crustaceanBrineJet => MonsterIntentLore.crustaceanBrineJet,
    MonsterIntentId.crustaceanTremorSlam =>
      MonsterIntentLore.crustaceanTremorSlam,
    MonsterIntentId.crustaceanHydraulicGuillotine =>
      MonsterIntentLore.crustaceanHydraulicGuillotine,
    MonsterIntentId.jellyfishArcPulse => MonsterIntentLore.jellyfishArcPulse,
    MonsterIntentId.jellyfishNematocystCurtain =>
      MonsterIntentLore.jellyfishNematocystCurtain,
    MonsterIntentId.jellyfishNeurotoxinEmbrace =>
      MonsterIntentLore.jellyfishNeurotoxinEmbrace,
    MonsterIntentId.serpentAbyssalUnderStrike =>
      MonsterIntentLore.serpentAbyssalUnderStrike,
    MonsterIntentId.serpentVenomSpitRecoil =>
      MonsterIntentLore.serpentVenomSpitRecoil,
    MonsterIntentId.serpentFangedWhipRecoil =>
      MonsterIntentLore.serpentFangedWhipRecoil,
    MonsterIntentId.squidFeedingTentacleSnare =>
      MonsterIntentLore.squidFeedingTentacleSnare,
    MonsterIntentId.squidSweepingTentacles =>
      MonsterIntentLore.squidSweepingTentacles,
    MonsterIntentId.squidConstrictingBeak =>
      MonsterIntentLore.squidConstrictingBeak,
    MonsterIntentId.squidInkShroudRecoil =>
      MonsterIntentLore.squidInkShroudRecoil,
    MonsterIntentId.bossKrakenWindup => MonsterIntentLore.bossKrakenWindup,
    MonsterIntentId.bossKrakenCatastrophe =>
      MonsterIntentLore.bossKrakenCatastrophe,
    MonsterIntentId.bossWorldSerpentWindup =>
      MonsterIntentLore.bossWorldSerpentWindup,
    MonsterIntentId.bossWorldSerpentCatastrophe =>
      MonsterIntentLore.bossWorldSerpentCatastrophe,
    MonsterIntentId.bossLeviathanWindup =>
      MonsterIntentLore.bossLeviathanWindup,
    MonsterIntentId.bossLeviathanCatastrophe =>
      MonsterIntentLore.bossLeviathanCatastrophe,
  };
}

/// How a monster intent alters the engagement distance between flagship and beast.
enum IntentMoveDelta {
  /// Monster holds its current spatial bearing.
  stationary,

  /// Monster surges 1 range band closer (Long -> Medium, Medium -> Short).
  closer1,

  /// Monster recoils/slithers 1 range band farther away (Short -> Medium, Medium -> Long).
  farther1,

  /// Monster reels the flagship 1 range band closer on attack execution.
  pullShipCloser1,

  /// Monster dives deep and erupts directly beneath the keel at Short Range.
  ambushToShort,
}

/// Whether the monster's spatial movement occurs before or after its attack resolves.
enum IntentMoveTiming { none, beforeAttack, afterAttack }

/// Tactical classification of how the player's planned helm maneuver interacts
/// with the monster's telegraphed intent.
enum IntentPreviewStatus {
  /// Ship will end up outside the monster's threatened range bands (0 damage).
  evadedByPosition,

  /// Ship will be inside the monster's threatened range bands when it strikes.
  inThreatZone,

  /// Ship is steering directly into a charging beast at Short Range (+30% collision impact).
  headOnCollisionDanger,

  /// Boss is on Turn 1 of a 2-turn wind-up (no strike this turn; opportunity to break poise).
  bossWindupSafeThisTurn,

  /// Boss is on Turn 2 of a 2-turn catastrophe (hits all ranges this turn unless disrupted).
  bossCatastropheImminent,

  /// Monster is executing a non-attack buff or shell restoration.
  nonAttackBuff,
}

/// Result of evaluating a [MonsterIntent] against a planned player [HelmOrder].
class IntentPreviewOutcome {
  const IntentPreviewOutcome({
    required this.status,
    required this.playerPostHelmRange,
    required this.rangeAtStrike,
    required this.projectedEndOfRoundRange,
    required this.estimatedDamage,
    required this.summaryBadge,
  });

  final IntentPreviewStatus status;
  final CombatRange playerPostHelmRange;
  final CombatRange rangeAtStrike;
  final CombatRange projectedEndOfRoundRange;
  final int estimatedDamage;
  final String summaryBadge;

  bool get isSafe =>
      status == IntentPreviewStatus.evadedByPosition ||
      status == IntentPreviewStatus.bossWindupSafeThisTurn ||
      status == IntentPreviewStatus.nonAttackBuff;
}

/// Immutable representation of a monster's telegraphed turn intention.
class MonsterIntent {
  static const krakenMaelstromBaseDamage = 38;

  /// Other Titans retain ordinary accuracy/dodge until separately reviewed.
  bool get isUnavoidable => id == MonsterIntentId.bossKrakenCatastrophe;

  const MonsterIntent({
    required this.id,
    required this.threatenedRanges,
    this.moveDelta = IntentMoveDelta.stationary,
    this.moveTiming = IntentMoveTiming.none,
    this.damageMultiplier = 1.0,
    required this.estimatedDamage,
    this.cooldownTurns = 0,
    this.isBossWindup = false,
    this.isBossCatastropheStrike = false,
    this.followUpStrikeId,
    this.poiseThreshold = 0,
  });

  final MonsterIntentId id;
  final Set<CombatRange> threatenedRanges;
  final IntentMoveDelta moveDelta;
  final IntentMoveTiming moveTiming;
  final double damageMultiplier;
  final int estimatedDamage;
  final int cooldownTurns;
  final bool isBossWindup;
  final bool isBossCatastropheStrike;
  final MonsterIntentId? followUpStrikeId;
  final int poiseThreshold;

  String get name => id.lore.name;
  String get subtitle => id.lore.subtitle;
  String get description => id.lore.description;
  String get tacticalTip => id.lore.tacticalTip;
  String get telegraphLog => id.lore.telegraphLog;

  /// Human-readable label for the range bands threatened by this intent.
  String get threatenedRangesLabel {
    if (isBossWindup) return 'NEXT TURN: ALL RANGES';
    if (threatenedRanges.isEmpty) return 'SELF / BUFF';
    if (threatenedRanges.length == 3) return 'ALL RANGES';
    final ordered = <String>[];
    if (threatenedRanges.contains(CombatRange.short)) ordered.add('SHORT');
    if (threatenedRanges.contains(CombatRange.medium)) ordered.add('MED');
    if (threatenedRanges.contains(CombatRange.long)) ordered.add('LONG');
    return ordered.join(' • ');
  }

  /// Human-readable label for the monster's movement behavior.
  String get moveLabel => switch (moveDelta) {
    IntentMoveDelta.stationary => 'STATIONARY',
    IntentMoveDelta.closer1 =>
      moveTiming == IntentMoveTiming.beforeAttack
          ? 'PRE-ATTACK CHARGE (+1 CLOSER)'
          : 'POST-ATTACK ADVANCE (+1 CLOSER)',
    IntentMoveDelta.farther1 => 'POST-ATTACK RECOIL (+1 FARTHER)',
    IntentMoveDelta.pullShipCloser1 => 'POST-ATTACK PULL (REELS SHIP +1)',
    IntentMoveDelta.ambushToShort => 'PRE-ATTACK AMBUSH (ERUPTS TO SHORT)',
  };

  /// Explicit timing badge for whether movement occurs before or after the strike.
  String get moveTimingBadge => switch (moveTiming) {
    IntentMoveTiming.beforeAttack => 'PRE-ATTACK',
    IntentMoveTiming.afterAttack => 'POST-ATTACK',
    IntentMoveTiming.none => 'NONE',
  };

  /// Evaluates the exact spatial outcome if the player issues [selectedHelmOrder]
  /// from [currentRange].
  ///
  /// When [helmAlreadyApplied] is true, [currentRange] already includes the
  /// committed helm and any predictable action movement. The order still
  /// identifies head-on collision risk, but is not applied a second time.
  IntentPreviewOutcome evaluatePreview({
    required CombatRange currentRange,
    required HelmOrder selectedHelmOrder,
    bool helmAlreadyApplied = false,
    bool isMonsterPinned = false,
    int? tentacleCount,
    int? damagePerTentacle,
  }) {
    final postHelmRange = helmAlreadyApplied
        ? currentRange
        : currentRange.rangeAfterHelmOrder(selectedHelmOrder);

    if (isBossWindup) {
      return IntentPreviewOutcome(
        status: IntentPreviewStatus.bossWindupSafeThisTurn,
        playerPostHelmRange: postHelmRange,
        rangeAtStrike: postHelmRange,
        projectedEndOfRoundRange: postHelmRange,
        estimatedDamage: 0,
        summaryBadge: 'WIND-UP (1/2): No strike this turn! Disrupt with Mortar, Harpoon, Blast Pack, Stun, or a windup-breaking blessing.',
      );
    }

    if (threatenedRanges.isEmpty) {
      return IntentPreviewOutcome(
        status: IntentPreviewStatus.nonAttackBuff,
        playerPostHelmRange: postHelmRange,
        rangeAtStrike: postHelmRange,
        projectedEndOfRoundRange: postHelmRange,
        estimatedDamage: 0,
        summaryBadge: 'SHELL FORTIFICATION: No direct attack this turn',
      );
    }

    var rangeAtStrike = postHelmRange;
    var willCollideHeadOn = false;

    if (moveTiming == IntentMoveTiming.beforeAttack && !isMonsterPinned) {
      switch (moveDelta) {
        case IntentMoveDelta.closer1:
          if (selectedHelmOrder == HelmOrder.advance &&
              postHelmRange.closer == CombatRange.short) {
            willCollideHeadOn = true;
            rangeAtStrike = CombatRange.short;
          } else {
            rangeAtStrike = postHelmRange.closer;
          }
        case IntentMoveDelta.ambushToShort:
          rangeAtStrike = CombatRange.short;
        case IntentMoveDelta.farther1:
          rangeAtStrike = postHelmRange.farther;
        case IntentMoveDelta.stationary:
        case IntentMoveDelta.pullShipCloser1:
          rangeAtStrike = postHelmRange;
      }
    }

    final inZone = threatenedRanges.contains(rangeAtStrike);

    var endRange = rangeAtStrike;
    if (moveTiming == IntentMoveTiming.afterAttack && !isMonsterPinned) {
      switch (moveDelta) {
        case IntentMoveDelta.farther1:
          endRange = rangeAtStrike.farther;
        case IntentMoveDelta.pullShipCloser1:
          endRange = inZone ? rangeAtStrike.closer : rangeAtStrike;
        case IntentMoveDelta.closer1:
          endRange = rangeAtStrike.closer;
        case IntentMoveDelta.ambushToShort:
          endRange = CombatRange.short;
        case IntentMoveDelta.stationary:
          endRange = rangeAtStrike;
      }
    }

    if (!inZone) {
      return IntentPreviewOutcome(
        status: IntentPreviewStatus.evadedByPosition,
        playerPostHelmRange: postHelmRange,
        rangeAtStrike: rangeAtStrike,
        projectedEndOfRoundRange: endRange,
        estimatedDamage: 0,
        summaryBadge:
            'EVADED BY MANEUVER (${rangeAtStrike.displayName} is outside [$threatenedRangesLabel])',
      );
    }

    if (willCollideHeadOn) {
      final collisionDmg = (estimatedDamage * 1.30).round();
      return IntentPreviewOutcome(
        status: IntentPreviewStatus.headOnCollisionDanger,
        playerPostHelmRange: postHelmRange,
        rangeAtStrike: rangeAtStrike,
        projectedEndOfRoundRange: endRange,
        estimatedDamage: collisionDmg,
        summaryBadge:
            'HEAD-ON COLLISION! (+30% Impact; ~$collisionDmg Dmg if beast survives!)',
      );
    }

    if (isBossCatastropheStrike) {
      return IntentPreviewOutcome(
        status: IntentPreviewStatus.bossCatastropheImminent,
        playerPostHelmRange: postHelmRange,
        rangeAtStrike: rangeAtStrike,
        projectedEndOfRoundRange: endRange,
        estimatedDamage: estimatedDamage,
        summaryBadge:
            isUnavoidable
                ? 'UNAVOIDABLE: ALL RANGES • $krakenMaelstromBaseDamage base Blast damage before weakening and defenses. Interrupt or brace!'
                : 'CATASTROPHE IMMINENT: Strikes ALL RANGES (~$estimatedDamage Dmg)! Disrupt with Stun or a windup-breaking blessing, or brace.',
      );
    }

    if (id == MonsterIntentId.squidSweepingTentacles &&
        tentacleCount != null && damagePerTentacle != null) {
      final perHit = (damagePerTentacle * damageMultiplier).round();
      final total = tentacleCount * perHit;
      return IntentPreviewOutcome(
        status: tentacleCount > 0
            ? IntentPreviewStatus.inThreatZone
            : IntentPreviewStatus.nonAttackBuff,
        playerPostHelmRange: postHelmRange,
        rangeAtStrike: rangeAtStrike,
        projectedEndOfRoundRange: endRange,
        estimatedDamage: total,
        summaryBadge: tentacleCount > 0
            ? 'TENTACLE SWEEP: $tentacleCount x $perHit base Blast (up to $total before accuracy, dodge and defenses). Retreat to Long or sever limbs!'
            : 'NO TENTACLES: No sweep strikes remain.',
      );
    }

    return IntentPreviewOutcome(
      status: IntentPreviewStatus.inThreatZone,
      playerPostHelmRange: postHelmRange,
      rangeAtStrike: rangeAtStrike,
      projectedEndOfRoundRange: endRange,
      estimatedDamage: estimatedDamage,
      summaryBadge:
          'IN THREAT ZONE (${rangeAtStrike.displayName} • Est. ~$estimatedDamage Dmg)',
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id.name,
    'threatenedRanges': threatenedRanges.map((e) => e.name).toList(),
    'moveDelta': moveDelta.name,
    'moveTiming': moveTiming.name,
    'damageMultiplier': damageMultiplier,
    'estimatedDamage': estimatedDamage,
    'cooldownTurns': cooldownTurns,
    'isBossWindup': isBossWindup,
    'isBossCatastropheStrike': isBossCatastropheStrike,
    'followUpStrikeId': followUpStrikeId?.name,
    'poiseThreshold': poiseThreshold,
  };

  factory MonsterIntent.fromJson(Map<String, dynamic> json) {
    final idName = json['id'] as String? ?? 'sharkBreachingLunge';
    final id = MonsterIntentId.values.firstWhere(
      (e) => e.name == idName,
      orElse: () => MonsterIntentId.sharkBreachingLunge,
    );
    final rangesList =
        (json['threatenedRanges'] as List<dynamic>?)
            ?.map(
              (e) => CombatRange.values.firstWhere(
                (r) => r.name == e,
                orElse: () => CombatRange.medium,
              ),
            )
            .toSet() ??
        const <CombatRange>{CombatRange.short, CombatRange.medium};
    final moveDeltaName = json['moveDelta'] as String? ?? 'stationary';
    final moveDelta = IntentMoveDelta.values.firstWhere(
      (e) => e.name == moveDeltaName,
      orElse: () => IntentMoveDelta.stationary,
    );
    final moveTimingName = json['moveTiming'] as String? ?? 'none';
    final moveTiming = IntentMoveTiming.values.firstWhere(
      (e) => e.name == moveTimingName,
      orElse: () => IntentMoveTiming.none,
    );
    final followUpName = json['followUpStrikeId'] as String?;
    final followUp = followUpName != null
        ? MonsterIntentId.values.firstWhere(
            (e) => e.name == followUpName,
            orElse: () => MonsterIntentId.bossKrakenCatastrophe,
          )
        : null;

    return MonsterIntent(
      id: id,
      threatenedRanges: rangesList,
      moveDelta: moveDelta,
      moveTiming: moveTiming,
      damageMultiplier: (json['damageMultiplier'] as num?)?.toDouble() ?? 1.0,
      estimatedDamage: json['estimatedDamage'] as int? ?? 15,
      cooldownTurns: json['cooldownTurns'] as int? ?? 0,
      isBossWindup: json['isBossWindup'] as bool? ?? false,
      isBossCatastropheStrike:
          json['isBossCatastropheStrike'] as bool? ?? false,
      followUpStrikeId: followUp,
      poiseThreshold: json['poiseThreshold'] as int? ?? 0,
    );
  }

  static MonsterIntent fromId(MonsterIntentId id) => catalog[id]!;

  static const Map<MonsterIntentId, MonsterIntent> catalog = {
    MonsterIntentId.normalStrike: MonsterIntent(
      id: MonsterIntentId.normalStrike,
      threatenedRanges: {
        CombatRange.short,
        CombatRange.medium,
        CombatRange.long,
      },
      moveDelta: IntentMoveDelta.stationary,
      moveTiming: IntentMoveTiming.none,
      damageMultiplier: 1.0,
      estimatedDamage: 15,
    ),
    // Shark
    MonsterIntentId.sharkRiptideWake: MonsterIntent(
      id: MonsterIntentId.sharkRiptideWake,
      threatenedRanges: {CombatRange.medium, CombatRange.long},
      moveDelta: IntentMoveDelta.closer1,
      moveTiming: IntentMoveTiming.beforeAttack,
      damageMultiplier: 1.0,
      estimatedDamage: 14,
    ),
    MonsterIntentId.sharkBreachingLunge: MonsterIntent(
      id: MonsterIntentId.sharkBreachingLunge,
      threatenedRanges: {CombatRange.short, CombatRange.medium},
      moveDelta: IntentMoveDelta.closer1,
      moveTiming: IntentMoveTiming.beforeAttack,
      damageMultiplier: 1.15,
      estimatedDamage: 18,
    ),
    MonsterIntentId.sharkFrenziedJaws: MonsterIntent(
      id: MonsterIntentId.sharkFrenziedJaws,
      threatenedRanges: {CombatRange.short},
      moveDelta: IntentMoveDelta.stationary,
      moveTiming: IntentMoveTiming.none,
      damageMultiplier: 1.25,
      estimatedDamage: 22,
    ),

    // Crustacean
    MonsterIntentId.crustaceanCalcifyCarapace: MonsterIntent(
      id: MonsterIntentId.crustaceanCalcifyCarapace,
      threatenedRanges: {},
      moveDelta: IntentMoveDelta.stationary,
      moveTiming: IntentMoveTiming.none,
      damageMultiplier: 0.0,
      estimatedDamage: 0,
      cooldownTurns: 3,
    ),
    MonsterIntentId.crustaceanBrineJet: MonsterIntent(
      id: MonsterIntentId.crustaceanBrineJet,
      threatenedRanges: {CombatRange.medium, CombatRange.long},
      moveDelta: IntentMoveDelta.stationary,
      moveTiming: IntentMoveTiming.none,
      damageMultiplier: 1.0,
      estimatedDamage: 15,
    ),
    MonsterIntentId.crustaceanTremorSlam: MonsterIntent(
      id: MonsterIntentId.crustaceanTremorSlam,
      threatenedRanges: {CombatRange.short, CombatRange.medium},
      moveDelta: IntentMoveDelta.stationary,
      moveTiming: IntentMoveTiming.none,
      damageMultiplier: 1.1,
      estimatedDamage: 16,
      cooldownTurns: 2,
    ),
    MonsterIntentId.crustaceanHydraulicGuillotine: MonsterIntent(
      id: MonsterIntentId.crustaceanHydraulicGuillotine,
      threatenedRanges: {CombatRange.short},
      moveDelta: IntentMoveDelta.stationary,
      moveTiming: IntentMoveTiming.none,
      damageMultiplier: 1.45,
      estimatedDamage: 26,
    ),

    // Jellyfish
    MonsterIntentId.jellyfishArcPulse: MonsterIntent(
      id: MonsterIntentId.jellyfishArcPulse,
      threatenedRanges: {CombatRange.medium, CombatRange.long},
      moveDelta: IntentMoveDelta.closer1,
      moveTiming: IntentMoveTiming.beforeAttack,
      damageMultiplier: 1.0,
      estimatedDamage: 14,
    ),
    MonsterIntentId.jellyfishNematocystCurtain: MonsterIntent(
      id: MonsterIntentId.jellyfishNematocystCurtain,
      threatenedRanges: {CombatRange.short, CombatRange.medium},
      moveDelta: IntentMoveDelta.stationary,
      moveTiming: IntentMoveTiming.none,
      damageMultiplier: 1.0,
      estimatedDamage: 15,
    ),
    MonsterIntentId.jellyfishNeurotoxinEmbrace: MonsterIntent(
      id: MonsterIntentId.jellyfishNeurotoxinEmbrace,
      threatenedRanges: {CombatRange.short},
      moveDelta: IntentMoveDelta.stationary,
      moveTiming: IntentMoveTiming.none,
      damageMultiplier: 1.2,
      estimatedDamage: 18,
      cooldownTurns: 2,
    ),

    // Serpent
    MonsterIntentId.serpentAbyssalUnderStrike: MonsterIntent(
      id: MonsterIntentId.serpentAbyssalUnderStrike,
      threatenedRanges: {
        CombatRange.short,
        CombatRange.medium,
        CombatRange.long,
      },
      moveDelta: IntentMoveDelta.ambushToShort,
      moveTiming: IntentMoveTiming.beforeAttack,
      damageMultiplier: 1.25,
      estimatedDamage: 20,
    ),
    MonsterIntentId.serpentVenomSpitRecoil: MonsterIntent(
      id: MonsterIntentId.serpentVenomSpitRecoil,
      threatenedRanges: {CombatRange.medium, CombatRange.long},
      moveDelta: IntentMoveDelta.farther1,
      moveTiming: IntentMoveTiming.afterAttack,
      damageMultiplier: 1.0,
      estimatedDamage: 15,
      cooldownTurns: 1,
    ),
    MonsterIntentId.serpentFangedWhipRecoil: MonsterIntent(
      id: MonsterIntentId.serpentFangedWhipRecoil,
      threatenedRanges: {CombatRange.short, CombatRange.medium},
      moveDelta: IntentMoveDelta.farther1,
      moveTiming: IntentMoveTiming.afterAttack,
      damageMultiplier: 1.1,
      estimatedDamage: 16,
    ),

    // Squid
    MonsterIntentId.squidFeedingTentacleSnare: MonsterIntent(
      id: MonsterIntentId.squidFeedingTentacleSnare,
      threatenedRanges: {CombatRange.medium, CombatRange.long},
      moveDelta: IntentMoveDelta.pullShipCloser1,
      moveTiming: IntentMoveTiming.afterAttack,
      damageMultiplier: 1.0,
      estimatedDamage: 15,
    ),
    MonsterIntentId.squidSweepingTentacles: MonsterIntent(
      id: MonsterIntentId.squidSweepingTentacles,
      threatenedRanges: {CombatRange.short, CombatRange.medium},
      moveDelta: IntentMoveDelta.stationary,
      moveTiming: IntentMoveTiming.none,
      damageMultiplier: 1.0,
      estimatedDamage: 15,
    ),
    MonsterIntentId.squidConstrictingBeak: MonsterIntent(
      id: MonsterIntentId.squidConstrictingBeak,
      threatenedRanges: {CombatRange.short},
      moveDelta: IntentMoveDelta.stationary,
      moveTiming: IntentMoveTiming.none,
      damageMultiplier: 1.25,
      estimatedDamage: 20,
      cooldownTurns: 2,
    ),
    MonsterIntentId.squidInkShroudRecoil: MonsterIntent(
      id: MonsterIntentId.squidInkShroudRecoil,
      threatenedRanges: {CombatRange.short, CombatRange.medium},
      moveDelta: IntentMoveDelta.farther1,
      moveTiming: IntentMoveTiming.afterAttack,
      damageMultiplier: 1.0,
      estimatedDamage: 14,
      cooldownTurns: 2,
    ),

    // Bosses
    MonsterIntentId.bossKrakenWindup: MonsterIntent(
      id: MonsterIntentId.bossKrakenWindup,
      threatenedRanges: {},
      moveDelta: IntentMoveDelta.stationary,
      moveTiming: IntentMoveTiming.none,
      damageMultiplier: 0.0,
      estimatedDamage: 0,
      isBossWindup: true,
      followUpStrikeId: MonsterIntentId.bossKrakenCatastrophe,
      poiseThreshold: 45,
    ),
    MonsterIntentId.bossKrakenCatastrophe: MonsterIntent(
      id: MonsterIntentId.bossKrakenCatastrophe,
      threatenedRanges: {
        CombatRange.short,
        CombatRange.medium,
        CombatRange.long,
      },
      moveDelta: IntentMoveDelta.stationary,
      moveTiming: IntentMoveTiming.none,
      damageMultiplier: 1.0,
      estimatedDamage: krakenMaelstromBaseDamage,
      isBossCatastropheStrike: true,
      poiseThreshold: 45,
      cooldownTurns: 3,
    ),
    MonsterIntentId.bossWorldSerpentWindup: MonsterIntent(
      id: MonsterIntentId.bossWorldSerpentWindup,
      threatenedRanges: {},
      moveDelta: IntentMoveDelta.stationary,
      moveTiming: IntentMoveTiming.none,
      damageMultiplier: 0.0,
      estimatedDamage: 0,
      isBossWindup: true,
      followUpStrikeId: MonsterIntentId.bossWorldSerpentCatastrophe,
      poiseThreshold: 45,
    ),
    MonsterIntentId.bossWorldSerpentCatastrophe: MonsterIntent(
      id: MonsterIntentId.bossWorldSerpentCatastrophe,
      threatenedRanges: {
        CombatRange.short,
        CombatRange.medium,
        CombatRange.long,
      },
      moveDelta: IntentMoveDelta.stationary,
      moveTiming: IntentMoveTiming.none,
      damageMultiplier: 1.65,
      estimatedDamage: 38,
      isBossCatastropheStrike: true,
      poiseThreshold: 45,
      cooldownTurns: 3,
    ),
    MonsterIntentId.bossLeviathanWindup: MonsterIntent(
      id: MonsterIntentId.bossLeviathanWindup,
      threatenedRanges: {},
      moveDelta: IntentMoveDelta.stationary,
      moveTiming: IntentMoveTiming.none,
      damageMultiplier: 0.0,
      estimatedDamage: 0,
      isBossWindup: true,
      followUpStrikeId: MonsterIntentId.bossLeviathanCatastrophe,
      poiseThreshold: 55,
    ),
    MonsterIntentId.bossLeviathanCatastrophe: MonsterIntent(
      id: MonsterIntentId.bossLeviathanCatastrophe,
      threatenedRanges: {
        CombatRange.short,
        CombatRange.medium,
        CombatRange.long,
      },
      moveDelta: IntentMoveDelta.stationary,
      moveTiming: IntentMoveTiming.none,
      damageMultiplier: 1.75,
      estimatedDamage: 44,
      isBossCatastropheStrike: true,
      poiseThreshold: 55,
      cooldownTurns: 3,
    ),
  };
}
