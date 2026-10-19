import '../config/balance_config.dart';
import '../model/attack_result.dart';
import '../model/combatant.dart';
import '../model/enums.dart';
import '../model/item.dart';
import '../rng/game_rng.dart';
import '../session/events.dart';
import '../traits/trait.dart';

/// Extension providing getter aliases for the record returned by [calculateAttack].
extension AttackOutcomeExtension on (AttackResult, List<GameEvent>) {
  AttackResult get result => $1;
  List<GameEvent> get events => $2;
}

/// Extension providing getter aliases for the record returned by [updateStatusEffects].
extension StatusOutcomeExtension on (bool, List<GameEvent>) {
  bool get canAct => $1;
  List<GameEvent> get events => $2;
}

/// Default combat traits active during naval engagements.
const defaultCombatTraits = <CombatTrait>[
  FortifyTrait(),
  EvasionTrait(),
  InkCloudTrait(),
  TentacleTrait(),
  CarapaceTrait(),
  SharkFrenzyTrait(),
  SerpentSlitherTrait(),
];

/// Evaluates whether [type] can be fired from [range].
///
/// Tactical Legality Rules:
/// - Prow Ram: Available at Medium or Short Range. Cannot be initiated from Long Range.
/// - Heavy Mortar, Culverin, Harpoon Winch, Broadsides, etc. can be launched from all legal ranges.
bool isWeaponTypeUsableAtRange(ShipWeaponType type, CombatRange range) {
  if (type == ShipWeaponType.prowRam) {
    return range != CombatRange.long;
  }
  return true;
}

/// Evaluates whether [weapon] can be fired from [range].
bool isWeaponUsableAtRange(ShipWeapon weapon, CombatRange range) =>
    isWeaponTypeUsableAtRange(weapon.weaponType, range);

/// Returns the Phase 3A normalized range effectiveness multiplier for [type] when fired from [range].
///
/// Every blueprint offensive hardpoint has a `1.00` (`100%`) anchor range:
/// - Broadsides (0T CD):
///   * Naval Cannon Battery (`cannon`): Short `85%`, Med `100%`, Long `65%`
///   * Heavy Carronades (`heavyCarronade`): Short `100%`, Med `80%`, Long `35%`
///   * Long-Barrel Swivel Guns (`swivelGun`): Short `75%`, Med `100%`, Long `100%`
///   * Chain-Shot Broadside (`chainShotBroadside`): Short `100%`, Med `85%`, Long `45%`
///   * Shrapnel Howitzers (`shrapnelHowitzer`): Short `70%`, Med `100%`, Long `75%`
/// - Signature Armaments (1T CD):
///   * Twin Chaser Cannons (`twinChasers`): Short `75%`, Med `100%`, Long `90%`
///   * Reinforced Prow Ram (`prowRam`): Short `100%`, Med `125%` (kinetic charge into Short), Long `0%`
///   * Precision Culverin (`precisionCulverin`): Short `40%`, Med `85%`, Long `100%`
///   * Harpoon Winch (`harpoonWinch`): Short `85%`, Med `100%`, Long `85%`
///   * Heavy Siege Mortar (`heavyMortar`): Short `70%` (25% self-splash), Med `85%`, Long `100%`
double weaponRangeDamageMultiplier(ShipWeaponType type, CombatRange range) {
  return switch (type) {
    ShipWeaponType.cannon => switch (range) {
        CombatRange.short => 0.85,
        CombatRange.medium => 1.00,
        CombatRange.long => 0.65,
      },
    ShipWeaponType.heavyCarronade => switch (range) {
        CombatRange.short => 1.00,
        CombatRange.medium => 0.80,
        CombatRange.long => 0.35,
      },
    ShipWeaponType.swivelGun => switch (range) {
        CombatRange.short => 0.75,
        CombatRange.medium => 1.00,
        CombatRange.long => 1.00,
      },
    ShipWeaponType.chainShotBroadside => switch (range) {
        CombatRange.short => 1.00,
        CombatRange.medium => 0.85,
        CombatRange.long => 0.45,
      },
    ShipWeaponType.shrapnelHowitzer => switch (range) {
        CombatRange.short => 0.70,
        CombatRange.medium => 1.00,
        CombatRange.long => 0.75,
      },
    ShipWeaponType.twinChasers => switch (range) {
        CombatRange.short => 0.75,
        CombatRange.medium => 1.00,
        CombatRange.long => 0.90,
      },
    ShipWeaponType.prowRam => switch (range) {
        CombatRange.short => 1.00,
        CombatRange.medium => 1.25,
        CombatRange.long => 0.0,
      },
    ShipWeaponType.precisionCulverin => switch (range) {
        CombatRange.short => 0.40,
        CombatRange.medium => 0.85,
        CombatRange.long => 1.00,
      },
    ShipWeaponType.harpoonWinch => switch (range) {
        CombatRange.short => 0.85,
        CombatRange.medium => 1.00,
        CombatRange.long => 0.85,
      },
    ShipWeaponType.heavyMortar => switch (range) {
        CombatRange.short => 0.70,
        CombatRange.medium => 0.85,
        CombatRange.long => 1.00,
      },
    ShipWeaponType.torpedoLauncher ||
    ShipWeaponType.bladeLauncher ||
    ShipWeaponType.lightningRailgun ||
    ShipWeaponType.flamethrower =>
      1.00,
  };
}

/// Calculates the percentage hit chance for [attacker] firing [weapon] at [defender].
///
/// Bounded between 25% and 95%:
/// - Base accuracy from [weapon.baseAccuracy] (or [weapon.hitModifier]).
/// - Optional [accuracyBonus] (e.g. from island gunnery drills or Standard Gunnery Drill).
/// - Long Range penalty (-15% accuracy) for standard broadside naval cannons.
/// - Obscurity modifier (Ink Cloud) reduces accuracy unless illuminated by a Spotter Flare.
/// - Spotter Flare grants +15% accuracy against illuminated monsters.
/// - Heavy Blast ordnance against colossal targets (Kraken, Crustacean) gains a +10% bonus.
int calculateHitChance(
  Combatant attacker,
  Weapon weapon,
  Combatant defender, {
  int accuracyBonus = 0,
  CombatRange range = CombatRange.medium,
}) {
  int chance = weapon.baseAccuracy + accuracyBonus;
  if (attacker is ShipState && attacker.tempAccuracyPenalty > 0) {
    chance -= attacker.tempAccuracyPenalty;
  }

  if (range == CombatRange.long &&
      weapon is ShipWeapon &&
      weapon.weaponType == ShipWeaponType.cannon) {
    chance -= 15;
  }

  if (defender is MonsterState) {
    if (defender.isIlluminatedByFlare) {
      chance += defender.spotterFlareAccuracyBonus;
    } else if (defender.isObscured) {
      chance -= defender.obscuredAcMod;
    }
    final isMassiveBeast = defender.species == MonsterSpecies.kraken ||
        defender.species == MonsterSpecies.ancientLeviathan ||
        defender.species == MonsterSpecies.crustacean ||
        defender.carapacePlating > 0;
    if (isMassiveBeast && weapon.damageType == DamageType.blast) {
      chance += 10;
    }
  }

  return chance.clamp(25, 95);
}

/// Calculates an individual attack from [attacker] using [weapon] against [defender].
///
/// Resolves a bounded d100 percentage hit roll against calculated accuracy,
/// rolls damage, triggers applicable [traits] hooks, applies final effective
/// damage and status effects, and emits the corresponding [GameEvent]s.
(AttackResult result, List<GameEvent> events) calculateAttack(
  Combatant attacker,
  Weapon weapon,
  Combatant defender,
  GameRng rng, [
  List<CombatTrait> traits = const [],
  int accuracyBonus = 0,
  double damageMultiplier = 1.0,
  CombatRange range = CombatRange.medium,
]) {
  final events = <GameEvent>[];
  final hitChance = calculateHitChance(
    attacker,
    weapon,
    defender,
    accuracyBonus: accuracyBonus,
    range: range,
  );
  final roll = rng.d100();
  final didHit = roll <= hitChance;

  events.add(AttackAttempted(
    attackerName: attacker.name,
    weaponName: weapon.name,
    roll: roll,
    targetAc: hitChance,
  ));

  var effectiveMultiplier = damageMultiplier;
  if (weapon is ShipWeapon) {
    effectiveMultiplier *= weaponRangeDamageMultiplier(weapon.weaponType, range);
    if (weapon.weaponType == ShipWeaponType.chainShotBroadside &&
        defender is MonsterState &&
        defender.isPinnedThisTurn) {
      effectiveMultiplier *= 1.20;
    }
  }
  if (defender is MonsterState &&
      defender.isIlluminatedByFlare &&
      weapon.damageType == DamageType.blast) {
    effectiveMultiplier *= (1.0 + defender.spotterFlareBlastBonus);
  }

  final baseDamage = (weapon.damage * effectiveMultiplier).round();
  final impactRange = (weapon is ShipWeapon &&
          weapon.weaponType == ShipWeaponType.prowRam)
      ? CombatRange.short
      : range;

  // Point-blank Mortar Backfire: firing a siege mortar at Short Range deals 70% damage
  // to the beast, but splashes 25% of the dealt damage back onto the Bombardier's hull.
  if (weapon is ShipWeapon &&
      weapon.weaponType == ShipWeaponType.heavyMortar &&
      range == CombatRange.short &&
      attacker is ShipState &&
      attacker.isAlive) {
    final backfireDmg = (baseDamage * 0.25).round().clamp(1, attacker.maxHp);
    attacker.applyDamage(backfireDmg);
    events.add(MortarBackfireOccurred(
      shipName: attacker.name,
      damage: backfireDmg,
      remainingHp: attacker.currentHp,
    ));
    if (!attacker.isAlive) {
      events.add(CombatantDefeated(
        name: attacker.name,
        flavorMessage:
            '${attacker.name} was destroyed by its own point-blank mortar barrage!',
      ));
    }
  }

  if (!didHit) {
    final result = AttackResult(
      didHit: false,
      damage: 0,
      damageType: weapon.damageType,
      shipWeaponType: weapon is ShipWeapon ? weapon.weaponType : null,
      statusEffect: null,
      description:
          '${attacker.name} attacks with ${weapon.name}, but misses ${defender.name}.',
      combatRange: range,
    );
    events.add(AttackMissed(targetName: defender.name));
    return (result, events);
  }

  // Attack hit
  final wasManeuver = defender is ShipState &&
      defender.currentEvasion > defender.baseEvasion;

  final result = AttackResult(
    didHit: true,
    damage: baseDamage,
    damageType: weapon.damageType,
    shipWeaponType: weapon is ShipWeapon ? weapon.weaponType : null,
    statusEffect: weapon.statusEffect,
    description: '${attacker.name} attacks with ${weapon.name}',
    combatRange: impactRange,
  );


  final activeTraits = traits.isNotEmpty ? traits : defaultCombatTraits;
  for (final trait in activeTraits) {
    trait.onIncomingAttack(defender, attacker, result, rng);
  }

  if (result.wasEvaded) {
    events.add(AttackEvaded(
      shipName: defender.name,
      wasManeuver: wasManeuver,
    ));
    return (result, events);
  }

  if (result.carapaceDamaged > 0 || result.wasCarapaceShattered) {
    events.add(CarapaceDamaged(
      monsterName: defender.name,
      damageDealt: result.carapaceDamaged,
      remainingCarapace: (defender as MonsterState).carapacePlating,
      wasShattered: result.wasCarapaceShattered,
    ));
  }

  if (result.carapaceAbsorbed > 0) {
    events.add(CarapaceAbsorbed(
      monsterName: defender.name,
      absorbedAmount: result.carapaceAbsorbed,
      penetratingDamage: result.damage - result.nullifiedDamage,
    ));
  }

  if (result.disruptedFrenzy) {
    events.add(SharkFrenzyDisrupted(
      monsterName: defender.name,
      reason: 'Shock disrupted feeding frenzy',
    ));
  }

  if (result.nullifiedDamage > 0 && defender is ShipState) {
    events.add(DamageReduced(
      shipName: defender.name,
      nullifiedAmount: result.nullifiedDamage,
    ));
  }

  final effectiveDamage =
      (result.damage - result.nullifiedDamage).clamp(0, defender.currentHp);
  defender.applyDamage(effectiveDamage);

  events.add(AttackHit(
    targetName: defender.name,
    damage: effectiveDamage,
    damageType: result.damageType.displayName,
    remainingHp: defender.currentHp,
  ));

  if (result.tentaclesSevered > 0 && defender is MonsterState) {
    events.add(TentaclesSevered(
      countSevered: result.tentaclesSevered,
      remainingTentacles: defender.numberOfTentacles,
    ));
  }

  if (result.statusEffect != null) {
    defender.addStatus(result.statusEffect!);
  }

  if (!defender.isAlive) {
    events.add(CombatantDefeated(
      name: defender.name,
      flavorMessage: '${defender.name} has been defeated!',
    ));
  }

  return (result, events);
}

/// Executes a coordinated volley of all ready equipped weapons of [weaponType] on [ship].
///
/// Iterates over all equipped weapons matching [weaponType] where `chargeCountdown == 0`,
/// executing individual attacks via [calculateAttack] and resetting their charge countdowns.
/// If [monster] is defeated mid-volley, remaining shots cease immediately.
List<GameEvent> executeShipWeaponVolley(
  ShipState ship,
  ShipWeaponType weaponType,
  MonsterState monster,
  GameRng rng, [
  List<CombatTrait> traits = const [],
  int accuracyBonus = 0,
  double damageMultiplier = 1.0,
  CombatRange range = CombatRange.medium,
]) {
  if (!isWeaponTypeUsableAtRange(weaponType, range)) {
    throw StateError('Cannot fire ${weaponType.displayName} at ${range.displayName}');
  }

  final events = <GameEvent>[];
  var readyWeapons = ship.equippedWeapons
      .where((w) => w.weaponType == weaponType && w.chargeCountdown == 0)
      .toList();
  if (readyWeapons.isEmpty && weaponType == ShipWeaponType.cannon) {
    readyWeapons = ship.equippedWeapons
        .where((w) => !w.isSignature && w.chargeCountdown == 0)
        .toList();
  }

  for (final weapon in readyWeapons) {
    if (!monster.isAlive || !ship.isAlive) break;

    final (_, attackEvents) = calculateAttack(
      ship,
      weapon,
      monster,
      rng,
      traits,
      accuracyBonus,
      damageMultiplier,
      range,
    );
    events.addAll(attackEvents);
    weapon.resetCharge();

    if (!monster.isAlive || !ship.isAlive) break;
  }

  return events;
}

/// Processes active status effects on [combatant] at turn start according to [config].
///
/// Returns a record of `(bool canAct, List<GameEvent> events)`.
/// - BURN: Deals `5 * difficulty` fire damage, 25% wear-off chance.
/// - POISON: Deals `5 * difficulty` venom damage, 25% wear-off chance.
/// - STUN: Clears after 1 turn for ships; 50% wear-off chance for monsters. If still stunned,
///   returns `canAct = false`.
(bool canAct, List<GameEvent> events) updateStatusEffects(
  Combatant combatant,
  int difficulty,
  GameRng rng, [
  BalanceConfig config = BalanceConfig.standard,
]) {
  final events = <GameEvent>[];

  if (combatant.hasStatus(StatusEffect.burn)) {
    final damage = config.statusEffectTickDamageMultiplier * difficulty;
    combatant.applyDamage(damage);
    final isDead = !combatant.isAlive;
    final woreOff =
        !isDead && (rng.d100() > (100 - config.statusWearOffChance));
    if (woreOff) {
      combatant.removeStatus(StatusEffect.burn);
    }
    events.add(StatusEffectTicked(
      targetName: combatant.name,
      effectName: StatusEffect.burn.displayName,
      damage: damage,
      woreOff: woreOff,
    ));
    if (isDead) {
      events.add(CombatantDefeated(
        name: combatant.name,
        flavorMessage: '${combatant.name} was destroyed by fire!',
      ));
      return (false, events);
    }
  }

  if (combatant.hasStatus(StatusEffect.poison)) {
    final damage = config.statusEffectTickDamageMultiplier * difficulty;
    combatant.applyDamage(damage);
    final isDead = !combatant.isAlive;
    final woreOff =
        !isDead && (rng.d100() > (100 - config.statusWearOffChance));
    if (woreOff) {
      combatant.removeStatus(StatusEffect.poison);
    }
    events.add(StatusEffectTicked(
      targetName: combatant.name,
      effectName: StatusEffect.poison.displayName,
      damage: damage,
      woreOff: woreOff,
    ));
    if (isDead) {
      events.add(CombatantDefeated(
        name: combatant.name,
        flavorMessage: '${combatant.name} succumbed to venom!',
      ));
      return (false, events);
    }
  }

  var canAct = true;
  if (combatant.hasStatus(StatusEffect.stun)) {
    if (combatant is ShipState) {
      combatant.removeStatus(StatusEffect.stun);
      combatant.decrementChargeTimeOnWeapons();
      events.add(StatusEffectTicked(
        targetName: combatant.name,
        effectName: StatusEffect.stun.displayName,
        damage: 0,
        woreOff: true,
      ));
      canAct = false;
    } else {
      canAct = false;
      final woreOff = rng.d100() > (100 - config.stunWearOffChanceMonster);
      if (woreOff) {
        combatant.removeStatus(StatusEffect.stun);
      }
      events.add(StatusEffectTicked(
        targetName: combatant.name,
        effectName: StatusEffect.stun.displayName,
        damage: 0,
        woreOff: woreOff,
      ));
    }
  }

  return (canAct, events);
}
