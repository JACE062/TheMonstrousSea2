/// Base sealed class for all events emitted by the game engine.
///
/// The UI, audio layer, and combat logger react to these events
/// without needing to inspect low-level game calculations.
sealed class GameEvent {
  const GameEvent();
}

/// A battle encounter has begun.
final class BattleStarted extends GameEvent {
  const BattleStarted({
    required this.monsterName,
    required this.difficulty,
    required this.isBoss,
    required this.monsterHp,
    required this.monsterAc,
  });

  final String monsterName;
  final int difficulty;
  final bool isBoss;
  final int monsterHp;
  final int monsterAc;
}

/// An attack was attempted.
final class AttackAttempted extends GameEvent {
  const AttackAttempted({
    required this.attackerName,
    required this.weaponName,
    required this.roll,
    required this.targetAc,
  });

  final String attackerName;
  final String weaponName;
  final int roll;
  final int targetAc;
}

/// An attack hit and dealt damage.
final class AttackHit extends GameEvent {
  const AttackHit({
    required this.targetName,
    required this.damage,
    required this.damageType,
    required this.remainingHp,
  });

  final String targetName;
  final int damage;
  final String damageType;
  final int remainingHp;
}

/// An attack missed.
final class AttackMissed extends GameEvent {
  const AttackMissed({required this.targetName});
  final String targetName;
}

/// An attack was evaded (Corvette trait).
final class AttackEvaded extends GameEvent {
  const AttackEvaded({required this.shipName, required this.wasManeuver});
  final String shipName;
  final bool wasManeuver;
}

/// Damage was reduced (Ironclad armor trait).
final class DamageReduced extends GameEvent {
  const DamageReduced({required this.shipName, required this.nullifiedAmount});
  final String shipName;
  final int nullifiedAmount;
}

/// Tentacles were severed from a Squid.
final class TentaclesSevered extends GameEvent {
  const TentaclesSevered({required this.countSevered, required this.remainingTentacles});
  final int countSevered;
  final int remainingTentacles;
}

/// An Ink cloud was deployed obscuring the monster.
final class InkCloudDeployed extends GameEvent {
  const InkCloudDeployed({required this.monsterName, required this.acBonus});
  final String monsterName;
  final int acBonus;
}

/// A status effect ticked (e.g. Burn, Poison).
final class StatusEffectTicked extends GameEvent {
  const StatusEffectTicked({
    required this.targetName,
    required this.effectName,
    required this.damage,
    required this.woreOff,
  });

  final String targetName;
  final String effectName;
  final int damage;
  final bool woreOff;
}

/// A combatant was defeated.
final class CombatantDefeated extends GameEvent {
  const CombatantDefeated({required this.name, required this.flavorMessage});
  final String name;
  final String flavorMessage;
}

/// The player fled back to port.
final class FledToPort extends GameEvent {
  const FledToPort({required this.shipName});
  final String shipName;
}

/// Captain died, ending the voyage.
final class CaptainLost extends GameEvent {
  const CaptainLost({
    required this.captainName,
    required this.monstersDefeated,
    required this.highestDifficulty,
  });

  final String captainName;
  final int monstersDefeated;
  final int highestDifficulty;
}
