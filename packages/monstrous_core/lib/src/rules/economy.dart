import 'dart:math';

import '../content/consumables.dart';
import '../model/combatant.dart';
import '../model/item.dart';
import '../rng/game_rng.dart';

/// Generates 3-5 Tactical Belt [Consumable] items for the merchant's inventory.
///
/// Each item has:
/// - 50% chance to be at [highestDifficultyReached]
/// - 25% chance to be at `highestDifficultyReached + 1`
/// - 25% chance to be at `max(1, highestDifficultyReached - 1)`
List<Item> generateMerchantStock(
  int highestDifficultyReached,
  GameRng rng,
) {
  final count = rng.nextIntRange(3, 5);
  final stock = <Item>[];

  for (var i = 0; i < count; i++) {
    final levelRoll = rng.nextInt(4);
    final int itemLevel;
    if (levelRoll == 0) {
      itemLevel = highestDifficultyReached + 1;
    } else if (levelRoll == 1 || levelRoll == 2) {
      itemLevel = highestDifficultyReached;
    } else {
      itemLevel = max(1, highestDifficultyReached - 1);
    }

    final item = randomConsumable(itemLevel, rng);
    stock.add(item);
  }

  stock.sort();
  return stock;
}

/// Calculates the merchant's asking price for [item].
///
/// Standard markup is 35% above nominal sell value.
/// If [isOnSale] is true, applies a 25% discount off base value.
int getMerchantBuyPrice(Item item, {bool isOnSale = false}) {
  if (isOnSale) {
    return max(1, (item.value * 0.75).round());
  }
  return max(1, (item.value * 1.35).round());
}

/// Attempts to purchase [item] for [ship] at [price] (defaults to item.value).
///
/// Succeeds if ship has sufficient gold and available cargo hold capacity.
/// Deducts price from gold and adds item to cargo.
bool buyItem(ShipState ship, Item item, {int? price}) {
  final cost = price ?? item.value;
  if (ship.gold < cost) return false;
  if (ship.cargo.length >= ship.maxCargo) return false;

  ship.gold -= cost;
  ship.addCargo(item);
  return true;
}

/// Sells [item] from [ship]'s cargo hold.
///
/// Succeeds if [item] is in cargo. Removes item and credits [item.value] gold.
bool sellItem(ShipState ship, Item item) {
  final removed = ship.removeCargo(item);
  if (!removed) return false;

  ship.gold += item.value;
  return true;
}

/// Sells all [Treasure] items currently stored in [ship]'s cargo hold.
///
/// Removes each treasure, credits total value to [ship.gold], and returns
/// a record of `(totalGoldEarned, itemsSold)`.
(int totalGold, int itemsSold) sellAllTreasure(ShipState ship) {
  final treasures = ship.cargo.whereType<Treasure>().toList();
  if (treasures.isEmpty) return (0, 0);

  var totalGold = 0;
  for (final treasure in treasures) {
    totalGold += treasure.value;
    ship.removeCargo(treasure);
  }

  ship.gold += totalGold;
  return (totalGold, treasures.length);
}

/// Calculates the cost in gold to repair [percentage] (0.0 to 1.0) of [ship]'s max HP.
///
/// Cost is 1g per 1 HP repaired. Repair amount is capped at missing HP.
int calculateRepairCost(ShipState ship, double percentage) {
  if (percentage <= 0) return 0;
  final missingHp = ship.maxHp - ship.currentHp;
  if (missingHp <= 0) return 0;

  final potentialRepair = (ship.maxHp * percentage).toInt();
  final repairedHp = min(potentialRepair, missingHp);
  return max(0, repairedHp);
}

/// Repairs [percentage] of [ship]'s hull at port.
///
/// Deducts the gold cost (1g per HP repaired) and restores hull points.
/// Returns false if no repair is needed or if [ship] cannot afford the cost.
bool repairShip(ShipState ship, double percentage) {
  final cost = calculateRepairCost(ship, percentage);
  if (cost <= 0) return false;
  if (ship.gold < cost) return false;

  ship.gold -= cost;
  ship.heal(cost);
  return true;
}
