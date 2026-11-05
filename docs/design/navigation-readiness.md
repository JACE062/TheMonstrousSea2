# Navigation refactor: WP0 readiness

Execution started 4 November 2026 under the user's implementation Goal. The [accepted design](navigation.md#consolidated-plan-review) remains authoritative. This brief records source findings and bounded execution choices; both material decisions are resolved. Initial numbers live in the [economy registry](voyage-economy.md#provisional-implementation-parameters).

## Source findings and material decisions

### Difficulty authority — selected 4 November 2026

In [SeaChart](../../packages/monstrous_core/lib/src/rules/sea_chart.dart), ordinary offers use `clamp((nextLeg + 1) ~/ 2, 1, 4) + 4 * timesCompleted`. Steering moves the old 4-by-5 coordinates; `currentDifficulty` instead uses `row + 1 + 4 * timesCompleted`, with an extra level at coordinate (3,4), even for an ordinary creature. [GameSession](../../packages/monstrous_core/lib/src/session/game_session.dart) creates monsters, resolves poison and awards victory gold/tactical loot using that coordinate difficulty. Thus a Region 2 leg-4 offer at level 6 can spawn a level-9 ordinary creature. This affects strength, rewards and damage-over-time, not just the label.

Titan offers are 5/9/13. Kraken's factory defaults to level 5; the later factories receive chart difficulty. [NemesisRecord](../../packages/monstrous_core/lib/src/model/nemesis.dart) instead instantiates its saved level, while the ordinary bounty still uses chart difficulty, followed by the saved additional Nemesis bounty.

**Selected by the user:** For new regions, one committed encounter level, copied from the offer into current encounter state and history, used by spawning, poison, bounty and tactical loot. Retain the existing offered progression: ordinary levels 1–4 / 5–8 / 9–12, increasing every two numbered slots and capped within the region; Titan 5/9/13. A Nemesis keeps its saved level and additional saved bounty; its offer and ordinary rewards use that saved level. Bearings and drawn geometry have no level effect. Opening combat retains level 1. A wreck's fight uses that wreck slot's committed level.

This deliberately changes ordinary monster strength relative to the accidental coordinate curve; it is **not** a preview-only fix. Tests must compare actual factory level, offered level, poison input and full bounty, including Nemeses and Titans.

### Existing-voyage rollout — user reset selected 4 November 2026

[VoyageSaveData](../../packages/monstrous_core/lib/src/persistence/voyage_save_data.dart) stores chart JSON, pending supplies, spent wreck choice/receipt, merchant supplies/return phase, captain traits, ending/heirs and voyage build. It does not serialize a live battle. [Controller persistence](../../apps/monstrous_sea/lib/src/game_controller.dart) also accepts `respiteIsland`/compatibility `restArea`, although the [menu gate](../../apps/monstrous_sea/lib/src/widgets/pause_menu.dart) does not offer leaving there. Island name/duty flags currently do not round-trip: complete visit state is needed before exposing more save stops.

| Saved context | Required treatment |
| --- | --- |
| Home preparation / home merchant | Preserve build, profile, offered heirs and stock; use new cadence on actual departure. |
| Helm | Preserve offered choices, current leg and history verbatim. Never manufacture an unseeded replacement for valid cached offers. |
| Loot / compatibility rest | Preserve defeated flag, already credited resources and pending items; continuation must resolve the existing Titan exactly once. |
| Wreck before/after salvage | Preserve old pending choice or spent receipt; finish that already-arrived legacy wreck without converting its rewards to a second haul. |
| Stronghold / its merchant | Titan already crossed; retain new-region index, build and depleted stock. Begin new cadence when departing this boundary. |
| Island checkpoint | Preserve current progress; older missing activity state requires a conservative spent-duty default, rather than granting a second free activity. Do not broaden the menu gate. |
| Caldera choice / death / ended | Preserve acknowledgement, exact heirs, ending and alternate-fate snapshot; no navigation migration or reward replay. |
| Battle / shrine / ketch | Remain unsupported save-and-leave phases; complete state is required before any future expansion. |

**User decision:** The user is the only playtester and will delete existing saves themselves; no migration systems are needed for this refactor. The proposed legacy-region branch and settlement adapter are withdrawn. Implement the new flow directly; do not add a parallel legacy schedule or attempt to translate an old active region. Do not delete or modify real saves on the user's behalf. Existing storage/lineage safety mechanisms remain intact.

The table above is the source inventory and persistence-risk map, not an obligation to add old-region adapters after this decision. Verification now targets newly created checkpoints: cached helm including Nemesis; pre-/post-cargo receipts and overflow; Titan loot at all three boundaries; stronghold/merchant reload and departure; home/succession; terminal outcomes and alternate fate. Compare resources, ship/build, leg and reward receipts before and after, using in-memory or injected disposable storage only. New visit fields distinguish exhausted/empty from uninitialized state. Do not broaden incomplete save phases.

## Bounded implementation choices

### First slice and checks

Start with WP1's core regional plan/progress model using the two selected decisions above. Keep hidden planned groups separate from the currently offered group. Reserve services/Titan and Vendetta first, then roll ordinary entries independently; replace a uniformly chosen eligible entry only if the complete plan lacks a shrine. Retain naturally rolled extra shrines. Store original groups, current redrawn offers, shrine-floor accounting, committed difficulty and outcome history. Rendering consumes no gameplay RNG.

Use explicit destination identity for Haven, repair/refit and specialist merchant; do not make all `respiteIsland` or merchant nodes interchangeable. Tests cover 10/12/14 preparation followed by Titan 11/13/15, full transitions, all-hunt/repeated types, shrine correction/natural extras, blocked/hidden/redrawn counting, service side bearings, sole-heading Vendetta, ordinary Nemesis and redraw preservation, and supported reload/migration. App/simulator adapters must understand destination identity before release of this slice.

The first independent prerequisite was the approved fixed hull-refit correction: replace modifier-adjusted current-HP growth with the same fixed addition as maximum HP. Coverage checks every supported/compatibility class, all three refits, damaged/full hull, neutral/Carpenter/Exacting/combined traits, paid gold and checkpoint restoration. Real healing modifiers and all other refit effects remain. This is a bounded WP3 prerequisite, not completion of WP3.

### Navigation presentation

**5 November playtest amendment:** The user replaced the lane/recentering geometry below with cumulative bearings on a growing pannable/zoomable map. Repeated port choices continue diagonally; ahead keeps the current lateral offset. Water marks, a compass rose and nautical markers are implemented. The desktop/compact arrangement remains. The original WP0 paragraph below records the earlier choice, now superseded only in route geometry/camera. See [the accepted amendment](navigation.md#post-implementation-chart-revision--5-november-2026).

Use one framed helm view: regional title/progress and existing pause control above an integrated history chart and the current heading choices. At desktop width, chart left and three vertically stacked course cards right; below 900 logical pixels, chart above independently scrollable cards. On short windows, chart contracts before controls scroll. Retain readable 115% and larger supported text, keyboard traversal and visible restrictions.

The chart lays completed slots along a forward vertical axis. Each bearing adds a short signed horizontal detour to its visited marker and returns toward the central prevailing course before the next forward step. Coordinates are stable functions of recorded slot/bearing, not gameplay RNG; never wrap the old grid or draw a future branch. Show the known next headings beside the current ship only. Animate the ship once along a newly committed history segment; restore/rebuild shows the committed endpoint. Reduced-motion settings use the endpoint immediately.

Arrival, passed wreck, recovered cargo and won combat have separate recorded outcomes; never infer victory from a combat node's arrival. Reuse approved chart markers, ship art, parchment and structural painting. Label early direction as prevailing wind/onward, without naming the Font. Preserve departure input gates and battle playback ownership. Review desktop/compact screenshots, keyboard/focus, scaling and stable reload/rebuild geometry in WP5.

### Patch Kit command boundary for WP3

Allow carried kits at helm, loot/overflow, wreck assessment/receipt, islands, ketch, merchant and stronghold management. Home preparation may use an already carried kit; never invoke the new path from captain creation, battle, shrine dedication or terminal outcomes. Combat retains its existing quick-action rules. Reject zero-benefit use with full-hull feedback, preserving the item. A dedicated pending-item command validates that exact pending kit ID, removes only it, leaves the belt unchanged and follows the normal pending-last-item continuation. A shop stock item is never pending loot; buying still requires normal payment and stowing. Freeze outgoing-screen callbacks through the existing transition gate.

## WP2 state and reward ownership

Wreck sightings persist a private seed, condition and clue visibility in their regional/current offers. Assessment creates a core `WreckEncounter`; separate deterministic seed substreams freeze approach danger, committed danger, creature factory facts and cargo. They prevent UI/reopen/checkpoint rerolls without introducing a mid-battle save phase or preserving a second legacy encounter engine. The current lifecycle and any selected cargo/threat round-trip independently of creature loot.

An approach win opens condition-appropriate full cargo. A committed win retains full creature gold/organics/tactical loot first; resolving that pending loot returns to the cleared wreck, where a single claim credits cargo gold/permanent materials and exposes its supplies. Quiet recovery claims cargo directly. State advances to receipt before crediting resources. Empty passage consumes the selected slot, and death cannot claim unearned cargo. Wreck-specific actions carry the current ID; departed/stale/repeated actions cannot reopen risk or rewards. Retired selectable-reward commands are rejected.

## Execution status

WP0–WP6 implementation and verification are complete. WP1 implements the hidden plan, conditional alternatives, shrine floor, service/captain placement, committed difficulty and supported checkpoint state. Full three-region regressions cover both final service routes; the reported level/poison/bounty mismatch and saved-level Nemesis bounty have explicit tests. The fixed-refit WP3 prerequisite also passes class/trait/transaction/checkpoint coverage. WP5 integrates saved nautical history/current choices; WP6 retains representative comparisons. Final tuning and human replay remain open.

Verification at this boundary: core analysis clean and 796 tests pass; simulator analysis clean and 33 tests pass; app analysis clean and 389 tests pass. Font-loaded widget checks at 360/1280 logical pixels and 130% text also pass; captures were inspected, and compact bearing/tag wrapping was corrected. These are flow/regression checks, not WP6 balance results or player replay. Native shared Windows output was not rebuilt.

No real save files or prior audit evidence were changed; existing planning edits are preserved. The simulator audit test formerly overwrote its tracked report; it now writes to a disposable test directory, and the original tracked report is restored. Development logs/captures remain under the packages' ignored `.dart_tool` directories pending the final retained verification receipt.

WP2 verification: core analysis clean, 805 tests pass; app analysis clean, 394 tests pass; simulator analysis clean, 33 tests pass. The 18 new core lifecycle cases cover all conditions, forced normal-only/committed Apex/quiet paths, death, complete creature-plus-cargo ownership, overflow, repeated/stale claims and supported reloads. A real Flame/widget test confirms the final hit completes playback before creature loot, then reaches cargo recovery without the controller taking the ordinary helm exit. Font-loaded condition/receipt checks at compact/desktop sizes and 115%/130% text pass; captures were inspected. These remain regression/visual checks, not final economy comparisons.

WP3 verification: core analysis clean, 869 tests pass. Repair coverage includes healing traits, every split checkpoint, first-purchase ordering, refits after partial/exhausted pools, separate careening, ketch pricing, uncapped Stronghold work and stale/illegal actions. Whole-battle drilling and carried/pending kit cases pass. App analysis clean; 400 passed with two obsolete full-belt help assertions subsequently corrected. Eight recovery-control cases and font-loaded compact/desktop captures at 130% text pass; inspected captures show real work allowances and full-belt use. Simulator analysis/33 tests pass after preventing zero-benefit bot repairs. These are correctness checks, not WP6 balance/player replay.

WP4 verification: core analysis/882 tests and app analysis/405 tests pass. Material transactions cover full belts, insufficient purse/stock, stale shipment, invalid quantities, off-site commands, empty ketch checkpoints, positive reliable stock and independent depletion. Regional income tests cover normal/Apex/Titan mapping at all boundaries; connected Nemesis/wreck/three-region regressions pass. Compact/desktop trade controls pass at 130% text. WP3's two old warning assertions now pass.

WP5/WP6 final verification, 5 November: core analysis/889 tests, app analysis/414 tests and simulator analysis/43 tests pass. Font-loaded compact/desktop chart, condition/recovery and service controls pass, including a small-purse repair purchase added during final review. Explicit outcomes distinguish arrival, victory, pass and cargo recovery; history persists across regions. Current choices scroll independently; geometry/redraw/reload remain deterministic and hidden plans stay hidden. Keyboard, reduced motion, pause/save and real playback/continuation retain coverage.

[The full receipt](../archive/README.md#navigation-refactor-verification-2026-11-05) retains initial/revised 10,800-trajectory bundles, 3,600 identical-combat comparisons, complete gold/material/service/kit/shrine ledgers, raw data, source hashes and visual captures. Initial later-region gold was provisionally lowered to 55–70 / 70–90g. All LIVE bots failed before three-region completion, while the two counterfactual attrition modes assume route access and count fatal shortfalls. Neither is a human win-rate or final balance claim. Aggressive midpoint maxing, conservative purchasing and harsh recovery pressure remain player replay/tuning questions; no accepted structural mechanic was replaced to force bot wins.
