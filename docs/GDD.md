# Game Design Document (GDD): The Monstrous Sea V2

This document reverse-engineers and formalizes every mechanic, mathematical formula, scaling curve, drop table, and rule from the original Java implementation (`TheMonstrousSea_Original`) as the canonical specification for the pure Dart engine (`packages/monstrous_core`).

---

## 1. Core Premise & Progression Loop

- **Role:** You captain a ship embarking on hunts against sea monsters across turn-based encounters.
- **Progression Map:** A 4×5 grid of battles:
  - Row 0 (Cols 0-4): Battles Level 1
  - Row 1 (Cols 0-4): Battles Level 2
  - Row 2 (Cols 0-4): Battles Level 3
  - Row 3 (Cols 0-3): Battles Level 4
  - Row 3 (Col 4): **Boss: The Kraken** (Difficulty 5 Squid)
- **Map Loop & Scaling:**
  - Upon defeating The Kraken (completing the map), `timesMapHasBeenCompleted` increments by 1.
  - The map refreshes:
    - Standard cells: Level = `row + 1 + (timesMapHasBeenCompleted * 4)`
    - Final cell: Level = `row + 2 + (timesMapHasBeenCompleted * 4)`
- **Loop Flow:**
  - After victory: Player enters `RestArea`, choosing to either `Continue to next Battle`, `Adjust Weapons`, `Drop Cargo`, or `Return to Port`.
  - Returning to port / Fleeing: Resets map position to start, refreshes Merchant inventory.
  - Death: Perma-death resets current ship, un-stashed cargo, and gold.

---

## 2. Combat Resolution Formulas

### 2.1 Attack Roll & Hit Resolution
- **Die Roll:** $d20$ ($1$ to $20$).
- **Hit Condition:**
  $$\text{Hit} \iff (d20 + \text{WeaponHitMod}) \ge \text{TargetArmorClass}$$
- **Weapon Hit Modifier:**
  - Ship weapons: $2 \times \text{WeaponLevel}$
  - Monster weapons: $1 \times \text{WeaponLevel}$

### 2.2 Damage & Reductions
- **Base Damage:** Rolled from weapon damage range, scaled by item level multiplier:
  - Damage dealt directly reduces target Hull/HP: $\text{HP}_{\text{new}} = \max(0, \text{HP} - \text{Damage})$.
- **Ironclad Damage Reduction:**
  - Passive mitigation: Reduces incoming hit damage by `currentDmgReduction` (Base: $3 \times \text{Level}$).
  - Fortify action: Increases damage reduction by `dmgReductionMod` ($2 \times \text{Level}$) for the encounter.
- **Corvette Evasion:**
  - Base Evasion: $10\% + 5\% \times \text{Level}$ (capped at 50%).
  - Evasive Maneuvers action: Doubles current evasion until an attack is dodged, then resets to base.
  - Dodging completely negates damage.
- **Squid Tentacle Severing:**
  - Slicing damage against Squid severs tentacles:
    $$\text{TentaclesSevered} = \left\lceil \frac{\text{DamageTaken}}{10} \right\rceil$$
  - Squid makes an attack roll for *each* intact tentacle remaining.

### 2.3 Status Effects
- **BURN:** Inflicts $5 \times \text{BattleDifficultyLevel}$ Fire damage at start of turn. 25% chance to extinguish each turn ($d100 > 75$).
- **POISON:** Inflicts $5 \times \text{BattleDifficultyLevel}$ Venom damage at start of turn. 25% chance to wear off each turn ($d100 > 75$).
- **STUN:**
  - Player ship: Always lasts exactly 1 turn, then clears.
  - Sea Monsters: 50% chance to wear off each turn ($d100 > 50$). Skips action while stunned.

### 2.4 Flee Mechanics
- **Base Flee Chance (Level 1):** 40% (as intended by original commentary; $d100 > 60$).
- **Level Scaling:** Decreases by 5% per level up to Level 6.
- **Level > 6:** Hardcoded minimum floor of 5% ($d100 > 95$).

---

## 3. Entities & Stats

### 3.1 Ships
| Class | Base HP Formula | Base AC | Base Cargo | Weapon Weight Cap | Special Mechanic |
|---|---|---|---|---|---|
| **Standard Ship** | $50 + [40..60] \times L$ | $8 + 2L$ | $5 + [10..20] \times L$ | $7L$ | Well-rounded baseline |
| **Freighter** | $50 + [50..70] \times L$ | $10 + 2L$ | $15 + [15..30] \times L$ | $5L$ | Stash: 5% gold & safe cargo persist through death |
| **Ironclad** | $25 + [65..85] \times L$ | $10 + 2L$ | $5 + [5..7] \times L$ | $10L$ | Armor plating: Flat damage reduction & Fortify |
| **Corvette** | $40 + [30..50] \times L$ | $4 + 2L$ | $5 + [5..15] \times L$ | $5L$ | High speed: Evasion chance & Evasive Maneuvers |

*Where $L$ is ship level.*

### 3.2 Monsters
| Species | Base HP | Base AC | Attacks | Special Ability |
|---|---|---|---|---|
| **Shark** | $40L$ | $6 + 2L$ | Ram, Jaws | Frenzy (offensive buff) |
| **Serpent** | $45L$ | $6 + 2L$ | Ram, Tail | Constrict |
| **Jellyfish**| $35L$ | $4 + 2L$ | Ram, Stinging Tendrils | Shock / Stun sting |
| **Squid** | $50L$ | $6 + 2L$ | Ram, Tentacles ($5L$ count) | Ink Cloud (boosts AC by $2L$, 25% to disperse on hit) |
| **Crustacean** | $60L$ | $10 + 2L$ | Ram, Claw | Heavy Carapace (appears $\ge$ level 2) |
| **The Kraken** | 300 HP | 18 AC | Tentacles (25 count), Ram | Colossal Boss at Map End (Level 5) |

---

## 4. Itemization & Economy

### 4.1 Rarity & Drop Rates
- **Drop Category Chances (Fixed B4):**
  - Treasure: 60% ($0 \le \text{roll} < 60$)
  - Consumable: 20% ($60 \le \text{roll} < 80$)
  - Ship Weapon: 20% ($80 \le \text{roll} < 100$)
- **Victory Drop Count (Fixed B1):** Rolled once per victory: $[3..6]$ items.
- **Item Level Spread relative to Monster Level ($M_L$):**
  - $\le 15\%$: $\max(1, M_L - 3)$
  - $16..30\%$: $\max(1, M_L - 2)$
  - $31..50\%$: $\max(1, M_L - 1)$
  - $51..80\%$: $M_L$
  - $81..95\%$: $M_L + 1$
  - $96..99\%$: $M_L + 2$
  - $100\%$: $M_L + 3$

### 4.2 Weapons & Weight
| Weapon | Weight | Charge Time (Rounds) | Base Dmg ($D$) | Damage Type | Special |
|---|---|---|---|---|---|
| **Cannon** | 2 | 0 (Instant) | $[8..12] \times L$ | Piercing | Reliable baseline |
| **Torpedo Launcher** | 4 | 2 | $[13..17] \times L$ | Blast | High burst |
| **Blade Launcher** | 3 | 1 | $[13..17] \times L$ | Slicing | Effective vs Squid tentacles |
| **Lightning Railgun**| 3 | 3 | $[20..30] \times L$ | Shock | Stun chance |
| **Flamethrower** | 3 | 3 | $[20..30] \times L$ | Fire | Inflicts Burn |
