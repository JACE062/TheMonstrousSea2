package edu.neumont.csc150.models.attacksandattackables.seamonsters;

import edu.neumont.csc150.controllers.ItemGenerator;
import edu.neumont.csc150.models.attacksandattackables.AttackResult;
import edu.neumont.csc150.models.attacksandattackables.Attackable;
import edu.neumont.csc150.models.attacksandattackables.ships.Ship;
import edu.neumont.csc150.models.enums.DamageType;
import edu.neumont.csc150.models.items.weapons.Weapon;

public class Shark extends SeaMonster{
    private static final String[] POSSIBLE_SHARK_NAMES = {"Thrashing Great White", "Bloodthirsty Bull Shark", "Colossal Tiger Shark", "Frenzied Maw", "Behemoth Mako", "Jagged Lurker", "Fang of the Abyss", "Terror of the Tides", "Ragefin", "Bloodrage Shark"};
    private int frenzyDmgMod;

    public void setFrenzyDmgMod(int frenzyDmgMod) {
        this.frenzyDmgMod = frenzyDmgMod;
    }

    public int getFrenzyDmgMod() {
        return frenzyDmgMod;
    }


    // Constructor for random Sharks based on level
    // Base stats of Shark: name: random from POSSIBLE_SHARK_NAMES, armorClass: 10 (+ 2 per level), hitPoints: 50 (+ 50 per level)
    public Shark(int level) {
        super(POSSIBLE_SHARK_NAMES[ItemGenerator.rand.nextInt(POSSIBLE_SHARK_NAMES.length)], level, 8 + 2*level, 50 * level);
        setFrenzyDmgMod(0);

        // Sharks also get jaws and tail attacks
        usableWeapons.add(ItemGenerator.generateMonsterWeapon(1, level, level));
        usableWeapons.add(ItemGenerator.generateMonsterWeapon(2, level, level));
    }

    // Constructor for hard coded Sharks (for potential hard-coded boss)
    public Shark(String name, int level, int armorClass, int hitPoints, int frenzyDmgMod) {
        super(name, level, armorClass, hitPoints);
        this.frenzyDmgMod = frenzyDmgMod;

        // Sharks also get jaws and tail attacks
        usableWeapons.add(ItemGenerator.generateMonsterWeapon(1, level, level));
        usableWeapons.add(ItemGenerator.generateMonsterWeapon(2, level, level));
    }

    @Override
    public String takeMonsterAction(Ship ship) {
        increaseFrenzy();
        return getName() + " roars in anger";
    }

    // Increases the dmgMod by a hard-coded 5*the level of the shark
    private void increaseFrenzy() {
        frenzyDmgMod += 5*getLevel();
    }

    private void decreaseFrenzy() {
        frenzyDmgMod -= 5*getLevel();
    }


    // Overrides Interface default to add frenzyDmgMod to the damage of the attack
    @Override
    public AttackResult attack(Attackable target, Weapon weapon) {
        boolean attackHit = false;
        int attackDmg = 0;
        DamageType attackType = weapon.getDamageType();
        String attackString = "The " + getName() + " attacks with " + weapon.getName();

        if((Attackable.diceRoll(1,20) + weapon.getHitModifier()) >= target.getArmorClass()) {
            attackHit = true;
            attackDmg = weapon.getDamage() + getFrenzyDmgMod();
        }
        return new AttackResult(attackString, attackHit, attackDmg, attackType);
    }
}
