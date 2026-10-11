package edu.neumont.csc150.models.attacksandattackables.seamonsters;

import edu.neumont.csc150.controllers.ItemGenerator;
import edu.neumont.csc150.models.attacksandattackables.AttackResult;
import edu.neumont.csc150.models.attacksandattackables.Attackable;
import edu.neumont.csc150.models.attacksandattackables.ships.Ship;
import edu.neumont.csc150.models.enums.DamageType;
import edu.neumont.csc150.models.items.weapons.Weapon;
import edu.neumont.csc150.models.items.weapons.monsterweapons.Tentacle;

public class Squid extends SeaMonster {
    private static final String[] POSSIBLE_SQUID_NAMES = {"Gargantuan Squid", "Krakenling", "Many-tentacled beast", "Inkborn Terror", "Hundred-Limbed Horror", "Grasping Abyss", "Suffocating Embrace", "Razor Tendrils", "Death by Ink", };
    private int numberOfTentacles;
    private boolean obscured;
    private int obscuredACMod;


    public int getNumberOfTentacles() {
        return numberOfTentacles;
    }

    public void setNumberOfTentacles(int numberOfTentacles) {
        if (numberOfTentacles >= 0) {
            this.numberOfTentacles = numberOfTentacles;
        } else {
            this.numberOfTentacles = 0;
        }
    }

    public int getObscuredACMod() {
        return obscuredACMod;
    }

    public void setObscuredACMod(int obscuredACMod) {
        this.obscuredACMod = obscuredACMod;
    }

    public boolean isObscured() {
        return obscured;
    }

    public void setObscured(boolean obscured) {
        this.obscured = obscured;
    }

    @Override
    public int getArmorClass() {
        if (obscured) {
            return super.getArmorClass() + obscuredACMod;
        }
        return super.getArmorClass();
    }

    // Constructor for random Squids based on level
    // Base stats of Squid: name: random from POSSIBLE_SQUID_NAMES, armorClass: 8 (+ 2 per level), hitPoints: 50 (+ 50 per level)
    // numberOfTentacles starts at 5, increasing by 5 per level
    // obscuredACMod starts at a base of 2, increasing by 2 per level
    public Squid(int level) {
        super(POSSIBLE_SQUID_NAMES[ItemGenerator.rand.nextInt(POSSIBLE_SQUID_NAMES.length)], level, 6 + 2*level, 50 * level);
        setNumberOfTentacles(5*level);
        setObscuredACMod(2*level);

        // Squid get a tentacle attack
        usableWeapons.add(ItemGenerator.generateMonsterWeapon(4, level, level));
    }


    // Constructor for hard coded Squids (for potential hard-coded boss)
    public Squid(String name, int level, int armorClass, int hitPoints, int numberOfTentacles, int obscuredACMod) {
        super(name, level, armorClass, hitPoints);
        setNumberOfTentacles(numberOfTentacles);
        setObscured(false);
        setObscuredACMod(obscuredACMod);

        // Squid get a tentacle attack
        usableWeapons.add(ItemGenerator.generateMonsterWeapon(4, level, level));
    }

    @Override
    public String takeMonsterAction(Ship ship) {
        inkCloud();
        return getName() + " jets out pitch black ink into the water, obscuring itself from view";
    }

    private void inkCloud() {
        setObscured(true);
    }

    // Removes tentacles from the squid, returns the number of tentacles that were chopped
    private int loseTentacles(int tentaclesChopped) {
        int tentaclesLost;
        if (tentaclesChopped >= getNumberOfTentacles()) {
            tentaclesLost = getNumberOfTentacles();
            setNumberOfTentacles(0);
            return tentaclesLost;
        }
        setNumberOfTentacles(getNumberOfTentacles() - tentaclesChopped);
        return tentaclesChopped;
    }


    @Override
    public AttackResult attack(Attackable target, Weapon weapon) {
        AttackResult result = super.attack(target,weapon);

        if (weapon instanceof Tentacle) {
            result.setAttackString("The " + getName() + " attacks with " + weapon.getName() + "s");
        }
        return result;
    }


    // Changes the Superclass takDamage to implement the chopping off of tentacles for squids
    @Override
    public String takeDamage(AttackResult attackResult) {
        String damageMessage = "";
        if(attackResult.didAttackHit()) {
            setHP(getHP() - attackResult.getAttackDmg());

            if(attackResult.inflictsEffect()) {
                this.addStatusEffectToList(attackResult.getEffectInflicted());
                damageMessage = "The " + getName() + " takes " + attackResult.getAttackDmg() + " damage and is " + attackResult.getEffectInflicted().getVerbRepresentation();
            } else {
                damageMessage = "The " + getName() + " takes " + attackResult.getAttackDmg() + " " + attackResult.getAttackType().toString() + " damage";
            }

            if (attackResult.getAttackType() == DamageType.SLICING && getNumberOfTentacles() > 0) {
                return damageMessage + ", losing " + loseTentacles((int)Math.ceil(attackResult.getAttackDmg() / 10.0)) + " tentacles ";
            }

        } else {
            damageMessage = "The attack misses The " + getName();
        }

        if (isObscured() && Attackable.diceRoll(1,100) < 25) {
            setObscured(false);
            return damageMessage + ", dispersing the cloud of ink";
        }
        return damageMessage;
    }
}
