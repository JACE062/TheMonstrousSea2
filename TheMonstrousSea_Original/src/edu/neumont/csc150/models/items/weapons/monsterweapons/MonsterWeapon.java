package edu.neumont.csc150.models.items.weapons.monsterweapons;


import edu.neumont.csc150.models.enums.DamageType;
import edu.neumont.csc150.models.enums.RarityLevel;
import edu.neumont.csc150.models.items.weapons.Weapon;

public class MonsterWeapon extends Weapon {
    private static final int DEFAULT_MONSTER_WEAPON_VALUE = 0;

    // Monster weapons don't need a value, so they are always set to zero
    public MonsterWeapon(String name, String description, DamageType damageType, int chargeTime, RarityLevel rarity, int dmg, int hitMod) {
        super(name, description, damageType, chargeTime, rarity, DEFAULT_MONSTER_WEAPON_VALUE, dmg, hitMod);
    }
}
