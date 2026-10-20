# Playtest backlog

Status: work consolidated on 20 October 2026. PT2-01–22 retain the original playtest observations; PT2-23/24 record the follow-up. Issues remain open unless explicitly marked resolved or implemented below. Source findings are dated observations, not proof of runtime reproduction.

Read [Current game](CURRENT_GAME.md) for approved baseline rules and [Lore](LORE.md) for canon. A reported symptom, approved requested outcome, unresolved design choice and deferred feature remain distinct. Preserve the six original [screenshot evidence files](playtests/2026-10-20/), follow-up evidence, and issue IDs when updating status. Historical receipts are indexed in [the archive](archive/README.md).

## Recommended work chunks

Each chunk should produce a reviewable change and focused verification. These are proposed scopes, not authorization to implement every design proposal without discussion.

| Order | Chunk | Items | Exit condition |
| --- | --- | --- | --- |
| Initial follow-up | Restore the guaranteed Nemesis choice; investigate the death ledger | PT2-24, PT2-23 | Nemesis is an optional, reachable second-half course in its killer region; the ledger counts actual deaths rather than candidate heirs. See individual statuses. |
| A — implemented, awaiting player replay | Protect voyage and succession continuity | PT2-19, PT2-21, PT2-14; voyage upgrades from PT2-20 | Strongholds preserve the current run and blessings; home-only blueprint actions stay at home; succession cannot lead into a dead menu. |
| B | Audit combat avoidance, boss damage, and regional scaling | PT2-12, PT2-17, PT2-18, PT2-22 | Seeded examples explain hit/dodge odds, Kraken catastrophe damage, and ordinary squid strength; agreed fixes have deterministic coverage. |
| C | Shorten navigation and make outcomes explicit | PT2-09, PT2-10, PT2-15, PT2-16 | Ordinary victories lead efficiently to course selection; headings do not flash replacements; restrictions and salvage rewards are visible. |
| D | Discuss the opening and shared family identity | PT2-01, PT2-02 | Agree on a spoiler-light prologue and permanent surname rules, including legacy-save migration, before implementation. |
| E | Design the command station and useful sea chart | PT2-03, PT2-08, PT2-11, PT2-13 | Review layouts and terminology at realistic window sizes/text scales before replacing the existing presentation. Apex naming can be a small independent fix. |
| F | Specify and implement post-boss progression / Phase 4 | PT2-20, depends on A | Strongholds offer the agreed hull/mark upgrades and exactly scoped Master Refits, with run persistence and blueprint-specific choices. |
| Later | Curated art and icon pass | PT2-04–07 | Use the [deferred asset backlog](#deferred-ui-art-and-icons); audit existing assets first. No image generation in this batch. |

The Nemesis/death-ledger follow-up and continuity batch A are implemented. Next is B, starting with confirmed stacking Serpent evasion, then C. Player replay should verify the stronghold boundary alongside that combat work. F is new feature work, rather than a claim that Master Refits were already completed in Phase 3B.

## Opening and lineage

### PT2-01 — Abrupt first-voyage exposition

- **Reported:** A short Bloodbound Ship / departure message immediately leads into captain naming, without enough context.
- **Requested direction:** Add a short, atmospheric introduction explaining the inherited obligation, returning ship, and reason this captain must sail. Preserve discovery of the deeper story; do not reveal the ending or the full pact/Sea-Madness plot.
- **Design status:** Prose and pacing need review. Keep the agreed direct-to-first-combat onboarding rather than introducing home-port menus again.
- **Starting points:** [intro_screen.dart](../apps/monstrous_sea/lib/src/screens/intro_screen.dart), [captain_screen.dart](../apps/monstrous_sea/lib/src/screens/captain_screen.dart), [existing curse lore](LORE.md#the-ancestors-bargain).
- **Acceptance:** A new player understands who they are, why they sail, and why an heir will follow. Returning captains do not replay the full introduction.

### PT2-02 — One permanent family name, customizable given names

- **Reported / proposal:** Heirs appear to belong to different families. Discuss choosing a permanent last name once, clearly warning that it belongs to the entire bloodline, with a separately editable first name for the founder and each heir.
- **Source finding:** [generateHeirCandidates](../packages/monstrous_core/lib/src/model/bloodline_trait.dart) currently extracts the last whitespace-delimited token of the previous captain's display name as a surname, then appends an epithet to generated names. On later generations that token can be an epithet, explaining surname drift. A one-word founder falls back to `Vane`.
- **Proposed model, pending agreement:** Store the family name explicitly on the profile; keep given names and optional epithets separate from the display name. Do not derive ancestry by splitting rendered names. Show the permanent-family-name warning before confirming a fresh bloodline.
- **Decisions to resolve:** Legacy-profile surname selection without losing history, whether epithets remain, compound family names, and presentation throughout the family record, death screen, and Nemesis names. Existing saves must not be silently assigned an arbitrary permanent name.
- **Acceptance:** Several generations retain the same surname after custom naming and save/reload; only given names are editable during normal succession. Historical captain records remain intact.

## Inspection, art, and chart design

### PT2-03 — Signature armament has two unexplained tier labels

- **Evidence:** [Screenshot 1](playtests/2026-10-20/01-hardpoint-tiers.png) shows `Signature Armament · Mk I` and `Ancestral Armament: Tier 1` on the same card.
- **Source finding:** The latter reads `profile.armamentTierFor(...)` in [armory_view.dart](../apps/monstrous_sea/lib/src/widgets/armory_view.dart): it is permanent blueprint progression, distinct from the voyage's temporary temper mark. It is not a second copy of the same value.
- **Requested outcome:** Make that distinction understandable and reduce clutter. Review hiding the baseline permanent tier or adding concise explanatory text; do not remove permanent progression by accident. Terminology must also distinguish shrine blessing tiers and Master Refits.
- **Acceptance:** Inspection and blueprint screens explain what persists across death and what resets each voyage, without requiring the player to infer the difference between “Tier” and “Mk”.

### PT2-04 — Home-port navigation feels empty without icons

- **Reported:** Merchant, Blueprints, and Sea Chart buttons lost their imagery during emoji removal, despite an existing themed asset set.
- **Disposition:** Deferred UI/art work. Audit existing curated nautical assets for reuse; restore appropriate imagery in the later pass. Removing colorful emoji did not mean abandoning thematic illustrations. See [asset backlog](#art-navigation-and-existing-assets).

### PT2-05 — Consumable images are incorrectly shared

- **Reported / confirmed mapping:** Hull Patch Kits use Unstable Tincture art; Pitch Flasks and Bottled Kraken Ink use Blast Pack art. [SvgAssetView.pathForItem](../apps/monstrous_sea/lib/src/widgets/svg_asset_view.dart) explicitly contains these fallback mappings.
- **Disposition:** Deferred dedicated art for every consumable identity, keeping the single-use rule. Inventory and required replacements are in the [asset backlog](#art-consumables).

### PT2-06 — Meta-materials lack thematic images

- **Evidence:** [Screenshot 2](playtests/2026-10-20/02-blueprint-materials.png) shows generic symbols for the blueprint currencies.
- **Disposition:** Deferred distinct, readable icons for common/rare materials and organics, then Titan trophies and endgame currency. Do not invent new currencies or substitute misleading item pictures. See [asset backlog](#art-meta-materials-and-trophies).

### PT2-07 — Current hardpoints need identity-specific art

- **Reported:** Hardpoint cards lack imagery. Earlier weapon art exists, but many images no longer represent the intrinsic hardpoint identities.
- **Disposition:** Deferred audit and redesign covering the current broadside, signature, and utility identities for all five blueprints. Keep reusable approved images where they fit; do not automatically reinstate retired standalone weapons. See [asset backlog](#art-hardpoints).

### PT2-08 — Sea chart needs a clearer player purpose

- **Evidence:** [Screenshot 3](playtests/2026-10-20/03-sea-chart.png). The chart mainly shows fog, defeated encounters, guaranteed Haven/Titan positions, and a Voyage Log whose decision value is unclear. Repeated “Soundings I / Inshore Waters” and “Soundings II / Abyssal Passage” headings feel wrong across different regions.
- **Design status:** Revisit information hierarchy before coding a replacement. Candidate priorities are current position, region identity, distance to Haven/Titan, known scouting information, and useful recent landmarks. Decide whether the log should be condensed, optional, or replaced; its current usefulness is questioned, not settled.
- **Constraints:** Preserve Dead Reckoning uncertainty; do not expose unscouted encounters or turn the chart into a different navigation system by accident. Respect 10/12/14 regional legs and their actual guaranteed waypoints. Use region-appropriate labels rather than repeating coastal geography everywhere.
- **Starting points:** [sea_chart_screen.dart](../apps/monstrous_sea/lib/src/screens/sea_chart_screen.dart), [SeaChart](../packages/monstrous_core/lib/src/rules/sea_chart.dart).
- **Acceptance:** A player can tell where they are, what useful information they know, and how far the next milestone is without reading a redundant narrative list. Screenshot 3 is layout evidence, not a new claim that the previous vessel-position bug has recurred.

## Navigation and encounter feedback

### PT2-09 — Redundant post-fight inspection screen

- **Evidence:** [Screenshot 4](playtests/2026-10-20/04-post-fight-scroll.png) requires scrolling through hardpoints, belt items, and the unavailable carpenter's workbench to reach navigation. [Screenshot 5](playtests/2026-10-20/05-setting-course.png) already offers the chart, collapsible inspection, hull status, and headings.
- **Proposed direction:** After ordinary victory/loot collection, proceed directly to Setting Course and keep inspection collapsed by default. Remove or bypass the redundant Rest screen in that flow. Preserve any meaningful rewards or decisions rather than silently skipping them.
- **Exceptions to design explicitly:** Titan victory must reach the stronghold or final resolution; island duties, shrine choices, and shipwreck salvage still require their own decisions. Empty loot and a full belt must also lead somewhere valid.
- **Starting points:** [rest_screen.dart](../apps/monstrous_sea/lib/src/screens/rest_screen.dart), [loot_screen.dart](../apps/monstrous_sea/lib/src/screens/loot_screen.dart), [helm_screen.dart](../apps/monstrous_sea/lib/src/screens/helm_screen.dart), session transitions and checkpoint saves.
- **Acceptance:** Navigation is immediately available after normal reward resolution without scrolling past inspection, including at 115% and 130% text size.

### PT2-10 — Headings briefly flash different encounter options

- **Reported:** Clicking a heading briefly replaces the three lookout options before the next screen appears. No screenshot was captured.
- **Investigation lead:** [SeaChart.steerCourse](../packages/monstrous_core/lib/src/rules/sea_chart.dart) generates the next options while the UI observes mutable controller state. [HelmScreen](../apps/monstrous_sea/lib/src/screens/helm_screen.dart) renders those live options. Confirm notification/transition ordering before calling this the cause.
- **Acceptance:** Once committed, the chosen course remains stable until departure. No replacement options flash, duplicate clicks cannot steer twice, and reload does not roll a new encounter.

### PT2-15 — Reckless Helmsman restriction is not communicated

- **Reported:** Dead Ahead does not look clearly unavailable for an heir with that quirk.
- **Requested outcome:** Disable and visibly distinguish the restricted heading; hover/focus explains the active quirk, and touch users have an equivalent explanation. An engine rejection alone is insufficient.
- **Starting points:** [HelmScreen / _CourseOptionCard](../apps/monstrous_sea/lib/src/screens/helm_screen.dart), session's existing steering validation.
- **Acceptance:** Show the restriction before clicking. Preserve the existing single-heading Haven/Titan convergence exception so this quirk cannot strand the voyage; also respect Blood Oath restrictions.

### PT2-16 — Shipwreck salvage promises retired loot and hides the result

- **Reported:** “Scour Hold for Munitions & Weaponry” promises a military-grade weapon or consumable, despite weapons no longer dropping. The completion screen does not show what was received.
- **Source finding:** [_handleSalvageShipwreck](../packages/monstrous_core/lib/src/session/game_session.dart) currently awards a consumable, with a possible Depth-Wrought Iron reward in later regions; other salvage choices award gold/healing and Sea Glass. The [screen](../apps/monstrous_sea/lib/src/screens/shipwreck_screen.dart) ends with generic “SALVAGE COMPLETE” text even though reward events exist.
- **Requested direction:** Describe the desired exploration salvage as common materials, sometimes rare materials, and perhaps a consumable. Exact rates and whether a consumable is guaranteed remain to be agreed; do not claim those probabilities are already implemented. Keep strongbox/timber alternatives distinct.
- **Acceptance:** Preview matches the actual reward table. Display exact materials, quantities, item, gold, or healing received; explain a no-item result. A full belt offers visible overflow/claim/jettison handling, rather than an invisible item left in `pendingLoot`. Rewards cannot be claimed twice and their persistence is verified.

## Combat mechanics and the command station

### PT2-11 — Combat UI does not function as a readable command station

- **Evidence:** [Screenshot 6](playtests/2026-10-20/06-battle-command-station.png). The Chronicle shows roughly two messages despite a turn containing movement, attacks, and status messages. Floating damage/status effects are small and disappear quickly. Intent is squeezed between log and weapons; threat preview and helm controls are crowded at the right edge.
- **Design goal:** Make the battle screen the player's station of command: readable intent and consequences, deliberate helm selection, clear weapon/utility actions, and accessible recent history. Treat log, feedback effects, and controls as one layout problem rather than enlarging one element until the arena no longer fits.
- **Options for review:** Group log entries by round/action, expandable or resizable history, a useful last-turn summary, larger/longer-lived feedback, a prominent intent/threat panel, and a coherent helm/action group. These are candidates, not an approved final layout.
- **Starting points:** [battle_screen.dart](../apps/monstrous_sea/lib/src/screens/battle_screen.dart), [combat_log_view.dart](../apps/monstrous_sea/lib/src/widgets/combat_log_view.dart), [Flame battle effects](../apps/monstrous_sea/lib/src/battle/monstrous_sea_battle_game.dart).
- **Acceptance:** At normal desktop sizes and 115–130% text, the player can understand the impending attack, select a helm order, and review a whole previous turn. Preserve intentional manual log scrolling; do not auto-scroll readers away from history. Compact layouts remain usable. Damage and status feedback must be legible without depending entirely on transient floating text.

### PT2-12 — Apex Serpent evasion feels nearly unbeatable

- **Reported:** Two deaths to an Apex Serpent that dodged almost everything while displaying 80% evasion; the player was unsure whether that meant 80% chance to hit.
- **Follow-up observation:** Reviewing a fight showed evasion starting at 30%, later reaching 50%, then 80% before the ship sank. The buildup itself is the problem, not only an ambiguous initial label. The intent implementation adds 20 percentage points on recoil, capped at 80%, explaining how an Apex's starting 30% can accumulate toward that ceiling.
- **Source finding:** [SerpentSlitherTrait](../packages/monstrous_core/lib/src/traits/trait.dart) uses evasion as a separate dodge roll after a successful accuracy roll. The intent path can raise evasion to 80%; a separate legacy special-action path caps it at 60%. At 85% final accuracy and 80% dodge, an uncountered shot connects only about 17% of the time. This is an explanation of the formula, not a reproduction of the exact runs.
- **Investigation:** Audit buildup, duration/decay/reset, duplicate avoidance checks, and the discrepancy between paths. Verify accessible counterplay for Standard and other blueprints, including Pin and Spotter Flare interactions. Display weapon accuracy and target dodge as different concepts.
- **Acceptance:** Seeded tests cover the actual combined connection rate and evasion transitions. Agree on a fair ceiling/counterplay before tuning; do not disguise a mechanical problem by relabeling 80% as hit chance.

### PT2-13 — Apex names are overlong

- **Reported:** `Apex Phosphor Wyrm Darting Death` is cumbersome; other Apex monsters follow the same pattern.
- **Source finding:** [applyApexEnhancements](../packages/monstrous_core/lib/src/content/monsters.dart) prepends the full species Apex title to the existing generated name.
- **Requested outcome:** Use one readable monster identity with Apex status clearly conveyed. Review a shorter title or separate status badge instead of stacking multiple names. Keep Nemesis identity distinct from generic Apex naming.
- **Acceptance:** All Apex species, combat logs, lookout calls, narrow HUDs, and Nemesis variants remain readable without losing useful species information.

### PT2-17 — Ink still claims “+25 AC”; avoidance needs a visible HUD explanation

- **Reported / confirmed copy:** [GameController's InkCloudDeployed log mapping](../apps/monstrous_sea/lib/src/game_controller.dart) prints `(+… AC)`. The player wants evasion/avoidance visible near monster health, including Kraken and normal squid.
- **Mechanical distinction:** [calculateHitChance](../packages/monstrous_core/lib/src/rules/combat.dart) currently implements ink as an accuracy penalty through `obscuredAcMod`, not AC and not an independent evasion roll. Simply changing the message to “+25% evasion” would misdescribe the current math.
- **Decision:** Align the intended ink design, event terminology, log text, HUD, and tooltips. Either explain obscurity as an accuracy penalty alongside actual evasion, or explicitly redesign/test it as evasion. Show active avoidance and duration/clear conditions accurately.
- **Acceptance:** No player-facing AC language remains in this flow. The UI distinguishes ink obscurity, intrinsic dodge, and effective shot accuracy, including stacked states and cleared ink.

### PT2-18 — Kraken's maelstrom is weak and can miss

- **Reported:** The supposedly powerful charged attack dealt only 7 damage and also missed a ship with about 10% evasion. Its payoff does not match the impending threat.
- **Source finding:** [executeMonsterIntent](../packages/monstrous_core/lib/src/rules/monster_ai.dart) selects a normal monster weapon and routes the catastrophe through ordinary attack resolution with an intent multiplier. [The Kraken catastrophe](../packages/monstrous_core/lib/src/model/monster_intent.dart) currently uses 1.65× damage. A small selected weapon and ordinary hit/dodge checks are plausible contributors, but the exact 7-damage case still needs reproduction, including defenses and blessings.
- **Requested rule:** An uninterrupted Kraken maelstrom should connect unavoidably, across its telegraphed threatened ranges, and feel substantially dangerous. The charge must still provide a meaningful chance to prevent/disrupt it before release; this is not a request to make all monster attacks unavoidable.
- **Design / validation:** Establish explicit boss damage rather than inheriting an arbitrary weak tentacle's profile. Agree how bracing, barriers, armor, and damage reduction mitigate it; unavoidable does not automatically mean unmitigable. Review preview estimates against resolved damage and check other Titans for the same resolution problem.
- **Acceptance:** Seeded tests prove no ordinary accuracy miss or evasion dodge on an uninterrupted maelstrom, meaningful defensive/interruption counterplay, and a damage result matching its preview. Do not choose a final damage number from one anecdote.

### PT2-22 — Tentacle counterplay and Region 2 squid scaling

- **Reported:** Kraken and subsequent squid can retain roughly 25 tentacles dealing repeated 4-damage hits. The first Region 2 squid feels nearly Kraken-strength rather than a progression from Region 1 squid. Standard lacks the old readily available Blade Launcher counterplay; armor that negates each small hit feels disproportionately necessary.
- **Source finding:** [TentacleTrait](../packages/monstrous_core/lib/src/traits/trait.dart) already permits severing with Slicing damage or Harpoon Winch hits. [Squid generation](../packages/monstrous_core/lib/src/content/monsters.dart) sets `5 * level` tentacles, and the sweeping intent attacks per intact tentacle. Counterplay therefore exists for some hardpoints, but accessibility and scaling for each blueprint remain open problems.
- **Investigation:** Trace regional difficulty into squid level/HP/damage/tentacles; compare late Region 1 squid, the Kraken, and early Region 2 squid. Audit per-hit mitigation versus total volley damage and whether the turn remains readable. Do not assume retiring Blade Launcher removed every severing path.
- **Design constraint:** Do not restore lootable Blade Launchers as a shortcut. A possible blade-based Master Refit remains a proposal; ordinary squid must be fair before a specific optional refit is acquired.
- **Acceptance:** Deterministic and simulated encounters cover all five blueprints, with/without armor and relevant refits. A common enemy should not inherit boss-level threat merely by crossing a region boundary; viable counterplay must be available before the damage becomes overwhelming.

## Succession, strongholds, and build persistence

### PT2-23 — Death ledger appears to count unchosen heirs

- **Reported:** The second voyage in the latest playtest showed four captains lost. The player suspected the two unchosen heir candidates were counted. [Follow-up screenshot](playtests/2026-10-20/07-captain-death-count.png).
- **Status: resolved investigation — retained earlier history.** Read-only inspection of the active profile found four distinct completed captain records: two from earlier playtesting and the latest two voyages. Their recorded kills total 14, matching the screenshot. Candidate generation does not call `recordDeath`; the saved aggregate agrees with its history. No player save was edited or reset, and no history was deleted to force the counter to two.
- **Regression coverage:** [playtest_nemesis_continuity_test.dart](../packages/monstrous_core/test/session/playtest_nemesis_continuity_test.dart) exercises two actual deaths, three generated candidates per death, succession, and profile serialization. It requires exactly two captain records and a count of two. If a clean profile later reproduces an excess count, reopen with the before/after history rather than assuming candidate generation is responsible.

### PT2-24 — Nemesis never offered on the following voyage

- **Reported / approved rule:** The previous captain's killer must be guaranteed as one navigation option in the second half of its original region, after the midpoint Haven and before the Titan. It must not replace all three headings with a forced encounter. The player's “Vendetta” quirk refers to the existing Blood Oath behavior, which compels engagement when that option appears.
- **Confirmed cause:** [SeaChart.steerCourse](../packages/monstrous_core/lib/src/rules/sea_chart.dart) eagerly generated the following courses without the active Nemesis or Covenant context. `ensureCourseOptions` then reused these nonempty, context-free offers. Separate eligibility logic allowed first-half appearances and used obsolete boss coordinates as an exclusion.
- **Status: implemented and automatically verified, 20 October 2026; awaiting player replay.** Generate unseen courses on approaching the helm with the current profile context. Eligibility uses actual region legs, never old grid coordinates. Offer one Nemesis side heading on each eligible second-half leg until engaged, preserving two alternatives; a side heading also remains reachable for Reckless Helmsman. Blood Oath still rejects alternatives, and the legacy automatic-advance command selects the compelled course. Once engaged, do not offer it again that voyage. Haven and Titan convergence remain unchanged.
- **Persistence:** Restore already offered helm choices exactly. Discard unseen cached future offers from older encounter checkpoints so they regenerate with the restored profile. Do not erase or reroll the current voyage trail.
- **Verification:** [New regressions](../packages/monstrous_core/test/session/playtest_nemesis_continuity_test.dart) cover complete regional navigation, optional avoidance, all three regions, wrong-region exclusion, old boss-coordinate overlap, no repeat after engagement, checkpoint/helm reloads, later-leg Covenant context, and compelled automatic advance. [Succession flow tests](../packages/monstrous_core/test/session/stage1_roguelite_flow_test.dart) cover Blood Oath enforcement and actual Nemesis combat/bounty. All 339 core, 29 simulator, and 107 Flutter tests passed; core and simulator analysis were clean. These checks do not resolve the separate stronghold or Serpent issues.

### PT2-14 — Remove “Abandon Hunt” from heir selection

- **Status: implemented and verified; awaiting player replay.** The obsolete control is removed; heir selection continues to home preparation. The headless simulation termination command remains for single-voyage audits and must not be restored as a player-facing button. See the [verification receipt in the archive index](archive/README.md#later-verification-receipts).

- **Reported:** The button returns to the opening menu, whose Start action then does nothing. The bloodline should continue until the curse is broken.
- **Source finding:** [death_screen.dart](../apps/monstrous_sea/lib/src/screens/death_screen.dart) still dispatches `AbandonHunt` from heir selection.
- **Requested outcome:** Remove this offered gameplay branch. Preserve normal application exit and legitimate ending choices; do not confuse quitting the app with abandoning the bloodline.
- **Acceptance:** Every non-final death permits choosing/customizing an heir and continuing. No legacy abandon control or dead-start-menu route remains in that flow, including after restart.

### PT2-19 — Fort Krakenwatch is treated like the ancestral home port

- **Status: implemented and verified; awaiting player replay.** Both regional transitions enter `stronghold`, with their own screen, shared voyage shipwright, merchant return context, and retained checkpoint. Permanent progression is rejected outside home; the legacy mid-run ReturnToPort shortcut is rejected. Legacy stronghold/merchant checkpoints are migrated on load. [Core regressions](../packages/monstrous_core/test/session/stronghold_continuity_test.dart) cover both strongholds and both advance commands; [app regressions](../apps/monstrous_sea/test/stronghold_flow_test.dart) cover UI, upgrades, merchant returns, disk reload, and save ordering. See the [verification receipt in the archive index](archive/README.md#later-verification-receipts).

- **Reported:** After the Kraken, Fort Krakenwatch feels almost identical to home and offers Blueprints, although unlocking/switching those should happen between runs after succession.
- **Source finding:** Both regional boss-transition paths in [GameSession](../packages/monstrous_core/lib/src/session/game_session.dart) enter `SessionPhase.port`, reusing the home-port presentation and behavior.
- **Requested outcome:** Distinguish a mid-voyage stronghold from ancestral home. Keep the current captain, blueprint, resources, blessings, marks, and voyage state; show appropriate voyage services. Home-only blueprint unlocking/commissioning must be unavailable in both UI and engine while still at sea.
- **Acceptance:** Test both regional strongholds and both existing advance commands, including saved completed-Titan checkpoints. Home remains available to subsequent heirs; reaching a stronghold never starts a fresh run.

### PT2-20 — Stronghold hull upgrades, Mk tempering, and Master Refits are missing

- **Status: hull/Mk services implemented; Master Refits remain deferred.** The user approved reusing Haven costs, caps, and upgrade rules at strongholds. Gold buys voyage hull tiers and Mk marks; meta-materials buy permanent blueprint progression at home. Both voyage locations now share one shipwright view and existing core handlers. Master Refit catalogs, prices, and choice rules still require the separate Phase 4 discussion.

- **Reported:** No ship-tier upgrade, weapon Mk upgrade, or Master Refit was offered at Fort Krakenwatch.
- **Original scope finding:** Hull refit and hardpoint tempering handlers existed at midpoint Havens, but the reused home-port screen exposed no stronghold service. That gap is now addressed. Master Refits are planned in [the retained Phase 4 scope](#future-master-refits) as **Phase 4**, after Phase 3B, and are still unimplemented.
- **Requested direction:** Give post-boss strongholds the intended in-run shipwright progression. Specify and implement Master Refit choices there, separately from permanent ancestral armament upgrades.
- **Remaining planning constraints:** The existing design calls for exactly two Master Refits per complete three-region run: after the Kraken and World Serpent. Reconcile their catalog with the current three-hardpoint topology, include Standard, and decide Master Refit pricing, choice timing, and duplicate/refit rules. Ordinary hull/Mk services use the approved Haven rules and require no new pricing decision.
- **Acceptance:** Services are discoverable and affect the current voyage, persist through region transitions/save-load, cannot be claimed twice by reopening or reloading, and reset only at a true new voyage. Midpoint Haven services continue to function.

### PT2-21 — Shrine blessing disappears entering Region 2

- **Status: implemented and verified; awaiting player replay.** Stronghold departures no longer pass through new-voyage reset logic. Full build and blessing state persists through arrival, merchant visits, checkpoint reloads, helm, and the next combat. Combat-only boosts still reset at combat boundaries; a new heir starts a fresh level-1/Mk-I voyage with permanent unlocks retained. Autosaves are serialized and snapshot before I/O so a delayed checkpoint cannot recreate a voyage after death. See the [verification receipt in the archive index](archive/README.md#later-verification-receipts).

- **Reported:** A blessed weapon lost its blessing without explanation at the first Sargasso Drift battle.
- **Source finding / leading cause:** A boss transition enters `port` (PT2-19). `_handleTakeHelm` clears `ship.blessings` and calls `_resetVoyageRefits` whenever leaving `port`; `_handleVentureOutToSea` also performs fresh-voyage resets. The source path explains how a stronghold departure can erase a current build. A runtime regression test should confirm the exact route.
- **Priority:** High. Fix the lifecycle boundary with PT2-19 before tuning later-region balance. Audit temporary hull/mark resets and storage deletion at the same boundary, not only the displayed blessing.
- **Acceptance:** A blessed, tempered, upgraded ship survives Kraken → stronghold → Region 2 and World Serpent → stronghold → Region 3 with the same run build, including save/reload before and after departure. Combat-only effects still clear appropriately. Actual new voyages still reset blessings and temporary upgrades exactly once.

## Decisions to resolve before dependent implementation

1. **Family identity:** Confirm the shared permanent surname proposal, epithet treatment, and legacy-save migration. This playtest asks to discuss it, not to silently make existing names permanent.
2. **Flow and chart:** Review direct-to-helm flow and a chart layout with useful scouting/milestone information. Preserve necessary encounter and reward choices.
3. **Combat semantics:** Agree on Serpent dodge behavior, ink's actual avoidance mechanism, unavoidable Kraken release plus allowed mitigation, and accessible tentacle counterplay. The user's desired maelstrom behavior is recorded; precise damage tuning is still open.
4. **Master Refit scope:** Haven/stronghold hull and Mk rules are approved and shared. Keep Phase 4 Master Refits separate and reconcile their catalog/upgrade economy with current hardpoints.

## Verification plan

- Add targeted core regression tests for lifecycle, avoidance/damage math, loot events, and reward idempotence; use injected RNG rather than judging a few unseeded fights.
- Add widget/flow coverage for direct course selection, stable departing headings, quirk explanations, salvage receipts, heir continuation, and home/stronghold service differences.
- Review combat/chart designs visually at realistic desktop sizes, compact layouts, and 115–130% text. Automated layout checks alone did not establish readability in this playtest.
- Run a native journey across the Kraken/stronghold boundary with a visible blessing and upgrade, then reload and die/continue. Verify both persistence within a run and resets between runs.
- After mechanic changes, run appropriate analysis/tests and a seeded simulation comparison that states blueprint/unlock conditions. Keep balance observations separate from correctness claims.
- For documentation maintenance, run `python tools/check_docs.py` from the repository root and review the actual diff. Gameplay tests are needed when gameplay code changes, not merely because historical documents move.

## Deferred UI art and icons

Planning only, tied to PT2-04–07. Audit/reuse approved assets before scheduling the user's image workflow. No images are generated by this documentation cleanup.

### Art style and workflow

- Retain the historical nautical, woodcut / ink-and-parchment style of the approved raster collection. Avoid colorful emoji and unrelated generic symbols.
- Audit [existing art](../apps/monstrous_sea/assets/art/) and [PilotArt](../apps/monstrous_sea/lib/src/widgets/pilot_art.dart) before requesting replacements. Missing UI imagery can be a missing mapping/widget rather than a missing image.
- Prepare a reviewed asset list and briefs for the user's established image workflow when that work is scheduled. Do not generate a new set now.
- Distinct gameplay identities need distinct silhouettes at actual UI size, with legible labels and hover/focus descriptions. An icon must not imply an item is a different consumable.
- Continue using code/vector linework for structural UI where appropriate. Icons supplement readable text; they do not replace accessible names or become the only indicator of an important state.

### Art navigation and existing assets

| UI use | Current concern | Existing candidates to audit later |
| --- | --- | --- |
| Home-port Merchant | Button feels empty after icon removal. | `icon_treasure_map.png`, `icon_helm_map.png`; choose by meaning rather than filling space. |
| Home-port Blueprints | Needs a recognizable shipwright/drafting identity. | Existing art may be insufficient; check the gallery before adding a dedicated drafting image to the production list. |
| Sea Chart buttons | Thematic imagery is inconsistent or absent depending on screen. | `icon_helm_map.png`, nautical navigation assets, and prior chart imagery. |
| Other existing navigation controls | Review consistency alongside the above. | `icon_port_haven_map.png`, `icon_anchor_map.png`, `icon_cannons_map.png` as appropriate. |

These are audit candidates, not approved final mappings. Screenshots 4 and 5 in the playtest also show that themed icons still exist in some locations; reconcile usage instead of assuming all icons were removed.

### Art consumables

Every current consumable needs its own accurate image. The current mappings below are confirmed in [SvgAssetView.pathForItem](../apps/monstrous_sea/lib/src/widgets/svg_asset_view.dart).

| Identity / enum | Current art | Later work |
| --- | --- | --- |
| Unstable Tincture / `unstableTincture` | `icon_unstable_tincture_map_v4.png` | Audit/reuse approved bottle art. |
| Hull Patch Kit / `hullPatchKit` | Unstable Tincture image | Dedicated repair materials/toolkit image. |
| Blast Pack / `blastPack` | `icon_blast_pack_map.png` | Audit/reuse approved explosive bundle art. |
| Bottled Kraken Ink / `krakenInkBomb` | Blast Pack image | Dedicated ink vessel image, clearly different from pitch and explosives. |
| Alchemical Pitch Flask / `alchemicalPitch` | Blast Pack image | Dedicated pitch vessel image, clearly different from ink and tincture. |
| Chakram / `chakram` | `icon_chakram_map.png` | Audit/reuse approved throwing-disc art. |

Apply the eventual mapping consistently to merchants, loot, belt inspection, salvage results, and battle actions. Consumables remain single-use and have no rarity/charge variants requiring separate pictures.

### Art meta-materials and trophies

The [blueprint screenshot](playtests/2026-10-20/02-blueprint-materials.png) shows generic symbols that do not match the intended collection. Plan distinct readable images for every persisted currency in [MetaInventory](../packages/monstrous_core/lib/src/model/meta_inventory.dart).

| Identity | Scope |
| --- | --- |
| Sea Glass | Common exploration material. |
| Monster Bone | Common combat organic. |
| Depth-Wrought Iron | Rare exploration material. |
| Abyssal Barnacles | Rare combat organic. |
| Kraken's Beak | Region 1 Titan trophy. |
| World Serpent's Scale | Region 2 Titan trophy. |
| Leviathan Core | Region 3 trophy / ending relevance. |
| Primordial Cinders | Endgame currency; include when that UI is visible. |

The same material must look the same in costs, inventory, rewards, and progression screens. Counts must remain readable at zero, large quantities, and insufficient-resource states. Do not confuse material rarity with the retired consumable rarity system.

### Art hardpoints

Earlier standalone weapon illustrations exist, including cannon, torpedo, blade launcher, railgun, and flamethrower images. They are not automatically accurate pictures of the current intrinsic weapons. The inspection UI also currently omits hardpoint imagery.

Audit these current blueprint identities against [the catalog](../packages/monstrous_core/lib/src/model/flagship_blueprint.dart) and [weapon content](../packages/monstrous_core/lib/src/content/ship_weapons.dart) when creating the final production brief:

| Blueprint | Broadside | Signature | Utility |
| --- | --- | --- | --- |
| Standard | Naval Cannon Battery | Twin Chaser Cannons | Gunnery Drill |
| Ironclad | Heavy Carronades | Reinforced Prow Ram | Fortify Iron Plates |
| Clipper | Long-Barrel Swivel Guns | Precision Culverin | Evasive Rigging |
| Bombardier | Shrapnel Howitzers | Heavy Siege Mortar | Spotter Flare |
| Corsair | Chain-Shot Broadside | Harpoon Winch | Drifting Tether-Trap |

Use the current source names as the final authority for asset briefs; the table describes the identities to cover. Decide whether Mk marks, blessings, and future Master Refits reuse a base illustration with readable overlays or warrant a variant. Do not generate every combination or illustrate a speculative Master Refit before its design is agreed.

### Art completion criteria for the eventual pass

- Approved asset inventory distinguishes reusable art, mapping-only repairs, and genuinely missing pictures.
- Each consumable, material, and hardpoint is recognizable and correctly mapped everywhere it appears.
- Navigation imagery is consistent with the parchment palette and nautical subject matter.
- Inspect screenshots at real display size and 115–130% text settings; preserve contrast, labels, accessibility, and compact layouts.
- Add focused mapping/asset-load checks where useful, then review the rendered UI. File existence alone does not establish visual correctness.

## Future work retained from earlier plans

These entries preserve intent without reviving old task briefs. Their detailed designs and implementation timing remain separate from the immediate playtest remediation.

### Future Master Refits

**FUT-01 — Deferred Phase 4, related to PT2-20.** Offer exactly two transformative Master Refit opportunities in a full three-region voyage: at post-Kraken and post-World-Serpent strongholds. They are voyage upgrades, distinct from permanent ancestral armament tiers, shrine blessings and midpoint tempering. First fix stronghold lifecycle/build retention (chunk A).

Prepare a catalog covering Standard as well as Ironclad, Clipper, Bombardier and Corsair against the current three-hardpoint system. Agree on prices versus rewards, offer/choice counts, duplicate stacking, interactions, save/load idempotence, and reset timing. Historical refit examples remain inspiration only; auxiliary mounts, obsolete weapon identities, arbitrary extra stuns and other superseded assumptions are not approved by their presence in an old catalog. A blade-based transformation is a possible design, not guaranteed access to an old Blade Launcher.

Acceptance: review an explicit Phase 4 design before implementation, then verify exactly-once claims across both strongholds, preserved build state, and clear player-facing effects. Post-boss hull/Mk services must also be specified and tested; they are not supplied by a new label alone.

### Atmosphere and living-port presentation

**FUT-02 — Deferred atmospheric/civic work.** Preserve the goals of marine ambience, cannon/monster/impact audio, shanties, legible battle VFX, environmental weather and gradual Sea-Madness cues. Coordinate readability with PT2-11 before adding visual noise.

The broader living town can express the family's sacrifice through a seawall/lighthouse, memorial, tavern, apothecary garden, lore and inhabitants. These are historical future concepts requiring scoped designs, not currently approved free starting items, hirelings, or automatic scouting bonuses. Existing Harbor Monument progression is a separate implemented system. Avoid describing all town or audio work as completed because its hooks or a profile field exist.

### Additional encounters and exploration

**FUT-03 — Proposed, deferred.** Earlier concepts include derelict ghost fleets, rifts/maelstroms, Siren Reefs, and navigation hazards with explicit risk/reward. Define any future leg-skipping, new encounter rewards or curses against current Dead Reckoning and save rules. Existing ordinary wrecks, coves, shrines and smugglers do not prove these additional concepts are implemented.

### Ending delivery and Ancestral Chronicles

**FUT-04 — Deferred presentation/features.** Preserve the intended memorial/peaceful-town epilogue after Shattering, the corrupted returning keel/Covenant awakening after Claiming, a possible Grand Admiralty Crest, and Ancestral Chronicles sandbox/challenge voyages. Ending choice handlers and persistent flags already exist; full cinematics, sandbox modes, atmosphere and civic scenes must be specified and delivered separately. Use [narrative canon](LORE.md#the-caldera-and-ending-choices) for the story and avoid spoiling it in onboarding.

## Maintenance rules

- Keep the PT2 IDs stable; mark work fixed only with an implementation and relevant verification. Do not discard an unresolved observation merely because a similar historical issue once passed tests.
- Move completed task receipts into the archive when useful, while retaining links and updating canonical rules in their owning document.
- Old pricing, animation, font, icon, or disabled-button recipes are not new open requirements. Bring a still-observed problem forward as a current issue with evidence; do not reimplement completed fixes from archival imperative prose.
