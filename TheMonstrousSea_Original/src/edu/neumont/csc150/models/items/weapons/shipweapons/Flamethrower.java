package edu.neumont.csc150.models.items.weapons.shipweapons;

import edu.neumont.csc150.models.enums.DamageType;
import edu.neumont.csc150.models.enums.RarityLevel;
import edu.neumont.csc150.models.enums.ShipWeaponType;
import edu.neumont.csc150.models.enums.StatusEffect;

public class Flamethrower extends ElementalWeapon{
    private static final String FLAMETHROWER_NAME = "Flamethrower";
    private static final String FLAMETHROWER_DESCRIPTION =  "Fuel. Ignition. A memory of hell wreaks flame upon your enemies";
    private static final DamageType FLAMETHROWER_DAMAGETYPE = DamageType.FIRE;
    private static final StatusEffect FLAMETHROWER_EFFECT = StatusEffect.BURN;
    private static final ShipWeaponType FLAMETHROWER_WEAPON_TYPE = ShipWeaponType.FLAMETHROWER;



    public Flamethrower(RarityLevel rarity, int value, int dmg, int hitMod) {
        super(FLAMETHROWER_NAME, FLAMETHROWER_DESCRIPTION, FLAMETHROWER_DAMAGETYPE, FLAMETHROWER_EFFECT, FLAMETHROWER_WEAPON_TYPE,  rarity,  value,  dmg,  hitMod);
    }
}
