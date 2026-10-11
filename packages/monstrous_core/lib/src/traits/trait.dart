import '../model/attack_result.dart';
import '../model/combatant.dart';
import '../model/enums.dart';
import '../rng/game_rng.dart';

/// Pluggable behavioral trait for combat mechanics and subclass actions.
abstract class CombatTrait {
  const CombatTrait();

  /// Hook invoked when incoming damage is calculated for a defender.
  void onIncomingAttack(
    Combatant defender,
    Combatant attacker,
    AttackResult result,
    GameRng rng,
  ) {}

  /// Hook invoked when an active combatant executes its special turn action.
  String executeSpecialAction(
    Combatant actor,
    Combatant target,
    GameRng rng,
  ) =>
      '';
}

/// Ironclad armor plating: passive flat damage reduction, stackable fortify action.
class FortifyTrait extends CombatTrait {
  const FortifyTrait();

  @override
  void onIncomingAttack(
    Combatant defender,
    Combatant attacker,
    AttackResult result,
    GameRng rng,
  ) {
    if (defender is ShipState && result.didHit && !result.wasEvaded) {
      final reduction = defender.currentDmgReduction;
      if (reduction > 0) {
        final mitigated = reduction.clamp(0, result.damage);
        result.nullifiedDamage = mitigated;
      }
    }
  }

  @override
  String executeSpecialAction(
    Combatant actor,
    Combatant target,
    GameRng rng,
  ) {
    if (actor is ShipState) {
      actor.currentDmgReduction += actor.dmgReductionMod;
      return '${actor.name} bolsters its hull plating, fortifying defenses!';
    }
    return '';
  }
}

/// Corvette speed: dodge chance, evasive maneuvers action doubling dodge.
class EvasionTrait extends CombatTrait {
  const EvasionTrait();

  @override
  void onIncomingAttack(
    Combatant defender,
    Combatant attacker,
    AttackResult result,
    GameRng rng,
  ) {
    if (defender is ShipState && result.didHit) {
      final roll = rng.d100();
      if (roll <= defender.currentEvasion) {
        result.wasEvaded = true;
        // Reset evasive maneuvers boost after successful dodge
        if (defender.currentEvasion > defender.baseEvasion) {
          defender.currentEvasion = defender.baseEvasion;
        }
      }
    }
  }

  @override
  String executeSpecialAction(
    Combatant actor,
    Combatant target,
    GameRng rng,
  ) {
    if (actor is ShipState) {
      actor.currentEvasion = (actor.baseEvasion * 2).clamp(0, 100);
      return '${actor.name} swiftly shifts course, slipping into an evasive pattern!';
    }
    return '';
  }
}

/// Squid ink cloud: obscures vision boosting AC, 25% chance to disperse upon hit.
class InkCloudTrait extends CombatTrait {
  const InkCloudTrait();

  @override
  void onIncomingAttack(
    Combatant defender,
    Combatant attacker,
    AttackResult result,
    GameRng rng,
  ) {
    if (defender is MonsterState && defender.isObscured && result.didHit) {
      if (rng.d100() <= 25) {
        defender.isObscured = false;
        result.description += ' (dispersing the cloud of ink)';
      }
    }
  }

  @override
  String executeSpecialAction(
    Combatant actor,
    Combatant target,
    GameRng rng,
  ) {
    if (actor is MonsterState) {
      actor.isObscured = true;
      return '${actor.name} jets out pitch black ink into the water, obscuring itself from view!';
    }
    return '';
  }
}

/// Squid tentacles: slicing attacks sever tentacles; multi-strike based on intact count.
class TentacleTrait extends CombatTrait {
  const TentacleTrait();

  @override
  void onIncomingAttack(
    Combatant defender,
    Combatant attacker,
    AttackResult result,
    GameRng rng,
  ) {
    if (defender is MonsterState &&
        defender.species == MonsterSpecies.squid &&
        result.didHit &&
        result.damageType == DamageType.slicing &&
        defender.numberOfTentacles > 0) {
      final effectiveDamage = result.damage - result.nullifiedDamage;
      final severed = (effectiveDamage / 10).ceil().clamp(0, defender.numberOfTentacles);
      defender.numberOfTentacles -= severed;
      result.tentaclesSevered = severed;
    }
  }
}
