package edu.neumont.csc150.models.items;

import edu.neumont.csc150.controllers.ItemGenerator;
import edu.neumont.csc150.models.attacksandattackables.AttackResult;
import edu.neumont.csc150.models.enums.ConsumableType;
import edu.neumont.csc150.models.enums.RarityLevel;
import edu.neumont.csc150.models.attacksandattackables.Attackable;
import edu.neumont.csc150.models.enums.StatusEffect;

public class Consumable extends Item{
    private int maxUses;
    private int usesLeft;
    private ConsumableType type;
    private final StatusEffect[] EFFECTS = {StatusEffect.STUN, StatusEffect.POISON, StatusEffect.BURN};

    private void setMaxUses(int maxUses) {
        this.maxUses = maxUses;
    }

    private void setUsesLeft() {
        this.usesLeft = maxUses;
    }

    public int getUsesLeft() {
        return usesLeft;
    }

    private void setType(ConsumableType type) {
        this.type = type;
    }

    public ConsumableType getType() {
        return type;
    }

    // Created a hard-coded Consumable by passing all the values needed
    public Consumable(RarityLevel rarity, int value, int maxUses, ConsumableType type) {
        super(type.toString(), type.getDescription(), value, rarity);
        setMaxUses(maxUses);
        setUsesLeft();
        setType(type);
    }

    // Creates and returns a random Consumable based on the rarity, value, and a randomTypeIndex
    public Consumable(RarityLevel rarity, int value, int randomTypeIndex) {
        super("", "", value, rarity);
        setMaxUses(rarity.getLevel());
        setUsesLeft();

        switch (randomTypeIndex) {
            case 0: {
                setType(ConsumableType.UNSTABLE_TINCTURE);
                break;
            }
            case 1: {
                setType(ConsumableType.BLAST_PACK);
                break;
            }
            case 2 : {
                setType(ConsumableType.CHAKRAM);
                break;
            }
        }
        setName(type.toString());
        setDescription(type.getDescription());
    }


    // Random chance for Consumables to work
    // Unstable Tincture always works
    // Blast pack and Chakram work 75% of the time
    public String use(Attackable target) {
        if (usesLeft > 0) {
            usesLeft--;

            if (type == ConsumableType.UNSTABLE_TINCTURE) {
                StatusEffect effect = EFFECTS[ItemGenerator.rand.nextInt(3)];
                target.addStatusEffectToList(effect);
                return getName() + " inflicts " + effect.toString();
            } else {
                if (ItemGenerator.rand.nextBoolean() || ItemGenerator.rand.nextBoolean()) {
                    return target.takeDamage(new AttackResult(true, (5 * getRarity().getLevel()), type.getDmgType()));
                }

            }
            return "The " + getName() + " misses";
        }
        return "The " + getName() + " has no uses left";
    }
    // When implementing, check after use() call and remove this from inventory if usesLeft = 0;




    @Override
    public String toString() {
        return super.toString() + " " + usesLeft + "/" + maxUses + " Uses";
    }

    @Override
    public String fullDetailsString() {
        return super.stringWithDescription();
    }
}
