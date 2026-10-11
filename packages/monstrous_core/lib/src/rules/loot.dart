import 'dart:math';

import '../config/balance_config.dart';
import '../content/consumables.dart';
import '../content/ship_weapons.dart';
import '../model/enums.dart';
import '../model/item.dart';
import '../rng/game_rng.dart';

int _treasureIdCounter = 0;

/// Calculates the level of a dropped loot item relative to [monsterLevel].
///
/// Distribution probabilities match original game design:
/// - <= 15%: max(1, monsterLevel - 3)
/// - <= 30%: max(1, monsterLevel - 2)
/// - <= 50%: max(1, monsterLevel - 1)
/// - <= 80%: monsterLevel
/// - <= 95%: monsterLevel + 1
/// - <= 99%: monsterLevel + 2
/// - > 99%: monsterLevel + 3
int calculateLootLevel(int monsterLevel, GameRng rng) {
  final roll = rng.d100();
  if (roll <= 15) return max(1, monsterLevel - 3);
  if (roll <= 30) return max(1, monsterLevel - 2);
  if (roll <= 50) return max(1, monsterLevel - 1);
  if (roll <= 80) return monsterLevel;
  if (roll <= 95) return monsterLevel + 1;
  if (roll <= 99) return monsterLevel + 2;
  return monsterLevel + 3;
}

/// Generates a [Treasure] item with value and rarity scaled to [level].
///
/// Formulas:
/// - Level 1: Common, 10g
/// - Level 2: Rare, 25g
/// - Level 3: Epic, 75g
/// - Level 4: Legendary, 250g
/// - Level > 4: Legendary, `100 * (1.25^level).toInt()`
Treasure generateTreasure(
  int level, {
  BalanceConfig config = BalanceConfig.standard,
  String? id,
}) {
  final treasureId = id ?? 'treasure_${++_treasureIdCounter}';
  final RarityLevel rarity;
  final int value;

  if (level <= 1) {
    rarity = RarityLevel.common;
    value = 10;
  } else if (level == 2) {
    rarity = RarityLevel.rare;
    value = 25;
  } else if (level == 3) {
    rarity = RarityLevel.epic;
    value = 75;
  } else if (level == 4) {
    rarity = RarityLevel.legendary;
    value = 250;
  } else {
    rarity = RarityLevel.legendary;
    value = 100 * pow(config.testingPriceExponentBase, level).toInt();
  }

  return Treasure(
    id: treasureId,
    name: 'Treasure',
    description: 'An item of some value once lost to the sea',
    value: value,
    rarity: rarity,
  );
}

/// Generates a single random item at [itemLevel] following category drop odds.
///
/// Fixes Bug B4:
/// Strict 60/20/20 range partitions:
/// - [0..59] (60%): Treasure
/// - [60..79] (20%): Consumable
/// - [80..99] (20%): ShipWeapon
Item generateLootItem(
  int itemLevel,
  GameRng rng, [
  BalanceConfig config = BalanceConfig.standard,
]) {
  final categoryRoll = rng.nextInt(100);
  if (categoryRoll < config.treasureDropWeight) {
    return generateTreasure(itemLevel, config: config);
  } else if (categoryRoll <
      config.treasureDropWeight + config.consumableDropWeight) {
    return randomConsumable(itemLevel, rng);
  } else {
    return randomShipWeapon(itemLevel, rng);
  }
}

/// Generates the list of loot items dropped upon defeating a monster.
///
/// Fixes Bug B1:
/// Evaluates total drop count ONCE before iterating:
/// `rng.nextIntRange(config.minItemsDropped, config.maxItemsDropped)`
///
/// Items are sorted by [Item.compareTo] before returning.
List<Item> generateVictoryLoot(
  int monsterLevel,
  GameRng rng, [
  BalanceConfig config = BalanceConfig.standard,
]) {
  final dropCount =
      rng.nextIntRange(config.minItemsDropped, config.maxItemsDropped);
  final items = <Item>[];

  for (var i = 0; i < dropCount; i++) {
    final itemLevel = calculateLootLevel(monsterLevel, rng);
    items.add(generateLootItem(itemLevel, rng, config));
  }

  items.sort();
  return items;
}
