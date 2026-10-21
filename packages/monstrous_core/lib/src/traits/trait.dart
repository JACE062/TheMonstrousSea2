import 'dart:math';

import '../model/attack_result.dart';
import '../model/combatant.dart';
import '../model/enums.dart';
import '../model/flagship_blueprint.dart';
import '../model/ocean_power.dart';
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
  String executeSpecialAction(Combatant actor, Combatant target, GameRng rng) =>
      '';
}

/// Ironclad armor plating & Gunnery Drill brace: passive flat damage reduction, stackable fortify action, and 20% drill brace.
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
      var reduction = defender.currentDmgReduction;
      if (defender.isBracedByDrill) {
        reduction += (result.damage * 0.20).round();
      }
      if (reduction > 0) {
        final mitigated = reduction.clamp(0, result.damage);
        result.nullifiedDamage = mitigated;
      }
    }
  }

  @override
  String executeSpecialAction(Combatant actor, Combatant target, GameRng rng) {
    if (actor is ShipState &&
        (actor.shipClass == ShipClass.ironclad || actor.dmgReductionMod > 0)) {
      final utilMult = actor.multiplierForHardpointMark(HardpointType.utility);
      final gain = max(1, (actor.dmgReductionMod * utilMult).round());
      actor.currentDmgReduction += gain;
      actor.isAnchoredThisTurn = true;
      return '${actor.name} bolts down its iron plates (+$gain Damage Reduction) and anchors against monster push/pull!';
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
      int effectiveEvasion = defender.currentEvasion;
      if (defender.basaltBarrierHp > 0 && defender.basaltAegisTurns > 0) {
        effectiveEvasion += defender.blessings[HardpointType.utility]?.tier == 3
            ? 20
            : 15;
      }
      if (result.combatRange == CombatRange.long) {
        effectiveEvasion += 15;
      } else if (result.combatRange == CombatRange.short) {
        effectiveEvasion -= 15;
      }
      effectiveEvasion = effectiveEvasion.clamp(0, 95);

      final roll = rng.d100();
      if (roll <= effectiveEvasion) {
        result.wasEvaded = true;
        // Reset evasive maneuvers boost after successful dodge
        if (defender.currentEvasion > defender.baseEvasion) {
          defender.currentEvasion = defender.baseEvasion;
        }
      }
    }
  }

  @override
  String executeSpecialAction(Combatant actor, Combatant target, GameRng rng) {
    if (actor is ShipState &&
        (actor.shipClass == ShipClass.corvette ||
            actor.shipClass == ShipClass.clipper ||
            actor.baseEvasion > 0)) {
      actor.currentEvasion = (actor.baseEvasion * 2).clamp(0, 100);
      return '${actor.name} swiftly shifts course, slipping into an evasive pattern!';
    }
    return '';
  }
}

/// Squid ink cloud: lowers shot accuracy, 25% chance to disperse upon hit.
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
  String executeSpecialAction(Combatant actor, Combatant target, GameRng rng) {
    if (actor is MonsterState && !actor.isIlluminatedByFlare) {
      actor.isObscured = true;
      return '${actor.name} jets out pitch black ink into the water, obscuring itself from view!';
    }
    return '';
  }
}

/// Squid & Kraken tentacles: slicing attacks and harpoon tethers sever tentacles; multi-strike based on intact count.
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
        (defender.species == MonsterSpecies.squid ||
            defender.species == MonsterSpecies.kraken) &&
        result.didHit &&
        (result.damageType == DamageType.slicing ||
            result.shipWeaponType == ShipWeaponType.harpoonWinch) &&
        defender.numberOfTentacles > 0) {
      final effectiveDamage = result.damage - result.nullifiedDamage;
      final severed = (effectiveDamage / 10).ceil().clamp(
        0,
        defender.numberOfTentacles,
      );
      defender.numberOfTentacles -= severed;
      result.tentaclesSevered = severed;
    }
  }
}

/// Crustacean Carapace: armored shell absorbing normal attacks.
/// Shattered by Blast damage (+50% for Heavy Mortar); bypassed by Fire and 50% by Precision Culverin.
class CarapaceTrait extends CombatTrait {
  const CarapaceTrait();

  @override
  void onIncomingAttack(
    Combatant defender,
    Combatant attacker,
    AttackResult result,
    GameRng rng,
  ) {
    if (defender is MonsterState &&
        defender.carapacePlating > 0 &&
        result.didHit) {
      final slot =
          (result.shipWeaponType?.isBlueprintIntrinsic == true ||
                  result.shipWeaponType == ShipWeaponType.cannon) &&
              attacker is ShipState
          ? result.shipWeaponType!.isSignature
                ? HardpointType.signature
                : HardpointType.broadside
          : null;
      final blessing = attacker is ShipState && slot != null
          ? attacker.blessings[slot]
          : null;
      if (blessing?.power == OceanPower.brinemother) {
        final signature = slot == HardpointType.signature;
        final intrinsicShellMultiplier =
            result.shipWeaponType == ShipWeaponType.heavyMortar ? 2 : 1;
        final shellDamage =
            (signature
                    ? result.damage * intrinsicShellMultiplier
                    : result.damage * 2 + [4, 8, 12][blessing!.tier - 1])
                .clamp(0, defender.carapacePlating);
        defender.carapacePlating -= shellDamage;
        result.carapaceDamaged = shellDamage;
        result.wasCarapaceShattered = defender.carapacePlating == 0;
        if (!signature && result.damageType != DamageType.fire) {
          result.nullifiedDamage = min(result.damage, shellDamage);
          result.carapaceAbsorbed = result.nullifiedDamage;
        }
      } else if (blessing?.power == OceanPower.earthshakerTitan &&
          result.damageType != DamageType.fire) {
        // Preserve the Culverin's penetration and Mortar's superior shell crush.
        final bypass = result.shipWeaponType == ShipWeaponType.precisionCulverin
            ? (result.damage * 0.5).round()
            : 0;
        final multiplier = result.shipWeaponType == ShipWeaponType.heavyMortar
            ? 2.0
            : 1.5;
        final shellDamage = ((result.damage - bypass) * multiplier)
            .round()
            .clamp(0, defender.carapacePlating);
        defender.carapacePlating -= shellDamage;
        result.carapaceDamaged = shellDamage;
        result.nullifiedDamage = min(result.damage - bypass, shellDamage);
        result.wasCarapaceShattered = defender.carapacePlating == 0;
      } else if (result.shipWeaponType == ShipWeaponType.precisionCulverin) {
        // Precision Culverin critical strikes bypass 50% of monster Carapace plating!
        // 50% is absorbed by the carapace, while the other 50% penetrates directly to HP.
        final halfDmg = (result.damage * 0.5).round();
        final absorbed = min(halfDmg, defender.carapacePlating);
        defender.carapacePlating -= absorbed;
        result.carapaceAbsorbed = absorbed;
        result.carapaceDamaged = absorbed;
        result.nullifiedDamage = absorbed;
        result.wasCarapaceShattered = defender.carapacePlating <= 0;
      } else if (result.damageType == DamageType.blast) {
        // Blast attacks deal devastating bonus damage directly to carapace!
        // Heavy Mortar delivers an additional +50% blast bonus (2.0x vs 1.5x)!
        final multiplier = result.shipWeaponType == ShipWeaponType.heavyMortar
            ? 2.0
            : 1.5;
        final blastDmg = (result.damage * multiplier).round();
        final absorbedByCarapace = blastDmg.clamp(0, defender.carapacePlating);
        defender.carapacePlating -= absorbedByCarapace;
        result.carapaceDamaged = absorbedByCarapace;
        result.wasCarapaceShattered = defender.carapacePlating <= 0;
        // The portion absorbed by the shell doesn't damage monster HP; leftover penetrates
        result.nullifiedDamage = min(result.damage, absorbedByCarapace);
      } else if (result.damageType == DamageType.fire) {
        // Fire bypasses the outer shell entirely, cooking the creature inside!
        // nullifiedDamage remains 0.
      } else {
        // Piercing, slicing, shock: absorbed point-for-point by carapace plating!
        // The shell absorbs damage up to remaining plating. Leftover damage penetrates to HP.
        final absorbed = min(result.damage, defender.carapacePlating);
        defender.carapacePlating -= absorbed;
        result.carapaceAbsorbed = absorbed;
        result.nullifiedDamage = absorbed;
        result.wasCarapaceShattered = defender.carapacePlating <= 0;
      }
    }
  }

  @override
  String executeSpecialAction(Combatant actor, Combatant target, GameRng rng) {
    if (actor is MonsterState &&
        actor.species == MonsterSpecies.crustacean &&
        actor.carapacePlating > 0 &&
        actor.carapacePlating < actor.maxCarapace) {
      final restored = (actor.maxCarapace * 0.2).ceil();
      actor.carapacePlating = (actor.carapacePlating + restored).clamp(
        0,
        actor.maxCarapace,
      );
      return '${actor.name} hunkers down into its armored shell, reinforcing its carapace!';
    }
    return '';
  }
}

/// Shark Frenzy: Roaring ramps up attack damage (+25% per stack, up to 3).
/// Shock damage, stun, or concussive Mortar impact disrupts the shark's nervous system, resetting frenzy.
class SharkFrenzyTrait extends CombatTrait {
  const SharkFrenzyTrait();

  @override
  void onIncomingAttack(
    Combatant defender,
    Combatant attacker,
    AttackResult result,
    GameRng rng,
  ) {
    if (defender is MonsterState &&
        defender.species == MonsterSpecies.shark &&
        result.didHit) {
      final isShockOrStunOrConcussive =
          result.damageType == DamageType.shock ||
          result.statusEffect == StatusEffect.stun ||
          result.shipWeaponType == ShipWeaponType.heavyMortar;
      if (isShockOrStunOrConcussive && defender.frenzyStacks > 0) {
        defender.frenzyStacks = 0;
        result.disruptedFrenzy = true;
      }
    }
  }

  @override
  String executeSpecialAction(Combatant actor, Combatant target, GameRng rng) {
    if (actor is MonsterState && actor.species == MonsterSpecies.shark) {
      actor.frenzyStacks = (actor.frenzyStacks + 1).clamp(1, 3);
      return '${actor.name} thrashes the sea and lets out a frenzied roar! (Frenzy x${actor.frenzyStacks})';
    }
    return '';
  }
}

/// Serpent Slither: Evasive coils granting a dodge chance.
class SerpentSlitherTrait extends CombatTrait {
  const SerpentSlitherTrait();

  @override
  void onIncomingAttack(
    Combatant defender,
    Combatant attacker,
    AttackResult result,
    GameRng rng,
  ) {
    if (defender is MonsterState &&
        result.didHit &&
        defender.effectiveEvasion > 0) {
      final effectiveEvasion = defender.effectiveEvasion;
      final roll = rng.d100();
      if (roll <= effectiveEvasion) {
        result.wasEvaded = true;
      }
    }
  }
}
