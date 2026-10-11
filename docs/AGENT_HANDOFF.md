# Agent Handoff & Quickstart Guide: The Monstrous Sea V2

Welcome! This repository contains the modernization of **The Monstrous Sea** from an educational Java console project to a multiplatform visual roguelike built with **Flutter + Flame (Dart)** and a decoupled domain engine.

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
    - [`phase1_engine.md`](file:///c:/Workspace/PersonalProjects/TheMonstrousSeaV2/docs/agents/phase1_engine.md) (Done)
    - [`phase2_visuals.md`](file:///c:/Workspace/PersonalProjects/TheMonstrousSeaV2/docs/agents/phase2_visuals.md) (Ready to start)
- `tools/java_oracle/` - Java test harness generating ground-truth distribution baselines:
  - Run: `powershell -ExecutionPolicy Bypass -File .\tools\java_oracle\build_fixtures.ps1`
  - Output: `tools/java_oracle/fixtures/*.json` (Monsters, Ships, Item drop distributions).
- `packages/monstrous_core/` - Pure Dart game rules engine package (Zero UI dependencies).
  - Status: **Complete & Verified** (106 unit & parity tests passing, `dart analyze` clean).
  - Implements: Content, Combat (d20, status effects), Traits (Fortify, Evasion, Tentacles, Ink Cloud), Economy (Merchant, Repairs), Sea Chart (4x5 grid with Kraken at [3][4]), Lineage (Freighter stash inheritance), State Machine (`GameSession.dispatch(Command) -> List<GameEvent>`), Narration Formatter.
- `packages/monstrous_sim/` - Automated Monte Carlo balance simulation CLI.
  - Status: **Complete & Verified** (6 tests passing, `dart analyze` clean).
  - Implements: Bot strategies (`Reckless`, `Cautious`, `Greedy`, `Random`), `SimulationRunner`, `MarkdownReporter`, CSV exporter.
  - Benchmark: Executed 10,000 automated voyages in 1.5 seconds with 0 crashes and 0 deadlocks. Report saved at `packages/monstrous_sim/reports/report.md`.

---

## 2. User-Approved Design Decisions

1. **Flee Mechanic (Bug B3):** Match comment intent: 40% at level 1, dropping by 5% per level, floor at 5% above level 6. Managed in `BalanceConfig`.
2. **Easter Egg:** Keep the "Davy Jones" cheat code intact (grants maxed *Flying Dutchman* and jumps straight to the Kraken).
3. **Aesthetics:** Ink-and-parchment nautical cartography theme. Free open-source nautical fonts (*Pirata One* / *IM Fell English*).
4. **Scope Phasing:** Milestone 1 focuses on a playable vertical slice (Port hub, Rest Area, Sea Chart, Battle Screen, Heir Death loop, Balance Simulator). Full Shipyard drydock/buying/selling ships is deferred to Milestone 2 (Repairs remain in Port for M1).
5. **Bugfixes:** All 6 documented bug fixes (B1 through B6) are formally approved and specified in [`docs/bugs.md`](file:///c:/Workspace/PersonalProjects/TheMonstrousSeaV2/docs/bugs.md).
6. **No AI-Generated Raster Art:** Strict user constraint to avoid generic AI-generated images. Use programmatic UI widgets, Flutter `CustomPainter` (procedural waves, compass, borders), and license-free/public-domain SVGs or vector line art.

---

- `apps/monstrous_sea/` - Multiplatform Flutter + Flame UI application.
  - Status: **Complete & Verified** (4 widget & combat flow tests passing, `flutter analyze` clean with 0 issues).
  - Implements:
    - Procedural Design System: `InkTheme` (sepia/iron-gall palette, Pirata One / IM Fell English typography), `CartoucheBorderPainter`, `CompassRosePainter`, `AnimatedWavePainter`, `ParchmentTexturePainter`.
    - Procedural & SVG Asset Pipeline: 5 Ships (Standard, Freighter, Ironclad, Corvette, Flying Dutchman), 6 Sea Monsters (Shark, Serpent, Jellyfish, Squid, Crustacean, The Kraken), 4 Nautical UI Icons. Zero AI-generated raster art.
    - Screens: `IntroScreen`, `CaptainScreen`, `PortScreen`, `MerchantScreen`, `SeaChartScreen`, `LootScreen`, `RestScreen`, `DeathScreen`.
    - Flame Combat Arena: `MonstrousSeaBattleGame` (dynamic waves, bobbing ships & monsters, floating damage numbers, camera shake, squid tentacle rendering, ink cloud overlay) + `BattleScreen` HUD with volley triggers, status meters, and chronicle drawer.

---

## 2. User-Approved Design Decisions

1. **Flee Mechanic (Bug B3):** Match comment intent: 40% at level 1, dropping by 5% per level, floor at 5% above level 6. Managed in `BalanceConfig`.
2. **Easter Egg:** Keep the "Davy Jones" cheat code intact (grants maxed *Flying Dutchman* and jumps straight to the Kraken).
3. **Aesthetics:** Ink-and-parchment nautical cartography theme. Free open-source nautical fonts (*Pirata One* / *IM Fell English*).
4. **Scope Phasing:** Milestone 1 focuses on a playable vertical slice (Port hub, Rest Area, Sea Chart, Battle Screen, Heir Death loop, Balance Simulator). Full Shipyard drydock/buying/selling ships is deferred to Milestone 2 (Repairs remain in Port for M1).
5. **Bugfixes:** All 6 documented bug fixes (B1 through B6) are formally approved and specified in [`docs/bugs.md`](file:///c:/Workspace/PersonalProjects/TheMonstrousSeaV2/docs/bugs.md).
6. **No AI-Generated Raster Art:** Strict user constraint to avoid generic AI-generated images. Uses programmatic UI widgets, Flutter `CustomPainter` (procedural waves, compass, borders), and license-free SVG vector art.

---

## 3. Current Phase & Milestone Status

- **Phase 0 (Foundation & Tooling):** Completed & Committed.
- **Phase 1 (Domain Engine & Balance Simulation):** Completed & Committed (106 core tests + 6 sim tests passing).
- **Phase 2 (Flutter + Flame Visuals & UI):** Completed & Committed (4 widget & battle flow tests passing, `flutter analyze` clean).
- **Milestone 1 Vertical Slice Gate:** Ready for user review! Next is Milestone 2 (Audio, Polish, Expanded Shipyard Drydock).

---

## 4. Verification Commands

To verify the entire project suite at any point:
```powershell
# Verify Dart Core Engine
cd packages/monstrous_core
dart analyze
dart test

# Verify Balance Simulator & Run 10k voyages
cd ../monstrous_sim
dart analyze
dart test
dart run bin/simulate.dart --runs 10000 --seed 42

# Verify Flutter App & Flame Arena
cd ../../apps/monstrous_sea
flutter analyze
flutter test
```
