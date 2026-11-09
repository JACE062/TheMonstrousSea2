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

## Later verification receipts

Later implementation receipts: [Stronghold continuity, 20 October 2026](playtests/STRONGHOLD_2026_10_20.md). These record verification for completed work; they do not replace current rules or the live backlog.

Combat receipt: [Serpent evasion, 20 October 2026](playtests/SERPENT_2026_10_20.md), including deterministic hit/dodge odds and a seeded before/after comparison.

Combat receipt: [Kraken release and ink, 20 October 2026](playtests/KRAKEN_INK_2026_10_20.md), including preserved defenses/interruption, readable feedback and the stronger release's seeded difficulty impact.

Combat receipt: [Tentacle scaling and counterplay, 20 October 2026](playtests/TENTACLES_2026_10_20.md), including all-blueprint controls, predictable sweeps and 24,000 isolated encounters per version.

Navigation receipt: [Course flow and salvage, 20 October 2026](playtests/NAVIGATION_2026_10_20.md), including transition stability, quirk restrictions, retained emergency triage and persistent wreck rewards.

Reliability receipt: [Test-save isolation and battle-art recovery, 20 October 2026](playtests/STORAGE_ART_2026_10_20.md). This also corrects earlier blanket claims of full-suite storage isolation: inherited UI fixtures could write production profiles until this fix.

Chronicle receipt: [Voyage history and scrolling, 20 October 2026](playtests/CHRONICLE_2026_10_20.md). This covers the lifecycle and scroll-position follow-ups within PT2-11; the larger command-station redesign remains open.

Ending receipt: [Caldera prose and continuation, 21 October 2026](playtests/ENDINGS_2026_10_21.md), including canonical text, readable outcomes, retained acknowledgement/heir checkpoints and old-save defaults. Cinematic epilogues remain deferred.

Development-tool receipt: [Configurable playtest menu, 21 October 2026](playtests/PLAYTEST_MENU_2026_10_21.md), covering seeded builds, region/Titan/ending shortcuts, isolated unsaved sessions and returning to normal play.

Lineage-menu receipt: [Independent saves and title navigation, 21 October 2026](playtests/LINEAGES_2026_10_21.md), including one-time original-save migration, supported menu checkpoints and error recovery.

Alternate-fate/frame receipt: [Persistent alternate branch and composed page framing, 21 October 2026](playtests/ALTERNATE_FATE_FRAME_2026_10_21.md), including pre-choice snapshots, independent progression, retry safety and full-app prologue containment.

Pause-menu receipt: [Esc, safe departures and playback continuity, 25 October 2026](playtests/PAUSE_2026_10_25.md), including modal/focus behavior, save and exit retries, queued writes, real battle playback and compact layouts.

Nemesis eligibility receipt: [Titan exclusion and heir/save compatibility, 25 October 2026](playtests/TITAN_NEMESIS_2026_10_25.md), covering all three Titans, ordinary/Apex controls, Vendetta eligibility and legacy profile/heir/course restoration.

Trait-rework receipt: [Storm-Seer, Overzealous Gunner and percentage notation, 25 October 2026](playtests/TRAITS_2026_10_25.md), including deterministic rules, persistence, UI checks and a paired 4,000-voyage comparison. The rest of the heir catalog remains under discussion.

Full-roster receipt: [Eight Boons, eight Quirks and action timing, 26 October 2026](playtests/CAPTAIN_ROSTER_2026_10_26.md), covering completed catalog hooks, healing and slot persistence, shrine/supply restrictions, Impatient/Skirmisher controls and an 18,000-start regional comparison. This completes the catalog work discussed in the earlier trait receipt; offer weighting remains proposed.

Combat presentation receipt: [Event-by-event displayed state, 27 October 2026](playtests/COMBAT_PRESENTATION_2026_10_27.md), covering the bounded feedback foundation, causal state/identity facts, isolated playback checks and remaining player evaluation. The broader command-station design remains open.

Menu feedback receipt: [Inspection copy and full-belt warning, 27 October 2026](playtests/MENU_FEEDBACK_2026_10_27.md), with deferred dialog typography, maritime backgrounds and title-menu review retained in the backlog.

Combat follow-up receipt: [Label readability, combat-status cleanup and Titan approach identity, 28 October 2026](playtests/COMBAT_FOLLOWUP_2026_10_28.md).

Command-station receipt: [Selected weapon cards, responsive helm/lookout and modal Chronicle, 28 October 2026](playtests/COMMAND_STATION_2026_10_28.md), with isolated layout/interaction verification and implementation captures. Player review remains pending.

Command-station refinement receipt: [Larger helm, aligned blessing attachments, bottom belt and contextual Inspect, 29 October 2026](playtests/COMMAND_REFINEMENT_2026_10_29.md), following positive player feedback on the modal Chronicle and requested dock/inspection corrections.

Terminology receipt: [Ship Fittings and Standard's Gun-Deck Bracing, 29 October 2026](playtests/FITTING_NAMES_2026_10_29.md), including runtime copy and preserved older save labels/identifiers.

Combat-rule receipt: [Global ship range-evasion removal, 29 October 2026](playtests/RANGE_EVASION_2026_10_29.md), preserving other dodge modifiers, with all-blueprint boundary checks and paired full-campaign observations. Clipper Mk progression and economy tuning remain open.

HUD receipt: [Effective evasion with regional, captain and defense context, 29 October 2026](playtests/EVASION_HUD_2026_10_29.md), sharing combat thresholds and preserving event-by-event display updates.

Combat-rule receipt: [Emergency/recovery Wait & Reload, 29 October 2026](playtests/WAIT_RELOAD_2026_10_29.md), removing Skirmisher's standing pass and the pass's accumulating evasion bonus, with recovery checks and a paired seeded comparison.

Utility/UI receipt: [Clipper Mk progression, numeric descriptions, upgrade purse and Sargasso clarification, 29 October 2026](playtests/RIGGING_PURSE_2026_10_29.md), with deterministic checks, layout captures and a bounded paired comparison.

Regional-combat receipt: [Sargasso haze's approved 10% accuracy floor, 30 October 2026](playtests/SARGASSO_HAZE_2026_10_30.md), preserving stronger ink and separate dodge, with real encounter/lifecycle checks and paired Region 2 observations.

Chronicle receipt: [Actual Titan names at encounter opening, 30 October 2026](playtests/BOSS_CHRONICLE_2026_10_30.md), correcting the separate hardcoded Kraken line and duplicated intent article.

Economy investigation: [Voyage gold, iron and service access, 30 October 2026](playtests/VOYAGE_ECONOMY_2026_10_30.md), including real purchase-policy baselines, isolated unapproved reward/price comparisons, iron opportunity models and a separate navigation-difficulty discrepancy. No production tuning or route changes were made; decisions remain in the current discussion and PT2-28/29.

## Explicit historical access

Default ripgrep searches exclude this directory and the separate historical art archive. Use `rg --no-ignore <pattern> docs/archive` only when history is needed; cite the source revision and compare it with the current rules before applying any idea. Reintroducing a retired mechanic requires an explicit new design decision, not discovery of an old approved-looking paragraph.

## Navigation refactor verification 2026-11-05

[The implementation and economy receipt](playtests/NAVIGATION_REFACTOR_2026_11_05.md) retains WP0–WP6 correctness/visual checks, initial/revised seeded comparisons, explicitly separated live combat and assumed attrition replays, and matched hunt/wreck receipts. Tuning remains provisional; player replay is outstanding. The [source/data manifest](playtests/evidence/navigation-refactor-2026-11-05/manifest.json) indexes new evidence without replacing the October audit.

## Navigation playtest fixes 2026-11-05

[The follow-up receipt](playtests/NAVIGATION_PLAYTEST_FIXES_2026_11_05.md) records shared supply UI, home trade removal, verified legacy-temp import, the explicitly approved one-field ownership repair, concise service presentation, Jellyfish positioning and the cumulative pannable/zoomable chart. New screenshots/checks and code commit IDs are indexed in the [follow-up manifest](playtests/evidence/navigation-playtest-fixes-2026-11-05/manifest.json). The initial navigation/economy audit above remains unchanged; the home material broker is future proposal FUT-08.

## Chart focus verification 2026-11-05

[The map-focus receipt](playtests/CHART_FOCUS_2026_11_05.md) records the unified helm/chart, crimson Nemesis identity, wheel ownership/height bounds, aged-paper presentation, reused harbor/cargo art and shared parchment tooltips. The [manifest](playtests/evidence/chart-focus-2026-11-05/manifest.json) retains player inputs, final captures, source commits and isolated Windows verification. Earlier navigation/economy evidence and player saves are unchanged.

## Chart refinement verification 2026-11-05

[The readability/control receipt](playtests/CHART_REFINEMENT_2026_11_05.md) records minimum icon scale, continuous world-space markings, prompt tooltip timing, on-map tools, colored header/actions and wider non-scrolling lookout cards. The [manifest](playtests/evidence/chart-refinement-2026-11-05/manifest.json) retains the input screenshot, final visual/interaction checks, source commits and a new isolated Windows build. Previous evidence and both the normal/running preview bundles are preserved.

## Chart bounds verification 2026-11-05

[The bounds/marginalia receipt](playtests/CHART_BOUNDS_2026_11_05.md) records 30%-width bearing cards, camera limits for every input path, the home-port name, legend removal and faded curved/creature/coastal ornaments. The [manifest](playtests/evidence/chart-bounds-2026-11-05/manifest.json) retains the player screenshot, final checks/captures, source commit and isolated build verification. Earlier audits, existing build bundles and player saves are unchanged; Hull/Purse/Center Journey icon replacements remain deferred.

## Vessel location and service copy 2026-11-06

[The follow-up receipt](playtests/CHART_LOCATE_2026_11_06.md) records zoom-preserving Find Vessel/End, closest permitted centering and concise pre-Titan service reports, including unchanged saved-plan data. The [manifest](playtests/evidence/chart-locate-2026-11-06/manifest.json) retains focused checks, selected final captures, the player screenshot and isolated native build verification. Earlier evidence, saves, icons and service rules are preserved.

## Shore UI and port chart verification 2026-11-06

[The shore UI receipt](playtests/SHORE_UI_2026_11_06.md) records tabbed chandlery trading, shared live inspection, the enlarged shore chart and confirmed port endpoints. The [manifest](playtests/evidence/shore-ui-2026-11-06/manifest.json) retains the three player inputs, final checks/captures and separate native build verification. The 36-item copy review was pending at this milestone, and regional artwork remains deferred; prior audits, saves and mechanics are unchanged.

## Approved player copy verification 2026-11-06

[The approved-copy receipt](playtests/APPROVED_COPY_2026_11_06.md) records 30 implemented selections and six passages awaiting clarification. The [manifest](playtests/evidence/approved-copy-2026-11-06/manifest.json) retains the decision IDs, pending-text preservation check, final app/font checks, representative captures and separate Windows build verification. Earlier receipts retain their original status snapshots; the current copy review owns the latest decisions.

## Copy clarification verification 2026-11-06

[The clarification receipt](playtests/COPY_CLARIFICATIONS_2026_11_06.md) records the six subsequent answers: no wind caption, comprehensive wreck-salvage framing, hopeful working captain prose, the user's Nemesis wording, plain save identity and concise adaptive Belt Help. The [manifest](playtests/evidence/copy-clarifications-2026-11-06/manifest.json) retains focused checks, selected captures and a separate native build. All 36 copy decisions are implemented; C28 remains working prose. Earlier audits, builds and saves are preserved.

## Lineage dialog typography verification 2026-11-06

[The typography receipt](playtests/LINEAGE_TYPOGRAPHY_2026_11_06.md) records consistent New Lineage title/actions in the selected font mode, wide/compact serif/plain captures and the separately discovered existing large-text layout guard/stale copy checks. The [manifest](playtests/evidence/lineage-typography-2026-11-06/manifest.json) retains the new player image, final checks and isolated Windows verification. The broader menu redesign remains deferred; older evidence and saves are preserved.

## Hull Patch Kit art verification 2026-11-07

[The approval/integration receipt](playtests/PATCH_KIT_ART_2026_11_07.md) records the user's selected rope-bound kit, shared item-art mapping, bundle/alpha and existing flow checks, font-loaded merchant captures and a separate Windows build. The [manifest](playtests/evidence/patch-kit-art-2026-11-07/manifest.json) retains source hashes and built-asset correspondence. Other candidates and earlier artwork remain preserved; player saves and gameplay rules are unchanged.

## Approved artwork pass verification 2026-11-07

[The complete-pass receipt](playtests/ARTWORK_PASS_2026_11_07.md) records the seven remaining selected illustrations, including revised hull and berry-free kelp, accurate ink/pitch mappings, chart controls and committed-region marginalia. The [manifest](playtests/evidence/artwork-pass-2026-11-07/manifest.json) retains hashes, 34-image bundle verification, UI/font checks, regional/menu captures and separate Windows correspondence. Earlier drafts, evidence, bundles and player saves are preserved; provisional gameplay tuning is unchanged.

## Combat status tooltip verification 2026-11-08

[The status-help receipt](playtests/COMBAT_STATUS_TOOLTIPS_2026_11_08.md) records independent inline effect targets, displayed-state values, real hover/long-press checks and font-loaded compact/desktop captures. The [manifest](playtests/evidence/combat-status-tooltips-2026-11-08/manifest.json) retains input/capture hashes, check logs and correspondence with a separate Windows preview. Existing combat rules, saves, artwork and earlier evidence remain intact.

## Shrine button verification 2026-11-08

[The shrine-button receipt](playtests/SHRINE_BUTTON_2026_11_08.md) records the boxed departure action, existing UI checks, compact/desktop captures and a separate Windows build. The action's wording and command are unchanged.

## Encounter button verification 2026-11-08

[The encounter audit receipt](playtests/ENCOUNTER_BUTTONS_2026_11_08.md) records four further boxed actions, the remaining encounter-screen review, existing functional checks and font-loaded captures. [Evidence](playtests/evidence/encounter-buttons-2026-11-08/manifest.json) keeps the separate pre-existing compact Covenant overflow and interrupted capture attempt distinct from passing checks and the isolated Windows build.

## Inspection button sizing verification 2026-11-08

[The sizing receipt](playtests/INSPECT_SIZING_2026_11_08.md) records regular shore inspection buttons, the explicitly compact helm variant, existing UI checks and a separate Windows preview. [Evidence](playtests/evidence/inspect-sizing-2026-11-08/manifest.json) retains the player image, selected captures and build correspondence.

## Action and condition copy verification 2026-11-08

[The D01–D02 receipt](playtests/MECHANIC_COPY_2026_11_08.md) records concise Rigging wording, Grappled condition help, existing UI checks, font-loaded captures and a separate Windows build. [Evidence](playtests/evidence/mechanic-copy-2026-11-08/manifest.json) distinguishes those delivered fixes from the 42 pending D03–D44 decisions in the current review.

## Approved action and condition copy verification 2026-11-08

[The approved D03–D44 receipt](playtests/APPROVED_MECHANIC_COPY_2026_11_08.md) records all remaining selections, Burning/Shaken names, concise effects and linked contextual help, plus the explicitly authorized Blast retaliation. [Evidence](playtests/evidence/approved-mechanic-copy-2026-11-08/manifest.json) retains full/focused checks, compact/desktop font-loaded captures and correspondence with a fresh Windows preview. D01–D02 and earlier evidence retain their original status snapshots; saves, prior bundles and provisional economy tuning are preserved.

## Storm-Seer chart layout verification 2026-11-08

[The layout receipt](playtests/STORM_SEER_CHART_2026_11_08.md) records the reproduced desktop collapse, separate on-map auxiliary notes, independent text measurement and compact fallback/resize checks. [Evidence](playtests/evidence/storm-seer-chart-2026-11-08/manifest.json) preserves the player input, before/after checks, font-loaded layouts and fresh Windows preview correspondence. Existing saves, prior bundles, navigation mechanics and provisional tuning are preserved.
