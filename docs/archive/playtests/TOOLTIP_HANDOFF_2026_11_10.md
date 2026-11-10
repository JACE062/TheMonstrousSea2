# Tooltip handoff follow-up — 10 November 2026

The player rejected dotted keyword underlines and reported that moving left from Signature toward its help card triggered Broadside help instead. The [original screenshot](evidence/tooltip-handoff-2026-11-10/player/01-signature-handoff.png) is preserved unchanged.

## Changes and reproduction

The existing eight-pixel tooltip gap exceeds the six-pixel gap between fitting controls, exposing a thin strip of the neighboring button. Its hover handler previously replaced the Signature card immediately, before the pointer reached the card.

Battle weapon/utility fittings now start mouse help only inside a 12 logical-pixel margin, capped at a quarter of each target dimension. A pointer crossing the exposed edge does not open neighboring help; moving deliberately into that fitting's interior still does. Once open, help retains its full anchor and existing grace period. Button clicks, F1, long press, keyword targets and ordinary stat help keep their full areas. Placement and action behavior are unchanged.

Keywords retain bold crimson text and the help cursor without any underline. The inner keyword link now explicitly uses the help cursor as well.

## Verification

Before production changes, all **nine** initial fixture cases failed against base commit `7843730`: four direct-path cases switched to Broadside, four edge-hover cases opened help, and the style case found an underline. The first inset implementation passed the direct paths; two deliberate-switch assertions then exposed a fixture point exactly on the popup boundary at compact width. Moving that test point into the exposed Broadside interior corrected the fixture. Both logs remain separate from final results.

The final **14 focused cases pass with cached game fonts** at 800×480 and 1280×900, each at 115% and 130% text. They traverse the exposed strip to the Signature card and the edge of Carapace, deliberately switch fittings afterward, verify full-size click areas, F1/long-press activation at the edge, retained keyword styling/cursor and full stat hover areas. Synthetic action counters distinguish reading from a real click. Representative proofs: [desktop linked help](evidence/tooltip-handoff-2026-11-10/visual/final/tip-carapace-1280-1.15.png), [compact linked help](evidence/tooltip-handoff-2026-11-10/visual/final/tip-carapace-800-1.15.png).

The **333-case offline regression run passes**, including the 14 focused cases, the previous 24 interaction cases, 264 overlay/layout cases and 31 existing mechanic, dodge, shore and Chronicle cases. Analysis, formatting and documentation checks pass. The fixture recreates fitting spacing and pointer travel; it is not a native recording of every combat configuration. Player replay remains useful.

## Preservation and preview

The [manifest](evidence/tooltip-handoff-2026-11-10/manifest.json) records source hashes, checks and staged captures. No combat values, shared-core code, save schema, player saves, artwork or tuning changed. Earlier audit evidence and preview bundles remain intact.

A fresh Windows Debug preview is built at `.dart_tool/tooltip-handoff-preview/build/windows/x64/runner/Debug/monstrous_sea.exe` and was not launched. [Correspondence](evidence/tooltip-handoff-2026-11-10/preview-correspondence.json) records matching app/config/Windows inputs, bundled assets, unchanged core inputs and build hashes.
