# The Monstrous Sea V2 — Project Instructions & Architecture Guide

This document defines the architectural boundaries, execution protocols, core game mechanics, and engineering guidelines for **The Monstrous Sea V2**. All AI agents and developers working in this repository must adhere to these instructions.

---

## 1. Repository Layout & Architecture

The project is structured as a multiplatform Dart/Flutter monorepo:

- **`packages/monstrous_core/`**: Pure Dart game engine, domain models, combat rules, state machine (`GameSession`), RNG, traits, and procedural generation.
  - **CRITICAL**: Zero UI dependencies. NEVER import `package:flutter`, `package:flame`, `dart:ui`, or any UI package here.
  - State transitions are strictly command-driven: `List<GameEvent> events = session.dispatch(Command command)`.
  - All gameplay randomness MUST be passed through `GameRng` (`SeededGameRng`) to preserve deterministic replayability and Monte Carlo auditability.
- **`packages/monstrous_sim/`**: Headless balance simulation CLI. Runs Monte Carlo automated voyages across thousands of seeds with automated bot strategies (`CautiousBot`, `RecklessBot`, `GreedyBot`, `RandomBot`).
- **`apps/monstrous_sea/`**: Flutter + Flame visual application.
  - Implements the ink-and-parchment cartographic aesthetic (`InkTheme`, `CartoucheBorderPainter`, `CompassRosePainter`).
  - Contains game screens, interactive widgets, audio, and the Flame battle arena (`MonstrousSeaBattleGame`).
  - Managed by `GameController` which wraps `GameSession` and publishes state changes via `ChangeNotifier`.
- **`docs/`**: Canonical documentation:
  - `GDD.md`: Reverse-engineered math and design specifications from Java.
  - `PLAN.md`: Phased roadmap and milestone definitions.
  - `ROGUE_LITE_DESIGN.md`: The Rogue-lite Evolution, Abyssal Pact lore, Bloodbound Flagship, Meta-Economy, and Progression GDD.
  - `bugs.md`: Documented resolutions for legacy Java bugs (B1 through B6).
  - `decisions/`: Architecture Decision Records (ADRs).
- **`TheMonstrousSea_Original/`**: Legacy Java console source code (read-only reference).
- **`OriginalProjectIdeas&Planning/`**: Legacy design diagrams and notes (read-only reference).

---

## 2. Terminal Execution Guidelines & Avoiding Sandbox Stalls

> [!CAUTION]
> **Why `dart test` and `dart analyze` stall on Windows:**
> Dart's analysis server and test runner daemon spawn background child worker isolates communicating over local loopback TCP sockets (`127.0.0.1` / IPC). Inside standard sandboxed execution environments on Windows, loopback socket communication and named pipes are restricted, causing the analysis server or test runner to hang indefinitely or time out.

### The Protocol for Reliable Command Execution
1. **Always Use `BypassSandbox: true` for Dart/Flutter Tooling on Windows:**
   - Run `dart test`, `flutter test`, `dart analyze`, and `flutter analyze` with `BypassSandbox: true`.
2. **Explicitly Target Packages for `dart analyze`:**
   - **NEVER** run a bare `dart analyze` or `dart analyze .` from the root directory. Scanning non-package folders or untracked tool files can freeze or produce spurious errors.
   - **ALWAYS** specify explicit package directories:
     ```powershell
     dart analyze packages/monstrous_core packages/monstrous_sim apps/monstrous_sea
     ```
3. **Run Tests Inside Package Directories:**
   - Switch to the package directory or pass the relative test path:
     ```powershell
     # In packages/monstrous_core
     dart test
     # Or specific test
     dart test test/session/region_mechanics_and_apex_test.dart
     ```
4. **Use Generous `WaitMsBeforeAsync`:**
   - Set `WaitMsBeforeAsync: 10000` (10 seconds) on test and analysis commands so they complete synchronously rather than being dropped into background tasks.
5. **No Busy-Polling Background Tasks:**
   - If a command is backgrounded, do NOT loop calling `manage_task(Action='status')`. Wait for the system's reactive notification upon completion.

---

## 3. Core Gameplay Rules & Design Systems

### A. Dead Reckoning Navigation & Region Structure
- Instead of a rigid grid of tiles, progression uses a procedural **Dead Reckoning Heading System** where captains choose between 3 options after each encounter:
  - `NavigationalBearing.port` (Port / Left)
  - `NavigationalBearing.deadAhead` (Dead Ahead / Center)
  - `NavigationalBearing.starboard` (Starboard / Right)
- **Escalating Region Lengths**:
  - Region 1 (*The Siren Shoals*): 10 legs.
  - Region 2 (*The Sargasso Drift*): 12 legs.
  - Region 3 (*The Boiling Reach*): 14 legs.
- **Guaranteed Convergence Waypoints**:
  - **Midpoint Haven Island**: Guaranteed at `leg = totalLegs / 2` (e.g. Leg 5 in R1, Leg 6 in R2, Leg 7 in R3). Approaches with a single convergent heading.
  - **Regional Titan Boss**: Guaranteed at `leg = totalLegs` (e.g. Leg 10 in R1, Leg 12 in R2, Leg 14 in R3). Single convergent heading.
    - Region 1 Titan: **The Kraken**
    - Region 2 Titan: **The World Serpent** (Jörmungandr)
    - Region 3 Titan: **The Ancient Leviathan**

### B. Respite Islands & Shore Duty
- **Grand Midpoint Haven**:
  - Full harbor with civilization. Careening restores **30% max HP**.
  - Host to a **Traveling Shipwright**: allows upgrading the ship's class tier (e.g. Corvette II, Ironclad III).
  - Offers Gunnery Drills (+5% volley accuracy) and rich Foraging (40–60 gold).
- **Secluded Cove / Atoll**:
  - Uninhabited procedural island. Careening restores **20% max HP**.
  - No shipwright present (tier refits disallowed).
  - Moderate Foraging (25–35 gold).
- **Armory & Munitions Refit**:
  - Players may freely swap/refit equipped weapons and cargo outside of combat (at Havens, Coves, Ketch merchants, and at the Helm between encounters).

### C. Combat Resolution & Armor Class
- **Armor Class (AC) is Vestigial**:
  - Legacy $d20 + \text{hitMod} \ge \text{AC}$ was replaced with percentile hit chance. AC does **not** affect hit rates or damage. Do not add or balance around AC.
- **Hit Calculation**:
  $$\text{HitChance} = (\text{weapon.baseAccuracy} + \text{accuracyBonus} - (\text{isObscured} ? \text{obscuredAcMod} : 0)).\text{clamp}(25, 95)$$
- **Massive Target Synergy**:
  - Colossal beasts (**Kraken**, **Ancient Leviathan**, **Crustaceans**, or any beast with active **Carapace Plating**) provide a **+10% accuracy bonus** to player Blast weapons (Torpedoes, Blast Packs).

### D. Carapace Plating & Elemental Interactions
- Any combatant with `carapacePlating > 0` absorbs incoming damage before hull/vitality is harmed:
  - **Blast damage**: Shatters armor, dealing **$1.5\times$ bonus damage** directly against carapace plating.
  - **Fire damage**: Bypasses the shell entirely, cooking the beast beneath without being absorbed by carapace.
  - Slicing, Piercing, Shock: Absorbed point-for-point.

### E. Apex / Elite Monsters
- Apex beasts appear on higher difficulty legs and are marked with `isApex = true`:
  - **Stat Boosts**: $+30\%$ HP and a universal **Encrusted Barnacle Carapace** ($20 + 5 \times \text{level}$).
  - **Species-Specific Tactical Affixes**:
    - *Apex Megalodon (Shark)*: Starts combat with `frenzyStacks = 1` active (+25% damage). Requires Shock or Stun to disrupt.
    - *Apex Phosphor Wyrm (Serpent)*: Gains 30% Evasion via `SerpentSlitherTrait`.
    - *Apex Volcanic Shock-Bell (Jellyfish)*: Dual-wields an extra `stingingTendrils` weapon.
    - *Apex Abyssal Krakenling (Squid)*: $+5$ extra tentacles and denser ink cloud (-25% accuracy penalty).
    - *Apex Obsidian Carapace Drake (Crustacean)*: $+25$ additional carapace plating on top of universal barnacles.

### F. Regional Combat Hazards
- **Region 2 (Sargasso Drift)**: Tangled Kelp reduces ship evasion by 10%; Phosphor Haze causes monsters to spawn obscured in glowing fog.
- **Region 3 (Boiling Reach)**: Thermal Caldera Scald erupts every 3 rounds, dealing 10 unblockable thermal scald damage to the ship.

### G. Visual & Art Asset Pipeline
- **Curated Stylized Raster Art for Entities & Icons**:
  - Entity graphics (ships, sea monsters, weapons, consumables, items, and major UI icons) use curated raster art (`.png`) residing in `apps/monstrous_sea/assets/art/`.
  - The user generates and tunes these assets using a dedicated external model to enforce a cohesive, historical woodcut/ink-and-parchment cartographic look (deliberately steering clear of generic, glossy "AI art").
  - When new monsters, ship classes, weapons, or items require illustrations, coordinate with the user so they can prompt/generate the asset through their tuned workflow rather than attempting to construct complex multi-part vector shapes.
- **SVGs & `CustomPainter` for Structural UI & Dynamic Linework**:
  - Use vector SVGs and Flutter `CustomPainter` for structural, responsive, or animated UI elements:
    - Screen cartouche framing and ornamental borders (`CartoucheBorderPainter`).
    - Dynamic animated ocean waves bobbing behind entity sprites (`AnimatedWavePainter`).
    - Nautical compass rose (`CompassRosePainter`).
    - Parchment overlays, dividers, and gauge linework.

### H. Rogue-lite Succession, Nemesis & Dual-File Persistence (Stage 1)
- **Dual-File Anti-Scumming Architecture (`StorageService`)**:
  - `player_profile.json`: Persistent cross-run ledger storing `MetaInventory`, `LineageTracker`, `activeNemesis`, and civic unlocks. Saved upon reaching Port, Helm, Rest Areas, or upon Captain Demise / Meta-Currency awards.
  - `voyage_save.json`: Transient mid-voyage save snapshot saved ONLY at checkpoints (Helm, Rest Area, Respite Island). Strictly auto-deleted upon captain death or returning to port to prevent save-scumming.
- **Lineage Succession & Bloodline Traits**:
  - Upon captain demise, 3 curated `HeirCandidate`s are generated, each bearing a unique pair of 1 Maritime Boon and 1 Curious Quirk.
  - Heirs can be custom-named or accept default generated monikers.
  - Bloodline traits alter gameplay (e.g. *Reckless Helmsman* disables Dead Ahead, *Blood Oath* locks wheel onto Nemesis, *Drillmaster* preserves turn on item usage, *Superstitious* rejects Abyssal Pacts, *Salt-Addict* amplifies damage but suppresses healing).
- **Nemesis System**:
  - The monster delivering the fatal blow to a predecessor absorbs life force and ascends into an empowered `NemesisRecord` with a custom infamy moniker, elevated HP, and thick carapace.
  - The Nemesis re-appears procedurally in its slayer's region on subsequent voyages (guaranteed appearance on later legs).
  - Slaying the Nemesis avenges the ancestor, awards a lavish multi-currency vengeance bounty, and clears the active Nemesis ledger.
- **Meta-Economy Currencies**:
  - Materials: Sea Glass, Depth-Wrought Iron.
  - Organics: Monster Bone, Abyssal Barnacles.
  - Titan Trophies: Kraken's Beak, World Serpent's Scale, Leviathan Core.

---

## 4. Verification Checklist Before Finishing Tasks

Before concluding any implementation or refactoring task, execute the full test and analysis suite:

1. **Static Analysis (All Packages)**:
   ```powershell
   dart analyze packages/monstrous_core packages/monstrous_sim apps/monstrous_sea
   ```
   *(Must return 0 errors, 0 warnings).*

2. **Core Domain Tests**:
   ```powershell
   cd packages/monstrous_core
   dart test
   ```
   *(All 182 unit, rule, content, and session tests must pass).*

3. **Simulation Sanity Check**:
   ```powershell
   cd packages/monstrous_sim
   dart test
   ```

4. **Flutter UI & Widget Tests**:
   ```powershell
   cd apps/monstrous_sea
   flutter test
   ```
   *(All 76 widget, flow, screen, and storage tests must pass).*

---

## 5. Coding Standards & Principles

- **Preserve Documentation Integrity**: Always preserve existing docstrings, rationale comments, and test descriptions unless the requirements explicitly mandate altering them.
- **Markdown Linking**: Always use clickable GitHub-style file markdown links with the `file://` scheme (e.g. `[combat.dart](file:///c:/Workspace/PersonalProjects/TheMonstrousSeaV2/packages/monstrous_core/lib/src/rules/combat.dart)`).
- **Concise, Focused Communication**: Explain decisions clearly, summarize testing outcomes, and avoid unnecessary verbosity.
