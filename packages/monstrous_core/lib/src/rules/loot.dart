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
  bool isApex = false,
]) {
  var dropCount =
      rng.nextIntRange(config.minItemsDropped, config.maxItemsDropped);
  if (isApex) {
    dropCount += 1;
  }
  final items = <Item>[];

  for (var i = 0; i < dropCount; i++) {
    final itemLevel = calculateLootLevel(isApex ? monsterLevel + 1 : monsterLevel, rng);
    items.add(generateLootItem(itemLevel, rng, config));
  }

  items.sort();
  return items;
}

/// Calculates direct gold bounty awarded upon vanquishing a monster of [monsterLevel].
///
/// Scales smoothly across monster levels to support drydock upgrades and merchant purchases:
/// - Level 1: 15–25g
/// - Level 2: 35–55g
/// - Level 3: 75–115g
/// - Level 4: 160–240g
/// - Level 5+: (100 * 1.35^lvl + d50)
/// - Apex monsters award +50% bonus gold.
int calculateVictoryGold(int monsterLevel, GameRng rng, {bool isApex = false}) {
  int baseGold;
  if (monsterLevel <= 1) {
    baseGold = rng.nextIntRange(15, 25);
  } else if (monsterLevel == 2) {
    baseGold = rng.nextIntRange(35, 55);
  } else if (monsterLevel == 3) {
    baseGold = rng.nextIntRange(75, 115);
  } else if (monsterLevel == 4) {
    baseGold = rng.nextIntRange(160, 240);
  } else {
    final base = 100 * pow(1.35, monsterLevel);
    final variance = rng.nextInt(50);
    baseGold = (base + variance).toInt();
  }

  return isApex ? (baseGold * 1.5).round() : baseGold;
}

/// Generates tactical battle spoils consisting strictly of [Consumable]s
/// for the ship's Tactical Belt (no random weapon drops in Phase 3A).
/// Apex predators drop an additional consumable item.
List<Item> generateTacticalVictoryLoot(
  int monsterLevel,
  GameRng rng, [
  int minItems = 1,
  int maxItems = 2,
  bool isApex = false,
]) {
  var dropCount = rng.nextIntRange(minItems, maxItems);
  if (isApex) {
    dropCount += 1;
  }
  final items = <Item>[];

  for (var i = 0; i < dropCount; i++) {
    items.add(randomConsumable(monsterLevel, rng));
  }

  items.sort();
  return items;
}
