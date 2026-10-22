# Playtest backlog

Status: work consolidated on 20 October 2026. PT2-01–22 retain the original playtest observations; PT2-23/24 record the follow-up; PT2-25 records the later ship-asset failure; PT2-26 tracks the heir trait review; PT2-27 records an unexpected blueprint unlock. Issues remain open unless explicitly marked resolved or implemented below. Source findings are dated observations, not proof of runtime reproduction.

Read [Current game](CURRENT_GAME.md) for approved baseline rules and [Lore](LORE.md) for canon. A reported symptom, approved requested outcome, unresolved design choice and deferred feature remain distinct. Preserve the six original [screenshot evidence files](playtests/2026-10-20/), follow-up evidence, and issue IDs when updating status. Historical receipts are indexed in [the archive](archive/README.md).

## Recommended work chunks

Each chunk should produce a reviewable change and focused verification. These are proposed scopes, not authorization to implement every design proposal without discussion.

| Order | Chunk | Items | Exit condition |
| --- | --- | --- | --- |
| Initial follow-up | Restore the guaranteed Nemesis choice; investigate the death ledger | PT2-24, PT2-23 | Nemesis is an optional, reachable second-half course in its killer region; the ledger counts actual deaths rather than candidate heirs. See individual statuses. |
| A — implemented, awaiting player replay | Protect voyage and succession continuity | PT2-19, PT2-21, PT2-14; voyage upgrades from PT2-20 | Strongholds preserve the current run and blessings; home-only blueprint actions stay at home; succession cannot lead into a dead menu. |
| B | Audit combat avoidance, boss damage, and regional scaling | PT2-12, PT2-17, PT2-18, PT2-22 | Seeded examples explain hit/dodge odds, Kraken catastrophe damage, and ordinary squid strength; agreed fixes have deterministic coverage. |
| C — implemented, positive player replay | Shorten navigation and make outcomes explicit | PT2-09, PT2-10, PT2-15, PT2-16 | Ordinary victories lead efficiently to course selection; headings do not flash replacements; restrictions and salvage rewards are visible. |
| D | Discuss the opening and shared family identity | PT2-01, PT2-02 | Agree on a spoiler-light prologue and permanent surname rules, including legacy-save migration, before implementation. |
| E | Design the command station and useful sea chart | PT2-03, PT2-08, PT2-11, PT2-13 | Review layouts and terminology at realistic window sizes/text scales before replacing the existing presentation. Apex naming can be a small independent fix. |
| F | Specify and implement post-boss progression / Phase 4 | PT2-20, depends on A | Strongholds offer the agreed hull/mark upgrades and exactly scoped Master Refits, with run persistence and blueprint-specific choices. |
| G — discussion required | Revamp heir Boons and Quirks | PT2-26 | Audit all ten traits against current mechanics, agree on meaningful effects/tradeoffs and saved-heir handling, then implement with accurate descriptions. |
| Later | Curated art and icon pass | PT2-04–07 | Use the [deferred asset backlog](#deferred-ui-art-and-icons); audit existing assets first. No image generation in this batch. |
| Later — substantial cleanup | Audit and retire vestigial core content | FUT-05 | Inventory live content, legacy helpers and save dependencies; reconcile ship/monster naming and weapon identities, then remove or isolate obsolete paths in scoped changes. See [cleanup scope](#deferred-core-cleanup). |
| Development support — implemented | Launch configurable isolated playtest scenarios | Requested 21 October 2026 | Debug menu selects loadout, region start/Titan or the Caldera choice; repeatable relaunch and return to the normal game preserve real progress. |

The Nemesis/death-ledger follow-up, continuity batch A and B's Serpent, ink and Kraken release fixes are implemented. B's initial tentacle/regional-scaling values are also implemented. Navigation chunk C is also implemented, and the player reports the changes are looking good in playtesting. Broader replay should still evaluate the stronghold boundary and combat changes. The arena asset failure now has recovery/retry handling (PT2-25); its original trigger still needs player replay. A verified test-save leak that can create unpaid blueprint unlocks has been fixed (PT2-27). F is new feature work, rather than a claim that Master Refits were already completed in Phase 3B.

## Development playtesting

**Implemented, 21 October 2026.** The debug playtest menu permits choosing any current blueprint, hull tier, ancestral signature tier, independent hardpoint Mk marks and blessing dedications/tiers, gold and seed. Start at a selected region's first course choices, face its Titan directly, or skip combat to the Caldera decision. Relaunch repeats the configured scenario; Change Scenario retains the configuration for edits. Test sessions use fresh profiles with autosave disabled and isolated storage, and returning to the normal game preserves its controller. The menu and factory are debug-only; none of these starting grants alter normal progression rules. See [access instructions](../README.md#playtest-menu-debug-builds), [technical behavior](../CLAUDE.md#development-playtesting) and the [verification receipt](archive/README.md#later-verification-receipts).

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

- **Status: implemented; positive player replay reported.** The app resolves the core's compatibility Rest checkpoint directly into Setting Course after loot decisions. Titan rewards instead reach the stronghold/final resolution through the existing engine route. Inspection defaults closed below the headings, and emergency triage remains available on the helm with its existing 25% floor and gold cost. Restored old Rest checkpoints follow the same route. No island, shrine, or wreck decision is skipped.

- **Evidence:** [Screenshot 4](playtests/2026-10-20/04-post-fight-scroll.png) requires scrolling through hardpoints, belt items, and the unavailable carpenter's workbench to reach navigation. [Screenshot 5](playtests/2026-10-20/05-setting-course.png) already offers the chart, collapsible inspection, hull status, and headings.
- **Proposed direction:** After ordinary victory/loot collection, proceed directly to Setting Course and keep inspection collapsed by default. Remove or bypass the redundant Rest screen in that flow. Preserve any meaningful rewards or decisions rather than silently skipping them.
- **Exceptions to design explicitly:** Titan victory must reach the stronghold or final resolution; island duties, shrine choices, and shipwreck salvage still require their own decisions. Empty loot and a full belt must also lead somewhere valid.
- **Starting points:** [rest_screen.dart](../apps/monstrous_sea/lib/src/screens/rest_screen.dart), [loot_screen.dart](../apps/monstrous_sea/lib/src/screens/loot_screen.dart), [helm_screen.dart](../apps/monstrous_sea/lib/src/screens/helm_screen.dart), session transitions and checkpoint saves.
- **Acceptance:** Navigation is immediately available after normal reward resolution without scrolling past inspection, including at 115% and 130% text size.

### PT2-10 — Headings briefly flash different encounter options

- **Status: transition fix implemented and verified; positive player replay reported.** The outgoing Helm screen retains its rendered view during AnimatedSwitcher's fade rather than rebuilding from the next encounter's mutable chart. Steering is guarded against duplicate activation; outgoing screens also ignore input/focus. Offered helm choices and resolved loot/wreck checkpoints retain their saved state across reload. This does not add mid-combat resume; battles still use the existing between-encounter checkpoint policy.

- **Reported:** Clicking a heading briefly replaces the three lookout options before the next screen appears. No screenshot was captured.
- **Investigation lead:** [SeaChart.steerCourse](../packages/monstrous_core/lib/src/rules/sea_chart.dart) generates the next options while the UI observes mutable controller state. [HelmScreen](../apps/monstrous_sea/lib/src/screens/helm_screen.dart) renders those live options. Confirm notification/transition ordering before calling this the cause.
- **Acceptance:** Once committed, the chosen course remains stable until departure. No replacement options flash, duplicate clicks cannot steer twice, and reload does not roll a new encounter.

### PT2-15 — Reckless Helmsman restriction is not communicated

- **Status: implemented; positive player replay reported.** The UI and engine share the course-restriction reason. Restricted cards show a disabled heading button, persistent readable explanation, tooltip and semantic hint. Blood Oath alternatives use the same presentation; guaranteed Haven/Titan approaches remain reachable.

- **Reported:** Dead Ahead does not look clearly unavailable for an heir with that quirk.
- **Requested outcome:** Disable and visibly distinguish the restricted heading; hover/focus explains the active quirk, and touch users have an equivalent explanation. An engine rejection alone is insufficient.
- **Starting points:** [HelmScreen / _CourseOptionCard](../apps/monstrous_sea/lib/src/screens/helm_screen.dart), session's existing steering validation.
- **Acceptance:** Show the restriction before clicking. Preserve the existing single-heading Haven/Titan convergence exception so this quirk cannot strand the voyage; also respect Blood Oath restrictions.

### PT2-16 — Shipwreck salvage promises retired loot and hides the result

- **Status: approved starting rewards implemented; positive player replay reported.** Search Hold always grants 2–4 Sea Glass, independently rolls a 25% chance of 1 Depth-Wrought Iron and a 50% chance of one single-use consumable, in every region. The user approved these values. Strongbox remains 60–120 gold + 2–4 Sea Glass; timbers retain up-to-25% hull healing, existing penalties and 1–2 Sea Glass. Exact receipts (including no consumable/zero healing), the spent salvage choice and any belt overflow persist. Full belts offer jettison/stow/leave controls and require an explicit resolution before departure; rewards cannot be claimed twice after reload. See the [verification receipt](archive/README.md#later-verification-receipts).

- **Reported:** “Scour Hold for Munitions & Weaponry” promises a military-grade weapon or consumable, despite weapons no longer dropping. The completion screen does not show what was received.
- **Source finding before the fix:** [_handleSalvageShipwreck](../packages/monstrous_core/lib/src/session/game_session.dart) currently awards a consumable, with a possible Depth-Wrought Iron reward in later regions; other salvage choices award gold/healing and Sea Glass. The [screen](../apps/monstrous_sea/lib/src/screens/shipwreck_screen.dart) ends with generic “SALVAGE COMPLETE” text even though reward events exist.
- **Requested direction:** Describe the desired exploration salvage as common materials, sometimes rare materials, and perhaps a consumable. The approved rates above now resolve the previously open probability decision; they remain starting values for playtesting. Keep strongbox/timber alternatives distinct.
- **Acceptance:** Preview matches the actual reward table. Display exact materials, quantities, item, gold, or healing received; explain a no-item result. A full belt offers visible overflow/claim/jettison handling, rather than an invisible item left in `pendingLoot`. Rewards cannot be claimed twice and their persistence is verified.

## Combat mechanics and the command station

### PT2-25 — Battle arena fails to load the Standard ship image

- **Reported:** The arena turns red with Flutter's `Unable to load asset: assets/art/ship_standard_map.png` error beneath the ship HUD. [Screenshot](playtests/2026-10-20/08-missing-standard-ship-asset.png).
- **Status: failure recovery implemented; original missing-file trigger unconfirmed, player replay pending.** Source and current Windows bundle both contain the same Standard PNG (SHA-256 matches). Cold scene loads also pass. That does not explain the earlier intermittent failure. Missing/undecodable illustrations now show a labeled cartouche and an inline Retry Art control while combat remains usable; recovery reloads approved art without resetting the battle.
- **Verified failure handling:** Injected failures exposed Flame 1.38.2's image cache creating additional unhandled error futures even when the caller catches a failed load. The scene now loads/decodes before putting successful images in its local cache. Failed assets stay retryable, with safe disposal during an in-flight retry. No art was generated/replaced. See the [verification receipt](archive/README.md#later-verification-receipts).
- **Starting points:** [PilotArt](../apps/monstrous_sea/lib/src/widgets/pilot_art.dart), [battle scene loading](../apps/monstrous_sea/lib/src/battle/monstrous_sea_battle_game.dart), and the Flutter asset bundle/build.
- **Acceptance:** Repeated battles and scene transitions load approved ship art in a clean Windows build; loading failure has a readable fallback instead of replacing the arena with a raw error. Keep this separate from deferred new art generation.

### PT2-11 — Combat UI does not function as a readable command station

- **Status: Chronicle lifecycle and scrolling fixes implemented; broader command-station design remains open.** Succession and fresh home departures clear prior-voyage entries before appending the new events. Earlier encounters and stronghold transitions retain the current voyage's history. Each newly opened Chronicle starts at the latest messages; new entries follow only while the reader stays at the live end. Scrolling into history preserves the reading position, with **Latest Messages** returning to live updates. Battle actions no longer force the log to the bottom. The live Chronicle is session memory, not a new persisted history/archive feature. See the [verification receipt](archive/README.md#later-verification-receipts).
- **Evidence:** [Screenshot 6](playtests/2026-10-20/06-battle-command-station.png). The Chronicle shows roughly two messages despite a turn containing movement, attacks, and status messages. Floating damage/status effects are small and disappear quickly. Intent is squeezed between log and weapons; threat preview and helm controls are crowded at the right edge.
- **Follow-up report — previous-voyage entries remain:** After death and succession, the next run's Chronicle still contains the previous run's messages. The player has observed this through a second run; accumulation across third and later runs is suspected, not yet observed. The live Chronicle should start fresh for each voyage. Any future historical archive should be a separate, deliberate feature rather than stale messages in the current log.
- **Follow-up report — incorrect initial scroll position:** On entering a battle, the Chronicle initially shows its oldest messages. Only after the player performs an action does it jump to the latest messages. Opening a battle should show the current encounter's latest opening messages/intent immediately, without requiring an action. Preserve deliberate manual scrolling after entry.
- **Confirmed causes and implementation:** [GameController](../apps/monstrous_sea/lib/src/game_controller.dart) previously appended events without a voyage reset. It now clears on successful succession and fresh departure boundaries. [CombatLogView](../apps/monstrous_sea/lib/src/widgets/combat_log_view.dart) now owns scrolling, follows layout changes until variable-height rows reach the real live end, and pauses that behavior during manual history reading. [BattleScreen](../apps/monstrous_sea/lib/src/screens/battle_screen.dart) no longer overrides the reader's position during action playback. Nine new regressions cover third-voyage isolation, continuity, initial position, live updates, manual reading, reopen and action playback.
- **Design goal:** Make the battle screen the player's station of command: readable intent and consequences, deliberate helm selection, clear weapon/utility actions, and accessible recent history. Treat log, feedback effects, and controls as one layout problem rather than enlarging one element until the arena no longer fits.
- **Options for review:** Group log entries by round/action, expandable or resizable history, a useful last-turn summary, larger/longer-lived feedback, a prominent intent/threat panel, and a coherent helm/action group. These are candidates, not an approved final layout.
- **Starting points:** [battle_screen.dart](../apps/monstrous_sea/lib/src/screens/battle_screen.dart), [combat_log_view.dart](../apps/monstrous_sea/lib/src/widgets/combat_log_view.dart), [Flame battle effects](../apps/monstrous_sea/lib/src/battle/monstrous_sea_battle_game.dart).
- **Acceptance:** At normal desktop sizes and 115–130% text, the player can understand the impending attack, select a helm order, and review a whole previous turn. Preserve intentional manual log scrolling; do not auto-scroll readers away from history. Compact layouts remain usable. Damage and status feedback must be legible without depending entirely on transient floating text.
- **Additional acceptance:** Verify death → heir → second and third voyages exclude older voyages' entries. On initial battle layout and subsequent encounter entry, display the latest relevant opening messages before any action, including with a long current-voyage log. New entries follow the live end only when the player has not intentionally scrolled back; offer a clear return-to-latest action while reading history. Keep same-voyage history scope explicit during layout design rather than accidentally deleting all earlier encounters.

### PT2-12 — Apex Serpent evasion feels nearly unbeatable

- **Status: Implemented; player replay pending.** Ordinary Serpents retain 20% innate dodge; Apex and World Serpents retain 30%. Recoil changes range without adding dodge. Both intent-driven and legacy special-action paths no longer accumulate evasion.
- **Reported / reproduced before the fix:** The player observed 30 → 50 → 80% dodge. A seeded forced-recoil sequence reproduced 30 → 50 → 70 → 80 → 80%, persisting after an ordinary action. With 85% final accuracy and 80% dodge, an uncountered shot connected only 17% of the time.
- **Accepted resolution:** Remove recoil's bonus entirely while preserving retreat. Pin halves innate dodge and prevents recoil movement for that turn; Spotter Flare suppresses dodge. The HUD displays effective **Dodge**, including Pin/Flare, separately from weapon accuracy. Intent text no longer promises an evasion boost.
- **Verification:** Deterministic tests cover repeated recoils, the legacy path, counter expiration, actual hit/dodge roll combinations and the HUD. At Medium, an unblessed Standard cannon connects 68% against ordinary Serpents and 59.5% against Apex/World Serpents; Pin raises these to 76.5%/72.25%, and Flare reaches the 95% accuracy cap. Range penalties and other modifiers still apply. See the [verification receipts](archive/README.md#later-verification-receipts) for the seeded voyage comparison and limits.

### PT2-13 — Apex names are overlong

- **Reported:** `Apex Phosphor Wyrm Darting Death` is cumbersome; other Apex monsters follow the same pattern.
- **Source finding:** [applyApexEnhancements](../packages/monstrous_core/lib/src/content/monsters.dart) prepends the full species Apex title to the existing generated name.
- **Requested outcome:** Use one readable monster identity with Apex status clearly conveyed. Review a shorter title or separate status badge instead of stacking multiple names. Keep Nemesis identity distinct from generic Apex naming.
- **Acceptance:** All Apex species, combat logs, lookout calls, narrow HUDs, and Nemesis variants remain readable without losing useful species information.

### PT2-17 — Ink still claims “+25 AC”; avoidance needs a visible HUD explanation

- **Status: Implemented; player replay pending.** Ink remains an accuracy penalty, with no independent dodge roll. Deployment events use `accuracyPenalty`; the legacy `acBonus` read accessor remains compatible. Core narration and the app log explain percentage points and clearing conditions without AC wording.
- **Reported / confirmed before the fix:** Kraken ink claimed `+25 AC`, while the math subtracted 25 percentage points from shot accuracy. Squid normally subtracts 20; the display now reads the actual monster value, including variants.
- **Accepted rule / presentation:** Display active obscurity beside monster health, separately from effective dodge. Weapon tooltips show opening-shot accuracy using current range, gunnery boosts, Flare and obscurity, before target dodge. Ghostwake Culverin's obscurity bypass is reflected. Successful hits have a 25% chance to disperse obscurity; Spotter Flare clears/suppresses it. There is no fixed ink duration. Legacy AI cannot redeploy ink while illuminated.
- **Copy decision, 21 October 2026:** Keep monster ink narration brief; it should not name the specific player hardpoint that counters it. Spotter Flare's own tooltip should explain clearing Obscured and suppressing dodge. Shortened narration is intentional, not a reason to restore the old detailed sentence. The narration assertion follows this contract, with separate mechanic coverage retained; the underlying ink and Flare rules are unchanged.
- **Verification:** Core tests cover actual accuracy, no added dodge, dispersion, Flare and legacy deployment suppression. App tests cover real deployment logs, clearing and tooltip updates, plus compact/desktop layouts at 115–130% text. Native Windows checks and screenshots use readable system fallback fonts. See the [verification receipts](archive/README.md#later-verification-receipts).

### PT2-18 — Kraken's maelstrom is weak and can miss

- **Status: Implemented; first successful player replay recorded, broader balance review open.** The accepted Kraken release deals 38 base Blast damage through the shared damage pipeline, with no accuracy or dodge roll. Armor, Gunnery Drill, barriers, Corroded and Electro-Jolt still apply. Its preview explicitly labels base damage before weakening/defenses. A full no-strike windup turn and existing interruption remain intact.
- **Reported / reproduced before the fix:** The player saw 7 damage and a dodge. Seed 42 reproduces a 4-damage tentacle becoming a 7-damage release, while a selected 26-damage ram becomes 43, both against a preview of 38. Separate forced rolls reproduce misses and dodges. This is a sufficient reproduction, not proof of the exact historical playtest defenses/blessings.
- **Accepted scope:** Use a dedicated Kraken attack profile, independent of weapon availability, cooldowns or remaining tentacles. Heavy Mortar, Harpoon, Blast Pack, Stun and windup-breaking blessings retain their existing disruption. Other Titan releases retain ordinary resolution pending their separate review; they were inspected for the same random-weapon issue, not silently retuned.
- **Verification:** Deterministic tests cover all five fresh hulls at all ranges, no accuracy/dodge RNG, old serialized intent multipliers, missing weapons, mitigation, weakening, retaliation, windup timing and representative interruption paths. Fresh Standard takes 38, or 30 braced; fresh Ironclad takes 35 through its 3 flat armor. A valid 20-HP barrier absorbs another 20 after reduction. See the [verification receipts](archive/README.md#later-verification-receipts).
- **Balance follow-up:** The matching 1,000-voyage fresh-Standard audit drops from 31 Kraken victories to 1. These bots do not time Standard's utility for the release and are not a human win-rate target. Keep the approved 38 base damage for player evaluation; do not call overall Kraken balance resolved. Regional tentacle scaling remains PT2-22.
- **Player replay after the fix:** The player defeated the Kraken with roughly 30% hull remaining, brought to roughly 50% with a Hull Patch Kit on the last battle turn. The route included three blessing shrines, a Tier II Brinemother Signature, Earthshaker-blessed rigging with a 15-HP barrier timed before impact, and several shrines/wrecks chosen instead of battles to reduce chip damage. This supports the usefulness of build preparation and defensive timing; it does not establish typical-run difficulty. Starting hull, blueprint/marks and permanent upgrades were not specified.
- **Player's balance direction:** The Kraken feels strong but acceptable as a roguelite milestone. Early failed voyages are expected; learning mechanics, choosing routes and earning meta-upgrades should improve consistency. Retain 38 base damage for now rather than nerfing solely to restore the simple bots' former win rate. Compare less shrine-favored builds and more combat-heavy routes as part of further balance evaluation.

### PT2-22 — Tentacle counterplay and Region 2 squid scaling

- **Status: Accepted starting values implemented and verified; player replay pending.** The player approved smaller ordinary/Apex squid pools, a 12-tentacle Kraken, predictable sweeps and continued damage growth every two levels. These are initial balance values, not a claim that every regional matchup is final.
- **Reported / reproduced before the fix:** The opening Region 2 squid had 225 HP and 25 tentacles, matching the Kraken's 100-damage all-hit sweep. Later ordinary squid could reach 40–45 tentacles. Sweeping Tentacles also randomly selected either a normal Ram or the complete tentacle barrage under one label/preview.
- **Current profile:** Ordinary squid start at 40 HP and gain 20 per additional level; their tentacles grow from 4 to at most 8 (`clamp(level + 3, 4, 8)`). Apex keeps its existing +30% HP/Carapace enhancements but adds only 2 limbs. The default Kraken retains 300 HP and its dedicated 38-base-Blast maelstrom, with 12 tentacles. Opening Region 2 ordinary squid now have 120 HP and 8 tentacles, giving at most 32 base sweep damage before hit/dodge rolls, weakening and defenses.
- **Accepted damage follow-up:** Preserve levels 1–2 at 2–3 damage and levels 3–6 at 3/4; continue with 5 per limb at levels 7–8, 6 at 9–10 and 7 at 11–12. Ordinary Region 2 sweeps are now 32–40 base damage; Region 3 sweeps 48–56. Remaining-limb counts, per-hit armor and default Kraken damage are unchanged. The same 24,000-fight matrix confirms all early/Kraken cells identical to the preceding capped-damage stage and modestly greater late-region pressure. The live level-12 preview and all-blueprint deterministic damage tests cover the 7-damage peak. See the archived receipt for the comparison; this is still a player-evaluation starting curve.
- **Predictable sweeps and feedback:** The sweep selects a Tentacle weapon, never a random Ram, and attacks once per remaining limb. Missing armament hesitates; zero remaining limbs produce a clear narration rather than a fabricated miss. The battle preview shows the current strike count, per-hit base damage and gross maximum, updates after severing, and preserves the Long-range escape preview.
- **Counterplay:** Bombardier Howitzers and Corsair Chain-Shot/Harpoon retain severing. Standard, Ironclad and Clipper's ordinary intrinsic weapons retain their identities; helm movement can avoid Short/Medium sweeps without special weapons or armor. Per-hit armor, bracing, barriers and weakening remain intact. No lootable Blade Launcher or unimplemented Master Refit was introduced.
- **Verification:** Core tests cover regional generation, all five blueprints with stock/upgraded builds, per-hit armor, sweep selection, severing, helm escape, zero/missing limbs and the unchanged Kraken maelstrom. Widget and native Windows checks cover live preview updates at 115–130% text. See the [verification receipts](archive/README.md#later-verification-receipts) for the full before/after comparison and limits.
- **Balance follow-up:** The [reproducible audit](../packages/monstrous_sim/bin/audit_tentacles.dart) compares 24,000 isolated full-health fights per version across five blueprints, six encounter types, stock/Hull-II-Mk-II builds, simple fire-only/helm-and-utility tactics and starting-armor controls. Starting-armor controls still permit active utility to add armor; no blessings, consumables, permanent stat upgrades or unavailable Master Refits are assumed. The same 100 seeds per cell improve upgraded Standard's opening-R2 result from 92 to 99 victories and late-R2 from 12 to 74; the earlier 10 step-limit outcomes disappear. These are encounter comparisons, not human voyage win rates or proof that the old limit cases were soft locks. Armor remains valuable; later-region whole-run difficulty still needs playtesting.

## Succession, strongholds, and build persistence

### PT2-26 — Revamp heir Boons and Quirks for current mechanics

- **Reported / requested:** Several heir traits describe obsolete systems, overlap baseline abilities or promise benefits that are not apparent in play. Schedule a separate design discussion and implementation task; replacement effects and values are **not yet agreed**. Review the whole five-Boon/five-Quirk catalog, starting with the four below.
- **Status: open — discussion required.** These are source observations from 20 October 2026, not runtime reproductions or approved replacement rules.

| Trait | Player concern | Current source finding / discussion scope |
| --- | --- | --- |
| Drillmaster | Says consumables do not consume an action, which is already standard behavior. | The live consumable handler and battle UI actually allow **two quick consumables per round instead of one**. The heir description and special narration still describe the old advantage. Decide whether to keep this existing distinct benefit with truthful copy or redesign it. |
| Iron Constitution | Promises 50% instead of 25% Burn/Poison wear-off, apparently conflicting with timed statuses and uncertain enemy application. | No runtime use of this Boon ID was found outside its catalog. Enemies **can** Poison the ship (including Brine Jet, Nematocyst Curtain and Serpent venom); Leviathan's release can Burn it. The shared status processor still uses probabilistic recovery for ship Burn/Poison, whereas Magma Burn on monsters has a turn counter. Reconcile this remaining mixed status model and decide the Boon's role; do not assume all effects are already timed or that the promised doubled recovery is implemented. |
| Storm-Seer | References high gales and drift damage; unclear whether this means regional hazards. | No gameplay hook for this Boon ID was found. The current trait copy alone does not establish a gale encounter or +10 HP conversion. Discuss a useful navigation/environment benefit tied to encounters that actually exist, without inventing gales to justify the old text. |
| Superstitious | Refuses obsolete Abyssal Pacts and promises immunity to absent Siren charms, confusion and fear. Blocking current Blessings could undermine normal run scaling. | The restriction exists in the old `CommuneWithShrine(abyssalPact)` branch; the current `AcceptShrineBlessing` handler does **not** check Superstitious. No current immunity implementation was found for the named effects. Distinguish this inactive legacy restriction from live Blessings; agree on a meaningful current tradeoff rather than automatically extending the prohibition to Blessings. |

- **Sources:** [trait descriptions](../packages/monstrous_core/lib/src/lore/trait_lore.dart), [trait/heir IDs and serialization](../packages/monstrous_core/lib/src/model/bloodline_trait.dart), [session handlers](../packages/monstrous_core/lib/src/session/game_session.dart), [monster status application](../packages/monstrous_core/lib/src/rules/monster_ai.dart), [status processing](../packages/monstrous_core/lib/src/rules/combat.dart), and [battle quick-item controls](../apps/monstrous_sea/lib/src/screens/battle_screen.dart).
- **Discussion / implementation scope:** Audit every trait's actual hook, frequency of usefulness, downside and description against the three-hardpoint, single-use belt, heading, blessing and regional systems. Decide which traits stay, change or are replaced; distinguish Boons from Quirks with benefits/costs the player can understand before selecting an heir. Review current and pending heirs in existing saves before changing stable trait IDs or silently reinterpreting a saved choice.
- **Constraints:** Retired mechanics and compatibility handlers are not requirements. Do not introduce charms/fear/confusion, gale encounters, old shrine pacts or a new status-duration model merely to make old descriptions true. Any such new system needs its own explicit design decision. Preserve essential blessing access unless an alternative progression path is deliberately agreed.
- **Acceptance:** Every offered trait describes an implemented, reachable and meaningful effect; the heir screen and in-run reminders agree with the engine. Test accepted effects, restrictions, status/quick-action interactions, and save/reload of active and pending heirs. No dead benefit, baseline ability presented as a unique Boon, or unimplemented immunity remains in the offered catalog.


### PT2-27 — Ironclad appears unlocked without an intentional purchase

- **Reported:** On first opening Blueprints after death/succession, Ironclad already offered **Commission** despite the player never intentionally purchasing it. The player explicitly confirmed it already showed Commission on that first visit. [Screenshot](playtests/2026-10-20/09-unexpected-ironclad-unlock.png). The suspected cause was an affordability check granting ownership without spending materials.
- **Status: verified unsafe test-write path fixed; original historical write not captured.** The earlier production purchase checks were correct, but the subsequent audit found older UI/art fixtures creating `GameController` with default autosave and no isolated storage. Those fixtures manually grant Ironclad/other blueprints and dispatch commands, allowing fixture profiles to overwrite real Windows saves. A disposable-directory reproduction confirms this writes unpaid Ironclad ownership. This is a concrete mechanism consistent with the report, though it cannot prove the exact earlier write. Production purchasing was not changed, and the player's current profile was not repaired or relocked.
- **Isolation fix:** Disable autosave in all seven affected UI test files (twelve constructors). `flutter_test_config.dart` additionally installs a disposable default storage directory for each suite's actual lifetime, including test-runner zones, so a future forgotten default controller cannot reach production saves. Explicit fixture directories take precedence; scoped async isolation is also supported. No legacy import runs for the injected default root. [Isolation regressions](../apps/monstrous_sea/test/storage_isolation_test.dart) cover the unsafe pattern, suite fallback, explicit-directory priority and scoped async behavior.
- **Correction to prior verification reporting:** Earlier blanket claims that full app test runs left production saves untouched were unsupported because these inherited fixtures were missed. The historical receipts have an explicit correction; their passing test counts do not establish storage isolation. Future verification uses the tested guard. See the [receipt](archive/README.md#later-verification-receipts).
- **Source findings:** [ProfileData.canUnlockBlueprint](../packages/monstrous_core/lib/src/persistence/profile_data.dart) only checks affordability; `unlockBlueprint` spends the catalog cost before adding ownership. The [home-port purchase handler](../packages/monstrous_core/lib/src/session/game_session.dart) calls that method; the [dialog](../apps/monstrous_sea/lib/src/screens/port_screen.dart) dispatches it on an explicit Unlock action. Ironclad currently costs 15 Sea Glass and 10 Monster Bone. No automatic affordability-based grant was found in the current production source. Saved ownership is retained on load.
- **Verification:** [New regressions](../apps/monstrous_sea/test/blueprint_purchase_test.dart) exercise actual death/succession, sufficient resources, repeated menu opening, a paid UI unlock, free commissioning, and isolated disk save/reload. The clean first-port menu retains the lock; buying deducts exactly 15/10 and repeated unlock requests do not charge twice. Existing engine blueprint tests also verify deductions. These checks do not invalidate the reported first-visit state or resolve its origin.
- **Acceptance / next evidence:** Reproduce an unintended ownership transition with the profile immediately before and after it, then fix the actual path. Merely accumulating materials, dying, choosing an heir, opening the menu, or reloading must never purchase a blueprint. Preserve legitimate old unlocks; do not retroactively charge/relock existing profiles based only on the absence of a purchase history.

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
3. **Combat balance evaluation:** Serpent dodge, ink accuracy, the 38-base-damage unavoidable Kraken release and the initial squid/tentacle profiles are approved and implemented. Review player feedback across builds/routes and later regions before further tuning; isolated bot results do not define a human win-rate target.
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
| Covenant altar / pacts | The altar banner's Material fire icon is an intentional temporary placeholder (21 October 2026), not approved final art. | Audit existing assets, then commission a custom nautical/parchment Covenant or pact icon during the art pass. Retain the banner's COMMUNE entry; the duplicate lower Covenant action has been removed. |
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

## Deferred core cleanup

**FUT-05 — Requested 21 October 2026; substantial deferred maintenance project.** Audit vestigial content and naming across `monstrous_core` after the successive gameplay revisions. This records future work, not authorization to delete every old-looking enum or helper now. Coordinate with PT2-02 (family identity), PT2-13 (Apex names), PT2-26 (heir traits) and the separate narrative integration work.

### Reported scope and initial source findings

- **Ship adjectives and identities:** [NameForge](../packages/monstrous_core/lib/src/content/names/name_forge.dart) still has Freighter/Corvette adjective pools, reused by Corsair/Clipper; Bombardier shares Ironclad's pool. [Ship content](../packages/monstrous_core/lib/src/content/ships.dart) retains older ship factories alongside the flagship/blueprint factory. Audit which names suit the current five blueprints and the one ancestral flagship, rather than perpetuating obsolete ship-selection identities. Final replacement names remain undecided.
- **Retired weapons and mechanics:** [Ship weapon generation](../packages/monstrous_core/lib/src/content/ship_weapons.dart), [monster weapon generation](../packages/monstrous_core/lib/src/content/monster_weapons.dart), [enums](../packages/monstrous_core/lib/src/model/enums.dart) and [weapon lore](../packages/monstrous_core/lib/src/lore/weapon_lore.dart) retain identities, factories, formulas and text from older systems. Inventory obsolete ship/monster weapons and distinguish them from still-used intrinsic hardpoints and monster attack implementations. Also audit rarity, weight, equip/swap/drop, AC and other compatibility references; their existence does not authorize restoring retired mechanics.
- **Titan naming inconsistency:** `NameForge` offers multiple Kraken titles, including `Ancient Leviathan`, while its World Serpent and Ancient Leviathan names are fixed. However, the actual [Kraken factory](../packages/monstrous_core/lib/src/content/monsters.dart) already defaults to `The Kraken`; the shared generator's title pool is not proof that normal Titan encounters randomize it. `generateKrakenTitle` has a direct content-test caller in the inspected source. Audit all factory/generator/custom-name paths and choose one authoritative policy for the three Titans. Avoid a Region 1 title colliding with the Region 3 Titan's identity. Preserve intentional custom/Nemesis identity where applicable.
- **Duplicated presentation sources:** Trace names, descriptions and narrative outcomes from catalogs through enums, events, session narration and app widgets. Retire or connect unused lore tables and remove stale hardcoded copies deliberately so an edit to the designated source actually reaches the player. Preserve the user's revised narrative intent; old copy is not the authority simply because a live widget still contains it.

### Suggested execution chunks and safeguards

1. Build a reachability/disposition inventory: current runtime content, supported save readers/migrations, legacy/parity-only helpers, plausible future concepts, and unused content. Check engine, app, simulator, public exports and tests; a reference in an old parity test alone does not establish a current gameplay requirement.
2. Agree on ship/Titan/Apex naming and current weapon identities, then consolidate their live sources without silently renaming historical captain/Nemesis records. A future Master Refit concept does not make an obsolete weapon an approved drop or current mount.
3. Remove demonstrably unused content in small commits. Isolate still-needed compatibility adapters from active catalogs; remove serialized IDs/fields only with an explicit migration and old-save coverage.
4. Update descriptions, comments and tests to the surviving contracts. Keep meaningful regression coverage rather than preserving obsolete behavior solely to satisfy historical tests. Check seeded RNG consumption when removing random name choices, since changing draws can alter later encounters and balance probes.

**Acceptance:** A reviewed inventory explains what was retained, removed or migrated. The current five blueprints, intrinsic weapons, monster intents and three Titan identities have authoritative live sources, with no accidental access to retired content. Existing supported profiles/voyage saves still load; current run progression, Nemesis identity and deterministic behavior remain verified. Run the affected core/app/simulator checks and documentation validation for each chunk. This initial note is not an exhaustive audit or a claim that every legacy monster weapon is unused.

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

**FUT-04 — Deferred presentation/features.** Preserve the intended memorial/peaceful-town epilogue after Shattering, the corrupted returning ship and its Covenant altar after Claiming, a possible Grand Admiralty Crest, and Ancestral Chronicles sandbox/challenge voyages. Ending choice handlers and persistent flags already exist; full cinematics, sandbox modes, atmosphere and civic scenes must be specified and delivered separately. Use [narrative canon](LORE.md#the-caldera-and-ending-choices) for the story and avoid spoiling it in onboarding.

**Implemented textual integration, 21 October 2026:** The user's rewritten Caldera outcomes now feed runtime narration and a dedicated reading screen. Pre-choice summaries explain loss of captain/ship versus the returning ship and awakened Covenant, without the old ascension claim. Acknowledgement reaches the finished hunt or heir selection; both the pending choice and resolved outcome/read state survive restart, including fixed heir offers. No reward is reapplied by acknowledgement/reload. Older completed profiles no longer lead to a dead Start menu. The Claim altar is aboard the returning ship in the captain's quarters, as in the revised canon. The cinematic memorial, town presentation and Ancestral Chronicles remain deferred. See the [verification receipt](archive/README.md#later-verification-receipts).

### Completed hunts, lineage saves and alternate fates

**FUT-06 — Plan accepted 21 October 2026; staged delivery.** A completed Shatter hunt needs a useful way out and future ways to keep playing without erasing its ending. The agreed order is:

1. **Immediate — implemented 21 October 2026:** Exit Game on the completed-hunt screen finishes saving the ending before requesting native application exit; saving or closing failures show a retryable error. Debug playtest sessions remain unsaved.
2. **Next:** Build a proper title menu with Continue, New Lineage, Settings and Exit, backed by separate lineage save slots. Each lineage owns its captains, materials, unlocks and ending. Keep completed lineages as records; starting another must not overwrite them. Ordinary death still continues the current bloodline. Specify slot selection, naming, migration of the existing single save and failure recovery before implementation.
3. **Then:** Offer “Explore the Other Fate” as a distinct branch from a dedicated pre-Caldera-choice snapshot. Preserve the completed Shatter lineage and create an independent copy where the player can Claim and pursue Covenant progression. The current resolved-ending checkpoint is not a substitute for this snapshot. Define branch ownership, rewards and repeat-branch behavior so no choice reward is applied twice to a lineage.
4. **Later, with FUT-04:** Completing Shatter unlocks Ancestral Chronicles challenges/configurable voyages framed as ancestral tales, preserving the peaceful ending. Agree on challenge rules and progression boundaries before implementation; the debug playtest launcher is development support, not delivery of this player feature.

Only the immediate exit button is in the current implementation scope. Menu/save slots, alternate-fate branching and Chronicles remain unimplemented planned work.

## Maintenance rules

- Keep the PT2 IDs stable; mark work fixed only with an implementation and relevant verification. Do not discard an unresolved observation merely because a similar historical issue once passed tests.
- Move completed task receipts into the archive when useful, while retaining links and updating canonical rules in their owning document.
- Old pricing, animation, font, icon, or disabled-button recipes are not new open requirements. Bring a still-observed problem forward as a current issue with evidence; do not reimplement completed fixes from archival imperative prose.
