# Tooltip hover follow-up — 10 November 2026

The player liked linked keyword help but reported that the close icons looked out of place, keywords were difficult to recognize as help targets, Dodge help named unrelated fittings, and fitting tooltips had awkward hover transitions. One utility tooltip stayed open after the pointer left, although the player could not reproduce that spontaneous sequence. The [secondary-help screenshot](evidence/tooltip-followup-2026-11-10/player/01-secondary-help.png) and [fitting screenshot](evidence/tooltip-followup-2026-11-10/player/02-fitting-help.png) are retained unchanged.

## Changes

- Keyword/action cards use the existing parchment, ink border and shadow without visible close icons. Headers retain the established typography. Linked terms use heavier crimson text, a dotted underline and a help cursor.
- Monster Dodge help reads: “Current dodge chance. Attack accuracy is a separate roll.” Pin and Spotter Flare are no longer generic examples on every build; their own status/fitting explanations remain intact.
- Mouse-opened help follows pointer presence across the anchor, card and descendants. Focus left inside a hovered card no longer latches it. Mouse activation of an already hovered keyword keeps the help readable instead of toggling it off or making it persistent.
- Each parent/route keeps one current branch. Entering another fitting or linked sibling replaces its predecessor immediately. Outside taps dismiss the family. Ancestor exits use one existing 250 ms grace period; child teardown no longer restarts an ancestor timer and stretches a multi-card exit into several delays.
- F1, keyboard/semantic activation and touch long press retain a focused reading scope. Escape closes the front card before Pause and restores surviving focus; outside tap and the semantic Dismiss action remain available. Help does not intercept normal fitting clicks or dispatch an action through F1/long press.

There is no combat, evasion, effect, save, progression, artwork or numerical tuning change. The ship dodge cap and existing contextual effect values are retained.

## Reproduction and verification

An isolated package copied the pre-change `mechanic_text.dart` and `combat_stats.dart` from base commit `fd1b575` and ran the corrected [seven-case reproduction fixture](evidence/tooltip-followup-2026-11-10/baseline-fixture.dart.txt). All seven failed before the changes: the requested icon/copy changes, immediate fitting replacement and retained-focus mouse-exit behavior. The focus reproduction deliberately retains focus inside a hovered linked card; it establishes a problematic state the old code allowed, not the player's exact unrecorded native input sequence. The main working tree and all player saves remained untouched by the baseline package.

The focused fixture now has **24 cases** at compact/desktop widths. It covers mouse click with retained focus, fitting replacement, hover-gap grace, staying inside the card, ten rapid fitting switches, nested sibling replacement and a whole-chain exit, mouse long press, normal fitting clicks, touch reading/outside dismissal, F1/Tab/Enter/Escape, F1 takeover of existing hover help, semantic Dismiss availability, icon absence, keyword style and a real Clipper-context monster Dodge target. Synthetic action counters prove that browsing/long press/F1 invokes no fitting action, while a normal click invokes exactly one.

**The focused 24 cases and 264 existing overlay/layout cases pass with game fonts: 288 distinct cases.** The layout run was captured with the initial 21 focused cases (285 total); the final 24-case run adds F1 takeover and deeper sibling checks against the same final implementation. The **319-case offline regression run passes**, including those 24 cases, all 264 overlay cases and 31 existing mechanic, dodge, shore and Chronicle cases. Bounds, 115–130% text, both fonts, current-route Escape precedence, context values and touch/disposal behavior remain covered. Analysis, formatting and documentation checks pass.

Earlier probes remain explicit: fixture compile/scope corrections are separate from behavior failures; a parent-timer probe caught stacked close delays; the semantics fixture needed to release its test handle before end-of-test verification; the status-hover helper was updated to leave the card rather than click the removed icon. Assertions for complete text, help bounds and input behavior remain.

## Evidence and limits

[The manifest](evidence/tooltip-followup-2026-11-10/manifest.json) records source hashes, baseline-package correspondence, checks and staged proofs. Examples: [icon-free linked cards](evidence/tooltip-followup-2026-11-10/visual/interaction-final/tip-mouse-link-1280.0.png) and [compact linked keyword](evidence/tooltip-followup-2026-11-10/visual/interaction-final/tip-keyword-360.0.png). Native player replay remains useful for the originally intermittent utility-tooltip report; the automated tests cover the identified focus, timer and sibling-transition cases.

A fresh Windows Debug preview is built at `.dart_tool/tooltip-followup-preview/build/windows/x64/runner/Debug/monstrous_sea.exe` and was not launched. [Preview correspondence](evidence/tooltip-followup-2026-11-10/preview-correspondence.json) verifies app/config/Windows source, bundled assets, unchanged shared-core inputs and build hashes. Earlier previews, audit evidence, approved artwork and player saves remain intact.
