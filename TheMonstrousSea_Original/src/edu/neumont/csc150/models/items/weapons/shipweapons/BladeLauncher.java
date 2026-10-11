package edu.neumont.csc150.models.items.weapons.shipweapons;

import edu.neumont.csc150.models.enums.DamageType;
import edu.neumont.csc150.models.enums.RarityLevel;
import edu.neumont.csc150.models.enums.ShipWeaponType;

public class BladeLauncher extends Launcher{
    private static final String BLADE_LAUNCHER_NAME = "Blade Launcher";
    private static final String BLADE_LAUNCHER_DESCRIPTION = "Launches spinning blades with a penchant for removing limbs";
    private static final DamageType BLADE_LAUNCHER_DAMAGE_TYPE = DamageType.SLICING;
    private static final ShipWeaponType BLADE_LAUNCHER_WEAPON_TYPE = ShipWeaponType.BLADE_LAUNCHER;


    public BladeLauncher(RarityLevel rarity, int value, int dmg, int hitMod) {
        super(BLADE_LAUNCHER_NAME, BLADE_LAUNCHER_DESCRIPTION, BLADE_LAUNCHER_DAMAGE_TYPE, BLADE_LAUNCHER_WEAPON_TYPE, rarity, value, dmg, hitMod);
    }
}
