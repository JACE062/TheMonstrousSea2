package edu.neumont.csc150.models.items.weapons.shipweapons;

import edu.neumont.csc150.models.enums.DamageType;
import edu.neumont.csc150.models.enums.RarityLevel;
import edu.neumont.csc150.models.enums.ShipWeaponType;
import edu.neumont.csc150.models.items.Item;
import edu.neumont.csc150.models.items.weapons.Weapon;

public abstract class ShipWeapon extends Weapon {
    private int equipWeight;
    private ShipWeaponType weaponType;


    public int getEquipWeight() {
        return equipWeight;
    }

    protected void setEquipWeight(int equipWeight) {
        this.equipWeight = equipWeight;
    }

    public ShipWeaponType getWeaponType() {
        return weaponType;
    }

    private void setWeaponType(ShipWeaponType weaponType) {
        this.weaponType = weaponType;
    }


    public ShipWeapon(String name, String description, DamageType damageType, int equipWeight, int chargeTime, ShipWeaponType weaponType, RarityLevel rarity, int value, int dmg, int hitMod) {
        super(name, description, damageType, chargeTime, rarity, value, dmg, hitMod);
        setEquipWeight(equipWeight);
        setWeaponType(weaponType);
    }

    @Override
    public String fullDetailsString() {
        return super.fullDetailsString() + "\n" + Item.whiteSpaceForDisplay + "Equip Weight: " + equipWeight;
    }
}

