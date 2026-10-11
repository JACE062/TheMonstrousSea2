package edu.neumont.csc150.models.attacksandattackables.ships;

import edu.neumont.csc150.controllers.ItemGenerator;
import edu.neumont.csc150.models.attacksandattackables.AttackResult;
import edu.neumont.csc150.models.items.Item;

public class Ironclad extends Ship {
    public static final String IRONCLAD_DESCRIPTION = Item.whiteSpaceForDisplay + "\"Ironclad-Class ships are the toughest vessels to sail the seas, their reinforced hulls taking hits that would shatter lesser ships.\n" +
                                                      Item.whiteSpaceForDisplay + "       With all their size and bulk, they brandish a large arsenal of weapons, striking fear into the denizens of the Sea.\n" +
                                                      Item.whiteSpaceForDisplay + "            But due to the sheer weight of their equipment, these behemoths are limited in their speed and cargo space.\"";
    @Override
    public String getDescription() {
        return IRONCLAD_DESCRIPTION;
    }

    private static final String[] ironcladAdjectives = {"Titanic", "Unyielding", "Indomitable", "Steadfast", "Dauntless", "Dreadnought", "Adamant", "Resolute"};

    private int baseDmgReduction;
    private int dmgReductionMod;
    private int currentDmgReduction;

    public int getBaseDmgReduction() {
        return baseDmgReduction;
    }

    public void setBaseDmgReduction(int baseDmgReduction) {
        this.baseDmgReduction = baseDmgReduction;
    }

    public int getDmgReductionMod() {
            return dmgReductionMod;
    }

    private void setDmgReductionMod(int dmgReductionMod) {
        if (dmgReductionMod > 0) {
            this.dmgReductionMod = dmgReductionMod;
        } else {
            this.dmgReductionMod = 0;
        }

    }

    public int getCurrentDmgReduction() {
        return currentDmgReduction;
    }

    private void setCurrentDmgReduction(int currentDmgReduction) {
        if (currentDmgReduction > 0) {
            this.currentDmgReduction = currentDmgReduction;
        }
    }


    // Constructor for random Ironclads based on level
    // Base stats of Ironclad: name: "(random ironcladAdjective) Ironclad", armorClass: 12 (+ 2 per level), hitPoints: ~100 (+ 65-85 per level), maxCargo: ~11 (+ 5-7 per level), maxWeaponWeight: 10 (+ 10 per level), baseDmgReduction: 3 (+ 3 per level), dmgReductionMod: 2 (+2 per level)
    public Ironclad(int level) {
        this(ironcladAdjectives[ItemGenerator.rand.nextInt(ironcladAdjectives.length)] + " Ironclad", level, 400*level, 10 + 2*level ,25 + ItemGenerator.rand.nextInt(65,86)*level, 5 + ItemGenerator.rand.nextInt(5, 8)*level, 10*level, 3*level, 2*level);
    }

    public Ironclad(String name, int level, int value, int armorClass, int hullHitPoints, int maxCargo, int maxWeaponWeight, int baseDmgReduction,int dmgReductionMod) {
        super(name, level, value, armorClass, hullHitPoints, maxCargo, maxWeaponWeight);
        setBaseDmgReduction(baseDmgReduction);
        setCurrentDmgReduction(baseDmgReduction);
        setDmgReductionMod(dmgReductionMod);
    }


    @Override
    public String shipSubclassAction() {
        return fortify();
    }


    private String fortify() {
        setCurrentDmgReduction(getCurrentDmgReduction() + getDmgReductionMod());
        return "The " + getName() + " braces and fortifies its hull";
    }

    // TODO: I would like there to be specific messages for the damage that has been nulified, to make the player feel powerful
    // Overrides the base Attackable takeDamage() method to implement the damage reduction on Ironclads
    @Override
    public String takeDamage(AttackResult attackResult) {
        if(attackResult.didAttackHit()) {
            setHP(getHP() - Math.max(attackResult.getAttackDmg() - getCurrentDmgReduction(), 0));
            if(attackResult.inflictsEffect()) {
                this.addStatusEffectToList(attackResult.getEffectInflicted());
                return "The " + getName() + " takes " + attackResult.getAttackDmg() + " damage and is " + attackResult.getEffectInflicted().getVerbRepresentation();
            }
            return "The " + getName() + " takes " + attackResult.getAttackDmg() + " " + attackResult.getAttackType().toString() + " damage";
        }
        return "The attack misses The " + getName();
    }


    @Override
    public String toString() {
        return getName() + " - lvl " + getLevel() + " Ironclad (" + getValue() + "g)";
    }

    @Override
    public String fullDetails(boolean displayDescription) {

        return super.fullDetails(displayDescription) +
                "\n" + Item.whiteSpaceForDisplay + "Base Hull Reinforcement: " + getBaseDmgReduction() +
                "\n" + Item.whiteSpaceForDisplay + "Fortify Modifier: " + getDmgReductionMod();
    }
}
