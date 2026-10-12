import '../model/item.dart';

/// Base sealed class for all events emitted by the game engine.
///
/// The UI, audio layer, and combat logger react to these events
/// without needing to inspect low-level game calculations.
sealed class GameEvent {
  const GameEvent();
}

/// The session transitioned to a new game phase.
final class PhaseChanged extends GameEvent {
  const PhaseChanged({required this.previousPhase, required this.newPhase});
  final String previousPhase;
  final String newPhase;
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

/// A monster hesitated or had no available weapons on its turn.
final class MonsterHesitated extends GameEvent {
  const MonsterHesitated([this.monsterName = '']);
  final String monsterName;
}

/// The player fled back to port.
final class FledToPort extends GameEvent {
  const FledToPort({required this.shipName});
  final String shipName;
}

/// The player attempted to flee but was intercepted.
final class FleeFailed extends GameEvent {
  const FleeFailed({required this.shipName});
  final String shipName;
}

/// Victory loot dropped following monster defeat.
final class LootDropped extends GameEvent {
  const LootDropped({required this.items});
  final List<Item> items;
}

/// Item picked up into cargo.
final class ItemAcquired extends GameEvent {
  const ItemAcquired({required this.item});
  final Item item;
}

/// Item sold to merchant.
final class ItemSold extends GameEvent {
  const ItemSold({required this.item, required this.goldEarned});
  final Item item;
  final int goldEarned;
}

/// All treasure sold at port.
final class AllTreasureSold extends GameEvent {
  const AllTreasureSold({required this.totalGold, required this.itemsSold});
  final int totalGold;
  final int itemsSold;
}

/// Ship hull was repaired at port.
final class ShipRepaired extends GameEvent {
  const ShipRepaired({required this.repairedHp, required this.goldCost, required this.newHp});
  final int repairedHp;
  final int goldCost;
  final int newHp;
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

/// A general narration or flavor message.
final class NarrationEvent extends GameEvent {
  const NarrationEvent(this.message);
  final String message;
}
