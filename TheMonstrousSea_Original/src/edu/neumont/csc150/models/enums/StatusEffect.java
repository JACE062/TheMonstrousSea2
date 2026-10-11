package edu.neumont.csc150.models.enums;

public enum StatusEffect {
    STUN("Stun", "Stunned"),
    POISON("Poison", "Poisoned"),
    BURN("Burn","Burning");

    private final String prettyString;
    private final String verbRepresentation;

    StatusEffect(String prettyString, String verbRepresentation) {
        this.prettyString = prettyString;
        this.verbRepresentation = verbRepresentation;
    }

    @Override
    public String toString() {
        return prettyString;
    }

    public String getVerbRepresentation() {
        return verbRepresentation;
    }
}
