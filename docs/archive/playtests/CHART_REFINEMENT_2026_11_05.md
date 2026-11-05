# Chart readability and control refinements — 5 November 2026

Completed the next screenshot-driven navigation UI batch. [Current game](../../CURRENT_GAME.md#chart-readability-refinements--5-november-2026) owns behavior; [PT2-08](../../BACKLOG.md#pt2-08--sea-chart-needs-a-clearer-player-purpose) owns status. Earlier navigation/economy and chart-focus evidence remains unchanged.

## Delivered changes

- **Readable zoom:** Replaced the rejected journey-height zoom trial with a provisional minimum of 90% scale. A 46-unit marker stays at least 41 logical pixels wide on long horizontal and diagonal routes. Maximum remains 3×. Initial/Find Vessel view uses normal scale; Center Journey centers travelled bounds while retaining zoom. Long journeys require panning.
- **Moving, continuous markings:** `SeaChartWaterPainter` shares the route’s camera transform/world offset and paints the visible world bounds. Waves, graticule, rhumb lines and folds move with pan/zoom and cover distant/negative coordinates without a finite texture rectangle. The worn frame, compass and controls remain fixed. No gameplay RNG, geography or future destinations are introduced.
- **Prompt tooltips:** Shared tooltip initial hover wait is zero. The first hover and a move to a second tooltip both produce their annotations within the test’s 30 ms window; normal fade animation remains. Parchment/ink styling and selected font mode remain.
- **Cleaner map:** Removed the Travelled Waters label and gesture-instruction line. Zoom, centering and vessel controls sit on the paper above the compass, toward the top on short maps to avoid covering the initial ship. Ink magnifier/centering glyphs and the approved ship illustration improve the controls; dedicated custom artwork remains deferred. Tooltips use device-neutral labels, while keyboard equivalents still work.
- **Useful header:** Healthy/wounded/critical hull and gold have colored, framed badges. Voyage Log and Inspect Vessel are bordered actions, with inspection emphasized and named even on compact screens.
- **Complete lookout reports:** Increased the available desktop width, removed nested quote boxes and redundant bearing prose, and reduced spacing. Full lookout/restriction text is retained; primary report text uses normal body size (17 before text scaling) rather than the previous 13.5-point override. Cards have no independent scroll. Text measurement selects an overlay only when it fits; constrained windows or additional triage/Storm-Seer controls use a single scrolling body below the fixed header. The existing stale/departure guards remain.

Zoom and report-width numbers are UI starting values for replay. Encounter cadence, strength, captain mechanics, reward/service rules and saves are unchanged; economy tuning remains separately provisional.

## Verification

| Check | Result |
| --- | --- |
| Complete app suite | **443 passed** |
| App analysis | No issues |
| Font-loaded navigation/service checks | **27 passed** |
| Windows Debug build | Successful, in a fresh isolated refinement project |
| Documentation/whitespace | Retained check output in the evidence directory |

New tests verify rendered minimum icon size on 40-leg horizontal/diagonal routes, distinct center/vessel actions, unchanged chart JSON, first/subsequent hover timing, translation of the same world texture patch and wave coverage in every distant viewport quadrant. Layout checks use the supplied long Nemesis callout at 2546×1424 and 1920×1080 with 115% text, and 1280×850, 360×900 and 800×480 with 130%. All three ordinary desktop choices are visible together without a nested scroll; short/compact fallbacks retain all text and actions. Existing region/service/restricted-heading/redraw/departure tests remain. Additional service controls receive conservative space so triage plus final preparation cannot overflow.

Final font-loaded screenshots are inspected and retained. Tests disable autosave or use the established disposable-storage guard. Core/simulator behavior is unchanged and those suites were not repeated. No new balance comparison or native player voyage is claimed.

## Build and preservation

The earlier preview was still running from `.dart_tool/chart-preview/`. It and the normal Windows bundle were left untouched. This batch builds under `.dart_tool/chart-refinement-preview/`, using exact final app sources/assets, matching dependency lock and the same original local core package. The preview was compiled without launching it or deliberately writing a player save. Close the running game before opening the new preview because normal instances share lineage storage.

The global tooltip timing change and connected map/header/report changes are logical code commits; their full IDs, canonical source hashes and raw evidence hashes are in the [manifest](evidence/chart-refinement-2026-11-05/manifest.json). The final documentation/evidence commit records owning-rule updates and this receipt. [Native source verification](evidence/chart-refinement-2026-11-05/native-source-verification.json) confirms the isolated app sources/assets match the workspace and records the executable hash.

The [player screenshot](../../playtests/2026-11-05/chart-refinement/01-map-usability.png) is preserved byte-for-byte. Previous archived evidence, player saves and the stock simulator report are not replaced. Human replay remains useful for the readability and layout trial.
