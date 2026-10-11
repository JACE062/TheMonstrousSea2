package edu.neumont.csc150.models.items.weapons.monsterweapons;

import edu.neumont.csc150.models.enums.DamageType;
import edu.neumont.csc150.models.enums.RarityLevel;

public class Ram extends MonsterWeapon{
    private static final String RAM_NAME = "Ram";
    private static final String RAM_DESCRIPTION = "The huge body of the creature is weapon enough";
    private static final DamageType RAM_DAMAGE_TYPE = DamageType.RAMMING;
    private static final int RAM_CHARGE_TIME = 0;


    public Ram(RarityLevel rarity, int dmg, int hitMod) {
        super (RAM_NAME, RAM_DESCRIPTION, RAM_DAMAGE_TYPE, RAM_CHARGE_TIME, rarity, dmg, hitMod);
    }

}
