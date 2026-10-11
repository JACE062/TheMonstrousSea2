package edu.neumont.csc150.models.enums;

public enum ShipWeaponType {
    CANNON("Cannon", 0),
    BLADE_LAUNCHER ("Blade Launcher", 2),
    TORPEDO_LAUNCHER ("Torpedo Launcher", 2),
    LIGHTNING_RAILGUN ("Lightning Railgun", 3),
    FLAMETHROWER ("Flamethrower", 3);

    private final String prettyString;
    private final int chargeTime;

    ShipWeaponType(String prettyString, int chargeTime) {
        this.prettyString = prettyString;
        this.chargeTime = chargeTime;
    }

    @Override
    public String toString() {
        return prettyString;
    }

    public int getChargeTime() {
        return chargeTime;
    }
}
