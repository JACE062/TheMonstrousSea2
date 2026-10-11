package edu.neumont.csc150.models.attacksandattackables.ships;

import edu.neumont.csc150.controllers.ItemGenerator;
import edu.neumont.csc150.models.attacksandattackables.Attackable;
import edu.neumont.csc150.models.enums.ShipWeaponType;
import edu.neumont.csc150.models.enums.StatusEffect;
import edu.neumont.csc150.models.items.Consumable;
import edu.neumont.csc150.models.items.Item;
import edu.neumont.csc150.models.items.Treasure;
import edu.neumont.csc150.models.items.weapons.Weapon;
import edu.neumont.csc150.models.items.weapons.shipweapons.ShipWeapon;

import java.util.ArrayList;

public class Ship implements Attackable {
    protected static final String SHIP_DESCRIPTION = Item.whiteSpaceForDisplay + "\"Standard Ships are well-rounded, finely-crafted vessels, constructed to sail the Sea and weather any storms they may face.\n" +
                                                     Item.whiteSpaceForDisplay + "     These barques are best suited for captains who value versatility and reliability over a specific style of sailing.\n" +
                                                     Item.whiteSpaceForDisplay + "         While they lack specialization, their balanced design ensures they are ready for whatever lies in wait.\"";

    public String getDescription() {
        return SHIP_DESCRIPTION;
    }
    private static final String[] baseShipAdjectives = {"Trusty", "Modest", "Faithful", "Reliable", "Seasoned", "Weathered", "Simple", "Dependable"};

    private String name;
    private int level;
    private int value;
    private int armorClass;
    private int maxHullHitPoints;
    private int hullHitPoints;
    protected ArrayList<StatusEffect> currentEffectList = new ArrayList<>();

    private int maxCargo;
    protected ArrayList<Item> currentCargo = new ArrayList<>();
    private int maxWeaponWeight;
    private int currentWeaponWeight;
    protected ArrayList<ShipWeapon> equippedWeapons = new ArrayList<>();
    private ArrayList<ShipWeaponType> typesOfWeaponsCurrentlyEquipped = new ArrayList<>();


    //region Getters/Setters
    @Override
    public String getName() {
        return this.name;
    }

    @Override
    public void setName(String name) {
        if(name != null){
            this.name = name;
        }
    }

    @Override
    public int getLevel() {
        return this.level;
    }

    @Override
    public void setLevel(int level) {
        if(level > 0){
            this.level = level;
        }
    }


    public int getValue() {
        return value;
    }

    public void setValue(int value) {
        this.value = value;
    }

    @Override
    public int getArmorClass() {
        return this.armorClass;
    }

    @Override
    public void setArmorClass(int armorClass) {
        if(armorClass > 0){
            this.armorClass = armorClass;
        }
    }

    public int getMaxHP() {
        return maxHullHitPoints;
    }

    public void setMaxHP(int maxHullHitPoints) {
        this.maxHullHitPoints = maxHullHitPoints;
    }

    @Override
    public int getHP() {
        return this.hullHitPoints;
    }

    @Override
    public void setHP(int hp) {
        this.hullHitPoints = Math.max(hp, 0);
    }

    @Override
    public void removeStatusEffectFromList(StatusEffect effect) {
        this.currentEffectList.remove(effect);
    }

    @Override
    public void addStatusEffectToList(StatusEffect effect) {
        if(!this.currentEffectList.contains(effect) && effect != null){
            this.currentEffectList.add(effect);
        }
    }

    @Override
    public ArrayList<StatusEffect> getStatusEffectList() {
        return currentEffectList;
    }
    //endregion


    //region Cargo
    public int getMaxCargo() {
        return maxCargo;
    }

    public void setMaxCargo(int maxCargo) {
        if(maxCargo > 0){
            this.maxCargo = maxCargo;
        }
    }

    public String sellCargoItem(Item item) {
        if (item != null && currentCargo.contains(item)) {
            currentCargo.remove(item);

            return item.getName() + " sold for " + item.getValue() + "g";
        }
        return "Item could not be sold";
    }


    // Removes an item to the cargo hold as long as it exists and the Cargo contains it
    public String dropCargo(Item item) {
        if (item != null && currentCargo.contains(item)) {
            currentCargo.remove(item);
            return item.getName() + " removed from cargo hold";
        } else {
            return "Item does not exist in cargo hold";
        }
    }

    // Adds an item to the cargo hold if it doesn't already contain it and the cargo isn't full
    public String addCargo(Item item) {
        if (item != null && !currentCargo.contains(item) && currentCargo.size() < maxCargo) {
            currentCargo.add(item);
            return item.getName() + " added to cargo hold";
        } else if(item != null){
            if (currentCargo.contains(item)) {
                return item.getName() + " is already in the cargo hold!";
            }
            return item.getName() + " could not be added to the cargo hold, the Cargo is full!";
        } else {
            return "Item does not exist";
        }
    }

    public String addCargoAndSort(Item item) {
        if (item instanceof Weapon) {
            return addCargo(item);
        } else {
            String message = addCargo(item);
            sortCargo();
            return message;
        }
    }

    // Separates cargo hold into the three item types, then sorts each section using Comparable implementation in Item, before combining
    public void sortCargo() {
        ArrayList<Item> treasureList = new ArrayList<>();
        ArrayList<Item> consumableList = new ArrayList<>();
        ArrayList<Item> weaponList = new ArrayList<>();


        for (Item item : getCurrentCargo()) {

            if (item instanceof Treasure) {
                treasureList.add(item);
            }

            if (item instanceof Consumable) {
                consumableList.add(item);
            }

            if (item instanceof Weapon) {
                weaponList.add(item);
            }
        }

        sortItemList(treasureList);
        sortItemList(consumableList);
        sortItemList(weaponList);

        getCurrentCargo().clear();
        getCurrentCargo().addAll(treasureList);
        getCurrentCargo().addAll(consumableList);
        getCurrentCargo().addAll(weaponList);

    }

    public void sortItemList(ArrayList<Item> items) {
        items.sort(Item::compareTo);
    }


    public String addListOfItemsToCargo(ArrayList<Item> items) {
        ArrayList<Item> itemsToRemove = new ArrayList<>();
        StringBuilder sb = new StringBuilder();
        for (Item item : items) {
            if (currentCargo.size() < maxCargo) {
                sb.append(addCargo(item)).append("\n");
                itemsToRemove.add(item);
            } else {
                for (Item itemToRemove : itemsToRemove) {
                    items.remove(itemToRemove);
                }
                sb.append("Cargo Hold is full!");
                sortCargo();
                return sb.toString();
            }
        }

        for (Item item : itemsToRemove) {
            items.remove(item);
        }

        sortCargo();
        return sb.toString();
    }


    public ArrayList<Item> getCurrentCargo() {
        return currentCargo;
    }
    //endregion


    //region Weapons
    public int getMaxWeaponWeight() {
        return maxWeaponWeight;
    }

    public void setMaxWeaponWeight(int maxWeaponWeight) {
        this.maxWeaponWeight = maxWeaponWeight;
    }

    public int getCurrentWeaponWeight() {
        return currentWeaponWeight;
    }

    public void setCurrentWeaponWeight(int currentWeaponWeight) {
        this.currentWeaponWeight = currentWeaponWeight;
    }

    public ArrayList<ShipWeapon> getEquippedWeapons() {
        return equippedWeapons;
    }

    public void setEquippedWeapons(ArrayList<ShipWeapon> equippedWeapons) {
        maxCargo++;
        for (ShipWeapon shipWeapon : equippedWeapons) {

            addCargo(shipWeapon);
            equipWeapon(shipWeapon);
        }
        maxCargo--;
    }

    // Equips the passed weapon if it is not currently equipped, is currently in the cargo, and won't cause the currentWeaponWeight go over the maximum weapon weight allowed
    // Returns a String with a success or failure message
    public String equipWeapon(ShipWeapon weapon) {
        sortEquippedWeapons();
        if (weapon != null && !equippedWeapons.contains(weapon) && currentCargo.contains(weapon) && (currentWeaponWeight + weapon.getEquipWeight()) <= maxWeaponWeight) {
            currentCargo.remove(weapon);
            equippedWeapons.add(weapon);

            sortEquippedWeapons();
            setCurrentWeaponWeight(currentWeaponWeight + weapon.getEquipWeight());
            if (!typesOfWeaponsCurrentlyEquipped.contains(weapon.getWeaponType())) {
                typesOfWeaponsCurrentlyEquipped.add(weapon.getWeaponType());
            }
            return weapon.getName() + " equipped";
        } else if (weapon != null && (currentWeaponWeight + weapon.getEquipWeight()) > maxWeaponWeight){
            return weapon.getName() + " exceeds " + getName() + "'s max total weapon equip weight. Unequip weapons to make space";
        }
        return "Weapon equip error";
    }

    // Unequips the passed weapon if it is currently equipped and there is space in the cargo to hold it
    // If there is no space in the cargo, lets the player know
    // Returns a String with a success or failure message
    public String unequipWeapon(ShipWeapon weapon) {
        sortEquippedWeapons();
        if (weapon != null && equippedWeapons.contains(weapon) && currentCargo.size() < maxCargo) {
            equippedWeapons.remove(weapon);
            addCargo(weapon);

            sortEquippedWeapons();
            sortCargo();
            if (!checkEquippedWeaponsForType(weapon.getWeaponType())) {
                typesOfWeaponsCurrentlyEquipped.remove(weapon.getWeaponType());
            }
            currentWeaponWeight -= weapon.getEquipWeight();
            return weapon.getName() + " unequipped and added to cargo";

        } else if (weapon != null && currentCargo.size() == maxCargo){
            return "No space available in cargo for the " + weapon.getName();
        }
        return "Weapon unequip error";
    }

    private void sortEquippedWeapons() {
        equippedWeapons.sort(Item::compareTo);
    }

    // Returns true if the currently equipped weapons have at least one weapon of a specific type
    private boolean checkEquippedWeaponsForType(ShipWeaponType type) {
        for(ShipWeapon weapon : equippedWeapons) {
            if (weapon.getWeaponType().equals(type)) {
                return true;
            }
        }
        return false;
    }

    public ArrayList<ShipWeaponType> getTypesOfWeaponsCurrentlyEquipped() {
        return typesOfWeaponsCurrentlyEquipped;
    }

    private void setTypesOfWeaponsCurrentlyEquipped(ArrayList<ShipWeaponType> typesOfWeaponsCurrentlyEquipped) {
        this.typesOfWeaponsCurrentlyEquipped = typesOfWeaponsCurrentlyEquipped;
    }

    public void decrementChargeTimeOnWeapons() {
        for (ShipWeapon weapon : getEquippedWeapons()) {
            weapon.decrementChargeCountdown();
        }
    }
    //endregion


    // Constructor for random Ships based on level
    // Base stats of Ship: name: "(random baseShipAdjective) Ship", armorClass: 10 (+ 2 per level), hitPoints: ~100 (+ 40-60 per level), maxCargo: ~20 (+ 10-20 per level), maxWeaponWeight: 7 (+ 7 per level)
    public Ship(int level) {
        this(baseShipAdjectives[ItemGenerator.rand.nextInt(baseShipAdjectives.length)] + " Ship", level, 400*level, 8 + 2*level ,50 + ItemGenerator.rand.nextInt(40, 61)*level, 5 + ItemGenerator.rand.nextInt(10, 21)*level, 7*level);
    }

    public Ship(String name, int level, int value, int armorClass, int hullHitPoints, int maxCargo, int maxWeaponWeight) {
        setName(name);
        setLevel(level);
        setValue(value);
        setArmorClass(armorClass);
        setMaxHP(hullHitPoints);
        setHP(hullHitPoints);
        setMaxCargo(maxCargo);
        setMaxWeaponWeight(maxWeaponWeight);

        sortCargo();
    }


    public String useConsumable(Consumable consumable, Attackable target) {
        String consumableActionString = consumable.use(target);

        if (consumable.getUsesLeft() == 0) {
            getCurrentCargo().remove(consumable);
            String consumableRemovedString = "\n" + "The " + consumable.getName() + " is fully consumed";
            return consumableActionString + consumableRemovedString;
        }
        return consumableActionString;
    }

    // 40% chance to flee at base level (returns true is fleeing was successful)
    // decreases by 5% each ship level (as you progress further, fleeing should be more difficult, less of a recourse)
    // if above level 6, just has a hard coded 5% chance of fleeing, so that no matter how high the level, there is always a small chance
    public boolean flee() {
        if (getLevel() > 6) {
            return Attackable.diceRoll(1, 100) > 95;
        }
        return Attackable.diceRoll(1, 100) > (60 + 5*getLevel());
    }



    public String shipSubclassAction() {
        return "";
    }

    @Override
    public String toString() {
        return getName() + " - lvl " + getLevel() + " Ship (" + getValue() + "g)";
    }

    // String representation of the Ship with all its fields, with optional description added based on whether the player wants it or not, overridden in subclasses to add their specific fields
    public String fullDetails(boolean displayDescription) {
        StringBuilder sb = new StringBuilder();
        sb.append(this);
        if (displayDescription) {
            sb.append("\n").append(getDescription());
        }
        sb.append("\n").append(Item.whiteSpaceForDisplay).append("AC: ").append(getArmorClass());
        sb.append("\n").append(Item.whiteSpaceForDisplay).append("Hull: ").append(getMaxHP());
        sb.append("\n").append(Item.whiteSpaceForDisplay).append("Cargo Space: ").append(getMaxCargo());
        sb.append("\n").append(Item.whiteSpaceForDisplay).append("Weapon Weight Capacity: ").append(getMaxWeaponWeight());

        return sb.toString();
    }
}
