import 'package:flutter/foundation.dart';
import 'package:monstrous_core/monstrous_core.dart';

/// A render-only projection. Both HUD and Flame read these detached combatants;
/// commands always go to GameSession, never to these copies.
class BattlePresentation extends ChangeNotifier {
  BattlePresentation(
    ShipState sourceShip,
    MonsterState sourceMonster,
    CombatRange initialRange,
  ) : ship = ShipState.fromJson(sourceShip.toJson()),
      monster = MonsterState(
        id: sourceMonster.id,
        name: sourceMonster.name,
        level: sourceMonster.level,
        maxHp: sourceMonster.maxHp,
        currentHp: sourceMonster.currentHp,
        armorClass: sourceMonster.armorClass,
        species: sourceMonster.species,
        maxCarapace: sourceMonster.maxCarapace,
        isApex: sourceMonster.isApex,
        apexTitle: sourceMonster.apexTitle,
        usableWeapons: sourceMonster.usableWeapons
            .map(
              (weapon) => MonsterWeapon(
                id: weapon.id,
                name: weapon.name,
                description: weapon.description,
                rarity: weapon.rarity,
                damage: weapon.damage,
                hitModifier: weapon.hitModifier,
                chargeTime: weapon.chargeTime,
                chargeCountdown: weapon.chargeCountdown,
                damageType: weapon.damageType,
                statusEffect: weapon.statusEffect,
                monsterWeaponType: weapon.monsterWeaponType,
              ),
            )
            .toList(),
      ),
      range = initialRange {
    ship.captainBoonId = sourceShip.captainBoonId;
    ship.captainQuirkId = sourceShip.captainQuirkId;
    _effects(ship, CombatantPresentation.capture(sourceShip));
    _effects(monster, CombatantPresentation.capture(sourceMonster));
    monster.carapacePlating = sourceMonster.carapacePlating;
    monster.numberOfTentacles = sourceMonster.numberOfTentacles;
  }

  final ShipState ship;
  final MonsterState monster;
  CombatRange range;
  String announcement = '';

  void announce(String text) {
    announcement = text;
    notifyListeners();
  }

  CombatSide targetFor(CombatSide? explicit, String legacyName) =>
      explicit ??
      (legacyName == monster.name ? CombatSide.monster : CombatSide.ship);
  Combatant combatant(CombatSide side) =>
      side == CombatSide.ship ? ship : monster;

  /// Range is relative, but the movement that changed it belongs to one actor.
  /// Missing metadata stays neutral rather than inventing ship movement.
  static ({CombatSide? anchor, String text}) rangeCue(
    CombatRangeChanged event,
  ) {
    final range = event.newRange.displayName.toUpperCase();
    final mover = event.mover;
    if (mover == null) return (anchor: null, text: range);
    final closing = event.newRange.index > event.previousRange.index;
    final subject = mover == CombatSide.ship ? 'SHIP' : 'BEAST';
    final instigator = event.instigator ?? mover;
    if (instigator != mover) {
      final source = instigator == CombatSide.ship ? 'SHIP' : 'BEAST';
      return (
        anchor: mover,
        text: '$source ${closing ? 'PULLS' : 'PUSHES'} $subject · $range',
      );
    }
    return (
      anchor: mover,
      text: '$subject ${closing ? 'CLOSES' : 'RETREATS'} · $range',
    );
  }

  /// Brief lifecycle cues; durations remain readable in the persistent HUD.
  static Map<String, String> effectReadouts(Combatant actor) => {
    for (final status in actor.statusEffects)
      status.displayName: status.displayName,
    if (actor is ShipState) ...{
      'Evasion': 'Evasion ${actor.currentEvasion + actor.captainEvasionBonus}%',
      if (actor.currentDmgReduction > 0)
        'Armor': 'Armor ${actor.currentDmgReduction}',
      if (actor.tempAccuracyPenalty > 0)
        'Accuracy': 'Accuracy −${actor.tempAccuracyPenalty}%',
      if (actor.basaltBarrierHp > 0)
        'Barrier': 'Barrier ${actor.basaltBarrierHp}',
      if (actor.stormRiggingTurns > 0) 'Storm Rigging': 'Storm Rigging',
      if (actor.boilingWakeTurns > 0) 'Boiling Wake': 'Boiling Wake',
      if (actor.isGrappled) 'Grappled': 'Grappled',
      if (actor.isAnchoredThisTurn) 'Anchored': 'Anchored',
      if (actor.isBracedByDrill) 'Braced': 'Braced',
      if (actor.gunneryDrillBuffActive) 'Drill Ready': 'Drill Ready',
      if (actor.pitchCoatingActive) 'Pitch': 'Pitch',
      if (actor.activeTetherTrapDistance != null)
        'Trap': 'Trap ${actor.activeTetherTrapDistance} bands',
    },
    if (actor is MonsterState) ...{
      if (actor.isPinnedThisTurn) 'Pinned': 'Pinned',
      if (actor.isObscured) 'Obscured': 'Obscured',
      if (actor.spotterFlareTurns > 0) 'Illuminated': 'Illuminated',
      if (actor.staticStacks > 0) 'Static': 'Static ${actor.staticStacks}/3',
      if (actor.corrodedStacks > 0)
        'Corroded': 'Corroded ${actor.corrodedStacks}/3',
      if (actor.isElectroJolted) 'Electro-Jolt': 'Electro-Jolt',
      if (actor.tremorAccPenalty > 0)
        'Tremor': 'Tremor -${actor.tremorAccPenalty}%',
    },
  };

  /// Used only while idle (including externally injected test/debug changes).
  /// During playback the event stream is the sole source of visible state.
  void synchronizeIdle(
    ShipState sourceShip,
    MonsterState sourceMonster,
    CombatRange sourceRange,
  ) {
    ship.currentHp = sourceShip.currentHp;
    monster.currentHp = sourceMonster.currentHp;
    monster.carapacePlating = sourceMonster.carapacePlating;
    monster.numberOfTentacles = sourceMonster.numberOfTentacles;
    _effects(ship, CombatantPresentation.capture(sourceShip));
    _effects(monster, CombatantPresentation.capture(sourceMonster));
    range = sourceRange;
    _controls(sourceShip);
  }

  /// Applies already-resolved facts only. No damage/healing formula or RNG lives
  /// here. Effect snapshots deliberately cannot advance health, shell or limbs.
  void apply(GameEvent event) {
    switch (event) {
      case AttackHit(:final target, :final targetName, :final remainingHp):
        combatant(targetFor(target, targetName)).currentHp = remainingHp;
      case CombatHealthChanged(:final target, :final remainingHp):
        combatant(target).currentHp = remainingHp;
      case StatusEffectTicked(
        :final target,
        :final targetName,
        :final remainingHp,
        :final damage,
        :final effectName,
        :final woreOff,
      ):
        final actor = combatant(targetFor(target, targetName));
        // Older externally constructed events lack an endpoint. Production
        // emits the exact endpoint, including capped lethal ticks.
        actor.currentHp =
            remainingHp ?? (actor.currentHp - damage).clamp(0, actor.maxHp);
        if (woreOff) {
          actor.statusEffects.removeWhere(
            (effect) => effect.displayName == effectName,
          );
        }
      case MortarBackfireOccurred(:final remainingHp):
        ship.currentHp = remainingHp;
      case ThermalScaldOccurred(:final remainingHp):
        ship.currentHp = remainingHp;
      case DamageReduced(
        defense: DefenseKind.barrier,
        :final remainingBarrierHp,
      ):
        if (remainingBarrierHp != null) {
          ship.basaltBarrierHp = remainingBarrierHp;
        }
      case CarapaceAbsorbed(:final remainingCarapace):
        if (remainingCarapace != null) {
          monster.carapacePlating = remainingCarapace;
        }
      case CarapaceDamaged(:final remainingCarapace):
        monster.carapacePlating = remainingCarapace;
      case CarapaceRestored(:final remainingCarapace):
        monster.carapacePlating = remainingCarapace;
      case TentaclesSevered(:final remainingTentacles):
        monster.numberOfTentacles = remainingTentacles;
      case CombatEffectsChanged(:final target, :final state):
        _effects(combatant(target), state);
      case CombatRangeChanged(:final newRange):
        range = newRange;
      case MonsterIntentTelegraphed(:final intent):
        monster.currentIntent = intent;
      case InkCloudDeployed(:final accuracyPenalty):
        monster.isObscured = true;
        monster.obscuredAcMod = accuracyPenalty;
      case SharkFrenzyRoared(:final stacks):
        monster.frenzyStacks = stacks;
      case SharkFrenzyDisrupted():
        monster.frenzyStacks = 0;
      case ShipGrappled():
        ship.isGrappled = true;
      default:
        break;
    }
    notifyListeners();
  }

  /// Only decision controls synchronize after playback. Visible consequences
  /// must have arrived through events, so this cannot mask missing HP facts.
  void finishControls(ShipState source) {
    _controls(source);
    notifyListeners();
  }

  void _controls(ShipState source) {
    ship.utilityCooldown = source.utilityCooldown;
    for (var index = 0; index < ship.equippedWeapons.length; index++) {
      ship.equippedWeapons[index].chargeCountdown =
          source.equippedWeapons[index].chargeCountdown;
    }
    ship.cargo
      ..clear()
      ..addAll(source.cargo.map((item) => Item.fromJson(item.toJson())));
  }

  static void _effects(Combatant actor, CombatantPresentation facts) {
    actor.statusEffects
      ..clear()
      ..addAll(facts.statusEffects);
    if (actor is ShipState) {
      actor.currentEvasion = facts.currentEvasion;
      actor.currentDmgReduction = facts.currentDmgReduction;
      actor.isGrappled = facts.isGrappled;
      actor.tempAccuracyPenalty = facts.tempAccuracyPenalty;
      actor.isAnchoredThisTurn = facts.isAnchoredThisTurn;
      actor.isBracedByDrill = facts.isBracedByDrill;
      actor.gunneryDrillBuffActive = facts.gunneryDrillBuffActive;
      actor.pitchCoatingActive = facts.pitchCoatingActive;
      actor.activeTetherTrapDistance = facts.activeTetherTrapDistance;
      actor.basaltBarrierHp = facts.basaltBarrierHp;
      actor.basaltAegisTurns = facts.basaltAegisTurns;
      actor.stormRiggingTurns = facts.stormRiggingTurns;
      actor.boilingWakeTurns = facts.boilingWakeTurns;
    } else if (actor is MonsterState) {
      actor.isObscured = facts.isObscured;
      actor.obscuredAcMod = facts.obscuredAcMod;
      actor.frenzyStacks = facts.frenzyStacks;
      actor.evasion = facts.evasion;
      actor.isPinnedThisTurn = facts.isPinnedThisTurn;
      actor.spotterFlareTurns = facts.spotterFlareTurns;
      actor.spotterFlareAccuracyBonus = facts.spotterFlareAccuracyBonus;
      actor.spotterFlareBlastBonus = facts.spotterFlareBlastBonus;
      actor.staticStacks = facts.staticStacks;
      actor.corrodedStacks = facts.corrodedStacks;
      actor.corrodedTurns = facts.corrodedTurns;
      actor.isElectroJolted = facts.isElectroJolted;
      actor.tremorAccPenalty = facts.tremorAccPenalty;
      actor.burnTurns = facts.burnTurns;
      actor.currentIntent = facts.currentIntent;
    }
  }
}
