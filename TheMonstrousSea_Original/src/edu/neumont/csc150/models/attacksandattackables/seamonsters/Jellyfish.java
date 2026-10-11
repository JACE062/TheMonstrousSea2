package edu.neumont.csc150.models.attacksandattackables.seamonsters;

import edu.neumont.csc150.controllers.ItemGenerator;
import edu.neumont.csc150.models.attacksandattackables.Attackable;
import edu.neumont.csc150.models.attacksandattackables.ships.Ship;
import edu.neumont.csc150.models.enums.StatusEffect;

public class Jellyfish extends SeaMonster {
    private static final String[] POSSIBLE_JELLYFISH_NAMES = {"Pulsating Jellyfish", "Venom-Inflicter", "Ghostly-Tendriled Creature", "Medusa’s Grasp", "Nerveburn Jelly", "Venomous Shroud", "Drifting Wraith", "Abyssal Stinger", "Floating Veil"};
    public int stunChance;

    public int getStunChance() {
        return stunChance;
    }

    public void setStunChance(int stunChance) {
        this.stunChance = stunChance;
    }


    // Constructor for random Jellyfish based on level
    // Base stats of Squid: name: random from POSSIBLE_JELLYFISH_NAMES, armorClass: 10 (+ 2 per level), hitPoints: 40 (+ 40 per level)
    // stunChance starts at a base of 10, increasing by 5 per level
    public Jellyfish(int level) {
        super(POSSIBLE_JELLYFISH_NAMES[ItemGenerator.rand.nextInt(POSSIBLE_JELLYFISH_NAMES.length)], level, 8 + 2*level, 40 * level);
        setStunChance(5 + 5*level);
    }


    // Constructor for hard coded Jellyfish (for potential hard-coded boss)
    public Jellyfish(String name, int level, int armorClass, int hitPoints, int stunChance) {
        super(name, level, armorClass, hitPoints);
        setStunChance(stunChance);

        // Jellyfish also get a Stinging Tendrils attack
        usableWeapons.add(ItemGenerator.generateMonsterWeapon(5, level, level));
    }

    @Override
    public String takeMonsterAction(Ship ship) {
        return neurotoxinWave(ship);
    }

    // String representation for whether the neurotoxin worked
    private String neurotoxinWave(Ship ship) {
        if (Attackable.diceRoll(1,100) < getStunChance()) {
            ship.addStatusEffectToList(StatusEffect.STUN);
            return getName() + " releases a wave of neurotoxin, briefly paralyzing the crew of the " + ship.getName();
        } else {
            return getName() + " releases neurotoxin into the battlefield, but a strong current swiftly sweeps it away.";
        }
    }
}
