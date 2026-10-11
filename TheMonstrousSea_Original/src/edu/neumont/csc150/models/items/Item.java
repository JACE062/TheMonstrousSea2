package edu.neumont.csc150.models.items;

import edu.neumont.csc150.models.enums.RarityLevel;
import edu.neumont.csc150.models.items.weapons.shipweapons.ShipWeapon;

public abstract class Item implements Comparable<Item> {
    public static final String whiteSpaceForDisplay = "       ";
    private String name;
    private String description;
    private int value;
    private RarityLevel rarity;


    public String getName() {
        return name;
    }

    protected void setName(String name) {
        this.name = name;
    }

    protected String getDescription() {
        return description;
    }

    protected void setDescription(String description) {
        this.description = description;
    }

    public int getValue() {
        return value;
    }

    protected void setValue(int value) {
        if(value >= 0) {
            this.value = value;
        } else {
            this.value = 0;
        }
    }

    public RarityLevel getRarity() {
        return rarity;
    }

    protected void setRarity(RarityLevel rarity) {
        this.rarity = rarity;
    }

    public Item(String name, String description, int value, RarityLevel rarity) {
        setName(name);
        setDescription(description);
        setValue(value);
        setRarity(rarity);
    }

    @Override
    public String toString() {
        return " - " + getName() + " (" + getValue() + "g)";
    }

    public String stringWithDescription() {
        return this.toString()  + "\n" + Item.whiteSpaceForDisplay + "\"" + getDescription() + "\"";
    }

    public abstract String fullDetailsString();


     //Comparable implementation so that the Cargo can be sorted by value and Rarity, with weapons being sorted by type
    @Override
    public int compareTo(Item item) {
        if (!this.getRarity().equals(item.getRarity())) {
            return this.getRarity().compareTo(item.getRarity());

        } else if (this instanceof ShipWeapon && item instanceof ShipWeapon && !((ShipWeapon)this).getWeaponType().equals(((ShipWeapon)item).getWeaponType())) {
            return ((ShipWeapon)this).getWeaponType().compareTo(((ShipWeapon)item).getWeaponType());
        }

        return this.getValue() - item.getValue();
    }
}
