import '../config/balance_config.dart';
import '../model/combatant.dart';
import '../model/enums.dart';
import '../rng/game_rng.dart';
import '../session/events.dart';
import '../traits/trait.dart';
import 'combat.dart';

/// Executes an autonomous turn for [monster] against [ship].
///
/// Resolves turn action decisions:
/// - Crustaceans never use special actions (always attack).
/// - Other monsters have an 80% chance to attack and 20% to use a special action.
/// - Fixes Bug B2: Filters ready weapons (`chargeCountdown == 0`). If no weapons
///   are ready, falls back to a special action if available, or emits [MonsterHesitated]
///   without spinning in an infinite loop.
/// - Tentacle attacks strike once per intact tentacle remaining, or flail uselessly
///   if all tentacles have been severed.
/// - The chosen weapon resets its charge to `chargeTime`, while all remaining weapons
///   have their charge countdown decremented.
List<GameEvent> takeMonsterTurn(
  MonsterState monster,
  ShipState ship,
  GameRng rng, [
  BalanceConfig config = BalanceConfig.standard,
  List<CombatTrait> traits = const [],
]) {
  if (!monster.isAlive) return const <GameEvent>[];

  final events = <GameEvent>[];

  CombatTrait? findSpecialTrait() {
    for (final trait in traits) {
      if (trait is InkCloudTrait && monster.species == MonsterSpecies.squid) {
        return trait;
      }
    }
    if (monster.species == MonsterSpecies.squid) {
      return const InkCloudTrait();
    }
    return null;
  }

  void executeSpecial(CombatTrait specialTrait) {
    specialTrait.executeSpecialAction(monster, ship, rng);
    if (specialTrait is InkCloudTrait) {
      events.add(InkCloudDeployed(
        monsterName: monster.name,
        acBonus: monster.obscuredAcMod,
      ));
    }
    monster.decrementChargeTimeOnWeapons();
  }

  final isCrustacean = monster.species == MonsterSpecies.crustacean;
  final wantsAttack = isCrustacean ||
      (rng.d100() <= config.monsterAttackProbability);

  if (!wantsAttack) {
    final special = findSpecialTrait();
    if (special != null) {
      executeSpecial(special);
      return events;
    }
    // No special action available; fall through to attack
  }

  // Bug B2 Fix: Filter ready weapons where chargeCountdown == 0
  final readyWeapons = monster.usableWeapons
      .where((w) => w.chargeCountdown == 0)
      .toList();

  if (readyWeapons.isEmpty) {
    final special = findSpecialTrait();
    if (special != null && !monster.isObscured) {
      executeSpecial(special);
      return events;
    }

    events.add(MonsterHesitated(monster.name));
    monster.decrementChargeTimeOnWeapons();
    return events;
  }

  // Pick random ready weapon
  final chosenWeapon = readyWeapons[rng.nextInt(readyWeapons.length)];
  final isTentacle =
      chosenWeapon.monsterWeaponType == MonsterWeaponType.tentacle;

  if (isTentacle) {
    if (monster.numberOfTentacles > 0) {
      for (var i = 0; i < monster.numberOfTentacles; i++) {
        if (!ship.isAlive) break;
        final (_, attackEvents) =
            calculateAttack(monster, chosenWeapon, ship, rng, traits);
        events.addAll(attackEvents);
      }
    } else {
      events.add(AttackMissed(targetName: ship.name));
    }
  } else {
    final (_, attackEvents) =
        calculateAttack(monster, chosenWeapon, ship, rng, traits);
    events.addAll(attackEvents);
  }

  // Put weapon on cooldown
  chosenWeapon.resetCharge();

  // Decrement charge times on remaining weapons
  for (final weapon in monster.usableWeapons) {
    if (weapon != chosenWeapon) {
      weapon.decrementChargeCountdown();
    }
  }

  return events;
}
