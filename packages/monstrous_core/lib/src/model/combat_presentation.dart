import 'combatant.dart';
import 'enums.dart';
import 'monster_intent.dart';

/// Stable identities for playback, independent of player-selected names.
enum CombatSide { ship, monster }

enum DefenseKind { mitigation, barrier }

/// Immutable resolved facts for the battle display. This is neither a save nor
/// another rules model. Capture at the mutation, before later effects resolve.
final class CombatantPresentation {
  CombatantPresentation.capture(Combatant combatant)
    : currentHp = combatant.currentHp,
      maxHp = combatant.maxHp,
      statusEffects = List.unmodifiable(combatant.statusEffects),
      currentEvasion = combatant is ShipState ? combatant.currentEvasion : 0,
      currentDmgReduction = combatant is ShipState
          ? combatant.currentDmgReduction
          : 0,
      isGrappled = combatant is ShipState && combatant.isGrappled,
      tempAccuracyPenalty = combatant is ShipState
          ? combatant.tempAccuracyPenalty
          : 0,
      isAnchoredThisTurn =
          combatant is ShipState && combatant.isAnchoredThisTurn,
      isBracedByDrill = combatant is ShipState && combatant.isBracedByDrill,
      gunneryDrillBuffActive =
          combatant is ShipState && combatant.gunneryDrillBuffActive,
      pitchCoatingActive =
          combatant is ShipState && combatant.pitchCoatingActive,
      activeTetherTrapDistance = combatant is ShipState
          ? combatant.activeTetherTrapDistance
          : null,
      basaltBarrierHp = combatant is ShipState ? combatant.basaltBarrierHp : 0,
      basaltAegisTurns = combatant is ShipState
          ? combatant.basaltAegisTurns
          : 0,
      stormRiggingTurns = combatant is ShipState
          ? combatant.stormRiggingTurns
          : 0,
      boilingWakeTurns = combatant is ShipState
          ? combatant.boilingWakeTurns
          : 0,
      isObscured = combatant is MonsterState && combatant.isObscured,
      obscuredAcMod = combatant is MonsterState ? combatant.obscuredAcMod : 0,
      numberOfTentacles = combatant is MonsterState
          ? combatant.numberOfTentacles
          : 0,
      carapacePlating = combatant is MonsterState
          ? combatant.carapacePlating
          : 0,
      frenzyStacks = combatant is MonsterState ? combatant.frenzyStacks : 0,
      evasion = combatant is MonsterState ? combatant.evasion : 0,
      isPinnedThisTurn =
          combatant is MonsterState && combatant.isPinnedThisTurn,
      spotterFlareTurns = combatant is MonsterState
          ? combatant.spotterFlareTurns
          : 0,
      spotterFlareAccuracyBonus = combatant is MonsterState
          ? combatant.spotterFlareAccuracyBonus
          : 0,
      spotterFlareBlastBonus = combatant is MonsterState
          ? combatant.spotterFlareBlastBonus
          : 0,
      staticStacks = combatant is MonsterState ? combatant.staticStacks : 0,
      corrodedStacks = combatant is MonsterState ? combatant.corrodedStacks : 0,
      corrodedTurns = combatant is MonsterState ? combatant.corrodedTurns : 0,
      isElectroJolted = combatant is MonsterState && combatant.isElectroJolted,
      tremorAccPenalty = combatant is MonsterState
          ? combatant.tremorAccPenalty
          : 0,
      burnTurns = combatant is MonsterState ? combatant.burnTurns : 0,
      currentIntent = combatant is MonsterState
          ? _freezeIntent(combatant.currentIntent)
          : null;

  /// Masks a temporary accuracy bypass while preserving this causal snapshot.
  /// The source lists and intent were frozen at capture and can be shared.
  CombatantPresentation withObscurity(bool value) =>
      CombatantPresentation._withObscurity(this, value);

  CombatantPresentation._withObscurity(
    CombatantPresentation source,
    this.isObscured,
  ) : currentHp = source.currentHp,
      maxHp = source.maxHp,
      statusEffects = source.statusEffects,
      currentEvasion = source.currentEvasion,
      currentDmgReduction = source.currentDmgReduction,
      isGrappled = source.isGrappled,
      tempAccuracyPenalty = source.tempAccuracyPenalty,
      isAnchoredThisTurn = source.isAnchoredThisTurn,
      isBracedByDrill = source.isBracedByDrill,
      gunneryDrillBuffActive = source.gunneryDrillBuffActive,
      pitchCoatingActive = source.pitchCoatingActive,
      activeTetherTrapDistance = source.activeTetherTrapDistance,
      basaltBarrierHp = source.basaltBarrierHp,
      basaltAegisTurns = source.basaltAegisTurns,
      stormRiggingTurns = source.stormRiggingTurns,
      boilingWakeTurns = source.boilingWakeTurns,
      obscuredAcMod = source.obscuredAcMod,
      numberOfTentacles = source.numberOfTentacles,
      carapacePlating = source.carapacePlating,
      frenzyStacks = source.frenzyStacks,
      evasion = source.evasion,
      isPinnedThisTurn = source.isPinnedThisTurn,
      spotterFlareTurns = source.spotterFlareTurns,
      spotterFlareAccuracyBonus = source.spotterFlareAccuracyBonus,
      spotterFlareBlastBonus = source.spotterFlareBlastBonus,
      staticStacks = source.staticStacks,
      corrodedStacks = source.corrodedStacks,
      corrodedTurns = source.corrodedTurns,
      isElectroJolted = source.isElectroJolted,
      tremorAccPenalty = source.tremorAccPenalty,
      burnTurns = source.burnTurns,
      currentIntent = source.currentIntent;

  final int currentHp, maxHp;
  final List<StatusEffect> statusEffects;
  final int currentEvasion, currentDmgReduction, tempAccuracyPenalty;
  final bool isGrappled, isAnchoredThisTurn, isBracedByDrill;
  final bool gunneryDrillBuffActive, pitchCoatingActive;
  final int? activeTetherTrapDistance;
  final int basaltBarrierHp,
      basaltAegisTurns,
      stormRiggingTurns,
      boilingWakeTurns;
  final bool isObscured;
  final int obscuredAcMod,
      numberOfTentacles,
      carapacePlating,
      frenzyStacks,
      evasion;
  final bool isPinnedThisTurn;
  final int spotterFlareTurns, spotterFlareAccuracyBonus;
  final double spotterFlareBlastBonus;
  final int staticStacks, corrodedStacks, corrodedTurns;
  final bool isElectroJolted;
  final int tremorAccPenalty, burnTurns;
  final MonsterIntent? currentIntent;

  static MonsterIntent? _freezeIntent(MonsterIntent? intent) => intent == null
      ? null
      : MonsterIntent(
          id: intent.id,
          threatenedRanges: Set.unmodifiable(intent.threatenedRanges),
          moveDelta: intent.moveDelta,
          moveTiming: intent.moveTiming,
          damageMultiplier: intent.damageMultiplier,
          estimatedDamage: intent.estimatedDamage,
          cooldownTurns: intent.cooldownTurns,
          isBossWindup: intent.isBossWindup,
          isBossCatastropheStrike: intent.isBossCatastropheStrike,
          followUpStrikeId: intent.followUpStrikeId,
          poiseThreshold: intent.poiseThreshold,
        );
}
