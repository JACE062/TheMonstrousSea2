# Historical documentation archive

**HISTORICAL / SUPERSEDED — NOT IMPLEMENTATION GUIDANCE.** Read [the current documentation guide](../README.md) for present work. Files below are preserved for posterity and explicitly needed historical reference. Their old imperatives and “approved,” “final,” or “locked” labels do not override current decisions.

## Migration record

The consolidation was performed on 20 October 2026, after commit `c16a1a2` separately recorded that day's playtest findings. Original text remains retrievable at that Git revision. Archive copies retain the prose, with a historical warning prepended and Markdown links rebased to their new locations.

The [machine-readable disposition ledger](migration_manifest.json) records all 17 original documents, source Git blobs/SHA-256 hashes, preserved archive-body hashes, and **268 original Markdown headings** with their destination, status and rationale. It also records the six screenshot hashes, PT2-01–22 IDs, and the initial exact transfer of twelve blessing-catalog rows. `python tools/check_docs.py` validates that coverage and the archive's integrity. The transfer receipt is historical evidence; it does not require future approved balance changes to reproduce old numerical values.

This index describes where material went. It is not a second gameplay manual. Current rules live in [CURRENT_GAME.md](../CURRENT_GAME.md), canon in [LORE.md](../LORE.md), open work in [BACKLOG.md](../BACKLOG.md), architecture in [CLAUDE.md](../../CLAUDE.md).

## Source disposition

| Original source | Archived copy | Current disposition |
| --- | --- | --- |
| `docs/GDD.md` | [Java GDD](java/GDD.md) | Original Java math/parity history. Retired d20/AC, flee, grid and loot/equipment mechanics do not govern the live game. |
| `docs/PLAN.md` | [Initial remake plan](java/PLAN.md) | Milestone 1 plan preserved. Technical boundaries retained in the developer guide; original ship picker, endless grid and SVG-only mandates superseded. |
| `docs/bugs.md` | [Original bug tracker](java/bugs.md) | Java B1–B6 receipts preserved; their old flee/drop distributions are not current requirements. Deterministic RNG and safe turn completion remain engineering principles. |
| `docs/ROGUE_LITE_DESIGN.md` | [Roguelite evolution](design/ROGUE_LITE_DESIGN.md) | Canon extracted to Lore; current progression to Current game; compatible future atmosphere/encounter/ending goals to Backlog. Old weapon swapping, doctrine and auxiliary-slot ideas are historical. |
| `docs/COMBAT_SYSTEM_REDESIGN.md` | [Combat redesign](design/COMBAT_SYSTEM_REDESIGN.md) | Current combat principles retained with later corrections. Early range/status sketches superseded. Post-boss Master Refit scope retained as deferred Phase 4 work. |
| `docs/PHASE_3A_HARDPOINT_AND_BELT_SPEC.md` | [Phase 3A](design/PHASE_3A_HARDPOINT_AND_BELT_SPEC.md) | Three-hardpoint topology, ranges and utilities retained; Ram/Howitzer types, Mk I departures, single-use consumables and current economy supersede earlier details. |
| `docs/PHASE_3B_OCEAN_POWERS_SPEC.md` | [Phase 3B](design/PHASE_3B_OCEAN_POWERS_SPEC.md) | All twelve dedication rows retained in the current blessing catalog, with integration/lifecycle clarifications. Conceptual paths, enum names and implementation checklists remain historical. |
| `docs/AGENT_HANDOFF.md` | [Former handoff](milestones/AGENT_HANDOFF.md) | Reading guide and technical navigation consolidated. Historical counts and conflicting “user-approved” flee/old topology claims retired from current guidance. |
| `docs/agents/phase0_foundation.md` | [Foundation brief](milestones/phase0_foundation.md) | Completed task receipt. Current architecture remains in the developer guide. |
| `docs/agents/phase1_engine.md` | [Engine brief](milestones/phase1_engine.md) | Completed original-engine brief; d20 combat and Java parity are historical, not a new implementation task. |
| `docs/agents/phase2_visuals.md` | [Visuals brief](milestones/phase2_visuals.md) | Asset approval/provenance retained with the existing art records and current presentation policy. Old screen tasks and assumed tool availability are historical. |
| `docs/agents/phase3b_ocean_powers.md` | [Phase 3B receipt](milestones/phase3b_ocean_powers.md) | Integration decisions promoted into current rules; work streams and dated tests/simulation remain receipts. |
| `docs/feedback_and_fixes.md` | [Early feedback plan](playtests/feedback_and_fixes.md) | Old fixes archived. Current readability/art concerns retained in PT2 issues; no active flee, cargo swapping, hit bonuses, SVG-only prompt, or old roadmap. Existing fixes are not silently requeued. |
| `docs/PLAYTEST_2026_10_19.md` | [October 19 remediation](playtests/PLAYTEST_2026_10_19.md) | Completed receipt and verification preserved. Updated rules promoted; later regressions remain open. |
| `docs/PLAYTEST_2026_10_20.md` | [October 20 capture](playtests/PLAYTEST_2026_10_20.md) | All 22 findings and acceptance criteria retained in the live backlog, preserving IDs and screenshots. |
| `docs/UI_ART_BACKLOG.md` | [Original deferred art list](playtests/UI_ART_BACKLOG.md) | Complete inventory and constraints merged into the live backlog's deferred-art section. |
| Root `CLAUDE.md` before consolidation | [Former developer guide](milestones/CLAUDE_2026_10_20.md) | Technical guidance rewritten against current tools; gameplay moved into its owning document. Stale formulas, counts and path conventions do not retain authority. |

## Important reconciliation decisions

- Current hardpoint identities replace legacy auxiliary/prow/mortar topology as player build slots. Saved aliases can remain compatible without adding mounts.
- Phase 3B corrected Ram to Piercing and Howitzers to Slicing. Old diagrams describing them as Blast are superseded; Heavy Mortar retains Blast and its special shell multiplier.
- The old `10–12` cannon table was corrected to the current `8–12` content roll. Per-weapon normalized range efficiencies replace generic “all mortars at Long gain +25%” guidance.
- All consumables are single-use. Weapon/item rarity and legacy charge fields do not add tiers, charges, price scaling or potency to the current belt.
- True new voyages begin with Mk I. The old expansion bonus granting starting Broadside Mk II is retired; ancestral signature tiers remain a distinct permanent progression system.
- Current Brinemother/Static/Electro-Jolt mechanics replace early generic acid decay and automatic Arc-Stun sketches. Conceptual `divination`, immutable field snippets and `models/ship.dart` paths are not requirements to rename working APIs.
- Region transitions must preserve voyage builds. Current code violations are recorded as PT2-19/21, rather than legitimized by copying its shared-port reset into canon.
- Broader town restoration, ending cinematics/Ancestral Chronicles, extra encounter concepts, and Master Refits are retained future work. Existing profile flags, town-monument upgrades or ending handlers are not proof that all proposed presentation has shipped.

## Explicit historical access

Default ripgrep searches exclude this directory and the separate historical art archive. Use `rg --no-ignore <pattern> docs/archive` only when history is needed; cite the source revision and compare it with the current rules before applying any idea. Reintroducing a retired mechanic requires an explicit new design decision, not discovery of an old approved-looking paragraph.
