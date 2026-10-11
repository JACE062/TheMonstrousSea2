package edu.neumont.csc150.controllers;

import edu.neumont.csc150.models.Battle;
import edu.neumont.csc150.models.BattleMap;
import edu.neumont.csc150.models.Player;
import edu.neumont.csc150.models.attacksandattackables.ships.Corvette;
import edu.neumont.csc150.models.attacksandattackables.ships.Freighter;
import edu.neumont.csc150.models.attacksandattackables.ships.Ironclad;
import edu.neumont.csc150.models.attacksandattackables.ships.Ship;
import edu.neumont.csc150.models.enums.RarityLevel;
import edu.neumont.csc150.models.items.weapons.shipweapons.ShipWeapon;
import edu.neumont.csc150.models.locations.*;
import edu.neumont.csc150.views.Console;
import edu.neumont.csc150.views.UI;

import java.util.ArrayList;

public class GameController {
    Battle firstBattle = BattleMap.battleMap[0][0];
    Battle nextBattle = firstBattle;
    boolean closeGameSelected = false;
    boolean firstRun = true;
    int captainsLost = 0;

    Ship startingShip;
    Player player = new Player("Captain");
    Merchant merchant = new Merchant("Harpoon & Helm", player);
    Shipyard shipyard = new Shipyard("Ironforged Foundry", player);
    Port port = new Port("Hunter's Respite", player, merchant, shipyard);
    RestArea restArea = new RestArea(player, port);

    LocationController locationController = new LocationController(player, restArea);
    BattleController battleController = new BattleController(player, locationController);



    public void run() {
        UI.playIntro();
        newCaptainAndShipSelection();
        UI.printLn(player.getCurrentCaptain() + " looks out onto the Sea as The " + player.getCurrentShip().getName() + " pulls away from the dock, the Hunt has begun...");
        do {
            player.addGold(25);

            runGameUntilPlayerDies();

            runPostDeathScreen();

        } while (!closeGameSelected);

        Console.close();
    }


    public void runGameUntilPlayerDies() {
        do {
            nextBattle.setBattleDefeated(battleController.runBattle(nextBattle));

            if (nextBattle.isBattleDefeated() && player.isAlive()) {
                nextBattle = BattleMap.getNextBattle();
                locationController.runLocation(restArea);
            } else if (battleController.battleFled && player.isAlive()) {
                merchant.refreshStock();
                shipyard.refreshShipsForSale();
                BattleMap.resetMap();
                locationController.runLocation(port);
            }
            if (locationController.currentLocation == port) {
                nextBattle = BattleMap.battleMap[0][0];
            }

        } while (player.isAlive());
    }


    // Shows stats for this run, as well as total stats for all of the runs so far, then allows the player to decide whether to continue or exit
    public void runPostDeathScreen() {
        UI.printLn("\n" + player.getCurrentCaptain() + " has met a watery end at the hands of the sea, but their accomplishments shall not be forgotten.");
        UI.printLn("\nSea Monsters Defeated: " + player.getSeaMonstersDefeatedThisLife());
        UI.printLn("Highest Battle Difficulty Reached: " + player.getHighestDifficultyThisLife());

        Ship previousShip = player.getCurrentShip();

        player.playerDies();
        captainsLost++;

        if (firstRun) {
            firstRun = false;
        } else {
            UI.printLn("");
            UI.printLn("Total Sea Monsters Defeated: " + player.getTotalSeaMonstersDefeated());
            UI.printLn("Overall Highest Difficulty Reached: " + player.getHighestDifficulty());

        }
        UI.printLn("Captains Lost: " + captainsLost);
        UI.waitSeconds(4);
        UI.printLn("\n\n");


        UI.printLn("Will your child continue your vendetta against the Sea?");
        if(UI.confirmOrDeny("They shall avenge me...", "No more. Let the Sea keep its monsters. The hunt dies with me.")) {

            newCaptainAndShipSelection();
            if (player.getCurrentCaptain().equalsIgnoreCase("Davy Jones")) {
                player.setAlive(true);
                return;
            }

            if (previousShip instanceof Freighter) {
                UI.printLn("The safe stash aboard the " + previousShip.getName() + " was found, and its contents have now been passed to you.");
                battleController.pickUpDroppedLoot("Not all of the Cargo fits onto The " + player.getCurrentShip() + ", would you like to drop Cargo to make room?", player.getCargoForNewShip());
                player.getCargoForNewShip().clear();
            }

            UI.printLn(player.getCurrentCaptain() + " looks out onto the Sea, The " + player.getCurrentShip().getName() + " pulls away from the dock, the Hunt continues with a new generation...");

            player.setAlive(true);
            BattleMap.resetMap();
            nextBattle = BattleMap.battleMap[0][0];
        } else {
            closeGameSelected = true;
            UI.writeStringDramatically("The Undying Sea has prevailed, but no longer shall the Hunt consume your lineage...", 0.12, true);
        }
    }


    // Runs the selection of a new captain name as well as ship, so that the player can continue playing after each death
    public void newCaptainAndShipSelection() {
        boolean nameConfirmed = false;
        String potentialName = "";
        while (!nameConfirmed) {
            if (firstRun) {
                potentialName = UI.userStringInput("What shall your Captain be named?", false);
            } else {
                potentialName = UI.userStringInput("What shall your heir be named?", false);
            }
            UI.printLn("Your Captain is to be named " + potentialName);
            if (UI.confirmOrDeny("Yes, it is a noble name!", "On second thought...")) {
                player.setCurrentCaptain(potentialName);
                nameConfirmed = true;
            }
            UI.printLn("");
        }

        if(potentialName.equalsIgnoreCase("Davy Jones")) {
            runOPShipAgainstFinalBoss();
            return;
        }

        if (firstRun) {
            startingShip = new Ship("Well-worn Ship", 1, 400, 10, 100, 20, 7);
            locationController.promptForShipRenaming(startingShip);
            player.setCurrentShip(startingShip);
        } else {
            ArrayList<Ship> shipsToOfferNewCaptain = new ArrayList<>();
            shipsToOfferNewCaptain.add(new Ship(1));
            shipsToOfferNewCaptain.add(new Freighter(1));
            shipsToOfferNewCaptain.add(new Ironclad(1));
            shipsToOfferNewCaptain.add(new Corvette(1));

            locationController.displayShipsWithLongDescription = true;
            int shipIndex = locationController.chooseShipFromList("What vessel shall " + player.getCurrentCaptain() + " helm?", shipsToOfferNewCaptain, false);
            locationController.promptForShipRenaming(shipsToOfferNewCaptain.get(shipIndex-1));


            player.setCurrentShip(shipsToOfferNewCaptain.get(shipIndex-1));
        }
        ShipWeapon startingCannon1 = ItemGenerator.getShipWeapon(0, RarityLevel.COMMON, 1);
        ShipWeapon startingCannon2 = ItemGenerator.getShipWeapon(0, RarityLevel.COMMON, 1);

        player.getCurrentShip().addCargo(startingCannon1);
        player.getCurrentShip().addCargo(startingCannon2);
        player.getCurrentShip().equipWeapon(startingCannon1);
        player.getCurrentShip().equipWeapon(startingCannon2);
    }


    public void runOPShipAgainstFinalBoss() {
        startingShip = new Ironclad("Flying Dutchman", 4, 1600, 18, 300, 25, 50, 8, 8);
        player.setCurrentShip(startingShip);

        ShipWeapon cannon1 = ItemGenerator.getShipWeapon(0, RarityLevel.LEGENDARY, 4);
        ShipWeapon cannon2 = ItemGenerator.getShipWeapon(0, RarityLevel.LEGENDARY, 4);
        ShipWeapon cannon3 = ItemGenerator.getShipWeapon(0, RarityLevel.LEGENDARY, 4);
        ShipWeapon cannon4 = ItemGenerator.getShipWeapon(0, RarityLevel.LEGENDARY, 4);
        ShipWeapon cannon5 = ItemGenerator.getShipWeapon(0, RarityLevel.LEGENDARY, 4);
        ShipWeapon cannon6 = ItemGenerator.getShipWeapon(0, RarityLevel.LEGENDARY, 4);
        ShipWeapon cannon7 = ItemGenerator.getShipWeapon(0, RarityLevel.LEGENDARY, 4);
        ShipWeapon cannon8 = ItemGenerator.getShipWeapon(0, RarityLevel.LEGENDARY, 4);

        ShipWeapon bladeLauncher1 = ItemGenerator.getShipWeapon(2, RarityLevel.LEGENDARY, 4);
        ShipWeapon bladeLauncher2 = ItemGenerator.getShipWeapon(2, RarityLevel.LEGENDARY, 4);
        ShipWeapon bladeLauncher3 = ItemGenerator.getShipWeapon(2, RarityLevel.LEGENDARY, 4);
        ShipWeapon bladeLauncher4 = ItemGenerator.getShipWeapon(2, RarityLevel.LEGENDARY, 4);
        ShipWeapon bladeLauncher5 = ItemGenerator.getShipWeapon(2, RarityLevel.LEGENDARY, 4);
        ShipWeapon bladeLauncher6 = ItemGenerator.getShipWeapon(2, RarityLevel.LEGENDARY, 4);

        ShipWeapon lightningRailgun1 = ItemGenerator.getShipWeapon(3, RarityLevel.LEGENDARY, 4);
        ShipWeapon lightningRailgun2 = ItemGenerator.getShipWeapon(3, RarityLevel.LEGENDARY, 4);

        ShipWeapon flamethrower1 = ItemGenerator.getShipWeapon(4, RarityLevel.LEGENDARY, 4);
        ShipWeapon flamethrower2 = ItemGenerator.getShipWeapon(4, RarityLevel.LEGENDARY, 4);




        startingShip.addCargo(cannon1);
        startingShip.addCargo(cannon2);
        startingShip.addCargo(cannon3);
        startingShip.addCargo(cannon4);
        startingShip.addCargo(cannon5);
        startingShip.addCargo(cannon6);
        startingShip.addCargo(cannon7);
        startingShip.addCargo(cannon8);

        startingShip.addCargo(bladeLauncher1);
        startingShip.addCargo(bladeLauncher2);
        startingShip.addCargo(bladeLauncher3);
        startingShip.addCargo(bladeLauncher4);
        startingShip.addCargo(bladeLauncher5);
        startingShip.addCargo(bladeLauncher6);


        startingShip.addCargo(lightningRailgun1);
        startingShip.addCargo(lightningRailgun2);

        startingShip.addCargo(flamethrower1);
        startingShip.addCargo(flamethrower2);

        startingShip.equipWeapon(cannon1);
        startingShip.equipWeapon(cannon2);
        startingShip.equipWeapon(cannon3);
        startingShip.equipWeapon(cannon4);
        startingShip.equipWeapon(cannon5);
        startingShip.equipWeapon(cannon6);
        startingShip.equipWeapon(cannon7);
        startingShip.equipWeapon(cannon8);


        startingShip.equipWeapon(bladeLauncher1);
        startingShip.equipWeapon(bladeLauncher2);
        startingShip.equipWeapon(bladeLauncher3);
        startingShip.equipWeapon(bladeLauncher4);
        startingShip.equipWeapon(bladeLauncher5);
        startingShip.equipWeapon(bladeLauncher6);

        startingShip.equipWeapon(lightningRailgun1);
        startingShip.equipWeapon(lightningRailgun2);

        startingShip.equipWeapon(flamethrower1);
        startingShip.equipWeapon(flamethrower2);


        nextBattle = BattleMap.battleMap[3][4];

        BattleMap.setCurrentRow(3);
        BattleMap.setCurrentCol(4);
    }
}
