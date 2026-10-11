package edu.neumont.csc150.models.locations;

import edu.neumont.csc150.models.Player;
import edu.neumont.csc150.models.enums.PlayerAction;

import java.util.ArrayList;
import java.util.List;

public abstract class GameLocation {
    private String locationName;
    private Player currentPlayer;
    private ArrayList<PlayerAction> availableActions = new ArrayList<>();
    private final PlayerAction[] ADJUSTING_WEAPONS_ACTIONS = {PlayerAction.EQUIP_WEAPONS, PlayerAction.UNEQUIP_WEAPONS, PlayerAction.EXIT};
    private PlayerAction[] standardActions;
    private boolean inSubMenu;

    private String locationMessage;


    public String getLocationName() {
        return locationName;
    }

    private void setLocationName(String locationName) {
        this.locationName = locationName;
    }

    public Player getCurrentPlayer() {
        return currentPlayer;
    }

    private void setCurrentPlayer(Player currentPlayer) {
        this.currentPlayer = currentPlayer;
    }


    public ArrayList<PlayerAction> getAvailableActions() {
        return availableActions;
    }

    public void setAvailableActions(PlayerAction[] availableActions) {
        this.availableActions.clear();
        this.availableActions.addAll(List.of(availableActions));
    }


    private PlayerAction[] getADJUSTING_WEAPONS_ACTIONS() {
        return ADJUSTING_WEAPONS_ACTIONS;
    }

    public PlayerAction[] getStandardActions() {
        return standardActions;
    }

    protected void setStandardActions(PlayerAction[] standardActions) {
        this.standardActions = standardActions;
    }

    public boolean isInSubMenu() {
        return inSubMenu;
    }

    public void setInSubMenu(boolean inSubMenu) {
        this.inSubMenu = inSubMenu;
    }

    private void setLocationMessage(String locationMessage) {
        this.locationMessage = locationMessage;
    }

    public String getLocationMessage() {
        return locationMessage;
    }


    public GameLocation(String locationName, Player currentPlayer, String locationMessage) {
        setLocationName(locationName);
        setCurrentPlayer(currentPlayer);
        setLocationMessage(locationMessage);
    }

    // String representation of the actions available, for use with the action selection menus
    public String stringOfAvailableActions() {
        StringBuilder sb = new StringBuilder();
        int i = 1;
        for (PlayerAction playerAction : getAvailableActions()) {
            sb.append(i).append(": ").append(playerAction).append("\n");
            i++;
        }
        return sb.toString();
    }

    public void enterWeaponAdjusting() {
        setAvailableActions(getADJUSTING_WEAPONS_ACTIONS());
        setInSubMenu(true);
    }

    public void leaveWeaponAdjusting() {
        setAvailableActions(getStandardActions());
        setInSubMenu(false);
    }
}