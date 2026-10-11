package edu.neumont.csc150.models.items.weapons.monsterweapons;

import edu.neumont.csc150.models.enums.DamageType;
import edu.neumont.csc150.models.enums.RarityLevel;

public class Claw extends MonsterWeapon {
    private static final String CLAW_NAME = "Claw";
    private static final String CLAW_DESCRIPTION = "A mighty claw";
    private static final DamageType CLAW_DAMAGE_TYPE = DamageType.CRUSHING;
    private static final int CLAW_CHARGE_TIME = 0;


    public Claw(RarityLevel rarity , int dmg, int hitMod) {
        super(CLAW_NAME, CLAW_DESCRIPTION, CLAW_DAMAGE_TYPE, CLAW_CHARGE_TIME, rarity, dmg, hitMod);
    }
}
