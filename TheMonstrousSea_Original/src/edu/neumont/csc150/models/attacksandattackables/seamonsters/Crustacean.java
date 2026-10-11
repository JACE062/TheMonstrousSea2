package edu.neumont.csc150.models.attacksandattackables.seamonsters;

import edu.neumont.csc150.controllers.ItemGenerator;
import edu.neumont.csc150.models.attacksandattackables.AttackResult;
import edu.neumont.csc150.models.attacksandattackables.Attackable;
import edu.neumont.csc150.models.attacksandattackables.ships.Ship;
import edu.neumont.csc150.models.enums.DamageType;

public class Crustacean extends SeaMonster{
    private static final String[] POSSIBLE_CRUSTACEAN_NAMES = {"Colossal Lobster", "Island-Shell Crab", "Radioactive Isopod", "Living Fortress", "Adamantine-Carapace Titan", "Chitinous Colossus", "Stoneclaw Leviathan", "Aegis-Lobster", "Shellbound Menace", "Abyssal Scuttler", "Terrorclaw", "Unbreakable One", "Mutant Shellback", "Hulking Razorclaw"};
    private int armorPlating;
    private int blastArmorReductionMod;

    public int getArmorPlating() {
        return armorPlating;
    }

    private void setArmorPlating(int armorPlating) {
        if (armorPlating > 0) {
            this.armorPlating = armorPlating;
        } else {
            this.armorPlating = 0;
        }
    }

    public int getBlastArmorReductionMod() {
        return blastArmorReductionMod;
    }

    private void setBlastArmorReductionMod(int blastArmorReductionMod) {
        this.blastArmorReductionMod = blastArmorReductionMod;
    }

    // Constructor for random Crustaceans based on level
    // Base stats of Crustacean: name: random from possibleCrustaceanNames, armorClass: 6 (+ 3 per level), hitPoints: 80 (+ 80 per level)
    // armorPlating starts at 15, increasing by 15 per level
    // blastArmorReductionMod starts at a base of 5, increasing by 5 per level
    public Crustacean(int level) {
        super(POSSIBLE_CRUSTACEAN_NAMES[ItemGenerator.rand.nextInt(POSSIBLE_CRUSTACEAN_NAMES.length)], level, 3 + 3*level, 80 * level);
        setArmorPlating(15*level);
        setBlastArmorReductionMod(5*level);
    }



    // Constructor for hard coded Crustaceans (for potential hard-coded boss)
    public Crustacean(String name, int level, int armorClass, int hitPoints, int armorPlating, int blastArmorReductionMod) {
        super(name, level, armorClass, hitPoints);
        setArmorPlating(armorPlating);
        setBlastArmorReductionMod(blastArmorReductionMod);

        // Crustaceans also get a Claw attack
        usableWeapons.add(ItemGenerator.generateMonsterWeapon(3, level, level));
    }


    // Crustacean does not have a specific monster action, apart from its heavy, damageable armor, so this returns an empty String
    @Override
    public String takeMonsterAction(Ship ship) {
        return "";
    }


    private void damageArmorPlating() {
        if (getArmorPlating() - getBlastArmorReductionMod() > 0) {
            setArmorPlating(getArmorPlating() - getBlastArmorReductionMod());
        } else {
            setArmorPlating(0);
        }
    }


    //Overrides the base Attackable takeDamage() method to implement the Crustaceans armor
    // Returns different messages based on whether it reduced took reduced damage, took blast damage and got its armor reduced, or has no armor left and takes full damage
    // Status effect inflicting weapons have an 80% chance of just glancing off the shell
    @Override
    public String takeDamage(AttackResult attackResult) {
        int damageBeingTaken = Math.max(attackResult.getAttackDmg() - getArmorPlating(), 0);
        String standardDamageMessage = "The " + getName() + " takes " + damageBeingTaken + " " + attackResult.getAttackType().toString() + " damage";

        if(attackResult.didAttackHit()) {

            if (getArmorPlating() > 0) {
                setHP(getHP() - damageBeingTaken);
                return takeDamageWithArmorPlatingMessage(attackResult, standardDamageMessage);

            } else {
                setHP(getHP() - attackResult.getAttackDmg());
                return takeDamageWithNoArmorMessage(attackResult, standardDamageMessage);
            }
        }
        return "The attack misses The " + getName();
    }

    // More complicated damage-taking message function for working with the armorPlating stat
    private String takeDamageWithArmorPlatingMessage(AttackResult attackResult, String standardDamageMessage) {
        if (attackResult.getAttackType() == DamageType.BLAST) {
            damageArmorPlating();
            if (getArmorPlating() == 0) {
                return standardDamageMessage + ", its shell now fully blasted apart";
            }
            return standardDamageMessage + ", as a section of its shell is blasted away";
        }

        if(attackResult.inflictsEffect() && Attackable.diceRoll(1,100) < 80) {
            return standardDamageMessage + ", but the " + attackResult.getEffectInflicted().toString() + " effect glances off the carapace";
        } else if (attackResult.inflictsEffect()) {
            addStatusEffectToList(attackResult.getEffectInflicted());
            return standardDamageMessage + " and is " + attackResult.getEffectInflicted().getVerbRepresentation();
        }
        return standardDamageMessage + ", its shell absorbing part of the hit";
    }

    // Less complicated damage-taking message function for once the armorPlating has been shattered
    private String takeDamageWithNoArmorMessage(AttackResult attackResult, String standardDamageMessage) {
        if(attackResult.inflictsEffect()) {
            addStatusEffectToList(attackResult.getEffectInflicted());
            return standardDamageMessage + " and is " + attackResult.getEffectInflicted().getVerbRepresentation();
        }
        return standardDamageMessage + ", wailing as the hit strikes its armor-less flesh";
    }
}

