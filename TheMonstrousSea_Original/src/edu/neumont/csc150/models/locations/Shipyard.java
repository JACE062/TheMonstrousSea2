package edu.neumont.csc150.models.locations;

import edu.neumont.csc150.controllers.ItemGenerator;
import edu.neumont.csc150.models.Player;
import edu.neumont.csc150.models.attacksandattackables.ships.Corvette;
import edu.neumont.csc150.models.attacksandattackables.ships.Freighter;
import edu.neumont.csc150.models.attacksandattackables.ships.Ironclad;
import edu.neumont.csc150.models.attacksandattackables.ships.Ship;
import edu.neumont.csc150.models.enums.PlayerAction;

import java.util.ArrayList;

public class Shipyard extends GameLocation {
    private static final String SHIPYARD_MESSAGE = "Ironforged Foundry offers the top-of-the line in naval vessels";

    private ArrayList<Ship> shipsForSale = new ArrayList<>();
    private ArrayList<Ship> playerShipsInDrydock = new ArrayList<>();
    private final PlayerAction[] drydockActions = {PlayerAction.SELL_SHIPS, PlayerAction.SWITCH_SHIP, PlayerAction.EXIT};
    private boolean viewingDrydock = false;

    public ArrayList<Ship> getShipsForSale() {
        return shipsForSale;
    }

    private void setShipsForSale(ArrayList<Ship> shipsForSale) {
        this.shipsForSale = shipsForSale;
    }

    private void addShipForSale(Ship ship) {
        if (!shipsForSale.contains(ship)) {
            shipsForSale.add(ship);
        }
    }

    public ArrayList<Ship> getPlayerShipsInDrydock() {
        return playerShipsInDrydock;
    }

    private void setPlayerShipsInDrydock(ArrayList<Ship> playerShipsInDrydock) {
        this.playerShipsInDrydock = playerShipsInDrydock;
    }

    public void addPlayerShipInDrydock(Ship ship) {
        if (!playerShipsInDrydock.contains(ship)) {
            playerShipsInDrydock.add(ship);
        }
    }



    public Shipyard(String locationName, Player currentPlayer) {
        super(locationName, currentPlayer, SHIPYARD_MESSAGE);

        setStandardActions(new PlayerAction[]{PlayerAction.BUY_SHIPS, PlayerAction.ENTER_DRYDOCK, PlayerAction.REPAIR_CURRENT_SHIP, PlayerAction.EXIT});
        setAvailableActions(getStandardActions());
    }

    // gives access in and out of the drydock submenu by changing the available actions
    public void viewingDrydock() {
        setAvailableActions(drydockActions);
        setInSubMenu(true);
        viewingDrydock = true;
    }

    public void leavingDrydock() {
        setAvailableActions(getStandardActions());
        setInSubMenu(false);
        viewingDrydock = false;
    }

    @Override
    public void leaveWeaponAdjusting() {
        if (viewingDrydock) {
            setAvailableActions(drydockActions);
        } else {
            super.leaveWeaponAdjusting();
        }
    }


    // Refreshes the ships in the shipyard's sell menu
    public void refreshShipsForSale() {
        getShipsForSale().clear();
        for (int i = 0; i < ItemGenerator.rand.nextInt(3,5); i++) {
            Ship newShip;
            int shipLevelToGenerate = getCurrentPlayer().getHighestDifficultyThisLife() + ItemGenerator.rand.nextInt(2);
            newShip = switch (ItemGenerator.rand.nextInt(4)) {
                case 1 -> new Freighter(shipLevelToGenerate);
                case 2 -> new Ironclad(shipLevelToGenerate);
                case 3 -> new Corvette(shipLevelToGenerate);
                default -> new Ship(shipLevelToGenerate);
            };
            addShipForSale(newShip);
        }
    }
}
