package edu.neumont.csc150.models.enums;

public enum PlayerAction {
    ATTACK("Attack"),
    USE_CONSUMABLE("Use Consumable"),
    FLEE("Flee"),

    EXECUTE_EVASIVE_MANEUVERS("Execute Evasive Maneuvers"),
    FORTIFY("Fortify"),


    RETURN_TO_PORT("Return to Port"),
    CONTINUE_TO_NEXT_BATTLE("Continue to next Battle"),
    DROP_CARGO("Drop Cargo"),

    ADJUST_WEAPONS("Adjust Weapons"),
    EQUIP_WEAPONS("Equip Weapons"),
    UNEQUIP_WEAPONS("Unequip Weapons"),


    VISIT_MERCHANT("Visit Merchant"),
    VISIT_SHIPYARD("Visit Shipyard"),
    VIEW_MAP("View Map"),
    VENTURE_OUT_TO_SEA("Venture out to Sea"),


    REPAIR_CURRENT_SHIP("Repair Current Ship"),
    UPGRADE_CURRENT_SHIP("Upgrade Current Ship"),
    BUY_SHIPS("Buy Ships"),

    ENTER_DRYDOCK("Enter Drydock"),
    SELL_SHIPS("Sell Ships"),
    SWITCH_SHIP("Switch Ship"),

    EXIT("Exit"),


    BUY_ITEMS("Buy Items"),
    SELL_ITEMS("Sell Items"),
    SELL_ALL_TREASURE("Sell All Treasure"),;

    private final String prettyString;

    PlayerAction(String prettyString) {
        this.prettyString = prettyString;
    }

    @Override
    public String toString() {
        return prettyString;
    }
}
