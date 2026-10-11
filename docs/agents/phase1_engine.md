# Agent Brief: Phase 1 - Core Game Engine & Simulation

Phase 1 breaks down into parallelizable workstreams operating on disjoint files.

---

### Stream 1A: Content & Procedural Names
- **Files:** `packages/monstrous_core/lib/src/content/**`
- **Scope:** Define immutable data models and enumerations:
  - `rarity.dart` (Common, Rare, Epic, Legendary, display colors)
  - `damage_types.dart` (Piercing, Slicing, Blast, Fire, Venom, Shock; StatusEffect: Burn, Poison, Stun)
  - `ship_weapons.dart`, `monster_weapons.dart`
  - `monsters.dart`, `ships.dart`, `consumables.dart`
  - `names/name_forge.dart` (Procedural adjectives & titles tables)
- **Exit Criteria:** Content tables match Java values; `dart test test/content/` passes.

---

### Stream 1B: Combat Engine & Monster AI
- **Files:**
  - `packages/monstrous_core/lib/src/rules/combat.dart`
  - `packages/monstrous_core/lib/src/rules/monster_ai.dart`
  - `packages/monstrous_core/lib/src/traits/**`
- **Scope:**
  - $d20$ hit roll vs target AC.
  - Volley attack per weapon type; charge time decrements.
  - Status effects application & ticking (Burn, Poison, Stun).
  - Trait hooks: `TentacleTrait` (tentacle loss on slicing damage), `InkCloudTrait` (+AC buff, hit dispersion), `FortifyTrait` (damage reduction), `EvasionTrait` (dodge).
  - Fix Bug B2 in `monster_ai.dart`.
- **Exit Criteria:** `dart test test/rules/combat_test.dart` and `monster_ai_test.dart` pass.

---

### Stream 1C: Economy, Sea Chart & Lineage
- **Files:**
  - `packages/monstrous_core/lib/src/rules/economy.dart`
  - `packages/monstrous_core/lib/src/rules/loot.dart`
  - `packages/monstrous_core/lib/src/rules/sea_chart.dart`
  - `packages/monstrous_core/lib/src/rules/lineage.dart`
- **Scope:**
  - Loot generator with Fixes B1 & B4.
  - Merchant restock, buy, sell, repair calculations.
  - 4×5 sea chart progression, Kraken encounter at [3][4], map completion scaling.
  - Lineage logic (Freighter stash persistence, Captain death tracking).
- **Exit Criteria:** `dart test test/rules/loot_test.dart`, `sea_chart_test.dart`, `lineage_test.dart` pass.

---

### Stream 1D: Session Machine & Parity Tests
- **Files:**
  - `packages/monstrous_core/lib/src/session/game_session.dart`
  - `packages/monstrous_core/lib/src/narration/narration_formatter.dart`
  - `packages/monstrous_core/test/parity/**`
  - `packages/monstrous_core/test/session/full_voyage_test.dart`
- **Scope:**
  - State machine processing `Command` into `GameEvent` list.
  - End-to-end voyage script defeating Kraken in headless session.
  - Distribution parity checks comparing against `tools/java_oracle/fixtures/*.json`.
- **Exit Criteria:** Full voyage test passes deterministic seeded run; parity within statistical tolerances.

---

### Stream 1E: Balance Simulator CLI
- **Files:** `packages/monstrous_sim/**`
- **Scope:**
  - Command line simulator (`bin/simulate.dart`).
  - Bot decision strategies (`reckless`, `cautious`, `greedy`, `random`).
  - Generates Markdown reports with Mermaid charts and CSV logs.
- **Exit Criteria:** `dart run monstrous_sim:simulate --runs 10000 --seed 42` completes with 0 crashes or infinite loops.
