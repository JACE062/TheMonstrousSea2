package edu.neumont.csc150.models;

import edu.neumont.csc150.models.attacksandattackables.seamonsters.Squid;

public class BattleMap {
    public static String KrakenArt = "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣀⣀⣀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀\n" +
                                     "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣶⣿⣿⣿⣿⣿⣿⣿⣿⣷⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀\n" +
                                     "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⠀⠀⠀⢠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀\n" +
                                     "⠀⠀⠀⠀⠀⠀⠀⠀⢠⣾⡿⠿⢿⣿⣷⣠⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡆⣷⣠⣴⣶⣶⣤⡀⠀⠀⠀⠀⠀⠀⠀⠀\n" +
                                     "⠀⠀⠀⠀⠀⠀⠀⠀⠻⢿⡄⠀⠀⠹⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⣿⣿⣟⠉⢹⣿⣷⠀⠀⠀⠀⠀⠀⠀⠀\n" +
                                     "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠛⠿⠿⠿⠋⠀⠀⠀⠀⠀⠀⠀⠀\n" +
                                     "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⡿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠉⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀\n" +
                                     "⠀⠀⠀⢀⣀⣀⠀⠀⠀⠀⠀⣰⣿⣿⡟⠁⠘⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠃⠀⠈⢿⣿⣷⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀\n" +
                                     "⠀⣴⣾⣿⣿⣿⣿⣶⡀⢀⣾⣿⣿⠋⠀⠀⠀⠈⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠃⠀⠀⠀⠀⠹⣿⣿⣦⠀⠀⠀⠀⠀⠀⠀⠀⠀\n" +
                                     "⢸⣿⡁⠀⠀⢀⣿⣿⢇⣾⣿⣿⠃⠀⠀⠀⠀⠀⠀⣿⡈⠙⢿⣿⣿⣿⠿⠋⢩⡇⠀⠀⠀⠀⠀⠀⠙⣿⣿⣇⠀⠀⠀⠀⠀⠀⠀⠀\n" +
                                     "⠈⠛⠛⣠⣴⣿⡿⠋⢸⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⣿⣿⣶⣾⣿⣿⣿⣷⣶⣿⡇⠀⠀⠀⠀⠀⠀⠀⣻⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀\n" +
                                     "⠀⣠⣾⣿⡿⠋⠀⠀⢻⣿⣿⣷⡀⠀⠀⠀⠀⣠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⡀⠀⠀⠀⠀⢠⣿⣿⣏⣠⣤⣶⣤⠀⠀⠀⠀\n" +
                                     "⢰⣿⣿⣟⠀⠀⠀⠀⠘⢿⣿⣿⣿⣷⣶⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣤⣤⣴⣿⣿⣿⣿⠋⠀⠀⠀⠀⠀⠀⠀\n" +
                                     "⢸⣿⣿⣿⣦⣄⣀⠀⠀⠀⠉⠙⠛⠛⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠿⠛⠉⢻⣿⣄⠀⠀⠀⠀⠀⠀⠀\n" +
                                     "⠀⠙⠿⣿⣿⣿⣿⣿⣿⣿⣶⣶⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⡀⠀⠀⠀⠈⢿⣿⣶⣄⠀⠀⠀⠀⠀\n" +
                                     "⠀⠀⠀⠀⠈⠉⠉⠙⠛⠛⠛⠛⠛⣿⣿⣿⣿⠟⢋⣿⣿⣿⡿⠋⠙⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣆⠀⠀⠀⠀⠙⢿⣿⣧⡀⠀⠀⠀\n" +
                                     "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣿⠟⠁⠀⣿⣿⣿⠟⠀⠀⢀⣿⣿⣿⡿⢿⣿⣿⣿⣿⣿⣿⣆⠀⠀⠀⠀⠈⢿⣿⣷⠀⠀⠀\n" +
                                     "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⣿⣿⠏⠀⠀⢸⣿⣿⣿⠀⠀⠀⢸⣿⣿⣿⠀⠈⢻⣿⣿⣿⢿⣿⣿⣦⡀⠀⠀⠀⣸⣿⣿⠀⣀⡄\n" +
                                     "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⡟⠀⠀⠀⠸⣿⣿⣿⠀⠀⠀⢻⣿⣿⣿⠀⠀⠀⢻⣿⣿⡆⠹⢿⣿⣿⣶⣶⣾⣿⣿⣿⣿⠋⠀\n" +
                                     "⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⣿⣿⡿⠁⠀⠀⠀⠀⢿⣿⣿⡆⠀⠀⠸⣿⣿⣿⡄⠀⠀⠀⢿⣿⣿⠀⠀⠙⠛⠿⠿⠿⠛⠋⢸⣿⠀⠀\n" +
                                     "⠀⠀⠀⠀⠀⠀⣠⣴⣿⣿⡿⠛⠁⠀⠀⠀⠀⠀⠘⣿⣿⣿⠀⠀⠀⣿⣿⣿⡇⠀⠀⠀⢸⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⠀⠀\n" +
                                     "⠀⠀⠀⢠⣶⣿⣿⠿⠋⠁⠒⠛⢻⣷⠀⠀⠀⠀⠀⢹⣿⣿⡇⠀⣠⣿⣿⣿⢃⣴⣿⠟⠛⢿⣿⣿⡄⠀⠀⠀⠀⠀⠀⢠⣿⣿⠀⠀\n" +
                                     "⠀⠀⢰⣿⣿⠟⠁⠀⠀⠀⠀⢀⣾⡟⠀⠀⠀⠀⠀⠘⣿⣿⣧⣾⣿⣿⠟⠁⣾⣿⡇⠀⠀⠘⢿⣿⣿⣦⡀⠀⠀⣀⣴⣿⣿⠃⠀⠀\n" +
                                     "⠀⠀⣿⣿⡇⠀⠀⢀⡄⠀⢠⣿⣿⠀⠀⠀⠀⠀⠀⢰⣿⣿⣿⣿⠟⠁⠀⠀⢿⣿⣇⠀⠀⠀⠈⠻⣿⣿⣿⣿⣿⣿⡿⠟⠁⠀⠀⠀\n" +
                                     "⠀⠀⠹⣿⣷⣄⣀⣼⡇⠀⢸⣿⣿⡀⠀⠀⠀⠀⣠⣿⣿⣿⡿⠋⠀⠀⠀⠀⢸⣿⣿⡀⠀⠀⠀⠀⠀⠉⠉⠉⠉⠁⠀⠀⠀⠀⠀⠀\n" +
                                     "⠀⠀⠀⠈⠛⠛⠛⠋⠀⠀⠀⢻⣿⣿⣶⣶⣶⣿⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀\n" +
                                     "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠛⠛⠛⠛⠛⠉⣿⣿⣿⡀⠀⠀⠀⠀⠀⠀⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀\n" +
                                     "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⣿⣿⣷⣄⣀⠀⢀⣀⣴⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀\n" +
                                     "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢿⣿⣿⣿⣿⣿⣿⣿⡿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀\n" +
                                     "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠉⠉⠉⠉⠀⠀⠀⠀⠀⠀";



    public static Battle[][] battleMap =  {{new Battle(1), new Battle(1), new Battle(1), new Battle(1), new Battle(1)},
                                           {new Battle(2), new Battle(2), new Battle(2), new Battle(2), new Battle(2)},
                                           {new Battle(3), new Battle(3), new Battle(3), new Battle(3), new Battle(3)},
                                           {new Battle(4), new Battle(4), new Battle(4), new Battle(4), new Battle(5, new Squid("The Kraken", 5, 18, 300, 25, 8))}};

    private static int currentRow = 0;
    private static int currentCol = 0;

    private static int timesMapHasBeenCompleted = 0;

    public static int getCurrentRow() {
        return currentRow;
    }

    public static void setCurrentRow(int currentRow) {
        BattleMap.currentRow = currentRow;
    }

    public static int getCurrentCol() {
        return currentCol;
    }

    public static void setCurrentCol(int currentCol) {
        BattleMap.currentCol = currentCol;
    }

    public static int getTimesMapHasBeenCompleted() {
        return timesMapHasBeenCompleted;
    }

    // Increments the battleMap placement, returns the next battle in the sequence
    // Resets the map with higher difficulty if it tries to access another battle past the final one
    public static Battle getNextBattle() {
        if (currentCol == battleMap[currentRow].length - 1 ) {
            currentCol = 0;
            currentRow++;
        } else {
            currentCol++;
        }

        if (currentRow > battleMap.length - 1) {
            timesMapHasBeenCompleted++;
            currentRow = 0;
            currentCol = 0;
            refreshBattleMap();
            return battleMap[currentRow][currentCol];
        }

        return BattleMap.battleMap[currentRow][currentCol];
    }


    public static void resetMap() {
        currentRow = 0;
        currentCol = 0;
        timesMapHasBeenCompleted = 0;
        refreshBattleMap();
    }

    // Replaces all the cells in the battleMap with new Battles, with increasing difficulty if they have completed the map more than once
    private static void refreshBattleMap() {
        for (int row=0; row < BattleMap.battleMap.length; row++) {
            for (int col=0; col < battleMap[row].length; col++) {
                if (row == 3 && col == 4) {
                    if (timesMapHasBeenCompleted == 0) {
                        BattleMap.battleMap[row][col] = new Battle(5, new Squid("The Kraken", 5, 18, 300, 25, 8));
                    } else {
                        BattleMap.battleMap[row][col] = new Battle(row+2 + timesMapHasBeenCompleted*4);
                    }
                } else {
                    BattleMap.battleMap[row][col] = new Battle(row+1 + timesMapHasBeenCompleted*4);
                }
            }
        }
    }


    // Different iterations of the battle map representation

    //        ┌────────────────────────────────────────────────┐
    //        │                                                │
    //        │                                                │
    //        │_     _     _     _     _     _     _     _     │
    //        │)`'-.,)`'-.,)`'-.,)`'-.,)`'-.,)`'-.,)`'-.,)`'-.,│
    //        │                                                │
    //        │                                                │
    //        │_     _     _     _     _     _     _     _     │
    //        │)`'-.,)`'-.,)`'-.,)`'-.,)`'-.,)`'-.,)`'-.,)`'-.,│
    //        │                                                │
    //        │                                                │
    //        │_     _     _     _     _     _     _     _     │
    //        │)`'-.,)`'-.,)`'-.,)`'-.,)`'-.,)`'-.,)`'-.,)`'-.,│
    //        │                                                │
    //        │                                                │
    //        │_     _     _     _     _     _     _     _     │
    //        │)`'-.,)`'-.,)`'-.,)`'-.,)`'-.,)`'-.,)`'-.,)`'-.,│
    //        └────────────────────────────────────────────────┘


//    String string =
//           ("""
//                   ┌─--─-╼━━╾-──--─-──╼━╾──---──-───--───--──--──┐
//                   │                                             │
//                   ╽                                             〈
//                   \ _     _     _     _     _     _     _     _ ╽
//                   /,)`'-.,)`'-.,)`'-.,)`'-.,)`'-.,)`'-.,)`'-.,)`╿
//                   ╿▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒│
//                   ]▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒│
//                   │ _     _     _     _     _     _     _     _ 〈
//                   │,)`'-.,)`'-.,)`'-.,)`'-.,)`'-.,)`'-.,)`'-.,)`│
//                   │░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░╽
//                   ╽░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░╿
//                   ╿ _     _     _     _     _     _     _     _ │
//                   │,)`'-.,)`'-.,)`'-.,)`'-.,)`'-.,)`'-.,)`'-.,)`〈
//                   \░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│
//                   /░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░〈
//                   ╿ _     _     _     _     _     _     _     _ │
//                   │,)`'-.,)`'-.,)`'-.,)`'-.,)`'-.,)`'-.,)`'-.,)`│
//                   └─-──--╼━╾╼━╾-──-──--───--──-╼━━╾──-─-──-──-──┘""");

    //    String string =
//           ("""
//                   ┌─--─--───---──────--────--───--───--────---──┐1
//                   P                                             │
//                   │                                             │
//                   │ _     _     _     _     _     _     _     _ │
//                   │,)`'-.,)`'-.,)`'-.,)`'-.,)`'-.,)`'-.,)`'-.,)`│
//                   │                                             │
//                   │                                             │
//                   │ _     _     _     _     _     _     _     _ │
//                   │,)`'-.,)`'-.,)`'-.,)`'-.,)`'-.,)`'-.,)`'-.,)`│
//                   │                                             │
//                   │                                             │
//                   │ _     _     _     _     _     _     _     _ │
//                   │,)`'-.,)`'-.,)`'-.,)`'-.,)`'-.,)`'-.,)`'-.,)`│
//                   │                                             │
//                   │                                             │
//                   │ _     _     _     _     _     _     _     _ │
//                   │,)`'-.,)`'-.,)`'-.,)`'-.,)`'-.,)`'-.,)`'-.,)`│
//                   └──--─────----────--────----───────---─────-──┘""");


    // Visual representation of the battleMap for the user to see where they are along the path
    public static String getCurrentMapRepresentation() {
        StringBuilder sb = new StringBuilder();
        sb.append("┌─--─-╼━━╾-──--─-──╼━╾──---──-───--───--──--──┐");
        if (timesMapHasBeenCompleted > 0) {
            sb.append(timesMapHasBeenCompleted+1).append("\n");
        } else {
            sb.append("\n");
        }

        for (int row=0; row < BattleMap.battleMap.length; row++) {
            if (row==0) {
                sb.append("P");
            } else {
                sb.append("│");
            }

                if (row == 0 && BattleMap.currentRow == 0 && BattleMap.currentCol == 0 && !BattleMap.battleMap[0][0].isBattleDefeated()) {
                    sb.append("⛴                                           │\n│");

                } else if (row == BattleMap.currentRow) {
                    for (int i = 0; i<BattleMap.currentCol; i++) {
                        sb.append("        ");
                    }

                    sb.append("    ⛴    ");
                    for (int i = BattleMap.currentCol +1; i<5; i++) {
                        sb.append("        ");
                    }
                    sb.append("   │\n│");
                } else if (row < BattleMap.currentRow) {
                    sb.append("                                             │\n│");
                } else{
                    sb.append("░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│\n│");
                }

            if (row <= BattleMap.currentRow) {
                sb.append(" ");
                for (int col = 0; col < 5; col++) {
                    sb.append("   ").append(BattleMap.battleMap[row][col].getMonsterEmoji()).append("   ");
                }
                sb.append("  〈");
            } else {
                sb.append("░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│");
            }


            sb.append("\n│ _     _     _     _     _     _     _     _ │\n│,)`'-.,)`'-.,)`'-.,)`'-.,)`'-.,)`'-.,)`'-.,)`");
            sb.append("│\n");
        }
        sb.append("└──--─────----────--────----───────---─────-──┘");
        return sb.toString();
    }

}
