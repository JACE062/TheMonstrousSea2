package edu.neumont.csc150.models.locations;

import edu.neumont.csc150.controllers.ItemGenerator;
import edu.neumont.csc150.models.Player;
import edu.neumont.csc150.models.enums.PlayerAction;
import edu.neumont.csc150.models.items.Item;

import java.util.ArrayList;

public class Merchant extends GameLocation {
    private static final String MERCHANT_MESSAGE = "The Harpoon & Helm invites you to peruse their wares.";

    private ArrayList<Item> itemsInStock = new ArrayList<>();

    public ArrayList<Item> getItemsInStock() {
        return itemsInStock;
    }

    private void setItemsInStock(ArrayList<Item> itemsInStock) {
        this.itemsInStock = itemsInStock;
    }

    private void addItemToStock(Item item) {
        itemsInStock.add(item);
    }


    public Merchant(String locationName, Player currentPlayer) {
        super(locationName, currentPlayer, MERCHANT_MESSAGE);

        setStandardActions(new PlayerAction[]{PlayerAction.BUY_ITEMS, PlayerAction.SELL_ITEMS, PlayerAction.SELL_ALL_TREASURE, PlayerAction.ADJUST_WEAPONS, PlayerAction.EXIT});
        setAvailableActions(getStandardActions());
    }



    // Clears the current stock of items and generates 3-5 random items to fill the stock
    // Has a 50% to generate an item of the highestDifficultyLevelReached, and a 25% chance each to generate one level higher or lower
    public void refreshStock() {
        getItemsInStock().clear();
        for (int i = 0; i < ItemGenerator.rand.nextInt(3,6); i++) {
            boolean bool1 = ItemGenerator.rand.nextBoolean();
            boolean bool2 = ItemGenerator.rand.nextBoolean();

            if (bool1 && bool2) {
                addItemToStock(ItemGenerator.randomNonTreasureItem(getCurrentPlayer().getHighestDifficultyThisLife() + 1));
            } else if (bool1 || bool2) {
                addItemToStock(ItemGenerator.randomNonTreasureItem(getCurrentPlayer().getHighestDifficultyThisLife()));
            } else {
                addItemToStock(ItemGenerator.randomNonTreasureItem(Math.max(getCurrentPlayer().getHighestDifficultyThisLife() - 1, 1)));

            }
        }
    }
}
