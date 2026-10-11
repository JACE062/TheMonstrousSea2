package edu.neumont.csc150.models.items.weapons.monsterweapons;

import edu.neumont.csc150.models.enums.DamageType;
import edu.neumont.csc150.models.enums.RarityLevel;

public class Jaws extends MonsterWeapon{
    private static final String JAWS_NAME = "Jaws";
    private static final String JAWS_DESCRIPTION = "A set of Jaws lined with razor-sharp teeth";
    private static final DamageType JAWS_DAMAGE_TYPE = DamageType.BITING;
    private static final int JAWS_CHARGE_TIME = 0;


    public Jaws( RarityLevel rarity, int dmg, int hitMod) {
        super(JAWS_NAME, JAWS_DESCRIPTION, JAWS_DAMAGE_TYPE, JAWS_CHARGE_TIME, rarity, dmg, hitMod);
    }
}
