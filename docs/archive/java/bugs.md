> **HISTORICAL / SUPERSEDED — NOT IMPLEMENTATION GUIDANCE.** Archived 20 October 2026 from `docs/bugs.md` at commit `c16a1a2`. Old approvals, locked specifications, instructions and test counts below apply only to that historical revision. Use the [current documentation guide](../../README.md) and open backlog for present work. Retain this file for explicitly requested historical reference only.

# Original Bug Tracker & Fix Specifications

This document catalogs known bugs and mathematical discrepancies found in the original Java implementation (`TheMonstrousSea_Original`), along with the approved resolution applied in `TheMonstrousSeaV2`.

---

### Bug B1: Unstable Victory Drop Loop Bound
- **Location:** `TheMonstrousSea_Original/src/edu/neumont/csc150/controllers/BattleController.java` (`dropVictoryLoot`)
- **Issue:** The loop condition evaluated `for (int i = 0; i < ItemGenerator.rand.nextInt(SeaMonster.MIN_ITEMS_DROPPED, SeaMonster.MAX_ITEMS_DROPPED + 1); i++)`. Because `rand.nextInt(...)` was evaluated on *every loop iteration*, the upper bound continuously shifted, leading to mathematically distorted drop quantities.
- **Resolution in V2:** Evaluate the total drop count once prior to the loop:
  ```dart
  final dropCount = rng.nextIntRange(minItemsDropped, maxItemsDropped);
  for (var i = 0; i < dropCount; i++) { ... }
  ```
- **Verification:** Unit test verifying victory loot always yields between `minItemsDropped` and `maxItemsDropped` inclusive.

---

### Bug B2: Infinite Loop on Monster Turn Cooldowns
- **Location:** `TheMonstrousSea_Original/src/edu/neumont/csc150/controllers/BattleController.java` (`playMonsterTurn`)
- **Issue:** A `while (!weaponAvailable)` loop randomly sampled `usableWeapons`. If all monster weapons were currently on cooldown, the loop spun infinitely.
- **Resolution in V2:** Filter ready weapons first:
  ```dart
  final readyWeapons = monster.usableWeapons.where((w) => w.chargeCountdown == 0).toList();
  if (readyWeapons.isEmpty) {
    if (monster.specialTrait != null) {
      return monster.specialTrait!.activate(monster, ship, rng);
    }
    return [MonsterHesitated(monster.id)]; // Skips turn cleanly
  }
  ```
- **Verification:** Unit test placing all monster weapons on cooldown and ensuring `takeMonsterTurn()` terminates cleanly with an event.

---

### Bug B3: Discrepancy in Flee Probability
- **Location:** `TheMonstrousSea_Original/src/edu/neumont/csc150/models/attacksandattackables/ships/Ship.java` (`flee`)
- **Issue:** Comment stated: *"40% chance to flee at base level, decreases by 5% each ship level"*. Code implemented `diceRoll(1, 100) > (60 + 5 * getLevel())`, which yielded 35% at Level 1 (`> 65`).
- **Resolution in V2:** User approved matching the comment intent:
  - Level 1: 40% success ($d100 > 60$)
  - Level $L$: $40\% - 5\% \times (L - 1)$
  - Level $> 6$: Flat 5% floor ($d100 > 95$).
  Formula: `success = rng.d100() > min(95, 60 + 5 * (level - 1))`
- **Verification:** Parity/unit tests over levels 1 through 10 asserting exact threshold percentages.

---

### Bug B4: Item Category Drop Distribution Bounds
- **Location:** `TheMonstrousSea_Original/src/edu/neumont/csc150/controllers/ItemGenerator.java` (`randomItem`)
- **Issue:** Used `<=` comparisons against cumulative chances (`diceRoll <= 60` for treasure, `<= 80` for consumable), resulting in distribution intervals of $[0..60]$ (61 values / 61%), $[61..80]$ (20 values / 20%), and $[81..99]$ (19 values / 19%).
- **Resolution in V2:** Strict range partitions:
  - $[0..59]$: Treasure (60%)
  - $[60..79]$: Consumable (20%)
  - $[80..99]$: Ship Weapon (20%)
- **Verification:** Monte Carlo test over 100,000 rolls confirming 60.0%, 20.0%, 20.0% ($\pm 0.5\%$).

---

### Bug B5: Freighter Heir String Formatting
- **Location:** `TheMonstrousSea_Original/src/edu/neumont/csc150/controllers/GameController.java` (`runPostDeathScreen`)
- **Issue:** Printed object reference directly instead of name: `"Not all of the Cargo fits onto The " + player.getCurrentShip()`.
- **Resolution in V2:** Access ship display name formatted cleanly in `CaptainLost` and inheritance events.
- **Verification:** Visual and event payload assertion.

---

### Bug B6: Static Global State
- **Location:** `BattleMap.battleMap`, `BattleMap.currentRow`, `ItemGenerator.rand`.
- **Issue:** Static globals prevented deterministic multi-session testing, isolated fuzzing, and save/load state serialization.
- **Resolution in V2:** Fully encapsulated session state inside `GameSession`, with injected `GameRng` and `BalanceConfig`.
- **Verification:** Concurrently running isolated `GameSession` instances with different seeds without side effects.
