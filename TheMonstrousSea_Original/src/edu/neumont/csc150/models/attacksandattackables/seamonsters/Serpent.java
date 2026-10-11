package edu.neumont.csc150.models.attacksandattackables.seamonsters;

import edu.neumont.csc150.controllers.ItemGenerator;
import edu.neumont.csc150.models.attacksandattackables.AttackResult;
import edu.neumont.csc150.models.attacksandattackables.Attackable;
import edu.neumont.csc150.models.attacksandattackables.ships.Ship;

public class Serpent extends SeaMonster {
    private static final String[] POSSIBLE_SERPENT_NAMES = {"Slithery Devil", "Eerie Elainaling", "Sussy Seaweed", "Elusive Eell", "Writhing Curse", "Lurking Coil", "Twisting Terror", "Vanishing Viper", "Mire Serpent", "Darting Death"};
    private int baseEvasionChance;
    private int currentEvasionChance;



    public int getBaseEvasionChance() {
        return baseEvasionChance;
    }

    private void setBaseEvasionChance(int baseEvasionChance) {
        if (baseEvasionChance > 0.0) {
            this.baseEvasionChance = baseEvasionChance;
        }
    }

    public int getCurrentEvasionChance() {
        return currentEvasionChance;
    }

    private void setCurrentEvasionChance(int currentEvasionChance) {
        this.currentEvasionChance = currentEvasionChance;
    }


    // Constructor for random Serpents based on level
    // Base stats of Serpent: name: random from possibleSerpentNames, armorClass: 10 (+ 2 per level), hitPoints: 60 (+ 60 per level)
    // EvasionChance starts at a base of 10, increasing by 5 per level
    public Serpent(int level) {
        super(POSSIBLE_SERPENT_NAMES[ItemGenerator.rand.nextInt(POSSIBLE_SERPENT_NAMES.length)], level, 8 + 2*level, 60 * level);
        setBaseEvasionChance(5 + 5*level);
        setCurrentEvasionChance(5 + 5*level);

        // Serpents also get jaws and tail attacks
        usableWeapons.add(ItemGenerator.generateMonsterWeapon(1, level, level));
        usableWeapons.add(ItemGenerator.generateMonsterWeapon(2, level, level));
    }

    // Constructor for hard coded Serpents (for potential hard-coded boss)
    public Serpent(String name, int level, int armorClass, int hitPoints, int evasionChance) {
        super(name, level, armorClass, hitPoints);
        setBaseEvasionChance(evasionChance);
        setCurrentEvasionChance(evasionChance);

        // Serpents also get jaws and tail attacks
        usableWeapons.add(ItemGenerator.generateMonsterWeapon(1, level, level));
        usableWeapons.add(ItemGenerator.generateMonsterWeapon(2, level, level));
    }


    @Override
    public String takeMonsterAction(Ship ship) {
        evasiveManeuvers();
        return getName() + " dives into the water, slithering to and fro, confusing the gunners";
    }


    private void evasiveManeuvers() {
        setCurrentEvasionChance(baseEvasionChance * 2);
    }

    //Overrides the base Attackable takeDamage() method to implement Serpents' dodge chance
    @Override
    public String takeDamage(AttackResult attackResult) {
        if(attackResult.didAttackHit()) {
            if (currentEvasionChance >= Attackable.diceRoll(1,100)) {
                if (getCurrentEvasionChance() > getBaseEvasionChance() ) {
                    setCurrentEvasionChance(getBaseEvasionChance());
                    return "The erratic movements of The " + getName() + " make the attack sail cleanly past, before the Serpent rears back out of the water";
                } else {
                    return "The " + getName() + " quickly slithers out of the way of the attack";
                }
            }
        }
        return super.takeDamage(attackResult);
    }
}