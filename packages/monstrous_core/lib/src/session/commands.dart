import '../model/enums.dart';

/// Base sealed class for all user or bot intents sent into the game engine.
sealed class Command {
  const Command();
}

/// Sets the initial captain name or heir name.
final class NameCaptain extends Command {
  const NameCaptain(this.name);
  final String name;
}

/// Chooses a starting ship by class.
final class ChooseShip extends Command {
  const ChooseShip(this.shipClass, {this.customName});
  final ShipClass shipClass;
  final String? customName;
}

/// Fires all weapons of the specified type in a volley.
final class FireWeaponVolley extends Command {
  const FireWeaponVolley(this.weaponType);
  final ShipWeaponType weaponType;
}

/// Uses a consumable item from cargo by index.
final class UseConsumableItem extends Command {
  const UseConsumableItem(this.cargoIndex);
  final int cargoIndex;
}

/// Attempts to flee from the active encounter back to port.
final class FleeEncounter extends Command {
  const FleeEncounter();
}

/// Executes the ship's active class action (Fortify, Evasive Maneuvers).
final class ExecuteShipSpecialAction extends Command {
  const ExecuteShipSpecialAction();
}

/// Takes a single loot item by index from pending victory loot.
final class TakeLootItem extends Command {
  const TakeLootItem(this.lootIndex);
  final int lootIndex;
}

/// Takes all pending victory loot items that fit into cargo.
final class TakeAllLoot extends Command {
  const TakeAllLoot();
}

/// Leaves all remaining pending victory loot behind.
final class LeaveRemainingLoot extends Command {
  const LeaveRemainingLoot();
}

/// Jettisons an item from cargo to make room.
final class DropCargoItem extends Command {
  const DropCargoItem(this.cargoIndex);
  final int cargoIndex;
}

/// Equips a weapon from cargo.
final class EquipCargoWeapon extends Command {
  const EquipCargoWeapon(this.cargoIndex);
  final int cargoIndex;
}

/// Unequips an equipped weapon back into cargo hold.
final class UnequipShipWeapon extends Command {
  const UnequipShipWeapon(this.equippedIndex);
  final int equippedIndex;
}

/// Advances from rest area or port into the next battle.
final class AdvanceToNextBattle extends Command {
  const AdvanceToNextBattle();
}

/// Leaves port to venture out onto the open sea (starting at [0][0]).
final class VentureOutToSea extends Command {
  const VentureOutToSea();
}

/// Enters the merchant shop in port.
final class VisitMerchant extends Command {
  const VisitMerchant();
}

/// Leaves the merchant shop back to port hub.
final class LeaveMerchant extends Command {
  const LeaveMerchant();
}

/// Purchases an item from the merchant by index in merchant stock.
final class BuyMerchantItem extends Command {
  const BuyMerchantItem(this.stockIndex);
  final int stockIndex;
}

/// Sells a cargo item to the merchant by index in cargo hold.
final class SellCargoItem extends Command {
  const SellCargoItem(this.cargoIndex);
  final int cargoIndex;
}

/// Sells all treasure in cargo for gold.
final class SellAllTreasure extends Command {
  const SellAllTreasure();
}

/// Repairs hull at port.
final class RepairShip extends Command {
  const RepairShip(this.percentage);
  final double percentage;
}

/// Returns to home port from the rest area.
final class ReturnToPort extends Command {
  const ReturnToPort();
}

/// Continues the hunt after death with an heir.
final class ContinueLineage extends Command {
  const ContinueLineage(this.heirName, this.chosenClass);
  final String heirName;
  final ShipClass chosenClass;
}

/// Ends the hunt lineage completely.
final class AbandonHunt extends Command {
  const AbandonHunt();
}
