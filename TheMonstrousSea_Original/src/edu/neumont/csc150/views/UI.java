package edu.neumont.csc150.views;

import edu.neumont.csc150.models.attacksandattackables.Attackable;
import edu.neumont.csc150.models.attacksandattackables.seamonsters.SeaMonster;
import edu.neumont.csc150.models.attacksandattackables.ships.Ship;
import edu.neumont.csc150.models.items.Item;


// Pipes user interaction and output to Console
// Additionally, has a few custom methods for use cases not covered by Console
public class UI {

    public static void HR() {
        Console.writeLn("――――――――――――――――――――――――――――――――――――――――――――――――――");
    }

    public static void print(String message) {
        Console.write(message);
    }

    public static void printLn(String message) {
        Console.writeLn(message);
    }

    public static void print(String message, Console.TextColor color) {
        Console.write(message, color);
    }

    public static void printLn(String message, Console.TextColor color) {
        Console.writeLn(message, color);
    }

    public static void printItemDetailsRarityColor(Item item) {
        Console.write(item.getRarity().toString(), item.getRarity().getTextColor());
        Console.writeLn(item.fullDetailsString());
    }


    public static int userIntInput(String message, int min, int max) {
        return Console.getIntInput(message, min, max);
    }

    public static boolean confirmOrDeny(String confirmMessage, String denyMessage) {
        return UI.userIntInput("1: " + confirmMessage + "\n2: " + denyMessage + "\n", 1, 2) == 1;
    }

    public static String userStringInput(String message, boolean allowEmpty) {
        return Console.getStringInput(message + "\n", allowEmpty);
    }

    public static String userStringInput(String message, boolean allowEmpty, Console.TextColor textColor) {
        return Console.getStringInput(message, allowEmpty, textColor);
    }


    public static void writeStringDramatically(String stringToDramaticise, double secondsBetweenCharacters, boolean printNewLine) {
        for(int i = 0; i < stringToDramaticise.length(); i++) {
            Console.write(String.valueOf(stringToDramaticise.charAt(i)));
            waitSeconds(secondsBetweenCharacters);
        }
        if (printNewLine) {
            Console.writeLn("");
        }
    }

    // Uses the Thread.sleep method to pause the game for a given amount od seconds
    // Mainly used for dramatic effect
    public static void waitSeconds(double seconds) {
        try {
            Thread.sleep((long) (seconds * 1000));
        } catch (InterruptedException e) {
            Console.writeLn(e.getMessage());
        }
    }


    public static void displayShipAndMonsterHealth(Ship ship, SeaMonster seaMonster) {
        displayShipHealth(ship);
        displaySeaMonsterHealth(seaMonster);
    }

    public static void displayShipHealth(Ship ship) {
        Console.write("Ship Hull Remaining: ");
        displayHealthWithWarningColor(ship);
    }

    public static void displaySeaMonsterHealth(SeaMonster seaMonster) {
        Console.write("Monster Health Remaining: ");
        displayHealthWithWarningColor(seaMonster);
    }

    public static void displayHealthWithWarningColor(Attackable attackable) {
        if(attackable.getHP() > 0.5 * attackable.getMaxHP()) {
            Console.writeLn(String.valueOf(attackable.getHP()), Console.TextColor.GREEN);
        } else if(attackable.getHP() > 0.25 * attackable.getMaxHP()) {
            Console.writeLn(String.valueOf(attackable.getHP()), Console.TextColor.YELLOW);
        } else {
            Console.writeLn(String.valueOf(attackable.getHP()), Console.TextColor.RED);
        }
    }


    public static void displayHullAndGold(String locationMessage, Ship ship, int gold) {
        HR();
        UI.printLn(locationMessage);
        displayShipHealth(ship);
        displayGold(gold);
    }

    public static void displayGold(int gold) {
        print("Current gold: ");
        printLn(String.valueOf(gold), Console.TextColor.YELLOW);
    }


    public static void displayPlayerDies(Ship ship) {
        Console.writeLn("\n");
        Console.write("Ship Hull Remaining: ", Console.TextColor.RED);
        displayHealthWithWarningColor(ship);
        displayPlayerDeathMessage(ship);

    }


    public static void displaySeaMonsterDies(SeaMonster monster) {
        Console.writeLn("The Battle against The " + monster.getName() + " has been won!", Console.TextColor.GREEN);
    }


    public static void playIntro() {
        writeStringDramatically("The Monsters of the Sea have been a scourge upon the land for too long", 0.08, false);
        writeStringDramatically("...", 0.3, true);
        writeStringDramatically("It's a risk to be sure, for your life is held in the hands of fate, but you have taken up the call", 0.08, false);
        writeStringDramatically("...", 0.3, true);
    }


    public static void displayPlayerDeathMessage(Ship ship) {
        waitSeconds(5);
        Console.clear();
        waitSeconds(2.51);
        writeStringDramatically("The Hull of the " + ship.getName() + " splits in two and sinks down into the waves", 0.12, false);
        writeStringDramatically("...", 0.7, true);
        waitSeconds(1.2);
//        writeStringDramatically("...", 0.75, true);
//        waitSeconds(1.2);
//        writeStringDramatically("...", 0.75, true);
//        waitSeconds(1.2);
        writeStringDramatically("...", 0.7, true);
        waitSeconds(3);
        writeStringDramatically("The Sea has claimed another soul", 0.12, false);
        writeStringDramatically("...", 0.7, true);
        waitSeconds(2);
    }

    public static void clear() {
        Console.clear();
    }
}
