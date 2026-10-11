package edu.neumont.csc150.models.locations;

import edu.neumont.csc150.models.Player;
import edu.neumont.csc150.models.enums.PlayerAction;

public class Port extends GameLocation {
    private static final String PORT_MESSAGE = "The docks of Hunter's Respite welcome you to various shops and activities for your crew.";

    private Merchant merchant;
    private Shipyard shipyard;

    public Merchant getMerchant() {
        return merchant;
    }

    public void setMerchant(Merchant merchant) {
        this.merchant = merchant;
    }

    public Shipyard getShipyard() {
        return shipyard;
    }

    public void setShipyard(Shipyard shipyard) {
        this.shipyard = shipyard;
    }


    public Port(String locationName, Player currentPlayer, Merchant merchant, Shipyard shipyard) {
        super(locationName, currentPlayer, PORT_MESSAGE);

        setMerchant(merchant);
        setShipyard(shipyard);

        setStandardActions(new PlayerAction[]{PlayerAction.VISIT_MERCHANT, PlayerAction.VISIT_SHIPYARD, PlayerAction.VIEW_MAP, PlayerAction.VENTURE_OUT_TO_SEA});
        setAvailableActions(getStandardActions());
    }
}
