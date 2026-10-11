package edu.neumont.csc150.models.attacksandattackables.ships;

import edu.neumont.csc150.controllers.ItemGenerator;
import edu.neumont.csc150.models.attacksandattackables.AttackResult;
import edu.neumont.csc150.models.attacksandattackables.Attackable;
import edu.neumont.csc150.models.items.Item;

public class Corvette extends Ship {
    private static final String CORVETTE_DESCRIPTION = Item.whiteSpaceForDisplay + "\"Corvette-Class ships zip through the waves with speed and agility unmatched by ship or sea monster alike.\n" +
                                                       Item.whiteSpaceForDisplay + "    Their lightweight frames dance around opponents, proving elusive for even the most formidable foes.\n" +
                                                       Item.whiteSpaceForDisplay + "       But, to achieve such breakneck speeds, they sacrifice both weapon capacity and cargo space.\"";

    @Override
    public String getDescription() {
        return CORVETTE_DESCRIPTION;
    }

    private static final String[] corvetteAdjectives = {"Swift", "Elusive", "Wily", "Phantom", "Nimble", "Slippery", "Gale-Forged", "Dancing"};

    private int baseEvasionChance;
    private int currentEvasionChance;

    public int getBaseEvasionChance() {
        return baseEvasionChance;
    }

    private void setBaseEvasionChance(int baseEvasionChance) {
        if (baseEvasionChance > 0 && baseEvasionChance <= 50) {
            this.baseEvasionChance = baseEvasionChance;
        } else {
            this.baseEvasionChance = 50;
        }
    }

    public int getCurrentEvasionChance() {
        return currentEvasionChance;
    }

    private void setCurrentEvasionChance(int currentEvasionChance) {
        this.currentEvasionChance = currentEvasionChance;
    }



    // Constructor for random Corvettes based on level
    // Base stats of Corvette: name: "(random corvetteAdjective) Corvette", armorClass: 6 (+ 2 per level), hitPoints: ~80 (+ 30-50 per level), maxCargo: ~15 (+ 5-15 per level), maxWeaponWeight: ~4 (+ 3-5 per level), evasionChance: 10 (+ 5 per level) (capped at 50 by setter)
    public Corvette(int level) {
        this(corvetteAdjectives[ItemGenerator.rand.nextInt(corvetteAdjectives.length)] + " Corvette", level, 400*level, 4 + 2*level , 40 + ItemGenerator.rand.nextInt(30, 51)*level, 5 + ItemGenerator.rand.nextInt(5, 16)*level,  5*level, 5 + 5*level);
    }

    public Corvette(String name, int level, int value, int armorClass, int hullHitPoints, int maxCargo, int maxWeaponWeight, int evasionChance) {
        super(name, level, value, armorClass, hullHitPoints, maxCargo, maxWeaponWeight);
        setBaseEvasionChance(evasionChance);
        setCurrentEvasionChance(evasionChance);

    }

    @Override
    public String shipSubclassAction() {
        evasiveManeuvers();
        return "The " + getName() + " swiftly shifts course, slipping into an evasive pattern";
    }

    private void evasiveManeuvers() {
        setCurrentEvasionChance(baseEvasionChance * 2);
    }


    //Overrides the base Attackable takeDamage() method to implement the evasion chance of Corvettes
    @Override
    public String takeDamage(AttackResult attackResult) {
        if(attackResult.didAttackHit()) {
            if (currentEvasionChance >= Attackable.diceRoll(1,100)) {
                if (getCurrentEvasionChance() > getBaseEvasionChance() ) {
                    setCurrentEvasionChance(getBaseEvasionChance());
                    return "In the nick of time, The " + getName() + " jukes hard to port, expertly dodging the strike, before settling back into its normal heading";
                } else {
                    return "The " + getName() + " narrowly dodges the attack";
                }
            }
        }
        return super.takeDamage(attackResult);
    }

    @Override
    public String toString() {
        return getName() + " - lvl " + getLevel() + " Corvette (" + getValue() + "g)";
    }

    @Override
    public String fullDetails(boolean displayDescription) {
        return super.fullDetails(displayDescription) +
                    "\n" + Item.whiteSpaceForDisplay + "Evasion: " + getBaseEvasionChance();
    }
}
