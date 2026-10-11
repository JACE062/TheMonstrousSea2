package edu.neumont.csc150.models.locations;

import edu.neumont.csc150.models.Player;
import edu.neumont.csc150.models.enums.PlayerAction;

public class RestArea extends GameLocation {
    private static final String REST_AREA_MESSAGE = "The Sea is calm here, rest and refit while you have the chance.";

    private Port homePort;

    public Port getHomePort() {
        return homePort;
    }

    public void setHomePort(Port homePort) {
        this.homePort = homePort;
    }


    public RestArea(Player currentPlayer, Port homePort) {
        super("Rest on the open Sea", currentPlayer, REST_AREA_MESSAGE);

        setHomePort(homePort);

        setStandardActions(new PlayerAction[]{PlayerAction.CONTINUE_TO_NEXT_BATTLE, PlayerAction.ADJUST_WEAPONS, PlayerAction.DROP_CARGO, PlayerAction.RETURN_TO_PORT});
        setAvailableActions(getStandardActions());
    }
}
