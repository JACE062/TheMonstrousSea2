package edu.neumont.csc150.models.items.weapons.monsterweapons;

import edu.neumont.csc150.models.enums.DamageType;
import edu.neumont.csc150.models.enums.RarityLevel;

public class Tail extends MonsterWeapon {
    private static final String TAIL_NAME = "Tail";
    private static final String TAIL_DESCRIPTION = "A huge and powerful tail";
    private static final DamageType TAIL_DAMAGE_TYPE = DamageType.BLUDGEONING;
    private static final int TAIL_CHARGE_TIME = 2;


    public Tail(RarityLevel rarity, int dmg, int hitMod) {
        super(TAIL_NAME, TAIL_DESCRIPTION, TAIL_DAMAGE_TYPE, TAIL_CHARGE_TIME, rarity, dmg, hitMod);
    }

}
