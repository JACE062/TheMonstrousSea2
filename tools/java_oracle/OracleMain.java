package tools.oracle;

import edu.neumont.csc150.controllers.ItemGenerator;
import edu.neumont.csc150.models.attacksandattackables.seamonsters.*;
import edu.neumont.csc150.models.attacksandattackables.ships.*;
import edu.neumont.csc150.models.items.Item;
import edu.neumont.csc150.models.items.weapons.shipweapons.ShipWeapon;

import java.io.FileWriter;
import java.io.IOException;
import java.util.*;

public class OracleMain {
    private static final int SAMPLES = 10000;

    public static void main(String[] args) {
        System.out.println("Starting Java Oracle Fixture Generation (" + SAMPLES + " samples)...");
        generateMonsterFixtures();
        generateShipFixtures();
        generateItemFixtures();
        System.out.println("Fixtures successfully written to tools/java_oracle/fixtures/");
    }

    private static void generateMonsterFixtures() {
        StringBuilder sb = new StringBuilder();
        sb.append("{\n  \"monsters\": {\n");

        String[] species = {"Shark", "Serpent", "Jellyfish", "Squid", "Crustacean"};
        for (int s = 0; s < species.length; s++) {
            String name = species[s];
            sb.append("    \"").append(name).append("\": {\n");
            for (int lvl = 1; lvl <= 4; lvl++) {
                int minHp = Integer.MAX_VALUE, maxHp = Integer.MIN_VALUE;
                long totalHp = 0;
                int minAc = Integer.MAX_VALUE, maxAc = Integer.MIN_VALUE;

                for (int i = 0; i < SAMPLES; i++) {
                    SeaMonster m = switch (name) {
                        case "Shark" -> new Shark(lvl);
                        case "Serpent" -> new Serpent(lvl);
                        case "Jellyfish" -> new Jellyfish(lvl);
                        case "Squid" -> new Squid(lvl);
                        case "Crustacean" -> new Crustacean(lvl);
                        default -> throw new IllegalStateException();
                    };
                    int hp = m.getMaxHP();
                    int ac = m.getArmorClass();
                    if (hp < minHp) minHp = hp;
                    if (hp > maxHp) maxHp = hp;
                    totalHp += hp;
                    if (ac < minAc) minAc = ac;
                    if (ac > maxAc) maxAc = ac;
                }

                sb.append("      \"level_").append(lvl).append("\": { ")
                  .append("\"minHp\": ").append(minHp).append(", ")
                  .append("\"maxHp\": ").append(maxHp).append(", ")
                  .append("\"meanHp\": ").append(String.format(Locale.US, "%.2f", (double) totalHp / SAMPLES)).append(", ")
                  .append("\"ac\": ").append(minAc)
                  .append(" }").append(lvl < 4 ? ",\n" : "\n");
            }
            sb.append("    }").append(s < species.length - 1 ? ",\n" : "\n");
        }
        sb.append("  }\n}\n");
        writeToFile("tools/java_oracle/fixtures/monsters.json", sb.toString());
    }

    private static void generateShipFixtures() {
        StringBuilder sb = new StringBuilder();
        sb.append("{\n  \"ships\": {\n");

        String[] shipTypes = {"Standard", "Freighter", "Ironclad", "Corvette"};
        for (int st = 0; st < shipTypes.length; st++) {
            String type = shipTypes[st];
            sb.append("    \"").append(type).append("\": {\n");
            for (int lvl = 1; lvl <= 4; lvl++) {
                int minHp = Integer.MAX_VALUE, maxHp = Integer.MIN_VALUE;
                int minCargo = Integer.MAX_VALUE, maxCargo = Integer.MIN_VALUE;
                int minWeight = Integer.MAX_VALUE, maxWeight = Integer.MIN_VALUE;
                long totalHp = 0;

                for (int i = 0; i < SAMPLES; i++) {
                    Ship s = switch (type) {
                        case "Standard" -> new Ship(lvl);
                        case "Freighter" -> new Freighter(lvl);
                        case "Ironclad" -> new Ironclad(lvl);
                        case "Corvette" -> new Corvette(lvl);
                        default -> throw new IllegalStateException();
                    };
                    int hp = s.getMaxHP();
                    if (hp < minHp) minHp = hp;
                    if (hp > maxHp) maxHp = hp;
                    totalHp += hp;

                    int cargo = s.getMaxCargo();
                    if (cargo < minCargo) minCargo = cargo;
                    if (cargo > maxCargo) maxCargo = cargo;

                    int weight = s.getMaxWeaponWeight();
                    if (weight < minWeight) minWeight = weight;
                    if (weight > maxWeight) maxWeight = weight;
                }

                sb.append("      \"level_").append(lvl).append("\": { ")
                  .append("\"minHp\": ").append(minHp).append(", ")
                  .append("\"maxHp\": ").append(maxHp).append(", ")
                  .append("\"meanHp\": ").append(String.format(Locale.US, "%.2f", (double) totalHp / SAMPLES)).append(", ")
                  .append("\"minCargo\": ").append(minCargo).append(", ")
                  .append("\"maxCargo\": ").append(maxCargo).append(", ")
                  .append("\"maxWeight\": ").append(minWeight)
                  .append(" }").append(lvl < 4 ? ",\n" : "\n");
            }
            sb.append("    }").append(st < shipTypes.length - 1 ? ",\n" : "\n");
        }
        sb.append("  }\n}\n");
        writeToFile("tools/java_oracle/fixtures/ships.json", sb.toString());
    }

    private static void generateItemFixtures() {
        StringBuilder sb = new StringBuilder();
        sb.append("{\n  \"items\": {\n");

        for (int lvl = 1; lvl <= 4; lvl++) {
            int treasures = 0, consumables = 0, weapons = 0;
            for (int i = 0; i < SAMPLES; i++) {
                Item item = ItemGenerator.randomItem(lvl);
                if (item instanceof edu.neumont.csc150.models.items.Treasure) {
                    treasures++;
                } else if (item instanceof edu.neumont.csc150.models.items.Consumable) {
                    consumables++;
                } else if (item instanceof ShipWeapon) {
                    weapons++;
                }
            }
            sb.append("    \"level_").append(lvl).append("\": { ")
              .append("\"treasurePct\": ").append(String.format(Locale.US, "%.4f", (double) treasures / SAMPLES)).append(", ")
              .append("\"consumablePct\": ").append(String.format(Locale.US, "%.4f", (double) consumables / SAMPLES)).append(", ")
              .append("\"weaponPct\": ").append(String.format(Locale.US, "%.4f", (double) weapons / SAMPLES))
              .append(" }").append(lvl < 4 ? ",\n" : "\n");
        }
        sb.append("  }\n}\n");
        writeToFile("tools/java_oracle/fixtures/item_distributions.json", sb.toString());
    }

    private static void writeToFile(String path, String content) {
        try (FileWriter writer = new FileWriter(path)) {
            writer.write(content);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
