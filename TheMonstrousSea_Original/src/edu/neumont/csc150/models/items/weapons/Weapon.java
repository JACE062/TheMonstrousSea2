package edu.neumont.csc150.models.items.weapons;

import edu.neumont.csc150.models.enums.DamageType;
import edu.neumont.csc150.models.enums.RarityLevel;
import edu.neumont.csc150.models.items.Item;

public abstract class Weapon extends Item {
    private int damage;
    private int hitModifier;

    private int chargeTime;
    private int chargeCountdown;
    private DamageType damageType;

    // TODO: As an additional touch, later I want to change the way that the weapons work so that they do damage based on the dmg ranges, not just generated based on those, so that a weapon doesn't just always do the same damage each time



    public int getDamage() {
        return damage;
    }

    protected void setDamage(int damage) {
        this.damage = damage;
    }

    public int getHitModifier() {
        return hitModifier;
    }

    protected void setHitModifier(int hitModifier) {
        this.hitModifier = hitModifier;
    }

    public int getChargeTime() {
        return chargeTime;
    }

    protected void setChargeTime(int chargeTime) {
        this.chargeTime = chargeTime;
    }

    public int getChargeCountdown() {
        return chargeCountdown;
    }

    public void setChargeCountdown(int chargeCountdown) {
        this.chargeCountdown = chargeCountdown;
    }

    public void decrementChargeCountdown() {
        if (chargeCountdown > 0) {
            this.chargeCountdown--;
        }
    }

    public DamageType getDamageType() {
        return damageType;
    }

    protected void setDamageType(DamageType damageType) {
        this.damageType = damageType;
    }




    public Weapon(String name, String description, DamageType damageType, int chargeTime, RarityLevel rarity, int value, int damage, int hitMod) {
        super(name, description, value, rarity);

        setDamageType(damageType);
        setChargeTime(chargeTime);

        setDamage(damage);
        setHitModifier(hitMod);
    }


    // String representation of the weapon for displaying
    @Override
    public String fullDetailsString() {
        return super.stringWithDescription() + "\n" +
                Item.whiteSpaceForDisplay + "Damage Type: " + getDamageType() + "\n" +
                Item.whiteSpaceForDisplay + "Damage: " + getDamage() + "\n" +
                Item.whiteSpaceForDisplay + "Hit Mod: +" + getHitModifier() + "\n" +
                Item.whiteSpaceForDisplay + "Reload Time: " + getChargeTime();
    }
}
