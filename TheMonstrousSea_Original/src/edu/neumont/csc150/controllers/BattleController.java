package edu.neumont.csc150.controllers;

import edu.neumont.csc150.models.BattleMap;
import edu.neumont.csc150.models.Player;
import edu.neumont.csc150.models.attacksandattackables.AttackResult;
import edu.neumont.csc150.models.attacksandattackables.Attackable;
import edu.neumont.csc150.models.attacksandattackables.seamonsters.Crustacean;
import edu.neumont.csc150.models.attacksandattackables.seamonsters.SeaMonster;
import edu.neumont.csc150.models.attacksandattackables.seamonsters.Squid;
import edu.neumont.csc150.models.attacksandattackables.ships.Ship;
import edu.neumont.csc150.models.enums.DamageType;
import edu.neumont.csc150.models.enums.PlayerAction;
import edu.neumont.csc150.models.enums.ShipWeaponType;
import edu.neumont.csc150.models.enums.StatusEffect;
import edu.neumont.csc150.models.items.Consumable;
import edu.neumont.csc150.models.items.Item;
import edu.neumont.csc150.models.items.weapons.monsterweapons.MonsterWeapon;
import edu.neumont.csc150.models.items.weapons.monsterweapons.Tentacle;
import edu.neumont.csc150.models.items.weapons.shipweapons.ShipWeapon;
import edu.neumont.csc150.models.Battle;
import edu.neumont.csc150.views.Console;
import edu.neumont.csc150.views.UI;


import java.util.ArrayList;

public class BattleController {

    private Battle currentBattle;
    private final Player currentPlayer;
    private final LocationController locationController;
    boolean battleOver;
    boolean battleWon;
    boolean battleFled;

    BattleController(Player player, LocationController locationController) {
        this.currentPlayer = player;
        this.locationController = locationController;
    }

    // Runs rounds of the battle until either the player wins, flees, or dies
    public boolean runBattle(Battle battle) {
        battleOver = false;
        battleWon = false;
        battleFled = false;
        currentBattle = battle;
        battle.setShipInBattle(currentPlayer.getCurrentShip());
        UI.HR();
        if (BattleMap.getCurrentRow() == 3 && BattleMap.getCurrentCol() == 4 && BattleMap.getTimesMapHasBeenCompleted() == 0) {
            UI.printLn(BattleMap.KrakenArt);
            UI.printLn("Colossal tentacles shoot out of the water, too many to count, as " + battle.getSeaMonsterInBattle().getName() + " itself has risen from the depths to face you!", Console.TextColor.RED);
        } else {
            UI.printLn("A " + battle.getSeaMonsterInBattle().getName() + " rears out of the water", Console.TextColor.RED);
        }

        UI.printLn("Battle Difficulty: " + currentBattle.getBattleDifficultyLevel(), Console.TextColor.RED);
        while(!battleOver) {
            playRound(currentBattle);
        }

        if (battleWon) {
            pickUpDroppedLoot("These items are still left in the water, would you like to drop some cargo to make room?", dropVictoryLoot( battle.getSeaMonsterInBattle()));
            currentPlayer.setHighestDifficultyThisLife(battle.getBattleDifficultyLevel());
            currentPlayer.incrementSeaMonstersDefeatedThisLife();
        } else if (battleFled) {
            UI.HR();
            UI.printLn("The " + currentPlayer.getCurrentShip().getName() + " high tails its way back to port, the crew reeling from a narrow scrape with fate.", Console.TextColor.RED);
        }

        currentPlayer.getCurrentShip().decrementChargeTimeOnWeapons();
        currentPlayer.getCurrentShip().decrementChargeTimeOnWeapons();

        return battleWon;
    }


    // plays a round of the battle, giving the player the options for their turn, then running the automatic monster turn, checking for status effects and deaths between each turn
    public void playRound(Battle battle) {
        UI.HR();
        battle.increaseBattleRoundCounter();

        checkForDeaths(battle.getShipInBattle(), battle.getSeaMonsterInBattle());
        if(battleOver) return;


        UI.printLn("Round: " + currentBattle.getBattleRoundCounter(), Console.TextColor.RED);
        UI.displayShipAndMonsterHealth(battle.getShipInBattle(), battle.getSeaMonsterInBattle());
        if(updateStatusEffects(battle.getShipInBattle())) {
            playPlayerTurn(battle.getShipInBattle());
        }

        checkForDeaths(battle.getShipInBattle(), battle.getSeaMonsterInBattle());
        if(battleOver) return;

        if(updateStatusEffects(battle.getSeaMonsterInBattle())) {
            playMonsterTurn(battle.getSeaMonsterInBattle(), battle.getShipInBattle());
        }
        checkForDeaths(battle.getShipInBattle(), battle.getSeaMonsterInBattle());
    }



    public void playPlayerTurn(Ship ship) {
        int i = 1;
        StringBuilder sb = new StringBuilder();
        for (PlayerAction action : currentPlayer.getPossibleBattleActions()) {
            sb.append(i).append(": ").append(action).append("\n");
            i++;
        }
        boolean actionWasChosen = false;
        while (!actionWasChosen){
            switch (UI.userIntInput(sb.toString(), 1, currentPlayer.getPossibleBattleActions().size())) {
                case 1: actionWasChosen = selectFromPossibleAttacks(ship);
                break;
                case 2: actionWasChosen = selectFromPossibleConsumables(ship);
                break;
                case 3: if(ship.flee()) { battleFled = true; endBattle();} else UI.printLn(ship.getName() + " was unable to flee"); actionWasChosen=true;
                break;
                case 4: UI.printLn(ship.shipSubclassAction()); actionWasChosen=true;
                break;
            }

        }
        ship.decrementChargeTimeOnWeapons();
    }



    // loops over and prints the weapon types that the currentShip has equipped
    // if a weapon is on cooldown, displays it is yellow with the rounds left until it can be fired
    // if they try to select a weapon on cooldown, loops again and gives them a error message
    // Lets the user select from one of the possible actions
    public boolean selectFromPossibleAttacks(Ship ship) {
        int i;
        boolean availableWeaponChosen = false;
        int weaponTypeIndex = 0;
        while (!availableWeaponChosen) {
            i = 1;

            if (!ship.getEquippedWeapons().isEmpty()) {
                for (ShipWeaponType weaponType : ship.getTypesOfWeaponsCurrentlyEquipped()) {

                    if (weaponType.getChargeTime() == 0 || checkShipWeaponTypeForCooldown(weaponType) == 0) {
                        UI.printLn(i + ": " + weaponType + "s");
                    } else {
                        UI.printLn(i + ": " + weaponType + "s (Ready in " + checkShipWeaponTypeForCooldown(weaponType) + ")", Console.TextColor.YELLOW);

                    }
                    i++;
                }
            } else {
                UI.printLn("Are you out of you mind, Captain? We have no weapons!", Console.TextColor.RED);
            }

            UI.printLn(i + ": Exit");

            weaponTypeIndex = UI.userIntInput("", 1, ship.getTypesOfWeaponsCurrentlyEquipped().size() + 1);

            if (weaponTypeIndex == ship.getTypesOfWeaponsCurrentlyEquipped().size() + 1) {
                return false;
            } else if (ship.getTypesOfWeaponsCurrentlyEquipped().get(weaponTypeIndex - 1).getChargeTime() == 0 || checkShipWeaponTypeForCooldown(ship.getTypesOfWeaponsCurrentlyEquipped().get(weaponTypeIndex - 1)) == 0){
                availableWeaponChosen = true;
            } else {
                UI.printLn("The " + ship.getTypesOfWeaponsCurrentlyEquipped().get(weaponTypeIndex - 1).toString() + "s are still being reloaded!", Console.TextColor.RED);           }
        }
        attackWithAllShipWeaponsOfAType(ship, currentBattle.getSeaMonsterInBattle(), ship.getTypesOfWeaponsCurrentlyEquipped().get(weaponTypeIndex - 1));
        return true;
    }


    private int checkShipWeaponTypeForCooldown(ShipWeaponType weaponType) {
        for (ShipWeapon weapon : currentBattle.getShipInBattle().getEquippedWeapons()) {
                if (weapon.getWeaponType() == weaponType) {
                    return  weapon.getChargeCountdown();
                }
        }
        return 0;
    }


    private void attackWithAllShipWeaponsOfAType(Ship ship, SeaMonster seaMonster, ShipWeaponType type) {
        for(ShipWeapon weapon : ship.getEquippedWeapons()) {
            if (weapon.getWeaponType() == type) {
                AttackResult result = ship.attack(seaMonster, weapon);
                UI.printLn(result.getAttackString());

                UI.printLn(seaMonster.takeDamage(result));
                weapon.setChargeCountdown(weapon.getChargeTime());

                if(seaMonster.getHP() == 0) {
                    return;
                }
            }
        }
    }


    public boolean selectFromPossibleConsumables(Ship ship) {
        int i = 1;
        ArrayList<Consumable> tempConsumableList = new ArrayList<Consumable>();
        if (ship.getCurrentCargo().isEmpty()) {
            UI.printLn("There are no consumables to use!", Console.TextColor.RED);
        } else {
            for (Item item : ship.getCurrentCargo()) {
                if (item instanceof Consumable) {
                    UI.print(i + ": ");
                    UI.printItemDetailsRarityColor(item);

                    tempConsumableList.add((Consumable) item);
                    i++;
                }
            }
        }
        UI.printLn(i + ": Exit");

        int consumableIndex = UI.userIntInput("", 1, tempConsumableList.size() + 1);

        if (consumableIndex == tempConsumableList.size() + 1) {
            return false;
        }

        UI.printLn(ship.useConsumable(tempConsumableList.get(consumableIndex-1), currentBattle.getSeaMonsterInBattle()));
        return true;
    }


    // Currently coded to have an 80% chance of sea monster attacking, 20% chance for it to use its subclass-specific action
    // Checks to see if the random weapon it selects with the Attack action is on cooldown, and picks a new weapon if so
    // Crustaceans do not have a subclass-specific action, so they always attack
    // Squid, when attacking with their tentacle attack, make a separate hit for each tentacle they have left, or attack uselessly if all their tentacles have been chopped off
    public void playMonsterTurn(SeaMonster seaMonster, Ship ship) {
        UI.HR();
        int roll = Attackable.diceRoll(1,100);
        if(roll < 80 || seaMonster instanceof Crustacean) {
            boolean weaponAvailable = false;

            while (!weaponAvailable) {
                MonsterWeapon randomAvailableWeapon = seaMonster.getUsableWeapons().get(ItemGenerator.rand.nextInt(seaMonster.getUsableWeapons().size()));

                if (randomAvailableWeapon.getChargeCountdown() == 0) {
                    if (randomAvailableWeapon instanceof Tentacle) {
                        if (((Squid) seaMonster).getNumberOfTentacles() > 0) {

                            AttackResult result = seaMonster.attack(ship, randomAvailableWeapon);
                            UI.printLn(result.getAttackString());
                            UI.printLn(ship.takeDamage(result));

                            for (int i = 1; i < ((Squid) seaMonster).getNumberOfTentacles(); i++) {
                                result = seaMonster.attack(ship, randomAvailableWeapon);
                                UI.printLn(ship.takeDamage(result));
                            }
                        } else {
                            UI.printLn(seaMonster.getName() + " flails as it tries to attack with its chopped-off tentacles");
                        }
                    } else {
                        AttackResult result = seaMonster.attack(ship, randomAvailableWeapon);
                        UI.printLn(result.getAttackString());
                        UI.printLn(ship.takeDamage(result));
                    }
                    weaponAvailable = true;
                    randomAvailableWeapon.setChargeCountdown(randomAvailableWeapon.getChargeTime());
                }
            }
        } else {
            UI.printLn(seaMonster.takeMonsterAction(ship));
        }
        seaMonster.decrementChargeTimeOnWeapons();
    }


    // Checks if the attackable for each of the status effects and applies the appropriate damage if necessary
    // Base damage for burn and poison is currently 5 * the battle difficulty level
    // Burn and Poison both currently have a 25% chance to wear off each turn - adjust for balance if necessary
    // Returns false if the creature is stunned
    // Stun has a 50% chance of wearing off each round for SeaMonsters
    // Stun always lasts just 1 round for player ship
    public boolean updateStatusEffects(Attackable attackable) {
        if(attackable.getStatusEffectList().contains(StatusEffect.BURN)) {
            UI.print(attackable.takeDamage(new AttackResult(true, 5 * currentBattle.getBattleDifficultyLevel(), DamageType.FIRE)));

            if (attackable.getHP() == 0) {
                UI.printLn("");
                return false;
            } else if (Attackable.diceRoll(1,100) > 75) {
                UI.printLn(" as the burning flames wear off");
                attackable.removeStatusEffectFromList(StatusEffect.BURN);
            } else {
                UI.printLn(" and is still burning");
            }
        }

        if (attackable.getStatusEffectList().contains(StatusEffect.POISON)) {
            UI.print(attackable.takeDamage(new AttackResult(true, 5 * currentBattle.getBattleDifficultyLevel(), DamageType.VENOM)));

            if (attackable.getHP() == 0) {
                UI.printLn("");
                return false;
            } else if (Attackable.diceRoll(1,100) > 75) {
                UI.printLn(" and recovers from the poison");
                attackable.removeStatusEffectFromList(StatusEffect.POISON);
            } else {
                UI.printLn(" and is still poisoned");
            }
        }

        if (attackable.getStatusEffectList().contains(StatusEffect.STUN)) {
            UI.print(attackable.getName() + " cannot move");

            if (Attackable.diceRoll(1,100) > 50 || attackable instanceof Ship) {
                UI.printLn(", but the stun wears off");
                attackable.removeStatusEffectFromList(StatusEffect.STUN);
            } else {
                UI.printLn(" and remains stunned");
            }

            if (attackable instanceof Ship) {
                ((Ship) attackable).decrementChargeTimeOnWeapons();
            }
            return false;
        }
        return true;
    }



    private void checkForDeaths(Ship ship, SeaMonster seaMonster) {
        if (ship.getHP() == 0) {
            UI.displayPlayerDies(ship);
            currentPlayer.setAlive(false);
            endBattle();
        } else if (seaMonster.getHP() == 0) {
            UI.displaySeaMonsterDies(seaMonster);
            battleWon = true;
            endBattle();
        }
    }



    private void endBattle() {
        battleOver = true;
    }


    // Drops loot of levels between -3 and +3 of the current battle's difficulty (with a minimum item level of 1)
    private ArrayList<Item> dropVictoryLoot(SeaMonster seaMonster) {

        ArrayList<Item> items = new ArrayList<>();
        for (int i = 0; i < ItemGenerator.rand.nextInt(SeaMonster.MIN_ITEMS_DROPPED, SeaMonster.MAX_ITEMS_DROPPED + 1); i++) {

            int randomNum = Attackable.diceRoll(1,100);
            if (randomNum <= 15) {
                items.add(ItemGenerator.randomItem(Math.max(seaMonster.getLevel()-3, 1)));
            } else if (randomNum <= 30) {
                items.add(ItemGenerator.randomItem(Math.max(seaMonster.getLevel()-2, 1)));
            } else if (randomNum <= 50) {
                items.add(ItemGenerator.randomItem(Math.max(seaMonster.getLevel()-1, 1)));
            } else if (randomNum <= 80) {
                items.add(ItemGenerator.randomItem(seaMonster.getLevel()));
            } else if (randomNum <= 95) {
                items.add(ItemGenerator.randomItem(seaMonster.getLevel()+1));
            } else if (randomNum <= 99) {
                items.add(ItemGenerator.randomItem(seaMonster.getLevel()+2));
            } else {
                items.add(ItemGenerator.randomItem(seaMonster.getLevel()+3));
            }
        }
        return items;
    }



    // adds the loot to the player's Cargo, and lets them drop cargo to make room if they don't have enough
    public void pickUpDroppedLoot(String message, ArrayList<Item> lootList) {
        lootList.sort(Item::compareTo);
        UI.printLn(currentPlayer.getCurrentShip().addListOfItemsToCargo(lootList));

        while (!lootList.isEmpty()) {
            UI.HR();
            UI.printLn(message);

            for (Item item : lootList) {
                UI.printItemDetailsRarityColor(item);
            }

            if (UI.confirmOrDeny("Drop items from Cargo to make space", "Leave items behind")) {
                locationController.dropCargo();
            } else {
                return;
            }

            if (UI.confirmOrDeny("Try to take all items", "Take specific items")) {
                UI.printLn(currentPlayer.getCurrentShip().addListOfItemsToCargo(lootList));
            } else {
                while (true) {
                    int itemIndex = locationController.chooseItemFromList("Take specific item:", lootList);

                    if (itemIndex == lootList.size() + 1) {
                        break;
                    }

                    UI.printLn(currentPlayer.getCurrentShip().addCargo(lootList.get(itemIndex - 1)));
                    lootList.remove(itemIndex - 1);
                }
            }
        }
    }
}