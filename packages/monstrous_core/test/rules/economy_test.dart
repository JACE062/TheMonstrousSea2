import 'package:monstrous_core/monstrous_core.dart';
import 'package:test/test.dart';

void main() {
  group('Merchant Stock Generation', () {
    test('generates between 3 and 5 non-treasure items', () {
      final rng = SeededGameRng(42);

      for (var highestDiff = 1; highestDiff <= 6; highestDiff++) {
        for (var i = 0; i < 50; i++) {
          final stock = generateMerchantStock(highestDiff, rng);
          expect(stock.length, inInclusiveRange(3, 5));
          for (final item in stock) {
            expect(item, isNot(isA<Treasure>()));
            expect(item is Consumable || item is ShipWeapon, isTrue);
          }
        }
      }
    });

    test('consumable stock has fixed price and use count at every difficulty', () {
      final rng = SeededGameRng(99);

      // Difficulty does not introduce consumable tiers.
      final stock1 = generateMerchantStock(1, rng);
      for (final item in stock1) {
        if (item is Consumable) {
          expect(item.rarity, RarityLevel.common);
          expect(item.value, 25);
          expect(item.maxUses, 1);
        } else if (item is ShipWeapon) {
          expect(item.rarity.level, inInclusiveRange(1, 2));
        }
      }

      // Later voyages stock the same single-use items.
      final stock3 = generateMerchantStock(3, rng);
      for (final item in stock3) {
        if (item is Consumable) {
          expect(item.rarity, RarityLevel.common);
          expect(item.value, 25);
          expect(item.maxUses, 1);
        } else if (item is ShipWeapon) {
          expect(item.rarity.level, inInclusiveRange(2, 4));
        }
      }
    });
  });

  group('Merchant Buying & Selling', () {
    test('buyItem fails when cargo hold is full', () {
      final ship = ShipState(
        id: 'ship_1',
        name: 'Test Ship',
        level: 1,
        maxHp: 100,
        armorClass: 10,
        shipClass: ShipClass.standard,
        maxCargo: 2,
        maxWeaponWeight: 10,
        gold: 500,
      );

      final t1 = generateTreasure(1);
      final t2 = generateTreasure(1);
      final itemToBuy = generateTreasure(1);

      ship.addCargo(t1);
      ship.addCargo(t2);
      expect(ship.cargo.length, 2);

      final success = buyItem(ship, itemToBuy);
      expect(success, isFalse);
      expect(ship.gold, 500);
      expect(ship.cargo.length, 2);
    });

    test('buyItem fails when ship has insufficient gold', () {
      final ship = ShipState(
        id: 'ship_1',
        name: 'Test Ship',
        level: 1,
        maxHp: 100,
        armorClass: 10,
        shipClass: ShipClass.standard,
        maxCargo: 5,
        maxWeaponWeight: 10,
        gold: 15,
      );

      // Every single-use item costs 25g before merchant markup.
      final itemToBuy = generateConsumable(ConsumableType.blastPack, RarityLevel.rare);
      expect(itemToBuy.value, 25);

      final success = buyItem(ship, itemToBuy);
      expect(success, isFalse);
      expect(ship.gold, 15);
      expect(ship.cargo, isEmpty);
    });

    test('buyItem succeeds when sufficient gold and space exist', () {
      final ship = ShipState(
        id: 'ship_1',
        name: 'Test Ship',
        level: 1,
        maxHp: 100,
        armorClass: 10,
        shipClass: ShipClass.standard,
        maxCargo: 5,
        maxWeaponWeight: 10,
        gold: 100,
      );

      final itemToBuy = generateConsumable(ConsumableType.blastPack, RarityLevel.common);
      expect(itemToBuy.value, 25);

      final success = buyItem(ship, itemToBuy);
      expect(success, isTrue);
      expect(ship.gold, 75);
      expect(ship.cargo, contains(itemToBuy));
    });

    test('sellItem fails if item is not in cargo', () {
      final ship = ShipState(
        id: 'ship_1',
        name: 'Test Ship',
        level: 1,
        maxHp: 100,
        armorClass: 10,
        shipClass: ShipClass.standard,
        maxCargo: 5,
        maxWeaponWeight: 10,
        gold: 50,
      );

      final unownedItem = generateTreasure(2);

      final success = sellItem(ship, unownedItem);
      expect(success, isFalse);
      expect(ship.gold, 50);
    });

    test('sellItem removes item and credits gold', () {
      final ship = ShipState(
        id: 'ship_1',
        name: 'Test Ship',
        level: 1,
        maxHp: 100,
        armorClass: 10,
        shipClass: ShipClass.standard,
        maxCargo: 5,
        maxWeaponWeight: 10,
        gold: 50,
      );

      final item = generateTreasure(2); // value: 25g
      ship.addCargo(item);

      final success = sellItem(ship, item);
      expect(success, isTrue);
      expect(ship.gold, 75);
      expect(ship.cargo, isNot(contains(item)));
    });
  });

  group('Sell All Treasure', () {
    test('returns (0, 0) and changes nothing when cargo contains no treasures', () {
      final ship = ShipState(
        id: 'ship_1',
        name: 'Test Ship',
        level: 1,
        maxHp: 100,
        armorClass: 10,
        shipClass: ShipClass.standard,
        maxCargo: 5,
        maxWeaponWeight: 10,
        gold: 100,
      );

      final consumable = generateConsumable(ConsumableType.chakram, RarityLevel.common);
      ship.addCargo(consumable);

      final (totalGold, itemsSold) = sellAllTreasure(ship);
      expect(totalGold, 0);
      expect(itemsSold, 0);
      expect(ship.gold, 100);
      expect(ship.cargo, contains(consumable));
    });

    test('removes all treasures and adds their combined value to ship gold', () {
      final ship = ShipState(
        id: 'ship_1',
        name: 'Test Ship',
        level: 1,
        maxHp: 100,
        armorClass: 10,
        shipClass: ShipClass.standard,
        maxCargo: 10,
        maxWeaponWeight: 10,
        gold: 20,
      );

      final t1 = generateTreasure(1); // 10g
      final t2 = generateTreasure(2); // 25g
      final t3 = generateTreasure(3); // 75g
      final weapon = randomShipWeapon(1, SeededGameRng(1));

      ship.addCargo(t1);
      ship.addCargo(t2);
      ship.addCargo(t3);
      ship.addCargo(weapon);

      final (totalGold, itemsSold) = sellAllTreasure(ship);

      expect(totalGold, 110);
      expect(itemsSold, 3);
      expect(ship.gold, 130);
      expect(ship.cargo, [weapon]);
    });
  });

  group('Ship Repairs at Port', () {
    test('calculateRepairCost is 1g per HP repaired and does not exceed missing HP', () {
      final ship = ShipState(
        id: 'ship_1',
        name: 'Test Ship',
        level: 1,
        maxHp: 100,
        currentHp: 85, // Missing 15 HP
        armorClass: 10,
        shipClass: ShipClass.standard,
        maxCargo: 5,
        maxWeaponWeight: 10,
      );

      // 10% of 100 is 10 HP <= 15 missing -> 10g
      expect(calculateRepairCost(ship, 0.10), 10);

      // 25% of 100 is 25 HP > 15 missing -> capped at 15g
      expect(calculateRepairCost(ship, 0.25), 15);

      // 50% of 100 is 50 HP > 15 missing -> capped at 15g
      expect(calculateRepairCost(ship, 0.50), 15);

      // 100% of 100 is 100 HP > 15 missing -> capped at 15g
      expect(calculateRepairCost(ship, 1.00), 15);

      // Fully healthy ship: cost is 0
      ship.currentHp = 100;
      expect(calculateRepairCost(ship, 0.50), 0);
    });

    test('repairShip fails when ship has full health', () {
      final ship = ShipState(
        id: 'ship_1',
        name: 'Test Ship',
        level: 1,
        maxHp: 100,
        currentHp: 100,
        armorClass: 10,
        shipClass: ShipClass.standard,
        maxCargo: 5,
        maxWeaponWeight: 10,
        gold: 100,
      );

      final repaired = repairShip(ship, 0.25);
      expect(repaired, isFalse);
      expect(ship.gold, 100);
      expect(ship.currentHp, 100);
    });

    test('repairShip fails when ship cannot afford the repair cost', () {
      final ship = ShipState(
        id: 'ship_1',
        name: 'Test Ship',
        level: 1,
        maxHp: 100,
        currentHp: 60, // Missing 40 HP
        armorClass: 10,
        shipClass: ShipClass.standard,
        maxCargo: 5,
        maxWeaponWeight: 10,
        gold: 10, // Cost for 25% is 25g
      );

      final repaired = repairShip(ship, 0.25);
      expect(repaired, isFalse);
      expect(ship.gold, 10);
      expect(ship.currentHp, 60);
    });

    test('repairShip deducts gold and heals hull by exact cost', () {
      final ship = ShipState(
        id: 'ship_1',
        name: 'Test Ship',
        level: 1,
        maxHp: 100,
        currentHp: 60, // Missing 40 HP
        armorClass: 10,
        shipClass: ShipClass.standard,
        maxCargo: 5,
        maxWeaponWeight: 10,
        gold: 50,
      );

      // Repair 25% (25 HP for 25g)
      final repaired = repairShip(ship, 0.25);
      expect(repaired, isTrue);
      expect(ship.gold, 25);
      expect(ship.currentHp, 85);

      // Repair remaining missing HP (15 HP for 15g) via 50%
      final repairedRemaining = repairShip(ship, 0.50);
      expect(repairedRemaining, isTrue);
      expect(ship.gold, 10);
      expect(ship.currentHp, 100);
    });

    test('getMerchantBuyPrice applies 35% markup by default and 25% discount when on sale', () {
      final item = generateConsumable(ConsumableType.blastPack, RarityLevel.common);
      final regularPrice = getMerchantBuyPrice(item);
      expect(regularPrice, (item.value * 1.35).round());

      final salePrice = getMerchantBuyPrice(item, isOnSale: true);
      expect(salePrice, (item.value * 0.75).round());
    });
  });
}
