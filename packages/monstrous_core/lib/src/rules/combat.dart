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

/// Calculates an individual attack from [attacker] using [weapon] against [defender].
///
/// Resolves the d20 roll against the defender's effective armor class, rolls damage,
/// triggers applicable [traits] hooks, applies final effective damage and status effects,
/// and emits the corresponding [GameEvent]s.
(AttackResult result, List<GameEvent> events) calculateAttack(
  Combatant attacker,
  Weapon weapon,
  Combatant defender,
  GameRng rng, [
  List<CombatTrait> traits = const [],
]) {
  final events = <GameEvent>[];
  final targetAc = defender is MonsterState
      ? defender.effectiveArmorClass
      : defender.armorClass;

  final d20 = rng.d20();
  final totalRoll = d20 + weapon.hitModifier;

  events.add(AttackAttempted(
    attackerName: attacker.name,
    weaponName: weapon.name,
    roll: totalRoll,
    targetAc: targetAc,
  ));

  if (totalRoll < targetAc) {
    final result = AttackResult(
      didHit: false,
      damage: 0,
      damageType: weapon.damageType,
      statusEffect: null,
      description: '${attacker.name} attacks with ${weapon.name}, but misses ${defender.name}.',
    );
    events.add(AttackMissed(targetName: defender.name));
    return (result, events);
  }

  // Attack hit
  final wasManeuver = defender is ShipState &&
      defender.currentEvasion > defender.baseEvasion;

  final result = AttackResult(
    didHit: true,
    damage: weapon.damage,
    damageType: weapon.damageType,
    statusEffect: weapon.statusEffect,
    description: '${attacker.name} attacks with ${weapon.name}',
  );

  for (final trait in traits) {
    trait.onIncomingAttack(defender, attacker, result, rng);
  }

  if (result.wasEvaded) {
    events.add(AttackEvaded(
      shipName: defender.name,
      wasManeuver: wasManeuver,
    ));
    return (result, events);
  }

  if (result.nullifiedDamage > 0) {
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
]) {
  final events = <GameEvent>[];
  final readyWeapons = ship.equippedWeapons
      .where((w) => w.weaponType == weaponType && w.chargeCountdown == 0)
      .toList();

  for (final weapon in readyWeapons) {
    if (!monster.isAlive) break;

    final (_, attackEvents) =
        calculateAttack(ship, weapon, monster, rng, traits);
    events.addAll(attackEvents);
    weapon.resetCharge();

    if (!monster.isAlive) break;
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
      final woreOff = rng.d100() > (100 - config.stunWearOffChanceMonster);
      if (woreOff) {
        combatant.removeStatus(StatusEffect.stun);
      } else {
        canAct = false;
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
