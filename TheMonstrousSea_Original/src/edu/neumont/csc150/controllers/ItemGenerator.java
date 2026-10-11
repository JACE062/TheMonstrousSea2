package edu.neumont.csc150.controllers;

import edu.neumont.csc150.models.enums.RarityLevel;
import edu.neumont.csc150.models.items.Consumable;
import edu.neumont.csc150.models.items.Item;
import edu.neumont.csc150.models.items.Treasure;
import edu.neumont.csc150.models.items.weapons.monsterweapons.*;
import edu.neumont.csc150.models.items.weapons.shipweapons.*;

import java.util.Random;

public class ItemGenerator {
    private static final int treasureDropChance = 60;
    private static final int consumableDropChance = 20;
    private static final double testingPriceExponentBase = 1.25;
    private static final double testingWeaponExponentBase = 1.25;

    public static Random rand = new Random();


    // generates a item of the level passed, based on the static drop chances for each weapon
    public static Item randomItem(int level) {
        int diceRoll = rand.nextInt(100);
        if (diceRoll <= treasureDropChance) {
            return generateTreasure(level);
        } else if(diceRoll <= (treasureDropChance + consumableDropChance)) {
            return generateConsumable(level);
        } else {
            return generateShipWeapon(level);
        }
    }

    // generates a non-treausre item for the Merchant's shop (since it doesn't make sense for the player to buy them)
    public static Item randomNonTreasureItem(int level) {
        int diceRoll = rand.nextInt(treasureDropChance, 100);
        if(diceRoll <= (treasureDropChance + consumableDropChance)) {
            return generateConsumable(level);
        } else {
            return generateShipWeapon(level);
        }

    }


    public static Treasure generateTreasure(int treasureLevel) {
        return switch (treasureLevel) {
            case 1 -> new Treasure(RarityLevel.COMMON, 10);
            case 2 -> new Treasure(RarityLevel.RARE, 25);
            case 3 -> new Treasure(RarityLevel.EPIC, 75);
            case 4 -> new Treasure(RarityLevel.LEGENDARY, 250);
            default -> new Treasure(RarityLevel.LEGENDARY, 100 * (int) (Math.pow(testingPriceExponentBase, treasureLevel)));
        };
    }

    public static Consumable generateConsumable(int consumableLevel) {
        int consumableTypeIndex = rand.nextInt(3);
        return switch (consumableLevel) {
            case 1 -> new Consumable(RarityLevel.COMMON, 25, consumableTypeIndex);
            case 2 -> new Consumable(RarityLevel.RARE, 50, consumableTypeIndex);
            case 3 -> new Consumable(RarityLevel.EPIC, 75, consumableTypeIndex);
            case 4 -> new Consumable(RarityLevel.LEGENDARY, 100, consumableTypeIndex);
            default -> new Consumable(RarityLevel.LEGENDARY, 150, consumableTypeIndex);
        };
    }

    public static ShipWeapon generateShipWeapon(int weaponLevel) {
        return switch (weaponLevel) {
            case 1 -> randomShipWeaponType(RarityLevel.COMMON, weaponLevel);
            case 2 -> randomShipWeaponType(RarityLevel.RARE, weaponLevel);
            case 3 -> randomShipWeaponType(RarityLevel.EPIC, weaponLevel);
            case 4 -> randomShipWeaponType(RarityLevel.LEGENDARY, weaponLevel);
            default -> randomShipWeaponType(RarityLevel.LEGENDARY, (int) (2 + Math.pow(testingWeaponExponentBase, weaponLevel)));
        };
    }


    public static ShipWeapon randomShipWeaponType(RarityLevel rarityLevel, int multi) {
        int diceRoll = rand.nextInt(5);
        return getShipWeapon(diceRoll, rarityLevel, multi);
    }

    public static ShipWeapon randomShipWeapon(int shipWeaponIndex, RarityLevel rarityLevel, int multi) {
        return getShipWeapon(shipWeaponIndex, rarityLevel, multi);
    }


    // Ship and Monster Weapon Generators, with base values that are multiplied by the item level

    // Hit Mod on every weapon is determined by 2 * its level
    // Cannon base Values  -            Value:20, dmg:8-12,
    // TorpedoLauncher base Values  -   Value:30, dmg:13-17,
    // BladeLauncher base Values  -     Value:30, dmg:13-17,
    // LightningRailgun base Values  -  Value:50, dmg:20-30,
    // Flamethrower base Values  -      Value:50, dmg:20-30,
    public static ShipWeapon getShipWeapon(int shipWeaponIndex, RarityLevel rarityLevel, int multi) {
        return switch (shipWeaponIndex) {
            case 0 -> new Cannon           (rarityLevel, 20 * multi, rand.nextInt(8,13) * multi, 2*multi);
            case 1 -> new TorpedoLauncher  (rarityLevel, 30 * multi, rand.nextInt(13,18) * multi, 2*multi);
            case 2 -> new BladeLauncher    (rarityLevel, 30 * multi, rand.nextInt(13,18) * multi, 2*multi);
            case 3 -> new LightningRailgun (rarityLevel, 50 * multi, rand.nextInt(20,31) * multi, 2*multi);
            case 4 -> new Flamethrower     (rarityLevel, 50 * multi, rand.nextInt(20,31) * multi, 2*multi);
            default -> null;
        };
    }


    // Hit Mod on every weapon is determined by its level
    // Ram base Values  -             dmg:10-14,
    // Jaws base Values  -            dmg:18-22,
    // Tail base Values  -            dmg:22-26,
    // CLaw base Values  -            dmg:10-14,
    // Tentacle base Values  -        dmg:2-4,
    // StingingTendrils base Values - dmg:8-12,
    public static MonsterWeapon generateMonsterWeapon(int monsterWeaponIndex, int rarityIndex, int multi) {
        RarityLevel rarityLevel;
        switch(rarityIndex) {
            case 1 -> rarityLevel = RarityLevel.COMMON;
            case 2 -> rarityLevel = RarityLevel.RARE;
            case 3 -> rarityLevel = RarityLevel.EPIC;
            case 4 -> rarityLevel = RarityLevel.LEGENDARY;
            default -> rarityLevel = RarityLevel.LEGENDARY;
        }

        return switch (monsterWeaponIndex) {
            case 0 -> new Ram              (rarityLevel, rand.nextInt(10,15) * multi, multi);
            case 1 -> new Tail             (rarityLevel, rand.nextInt(18,23) * multi, multi);
            case 2 -> new Jaws             (rarityLevel, rand.nextInt(22,27) * multi, multi);
            case 3 -> new Claw             (rarityLevel, rand.nextInt(10,15) * multi, multi);
            case 4 -> new Tentacle         (rarityLevel, rand.nextInt(2,5) * multi, multi);
            case 5 -> new StingingTendrils (rarityLevel, rand.nextInt(8,13) * multi, multi);
            default -> null;
        };
    }
}
