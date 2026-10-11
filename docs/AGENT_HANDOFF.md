# Agent Handoff & Quickstart Guide: The Monstrous Sea V2

Welcome! This repository contains the ongoing migration of **The Monstrous Sea** from an educational Java console project to a multiplatform visual roguelike built with **Flutter + Flame (Dart)** and a decoupled domain engine.

---

## 1. Project Layout & Current State

- `TheMonstrousSea_Original/` - The original Java console game (read-only reference).
- `OriginalProjectIdeas&Planning/` - Initial UML diagrams and concept notes (read-only reference).
- `docs/`
  - [`PLAN.md`](file:///c:/Workspace/PersonalProjects/TheMonstrousSeaV2/docs/PLAN.md) - Complete approved architecture & phased execution roadmap.
  - [`GDD.md`](file:///c:/Workspace/PersonalProjects/TheMonstrousSeaV2/docs/GDD.md) - Exact mathematical game design document reverse-engineered from Java.
  - [`bugs.md`](file:///c:/Workspace/PersonalProjects/TheMonstrousSeaV2/docs/bugs.md) - Verified bug resolutions (B1 through B6) approved by the user.
  - [`decisions/0001-platform.md`](file:///c:/Workspace/PersonalProjects/TheMonstrousSeaV2/docs/decisions/0001-platform.md) - Architectural Decision Record for Flutter + Flame + Pure Dart.
  - `agents/` - Detailed task briefs for subagents:
    - [`phase0_foundation.md`](file:///c:/Workspace/PersonalProjects/TheMonstrousSeaV2/docs/agents/phase0_foundation.md) (Done)
    - [`phase1_engine.md`](file:///c:/Workspace/PersonalProjects/TheMonstrousSeaV2/docs/agents/phase1_engine.md) (Ready to start)
    - [`phase2_visuals.md`](file:///c:/Workspace/PersonalProjects/TheMonstrousSeaV2/docs/agents/phase2_visuals.md)
- `tools/java_oracle/` - Java test harness generating ground-truth distribution baselines:
  - Run: `powershell -ExecutionPolicy Bypass -File .\tools\java_oracle\build_fixtures.ps1`
  - Output: `tools/java_oracle/fixtures/*.json` (Monsters, Ships, Item drop distributions).
- `packages/monstrous_core/` - Pure Dart game rules engine package (Zero UI dependencies).
  - Status: Initialized, zero analysis errors, passes `dart analyze` and `dart test`.
  - Foundation classes created: `GameRng`, `BalanceConfig`, sealed `Command`, sealed `GameEvent`.

---

## 2. User-Approved Design Decisions

1. **Flee Mechanic (Bug B3):** Match comment intent: 40% at level 1, dropping by 5% per level, floor at 5% above level 6. Managed in `BalanceConfig`.
2. **Easter Egg:** Keep the "Davy Jones" cheat code intact (grants maxed *Flying Dutchman* and jumps straight to the Kraken).
3. **Aesthetics:** Ink-and-parchment nautical cartography theme. Free open-source nautical fonts (*Pirata One* / *IM Fell English*).
4. **Scope Phasing:** Milestone 1 focuses on a playable vertical slice (Port hub, Rest Area, Sea Chart, Battle Screen, Heir Death loop, Balance Simulator). Full Shipyard drydock/buying/selling ships is deferred to Milestone 2 (Repairs remain in Port for M1).
5. **Bugfixes:** All 6 documented bug fixes (B1 through B6) are formally approved and specified in [`docs/bugs.md`](file:///c:/Workspace/PersonalProjects/TheMonstrousSeaV2/docs/bugs.md).

---

## 3. Immediate Next Steps: Executing Phase 1

The foundation (Phase 0) is complete and committed to git. The next agent or session should proceed directly with **Phase 1** as specified in [`docs/agents/phase1_engine.md`](file:///c:/Workspace/PersonalProjects/TheMonstrousSeaV2/docs/agents/phase1_engine.md):

### Step 1: Content & Procedural Names (`packages/monstrous_core/lib/src/content/`)
- Implement `rarity.dart`, `damage_types.dart`, `ship_weapons.dart`, `monster_weapons.dart`, `ships.dart`, `monsters.dart`, `consumables.dart`.
- Build `names/name_forge.dart` with adjective & name tables for ships, monsters, and captains.

### Step 2: Combat Engine & Monster AI (`packages/monstrous_core/lib/src/rules/`)
- Implement `combat.dart` (d20 attack rolls, status effects, damage reduction, evasion).
- Implement `traits/` (`TentacleTrait`, `InkCloudTrait`, `FortifyTrait`, `EvasionTrait`).
- Implement `monster_ai.dart` (fixing Bug B2).

### Step 3: Economy, Loot & Progression (`packages/monstrous_core/lib/src/rules/`)
- Implement `loot.dart` (fixing Bugs B1 and B4).
- Implement `sea_chart.dart` (4×5 map with Kraken boss at [3][4] and loop scaling).
- Implement `economy.dart` and `lineage.dart` (Freighter stash carryover).

### Step 4: Game Session Machine (`packages/monstrous_core/lib/src/session/`)
- Implement `game_session.dart` dispatching `Command`s and emitting `GameEvent`s.
- Write `full_voyage_test.dart` to simulate a complete voyage through Kraken defeat headlessly.

### Step 5: Balance Simulator (`packages/monstrous_sim/`)
- Create `packages/monstrous_sim` package.
- Implement `bin/simulate.dart` running 10,000 automated bot runs to test endless scaling.

---

## 4. Verification Commands

To verify your work at any point:
```powershell
# Verify Dart Core Engine
cd packages/monstrous_core
dart analyze
dart test

# Rebuild Java Oracle Fixtures (if needed)
cd ../..
powershell -ExecutionPolicy Bypass -File .\tools\java_oracle\build_fixtures.ps1
```
