package edu.neumont.csc150.models.attacksandattackables.seamonsters;

import edu.neumont.csc150.controllers.ItemGenerator;
import edu.neumont.csc150.models.attacksandattackables.AttackResult;
import edu.neumont.csc150.models.attacksandattackables.Attackable;
import edu.neumont.csc150.models.attacksandattackables.ships.Ship;
import edu.neumont.csc150.models.enums.StatusEffect;
import edu.neumont.csc150.models.items.weapons.monsterweapons.MonsterWeapon;
import edu.neumont.csc150.models.items.weapons.shipweapons.ShipWeapon;

import java.util.ArrayList;

public abstract class SeaMonster implements Attackable {
    private String name;
    private int level;
    private int armorClass;
    private int maxHitPoints;
    private int hitPoints;
    protected ArrayList<StatusEffect> currentEffectList = new ArrayList<>();
    protected ArrayList<MonsterWeapon> usableWeapons = new ArrayList<>();

    public static int MIN_ITEMS_DROPPED = 3;
    public static int MAX_ITEMS_DROPPED = 6;

    @Override
    public String getName() {
        return this.name;
    }

    @Override
    public void setName(String name) {
        if(name != null){
            this.name = name;
        }
    }

    @Override
    public int getLevel() {
        return this.level;
    }

    @Override
    public void setLevel(int level) {
        if(level > 0){
            this.level = level;
        }
    }

    @Override
    public int getArmorClass() {
        return this.armorClass;
    }

    @Override
    public void setArmorClass(int armorClass) {
        if(armorClass > 0){
            this.armorClass = armorClass;
        }
    }

    public int getMaxHP() {
        return maxHitPoints;
    }

    public void setMaxHP(int maxHitPoints) {
        this.maxHitPoints = maxHitPoints;
    }

    public int getHitPoints() {
        return hitPoints;
    }

    public void setHitPoints(int hitPoints) {
        if (hitPoints > 0) {
            this.hitPoints = hitPoints;
        } else {
            this.hitPoints = 0;
        }

    }

    @Override
    public int getHP() {
        return this.hitPoints;
    }

    @Override
    public void setHP(int hp) {
        this.hitPoints = Math.max(hp, 0);
    }

    @Override
    public void removeStatusEffectFromList(StatusEffect effect) {
        this.currentEffectList.remove(effect);
    }

    @Override
    public void addStatusEffectToList(StatusEffect effect) {
        if(!this.currentEffectList.contains(effect) && effect != null){
            this.currentEffectList.add(effect);
        }
    }

    @Override
    public ArrayList<StatusEffect> getStatusEffectList() {
        return currentEffectList;
    }

    public ArrayList<MonsterWeapon> getUsableWeapons() {
        return usableWeapons;
    }

    public void decrementChargeTimeOnWeapons() {
        for (MonsterWeapon weapon : getUsableWeapons()) {
            weapon.decrementChargeCountdown();
        }
    }

    public SeaMonster(String name, int level, int armorClass, int hitPoints) {
        setName(name);
        setLevel(level);
        setArmorClass(armorClass);
        setMaxHP(hitPoints);
        setHP(hitPoints);

        // All SeaMonsters get the Ram attack by default, subclass specific attacks are added by subclass constructors
        usableWeapons.add(ItemGenerator.generateMonsterWeapon(0,level, level));
    }

    public abstract String takeMonsterAction(Ship ship);



    // Overrides Attackable's takDamage() to add the death messages to the monsters
    public String takeDamage(AttackResult attackResult) {
        if(attackResult.didAttackHit()) {
            setHP(getHP() - attackResult.getAttackDmg());
            if(getHP() == 0) {
                return "The " + getName() + " takes " + attackResult.getAttackDmg() + " " + attackResult.getAttackType().toString() + " damage" + randomDeathString();
            } else if(attackResult.inflictsEffect()) {
                this.addStatusEffectToList(attackResult.getEffectInflicted());
                return "The " + getName() + " takes " + attackResult.getAttackDmg() + " damage and is " + attackResult.getEffectInflicted().getVerbRepresentation();
            }
            return "The " + getName() + " takes " + attackResult.getAttackDmg() + " " + attackResult.getAttackType().toString() + " damage";
        }
        return "The attack misses The " + getName();
    }

    public String randomDeathString() {
        return switch (Attackable.diceRoll(1,5)) {
            case 1 -> " and is vanquished";
            case 2 -> " and dies";
            case 3 -> " and screams, before falling silent";
            case 4 -> " and falls in pieces into the Sea";
            case 5 -> ", shudders, then collapses";
            default -> " and is le ded";
        };
    }
}
