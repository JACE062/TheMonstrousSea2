package edu.neumont.csc150.controllers;

import edu.neumont.csc150.models.BattleMap;
import edu.neumont.csc150.models.Player;
import edu.neumont.csc150.models.attacksandattackables.ships.Ship;
import edu.neumont.csc150.models.enums.PlayerAction;
import edu.neumont.csc150.models.items.Consumable;
import edu.neumont.csc150.models.items.Item;
import edu.neumont.csc150.models.items.Treasure;
import edu.neumont.csc150.models.items.weapons.Weapon;
import edu.neumont.csc150.models.items.weapons.shipweapons.ShipWeapon;
import edu.neumont.csc150.models.locations.*;
import edu.neumont.csc150.views.Console;
import edu.neumont.csc150.views.UI;

import java.lang.reflect.Array;
import java.util.ArrayList;

public class LocationController {
    private final Player player;
    private final RestArea restArea;
    private final Port port;
    private final Merchant merchant;
    private final Shipyard shipyard;

    public boolean displayShipsWithLongDescription = true;

    public GameLocation currentLocation;


    public LocationController(Player player, RestArea restArea) {
        this.player = player;
        this.restArea = restArea;
        this.port = restArea.getHomePort();
        this.merchant = port.getMerchant();
        this.shipyard = port.getShipyard();
    }


    public void runLocation(GameLocation currentLocation) {
        this.currentLocation = currentLocation;
        boolean returnToTheSea = false;

        while (!returnToTheSea) {
            returnToTheSea = runActionFromSelection(selectFromActions());
        }
    }


    // Allows the player to select from a list of PlayerActions currently available at the location, then returns that action
    private PlayerAction selectFromActions() {
        if (!currentLocation.isInSubMenu()) {
            if (currentLocation == restArea) {
                UI.printLn(BattleMap.getCurrentMapRepresentation());
            }

            UI.displayHullAndGold(currentLocation.getLocationMessage(), player.getCurrentShip(), player.getCurrentGold());
        }

        int actionIndex = UI.userIntInput(currentLocation.stringOfAvailableActions(), 1, currentLocation.getAvailableActions().size());

        return currentLocation.getAvailableActions().get(actionIndex-1);

    }


    // Takes the PlayerAction input and routes it to the method it is supposed to go to
    private boolean runActionFromSelection(PlayerAction action) {
        switch (action) {
            case CONTINUE_TO_NEXT_BATTLE -> {return true;}
            case VENTURE_OUT_TO_SEA -> {UI.writeStringDramatically("Although your time in " + port.getLocationName() + " was comforting, the Sea awaits...", 0.08, true); return true;}
            case EXIT -> exitLocation();

            case DROP_CARGO -> dropCargo();
            case ADJUST_WEAPONS -> adjustWeapons();
            case EQUIP_WEAPONS -> equipWeapons();
            case UNEQUIP_WEAPONS -> unequipWeapons();
            case RETURN_TO_PORT -> returnToPort();

            case VISIT_SHIPYARD -> visitShipyard();
            case VISIT_MERCHANT -> visitMerchant();
            case VIEW_MAP -> {UI.HR(); UI.printLn(BattleMap.getCurrentMapRepresentation());}

            case REPAIR_CURRENT_SHIP -> repairShip();
            case BUY_SHIPS -> buyShips();
            case ENTER_DRYDOCK -> enterDrydock();
            case SELL_SHIPS -> sellShips();
            case SWITCH_SHIP -> switchShipMenu();

            case BUY_ITEMS -> buyItems();
            case SELL_ITEMS -> sellItems();
            case SELL_ALL_TREASURE -> sellAllTreasures();
        }
        return false;
    }



    private void exitLocation() {
        if (currentLocation instanceof Merchant || currentLocation instanceof Shipyard) {
            currentLocation = port;
            port.setAvailableActions(port.getStandardActions());
        } else {
            currentLocation = restArea;
            restArea.setAvailableActions(restArea.getStandardActions());
        }
    }


    public void dropCargo() {
        while (true) {
            UI.HR();
            UI.printLn("Current cargo space " + player.getCurrentShip().getCurrentCargo().size() + "/" + player.getCurrentShip().getMaxCargo());
            int itemIndex = chooseItemFromList("Choose item to drop from the Cargo:", player.getCurrentShip().getCurrentCargo());

            if (itemIndex == player.getCurrentShip().getCurrentCargo().size() + 1) {
                return;
            }
            UI.printLn(player.getCurrentShip().dropCargo(player.getCurrentShip().getCurrentCargo().get(itemIndex -1)));
        }
    }


    public int chooseItemFromList(String message, ArrayList<Item> itemListToSearch) {
        UI.printLn(message);
        printCargoByType(itemListToSearch);

        return UI.userIntInput("", 1, itemListToSearch.size() + 1);
    }


    // prints the cargo into nice sections separated by type
    public void printCargoByType(ArrayList<Item> itemList) {
        boolean treasureLabelNotPrinted = true;
        boolean consumableLabelNotPrinted = true;
        boolean weaponLabelNotPrinted = true;
        int i = 1;


        if (itemList.isEmpty()) {
            UI.printLn("There are currently no items available to select from.", Console.TextColor.RED);
        } else {
            sortItemList(itemList);
            player.getCurrentShip().sortCargo();
            for (Item item : itemList) {
                if (item instanceof Treasure && treasureLabelNotPrinted) {
                    UI.printLn("\n―――――――――TREASURES―――――――――");
                    treasureLabelNotPrinted = false;
                } else if (item instanceof Consumable && consumableLabelNotPrinted) {
                    UI.printLn("\n――――――――CONSUMABLES―――――――――");
                    consumableLabelNotPrinted = false;
                } else if (item instanceof Weapon && weaponLabelNotPrinted) {
                    UI.printLn("\n―――――――――WEAPONS―――――――――――");
                    weaponLabelNotPrinted = false;
                }
                UI.print(i + ": ");
                UI.printItemDetailsRarityColor(item);
                i++;
            }
        }
        UI.printLn(i + ": Exit");
    }

    private void sortItemList(ArrayList<Item> itemListToSort) {
        ArrayList<Item> treasureList = new ArrayList<>();
        ArrayList<Item> consumableList = new ArrayList<>();
        ArrayList<Item> weaponList = new ArrayList<>();


        for (Item item : itemListToSort) {

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

        treasureList.sort(Item::compareTo);
        consumableList.sort(Item::compareTo);
        weaponList.sort(Item::compareTo);


        itemListToSort.clear();
        itemListToSort.addAll(treasureList);
        itemListToSort.addAll(consumableList);
        itemListToSort.addAll(weaponList);
    }



    private void adjustWeapons() {
        currentLocation.enterWeaponAdjusting();

        while (true) {
            PlayerAction action = selectFromActions();
            if (action == PlayerAction.EXIT) {
                currentLocation.leaveWeaponAdjusting();
                return;
            }
            runActionFromSelection(action);
        }
    }


    private void equipWeapons() {
        ArrayList<ShipWeapon> weapons = new ArrayList<>();
        int weaponIndex;
        while (true) {
            UI.HR();
            weaponIndex = chooseWeaponFromList("Choose Weapon to Equip:  (" + player.getCurrentShip().getCurrentWeaponWeight() + "/" + player.getCurrentShip().getMaxWeaponWeight() + " weight)", weapons, player.getCurrentShip().getCurrentCargo());

            if (weaponIndex == weapons.size() + 1) {
                return;
            }

            UI.print(weapons.get(weaponIndex - 1).getRarity().toString(), weapons.get(weaponIndex - 1).getRarity().getTextColor());
            UI.printLn(" - " + player.getCurrentShip().equipWeapon(weapons.get(weaponIndex - 1)));
        }
    }


    private void unequipWeapons() {
        ArrayList<ShipWeapon> weapons = new ArrayList<>();
        int weaponIndex;
        while (true) {
            UI.HR();
            weaponIndex = chooseWeaponFromList("Choose Weapon to Unequip:  (" + player.getCurrentShip().getCurrentWeaponWeight() + "/" + player.getCurrentShip().getMaxWeaponWeight() + " weight)", weapons, player.getCurrentShip().getEquippedWeapons());

            if (weaponIndex == weapons.size() + 1) {
                return;
            }

            UI.print(weapons.get(weaponIndex - 1).getRarity().toString(), weapons.get(weaponIndex - 1).getRarity().getTextColor());
            UI.printLn(" - " + player.getCurrentShip().unequipWeapon(weapons.get(weaponIndex - 1)));
        }
    }



    // Allows the player to choose from weapons in a list, gives a message if there are no weapons in the list
    private int chooseWeaponFromList(String message, ArrayList<ShipWeapon> weapons, ArrayList<?> weaponListToSearch) {
        int i = 1;
        weapons.clear();

        UI.printLn(message);

        if (weaponListToSearch.isEmpty()) {
            UI.printLn("There are currently no weapons available to select from.", Console.TextColor.RED);
        } else {
            for (Object item : weaponListToSearch) {
                if (item instanceof ShipWeapon) {
                    UI.print(i + ": ");
                    UI.print(((ShipWeapon) item).getRarity().toString(), ((ShipWeapon) item).getRarity().getTextColor());
                    UI.printLn(((ShipWeapon) item).fullDetailsString());

                    weapons.add(((ShipWeapon) item));
                    i++;
                }
            }
            if (weapons.isEmpty()) {
                UI.printLn("There are currently no weapons available to select from.", Console.TextColor.RED);
            }

        }
        UI.printLn(i + ": Exit") ;

        return UI.userIntInput("", 1, weapons.size() + 1);
    }


    private void returnToPort() {
        currentLocation = restArea.getHomePort();
        shipyard.refreshShipsForSale();
        merchant.refreshStock();
        BattleMap.resetMap();
    }


    private void visitShipyard() {
        currentLocation = shipyard;
    }


    // Lets the user choose from a list of ships, gives message if there are no ships in the list
    public int chooseShipFromList(String message, ArrayList<Ship> shipList, boolean showDescriptionAndExit) {
        int i = 1;
        UI.printLn(message);

        if (shipList.isEmpty()) {
            UI.printLn("There are currently no ships to choose from!", Console.TextColor.RED);
        } else {
            for (Ship ship : shipList) {
                if (ship != null) {
                    UI.print(i + ": ");
                    UI.printLn(ship.fullDetails(displayShipsWithLongDescription));
                    UI.printLn("-");
                    i++;
                }
            }
        }
        if (showDescriptionAndExit) {
            UI.printLn(i + ": Toggle Ship Descriptions");
            UI.printLn(i + 1 + ": Exit");

            return UI.userIntInput("", 1, shipList.size() + 2);
        } else {
            return UI.userIntInput("", 1, shipList.size());
        }
    }


    // offers ships for sale to the user, which they can buy outright if they have the money
    // If they are just a little short, offers them to sell their ship and trade it for the new one immediately, rather than put the new ship into the drydock
    private void buyShips() {
        int shipIndex;
        while (true) {
            UI.HR();
            UI.printLn("Current ship: ");
            UI.printLn(player.getCurrentShip().fullDetails(displayShipsWithLongDescription));
            UI.printLn("-");
            UI.displayGold(player.getCurrentGold());
            UI.printLn("-");
            shipIndex = chooseShipFromList("Select a vessel to purchase (New Ship will be placed in drydock) :", shipyard.getShipsForSale(), true);

            if (shipIndex == shipyard.getShipsForSale().size() +2) {
                return;
            } else if (shipIndex == shipyard.getShipsForSale().size()+1) {
                displayShipsWithLongDescription = !displayShipsWithLongDescription;
                UI.printLn("Descriptions toggled!");
            } else {

                Ship shipSelected = shipyard.getShipsForSale().get(shipIndex - 1);

                if (player.getCurrentGold() >= shipSelected.getValue()) {
                    promptForShipRenaming(shipSelected);
                    player.removeGold(shipSelected.getValue());
                    shipyard.addPlayerShipInDrydock(shipSelected);
                    shipyard.getShipsForSale().remove(shipSelected);

                } else if (player.getCurrentGold() + player.getCurrentShip().getValue() >= shipSelected.getValue()) {
                    UI.HR();
                    UI.printLn("You don't have enough loose gold to buy the " + shipSelected.getName() + ", but if you sell you current ship, you will.");
                    UI.print("Would you like to sell the " + player.getCurrentShip().getName() + " for the " + shipSelected.getName() + "? (You will have ");
                    UI.print(((player.getCurrentGold() + player.getCurrentShip().getValue()) - shipSelected.getValue()) + "g", Console.TextColor.YELLOW);
                    UI.printLn(" left over)");


                    if (UI.confirmOrDeny("Sell and switch over", "Cancel Purchase")) {
                        if (switchShip(player.getCurrentShip(), shipSelected)) {
                            player.removeGold(shipSelected.getValue() - player.getCurrentShip().getValue());
                            promptForShipRenaming(shipSelected);
                            player.setCurrentShip(shipSelected);
                            shipyard.getShipsForSale().remove(shipSelected);
                        } else {
                            UI.printLn("Purchase Cancelled", Console.TextColor.RED);
                        }
                    }

                } else {
                    UI.printLn("You can't purchase the " + shipSelected.getName() + " with that! Come back when you have enough gold.", Console.TextColor.RED);
                }
            }
        }
    }


    public void promptForShipRenaming(Ship ship) {
        UI.HR();
        UI.printLn("Would you like to rename The " + ship.getName() + "?  (Name of this ship will be permenant)");
        if(UI.confirmOrDeny("Rename", "Leave as-is")) {
            String potentialName;
            while(true) {
                potentialName = UI.userStringInput("What shall she be named?", false);
                UI.printLn("Your vessel is to be called The " + potentialName);
                if (UI.confirmOrDeny("Yes, it's perfect!", "On second thought...")) {
                    break;
                }
                UI.printLn("");
            }
            ship.setName(potentialName);
        }
    }


    // Allows the user to switch between their current ship and one in the drydock, with handling of problems with Cargo and Equipped Weapons
    private boolean switchShip(Ship currentShip, Ship shipToSwitchTo) {
        boolean continueWithSwitch = true;

        while (continueWithSwitch && currentShip.getCurrentWeaponWeight() > shipToSwitchTo.getMaxWeaponWeight()) {
            UI.HR();
            UI.printLn("The weapons on the " + currentShip.getName() + " are heavier than the " + shipToSwitchTo.getName() + " can carry.  (" + currentShip.getCurrentWeaponWeight() + " vs " + shipToSwitchTo.getMaxWeaponWeight() + ")");
            if (UI.confirmOrDeny("Adjust Weapons", "Cancel")) {
                runActionFromSelection(PlayerAction.ADJUST_WEAPONS);
            } else {
                continueWithSwitch = false;
            }
        }

        if (continueWithSwitch && shipToSwitchTo.getMaxCargo() < currentShip.getCurrentCargo().size()) {
            UI.HR();
            UI.printLn("There is more cargo in the Hold than the " + shipToSwitchTo.getName() + " can carry, do you want to proceed? (Excess cargo will be sold starting from lowest value)");
            if (UI.confirmOrDeny("Proceed", "Cancel")) {
                currentShip.sortCargo();
                while (currentShip.getCurrentCargo().size() > shipToSwitchTo.getMaxCargo()) {
                    player.addGold(currentShip.getCurrentCargo().getFirst().getValue());
                    UI.printLn(currentShip.sellCargoItem(currentShip.getCurrentCargo().getFirst()));
                }
            } else {
                continueWithSwitch = false;
            }
        }

        if(continueWithSwitch) {
            currentShip.sortCargo();
            shipToSwitchTo.addListOfItemsToCargo(currentShip.getCurrentCargo());

            shipToSwitchTo.setEquippedWeapons(currentShip.getEquippedWeapons());
            currentShip.getEquippedWeapons().clear();
            currentShip.setCurrentWeaponWeight(0);
        }

        return continueWithSwitch;
    }


    // Allows the player to repair their ship by a percentage, but if the repair would go over their max hull, only offers them to repair the hull missing (changes price accordingly)
    private void repairShip() {
        Ship shipToRepair = player.getCurrentShip();
        while (true) {
            UI.HR();
            //UI.printLn(player.getCurrentShip().getName() + " currently has " + shipCurrentHP + "/" + shipMaxHP + " Hull left");
            UI.printLn("How much would you like to repair your ship hull?: (Currently at " + shipToRepair.getHP() + "/" + shipToRepair.getMaxHP() + ")");
            UI.print(" Current gold: ");
            UI.printLn(String.valueOf(player.getCurrentGold()), Console.TextColor.YELLOW);
            UI.printLn(String.format("1: 10%% - %1$d Hull, for %1$dg", Math.min((int) (shipToRepair.getMaxHP() * 0.1), shipToRepair.getMaxHP() - shipToRepair.getHP())));
            UI.printLn(String.format("2: 25%% - %1$d Hull, for %1$dg", Math.min((int) (shipToRepair.getMaxHP() * 0.25), shipToRepair.getMaxHP() - shipToRepair.getHP())));
            UI.printLn(String.format("3: 50%% - %1$d Hull, for %1$dg", Math.min((int) (shipToRepair.getMaxHP() * 0.5), shipToRepair.getMaxHP() - shipToRepair.getHP())));
            UI.printLn(String.format("4: 100%% - %1$d Hull, for %1$dg", Math.min(shipToRepair.getMaxHP(), shipToRepair.getMaxHP() - shipToRepair.getHP())));

            UI.printLn("5: Exit");

            int selection = UI.userIntInput("", 1, 5);
            if (selection == 5) {
                return;
            }

            if (shipToRepair.getHP() == shipToRepair.getMaxHP()) {
                UI.printLn("The " + shipToRepair.getName() + " needs no repairs, it is shipshape and ready to sail!");

            }else if (selection == 4 && player.getCurrentGold() >= Math.min(shipToRepair.getMaxHP(), shipToRepair.getMaxHP() - shipToRepair.getHP())) {
                repairAndChargePlayer(shipToRepair, 1);

            } else if (selection == 3 && player.getCurrentGold() >= Math.min((int) (shipToRepair.getMaxHP() * 0.5), shipToRepair.getMaxHP() - shipToRepair.getHP())) {
                repairAndChargePlayer(shipToRepair, 0.5);

            } else if (selection == 2 && player.getCurrentGold() >= Math.min((int) (shipToRepair.getMaxHP() * 0.25), shipToRepair.getMaxHP() - shipToRepair.getHP())) {
                repairAndChargePlayer(shipToRepair, 0.25);

            } else if (selection == 1 && player.getCurrentGold() >= Math.min((int) (shipToRepair.getMaxHP() * 0.1), shipToRepair.getMaxHP() - shipToRepair.getHP())){
                repairAndChargePlayer(shipToRepair, 0.1);

            } else {
                UI.printLn("Are you pulling my leg? You don't have enough gold!", Console.TextColor.RED);
            }
        }
    }


    private void repairAndChargePlayer(Ship shipToRepair, double mult) {
        int adjustingValue = Math.min((int) (shipToRepair.getMaxHP() * mult), shipToRepair.getMaxHP() - shipToRepair.getHP());
        shipToRepair.setHP(shipToRepair.getHP() + adjustingValue);
        player.removeGold( adjustingValue);

        if (shipToRepair.getHP() == shipToRepair.getMaxHP()) {
            UI.printLn("The " + shipToRepair.getName() + " is fully repaired!");
        }
    }


    private void enterDrydock() {
        ((Shipyard)currentLocation).viewingDrydock();

        while (true) {
            PlayerAction action = selectFromActions();
            if (action == PlayerAction.EXIT) {
                ((Shipyard) currentLocation).leavingDrydock();
                return;
            }
            runActionFromSelection(action);
        }
    }


    private void switchShipMenu() {
        int shipIndex;
        Ship currentPlayerShip;
        while (true) {
            UI.displayHullAndGold(currentLocation.getLocationMessage(), player.getCurrentShip(), player.getCurrentGold());
            currentPlayerShip = player.getCurrentShip();

            shipIndex = chooseShipFromList("Select which of your docked ships you would like to switch over to:", shipyard.getPlayerShipsInDrydock(), true);

            if (shipIndex == shipyard.getPlayerShipsInDrydock().size() + 2) {
                return;
            } else if (shipIndex == shipyard.getPlayerShipsInDrydock().size() + 1) {
                displayShipsWithLongDescription = !displayShipsWithLongDescription;
            } else {
                switchShip(currentPlayerShip, shipyard.getPlayerShipsInDrydock().get(shipIndex-1));
                player.setCurrentShip(shipyard.getPlayerShipsInDrydock().get(shipIndex-1));
                shipyard.getPlayerShipsInDrydock().remove(shipIndex-1);
                shipyard.getPlayerShipsInDrydock().add(currentPlayerShip);
                player.updatePossibleBattleActions();
                UI.printLn("Successfully switched over to the " + player.getCurrentShip());
            }
        }
    }


    private void sellShips() {
        int shipIndex;
        while (true) {
            UI.displayHullAndGold(currentLocation.getLocationMessage(), player.getCurrentShip(), player.getCurrentGold());
            shipIndex = chooseShipFromList("Select which of your docked ships you would like to sell:", shipyard.getPlayerShipsInDrydock(), true);

            if (shipIndex == shipyard.getPlayerShipsInDrydock().size() + 2) {
                return;
            } else if (shipIndex == shipyard.getPlayerShipsInDrydock().size() + 1) {
                displayShipsWithLongDescription = !displayShipsWithLongDescription;
            } else {
                player.addGold(shipyard.getPlayerShipsInDrydock().get(shipIndex-1).getValue());
                UI.print("The " + shipyard.getPlayerShipsInDrydock().get(shipIndex-1).getName() + " has been sold for ");
                UI.printLn(shipyard.getPlayerShipsInDrydock().get(shipIndex-1).getValue() + "g", Console.TextColor.YELLOW);
                shipyard.getPlayerShipsInDrydock().remove(shipIndex-1);
            }
        }
    }



    private void visitMerchant() {
        currentLocation = merchant;
    }

    // Allows the player to buy items from the merchant's stock, with error checking for if their cargo is full or they lack sufficient gold
    private void buyItems() {
        do {
            UI.displayHullAndGold(currentLocation.getLocationMessage(), player.getCurrentShip(), player.getCurrentGold());
            int itemIndex = chooseItemFromList("Choose item to buy from the " + merchant.getLocationName() + ":", merchant.getItemsInStock());

            if (itemIndex == merchant.getItemsInStock().size() + 1) {
                return;
            }

            Item itemToBuy = merchant.getItemsInStock().get(itemIndex - 1);
            if (player.getCurrentShip().getCurrentCargo().size() == player.getCurrentShip().getMaxCargo()) {
                UI.printLn("The " + player.getCurrentShip().getName() + " cannot carry anymore Cargo, sell items to make space!", Console.TextColor.RED);

            } else if (player.getCurrentGold() >= itemToBuy.getValue()) {
                UI.print(itemToBuy.getRarity().toString(), itemToBuy.getRarity().getTextColor());
                UI.print(" " + itemToBuy.getName() + " bought for ");
                UI.printLn(itemToBuy.getValue() + "g", Console.TextColor.YELLOW);

                player.removeGold(itemToBuy.getValue());
                player.getCurrentShip().addCargo(itemToBuy);
                merchant.getItemsInStock().remove(itemToBuy);

            } else {
                UI.print("You don't have enough gold to buy that ", Console.TextColor.RED);
                UI.print(itemToBuy.getRarity().toString(), itemToBuy.getRarity().getTextColor());
                UI.printLn(" - " + itemToBuy.getName() + "!", Console.TextColor.RED);
            }
        } while (true);
    }


    private void sellItems() {
        do {
            UI.displayHullAndGold(currentLocation.getLocationMessage(), player.getCurrentShip(), player.getCurrentGold());
            int itemIndex = chooseItemFromList("Choose item to sell to the " + merchant.getLocationName() + ":", player.getCurrentShip().getCurrentCargo());

            if (itemIndex == player.getCurrentShip().getCurrentCargo().size() + 1) {
                return;
            }

            player.addGold(player.getCurrentShip().getCurrentCargo().get(itemIndex - 1).getValue());
            UI.printLn(player.getCurrentShip().sellCargoItem(player.getCurrentShip().getCurrentCargo().get(itemIndex - 1)));

        } while (true);
    }


    private void sellAllTreasures() {
        ArrayList<Item> itemsToSell = new ArrayList<>();
        for (Item item : player.getCurrentShip().getCurrentCargo()) {
            if (item instanceof Treasure) {
                player.addGold(item.getValue());
                itemsToSell.add(item);
            }
        }

        if (itemsToSell.isEmpty()) {
            UI.printLn("There are no Treasures in the Cargo hold to sell!", Console.TextColor.RED);
            return;
        }

        for (Item item : itemsToSell) {
            UI.printLn(player.getCurrentShip().sellCargoItem(item));
        }
    }
}