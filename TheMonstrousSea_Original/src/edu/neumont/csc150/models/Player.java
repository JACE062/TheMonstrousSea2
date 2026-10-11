package edu.neumont.csc150.models;

import edu.neumont.csc150.models.attacksandattackables.ships.Corvette;
import edu.neumont.csc150.models.attacksandattackables.ships.Freighter;
import edu.neumont.csc150.models.attacksandattackables.ships.Ironclad;
import edu.neumont.csc150.models.attacksandattackables.ships.Ship;
import edu.neumont.csc150.models.enums.PlayerAction;
import edu.neumont.csc150.models.items.Item;

import java.util.ArrayList;

public class Player {
    private String currentCaptain;
    private Ship currentShip;
    private int currentGold;
    private int highestDifficultyThisLife;
    private int highestDifficulty;
    private int seaMonstersDefeatedThisLife;
    private int totalSeaMonstersDefeated;
    private ArrayList<PlayerAction> possibleBattleActions = new ArrayList<>();
    private ArrayList<Item> cargoForNewShip = new ArrayList<>();

    private boolean alive = true;

    public String getCurrentCaptain() {
        return currentCaptain;
    }

    public void setCurrentCaptain(String currentCaptain) {
        this.currentCaptain = currentCaptain;
    }

    public Ship getCurrentShip() {
        return currentShip;
    }

    public void setCurrentShip(Ship currentShip) {
        this.currentShip = currentShip;
    }

    public int getCurrentGold() {
        return currentGold;
    }

    public void setCurrentGold(int currentGold) {
        this.currentGold = currentGold;
    }

    public void removeGold(int goldToRemove) {
        setCurrentGold(getCurrentGold() - goldToRemove);
    }

    public void addGold(int goldToAdd) {
        setCurrentGold(getCurrentGold() + goldToAdd);
    }

    public int getHighestDifficultyThisLife() {
        return highestDifficultyThisLife;
    }

    public void setHighestDifficultyThisLife(int highestDifficultyThisLife) {
        if(highestDifficultyThisLife > this.highestDifficultyThisLife) {
            this.highestDifficultyThisLife = highestDifficultyThisLife;
        }
    }

    public int getHighestDifficulty() {
        return highestDifficulty;
    }

    private void setHighestDifficulty(int highestDifficulty) {
        if(highestDifficulty > this.highestDifficulty) {
            this.highestDifficulty = highestDifficulty;
        }
    }

    public int getSeaMonstersDefeatedThisLife() {
        return seaMonstersDefeatedThisLife;
    }

    public void setSeaMonstersDefeatedThisLife(int seaMonstersDefeatedThisLife) {
        this.seaMonstersDefeatedThisLife = seaMonstersDefeatedThisLife;
    }

    public void incrementSeaMonstersDefeatedThisLife() {
        this.seaMonstersDefeatedThisLife++;
    }

    public int getTotalSeaMonstersDefeated() {
        return totalSeaMonstersDefeated;
    }

    public void setTotalSeaMonstersDefeated(int totalSeaMonstersDefeated) {
        this.totalSeaMonstersDefeated = totalSeaMonstersDefeated;
    }

    public ArrayList<PlayerAction> getPossibleBattleActions() {
        return possibleBattleActions;
    }

    public void setPossibleBattleActions(ArrayList<PlayerAction> possibleBattleActions) {
        this.possibleBattleActions = possibleBattleActions;
    }

    public void addPossibleBattleAction(PlayerAction playerAction) {
        possibleBattleActions.add(playerAction);
    }

    public ArrayList<Item> getCargoForNewShip() {
        return cargoForNewShip;
    }

    public void setCargoForNewShip(ArrayList<Item> cargoForNewShip) {
        this.cargoForNewShip = cargoForNewShip;
    }

    public boolean isAlive() {
        return alive;
    }

    public void setAlive(boolean isAlive) {
        this.alive = isAlive;
    }

    // updates the available actions for battles depending on what type of ship the player currently has
    public void updatePossibleBattleActions() {
        possibleBattleActions.clear();
        addPossibleBattleAction(PlayerAction.ATTACK);
        addPossibleBattleAction(PlayerAction.USE_CONSUMABLE);
        addPossibleBattleAction(PlayerAction.FLEE);

        if (currentShip instanceof Ironclad) {
            addPossibleBattleAction(PlayerAction.FORTIFY);
        } else if (currentShip instanceof Corvette) {
            addPossibleBattleAction(PlayerAction.EXECUTE_EVASIVE_MANEUVERS);
        }
    }


    public Player(String captain) {
        setCurrentCaptain(captain);
        updatePossibleBattleActions();
    }

    // Sets fields to null or zero, adds monsters defeated this life to the total, and changes the highest difficulty reached stat if it exceeds the previous highest difficulty
    // Checks if the current ship is a Freighter and saves a fraction of the current cargo and gold for the next run to start with if so
    public void playerDies() {
        if (getCurrentShip() instanceof Freighter) {
            setCargoForNewShip(((Freighter) getCurrentShip()).safeCargoStash());
            setCurrentGold((int) ( 0.05 * getCurrentGold()));
        } else {
            setCurrentGold(0);
        }

        setHighestDifficulty(getHighestDifficultyThisLife());
        setTotalSeaMonstersDefeated(getTotalSeaMonstersDefeated() + getSeaMonstersDefeatedThisLife());
        setHighestDifficultyThisLife(0);
        setSeaMonstersDefeatedThisLife(0);
        setAlive(false);
        setCurrentCaptain(null);
        setCurrentShip(null);
    }
}
