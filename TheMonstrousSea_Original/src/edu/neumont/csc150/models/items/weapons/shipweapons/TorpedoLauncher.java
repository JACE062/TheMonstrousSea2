package edu.neumont.csc150.models.items.weapons.shipweapons;

import edu.neumont.csc150.models.enums.DamageType;
import edu.neumont.csc150.models.enums.RarityLevel;
import edu.neumont.csc150.models.enums.ShipWeaponType;

public class TorpedoLauncher extends Launcher{
    private static final String TORPEDO_LAUNCHER_NAME = "Torpedo Launcher";
    private static final String TORPEDO_LAUNCHER_DESCRIPTION = "Fires underwater explosives capable of blasting through armor";
    private static final DamageType TORPEDO_LAUNCHER_DAMAGE_TYPE = DamageType.BLAST;
    private static final ShipWeaponType TORPEDO_LAUNCHER_WEAPON_TYPE = ShipWeaponType.TORPEDO_LAUNCHER;


    public TorpedoLauncher(RarityLevel rarity, int value, int dmg, int hitMod) {
        super(TORPEDO_LAUNCHER_NAME, TORPEDO_LAUNCHER_DESCRIPTION, TORPEDO_LAUNCHER_DAMAGE_TYPE, TORPEDO_LAUNCHER_WEAPON_TYPE, rarity, value, dmg, hitMod);
    }
}
