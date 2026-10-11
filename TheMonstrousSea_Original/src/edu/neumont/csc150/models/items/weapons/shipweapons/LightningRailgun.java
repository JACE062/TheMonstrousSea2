package edu.neumont.csc150.models.items.weapons.shipweapons;

import edu.neumont.csc150.models.enums.DamageType;
import edu.neumont.csc150.models.enums.RarityLevel;
import edu.neumont.csc150.models.enums.ShipWeaponType;
import edu.neumont.csc150.models.enums.StatusEffect;

public class LightningRailgun extends ElementalWeapon{
    private static final String LIGHTNING_RAILGUN_NAME = "Lightning Railgun";
    private static final String LIGHTNING_RAILGUN_DESCRIPTION = "Arcs a powerful lightning bolt, zapping a target's nervous system";
    private static final DamageType LIGHTNING_RAILGUN_DAMAGETYPE = DamageType.ELECTRIC;
    private static final StatusEffect LIGHTNING_RAILGUN_EFFECT = StatusEffect.STUN;
    private static final ShipWeaponType LIGHTNING_RAILGUN_WEAPON_TYPE = ShipWeaponType.LIGHTNING_RAILGUN;


    public LightningRailgun(RarityLevel rarity, int value, int dmg, int hitMod) {
        super(LIGHTNING_RAILGUN_NAME, LIGHTNING_RAILGUN_DESCRIPTION, LIGHTNING_RAILGUN_DAMAGETYPE, LIGHTNING_RAILGUN_EFFECT, LIGHTNING_RAILGUN_WEAPON_TYPE,  rarity,  value,  dmg,  hitMod);
    }
}
