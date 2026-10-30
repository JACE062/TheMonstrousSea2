# Combat UI design discussion

Recorded 26 October 2026. Supporting design notes for [PT2-11](../BACKLOG.md#pt2-11--combat-ui-does-not-function-as-a-readable-command-station).

## Status and scope

Terminology selected 29 October 2026: **Ship Fittings** replaces the player-facing Hardpoint label; Standard's utility is **Gun-Deck Bracing**, framed as built-in hull/gun-deck braces operated by the crew. Rules and internal save identifiers stay unchanged. Earlier screenshots and receipts retain the wording they originally showed.

This document captures the user's direction, selected implementation trials and unresolved concepts. It is not a final visual specification. PT2-11 owns work status; [Current game](../CURRENT_GAME.md#combat-resolution-and-monster-behavior) owns gameplay rules. No combat tuning, new targeting rules, save changes or replacement entity art are approved here.

Discuss the alternatives and agree on a scoped next step before producing further mockups or implementing it. The earlier Compact forecast / Threat panel mockups were not approved as the overall menu design; carousel selections were not design approval. The useful element retained from them is showing accuracy and damage percentages on actions.

On 27 October 2026 the user approved a bounded first implementation: shared event-by-event displayed state and the outcome facts/minimum local feedback needed to explain it, within the current layout. That foundation is now implemented; [PT2-11](../BACKLOG.md#pt2-11--combat-ui-does-not-function-as-a-readable-command-station) owns its status and player replay. This does not approve the broader concepts below or establish a final feedback vocabulary. Flutter/Dart/Flame is retained after the bounded engine comparison; its fixtures remain experimental evidence.

On 28 October the user approved the next command-station slice and selected **two weapon cards side by side with a utility row beneath**. The implemented trial retains the upper HUD, uses a 40/60 helm/actions split where space permits, moves intent essentials into a lookout with deliberate Inspect, and opens the Chronicle as a modal. Narrow windows stack helm above actions and keep a compact lookout above the scrolling commands; Pause and Chronicle remain fixed. This is ready for player review, not approval of spatial movement, threat zones, status icons, new backgrounds or a final visual style.

The 29 October player review approves the modal Chronicle and finds the lookout informative, while its styling remains undecided. Requested refinements are implemented: larger helm choices use the available panel width; Broadside, Signature and Utility have consistent headings; weapon buttons align with blessings hanging beneath; the belt shares the dock's bottom edge with Pause/Chronicle. Compact/short windows use horizontal belt scrolling. Inspect now matches the squared parchment modal treatment, removes the generic cross-blueprint paragraph and limits extra movement notes to the current ship/trait. Forecast and counterplay remain; defense caveats require a damage estimate and sweep-specific guidance stays with sweeps. Further player review is pending.

## Problem and intended experience

The original report described having to read the Chronicle before deciding what to do next because brief flashes and floating damage numbers did not explain a complete turn clearly enough. A turn can contain five or more movement, attack and effect events, but the embedded Chronicle showed only two or three entries while consuming roughly a quarter of the screen's height. The lower controls were consequently crowded: some were too shallow, while others stretched excessively across unused width. The displayed-state and command-station trials address these problems; player replay still determines their success.

The desired experience is commanding a ship in a battle that the player can follow as it happens. Slay the Spire is the user's experiential reference: attacks, feedback and visible state communicate consequences without routinely reading an action history. It is a reference for clarity, not a requirement to copy its visual style or mechanics.

Replacing the Chronicle with a last-turn text summary would reproduce much of the same reading friction. A permanent summary strip or written result beside each combatant is not the selected solution. Damage/effect communication needs its own careful design work before the broader menu is rearranged.

## Direction established in discussion

| Area | User direction | Still unresolved |
| --- | --- | --- |
| Upper scene | Mainly retain the existing health bars and ship/monster information. | How statuses, intent and movement fit around that information. |
| Combat feedback | Make damage, avoidance and effects understandable during resolution, with visible ongoing state. | Visual vocabulary, placement, sequencing, timing and accessibility. |
| Lower controls | Implemented trial: helm on the left and fittings/consumables on the right at 40/60; stack on narrow windows. | Player review of proportions and scrolling. |
| Fitting layout | User selected two weapon cards side by side with a utility row beneath; implemented. | Readability with long names, blessings and expanded belts. |
| Helm theming | Consider a static wheel icon or controls around a wheel to evoke commanding a ship. | Exact arrangement; no spinning/rotating wheel interaction is intended. |
| Monster intent | Implemented trial: a side lookout on large windows, compact fixed strip above commands otherwise; Inspect holds detailed mechanics. | Player review of information hierarchy and compact scrolling. |
| Chronicle | Implemented as an intentionally opened modal beside Pause, with remembered reading position during the battle. | Further logbook styling or round grouping. Its normal role is occasional reference. |
| Spatial range | Explore changing the distance between ship and monster illustrations with Short/Medium/Long bearing. | Feasibility, movement responsibility, animation and visual tradeoffs. |
| Threat telegraph | Red affected-area indicators might complement spatial range. | An exploratory concept requiring separate discussion, not an approved feature. |

## 1. Damage and effect communication

### Questions to solve first

- Can the player see who acted, what was affected and what changed while it happens?
- Are direct damage, damage over time, healing, shell loss, barriers and other defenses distinguishable?
- Can the player distinguish a missed attack, a dodge, damage absorbed and an attack avoided through range?
- Are important consequences such as severed tentacles, Pin, Stun, obscurity and disrupted windups apparent without opening history?
- Does the visible health/status state change at the corresponding impact rather than revealing the entire resolved turn before playback explains it?

These are presentation questions about existing rules. Numeric feedback remains useful; the aim is to make numbers understandable through context, rather than replace them with text narration or make every event a large floating message.

The 27 October status follow-up uses a padded horizontal wrapping row beneath health for existing text badges. The user wants status icons with small corner stack counts considered in a later pass; retain that direction without treating an icon inventory, artwork or exact icon treatment as implemented. Shell and flesh feedback currently retain separate numeric amounts, including the shell amount on a breaking hit.

The user subsequently approved a bounded trial of up to three local feedback labels per combatant, with independent visibility lifetimes and shorter ordinary event beats. This addresses maneuver/charge sequences waiting for each label to disappear. Newest cues sit nearest the actor, with older cues above; compact space may reduce the visible count. This implementation is provisional for player pacing review. The command layout was approved separately on 28 October.

### Candidate tools, not yet selected

- Effects located at the affected ship or monster, with an identifiable source-to-target relationship where useful.
- Readable health-bar changes synchronized to impacts, with a brief damage trail or equivalent visual distinction to investigate.
- Persistent status icons near the relevant combatant or health information, showing existing stacks/duration where meaningful; deliberate inspection explains unfamiliar icons.
- Distinct arrival, triggering and expiration feedback for statuses. An icon's quiet presence alone does not explain that an effect just activated.
- Different impact/defense cues, supported by sound without requiring sound to understand the outcome.
- Deliberate sequencing and grouping for chained effects, so attacks and their riders remain causally connected.

### Tradeoffs to evaluate

Persistent icons can reduce reading, but a dense wall of unexplained symbols would create a different comprehension problem. Avoid conveying distinctions through color alone. Text size, reduced motion, keyboard access and muted play must remain viable.

Multi-hit attacks are a special case. Twelve tentacle strikes cannot become twelve overlapping unreadable numbers, but combining everything into a single net loss can conceal valuable armor/barrier effects and individual avoidance. Decide how to communicate a barrage and its mitigation without excessive playback time or a mandatory textual recap.

Reactive blessings, healing followed by damage, backfire and status ticks also need explicit review. Net health change alone loses these causes. The full explanation may remain available in the optional logbook, but ordinary comprehension should come from the battle presentation.

No exact animation lengths, status icon inventory, SFX assets or feedback design are selected yet.

## 2. Helm and action layout

Explore a bottom command area with helm/maneuver decisions on the left and fittings plus consumables on the right. The right side also faces toward the monster in the existing composition. Reclaiming the embedded Chronicle's space should provide useful control height instead of simply making buttons wider.

The alternatives considered before selection were:

| Candidate | Potential benefit | Risk to evaluate |
| --- | --- | --- |
| Three stacked fitting actions | Consistent rows, space for long names and readable action statistics. | Total height alongside utility details, trait stages and the expanded belt. |
| Two weapon cards plus a utility row | Distinguishes offensive choices from supporting orders. | Long names or additional effects may crowd the weapon cards at narrow widths. |

The user selected the second arrangement. The implementation uses a static compass symbol and labeled helm choices, rather than generating a wheel asset. Both weapon cards remain side by side; utility sits below and the belt is pinned in the bottom footer. The command area scrolls when enlarged text or limited height cannot fit all controls. Review captures cover all five hulls, long names, partial blessings, cooldowns, an expanded belt and 115–130% text; they are implementation evidence, not final layout approval.

Further player review on 29 October accepts the larger helm commands as an improvement but still finds their appearance drab. A ship's wheel/captain's helm motif is the next visual direction to explore. The functional buttons are committed as a checkpoint; their appearance remains provisional. Lookout and bottom consumables receive positive feedback. Recording this direction does not start art generation or a new layout implementation.

Both should expose accuracy and damage effectiveness where meaningful. Clarify what the damage percentage measures, rather than imply that a range multiplier is final damage against the target. Accuracy and monster dodge are separate existing checks; labels must not present accuracy as the final chance to deal damage. Use `%`, not `pp`.

A wheel may be decorative or organize farther/same/closer controls around its left/top/right positions. Keep clear labels and selection feedback; do not require dragging, spinning or interpreting wheel rotation. Evaluate whether placement communicates range rather than suggesting a separate directional steering system.

The trial's left panel holds current/pending bearing, helm choices and their timing, including Skirmisher and Impatient restrictions. Intent resides in the lookout. The amount of empty helm space and compact command scrolling remain player-review questions.

## 3. Lookout-themed intent and forecasts

Explore a small component on the right side of, or in the background area behind, the monster. The side margins are currently underused. A spyglass icon and restrained lookout-callout styling could connect mechanical information to the captain's perspective.

Keep critical intent information legible and visually separate from the monster art; "behind" does not mean obscured by the illustration. Determine placement with large Titans, changing combatant distance, compact windows and enlarged text before committing.

The implemented hierarchy keeps the intended action, threatened ranges, movement/windup timing and a short helm forecast in the lookout. Inspect opens a scrollable modal containing the description, range stages, damage math, mitigation caveats and counterplay. Action-driven movement makes the helm-only forecast explicitly conditional; the relevant action tooltip provides its response forecast. Forecasts are withheld during playback. Inspection shows the live tentacle count and base sweep damage without filling the persistent strip with those calculations.

Forecasts must respect current mechanics:

- The firing range, range when the monster attacks and final range after recoil can differ.
- Ram, Harpoon and Evasive Rigging can change the outcome of a helm-only forecast. Ram closes before impact while retaining its accepted Medium-launch charge bonus; Harpoon hits using its launch range before pulling.
- Skirmisher resolves its committed helm after its main action and intrinsic movement.
- Hit-dependent interruption or Pin must not be promised as certain before the attack resolves.
- Impatient can act through Utility and a weapon before the response, then has a fitting-only recovery restriction; helm, belt and Wait & Reload remain legal. The pass grants no evasion and appears only for recovery or when no fitting action is usable; Skirmisher alone does not expose it.

These are design constraints, not approval to alter the turn sequence or add an action-confirmation step.

## 4. Chronicle as an optional logbook

The Chronicle now opens in a modal beside Pause instead of inserting a large panel into the live layout. It retains the existing attributed entries while the combat screen communicates normal play without requiring frequent visits.

It initially follows the latest entries. Manual history reading and the follow-latest choice survive closing and reopening within the same battle; **Latest Messages** returns to live updates. A new battle starts at the latest entries. The current-voyage scope and session-only history remain unchanged. Round grouping and richer logbook styling remain open. Do not introduce persistent combat archives or alter save behavior as an incidental UI change.

Opening the modal blocks new gameplay input while existing playback continues. Close/Escape dismisses it before Pause and restores surviving prior focus. Moving the log is not a substitute for delivering understandable feedback first.

## 5. Bearing represented through distance

Explore making Short, Medium and Long visually distinct through the distance between the combatants, rather than leaving the illustrations at a fixed separation while labels describe movement.

This remains a categorical three-band combat system. Pixel distance should communicate those bands; it must not imply new continuous range, free positioning or timing-based dodging.

Questions for a focused feasibility discussion:

- Does the ship move, the monster move, or both? How are helm movement, charges, pulls and recoil distinguished?
- What positions keep the approved art, health information and lookout component readable without overlap, especially for Titans?
- How are committed movement and previewed movement distinguished? Moving the real sprite on hover could falsely imply that a choice already happened.
- Can simple translation or restrained wake effects provide the intended feeling without new entity animation assets?
- How should reduced motion preserve a clear band change?
- Does frequent movement make the scene harder to track or cause intent/status information to jump around?

More animation is not automatically better. Evaluate the clarity and immersion gained against implementation effort, visual clutter and playback time before choosing a solution.

## 6. Optional affected-area telegraphs

Red threat zones could eventually connect enemy intent with the spatial scene. This is more speculative than moving the illustrations and should be evaluated separately.

The display must explain categorical threatened ranges rather than suggest physical hitboxes that the rules do not use. Consider when the zone appears, whether it represents the current or predicted strike position, how it changes with monster movement/interruption and how all-range attacks differ from ordinary attacks. Color needs supporting shapes/labels or other cues.

Do not add this merely because sprite movement is implemented; movement and threat zones can be accepted or rejected independently.

## Smaller discussion and implementation scopes

The following breakdown separates delivered trials from later proposals. Future unresolved portions still need agreement.

| Chunk | Discussion output before implementation | Dependency / limit |
| --- | --- | --- |
| A. Feedback vocabulary | Agree how hits, avoidance, defenses and health changes are communicated through representative turn sequences. | First priority; can be evaluated within the current layout. |
| B. Status lifecycle and complex effects | Agree icon placement, application/trigger/expiry cues and treatment of barrages/chained effects. | Build on A; prioritize clarity over adding effects. |
| C. Lookout and intent inspection | Agree persistent intent essentials, detailed inspection and action-aware forecasts. | Coordinate with status placement and future spatial movement. |
| D. Command layout alternatives | Compare 40/60-style split, both fitting arrangements, static wheel and belt capacity. | Needs actual space requirements from A–C; retain the liked upper HUD. |
| E. Modal Chronicle | Design the optional logbook and interaction behavior. | Remove the embedded dependency only when replacement feedback is sufficient. |
| F. Spatial bearing feasibility | Evaluate band positions, movement ordering, art overlap and animation cost in isolation. | Can be investigated separately; no range-rule changes. |
| G. Threat-zone exploration | Decide whether spatial telegraphs improve understanding enough to justify the work. | Optional; informed by C and F, not required by either. |

A's displayed-state foundation and bounded portions of B are implemented. The 28 October trial implements C, the selected arrangement in D and modal behavior in E. Final feedback styling, status icons, further command-layout refinement, F and G remain open or deferred as stated above.

Before declaring a solution successful, evaluate ordinary hits/misses/dodges, armor/barriers, multi-hit sweeps, damage-over-time and healing, a windup/disruption/release, action-driven movement/recoil and both Impatient/Skirmisher turn flows. Include compact layouts, large Titans, enlarged text, muted audio and reduced motion. The central player-facing check is whether they can follow meaningful consequences and make their next decision without routinely opening the Chronicle or reading a replacement summary.
