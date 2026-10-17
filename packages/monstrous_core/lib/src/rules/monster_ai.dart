import 'dart:math';

import '../config/balance_config.dart';
import '../model/combatant.dart';
import '../model/enums.dart';
import '../model/monster_intent.dart';
import '../rng/game_rng.dart';
import '../session/events.dart';
import '../traits/trait.dart';
import 'combat.dart';

/// Selects and telegraphs the next [MonsterIntent] for [monster] based on [currentRange].
///
/// Enforces species-specific spatial tactics, cooldowns, and anti-loop rules:
/// - Region Bosses (`kraken`, `worldSerpent`, `ancientLeviathan`) initiate a 2-turn
///   catastrophic wind-up on round 2+ whenever off cooldown.
/// - Sharks close distance with Riptide Wake (Long) and Breaching Lunge (Medium),
///   and ramp Frenzy before biting with Frenzied Jaws (Short).
/// - Crustaceans restore 35% of `maxCarapace` when plating drops below 50%, fire
///   Brine Jets at Medium/Long, crush Short range with Hydraulic Guillotine, and
///   break `Short <-> Medium` dodge loops with Tremor Slam.
/// - Jellyfish alternate between Arc Pulse (closing into Medium/Long) and
///   Nematocyst Curtain (Short/Medium), punishing extended point-blank stays
///   with Neurotoxin Embrace.
/// - Serpents punish Long range with unavoidable Abyssal Under-Strike ambushes
///   and use hit-and-run recoil strikes at Medium and Short range.
/// - Squids snare distant ships at Long range, sweep tentacles or deploy Ink Shrouds
///   at Medium, and grapple the ship's helm at Short range.
MonsterIntent selectNextMonsterIntent(
  MonsterState monster,
  CombatRange currentRange,
  GameRng rng, {
  int battleRound = 1,
}) {
  // 1. Check if a Boss Wind-up just completed Turn 1 and must transition to Turn 2 Strike
  final active = monster.currentIntent;
  if (active != null && active.isBossWindup && active.followUpStrikeId != null) {
    return MonsterIntent.fromId(active.followUpStrikeId!);
  }

  // 2. Check Region Boss 2-turn Catastrophe Wind-up eligibility (Round 2+, off cooldown)
  if (battleRound >= 2) {
    if (monster.species == MonsterSpecies.kraken &&
        !monster.isIntentOnCooldown(MonsterIntentId.bossKrakenWindup) &&
        !monster.isIntentOnCooldown(MonsterIntentId.bossKrakenCatastrophe)) {
      return MonsterIntent.fromId(MonsterIntentId.bossKrakenWindup);
    }
    if (monster.species == MonsterSpecies.worldSerpent &&
        !monster.isIntentOnCooldown(MonsterIntentId.bossWorldSerpentWindup) &&
        !monster.isIntentOnCooldown(MonsterIntentId.bossWorldSerpentCatastrophe)) {
      return MonsterIntent.fromId(MonsterIntentId.bossWorldSerpentWindup);
    }
    if (monster.species == MonsterSpecies.ancientLeviathan &&
        !monster.isIntentOnCooldown(MonsterIntentId.bossLeviathanWindup) &&
        !monster.isIntentOnCooldown(MonsterIntentId.bossLeviathanCatastrophe)) {
      return MonsterIntent.fromId(MonsterIntentId.bossLeviathanWindup);
    }
  }

  // 3. Species-specific spatial intent selection
  switch (monster.species) {
    case MonsterSpecies.shark:
      return switch (currentRange) {
        CombatRange.long =>
          MonsterIntent.fromId(MonsterIntentId.sharkRiptideWake),
        CombatRange.medium =>
          MonsterIntent.fromId(MonsterIntentId.sharkBreachingLunge),
        CombatRange.short =>
          MonsterIntent.fromId(MonsterIntentId.sharkFrenziedJaws),
      };

    case MonsterSpecies.crustacean:
      if (monster.maxCarapace > 0 &&
          monster.carapacePlating < (monster.maxCarapace * 0.5).round() &&
          !monster.isIntentOnCooldown(
              MonsterIntentId.crustaceanCalcifyCarapace)) {
        return MonsterIntent.fromId(MonsterIntentId.crustaceanCalcifyCarapace);
      }
      return switch (currentRange) {
        CombatRange.long =>
          MonsterIntent.fromId(MonsterIntentId.crustaceanBrineJet),
        CombatRange.medium => (!monster.isIntentOnCooldown(
                    MonsterIntentId.crustaceanTremorSlam) &&
                (monster.lastExecutedIntentId ==
                        MonsterIntentId.crustaceanBrineJet ||
                    monster.lastExecutedIntentId ==
                        MonsterIntentId.crustaceanHydraulicGuillotine ||
                    rng.nextInt(100) < 50))
            ? MonsterIntent.fromId(MonsterIntentId.crustaceanTremorSlam)
            : MonsterIntent.fromId(MonsterIntentId.crustaceanBrineJet),
        CombatRange.short => (!monster.isIntentOnCooldown(
                    MonsterIntentId.crustaceanTremorSlam) &&
                monster.lastExecutedIntentId ==
                    MonsterIntentId.crustaceanBrineJet)
            ? MonsterIntent.fromId(MonsterIntentId.crustaceanTremorSlam)
            : MonsterIntent.fromId(
                MonsterIntentId.crustaceanHydraulicGuillotine),
      };

    case MonsterSpecies.jellyfish:
      return switch (currentRange) {
        CombatRange.long =>
          MonsterIntent.fromId(MonsterIntentId.jellyfishArcPulse),
        CombatRange.medium => (monster.lastExecutedIntentId ==
                MonsterIntentId.jellyfishArcPulse)
            ? MonsterIntent.fromId(MonsterIntentId.jellyfishNematocystCurtain)
            : (monster.lastExecutedIntentId ==
                    MonsterIntentId.jellyfishNematocystCurtain)
                ? MonsterIntent.fromId(MonsterIntentId.jellyfishArcPulse)
                : (rng.nextInt(100) < 50
                    ? MonsterIntent.fromId(MonsterIntentId.jellyfishArcPulse)
                    : MonsterIntent.fromId(
                        MonsterIntentId.jellyfishNematocystCurtain)),
        CombatRange.short => !monster.isIntentOnCooldown(
                MonsterIntentId.jellyfishNeurotoxinEmbrace)
            ? MonsterIntent.fromId(MonsterIntentId.jellyfishNeurotoxinEmbrace)
            : MonsterIntent.fromId(MonsterIntentId.jellyfishNematocystCurtain),
      };

    case MonsterSpecies.serpent:
    case MonsterSpecies.worldSerpent:
      return switch (currentRange) {
        CombatRange.long =>
          MonsterIntent.fromId(MonsterIntentId.serpentAbyssalUnderStrike),
        CombatRange.medium =>
          MonsterIntent.fromId(MonsterIntentId.serpentVenomSpitRecoil),
        CombatRange.short =>
          MonsterIntent.fromId(MonsterIntentId.serpentFangedWhipRecoil),
      };

    case MonsterSpecies.squid:
    case MonsterSpecies.kraken:
      return switch (currentRange) {
        CombatRange.long =>
          MonsterIntent.fromId(MonsterIntentId.squidFeedingTentacleSnare),
        CombatRange.medium => (!monster.isObscured &&
                !monster.isIntentOnCooldown(
                    MonsterIntentId.squidInkShroudRecoil) &&
                rng.nextInt(100) < 45)
            ? MonsterIntent.fromId(MonsterIntentId.squidInkShroudRecoil)
            : MonsterIntent.fromId(MonsterIntentId.squidSweepingTentacles),
        CombatRange.short => (!monster.isObscured &&
                !monster.isIntentOnCooldown(
                    MonsterIntentId.squidInkShroudRecoil) &&
                monster.lastExecutedIntentId ==
                    MonsterIntentId.squidConstrictingBeak)
            ? MonsterIntent.fromId(MonsterIntentId.squidInkShroudRecoil)
            : !monster.isIntentOnCooldown(MonsterIntentId.squidConstrictingBeak)
                ? MonsterIntent.fromId(MonsterIntentId.squidConstrictingBeak)
                : MonsterIntent.fromId(MonsterIntentId.squidSweepingTentacles),
      };

    case MonsterSpecies.ancientLeviathan:
      return switch (currentRange) {
        CombatRange.long =>
          MonsterIntent.fromId(MonsterIntentId.sharkRiptideWake),
        CombatRange.medium => !monster.isIntentOnCooldown(
                MonsterIntentId.crustaceanTremorSlam)
            ? MonsterIntent.fromId(MonsterIntentId.crustaceanTremorSlam)
            : MonsterIntent.fromId(MonsterIntentId.sharkBreachingLunge),
        CombatRange.short =>
          MonsterIntent.fromId(MonsterIntentId.crustaceanHydraulicGuillotine),
      };
  }
}

/// Resolves the telegraphed [MonsterState.currentIntent] against [ship] at [currentRange].
///
/// Returns the updated [CombatRange] after any monster lunge/recoil/pull and all
/// emitted [GameEvent]s.
(CombatRange newRange, List<GameEvent> events) executeMonsterIntent(
  MonsterState monster,
  ShipState ship,
  GameRng rng,
  CombatRange currentRange, [
  BalanceConfig config = BalanceConfig.standard,
  List<CombatTrait> traits = const [],
  HelmOrder playerHelmOrderThisTurn = HelmOrder.holdLine,
]) {
  if (!monster.isAlive) {
    return (currentRange, const <GameEvent>[]);
  }

  final intent = monster.currentIntent ??
      selectNextMonsterIntent(monster, currentRange, rng);
  var range = currentRange;
  final events = <GameEvent>[];

  // 1. Boss Wind-up Turn 1 of 2: Telegraphed gathering of catastrophic power
  if (intent.isBossWindup) {
    events.add(NarrationEvent(
      '${monster.name} coils with cataclysmic force: ${intent.description}',
    ));
    monster.lastExecutedIntentId = intent.id;
    monster.isPinnedThisTurn = false;
    monster.tickIntentCooldowns();
    if (intent.followUpStrikeId != null) {
      final nextIntent = MonsterIntent.fromId(intent.followUpStrikeId!);
      monster.currentIntent = nextIntent;
      events.add(MonsterIntentTelegraphed(
        monsterName: monster.name,
        intent: nextIntent,
      ));
    } else {
      monster.currentIntent = null;
    }
    return (range, events);
  }

  // 2. Self-buff / Carapace regeneration intent (Crustacean Calcify Carapace)
  if (intent.id == MonsterIntentId.crustaceanCalcifyCarapace) {
    final restored = max(1, (monster.maxCarapace * 0.35).round());
    monster.carapacePlating =
        min(monster.maxCarapace, monster.carapacePlating + restored);
    monster.removeStatus(StatusEffect.burn);
    monster.removeStatus(StatusEffect.poison);
    events.add(NarrationEvent(
      '${monster.name} calcifies its shell plates, restoring $restored Carapace (${monster.carapacePlating}/${monster.maxCarapace}) and purging corrosive statuses!',
    ));
    monster.tickIntentCooldowns();
    if (intent.cooldownTurns > 0) {
      monster.setIntentCooldown(intent.id, intent.cooldownTurns);
    }
    monster.lastExecutedIntentId = intent.id;
    monster.isPinnedThisTurn = false;
    monster.currentIntent = null;
    return (range, events);
  }

  // 3. Shark Frenzied Jaws: gains +1 Frenzy stack BEFORE attempting to hit,
  // so even if the ship maneuvers out of Short Range, the Shark's frenzy still ramps!
  if (intent.id == MonsterIntentId.sharkFrenziedJaws) {
    monster.frenzyStacks++;
    events.add(SharkFrenzyRoared(
      monsterName: monster.name,
      stacks: monster.frenzyStacks,
    ));
  }

  // 4. Pre-Attack Movement (Charges & Ambushes)
  var hadHeadOnCollision = false;
  if (intent.moveTiming == IntentMoveTiming.beforeAttack &&
      intent.moveDelta != IntentMoveDelta.stationary) {
    if (monster.isPinnedThisTurn) {
      events.add(NarrationEvent(
        '${monster.name}\'s ${intent.name} lunge was held in check by pinning ordnance!',
      ));
    } else {
      if (intent.moveDelta == IntentMoveDelta.closer1) {
        final targetRange = range.closer;
        if (playerHelmOrderThisTurn == HelmOrder.advance &&
            targetRange == CombatRange.short) {
          hadHeadOnCollision = true;
        }
        if (range != targetRange) {
          final prev = range;
          range = targetRange;
          events.add(CombatRangeChanged(
            previousRange: prev,
            newRange: range,
            reason:
                '${monster.name} surged closer with ${intent.name} (${prev.displayName} -> ${range.displayName})!',
          ));
        }
        if (hadHeadOnCollision) {
          events.add(HeadOnCollisionOccurred(
            monsterName: monster.name,
            shipName: ship.name,
            intentName: intent.name,
            bonusDamagePercent: 30,
          ));
        }
      } else if (intent.moveDelta == IntentMoveDelta.ambushToShort) {
        if (range != CombatRange.short) {
          final prev = range;
          range = CombatRange.short;
          events.add(CombatRangeChanged(
            previousRange: prev,
            newRange: range,
            reason:
                '${monster.name} vanished beneath the abyss and erupted at point-blank range!',
          ));
        }
      }
    }
  }

  // 5. Attack Resolution & Positional Evasion Check
  var didHitShip = false;
  if (intent.threatenedRanges.isNotEmpty) {
    if (!intent.threatenedRanges.contains(range)) {
      events.add(MonsterAttackOutOfRange(
        monsterName: monster.name,
        intentName: intent.name,
        shipName: ship.name,
        currentRange: range,
      ));
    } else {
      final readyWeapons = monster.usableWeapons
          .where((w) => w.chargeCountdown == 0)
          .toList();
      final chosenWeapon = readyWeapons.isNotEmpty
          ? readyWeapons[rng.nextInt(readyWeapons.length)]
          : (monster.usableWeapons.isNotEmpty
              ? monster.usableWeapons.first
              : null);

      if (chosenWeapon == null) {
        events.add(MonsterHesitated(monster.name));
      } else {
        var effectiveMultiplier = intent.damageMultiplier;
        if (monster.species == MonsterSpecies.shark &&
            monster.frenzyStacks > 0) {
          effectiveMultiplier *= (1.0 + (monster.frenzyStacks * 0.25));
        }
        if (hadHeadOnCollision) {
          effectiveMultiplier *= 1.30;
        }

        final isMultiTentacleSweep =
            intent.id == MonsterIntentId.squidSweepingTentacles &&
                chosenWeapon.monsterWeaponType == MonsterWeaponType.tentacle;

        if (isMultiTentacleSweep) {
          if (monster.numberOfTentacles > 0) {
            for (var i = 0; i < monster.numberOfTentacles; i++) {
              if (!ship.isAlive) break;
              final (res, attackEvents) = calculateAttack(
                monster,
                chosenWeapon,
                ship,
                rng,
                traits,
                0,
                effectiveMultiplier,
                range,
              );
              events.addAll(attackEvents);
              if (res.didHit && !res.wasEvaded) {
                didHitShip = true;
              }
            }
          } else {
            events.add(AttackMissed(targetName: ship.name));
          }
        } else {
          final (res, attackEvents) = calculateAttack(
            monster,
            chosenWeapon,
            ship,
            rng,
            traits,
            0,
            effectiveMultiplier,
            range,
          );
          events.addAll(attackEvents);
          if (res.didHit && !res.wasEvaded) {
            didHitShip = true;
          }
        }

        chosenWeapon.resetCharge();
        for (final weapon in monster.usableWeapons) {
          if (weapon != chosenWeapon) {
            weapon.decrementChargeCountdown();
          }
        }
      }
    }
  }

  // 6. On-Hit Tactical Effects
  if (didHitShip && ship.isAlive) {
    switch (intent.id) {
      case MonsterIntentId.sharkRiptideWake:
        ship.tempAccuracyPenalty = max(ship.tempAccuracyPenalty, 10);
        events.add(NarrationEvent(
          'Blinding spray from ${monster.name}\'s Riptide Wake fouls gunnery sights (-10% accuracy next turn)!',
        ));
      case MonsterIntentId.crustaceanBrineJet:
      case MonsterIntentId.jellyfishNematocystCurtain:
      case MonsterIntentId.serpentVenomSpitRecoil:
      case MonsterIntentId.bossWorldSerpentCatastrophe:
        if (!ship.hasStatus(StatusEffect.poison)) {
          ship.addStatus(StatusEffect.poison);
          events.add(NarrationEvent(
            '${intent.name} coats ${ship.name} in corrosive abyssal venom (Poison)!',
          ));
        }
      case MonsterIntentId.bossLeviathanCatastrophe:
        if (!ship.hasStatus(StatusEffect.burn)) {
          ship.addStatus(StatusEffect.burn);
          events.add(NarrationEvent(
            '${intent.name} engulfs ${ship.name} in superheated caldera fire (Burn)!',
          ));
        }
      case MonsterIntentId.crustaceanTremorSlam:
        ship.currentEvasion = max(0, ship.currentEvasion - 15);
        events.add(NarrationEvent(
          'Abyssal shockwaves from ${intent.name} rattle ${ship.name}\'s rudder (-15% evasion)!',
        ));
      case MonsterIntentId.jellyfishNeurotoxinEmbrace:
        if (ship.equippedWeapons.isNotEmpty) {
          final targetWeapon =
              ship.equippedWeapons[rng.nextInt(ship.equippedWeapons.length)];
          targetWeapon.chargeCountdown += 1;
          events.add(NarrationEvent(
            'Bio-electric neurotoxin shorts out ${targetWeapon.name} (+1 turn cooldown)!',
          ));
        }
      case MonsterIntentId.squidConstrictingBeak:
        ship.isGrappled = true;
        events.add(ShipGrappled(
          shipName: ship.name,
          monsterName: monster.name,
        ));
      default:
        break;
    }
  }

  // 7. Post-Attack Buffs & Movement (Recoils & Tentacle Snares)
  if (ship.isAlive) {
    if (intent.id == MonsterIntentId.serpentVenomSpitRecoil) {
      monster.evasion = min(80, monster.evasion + 20);
      events.add(SerpentSlithered(
        monsterName: monster.name,
        evasionBonus: 20,
      ));
    } else if (intent.id == MonsterIntentId.squidInkShroudRecoil) {
      monster.isObscured = true;
      events.add(InkCloudDeployed(
        monsterName: monster.name,
        acBonus: monster.obscuredAcMod,
      ));
    }

    if (intent.moveTiming == IntentMoveTiming.afterAttack &&
        intent.moveDelta != IntentMoveDelta.stationary) {
      if (monster.isPinnedThisTurn) {
        events.add(NarrationEvent(
          '${monster.name} could not reposition while pinned!',
        ));
      } else if (intent.moveDelta == IntentMoveDelta.farther1 &&
          range != CombatRange.long) {
        final prev = range;
        range = range.farther;
        events.add(CombatRangeChanged(
          previousRange: prev,
          newRange: range,
          reason:
              '${monster.name} recoiled into deeper water (${prev.displayName} -> ${range.displayName})!',
        ));
      } else if (intent.moveDelta == IntentMoveDelta.pullShipCloser1 &&
          didHitShip &&
          range != CombatRange.short) {
        final prev = range;
        range = range.closer;
        events.add(CombatRangeChanged(
          previousRange: prev,
          newRange: range,
          reason:
              '${monster.name}\'s barbed tentacles dragged ${ship.name} into ${range.displayName}!',
        ));
      }
    }
  }

  // 8. Cooldown & Turn Cleanup
  monster.tickIntentCooldowns();
  if (intent.cooldownTurns > 0) {
    monster.setIntentCooldown(intent.id, intent.cooldownTurns);
  }
  if (intent.isBossCatastropheStrike) {
    switch (intent.id) {
      case MonsterIntentId.bossKrakenCatastrophe:
        monster.setIntentCooldown(
            MonsterIntentId.bossKrakenWindup, 3);
      case MonsterIntentId.bossWorldSerpentCatastrophe:
        monster.setIntentCooldown(
            MonsterIntentId.bossWorldSerpentWindup, 3);
      case MonsterIntentId.bossLeviathanCatastrophe:
        monster.setIntentCooldown(
            MonsterIntentId.bossLeviathanWindup, 3);
      default:
        break;
    }
    monster.windupDamageTaken = 0;
  }

  monster.lastExecutedIntentId = intent.id;
  monster.isPinnedThisTurn = false;
  monster.currentIntent = null;

  return (range, events);
}

/// Executes an autonomous turn for [monster] against [ship].
///
/// If [monster.currentIntent] is active, delegates to [executeMonsterIntent];
/// otherwise falls back to legacy autonomous weapon/trait selection for
/// backward compatibility with isolated unit tests.
List<GameEvent> takeMonsterTurn(
  MonsterState monster,
  ShipState ship,
  GameRng rng, [
  BalanceConfig config = BalanceConfig.standard,
  List<CombatTrait> traits = const [],
  CombatRange range = CombatRange.medium,
]) {
  if (!monster.isAlive) return const <GameEvent>[];
  if (monster.currentIntent != null) {
    final (_, events) = executeMonsterIntent(
      monster,
      ship,
      rng,
      range,
      config,
      traits,
    );
    return events;
  }

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

