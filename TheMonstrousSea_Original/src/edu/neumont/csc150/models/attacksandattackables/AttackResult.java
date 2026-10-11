package edu.neumont.csc150.models.attacksandattackables;

import edu.neumont.csc150.models.enums.DamageType;
import edu.neumont.csc150.models.enums.StatusEffect;

public class AttackResult {
    private String attackString;
    private boolean attackHit;
    private int attackDmg;
    private DamageType attackType;
    private boolean inflictsEffect;
    private StatusEffect effectInflicted;

    public String getAttackString() {
        return attackString;
    }

    public void setAttackString(String attackString) {
        this.attackString = attackString;
    }


    public boolean didAttackHit() {
        return attackHit;
    }

    private void setAttackHit(boolean attackHit) {
        this.attackHit = attackHit;
    }

    public int getAttackDmg() {
        return attackDmg;
    }

    private void setAttackDmg(int attackDmg) {
        this.attackDmg = attackDmg;
    }

    public DamageType getAttackType() {
        return attackType;
    }

    private void setAttackType(DamageType attackType) {
        this.attackType = attackType;
    }

    public boolean inflictsEffect() {
        return inflictsEffect;
    }

    private void setInflictsEffect() {
        this.inflictsEffect = true;
    }

    public StatusEffect getEffectInflicted() {
        return effectInflicted;
    }

    private void setEffectInflicted(StatusEffect effectInflicted) {
        this.effectInflicted = effectInflicted;
    }

    // Has different constructors for if an attack inflict a status effect or not
    public AttackResult(boolean attackHit, int attackDmg, DamageType attackType) {
        setAttackHit(attackHit);
        setAttackDmg(attackDmg);
        setAttackType(attackType);

    }

    public AttackResult(boolean attackHit, int attackDmg, DamageType attackType, StatusEffect effectInflicted) {
        this(attackHit, attackDmg, attackType);
        setInflictsEffect();
        setEffectInflicted(effectInflicted);
    }


    // Constructors for monster-specific attacks, so they can return a string representation of their attacks
    public AttackResult(String attackString, boolean attackHit, int attackDmg, DamageType attackType) {
        setAttackString(attackString);
        setAttackHit(attackHit);
        setAttackDmg(attackDmg);
        setAttackType(attackType);

    }

    public AttackResult(String attackString, boolean attackHit, int attackDmg, DamageType attackType, StatusEffect effectInflicted) {
        this(attackString, attackHit, attackDmg, attackType);
        setInflictsEffect();
        setEffectInflicted(effectInflicted);
    }
}
