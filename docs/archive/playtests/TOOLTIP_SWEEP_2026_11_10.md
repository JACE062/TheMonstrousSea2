# Tooltip sweep — 10 November 2026

The user requested a new pass over all tooltips after the keyword/handoff/spacing changes. The [source inventory](evidence/tooltip-sweep-2026-11-10/inventory.json) lists explicit tooltips, implicit icon-button hints and linked mechanic text. Earlier player screenshots and audit evidence remain unchanged in their original receipts.

## Coverage

| Tooltip family | Review and exercised presentation |
| --- | --- |
| Combat fittings and supplies | All five hulls; weapon/utility forecasts; full belts; crowded statuses; reload/disabled actions; direct mouse paths and fitting clicks. |
| Combat readouts and blessings | Detached ship/beast stats; active status badges; every power/slot/tier blessing; linked condition chains and contextual values. |
| Intent details | Compact/wide Inspect controls and nested counterplay keywords. |
| Home and vessel inspection | Blueprint Flare detail, fitting/blessing/relic/belt keywords and scrolling inside the actual inspection dialog. |
| Merchants and encounter screens | Supply cards, salvage/wreck receipts, shrine synergy/comparison text, Haven/stronghold patch-kit hints and the shared inspection presentation. |
| Navigation | Current visible chart markers/ports, all four chart controls and heading-button hints. Offscreen/covered chart targets are not claimed as hovered. |
| Small controls and debug UI | Pause/Settings/close hints, Chronicle/Belt help, selected playtest dropdown hints; existing overlay/corner and chart-latency cases supplement the real screen walk. |

The source inventory contains 37 sites across 16 files. The new screen walker opens actual current-route keyword targets, visits up to two linked descendants, checks separate card bounds and dismisses with Escape. Across its 41 cases it reads 915 linked cards and 168 native tooltip targets, including repeated contexts/text sizes. It reads real mechanic target help by long press. Native tooltip overlays are opened programmatically only for active hit-testable targets, with overlay text distinguished from identically named source labels. Browsing snapshots remain unchanged; no real profiles are loaded.

## Corrections

- Keyword cards previously used unscaled source width, so they could overlap their enlarged label. Layout-time transformed bounds now match painted targets.
- Open help previously stayed at its old position when the source scrolled. It now follows; leaving an ancestor reading viewport dismisses the branch after layout.
- A narrow strip of a neighboring status label could still steal help. A small translucent region tracks the help gap, and other mechanic anchors on the same route suppress hover activation there. It does not intercept clicks; an explicit click-through regression remains.
- Nested placement previously considered mainly horizontal room and could overlap earlier cards despite vertical space. Free-space selection now excludes every ancestor, adapts card width/scroll height and uses side/vertical space. Text sizes are retained. Both fonts exposed short-window cases; the final minimum candidate width allows the available side strip in the 800×480/130% inspection case.

These are shared presentation fixes. Gold/600 keyword styling, the existing fitting inset, contextual effect numbers, help controls and the selected mechanics remain intact.

## Verification and evidence

The initial **eight-case baseline failed all eight** against `81b20fd`: scaled targets, scroll tracking, vertical nesting and dense-label traversal at 115/130%. The final new regression file has ten cases, adding inner-viewport dismissal. The real screen walk has **41 cases**; existing input, typography and overlay checks supply the broader matrix.

**367 tooltip-focused cases pass with cached game fonts.** The **407-case offline regression run passes**, including related mechanic/dodge/shore/Chronicle tests and nine chart checks. Both fonts, 115–130%, compact portrait, short landscape and desktop sizes are represented. Analysis, formatting and documentation checks pass.

The retained probes distinguish real defects from fixture changes: translucent regions alone did not suppress underlying hover callbacks; the initial screen walker included obscured routes/inactive dropdown labels; viewport type promotion needed an explicit RenderBox cast; focused F1 tests needed to scroll clipped sources into view after offscreen dismissal was added. Short-window atmospheric and high-legibility packing failures are kept separately from final passes.

[The manifest](evidence/tooltip-sweep-2026-11-10/manifest.json) records source hashes, inventory, per-screen read counts, checks and proofs. Examples include [stacked explanations](evidence/tooltip-sweep-2026-11-10/visual/final/tip-vertical-chain-1.15.png) and [dense-label handoff](evidence/tooltip-sweep-2026-11-10/visual/final/tip-dense-handoff-1.15.png). This is a source inventory plus automated widget/render/input review, not a claim to have replayed every possible live native build and window size. Native player replay remains valuable.

A separate Windows Debug preview is built at `.dart_tool/tooltip-sweep-preview/build/windows/x64/runner/Debug/monstrous_sea.exe` and was not launched. [Correspondence](evidence/tooltip-sweep-2026-11-10/preview-correspondence.json) verifies app/config/Windows inputs, bundled assets, unchanged shared-core inputs and binary hashes. The running shared build, older previews, saves, approved artwork, audit evidence and provisional gameplay tuning remain untouched.
