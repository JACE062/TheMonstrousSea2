package edu.neumont.csc150.models.items.weapons.monsterweapons;

import edu.neumont.csc150.models.enums.DamageType;
import edu.neumont.csc150.models.enums.RarityLevel;

public class StingingTendrils extends MonsterWeapon{
    private static final String STINGING_TENDRIL_NAME = "Stinging Tendrils";
    private static final String STINGING_TENDRIL_DESCRIPTION = "Tendrils filled with venom strong enough to eat away at ships";
    private static final DamageType STINGING_TENDRIL_DAMAGE_TYPE = DamageType.VENOM;
    private static final int STINGING_TENDRIL_CHARGE_TIME = 2;


    public StingingTendrils(RarityLevel rarity, int dmg, int hitMod) {
        super(STINGING_TENDRIL_NAME, STINGING_TENDRIL_DESCRIPTION, STINGING_TENDRIL_DAMAGE_TYPE, STINGING_TENDRIL_CHARGE_TIME, rarity, dmg, hitMod);
    }
}
