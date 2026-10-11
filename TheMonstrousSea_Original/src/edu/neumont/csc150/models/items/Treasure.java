package edu.neumont.csc150.models.items;

import edu.neumont.csc150.models.enums.RarityLevel;

public class Treasure extends Item {
    private static final String GENERIC_TREASURE_NAME = "Treasure";
    private static final String GENERIC_TREASURE_DESCRIPTION = "An item of some value once lost to the sea";


    public Treasure(RarityLevel rarity, int value) {
        super(GENERIC_TREASURE_NAME, GENERIC_TREASURE_DESCRIPTION, value, rarity);
    }

    @Override
    public String fullDetailsString() {
        return super.stringWithDescription();
    }
}
