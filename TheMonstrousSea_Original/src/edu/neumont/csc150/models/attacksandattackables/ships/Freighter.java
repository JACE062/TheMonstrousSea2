package edu.neumont.csc150.models.attacksandattackables.ships;

import edu.neumont.csc150.controllers.ItemGenerator;
import edu.neumont.csc150.models.attacksandattackables.Attackable;
import edu.neumont.csc150.models.items.Item;

import java.util.ArrayList;

public class Freighter extends Ship{
    public static final String FREIGHTER_DESCRIPTION = Item.whiteSpaceForDisplay + "\"Freighter-Class ships are vast, heavy cargo vessels designed with hold capacity, rather than fighting capabilities, as their main priority.\n" +
                                                       Item.whiteSpaceForDisplay + "   With the right weapons, though few they might be, a Freighter can pack a wallop and have plenty of hold space to bring the loot home.\n" +
                                                       Item.whiteSpaceForDisplay + "     Although utilized for smuggling, the safe stash on Freighters can survive almost anything, saving some items even after capsizing.\"";
    @Override
    public String getDescription() {
        return FREIGHTER_DESCRIPTION;
    }

    private static final String[] freighterAdjectives = {"Plentiful", "Golden", "Bountiful", "Hefty", "Heavy-Laden", "Abundant", "Opulent", "Colossal", "Well-Stocked"};

    // Constructor for random Freighters based on level
    // Base stats of Freighter: name: "(random freighterAdjective) Freighter", armorClass: 8 (+ 2 per level), hitPoints: 125 (+ 80-120 per level), maxCargo: ~30 (+ 20-40 per level), maxWeaponWeight: ~4 (+ 3-5 per level)
    public Freighter(int level) {
        this(freighterAdjectives[ItemGenerator.rand.nextInt(freighterAdjectives.length)] + " Freighter", level, 400*level, 6 + 2*level , 25 + ItemGenerator.rand.nextInt(80, 121)*level, ItemGenerator.rand.nextInt(20, 41)*level, ItemGenerator.rand.nextInt(3, 6)*level);
    }

    public Freighter(String name, int level, int value, int armorClass, int hullHitPoints, int maxCargo, int maxWeaponWeight) {
        super(name, level, value, armorClass, hullHitPoints, maxCargo, maxWeaponWeight);
    }


    // Currently hard coded to only keep a tenth of the items in the hold
    // Also keeps one random weapon that is currently equipped
    public ArrayList<Item> safeCargoStash() {
        ArrayList<Item> randomSavedCargo = new ArrayList<>();

        int i = 0;
        for (Item item : getCurrentCargo()) {
            if (i % 10 == 0) {
                randomSavedCargo.add(item);
            }
            i++;
        }

        if (!getEquippedWeapons().isEmpty()) {
            Item randomKeptWeapon = getEquippedWeapons().get(Attackable.diceRoll(1, getEquippedWeapons().size() - 1));
            randomSavedCargo.add(randomKeptWeapon);
        }

        return randomSavedCargo;
    }


    @Override
    public String toString() {
        return getName() + " - lvl " + getLevel() + " Freighter (" + getValue() + "g)";
    }
}
