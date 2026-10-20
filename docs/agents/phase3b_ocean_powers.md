# Phase 3B implementation handoff

Source of truth: [Phase 3B specification](../PHASE_3B_OCEAN_POWERS_SPEC.md).

The implementation follows the repository's existing mutable Dart domain model and command-driven session. The specification's conceptual `models/ship.dart` and `models/monster.dart` correspond to `lib/src/model/combatant.dart`; its combat UI corresponds to `battle_screen.dart`. No Flutter dependencies enter the core package.

## Work streams

- Shared models and integration: `model/ocean_power.dart`, ship/monster state, voyage serialization, base weapon type corrections, lore, regression review and final verification.
- Combat agent: `rules/combat.dart`, `rules/monster_ai.dart`, combat traits, a plain fallback monster intent, and deterministic combat tests.
- Shrine/session agent: weighted shrine selection, dedication commands, combat lifecycle hooks, Runic Guidance, four simulation strategies, and session/bot tests.
- UI agent: two-step shrine flow, upgrade/lock previews, combat badges, and compact/wide widget tests.

## Implementation decisions

- There are exactly three blessing sockets: Broadside, Signature, Utility. Legacy hardpoint aliases cannot be selected at shrines.
- Shrines sample without replacement using `GameRng`; fewer than two eligible powers yields one or zero manifestations. The rune option remains available when all sockets are sovereign.
- Existing `ShrineChoice.ancientRunes` represents the specification's divination fallback. Guidance refreshes to +10% for the entire next combat, does not stack at consecutive shrines, and survives checkpoint saves. Older tribute/pact commands remain compatible but are no longer offered by the shrine UI or bots.
- Blessings persist through combat, refits, and voyage saves, but clear for a new voyage. Combat-only barriers, charged rigging, and boiling wakes are neither persisted nor carried between battles.
- The specification leaves regional Burn scaling and critical damage unspecified numerically. Magma ignition uses +10% per region after the first (6/10/15 base Fire), and Tempest critical hits deal 1.5 times damage. Both use deterministic rules and injected RNG.
- Thermal Detonation uses the weapon's damage and range scaling before the blessing's direct damage bonus; it then applies Corroded once. It preserves Burn and the weapon's intrinsic damage type.
- Kinetic shockwaves use the existing `DamageType.piercing` with an explicit 1.5× Carapace multiplier. No new damage type is introduced.
- Earthshaker windup cancellation uses a plain normal strike, avoiding unrelated species abilities or poison. Tempest discharges on normal actions apply Electro-Jolt instead of hard stun.
- Boiling Wake responds to monster range movement, including a Harpoon pull, but not movement of the ship alone.
- Old saved Rams and Howitzers migrate to Piercing and Slicing respectively. Heavy Siege Mortar retains Blast and its existing 2× shell damage.

## Verification commands

Run Dart/Flutter tooling outside the Windows sandbox so analysis and test worker IPC can complete, as described in `CLAUDE.md`.

```powershell
dart analyze packages/monstrous_core
dart analyze packages/monstrous_sim
flutter analyze # from apps/monstrous_sea
dart test # from packages/monstrous_core, then packages/monstrous_sim
flutter test # from apps/monstrous_sea
dart run bin/simulate.dart --runs 1000 --seed 42 --strategy all # from packages/monstrous_sim
```

The final simulation report and per-voyage records live in `packages/monstrous_sim/reports/report.md` and `sim_log.csv`. These are regression/balance observations, not balance targets; no unrelated tuning is included in this phase.

## Verified results (2026-10-19)

- Core: 290 tests passed, including 45 deterministic Ocean Power combat tests and 14 new shrine/session tests.
- Simulator: 19 tests passed.
- Flutter: 89 widget/flow tests passed, including shrine and battle layouts at 360px and 1200px widths.
- Static analysis: no issues in core, simulator, or Flutter app.
- Seed 42, 1,000 voyages (250 per strategy): no crashes or stalemates; longest run 244 steps against the 2,500-step guard. Win rates: Reckless 7.2%, Cautious 18.4%, Greedy 1.6%, Random 0.4%.
- Review regressions cover Calcify clearing Ignited counters, simultaneous fatal retaliation prioritizing captain death, Arc preventing immediate Feeding Frenzy reinstatement, single relic procs despite extra blessing damage events, and Brinemother preserving Heavy Mortar's 2× shell damage.

Verification used automated domain, simulation, and Flutter widget tests. A native desktop playthrough was not performed.
