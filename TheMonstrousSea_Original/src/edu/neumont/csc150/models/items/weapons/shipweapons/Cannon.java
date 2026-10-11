package edu.neumont.csc150.models.items.weapons.shipweapons;

import edu.neumont.csc150.models.enums.DamageType;
import edu.neumont.csc150.models.enums.RarityLevel;
import edu.neumont.csc150.models.enums.ShipWeaponType;

public class Cannon extends ShipWeapon{
    private static final String CANNON_NAME = "Cannon";
    private static final String CANNON_DESCRIPTION = "A simple, lead-firing cannon";
    private static final DamageType CANNON_DAMAGE_TYPE = DamageType.BLUDGEONING;
    private static final int CANNON_EQUIP_WEIGHT = 1;
    private static final int CANNON_CHARGE_TIME = 0;
    private static final ShipWeaponType CANNON_WEAPON_TYPE = ShipWeaponType.CANNON;


    public Cannon(RarityLevel rarity, int value, int dmg, int hitMod) {
        super(CANNON_NAME, CANNON_DESCRIPTION, CANNON_DAMAGE_TYPE, CANNON_EQUIP_WEIGHT, CANNON_CHARGE_TIME, CANNON_WEAPON_TYPE, rarity, value, dmg, hitMod);
    }

}
