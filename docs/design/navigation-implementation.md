# Navigation refactor: implementation handoff

**Execution complete, 5 November 2026:** WP0–WP6 mechanics/verification are implemented under the user's Goal. Tuning remains provisional and player replay is outstanding; [the retained receipt](../archive/README.md#navigation-refactor-verification-2026-11-05) states the simulation limits. The original planning/source inventory below is retained with the execution checklist updated. The user accepted the [consolidated design](navigation.md#consolidated-plan-review); settled mechanics were not reopened.

This document owns execution order, readiness decisions and verification. It does not replace the design or approve old balance candidates. [Voyage economy](voyage-economy.md) owns the detailed service, stock and progression targets; [Current game](../CURRENT_GAME.md) separates implemented behavior from selected future targets.

## Start here in the new chat

1. Check actual git status before editing. Preserve every existing modification, untracked planning/evidence file and player save. Do not reset, clean, discard or infer that untracked files are disposable.
2. Read [AGENTS.md](../../AGENTS.md), [docs/README.md](../README.md) and [CLAUDE.md](../../CLAUDE.md), then this handoff and only the [consolidated review](navigation.md#consolidated-plan-review) initially. Follow links to the owning selected sections as needed; do not spend the new context rereading all historical discussion.
3. Read the relevant baseline navigation/reward/service/progression sections of Current game, PT2-08/28/29 in [Backlog](../BACKLOG.md), and region/respite fiction in [Lore](../LORE.md#regions-titans-and-the-town). PT2-16/26 contain related salvage and trait receipts, not instructions to preserve superseded behavior.
4. Begin WP0 below. Resolve only actual remaining execution choices, not the accepted game loop. Keep the readiness proposal together rather than reopening a long questionnaire.
5. Gameplay authority comes from the user's current launch instruction. This planning handoff alone does not start implementation or a Goal. With an explicit implementation instruction, proceed autonomously on routine code choices and permitted provisional tuning; resolve material unanswered choices before dependent work.

Snapshot when this handoff was written: branch `master`, HEAD `84d5cb2`. Modified tracked files: CLAUDE.md, Backlog, Current game, Lore, documentation guide and archive index. Untracked material includes navigation/economy plans and the retained 30 October economy audit/evidence. This handoff is also untracked until deliberately committed. Recheck rather than assuming that snapshot remains current. No source changes were present at handoff.

## Scope and authority

Implement the accepted cadence/generation, wreck flow, service/recovery, finite merchant materials, Patch Kit timing and integrated nautical navigation presentation. Flutter/Dart/Flame remains selected. Preserve normal combat rules except the explicitly selected refit/drilling corrections.

Discovery leads are [deferred for possible later consideration](../BACKLOG.md#discovery-leads), not a committed future feature. Quests/story chains, mid-region mini-bosses and a shipwreck-lure species are outside this refactor. No sheltered-water lanes, fully revealed branching map, new flee system, selectable corpse-reward packages, combat blessing payouts, new material types or automatic new art generation are selected. Do not resume unrelated combat-UI polishing.

The 40g-per-hunt / 30g repair reserve example is illustrative. Earlier gold curves, guaranteed wreck/Titan iron, free fitting upgrades and guaranteed kits are not approved defaults. Current prices, stock counts and percentages are baseline evidence, not a substitute for selecting initial parameters.

## WP0 — Readiness brief before dependent changes

Produce a short source-backed brief covering four open decisions, a proposed first bounded slice, and its acceptance checks.

| Decision | Required output | Current status |
| --- | --- | --- |
| Difficulty authority | Trace the offered difficulty, actual monster difficulty and bounty difficulty. Propose one consistent source for the new flow; state any encounter-strength changes separately from a preview-only correction. Visual chart coordinates must not silently decide a new curve. | Audit found a mismatch; correction/scaling is not selected. |
| Existing-voyage rollout | Inventory supported saved phases and propose how an active old region enters the new cadence without skipping/duplicating a Titan, granting extra rewards or stranding a voyage. Specify missing-field defaults and migration tests. | Policy not selected; never reset real saves to avoid it. |
| Initial parameter bundle | Give explicit provisional values and rationale for the registry below, using the accepted progression targets and complete costs/rewards. Mark values as provisional, with source/reference distinctions. | Exact numbers not selected. |
| Navigation presentation | Describe a bounded arrangement for current choices, integrated chart/history, animation and compact layouts using existing approved assets. Keep the hidden plan hidden. | Direction accepted; exact layout/geometry not selected. |

This is a readiness check, not an automatic four-question approval gate. Under an explicit implementation request, document reasonable technical choices and provisional starting values within that authority. Ask only when an unresolved choice materially changes difficulty, player progress, accepted design or the authorized scope; continue independent work that does not depend on the answer.

Technical recommendations for consideration, not approvals: prefer a consistent progression-based encounter authority over accidental legacy visual-coordinate effects; investigate preserving an already-active region's cadence through a safe boundary rather than rewriting progress blindly. Choose the actual rollout after source inventory. Neither recommendation is permission to change scaling or maintain a large duplicate legacy engine without review.

Routine API names, file splits and internal data structures can be decided by the implementer. Record consequential assumptions; do not turn every mechanical choice into a permission request. Treat new mechanics, unresolved difficulty changes and save-rollout policy as material decisions.

### Starting-parameter registry

Select explicit starting values before the slice that uses them. Do not hide placeholder numbers inside UI or call them final balance.

| Parameters to specify | Accepted constraints |
| --- | --- |
| Ordinary encounter weights and wreck-condition mix | Hunting central; repeats/all-hunt sets valid; discovered respite rare; one shrine offered per region through the selected correction method. |
| Approach ambush / committed fight / committed Apex rates | Approach ambush occasional, any wreck, normal-only; deliberate richer searches have high fight chance and can roll Apex; quiet windfalls remain possible. |
| Cargo profiles and gold | One haul; deeper success guarantees cargo; slim rare-material chance in small salvage, much higher in richer salvage; better deeper consumable odds; possible secondary gold; no immediate healing. |
| Merchant stock distributions and prices | Separate finite allocations; type-specific guarantees; same material stock levels across regions; iron mainly distinguished by higher price; no global quota. |
| Gold progression, repair costs and upgrade prices | Roughly two hunts for first fitting + repairs, three for first hull + repairs; early specialization; full upgrades late Region 3 while paying repairs. Whole-voyage purchases compete. |
| Repair capacities and shore-duty values | Separate careen/paid pools; pre-boss paid capacity predictable, 30–50% only an evaluation range; Haven/smuggler values not automatically copied; drilling next whole battle, potency open. |

Use a named shared core configuration or equally reviewable source of parameters rather than duplicated engine/UI/bot constants. That is an implementation recommendation, not a required new framework. A small complete starting bundle is preferable to premature optimization. Give simulation/replay a way to revise it without changing the accepted structure.

## Verified source map

These paths were checked while preparing the handoff; inspect current contents before coding.

| Area | Primary entry points |
| --- | --- |
| Core flow and state | [game_session.dart](../../packages/monstrous_core/lib/src/session/game_session.dart), [commands.dart](../../packages/monstrous_core/lib/src/session/commands.dart), [events.dart](../../packages/monstrous_core/lib/src/session/events.dart), [session_phase.dart](../../packages/monstrous_core/lib/src/session/session_phase.dart) |
| Offers, progress and history | [sea_chart.dart](../../packages/monstrous_core/lib/src/rules/sea_chart.dart) — contains CourseOption and VoyageLegRecord as well as the chart rules |
| Saved voyage | [voyage_save_data.dart](../../packages/monstrous_core/lib/src/persistence/voyage_save_data.dart), app [game_controller.dart](../../apps/monstrous_sea/lib/src/game_controller.dart), [storage_service.dart](../../apps/monstrous_sea/lib/src/services/storage_service.dart) |
| Upgrades, stock, rewards | [ships.dart](../../packages/monstrous_core/lib/src/content/ships.dart), [economy.dart](../../packages/monstrous_core/lib/src/rules/economy.dart), [loot.dart](../../packages/monstrous_core/lib/src/rules/loot.dart), [consumables.dart](../../packages/monstrous_core/lib/src/content/consumables.dart) |
| Navigation presentation | [helm_screen.dart](../../apps/monstrous_sea/lib/src/screens/helm_screen.dart), [sea_chart_screen.dart](../../apps/monstrous_sea/lib/src/screens/sea_chart_screen.dart) |
| Encounter/service presentation | [shipwreck_screen.dart](../../apps/monstrous_sea/lib/src/screens/shipwreck_screen.dart), [loot_screen.dart](../../apps/monstrous_sea/lib/src/screens/loot_screen.dart), [respite_island_screen.dart](../../apps/monstrous_sea/lib/src/screens/respite_island_screen.dart), [merchant_screen.dart](../../apps/monstrous_sea/lib/src/screens/merchant_screen.dart), [smuggler_screen.dart](../../apps/monstrous_sea/lib/src/screens/smuggler_screen.dart), [voyage_shipwright_view.dart](../../apps/monstrous_sea/lib/src/widgets/voyage_shipwright_view.dart) |
| Simulation | [simulation_runner.dart](../../packages/monstrous_sim/lib/src/runner/simulation_runner.dart), [bot_strategy.dart](../../packages/monstrous_sim/lib/src/strategy/bot_strategy.dart), [CLI](../../packages/monstrous_sim/bin/simulate.dart) |

Keep core mutations, validation, RNG and reward ownership in pure Dart. Flutter/controller/simulator issue core commands; none should implement a second economy or encounter engine.

## WP1 — Regional flow, offers and persisted progress

- Implement 10/12/14 numbered pre-Titan slots, midpoint 5/6/7, final preparation at the last numbered slot, Titan afterward. Opening fight belongs to Region 1's first four. Ordinary stretches are 4/4, 5/5, 6/6.
- Midpoint is Haven plus two ordinary alternatives; exclude Nemesis from the entire set. Final preparation is exactly two specialist destinations, one visit. Preserve post-Titan stronghold transitions and voyage continuity.
- Stage hidden regional offers after known structural restrictions are reserved. Keep valid natural plans/extras; only when none contains an eligible shrine, randomly replace one eligible ordinary entry. Do not reroll the region, pin a correction to the last leg or expose the hidden plan.
- Apply the selected Reckless/Fog shrine counting, service bearings, Vendetta sole-heading reservation and Storm-Seer redraw behavior from the consolidated review. Redraw affects only current eligible entries; original shrine offers still count.
- Persist enough plan/progress/offer state for supported reloads to keep the same opportunities and accounting. Do not assume an unseeded reroll is a migration. Use the WP0 difficulty and rollout decisions.

Acceptance: deterministic new-region plans; all three cadences and boss transitions; valid/invalid shrine plans; natural extras; inaccessible/hidden/redrawn shrine accounting; all-hunt sets; midpoint/final Nemesis exclusion; service reachability; normal/Vendetta Nemesis and redraw cases; supported reload/older-checkpoint behavior. Include a full region transition so an off-by-one cannot hide behind a single heading test.

## WP2 — Wreck lifecycle and exactly-once rewards

Implement a core-owned encounter lifecycle, with representation chosen after inspection. Track condition, recovery commitment, whether the sole threat is cleared, selected outcome/cargo and claim/continuation state. Freeze actual rolls at the appropriate decision boundary; UI rebuilds/reopening cannot change them.

Required paths:
- Approach every condition with occasional normal-only ambush eligibility; usually allow assessment and empty pass-by. Clues are usually informative about condition, never a guarantee of safety or a species reveal.
- Picked-clean: small quick salvage only. Uncertain: quick haul and depart OR forego it and linger. Fresh: empty departure OR richer recovery, with no quick haul.
- Consistently warn before Apex-eligible voluntary recovery. Eligibility precedes chance modifiers. Do not add a free enemy opening attack, special stat penalty or new flee option.
- Winning any approach ambush opens the condition's full haul without a further risk choice. A picked-clean wreck remains modest. No second fight.
- Victory from a committed fight awards full ordinary creature loot plus one cargo haul; quiet recovery has cargo but no creature loot. Death grants no unearned wreck cargo. Passing uses one leg with no reward/extra charge.
- Replace Search Hold/Strongbox/Timbers selection with mixed cargo profiles. Preserve one receipt, permanent-resource ownership and belt overflow resolution; do not bank quick cargo before deeper recovery.

Critical integration: the controller currently sends TakeHelm after certain loot commands reach restArea. A wreck battle must not accidentally take that normal exit before its pending cargo is resolved. Preserve combat event playback/input gates; do not route away while the battle is still being displayed.

Acceptance: each condition across quiet/forced/committed fight paths, normal/Apex eligibility and pact modifiers, ambush threat clearance, exact whole receipts, empty departure, death, full belt, repeated/stale callbacks and reload before/after claiming. Prove creature loot never substitutes for cargo or gets awarded again on continuation.

## WP3 — Recovery, upgrades and Patch Kits

- Add per-visit capped paid repair state where selected. Latch normal work from maximum HP at the first purchase, not menu opening. Track spent normal work separately from modifier-adjusted restoration; partial/exhausted pools never grow after a hull upgrade or reload.
- Keep one free Haven activity and separate careen/paid pools. Allow upgrades and repairs in the same visit. Pre-boss repair/refit has no extra free heal. Retain bounded smuggler repairs for now and the distinct combined stronghold services without inventing a new stronghold cap.
- Correct hull upgrades to add equal fixed maximum/current HP for every captain without healing modifiers, preserving existing damage and consuming no repair work.
- Careen uses maximum HP when performed and stays spent. Quote percentages, actual restoration/cost and remaining work clearly. Prevent split-purchase rounding from manufacturing work or healing.
- Make drilling last the next whole combat, including wreck/Nemesis/Titan, survive peaceful encounters, and refresh without stacking. Apply the selected starting potency, not automatically the old +15.
- Permit carried Patch Kit use at appropriate nonbattle voyage management points, explicitly loot/overflow. Permit deliberate direct use of a pending kit without stowing/discarding; consume that exact kit, apply normal healing and keep the belt unchanged. Only kits gain this nonbattle role. Combat quick-action limits and other items' combat roles remain intact.

Specify valid command phases, full-hull feedback and controls in the bounded brief. Disabling zero-benefit use is a recommendation, not a separately accepted rule. A buy-and-use shortcut directly from merchant stock is not selected; do not obtain a free shop kit through the pending-loot path.

Acceptance: neutral/Skilled Carpenter/Exacting/combined traits; upgrade before repairs, partial and exhausted work then upgrade, careen then upgrade, distinct pools, missing-hull limits, rounding, repeated visits/reload; fixed refit HP across classes; drilling duration; carried/pending kit use, full belt, stale requests and pending-last-item routing. Preserve deaths, captain boundaries and supported save gates.

## WP4 — Finite material trade and linked economy

- Add glass/iron purchases alongside a separate consumable allocation. Use existing permanent-resource retention rather than treating currencies as belt consumables.
- Generate one bounded shipment per merchant encounter, keeping empty material stock distinct from uninitialized stock. Buying, reopening and supported reloads cannot refresh it. New merchants have separate shipments; no region/voyage purchase quota.
- Preserve reliable positive glass/iron at chosen pre-Titan merchants and both strongholds, chance-based ketch materials and even regional stock levels. Keep exact wares hidden until arrival.
- Preserve Smuggler's Kin's consumable-specific gift, full-belt handling and repair-price behavior; adding materials must not silently turn the gift into free iron.
- Apply the explicitly selected provisional gold/price/stock/cargo parameters. Count whole earned/spent packages and preserve existing unlocks/costs unless a later decision changes them. No direct Titan/monster iron, save grant or automatic unlock.
- Make merchant and repair/refit destinations genuinely separate; don't accidentally expose stronghold combined services at both pre-boss destinations.

Acceptance: gold/resource transactions and failures; finite depletion including zero stock; type guarantees and random quantity bounds; consumable/material separation; permanent retention through death; exact stock after reload; gift and repair regressions. Validate current-voyage progress and permanent blueprint affordability separately.

## WP5 — Integrated nautical navigation

Implement the agreed chart using actual chosen bearings and encounter outcomes, not a new map-driven gameplay system. Determine exact layout/route geometry in WP0 or a focused presentation brief before this slice.

- Integrate current choices, travelled dotted route, ship movement, visited discoveries and combat victories. Distinguish passed wrecks, arrival and actual victory/recovery.
- Short port/starboard deviations resume the prevailing wind's broader course. No loops, backtracking, safer lateral lanes, terrain gates, extra legs or rewards revealed by line length.
- Derive stable visuals from committed history/visual state; widget rendering must not consume gameplay RNG or regenerate offers. Keep future encounters hidden and early Font fiction spoiler-safe.
- Explain heading restrictions according to their real captain/service cause. Preserve current information boundaries, service identity and unidentified wreck creatures.
- Reuse approved assets/style. Test responsive layouts, text scaling, focus/keyboard access, pause/save controls and playback boundaries. New mockup/art generation is not implicit.

Acceptance: every bearing changes history meaningfully; stable reload/redraw visuals; all cadences/service sets; passed/fought/recovered wreck markers; no future leakage; compact/default desktop readability. History is presentation evidence, not proof of a reward claim.

## WP6 — Full-voyage verification and balance iteration

Correctness checks accompany each slice; don't postpone state/reward/save tests until balance work. Then adapt simulator strategies to actually choose routes, spend on upgrades/repairs/materials and use supplies under the same core commands.

The default simulator stops after the Kraken. Inspect the current runner/CLI before selecting full-campaign settings; CLAUDE documents SimulationRunner(endless: true), and its won flag still means crossing the first Kraken boundary. Do not report that as a three-region completion.

Compare fixed-seed conservative, mixed and danger-seeking policies, including fresh Standard and modestly progressed profiles, healing modifiers, no-cove/poor-kit routes, costly ambushes and capped late builds. Record:
- First-Haven affordability and purchases; first full-max point; gold earned/spent/reserved by source.
- Actual hull before the same Titans, repairs/work consumed, free duty choices, refit HP growth and triage.
- Kits acquired/used/left, overflow waste avoided by nonbattle use, and other supplies spent.
- Complete wreck versus hunt receipts and opportunities forgone, not just rewards per won battle.
- Glass/iron plus Bone/Barnacles, competing permanent purchases and actual unlock affordability over short and full runs.
- Shrine offers, distinct decision opportunities, visits/useful dedications and full blessing saturation.
- Region progress, deaths, exceptions and full completion separately from the runner's first-boss win flag.

A matched won wreck fight pays more than an identical hunt because cargo is additional. Do not declare the design balanced from rarity, voluntary commitment or one upgraded bot. If wreck-heavy routing dominates across relevant states, review weights/cargo/income/damage and present any structural changes rather than silently nerfing corpse loot or making sanctuaries unsafe.

Use simulations to select/revise provisional numbers, then player replay to assess clarity, tension and fairness. No invented target human win rate.

## Verification and completion record

Follow CLAUDE for exact working directories and supported tools. Begin with targeted behavior tests; run relevant package analysis/tests when connected changes justify them. Core uses dart analyze / dart test, simulator the same in its package, app flutter analyze / flutter test in its package. Native Windows flow checks are valuable for this refactor but must be isolated. Recheck CLI options rather than copying an unverified full-voyage flag.

Never use production storage in tests. Inject disposable roots, disable implicit legacy import and use autoSave: false when persistence is not under test. Do not reset player lineages or rebuild the shared Windows app while it is running. Existing supported battle/shrine/smuggler save restrictions are not broadened merely for convenience.

Update implemented facts in Current game, issue progress in Backlog, selected numerical decisions in the economy owner and the checklist below. Run python tools/check_docs.py and git diff --check after documentation changes. Preserve stable PT2/FUT IDs and historical evidence. Do not claim this handoff's tests have already run.

| Work package | State at handoff | Evidence required to mark complete |
| --- | --- | --- |
| WP0 | Complete, 4 November 2026 | [Readiness brief](navigation-readiness.md): offered progression selected; user will delete old saves, so no new migration systems; [initial parameters](voyage-economy.md#provisional-implementation-parameters) remain provisional |
| WP1 | Implemented, 4 November 2026 | Hidden groups and conditional offers, optional midpoint, final specialists/separate Titan, shrine/quirk/redraw and difficulty/checkpoint regressions. Three-region tests cover both preparation routes; [WP0/status](navigation-readiness.md#execution-status) records checks. Service caps/materials remain WP3/WP4. |
| WP2 | Implemented, 4 November 2026 | Condition/risk lifecycle, deterministic sighting/cargo/threat state, full creature rewards plus exactly-once cargo, death/overflow/reload/stale-action coverage; actual battle playback and controller continuation verified in [execution status](navigation-readiness.md#execution-status). |
| WP3 | Implemented, 4 November 2026 | Fixed refits; first-purchase repair ledgers, separate duties, whole-battle drilling, carried/pending kits and compact controls. [Execution status](navigation-readiness.md#execution-status) records checks. |
| WP4 | Implemented, 4 November 2026 | Separate finite shipments, atomic permanent purchases, depletion/empty/reload/phase/Kin/full-belt checks and bounded regional bounties. Core 882 / app 405 tests and analysis pass. |
| WP5 | Implemented, 5 November 2026 | Integrated nautical history/current choices, explicit outcome markers, cross-region persistence, stable geometry, responsive scrolling, keyboard/reduced-motion checks and inspected font-loaded captures. |
| WP6 | Verification implemented, 5 November 2026; final balance/player replay open | Two 10,800-trajectory income comparisons, 3,600 matched combats, raw ledgers/source receipt, bounded provisional income revision. LIVE deaths and assumed full-route replays remain distinct. Core 889 / app 414 / sim 43 tests; clean analysis. |

This is a recommended execution sequence, not a requirement to cram connected work into one patch. Complete coherent bounded slices, review their actual diffs and report tests/remaining risks. Follow AGENTS for any useful authorized delegation; no automatic Goal.

## Copyable new-chat prompt

Implement the accepted navigation/encounter refactor for TheMonstrousSeaV2 in C:\Workspace\PersonalProjects\TheMonstrousSeaV2 using docs/design/navigation-implementation.md.

The consolidated design has been reviewed and accepted. Begin with WP0: check git status, preserve all existing changes/evidence/player saves, read the focused references, and inspect the current code. Document the first bounded slice, provisional starting values and difficulty/save/layout choices. Ask only about material unresolved decisions that require my input, continuing independent work while waiting. Then implement in coherent slices with the listed checks and later full-voyage balance comparisons. Do not reopen settled mechanics or revive old balance candidates. Keep owning documents updated, run python tools/check_docs.py after documentation changes, follow AGENTS.md for delegation, and do not automatically activate a Goal.

