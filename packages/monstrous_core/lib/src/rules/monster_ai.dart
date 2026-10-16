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
  CombatRange range = CombatRange.medium,
]) {
  if (!monster.isAlive) return const <GameEvent>[];

  final events = <GameEvent>[];

  CombatTrait? findSpecialTrait() {
    for (final trait in traits) {
      if (trait is InkCloudTrait &&
          (monster.species == MonsterSpecies.squid ||
              monster.species == MonsterSpecies.kraken)) {
        return trait;
      }
      if (trait is SharkFrenzyTrait &&
          monster.species == MonsterSpecies.shark) {
        return trait;
      }
      if (trait is SerpentSlitherTrait &&
          monster.species == MonsterSpecies.serpent) {
        return trait;
      }
      if (trait is CarapaceTrait &&
          monster.species == MonsterSpecies.crustacean &&
          monster.carapacePlating < monster.maxCarapace) {
        return trait;
      }
    }
    if (monster.species == MonsterSpecies.squid ||
        monster.species == MonsterSpecies.kraken) {
      return const InkCloudTrait();
    }
    if (monster.species == MonsterSpecies.shark) {
      return const SharkFrenzyTrait();
    }
    if (monster.species == MonsterSpecies.serpent) {
      return const SerpentSlitherTrait();
    }
    if (monster.species == MonsterSpecies.crustacean &&
        monster.carapacePlating < monster.maxCarapace) {
      return const CarapaceTrait();
    }
    return null;
  }

  void executeSpecial(CombatTrait specialTrait) {
    final msg = specialTrait.executeSpecialAction(monster, ship, rng);
    if (specialTrait is InkCloudTrait) {
      events.add(InkCloudDeployed(
        monsterName: monster.name,
        acBonus: monster.obscuredAcMod,
      ));
    } else if (specialTrait is SharkFrenzyTrait) {
      events.add(SharkFrenzyRoared(
        monsterName: monster.name,
        stacks: monster.frenzyStacks,
      ));
    } else if (specialTrait is SerpentSlitherTrait) {
      events.add(SerpentSlithered(
        monsterName: monster.name,
        evasionBonus: 20,
      ));
    } else if (msg.isNotEmpty) {
      events.add(NarrationEvent(msg));
    }
    monster.decrementChargeTimeOnWeapons();
  }

  final isJellyfish = monster.species == MonsterSpecies.jellyfish;
  final isCrustacean = monster.species == MonsterSpecies.crustacean;
  final wantsAttack = isJellyfish ||
      (isCrustacean && monster.carapacePlating >= monster.maxCarapace) ||
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
    if (monster.species == MonsterSpecies.squid ||
        monster.species == MonsterSpecies.kraken) {
      final special = findSpecialTrait();
      if (special != null && !monster.isObscured) {
        executeSpecial(special);
        return events;
      }
    }

    events.add(MonsterHesitated(monster.name));
    monster.decrementChargeTimeOnWeapons();
    return events;
  }

  // Pick random ready weapon
  final chosenWeapon = readyWeapons[rng.nextInt(readyWeapons.length)];
  final isTentacle =
      chosenWeapon.monsterWeaponType == MonsterWeaponType.tentacle;

  // Apply Shark Frenzy damage scaling if active
  final originalDamage = chosenWeapon.damage;
  if (monster.species == MonsterSpecies.shark && monster.frenzyStacks > 0) {
    final bonusMultiplier = 1.0 + (monster.frenzyStacks * 0.25);
    chosenWeapon.damage = (originalDamage * bonusMultiplier).round();
  }

  try {
    if (isTentacle) {
      if (monster.numberOfTentacles > 0) {
        for (var i = 0; i < monster.numberOfTentacles; i++) {
          if (!ship.isAlive) break;
          final (_, attackEvents) = calculateAttack(
            monster,
            chosenWeapon,
            ship,
            rng,
            traits,
            0,
            1.0,
            range,
          );
          events.addAll(attackEvents);
        }
      } else {
        events.add(AttackMissed(targetName: ship.name));
      }
    } else {
      final (_, attackEvents) = calculateAttack(
        monster,
        chosenWeapon,
        ship,
        rng,
        traits,
        0,
        1.0,
        range,
      );
      events.addAll(attackEvents);
    }
  } finally {
    // Restore base damage after attacking
    chosenWeapon.damage = originalDamage;
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
