# Phase 3A Specification: 3-Hardpoint Architecture, Utilities & Tactical Belt

> **Status:** Locked Specification for Phase 3A Implementation  
> **Scope:** Intrinsic 3-Hardpoint Blueprint Topology, Normalized Range Curves, Utility Hardpoints, Quick-Action Tactical Belt, and Shop/Loot Refactoring.  
> **Out of Scope (Deferred to Phase 3B):** Sea Shrine Ocean Power Blessings (4 Powers $\times$ Hardpoint Permutations) and Master Refit ("Hammer") Transformations.

---

## 1. Core Architectural Shift: Intrinsic 3-Hardpoint Topology

Weapons are no longer generic inventory items dropped by monsters or swapped in and out of untyped slots. Every [`FlagshipBlueprint`](../packages/monstrous_core/lib/src/model/flagship_blueprint.dart) permanently mounts **strictly 3 intrinsic Hardpoints** for the entire voyage:

1. **Broadside (`HardpointType.broadside`)**: Primary hull battery (`0T` Cooldown). Reliable every-turn attack with a hull-specific firing profile and damage type.
2. **Signature (`HardpointType.signature`)**: Defining prow/centerline tactical armament (`1T` Cooldown across all ships).
3. **Utility (`HardpointType.utility`)**: Tactical control, defense, or targeting mechanism (`2T` Cooldown across all ships). Replaces legacy hardcoded `ExecuteShipSpecialAction` buttons so Utility mounts are first-class hardpoints eligible for Phase 3B Blessings and Refits.

### Retired Legacy Mechanics
- **Auxiliary Weapon Slot (`HardpointType.auxiliary`)**: Removed. The 4 legacy Java weapons (*Torpedo Launcher*, *Blade Launcher*, *Lightning Railgun*, *Flamethrower*) are retired as standalone lootable items and reserved for Phase 3B Shrine Infusions and Master Refits.
- **Equip / Unequip Weapon Actions**: Removed. Hardpoints cannot be unequipped into cargo or stacked with duplicate weapons.
- **Weapon Weight (`maxWeaponWeight`, `equipWeight`)**: Completely removed from `ShipState`, ship factories, and upgrade formulas.
- **Monster Weapon Drops**: Removed from [`loot.dart`](../packages/monstrous_core/lib/src/rules/loot.dart). Monsters never drop `ShipWeapon` items.
- **Unimplemented "Poise" Vestiges**: Removed (`windupDamageTaken` on `MonsterState`). Staggering/interrupting a Boss Wind-Up or resetting Shark Frenzy is strictly governed by **Stun** effects and specific weapon/refit identities.

---

## 2. The 5 Flagship Blueprints: Hardpoint Matrix & Range Math

### Normalization Rule
Every offensive hardpoint has a **Base Damage** and at least one optimal range band anchored at **`100%` effectiveness**, with off-optimal ranges scaling relative to `100%`.

### 2.1 Broadside Hardpoints (`0T` Cooldown)

| Blueprint | Broadside Name | Damage Type | Base Dmg (L1) | Base Hit | Short | Medium | Long | Special Trait |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| **Standard** | **Naval Cannon Battery** | Piercing | `10–12` | `85%` | `85%` | **`100%`** | `65%` | `-15%` Accuracy at Long range. |
| **Ironclad** | **Heavy Carronades** | Piercing | `12–15` | `85%` | **`100%`** | `80%` | `35%` | High close-quarters slug power; steep Long falloff. |
| **Clipper** | **Long-Barrel Swivel Guns** | Piercing | `9–11` | `90%` | `75%` | **`100%`** | **`100%`** | No Long-range accuracy penalty; flat Medium/Long damage. |
| **Corsair** | **Chain-Shot Broadside** | Slicing | `10–13` | `85%` | **`100%`** | `85%` | `45%` | Deals `+20%` bonus damage against **Pinned** targets; severs tentacles. |
| **Bombardier** | **Shrapnel Howitzers** | Blast | `10–13` | `85%` | `70%` | **`100%`** | `75%` | Blast damage deals `1.5x` to Crustacean `carapacePlating`. |

### 2.2 Signature Hardpoints (`1T` Cooldown)

| Blueprint | Signature Name | Damage Type | Base Dmg (L1) | Base Hit | Short | Medium | Long | Tactical Behavior |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| **Standard** | **Twin Chaser Cannons** | Piercing | `16–20` | `95%` | `75%` | **`100%`** | `90%` | High-velocity twin shot with `+10%` accuracy bonus. |
| **Ironclad** | **Reinforced Prow Ram** | Blast | `20–25` | `90%` | **`100%`** | **`125%`** | *Unusable* | **From Short**: `100%` Blast (`1.5x` vs Carapace).<br>**From Medium**: Advances ship `Medium -> Short` *before* impact, dealing **`125%` kinetic charge damage**. Cannot be initiated from Long. |
| **Clipper** | **Precision Culverin** | Piercing | `16–20` | `95%` | `40%` | `85%` | **`100%`** | Pierces `50%` of `carapacePlating` directly to monster HP. |
| **Corsair** | **Harpoon Winch** | Piercing | `14–18` | `85%` | `85%` | **`100%`** | `85%` | On hit: **Pulls** monster `1` band closer (`Long -> Med -> Short`), severs tentacles, and inflicts **Pinned (`1T`)** (cancels monster movement intent and halves monster evasion). |
| **Bombardier** | **Heavy Siege Mortar** | Blast | `22–28` | `80%` | `70%` | `85%` | **`100%`** | Deals `2.0x` damage to `carapacePlating` and disrupts Shark Frenzy.<br>**At Short Range**: Deals `70%` damage to monster, but splashes **`25%` of dealt damage** back onto the Bombardier's hull. |

### 2.3 Utility Hardpoints (`2T` Cooldown)

| Blueprint | Utility Name | Cooldown | Exact Mechanical Resolution |
| :--- | :--- | :---: | :--- |
| **Standard** | **Gunnery Drill** | `2T` | • Grants **Brace (`20%` incoming damage reduction)** for the current round.<br>• Grants **Next Volley Buff**: `+15%` Accuracy and `+20%` Damage on the ship's next offensive hardpoint attack. |
| **Ironclad** | **Fortify Iron Plates** | `2T` | • Increases `currentDmgReduction` by `+dmgReductionMod` (`2 * level`) for the battle.<br>• **Anchors** the hull for the current round (immune to monster push/pull effects). |
| **Clipper** | **Evasive Rigging** | `2T` | • Doubles `currentEvasion` (`baseEvasion * 2`, up to `95%`) until the next dodged attack.<br>• Immediately shifts the ship **`1` range band away** from the monster (`Short -> Med -> Long`). |
| **Corsair** | **Drifting Tether-Trap** | `2T` | • Base Trap Damage: `14–18` Slicing (scaled by level/tempering).<br>• Launches a floating tether-trap `1` band ahead of the ship:<br>  - Fired at **Short (`0`)**: `trapDistanceToMonster = 0` $\rightarrow$ **Detonates immediately**.<br>  - Fired at **Medium (`1`)**: Sets `trapDistanceToMonster = 1` (sits at Short).<br>  - Fired at **Long (`2`)**: Sets `trapDistanceToMonster = 2` (sits at Medium).<br>• **Distance Adjustments**:<br>  - Monster advances `1` band closer: `trapDistanceToMonster -= 1`.<br>  - Monster retreats `1` band away: `trapDistanceToMonster += 1`.<br>  - Player pulls monster `1` band closer (Harpoon): `trapDistanceToMonster -= 1`.<br>  - Start of each new round (Ocean Current): `trapDistanceToMonster -= 1`.<br>• **Detonation (`trapDistanceToMonster <= 0`)**: Deals Slicing damage to the monster and inflicts **Pinned (`1T`)**, immediately halting any remaining movement in the monster's current intent. |
| **Bombardier** | **Phosphor Spotter Flare** | `2T` | • Illuminates the monster for **2 turns** (`flareTurnsRemaining = 2`):<br>  1. Clears `isObscured` (disperses Squid/Kraken ink) and suppresses monster Evasion.<br>  2. Grants `+15%` Accuracy to all attacks against the monster.<br>  3. Monster takes **`+25%` bonus damage from all Blast attacks** (*Shrapnel Howitzers* & *Heavy Siege Mortar*). |

---

## 3. Carapace Shield Interaction (Grounded in Existing Code)

- `MonsterState.carapacePlating` remains the Crustacean's dedicated armor shield bar above its HP:
  - **Piercing / Slicing / Shock**: Absorbed `1:1` by `carapacePlating`; overflow hits HP.
  - **Precision Culverin**: `50%` absorbed by `carapacePlating`, `50%` pierces directly to HP.
  - **Blast (*Howitzers*, *Prow Ram*, *Heavy Mortar*)**: Deals `1.5x` (`2.0x` for *Heavy Mortar*) damage to `carapacePlating`.
  - **Fire**: Bypasses `carapacePlating` completely to hit HP.
- No separate "plate count" or "poise bar" is added.

---

## 4. Tactical Consumable Belt (Replacing Cargo Tonnage)

### 4.1 Slot-Based Belt & Free Quick-Actions
- **Retire Cargo Tonnage**: Replace abstract `maxCargo` weight capacity (`15–80` tons) with a **Tactical Belt** holding **3 Consumable Slots** by default (`maxTacticalSlots = 3`, expandable to `4` on Corsair or via Hull Upgrade).
- **Retire RPG Rarity Tiers on Weapons/Items**: Hardpoints use **Tempering Marks (`Mk I`, `Mk II`, `Mk III`)** rather than random `Common`/`Rare`/`Epic`/`Legendary` loot rolls.
- **0-Turn-Cost Quick Action (1 Per Turn)**:
  - Using a consumable from the Tactical Belt in combat is a **Quick Action** (`usedQuickItemThisTurn = false -> true`), **NOT** a full turn action.
  - The player can trigger **1 Tactical Consumable** AND still execute their **Helm Order + Hardpoint Action** on the same turn.

### 4.2 Core Tactical Consumables
1. **Hull Patch Kit** (*Emergency Planks*): Restores `30%` of `maxHp` immediately as a Quick Action.
2. **Bottled Kraken Ink** (*Smoke Screen*): Grants `+25%` Evasion for 1 round.
3. **Alchemical Pitch Flask** (*Incendiary Coating*): Empowers your next hardpoint attack this turn to deal `+25%` bonus Fire damage and inflict `StatusEffect.burn`.
4. **Black-Powder Charge** (*Concussive Bomb*): Deals instant Blast damage to `carapacePlating` / hull HP.

---

## 5. Ports, Smugglers, and Progression Economy

With random weapon drops and weapon shops removed, economy nodes are structured around **Hull Upgrades**, **Hardpoint Tempering**, and **Tactical Supplies**:

1. **Port Shipwright / Merchant**:
   - **Hull Repair**: Restore missing HP for Doubloons.
   - **Hull Tier Upgrade (`Lvl 1 -> 2 -> 3 -> 4`)**: Increases Max HP, Armor Class, Class Defense (`baseDmgReduction` / `baseEvasion`), and scales the base damage of allequipped hardpoints by `+25%` per ship level.
   - **Hardpoint Tempering (`Mk I -> Mk II -> Mk III`)**: Spend Doubloons to permanently temper a specific hardpoint (**Broadside**, **Signature**, or **Utility**), boosting its effectiveness/damage by `+20%` per Mark (`Mk II = 1.2x`, `Mk III = 1.4x`).
   - **Tactical Belt Restock**: Purchase **Hull Patch Kits**, **Bottled Kraken Ink**, and **Alchemical Pitch Flasks**.
2. **Smuggler's Cove**:
   - Sells discounted/high-impact **Tactical Consumables** and emergency **Hardpoint Tempering** or hull patches. (In Phase 3B, Smugglers will also offer contraband Master Refits).
3. **Covenant of the Deep Meta-Upgrade**:
   - Repurpose `auxiliaryExpansionUnlocked` from adding a 4th weapon slot to **Expanded Ordnance Belt & Tempering (`+1 Tactical Belt Slot` + starts run with Broadside pre-tempered to `Mk II`)**.
