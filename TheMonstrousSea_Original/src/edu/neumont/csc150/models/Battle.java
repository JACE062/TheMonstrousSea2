package edu.neumont.csc150.models;

import edu.neumont.csc150.models.attacksandattackables.Attackable;
import edu.neumont.csc150.models.attacksandattackables.seamonsters.*;
import edu.neumont.csc150.models.attacksandattackables.ships.Ship;


public class Battle {
    private int battleDifficultyLevel;
    private int battleRoundCounter;
    private Ship shipInBattle;
    private SeaMonster seaMonsterInBattle;
    private boolean battleDefeated;

    public int getBattleDifficultyLevel() {
        return battleDifficultyLevel;
    }

    public void setBattleDifficultyLevel(int battleDifficultyLevel) {
        this.battleDifficultyLevel = battleDifficultyLevel;
    }

    public int getBattleRoundCounter() {
        return battleRoundCounter;
    }

    public void setBattleRoundCounter(int battleRoundCounter) {
        this.battleRoundCounter = battleRoundCounter;
    }

    public void increaseBattleRoundCounter() {
        battleRoundCounter++;
    }

    public Ship getShipInBattle() {
        return shipInBattle;
    }

    public void setShipInBattle(Ship shipInBattle) {
        this.shipInBattle = shipInBattle;
    }

    public SeaMonster getSeaMonsterInBattle() {
        return seaMonsterInBattle;
    }

    public void setSeaMonsterInBattle(SeaMonster seaMonsterInBattle) {
        this.seaMonsterInBattle = seaMonsterInBattle;
    }

    public boolean isBattleDefeated() {
        return battleDefeated;
    }

    public void setBattleDefeated(boolean battleDefeated) {
        this.battleDefeated = battleDefeated;
    }

    public Battle(int battleDifficultyLevel, SeaMonster seaMonsterInBattle) {
        setBattleDifficultyLevel(battleDifficultyLevel);
        setBattleRoundCounter(0);
        setSeaMonsterInBattle(seaMonsterInBattle);
    }

    public Battle(int battleDifficultyLevel) {
        setBattleDifficultyLevel(battleDifficultyLevel);
        setBattleRoundCounter(0);


        setSeaMonsterInBattle(randomSeaMonster(battleDifficultyLevel));
    }

    // Generates a random SeaMonster for the battle based on the difficulty
    // Crustaceans are too difficult for the very beginning of the game, so they can't show up until difficulty level 2
    private SeaMonster randomSeaMonster(int level) {
        if (level == 1) {
            return switch(Attackable.diceRoll(1,4)) {
                case 1 -> new Shark(level);
                case 2 -> new Serpent(level);
                case 3 -> new Jellyfish(level);
                case 4 -> new Squid(level);
                default -> new Shark(level);
            };
        } else {
            return switch (Attackable.diceRoll(1, 5)) {
                case 1 -> new Shark(level);
                case 2 -> new Serpent(level);
                case 3 -> new Jellyfish(level);
                case 4 -> new Squid(level);
                case 5 -> new Crustacean(level);
                default -> new Shark(level);
            };
        }
    }

    // Emoji of the current monster for the battleMap display
    public String getMonsterEmoji() {
        SeaMonster sm = getSeaMonsterInBattle();
        if (isBattleDefeated()) {
            return "☠️";
        } else
            if (sm instanceof Shark) {
            return "\uD83E\uDD88";
        } else if (sm instanceof Serpent) {
            return "\uD83D\uDC0D";
        } else if (sm instanceof Crustacean) {
            return "\uD83E\uDD9E";
        } else if (sm instanceof Squid) {
            return "\uD83E\uDD91";
        } else if (sm instanceof Jellyfish) {
            return "\uD83E\uDEBC";
        }
        return "";
    }

}
