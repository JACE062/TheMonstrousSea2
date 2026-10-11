package edu.neumont.csc150.models.attacksandattackables;

import edu.neumont.csc150.models.enums.DamageType;
import edu.neumont.csc150.models.enums.StatusEffect;
import edu.neumont.csc150.models.items.weapons.shipweapons.ElementalWeapon;
import edu.neumont.csc150.models.items.weapons.Weapon;

import java.util.ArrayList;
import java.util.Random;

public interface Attackable {
    String getName();
    void setName(String name);
    int getLevel();
    void setLevel(int progressionMulti);
    int getArmorClass();
    void setArmorClass(int armorClass);
    int getMaxHP();
    void setMaxHP(int maxHP);
    int getHP();
    void setHP(int hp);
    void removeStatusEffectFromList(StatusEffect effect);
    void addStatusEffectToList(StatusEffect effect);
    ArrayList<StatusEffect> getStatusEffectList();


    // Base attack implementation for Attackables, takes a weapon and a target and rolls dice to determine if it hits
    // Returns an AttackResult with the details of the attack
    default AttackResult attack(Attackable target, Weapon weapon) {
        boolean attackHit = false;
        int attackDmg = 0;
        DamageType attackType = weapon.getDamageType();
        StatusEffect effect;
        String attackString = "The " + getName() + " attacks with " + weapon.getName();

        if((Attackable.diceRoll(1,20) + weapon.getHitModifier()) >= target.getArmorClass()) {
            attackHit = true;
            attackDmg = weapon.getDamage();
            if(weapon instanceof ElementalWeapon) {
                effect = ((ElementalWeapon) weapon).getEffect();
                return new AttackResult(attackString, attackHit, attackDmg, attackType, effect);
            }
        }

        return new AttackResult(attackString, attackHit, attackDmg, attackType);
    }

    // Base implementation for taking damage for Attackables, takes in attackresult and returns a string representation of the Attackable taking damage
    default String takeDamage(AttackResult attackResult) {
        if(attackResult.didAttackHit()) {
            setHP(getHP() - attackResult.getAttackDmg());
            if(attackResult.inflictsEffect()) {
                this.addStatusEffectToList(attackResult.getEffectInflicted());
                return "The " + getName() + " takes " + attackResult.getAttackDmg() + " damage and is " + attackResult.getEffectInflicted().getVerbRepresentation();
            }
            return "The " + getName() + " takes " + attackResult.getAttackDmg() + " " + attackResult.getAttackType().toString() + " damage";
        }
        return "The attack misses The " + getName();
    }

    // Simple dice roll used for attacking, random chances for items, all sorts of stuff
    Random rand = new Random();
    static int diceRoll(int numDice, int numberOfSidesOnDie) {
        int rollTotal = 0;
        for ( int i = 0; i < numDice; i++ ) {
            rollTotal += rand.nextInt(numberOfSidesOnDie) + 1;
        }
        return rollTotal;
    }



}
