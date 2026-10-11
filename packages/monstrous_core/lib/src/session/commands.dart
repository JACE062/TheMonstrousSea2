/// Base sealed class for all user or bot intents sent into the game engine.
sealed class Command {
  const Command();
}

/// Sets the initial captain name or heir name.
final class NameCaptain extends Command {
  const NameCaptain(this.name);
  final String name;
}

/// Chooses a starting ship by class index.
final class ChooseShip extends Command {
  const ChooseShip(this.shipIndex);
  final int shipIndex;
}

/// Fires all weapons of the specified type in a volley.
final class FireWeaponVolley extends Command {
  const FireWeaponVolley(this.weaponTypeName);
  final String weaponTypeName;
}

/// Uses a consumable item by ID from cargo.
final class UseConsumable extends Command {
  const UseConsumable(this.itemId);
  final String itemId;
}

/// Attempts to flee from the active encounter back to port.
final class FleeEncounter extends Command {
  const FleeEncounter();
}

/// Executes the ship's active class action (Fortify, Evasive Maneuvers).
final class ExecuteShipSpecialAction extends Command {
  const ExecuteShipSpecialAction();
}

/// Advances from rest area or port into the next battle.
final class AdvanceToNextBattle extends Command {
  const AdvanceToNextBattle();
}

/// Returns to home port from the rest area.
final class ReturnToPort extends Command {
  const ReturnToPort();
}

/// Repairs hull at port.
final class RepairShip extends Command {
  const RepairShip(this.percentage);
  final double percentage;
}

/// Sells all treasure in cargo for gold.
final class SellAllTreasure extends Command {
  const SellAllTreasure();
}

/// Continues the hunt after death with an heir.
final class ContinueLineage extends Command {
  const ContinueLineage(this.heirName);
  final String heirName;
}

/// Ends the hunt lineage completely.
final class AbandonHunt extends Command {
  const AbandonHunt();
}
