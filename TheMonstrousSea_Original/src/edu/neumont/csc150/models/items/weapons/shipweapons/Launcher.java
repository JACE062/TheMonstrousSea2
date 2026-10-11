package edu.neumont.csc150.models.items.weapons.shipweapons;

import edu.neumont.csc150.models.enums.DamageType;
import edu.neumont.csc150.models.enums.RarityLevel;
import edu.neumont.csc150.models.enums.ShipWeaponType;

public abstract class Launcher extends ShipWeapon{
    private static final int LAUNCHER_EQUIP_WEIGHT = 2;
    private static final int LAUNCHER_CHARGE_TIME = 2;

    public Launcher(String name, String description, DamageType damageType, ShipWeaponType weaponType, RarityLevel rarity, int value, int dmg, int hitMod) {
        super(name, description, damageType, LAUNCHER_EQUIP_WEIGHT, LAUNCHER_CHARGE_TIME, weaponType, rarity, value, dmg, hitMod);
    }


}
