# Six copy clarifications — 6 November 2026

Implemented the user's answers to C02, C17, C28, C29, C31 and C35. The [current review](../../design/player-copy-review.md) now records all 36 delivered selections; C28 remains working prose for further wordsmithing.

- Removed the wind caption entirely; the captain's goal needs no extra onward-travel explanation.
- Wreck recovery warns “A fight is likely; an Apex may be lurking.” The uncertain-wreck introduction offers a quick haul versus lingering to salvage the wreck in full. It no longer suggests forfeiting some of the loot. The existing alternative quick/deep settlements and their numeric bundles are unchanged.
- The working first-captain line is “Set your range, fire a volley, and pray to make it home someday. The port has waited generations for a captain’s return.” The authored prologue/endings remain unchanged.
- Nemesis wording follows the user's victory-linked growth sentence. Saved levels and growth rules are unchanged.
- The lineage menu says “Each lineage is its own save.”
- Belt Help uses the user's short one-per-turn wording. Drillmaster instead displays its existing two-item limit; reset guidance and the live counter remain, using “turn.” No quick-item rule or boon changed.

## Verification

**53 focused app checks passed**, covering ordinary/Drillmaster quotas, helm, wreck/loot presentation, death/Nemesis, save menus and combat panels. App analysis is clean. **17 font-loaded navigation checks** and **10 isolated font-loaded belt checks** passed. Representative wide/compact chart and Belt Help captures were inspected. Existing test expectations were updated for the new wording; no new copy-mirroring tests were added. Full app/core/simulator suites and balance comparisons were not repeated for this six-passage presentation change.

The Windows Debug build succeeded in `.dart_tool/copy-followup-preview/`. Exact app sources/assets and dependency lock are verified. Its belt fixture is copied from the app test and uses unsaved controllers; captures go to this new preview's build directory, preserving older belt captures. The agent compiled but did not launch the game. Prior bundles, player saves and archived evidence are preserved.

Code commit: `a4789224580330015cb214f38afd976b22249737`. Documentation/evidence is separate. The [manifest](evidence/copy-clarifications-2026-11-06/manifest.json) retains source hashes, the six clarified decisions, final check output, selected captures and native correspondence. Previous receipts keep their original pending-decision snapshots; this receipt and the current review record the completed follow-up.
