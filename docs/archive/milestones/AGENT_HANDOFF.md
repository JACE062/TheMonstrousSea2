> **HISTORICAL / SUPERSEDED — NOT IMPLEMENTATION GUIDANCE.** Archived 20 October 2026 from `docs/AGENT_HANDOFF.md` at commit `c16a1a2`. Old approvals, locked specifications, instructions and test counts below apply only to that historical revision. Use the [current documentation guide](../../README.md) and open backlog for present work. Retain this file for explicitly requested historical reference only.

# Agent Handoff & Quickstart Guide: The Monstrous Sea V2

Welcome! This repository contains the modernization of **The Monstrous Sea** from an educational Java console project to a multiplatform visual roguelike built with **Flutter + Flame (Dart)** and a decoupled domain engine.

---

## 1. Project Layout & Current State

- `TheMonstrousSea_Original/` - The original Java console game (read-only reference).
- `OriginalProjectIdeas&Planning/` - Initial UML diagrams and concept notes (read-only reference).
- `docs/`
  - [`PLAN.md`](../java/PLAN.md) - Complete approved architecture & phased execution roadmap.
  - [`GDD.md`](../java/GDD.md) - Exact mathematical game design document reverse-engineered from Java.
  - [`ROGUE_LITE_DESIGN.md`](../design/ROGUE_LITE_DESIGN.md) - Rogue-lite progression, blueprints, hardpoints, nemesis system, and bloodline GDD.
  - [`COMBAT_SYSTEM_REDESIGN.md`](../design/COMBAT_SYSTEM_REDESIGN.md) - Complete tactical combat overhaul specification: 3-band range system, telegraphed intents, 4 ocean powers, and master refits.
  - [`bugs.md`](../java/bugs.md) - Verified bug resolutions (B1 through B6) approved by the user.
  - [`decisions/0001-platform.md`](../../decisions/0001-platform.md) - Architectural Decision Record for Flutter + Flame + Pure Dart.
- `tools/java_oracle/` - Java test harness generating ground-truth distribution baselines:
  - Run: `powershell -ExecutionPolicy Bypass -File .\tools\java_oracle\build_fixtures.ps1`
  - Output: `tools/java_oracle/fixtures/*.json` (Monsters, Ships, Item drop distributions).
- `packages/monstrous_core/` - Pure Dart game rules engine package (Zero UI dependencies).
  - Status: **Complete & Verified** (197 unit, parity, and rogue-lite tests passing, `dart analyze` clean).
  - Implements: Content, Combat (d20, status effects), Traits (Fortify, Evasion, Tentacles, Ink Cloud), Economy (Merchant, Repairs), Sea Chart (dead-reckoning navigation, multi-region escalating routes, haven/cove careening), Lineage (ProfileData, Heir succession, Nemesis generation), State Machine (`GameSession.dispatch(Command) -> List<GameEvent>`), Narration Formatter, Flagship Blueprints & Hardpoints, Covenant of the Deep (Pact Burden, Titan Trophy Progression, Eldritch Relics, Cursed Monuments).
- `packages/monstrous_sim/` - Automated Monte Carlo balance simulation CLI.
  - Status: **Complete & Verified** (6 tests passing, `dart analyze` clean).
  - Implements: Bot strategies (`Reckless`, `Cautious`, `Greedy`, `Random`), `SimulationRunner`, `MarkdownReporter`, CSV exporter.
  - Benchmark: Executed 10,000 automated voyages in 1.5 seconds with 0 crashes and 0 deadlocks. Report saved at `packages/monstrous_sim/reports/report.md`.
- `apps/monstrous_sea/` - Multiplatform Flutter + Flame UI application.
  - Status: **Complete & Verified** (82 widget, combat flow & Covenant UI tests passing, `flutter analyze` clean with 0 issues).
  - Implements:
    - Procedural Design System: `InkTheme` (sepia/iron-gall palette, Pirata One / IM Fell English typography), `CartoucheBorderPainter`, `CompassRosePainter`, `AnimatedWavePainter`, `ParchmentTexturePainter`.
    - Curated ink-and-parchment raster sprites for all ship blueprints, monsters, weapons, encounters, and UI icons.
    - Screens: `IntroScreen`, `CaptainScreen`, `PortScreen`, `MerchantScreen`, `SeaChartScreen`, `HelmScreen`, `LootScreen`, `RestScreen`, `DeathScreen`, `SmugglerScreen`, `ShrineScreen`, `RespiteIslandScreen`, `ShipwreckScreen`, `VictoryScreen`.
    - Shipwright's Drafting Table & Hardpoint Expansion: Meta-currency ledger, blueprint cards, hardpoint slots, signature armament tier progression (Tiers I -> II -> III), and reserve auxiliary expansion.
    - Covenant Altar & Post-End Loops: 3-tab Covenant of the Deep modal (Pact Burden modifiers, Eldritch Relic weapons, Cursed Harbor Monuments), Caldera Dilemma (Shatter vs. Claim the Core), and deep ascension succession flow.
    - Flame Combat Arena: `MonstrousSeaBattleGame` (dynamic waves, bobbing ships & monsters, floating damage numbers, camera shake, squid tentacle rendering, ink cloud overlay) + `BattleScreen` HUD with volley triggers, status meters, and chronicle drawer.

---

## 2. User-Approved Design Decisions

1. **Flee Mechanic (Bug B3):** Match comment intent: 40% at level 1, dropping by 5% per level, floor at 5% above level 6. Managed in `BalanceConfig`.
2. **Easter Egg:** Keep the "Davy Jones" cheat code intact (grants maxed *Flying Dutchman* and jumps straight to the Kraken).
3. **Aesthetics:** Ink-and-parchment nautical cartography theme. Free open-source nautical fonts (*Pirata One* / *IM Fell English*).
4. **Art Pipeline:** Curated, stylized raster art (`.png`) for entity sprites (ships, monsters, weapons, icons) generated via the user's tuned model pipeline to maintain consistent ink-and-parchment cartographic styling without generic AI sheen. SVGs and Flutter `CustomPainter` are used for structural frames, animated waves, and compass linework.
5. **Rogue-lite Blueprints & Hardpoints:**
   - Single returned hull from the Abyssal Pact.
   - 5 Blueprints: `Standard`, `Ironclad`, `Clipper`, `Bombardier`, `Corsair`.
   - Distinct deck hardpoints (`broadside`, `prow`, `mortar`, `utility`, `auxiliary`) with signature weapon capabilities and tactical roles.
   - Dual-source meta-currencies: Materials (exploration) and Organics (combat/apex hunting).
   - In-run gold is strictly transient ("use it or lose it").
6. **Covenant of the Deep & Titan Trophies (Stage 4):**
   - Strictly **Pact Burden** (never "Heat").
   - 7 Pacts cleanly mapped to active systems with zero vestigial mechanics.
   - Guaranteed Titan Trophies drop on every boss kill (Kraken Beak, Serpent Scale, Leviathan Core).
   - Caldera Climax choice: Shatter the Core (ends loop & salt-sickness) vs. Claim the Core (captain ascends as Warden, flagships loops with Core fused into keel, unlocking Covenant Altar).
   - Primordial Cinders drop exclusively from Region Titans defeated under active Pact Burden.
   - Three-Chapter Trophy Progression: Signature Armament Tiers (I -> II -> III), Eldritch Relics, and Cursed Harbor Monuments.

---

## 3. Current Phase & Milestone Status

- **Phase 0 & 1 (Foundation & Domain Engine):** Completed & Committed.
- **Phase 2 (Visuals, Screens & Encounters):** Completed & Committed.
- **Rogue-lite Stage 1 (Profile, Heir Succession, Nemesis, Multi-Region Navigation):** Completed & Verified.
- **Rogue-lite Stage 2 (Encounter Variety, Sea Shrines, Smuggler Ketches, Havens):** Completed & Verified.
- **Rogue-lite Stage 3 (The Bloodbound Flagship, Blueprints & Hardpoints):** Completed & Verified.
- **Rogue-lite Stage 4 (Covenant of the Deep, Titan Trophies & Post-End Loops):** Completed & Verified.
- **Combat Redesign Phase 1 (Domain Core & Weight Removal):** Completed & Verified (210 core tests + 82 Flutter tests passing, 0 lint issues).
  - Retired weapon weight restriction in favor of Physical Deck Hardpoints and Cargo Stowage.
  - Implemented 3 discrete Range Bands (`Long`, `Medium`, `Short`) with action-driven momentum (Ram charges in, Culverin snipes from afar, Harpoon Winch reels in, Evasive Maneuver tacks away).
  - Scaled damage and accuracy by distance (Long: Culverin/Mortar +25% dmg, Cannon -15% acc, Flagship +15% evasion; Short: Ram +30% collision, Mortar point-blank backfire splash to own hull, Flagship -15% evasion).
- **Combat Redesign Phase 2 (Telegraphed Monster Intent System):** Implemented.
- **Combat Redesign Phase 3A (Intrinsic Hardpoints & Tactical Belt):** Implemented.
- **Combat Redesign Phase 3B (Primordial Ocean Powers):** Implemented: four powers across three dedication sockets and three tiers, weighted shrine encounters, combat riders and synergies, persistent voyage blessings, responsive shrine/HUD UI, and simulation bot support. See [implementation notes and verification](phase3b_ocean_powers.md) for current details; earlier section test counts describe historical milestones.
- **Post-Phase-3B Playtest Remediation:** Implemented. See [19 October playtest notes](../playtests/PLAYTEST_2026_10_19.md) for Standard-only first-voyage onboarding, enforced blueprint locks, voyage-only refits/tempering, chart/checkpoint fixes, readable inspection UI, and the single-use consumable decision. A native Windows first-voyage integration test now passes.
- **20 October Playtest Follow-up:** Open, documented only. See the [prioritized backlog](../playtests/PLAYTEST_2026_10_20.md) for 22 findings and proposed chunks. Start with home-port versus post-boss stronghold lifecycle, blessing/build preservation, and the dead-end Abandon Hunt route; then audit combat and navigation. Shared permanent family names and command-station/chart layouts need design discussion. Master Refits remain planned Phase 4 work. [Art/icon work is deferred](../playtests/UI_ART_BACKLOG.md); do not generate new assets in this documentation batch.
- **Rogue-lite Stage 5 (Atmospheric Immersion, Port Civic Restoration & Audio/Visual VFX):** Queued following combat overhaul.

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
