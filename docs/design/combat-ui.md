# Combat UI design discussion

Recorded 26 October 2026. Supporting design notes for [PT2-11](../BACKLOG.md#pt2-11--combat-ui-does-not-function-as-a-readable-command-station).

## Status and scope

This document captures the user's direction, candidate concepts and unresolved decisions. It is a discussion record, not a final layout or an implementation brief. PT2-11 owns work status; [Current game](../CURRENT_GAME.md#combat-resolution-and-monster-behavior) owns gameplay rules. No combat tuning, new targeting rules, save changes or replacement entity art are approved here.

Discuss the alternatives and agree on a scoped next step before producing further mockups or implementing it. The earlier Compact forecast / Threat panel mockups were not approved as the overall menu design; carousel selections were not design approval. The useful element retained from them is showing accuracy and damage percentages on actions.

On 27 October 2026 the user approved a bounded first implementation: shared event-by-event displayed state and the outcome facts/minimum local feedback needed to explain it, within the current layout. That foundation is now implemented; [PT2-11](../BACKLOG.md#pt2-11--combat-ui-does-not-function-as-a-readable-command-station) owns its status and player replay. This does not approve the broader concepts below or establish a final feedback vocabulary. Flutter/Dart/Flame is retained after the bounded engine comparison; its fixtures remain experimental evidence.

## Problem and intended experience

The player currently has to read the Chronicle before deciding what to do next because brief flashes and floating damage numbers do not explain a complete turn clearly enough. A turn can contain five or more movement, attack and effect events, but the embedded Chronicle shows only two or three entries while consuming roughly a quarter of the screen's height. The lower controls are consequently crowded: some are too shallow, while others stretch excessively across unused width.

The desired experience is commanding a ship in a battle that the player can follow as it happens. Slay the Spire is the user's experiential reference: attacks, feedback and visible state communicate consequences without routinely reading an action history. It is a reference for clarity, not a requirement to copy its visual style or mechanics.

Replacing the Chronicle with a last-turn text summary would reproduce much of the same reading friction. A permanent summary strip or written result beside each combatant is not the selected solution. Damage/effect communication needs its own careful design work before the broader menu is rearranged.

## Direction established in discussion

| Area | User direction | Still unresolved |
| --- | --- | --- |
| Upper scene | Mainly retain the existing health bars and ship/monster information. | How statuses, intent and movement fit around that information. |
| Combat feedback | Make damage, avoidance and effects understandable during resolution, with visible ongoing state. | Visual vocabulary, placement, sequencing, timing and accessibility. |
| Lower controls | Explore helm on the left and hardpoints/consumables on the right. A 40/60 split is a plausible starting point. | Proportions depend on actual maneuver/monster information and available space. |
| Hardpoint layout | Evaluate both three stacked actions and two weapon cards with a utility row. | Neither layout is selected. |
| Helm theming | Consider a static wheel icon or controls around a wheel to evoke commanding a ship. | Exact arrangement; no spinning/rotating wheel interaction is intended. |
| Monster intent | Consider a small lookout-themed component to the monster's right, using underused side space. | Placement, content hierarchy and behavior at compact widths. |
| Chronicle | If retained, make it an intentionally opened logbook-like modal, comparable to Pause, rather than an embedded panel that takes space from combat. | Modal layout and detailed navigation. Its normal role is occasional reference. |
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

The user subsequently approved a bounded trial of up to three local feedback labels per combatant, with independent visibility lifetimes and shorter ordinary event beats. This addresses maneuver/charge sequences waiting for each label to disappear. Newest cues sit nearest the actor, with older cues above; compact space may reduce the visible count. This implementation is provisional for player pacing review and does not approve the broader command layout below.

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

Explore a bottom command area with helm/maneuver decisions on the left and hardpoints plus consumables on the right. The right side also faces toward the monster in the existing composition. Reclaiming the embedded Chronicle's space should provide useful control height instead of simply making buttons wider.

Compare these alternatives at realistic window sizes and 115–130% text:

| Candidate | Potential benefit | Risk to evaluate |
| --- | --- | --- |
| Three stacked hardpoint actions | Consistent rows, space for long names and readable action statistics. | Total height alongside utility details, trait stages and the expanded belt. |
| Two weapon cards plus a utility row | Distinguishes offensive choices from supporting orders. | Long names or additional effects may crowd the weapon cards at narrow widths. |

Both should expose accuracy and damage effectiveness where meaningful. Clarify what the damage percentage measures, rather than imply that a range multiplier is final damage against the target. Accuracy and monster dodge are separate existing checks; labels must not present accuracy as the final chance to deal damage. Use `%`, not `pp`.

A wheel may be decorative or organize farther/same/closer controls around its left/top/right positions. Keep clear labels and selection feedback; do not require dragging, spinning or interpreting wheel rotation. Evaluate whether placement communicates range rather than suggesting a separate directional steering system.

The left panel's information budget is open. Current bearing, helm orders and the consequence of selected movement belong in the discussion, but monster intent need not all be squeezed there if the lookout component works better beside the monster.

## 3. Lookout-themed intent and forecasts

Explore a small component on the right side of, or in the background area behind, the monster. The side margins are currently underused. A spyglass icon and restrained lookout-callout styling could connect mechanical information to the captain's perspective.

Keep critical intent information legible and visually separate from the monster art; "behind" does not mean obscured by the illustration. Determine placement with large Titans, changing combatant distance, compact windows and enlarged text before committing.

Discuss a hierarchy that separates the intended action, threatened ranges and movement/windup timing from detailed damage math, mitigation caveats and counterplay. The long sweep and windup tooltips are evidence that these details should not all occupy one inline sentence. The deliberate inspection method remains open.

Forecasts must respect current mechanics:

- The firing range, range when the monster attacks and final range after recoil can differ.
- Ram, Harpoon and Evasive Rigging can change the outcome of a helm-only forecast. Ram closes before impact while retaining its accepted Medium-launch charge bonus; Harpoon hits using its launch range before pulling.
- Skirmisher resolves its committed helm after its main action and intrinsic movement.
- Hit-dependent interruption or Pin must not be promised as certain before the attack resolves.
- Impatient can act through Utility and a weapon before the response, then has a hardpoint-only recovery restriction; helm, belt and Brace remain legal.

These are design constraints, not approval to alter the turn sequence or add an action-confirmation step.

## 4. Chronicle as an optional logbook

If the Chronicle is retained, open it in a modal instead of inserting a large panel into the live layout. It can contain the detailed action descriptions with logbook aesthetics, while the combat screen communicates normal play without requiring frequent visits.

Round grouping, readable full-turn review, scrolling and return to recent entries are design questions for that modal. Preserve the existing current-voyage scope and intentional history reading. Do not introduce persistent combat archives or alter save behavior as an incidental UI change.

The design must account for playback/input handling when opened and for keyboard focus/Escape behavior. Moving the log is not a substitute for delivering understandable feedback first.

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

The following is a proposed breakdown for later agreement. It does not authorize starting any chunk now.

| Chunk | Discussion output before implementation | Dependency / limit |
| --- | --- | --- |
| A. Feedback vocabulary | Agree how hits, avoidance, defenses and health changes are communicated through representative turn sequences. | First priority; can be evaluated within the current layout. |
| B. Status lifecycle and complex effects | Agree icon placement, application/trigger/expiry cues and treatment of barrages/chained effects. | Build on A; prioritize clarity over adding effects. |
| C. Lookout and intent inspection | Agree persistent intent essentials, detailed inspection and action-aware forecasts. | Coordinate with status placement and future spatial movement. |
| D. Command layout alternatives | Compare 40/60-style split, both hardpoint arrangements, static wheel and belt capacity. | Needs actual space requirements from A–C; retain the liked upper HUD. |
| E. Modal Chronicle | Design the optional logbook and interaction behavior. | Remove the embedded dependency only when replacement feedback is sufficient. |
| F. Spatial bearing feasibility | Evaluate band positions, movement ordering, art overlap and animation cost in isolation. | Can be investigated separately; no range-rule changes. |
| G. Threat-zone exploration | Decide whether spatial telegraphs improve understanding enough to justify the work. | Optional; informed by C and F, not required by either. |

Before declaring a solution successful, evaluate ordinary hits/misses/dodges, armor/barriers, multi-hit sweeps, damage-over-time and healing, a windup/disruption/release, action-driven movement/recoil and both Impatient/Skirmisher turn flows. Include compact layouts, large Titans, enlarged text, muted audio and reduced motion. The central player-facing check is whether they can follow meaningful consequences and make their next decision without routinely opening the Chronicle or reading a replacement summary.
