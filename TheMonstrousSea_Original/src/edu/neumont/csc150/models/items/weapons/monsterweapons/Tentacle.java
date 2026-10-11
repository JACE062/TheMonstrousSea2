package edu.neumont.csc150.models.items.weapons.monsterweapons;

import edu.neumont.csc150.models.enums.DamageType;
import edu.neumont.csc150.models.enums.RarityLevel;

public class Tentacle extends MonsterWeapon{
    private static final String TENTACLE_NAME = "Tentacle";
    private static final String TENTACLE_DESCRIPTION = "One tentacle of many, capable of grabbing and slamming alike";
    private static final DamageType TENTACLE_DAMAGE_TYPE = DamageType.BLUDGEONING;
    private static final int TENTACLE_CHARGE_TIME = 0;


    public Tentacle(RarityLevel rarity, int dmg, int hitMod) {
        super(TENTACLE_NAME, TENTACLE_DESCRIPTION, TENTACLE_DAMAGE_TYPE, TENTACLE_CHARGE_TIME, rarity, dmg, hitMod);
    }
}
