import '../config/balance_config.dart';
import '../model/attack_result.dart';
import '../model/bloodline_trait.dart';
import '../model/combatant.dart';
import '../model/combat_presentation.dart';
import '../model/enums.dart';
import '../model/item.dart';
import '../model/flagship_blueprint.dart';
import '../model/monster_intent.dart';
import '../model/ocean_power.dart';
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
    ShipWeaponType.flamethrower => 1.00,
  };
}

/// Calculates the percentage hit chance for [attacker] firing [weapon] at [defender].
///
/// Bounded between 25% and 95%:
/// - Base accuracy from [weapon.baseAccuracy] (or [weapon.hitModifier]).
/// - Optional [accuracyBonus] (e.g. from island gunnery drills or Standard Gun-Deck Bracing).
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
  bool ignoreObscurity = false,
}) {
  int chance = weapon.baseAccuracy + accuracyBonus;
  if (attacker is ShipState &&
      attacker.captainBoonId == BloodlineTraitId.preciseCommander) {
    chance += 5;
  }
  if (attacker is MonsterState) {
    chance -= attacker.tremorAccPenalty;
    if (attacker.isElectroJolted) chance -= 30;
  }
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
    } else if (!ignoreObscurity) {
      chance -= defender.obscurityAccuracyPenalty;
    }
    final isMassiveBeast =
        defender.species == MonsterSpecies.kraken ||
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
/// [unavoidable] bypasses accuracy and dodge only, preserving mitigation and
/// damage riders. It is used by the Kraken's dedicated catastrophe release.
(AttackResult result, List<GameEvent> events) calculateAttack(
  Combatant attacker,
  Weapon weapon,
  Combatant defender,
  GameRng rng, [
  List<CombatTrait> traits = const [],
  int accuracyBonus = 0,
  double damageMultiplier = 1.0,
  CombatRange range = CombatRange.medium,
  bool unavoidable = false,
]) {
  final events = <GameEvent>[];
  final hitChance = unavoidable
      ? 100
      : calculateHitChance(
          attacker,
          weapon,
          defender,
          accuracyBonus: accuracyBonus,
          range: range,
        );
  final roll = unavoidable ? 0 : rng.d100();
  final didHit = unavoidable || roll <= hitChance;

  if (unavoidable) {
    events.add(
      NarrationEvent(
        '${attacker.name} unleashes ${weapon.name}: the release cannot miss or be dodged!',
      ),
    );
  } else {
    events.add(
      AttackAttempted(
        attacker: attacker is ShipState ? CombatSide.ship : CombatSide.monster,
        attackerName: attacker.name,
        weaponName: weapon.name,
        roll: roll,
        targetAc: hitChance,
      ),
    );
  }

  var effectiveMultiplier = damageMultiplier;
  final blessing =
      attacker is ShipState &&
          weapon is ShipWeapon &&
          (weapon.weaponType.isBlueprintIntrinsic ||
              weapon.weaponType == ShipWeaponType.cannon)
      ? attacker.blessings[weapon.isSignature
            ? HardpointType.signature
            : HardpointType.broadside]
      : null;
  if (blessing != null) {
    effectiveMultiplier *= 1 + blessing.damageBonus;
    if (defender is MonsterState) {
      if (blessing.power == OceanPower.earthshakerTitan &&
          blessing.slot == HardpointType.signature &&
          _isWindingUp(defender)) {
        effectiveMultiplier *= blessing.tier == 3 ? 1.35 : 1.25;
      }
      if (blessing.power == OceanPower.brinemother &&
          blessing.slot == HardpointType.signature &&
          blessing.tier == 3 &&
          defender.carapacePlating == 0) {
        effectiveMultiplier *= 1.15;
      }
    }
    // Phase 3B introduces critical strikes: 1.5x damage, using only GameRng.
    if (didHit &&
        blessing.critChanceBonus > 0 &&
        rng.d100() <= blessing.critChanceBonus) {
      effectiveMultiplier *= 1.5;
      events.add(NarrationEvent('Thunderclap critical strike!'));
    }
  }
  if (attacker is MonsterState) {
    if (attacker.species == MonsterSpecies.shark) {
      effectiveMultiplier *= 1 + attacker.frenzyStacks * 0.25;
    }
    effectiveMultiplier *= 1 - attacker.corrodedStacks * 0.05;
    if (attacker.isElectroJolted) effectiveMultiplier *= 0.75;
  }
  if (weapon is ShipWeapon) {
    effectiveMultiplier *= weaponRangeDamageMultiplier(
      weapon.weaponType,
      range,
    );
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

  // Stabilize half-point rounding after multiplying several percentage factors.
  final unamplifiedDamage = (weapon.damage * effectiveMultiplier + 1e-9)
      .round();
  final baseDamage = attacker is ShipState && defender is MonsterState
      ? amplifyMonsterDamage(attacker, defender, unamplifiedDamage)
      : unamplifiedDamage;
  final impactRange =
      (weapon is ShipWeapon && weapon.weaponType == ShipWeaponType.prowRam)
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
    events.add(
      MortarBackfireOccurred(
        shipName: attacker.name,
        damage: backfireDmg,
        remainingHp: attacker.currentHp,
      ),
    );
    if (!attacker.isAlive) {
      events.add(
        CombatantDefeated(
          name: attacker.name,
          flavorMessage:
              '${attacker.name} was destroyed by its own point-blank mortar barrage!',
        ),
      );
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
    events.add(
      AttackMissed(
        targetName: defender.name,
        target: defender is ShipState ? CombatSide.ship : CombatSide.monster,
      ),
    );
    if (attacker is MonsterState && defender is ShipState) {
      events.addAll(_stormRetaliation(defender, attacker));
    }
    return (result, events);
  }

  // Attack hit
  final wasManeuver =
      defender is ShipState && defender.currentEvasion > defender.baseEvasion;

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
  final wasObscured = defender is MonsterState && defender.isObscured;
  final priorEvasion = defender is ShipState ? defender.currentEvasion : null;
  // Resolve avoidance before any hit rider mutates armor, ink, or tentacles.
  if (!unavoidable) {
    for (final trait in activeTraits.where(
      (trait) => trait is EvasionTrait || trait is SerpentSlitherTrait,
    )) {
      trait.onIncomingAttack(defender, attacker, result, rng);
    }
  }
  for (final trait in activeTraits) {
    if (result.wasEvaded) break;
    if (trait is EvasionTrait || trait is SerpentSlitherTrait) continue;
    trait.onIncomingAttack(defender, attacker, result, rng);
  }
  if (wasObscured && !defender.isObscured) {
    events.add(
      NarrationEvent(
        '${defender.name}\'s obscuring cloud dispersed; its accuracy penalty is cleared.',
      ),
    );
  }

  if (wasObscured && !defender.isObscured) {
    events.add(CombatEffectsChanged.capture(defender));
  }

  if (result.wasEvaded) {
    events.add(
      AttackEvaded(
        shipName: defender.name,
        wasManeuver: wasManeuver,
        target: defender is ShipState ? CombatSide.ship : CombatSide.monster,
      ),
    );
    if (defender is ShipState && defender.currentEvasion != priorEvasion) {
      events.add(CombatEffectsChanged.capture(defender));
    }
    if (attacker is MonsterState && defender is ShipState) {
      events.addAll(_stormRetaliation(defender, attacker));
    }
    return (result, events);
  }

  if (result.carapaceDamaged > 0 || result.wasCarapaceShattered) {
    events.add(
      CarapaceDamaged(
        monsterName: defender.name,
        damageDealt: result.carapaceDamaged,
        remainingCarapace: (defender as MonsterState).carapacePlating,
        wasShattered: result.wasCarapaceShattered,
      ),
    );
  }

  if (result.carapaceAbsorbed > 0) {
    events.add(
      CarapaceAbsorbed(
        monsterName: defender.name,
        absorbedAmount: result.carapaceAbsorbed,
        remainingCarapace: (defender as MonsterState).carapacePlating,
        penetratingDamage: result.damage - result.nullifiedDamage,
      ),
    );
  }

  if (result.disruptedFrenzy) {
    events.add(
      SharkFrenzyDisrupted(
        monsterName: defender.name,
        reason: 'Shock disrupted feeding frenzy',
      ),
    );
    events.add(CombatEffectsChanged.capture(defender));
  }

  if (defender is ShipState &&
      defender.captainQuirkId == BloodlineTraitId.exactingShipwright) {
    final remaining = (result.damage - result.nullifiedDamage).clamp(
      0,
      result.damage,
    );
    final reduction = remaining * 0.10 + defender.exactingReductionRemainder;
    final wholeReduction = (reduction + 1e-9).floor();
    defender.exactingReductionRemainder = reduction - wholeReduction;
    result.nullifiedDamage += wholeReduction;
  }

  if (result.nullifiedDamage > 0 && defender is ShipState) {
    events.add(
      DamageReduced(
        shipName: defender.name,
        nullifiedAmount: result.nullifiedDamage,
      ),
    );
  }

  final barrierWasHit =
      defender is ShipState &&
      defender.basaltBarrierHp > 0 &&
      defender.basaltAegisTurns > 0 &&
      result.damage > result.nullifiedDamage;
  if (barrierWasHit) {
    final ship = defender;
    final absorbed = (result.damage - result.nullifiedDamage).clamp(
      0,
      ship.basaltBarrierHp,
    );
    ship.basaltBarrierHp -= absorbed;
    result.nullifiedDamage += absorbed;
    events.add(
      DamageReduced(
        shipName: ship.name,
        nullifiedAmount: absorbed,
        defense: DefenseKind.barrier,
        remainingBarrierHp: ship.basaltBarrierHp,
      ),
    );
    events.add(CombatEffectsChanged.capture(ship));
  }
  final effectiveDamage = (result.damage - result.nullifiedDamage).clamp(
    0,
    defender.currentHp,
  );
  defender.applyDamage(effectiveDamage);

  events.add(
    AttackHit(
      targetName: defender.name,
      target: defender is ShipState ? CombatSide.ship : CombatSide.monster,
      damage: effectiveDamage,
      damageType: result.damageType.displayName,
      remainingHp: defender.currentHp,
    ),
  );

  if (result.tentaclesSevered > 0 && defender is MonsterState) {
    events.add(
      TentaclesSevered(
        countSevered: result.tentaclesSevered,
        remainingTentacles: defender.numberOfTentacles,
      ),
    );
  }

  if (result.statusEffect != null) {
    defender.addStatus(result.statusEffect!);
    events.add(CombatEffectsChanged.capture(defender));
  }

  if (attacker is ShipState &&
      defender is MonsterState &&
      blessing != null &&
      defender.isAlive) {
    final detonationBase =
        (weapon.damage *
                damageMultiplier *
                (weapon is ShipWeapon
                    ? weaponRangeDamageMultiplier(weapon.weaponType, range)
                    : 1))
            .round();
    events.addAll(
      _applyWeaponBlessing(attacker, defender, blessing, detonationBase, rng),
    );
  }
  if (attacker is MonsterState && defender is ShipState) {
    if (barrierWasHit && attacker.isAlive) {
      final tier = defender.blessings[HardpointType.utility]!.tier;
      events.addAll(
        dealBlessingDamage(
          defender,
          attacker,
          [12, 20, 30][tier - 1],
          DamageType.piercing,
          source: 'Tidal Shockwave',
          carapaceMultiplier: 1.5,
        ),
      );
    }
    events.addAll(_stormRetaliation(defender, attacker));
  }

  if (!defender.isAlive &&
      !events.whereType<CombatantDefeated>().any(
        (event) => event.name == defender.name,
      )) {
    events.add(
      CombatantDefeated(
        name: defender.name,
        flavorMessage: '${defender.name} has been defeated!',
      ),
    );
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
    throw StateError(
      'Cannot fire ${weaponType.displayName} at ${range.displayName}',
    );
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
/// - BURN: Legacy fire deals `5 * difficulty` with a 25% wear-off chance;
///   Magma ignition instead lasts exactly 3 monster turns.
/// - POISON: Deals `5 * difficulty` venom damage, 25% wear-off chance.
/// - STUN: Always skips exactly one action, then clears for both sides.
(bool canAct, List<GameEvent> events) updateStatusEffects(
  Combatant combatant,
  int difficulty,
  GameRng rng, [
  BalanceConfig config = BalanceConfig.standard,
  ShipState? blessingShip,
  int? regionIndex,
]) {
  final events = <GameEvent>[];

  if (combatant.hasStatus(StatusEffect.burn)) {
    final magmaBurn = combatant is MonsterState && combatant.burnTurns > 0;
    var damage = config.statusEffectTickDamageMultiplier * difficulty;
    if (magmaBurn && blessingShip != null) {
      final tier = blessingShip.highestBlessingTier(OceanPower.magmaVentLord);
      // "Scaled slightly by region": +10% per region beyond the first.
      damage =
          ([6, 10, 15][(tier - 1).clamp(0, 2)] *
                  (1 + 0.10 * (regionIndex ?? difficulty - 1).clamp(0, 2)))
              .round();
    }
    if (combatant is MonsterState && blessingShip != null) {
      final utility = blessingShip.blessings[HardpointType.utility];
      if (utility?.power == OceanPower.magmaVentLord &&
          utility?.tier == 3 &&
          blessingShip.boilingWakeTurns > 0) {
        damage = (damage * 1.5).round();
      }
      damage = amplifyMonsterDamage(blessingShip, combatant, damage);
    }
    if (combatant is ShipState &&
        combatant.captainBoonId == BloodlineTraitId.ironConstitution) {
      damage = (damage * 0.5).round();
    }
    combatant.applyDamage(damage);
    final isDead = !combatant.isAlive;
    if (magmaBurn) combatant.burnTurns--;
    final woreOff = magmaBurn
        ? combatant.burnTurns == 0
        : !isDead && (rng.d100() > (100 - config.statusWearOffChance));
    if (woreOff) {
      combatant.removeStatus(StatusEffect.burn);
    }
    events.add(
      StatusEffectTicked(
        targetName: combatant.name,
        target: combatant is ShipState ? CombatSide.ship : CombatSide.monster,
        remainingHp: combatant.currentHp,
        effectName: StatusEffect.burn.displayName,
        damage: damage,
        woreOff: woreOff,
      ),
    );
    events.add(CombatEffectsChanged.capture(combatant));
    if (isDead) {
      events.add(
        CombatantDefeated(
          name: combatant.name,
          flavorMessage: '${combatant.name} was destroyed by fire!',
        ),
      );
      return (false, events);
    }
  }

  if (combatant.hasStatus(StatusEffect.poison)) {
    var damage = config.statusEffectTickDamageMultiplier * difficulty;
    if (combatant is ShipState &&
        combatant.captainBoonId == BloodlineTraitId.ironConstitution) {
      damage = (damage * 0.5).round();
    }
    if (combatant is MonsterState && blessingShip != null) {
      damage = amplifyMonsterDamage(blessingShip, combatant, damage);
    }
    combatant.applyDamage(damage);
    final isDead = !combatant.isAlive;
    final woreOff =
        !isDead && (rng.d100() > (100 - config.statusWearOffChance));
    if (woreOff) {
      combatant.removeStatus(StatusEffect.poison);
    }
    events.add(
      StatusEffectTicked(
        targetName: combatant.name,
        target: combatant is ShipState ? CombatSide.ship : CombatSide.monster,
        remainingHp: combatant.currentHp,
        effectName: StatusEffect.poison.displayName,
        damage: damage,
        woreOff: woreOff,
      ),
    );
    events.add(CombatEffectsChanged.capture(combatant));
    if (isDead) {
      events.add(
        CombatantDefeated(
          name: combatant.name,
          flavorMessage: '${combatant.name} succumbed to venom!',
        ),
      );
      return (false, events);
    }
  }

  var canAct = true;
  if (combatant.hasStatus(StatusEffect.stun)) {
    if (combatant is ShipState) {
      combatant.removeStatus(StatusEffect.stun);
      combatant.decrementChargeTimeOnWeapons();
      events.add(
        StatusEffectTicked(
          targetName: combatant.name,
          target: CombatSide.ship,
          remainingHp: combatant.currentHp,
          effectName: StatusEffect.stun.displayName,
          damage: 0,
          woreOff: true,
        ),
      );
      canAct = false;
    } else {
      canAct = false;
      combatant.removeStatus(StatusEffect.stun);
      events.add(
        StatusEffectTicked(
          targetName: combatant.name,
          target: combatant is ShipState ? CombatSide.ship : CombatSide.monster,
          remainingHp: combatant.currentHp,
          effectName: StatusEffect.stun.displayName,
          damage: 0,
          woreOff: true,
        ),
      );
    }
  }

  if (!canAct) events.add(CombatEffectsChanged.capture(combatant));
  return (canAct, events);
}

/// Applies Corroded once, before mitigation, for every incoming damage source.
int amplifyMonsterDamage(ShipState ship, MonsterState monster, int damage) =>
    (damage *
            (1 +
                monster.corrodedStacks *
                    (ship.highestBlessingTier(OceanPower.brinemother) == 3
                        ? 0.12
                        : 0.08)))
        .round();

bool _isWindingUp(MonsterState monster) =>
    monster.currentIntent?.isBossWindup == true ||
    monster.currentIntent?.isBossCatastropheStrike == true;

void _breakWindup(MonsterState monster) {
  final intent = monster.currentIntent;
  if (intent != null) {
    monster.setIntentCooldown(intent.id, 3);
    if (intent.followUpStrikeId != null) {
      monster.setIntentCooldown(intent.followUpStrikeId!, 3);
    }
  }
  switch (monster.species) {
    case MonsterSpecies.kraken:
      monster.setIntentCooldown(MonsterIntentId.bossKrakenWindup, 3);
    case MonsterSpecies.worldSerpent:
      monster.setIntentCooldown(MonsterIntentId.bossWorldSerpentWindup, 3);
    case MonsterSpecies.ancientLeviathan:
      monster.setIntentCooldown(MonsterIntentId.bossLeviathanWindup, 3);
    default:
      break;
  }
  // A stationary normal strike avoids granting a new charge or another windup.
  monster.currentIntent = MonsterIntent.fromId(MonsterIntentId.normalStrike);
  monster.windupDamageTaken = 0;
}

void _ignite(MonsterState monster) {
  monster.addStatus(StatusEffect.burn);
  monster.burnTurns = 3;
}

void _corrode(MonsterState monster, int stacks) {
  monster.corrodedStacks = (monster.corrodedStacks + stacks).clamp(0, 3);
  monster.corrodedTurns = 3;
}

/// Resolves a guaranteed elemental rider without reapplying weapon blessings.
List<GameEvent> dealBlessingDamage(
  ShipState ship,
  MonsterState monster,
  int damage,
  DamageType type, {
  required String source,
  double carapaceMultiplier = 1,
}) {
  if (!monster.isAlive) return [];
  final events = <GameEvent>[];
  final flareDamage = type == DamageType.blast && monster.isIlluminatedByFlare
      ? (damage * (1 + monster.spotterFlareBlastBonus)).round()
      : damage;
  final amplified = amplifyMonsterDamage(ship, monster, flareDamage);
  var absorbed = 0;
  if (type != DamageType.fire && monster.carapacePlating > 0) {
    final multiplier = type == DamageType.blast ? 1.5 : carapaceMultiplier;
    final shellDamage = (amplified * multiplier).round().clamp(
      0,
      monster.carapacePlating,
    );
    monster.carapacePlating -= shellDamage;
    absorbed = shellDamage.clamp(0, amplified);
    events.add(
      CarapaceDamaged(
        monsterName: monster.name,
        damageDealt: shellDamage,
        remainingCarapace: monster.carapacePlating,
        wasShattered: monster.carapacePlating == 0,
      ),
    );
  }
  final hpDamage = (amplified - absorbed).clamp(0, monster.currentHp);
  monster.applyDamage(hpDamage);
  events.add(NarrationEvent('$source strikes ${monster.name}.'));
  events.add(
    AttackHit(
      targetName: monster.name,
      target: CombatSide.monster,
      damage: hpDamage,
      damageType: type.displayName,
      remainingHp: monster.currentHp,
      isBlessingDamage: true,
      source: source,
    ),
  );
  if (!monster.isAlive) {
    events.add(
      CombatantDefeated(
        name: monster.name,
        flavorMessage: '${monster.name} was defeated by $source!',
      ),
    );
  }
  return events;
}

List<GameEvent> _addStatic(ShipState ship, MonsterState monster, int stacks) {
  monster.staticStacks += stacks;
  final events = <GameEvent>[CombatEffectsChanged.capture(monster)];
  if (monster.staticStacks < 3) return events;
  monster.staticStacks = 0;
  events.add(CombatEffectsChanged.capture(monster));
  final tier = ship.highestBlessingTier(OceanPower.tempestSovereign);
  events.addAll(
    dealBlessingDamage(
      ship,
      monster,
      [12, 20, 28][(tier - 1).clamp(0, 2)],
      DamageType.shock,
      source: 'Arc Discharge',
    ),
  );
  if (monster.frenzyStacks > 0) {
    monster.frenzyStacks = 0;
    events.add(
      SharkFrenzyDisrupted(
        monsterName: monster.name,
        reason: 'Arc Discharge purged the frenzy',
      ),
    );
  }
  if (_isWindingUp(monster)) {
    final disruptedIntent = monster.currentIntent!;
    _breakWindup(monster);
    monster.addStatus(StatusEffect.stun);
    events.add(
      MonsterIntentDisrupted(
        monsterName: monster.name,
        intentName: disruptedIntent.name,
        reason: 'Arc Discharge shattered the lethal windup!',
      ),
    );
  } else {
    monster.isElectroJolted = true;
  }
  events.add(CombatEffectsChanged.capture(monster));
  return events;
}

List<GameEvent> _applyWeaponBlessing(
  ShipState ship,
  MonsterState monster,
  HardpointBlessing blessing,
  int damage,
  GameRng rng,
) {
  final signature = blessing.slot == HardpointType.signature;
  switch (blessing.power) {
    case OceanPower.magmaVentLord:
      final effects = <GameEvent>[];
      if (!signature || blessing.tier == 3) {
        _ignite(monster);
        effects.add(CombatEffectsChanged.capture(monster));
      }
      if (signature && monster.hasStatus(StatusEffect.burn)) {
        return [
          ...effects,
          ...dealBlessingDamage(
            ship,
            monster,
            (damage * [0.25, 0.40, 0.60][blessing.tier - 1]).round(),
            DamageType.blast,
            source: 'Thermal Detonation',
          ),
        ];
      }
      return effects;
    case OceanPower.tempestSovereign:
      final stacks = signature
          ? (blessing.tier == 3 ? 3 : 2)
          : blessing.tier == 3 && rng.d100() <= 35
          ? 2
          : 1;
      return _addStatic(ship, monster, stacks);
    case OceanPower.brinemother:
      _corrode(
        monster,
        signature
            ? (blessing.tier == 3 ? 3 : 2)
            : blessing.tier == 3
            ? 2
            : 1,
      );
    case OceanPower.earthshakerTitan:
      if (!signature) {
        monster.tremorAccPenalty = [10, 15, 20][blessing.tier - 1];
      } else if (_isWindingUp(monster)) {
        final disruptedIntent = monster.currentIntent!;
        _breakWindup(monster);
        if (blessing.tier == 3) monster.addStatus(StatusEffect.stun);
        return [
          NarrationEvent('Fault-Line Shatter breaks the lethal windup!'),
          MonsterIntentDisrupted(
            monsterName: monster.name,
            intentName: disruptedIntent.name,
            reason: 'Fault-Line Shatter breaks the lethal windup!',
          ),
          CombatEffectsChanged.capture(monster),
        ];
      }
  }
  return [CombatEffectsChanged.capture(monster)];
}

/// Adds a rider to the ship's existing class-specific utility action.
List<GameEvent> activateUtilityBlessing(ShipState ship, MonsterState monster) {
  final blessing = ship.blessings[HardpointType.utility];
  if (blessing == null || !monster.isAlive) return [];
  final tier = blessing.tier;
  switch (blessing.power) {
    case OceanPower.magmaVentLord:
      _ignite(monster);
      ship.boilingWakeTurns = tier == 3 ? 3 : 2;
    case OceanPower.tempestSovereign:
      ship.stormRiggingTurns = 2;
      return [
        CombatEffectsChanged.capture(ship),
        ..._addStatic(ship, monster, tier == 3 ? 2 : 1),
      ];
    case OceanPower.brinemother:
      monster.isObscured = false;
      final melt = [8, 14, 22][tier - 1].clamp(0, monster.carapacePlating);
      monster.carapacePlating -= melt;
      _corrode(monster, tier);
      return [
        CarapaceDamaged(
          monsterName: monster.name,
          damageDealt: melt,
          remainingCarapace: monster.carapacePlating,
          wasShattered: melt > 0 && monster.carapacePlating == 0,
        ),
        CombatEffectsChanged.capture(monster),
      ];
    case OceanPower.earthshakerTitan:
      ship.basaltBarrierHp = [15, 25, 35][tier - 1];
      ship.basaltAegisTurns = 2;
  }
  return [
    NarrationEvent('${blessing.title} awakens!'),
    CombatEffectsChanged.capture(ship),
    CombatEffectsChanged.capture(monster),
  ];
}

List<GameEvent> _stormRetaliation(ShipState ship, MonsterState monster) {
  if (ship.stormRiggingTurns <= 0 || !monster.isAlive) return [];
  final tier = ship.blessings[HardpointType.utility]!.tier;
  return [
    ...dealBlessingDamage(
      ship,
      monster,
      [10, 18, 26][tier - 1],
      DamageType.shock,
      source: 'Storm-Arc Rigging',
    ),
    if (monster.isAlive) ..._addStatic(ship, monster, 1),
  ];
}

/// Trigger once for each range band traversed by the monster itself.
List<GameEvent> triggerBoilingWake(ShipState ship, MonsterState monster) {
  if (ship.boilingWakeTurns <= 0) return [];
  final tier = ship.blessings[HardpointType.utility]!.tier;
  return dealBlessingDamage(
    ship,
    monster,
    [12, 20, 30][tier - 1],
    DamageType.fire,
    source: 'Boiling Wake',
  );
}

/// Called after the monster's complete action, including a skipped stun turn.
List<GameEvent> finishOceanPowerTurn(
  ShipState ship,
  MonsterState monster, {
  bool electroJoltWasActiveAtStart = true,
}) {
  if (ship.boilingWakeTurns > 0) ship.boilingWakeTurns--;
  if (ship.stormRiggingTurns > 0) ship.stormRiggingTurns--;
  if (ship.basaltAegisTurns > 0 && --ship.basaltAegisTurns == 0) {
    ship.basaltBarrierHp = 0;
  }
  if (electroJoltWasActiveAtStart) monster.isElectroJolted = false;
  monster.tremorAccPenalty = 0;
  if (monster.corrodedTurns > 0 && --monster.corrodedTurns == 0) {
    monster.corrodedStacks = 0;
  }
  return [
    CombatEffectsChanged.capture(ship),
    CombatEffectsChanged.capture(monster),
  ];
}
