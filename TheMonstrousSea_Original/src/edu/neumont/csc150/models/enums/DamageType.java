package edu.neumont.csc150.models.enums;

public enum DamageType {
    BLUDGEONING ("Bludgeoning"),
    BLAST ("Blast"),
    ELECTRIC ("Electric"),
    FIRE ("Fire"),
    SLICING ("Slicing"),

    BITING ("Biting"),
    CRUSHING ("Crushing"),
    RAMMING ("Ramming"),
    VENOM ("Venom");

    private final String prettyString;

    DamageType(String prettyString) {
        this.prettyString = prettyString;
    }

    @Override
    public String toString() {
        return prettyString;
    }


}
