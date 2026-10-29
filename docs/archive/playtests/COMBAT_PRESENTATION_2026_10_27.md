# Combat displayed-state foundation — 27 October 2026

Completed implementation receipt for the bounded first slice of [PT2-11](../../BACKLOG.md#pt2-11--combat-ui-does-not-function-as-a-readable-command-station). Current behavior belongs to [Current game](../../CURRENT_GAME.md#persistence-and-presentation); open design belongs to the [combat UI discussion](../../design/combat-ui.md).

## Delivered boundary

Flutter/Dart/Flame remains the production stack. Core still resolves commands immediately. Detached combatants shared by the HUD and Flame advance from structured outcomes during playback, keeping health, shell, barrier, limbs, effects, bearing and intent synchronized with their cues. Effect checkpoints explicitly cannot substitute their captured health/shell/limb values for missing numerical events.

New facts cover capped/modified healing, extra relic damage, consumed barrier endpoints, ordinary shell absorption, shell restoration, status/buff lifecycle and named reactive damage. Combatant identity is explicit even when names match. Ghostwake's temporary obscurity bypass does not appear as ink clearing/reapplying. Arc Discharge and Fault-Line windup breaks emit explicit disruption facts.

Readable local cues distinguish damage/healing, aggregate non-barrier defense, barrier absorption, shell changes, miss/dodge/range avoidance and status application/tick/expiry. Non-barrier reduction is labeled **DEFENSE** because it can combine armor, bracing and captain mitigation. Burn/Poison/Stun have persistent badges alongside the existing power statuses. Multiple changes at one checkpoint share a readable cue and one complete accessibility announcement. Numbers/cues replace previous feedback at the same combatant; a twelve-hit sweep retains every outcome with shorter per-hit waits. Reduced motion removes decorative bobbing, floating, fading and shaking while preserving readable state changes.

Decision controls remain frozen until playback finishes; action-dependent forecasts are suppressed during resolution. The health meter's compact threshold accounts for enlarged text, fixing an overflow found at 600 pixels and 130% text. Existing Pause, Chronicle scrolling, art recovery and terminal playback gates remain in place.

No command-station redesign, Chronicle relocation, new art/audio, spatial bearing movement, threat zones, save schema or balance changes were included. The engine-comparison fixtures were not imported into production and remain experimental evidence.

## Verification

All 577 core, 33 simulator and 322 Flutter tests passed. Core, simulator and app analysis were clean. Documentation and whitespace checks passed. The simulator suite includes its seeded 1,000-run audit; its generated report was restored to the pre-task version rather than replacing historical evidence.

The core replay oracle ignores health/shell/limbs in effect snapshots and verifies actual command endpoints across all five hulls, representative species/statuses, every consumable, Siphon/Ghostwake, Impatient/Skirmisher, Harpoon/Wake/trap chains, thermal scald and fatal outcomes. Rule tests check barrier versus other mitigation, reactive ordering, exact status tick endpoints, Static discharge stages, Calcify restoration/purge, expiry and named rider/disruption facts.

Widget regressions step the real playback queue to inspect pre-impact and post-impact HUD values, including resize and art retry during resolution, explicit identity with equal names, normal/reduced motion, every impact of a real twelve-hit sweep, status expiry and cancellation after scene removal. Existing Pause regressions cover fatal playback surviving modal and parent rebuilds.

Font-loaded widget captures use the current renderer and approved art with Georgia/system fallback and Material icons. The small controlled sequence uses synthetic HP/barrier/status facts to isolate timing; it does not describe a new monster attack or balance rule. It is shown with the Chronicle closed. These are implementation captures, not approved layout mockups or native Windows playthroughs.

Reviewed captures from the final implementation (130% text):

| Checkpoint | Evidence |
| --- | --- |
| Barrier consumed; hull still 100/100 | [Desktop absorption](../../playtests/2026-10-27/combat-barrier-1280.png) |
| Hull impact; hull now 96/100 | [Desktop damage](../../playtests/2026-10-27/combat-hull-1280.png) |
| Poison arrives; persistent badge appears | [Desktop status](../../playtests/2026-10-27/combat-status-1280.png) |
| Same hull impact at 600 pixels wide | [Compact damage](../../playtests/2026-10-27/combat-hull-600.png) |

## Player pacing follow-up

The player found the text clearer than bare numbers but still too brief to read comfortably. The [player capture](../../playtests/2026-10-27/combat-feedback-fast-player.png) records the report. The original text lifetime was 0.7 seconds with immediate fade, and the queue could replace a cue after 0.18 seconds.

Fresh text now receives a 1.4-second minimum reading interval, increasing with word count to 3.4 seconds before replacement. If unreplaced, text stays fully opaque and stationary for 3.75 seconds and fades over 0.25 seconds. Damage numbers remain solid for 2.25 seconds, with a minimum 0.8-second impact hold. First occurrences of barrage source/defense/rider wording get reading time; repeated familiar cues retain the compact cadence and do not multiply long pauses across twelve strikes. New status meanings always receive their reading interval. These remain provisional pacing values for player replay.

The new real-clock widget regression checks an applied two-effect cue after 1.2 seconds, before the next impact. The twelve-hit regression still checks every HP endpoint and bounds total scheduled playback with the added reading intervals. Timing-sensitive art/flow/belt fixtures now wait for the existing completion gate instead of assuming playback ends within three or six seconds. Gameplay rules, save behavior and layout are unchanged.

Pacing verification: app analysis was clean, and all 75 targeted playback, belt, art, flow and Pause tests passed. The [1.2-second reading-hold capture](../../playtests/2026-10-27/combat-reading-hold.png) was generated by the timed widget regression and visually checked: both effect names remain fully visible before the following impact. Earlier full-suite counts above describe the initial slice; the pacing follow-up changes presentation timing and fixture completion waits only.

## Normal fade and movement attribution follow-up

The next player replay approved the slow opening tentacle strike followed by the fast barrage cadence, but found ordinary labels sometimes lingered too long. Ordinary text now stays solid for the first half of its established reading interval (0.7 seconds for a short cue), then fades over the remaining half. Its text, background and border fade together. Ordinary numbers hold for 0.65 seconds and fade for 0.65 seconds. Queue reading holds and the accepted barrage waits are preserved; reduced motion clears without fading. This supersedes the preceding ordinary four-second lifetime.

The player also reported a Kraken retreat being described above the ship as ship movement. Range events previously had only a distance change and narration, while the scene always placed a generic closing/falling-back cue above the ship. All nine production emitters now record the mover and instigator. Helm/Ram/Rigging/Skirmisher move the ship; charge/ambush/retreat move the beast; Harpoon moves the beast at the ship's instigation; monster pulls move the ship at the beast's instigation. Playback anchors to the mover and distinguishes retreat, closing and forced pulls/pushes. Unattributed compatibility events update the bearing neutrally. No combat movement, RNG, save or sprite-position rules changed.

Eight new core regressions cover every emitter, including a Short-to-Medium retreat and both steps of an ambush. App tests cover attribution/placement, real opacity before/after the fade delay, and the unchanged 90 ms source beat for each of the eleven tentacle strikes following the readable opener.

Follow-up verification: all 26 focused core range/intent tests and 77 app playback/flow/Pause/belt/art tests passed. Core/app analysis, documentation and whitespace checks were clean. Visual checks confirm [ordinary text during its initial hold](../../playtests/2026-10-27/combat-normal-label-solid.png), [the same cue fading at 1.2 seconds](../../playtests/2026-10-27/combat-normal-label-fading.png), and [retreat feedback above the Kraken](../../playtests/2026-10-27/combat-kraken-retreat.png). These remain isolated widget captures of the production renderer; the shared Windows player binary and player saves were untouched.

## Ram and Harpoon sequencing follow-up

The player reported that Ram's movement cue followed the attack name and damage. Ram now records its launch range, closes to Short and emits that movement before the attack attempt/impact. On clarification the user explicitly kept the +25% Medium-launch charge bonus; the captured launch range preserves its damage calculation. Harpoon still attacks at the range it was launched from, then pulls. Skirmisher's late helm remains after the main action and its intrinsic movement. No barrage/fade timings or range multipliers changed.

Core regressions verify Ram charge-before-attempt-before-hit, its 25 damage from a controlled 20-base Medium charge, 20 damage with no phantom movement at Short, misses and lethal hits. Harpoon tests verify controlled 17/20/17 damage at Long/Medium/Short before pulling, with no pull at already-Short range. Existing replay tests now assert each action's ordering before late Skirmisher helm. Evasive Rigging also explicitly opens range before a damaging utility rider. Two widget regressions record the actual rendered bearing/monster-health sequence for Ram and Harpoon.

All 593 core tests and 27 focused app presentation/flow/Pause tests passed; core/app analysis and documentation/whitespace checks were clean. No player saves or shared player executable were touched.

## Faster response and independent Stun follow-up

The player reported that sweeps took too long to reach full speed, ordinary weapon damage waited until the attack name was fading, and Stun also showed Pin. The first sweep strike now retains normal reading pauses; every wait from strike two onward uses the accepted half-base cadence capped at 200 ms, including the first later defense, barrier, hull or status cue. The source beat is 90 ms from the second tentacle. This supersedes the earlier per-wording introduction holds that could repeatedly slow the sweep.

Ordinary attack names lead the next outcome by 100 ms without waiting for their visual read/fade lifetime. The labels keep their existing lifetime, so name and impact can be visible together. The real-clock widget regression verifies unchanged HP at 99 ms, damage at 100 ms, and a fully opaque weapon name at impact. Range/defense/impact ordering remains event-driven.

Stun was genuinely setting the core Pin flag through the shared interruption helper. Pinning ordnance and catastrophe interruption are now separate conditions. Stun alone denies the next movement/action and interrupts windup/release without adding Pin or halving dodge. Harpoon, Heavy Mortar, Blast Pack and Tether-Trap still apply independent Pin and can coexist with Stun. Nine core regressions cover quick Stun, normal dodge on follow-up shots/hits, movement/action denial and resumption, Kraken windup/release cancellation and legitimate pinning sources. A widget test checks the visible Stun badge, absence of Pinned, full dodge and accessibility announcement.

All 602 core tests and 81 targeted app playback/flow/Pause/belt/art tests passed. The tightened 99/100 ms boundary also passed separately; core/app analysis and documentation/whitespace checks were clean. A Sol Medium subagent implemented and checked the independent core fix, then reviewed the app pacing changes without finding a concrete regression. No player saves or shared player executable were touched. Player replay remains the pacing acceptance check; the broader layout is unchanged.

## Status row and numeric shell-break follow-up

The player reported that status badges touched the bottom of health and power effects appeared above ordinary statuses as separate columns. Each combatant now has one wrapping horizontal status row, combining both existing badge sets with an 8-pixel top gap only when effects are present. Burn deduplication, explanations and accessible labels remain intact. Icons with small corner stack counts are recorded as future direction, without generating assets or replacing text in this pass.

Shell-breaking cues formerly replaced their numeric amount with SHELL BROKEN. The cue now reads SHELL −N · BROKEN; non-breaking shell damage retains its number, and flesh damage remains its separate HP impact. This preserves the different shell multipliers and penetration mechanics without changing damage rules or combining them into a potentially misleading attack total.

All 26 focused app presentation/power-UI tests passed, including five new checks: mixed ordinary/power status placement at 1280, 600 and 360 pixels with 130% text, and actual Heavy Mortar outcomes with broken or surviving Carapace. The break case shows 10 shell damage followed by 7 flesh damage, with HP unchanged until that second impact; the non-break case shows 34 shell damage without a false −0 HP number. App analysis and documentation/whitespace checks were clean. The five new tests also passed with the installed Georgia font loaded for capture. No core rule, save or shared player executable changed.

Visually checked production-renderer widget captures: [desktop status row](../../playtests/2026-10-27/combat-status-row-1280.png), [compact status row](../../playtests/2026-10-27/combat-status-row-600.png), [numeric shell break](../../playtests/2026-10-27/combat-shell-broken-amount.png), and [following flesh impact](../../playtests/2026-10-27/combat-shell-overflow-flesh.png). These isolated test captures are implementation evidence, not a native player replay or approved redesign.

## Independent label stack and maneuver pacing follow-up

The player reported that Long → Medium helm → Short Ram felt sluggish because each movement label blocked the next. The user approved a bounded stack of up to three labels per combatant and event timing independent of each label's lifetime. Ordinary outcomes now advance in 300–400 ms; the attack-name lead stays 100 ms. The real-clock regression verifies Medium at click, Short at 300 ms, attack name at 600 ms and the controlled 25-damage impact at 700 ms, with both movement labels and the Ram name still visible. It preserves the approved Medium-launch charge bonus and causal state order.

Measured cartouches place newest nearest the actor and older entries above, with independent fade/expiry, per-side capacity and compact-space eviction. The stack retains surviving labels across quick/main commands; a new command no longer truncates their lifetime. Playback finishes after its final beat while cues can remain visible. The existing terminal-combat delay, input gate, readable opening sweep strike and fast waits from strike two are preserved. Stable space inside the arena accommodates feedback without changing the control layout. Compact arena reservation uses only height beyond the art allowance; it does not halve an already-small illustration area. Fewer than three labels may fit when cues wrap.

A Sol Medium read-only review caught two issues before completion: command-entry cleanup cut short quick-action labels, and Flame can cancel an unmounted add without calling onRemove. Both were corrected. Synchronous, idempotent dismissal removes stack ownership and disposes cached text layout on eviction/expiry, with external-removal fallback and scene cleanup. Four new widget regressions cover the 700 ms maneuver/Ram sequence, bounded/reflowed/independently expiring rows in normal and reduced motion, and successive command retention plus multiple additions before the first Flame mount. Additional geometry checks cover the actual twelve-hit Kraken and compact stacks. The prior long reading-hold regression now verifies impact and completion occur while the previous label is still fading.

Verification: 23 presentation, 33 raster and 41 other targeted flow/Pause/belt/art-recovery/power-UI tests passed. The 56 presentation/raster tests were rechecked after correcting compact art reservation; existing actual-ink and art-bound checks pass unchanged. App analysis, documentation and whitespace checks were clean. Five focused scenarios also passed with Georgia loaded for visual review. No core rules, player saves or shared Windows executable were changed.

Reviewed implementation captures: [700 ms Ram impact with both movement labels](../../playtests/2026-10-27/combat-ram-feedback-stack.png), [desktop stack](../../playtests/2026-10-27/combat-feedback-stack-desktop.png), [compact stack](../../playtests/2026-10-27/combat-feedback-stack-compact.png), and [Kraken barrage stack](../../playtests/2026-10-27/combat-kraken-feedback-stack.png). These are isolated production-renderer widget checkpoints; the controlled stack fixture includes synthetic events to exercise bounds/lifetime, while the maneuver and sweep use actual commands. Player replay remains the pacing acceptance check.

## Remaining evaluation

Player replay still needs to assess comprehension, timing and complex builds with the Chronicle closed. Automated endpoints and keyframes do not establish that a full turn is easy to follow in motion. Final feedback vocabulary and the broader layout remain open. Native player save directories were not accessed; app fixtures use disabled autosave and the suite's disposable storage. The shared Windows player executable/bundle was not rebuilt or launched.
