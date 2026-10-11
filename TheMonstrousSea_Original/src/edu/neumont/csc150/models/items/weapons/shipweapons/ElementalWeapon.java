package edu.neumont.csc150.models.items.weapons.shipweapons;

import edu.neumont.csc150.models.enums.DamageType;
import edu.neumont.csc150.models.enums.RarityLevel;
import edu.neumont.csc150.models.enums.ShipWeaponType;
import edu.neumont.csc150.models.enums.StatusEffect;

public abstract class ElementalWeapon extends ShipWeapon{
    private static final int ELEMENTAL_WEAPON_EQUIP_WEIGHT = 3;
    private static final int ELEMENTAL_WEAPON_CHARGE_TIME = 3;

    private StatusEffect effect;

    public StatusEffect getEffect() {
        return effect;
    }

    protected void setEffect(StatusEffect effect) {
        this.effect = effect;
    }


    public ElementalWeapon(String name, String description, DamageType damageType, StatusEffect effect, ShipWeaponType weaponType, RarityLevel rarity, int value, int dmg, int hitMod) {
        super(name, description, damageType, ELEMENTAL_WEAPON_EQUIP_WEIGHT, ELEMENTAL_WEAPON_CHARGE_TIME, weaponType, rarity, value, dmg, hitMod);
        setEffect(effect);
    }
}
