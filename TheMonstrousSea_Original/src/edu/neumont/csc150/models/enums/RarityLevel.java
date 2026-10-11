package edu.neumont.csc150.models.enums;

import edu.neumont.csc150.models.items.Item;
import edu.neumont.csc150.views.Console;

public enum RarityLevel implements Comparable<RarityLevel>{
    COMMON ("Common", 1, Console.TextColor.GREEN),
    RARE ("Rare", 2, Console.TextColor.BLUE),
    EPIC ("Epic", 3, Console.TextColor.PURPLE),
    LEGENDARY ("Legendary", 4, Console.TextColor.YELLOW);

    private final String prettyString;
    private final int level;
    private final Console.TextColor textColor;

    RarityLevel(String prettyString, int level, Console.TextColor textColor) {
        this.prettyString = prettyString;
        this.level = level;
        this.textColor = textColor;
    }

    public int getLevel() {
        return level;
    }

    public Console.TextColor getTextColor() {
        return textColor;
    }

    @Override
    public String toString() {
        return prettyString;
    }
}
