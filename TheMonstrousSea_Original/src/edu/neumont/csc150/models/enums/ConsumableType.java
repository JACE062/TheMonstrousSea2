package edu.neumont.csc150.models.enums;

public enum ConsumableType {
    UNSTABLE_TINCTURE("Unstable Tincture", "An iridescant vial of stormy liquid with a noticable warmth", DamageType.VENOM),
    BLAST_PACK("Blast Pack", "A small bundle of explosives designed for breaching armored doors", DamageType.BLAST),
    CHAKRAM("Chakram", "Very sharp, circular throwing-blade. Won't hurt much, but could sever limbs if thrown right", DamageType.SLICING),;



    private final String prettyString;
    private final String description;
    private final DamageType dmgType;

    ConsumableType(String prettyString, String description, DamageType inflictsStatus) {
        this.prettyString = prettyString;
        this.description = description;
        this.dmgType = inflictsStatus;
    }

    public String getDescription() {
        return description;
    }

    public DamageType getDmgType() {
        return dmgType;
    }

    @Override
    public String toString() {
        return prettyString;
    }


}
