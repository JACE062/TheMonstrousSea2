# Chart bounds, bearing width and marginalia — 5 November 2026

Completed the next player-requested chart refinements. [Current game](../../CURRENT_GAME.md#chart-bounds-and-marginalia--5-november-2026) owns behavior; [PT2-08](../../BACKLOG.md#pt2-08--sea-chart-needs-a-clearer-player-purpose) owns status. Earlier navigation, economy and chart evidence is preserved.

## Delivered changes

- Desktop bearings use **30%** of the chart width. Text retains its normal body size and complete callouts. When the narrower overlay cannot fit, the existing single-page fallback retains every choice without nested scrolling or text reduction.
- Every camera write is bounded, including drag inertia, wheel/pinch, toolbar, keyboard and resize/rebasing. The initial limits extend 120 world units left of the start, 160 beyond the furthest visit, and one minimum-zoom viewport height above/below recorded extrema. A short route that fits horizontally stays centered on that axis. Zoom remains 90%–3×.
- The original harbor says **Hunter’s Respite**, including after changing regions. The text-only Arrival/Passed wreck/Cargo recovered/Skull legend is removed.
- Curved warnings, reused approved shark/squid/serpent illustrations, uncertain coast sketches and small ink annotations move with the map. These faded ornaments sit beneath the wake, ignore pointers/semantics, use only recorded points and consume no gameplay RNG. They are not terrain, destinations or clues to hidden plans.
- The user’s requested Hull, Purse and Center Journey icon replacements are recorded in the art backlog, explicitly deferred. Existing colored badges and named controls remain usable.

Width and camera margins are presentation starting values for replay. No encounter, captain, reward, service, economy or save mechanics changed. Economy tuning remains independently provisional.

## Verification

| Check | Result |
| --- | --- |
| Complete app suite | **447 passed** |
| App analysis | No issues |
| Font-loaded navigation/service checks | **31 passed** |
| Windows Debug build | Successful in a new isolated project |
| Documentation/whitespace | Output retained with the evidence |

Four new tests cover 40-leg horizontal/diagonal routes, large high-speed flings and inertia, keyboard movement, both zoom limits, resize and Find Vessel. They check finite world limits, unchanged chart JSON, short-route horizontal centering, actual displayed 30% report width at 2536×1417/115%, the visible home name after crossing regions, removed legend and noninteractive marginalia. Camera matrices keep uniform XYZ scaling because Flutter’s maximum-axis zoom read otherwise defeats a scale below 1.

The existing font-loaded layout checks cover 115–130% text, compact/short screens, region/service/restriction states, redraw and departure. At the narrower width, constrained screens can use the established complete-page fallback; no test requires a clipped overlay. Final captures include the 30% layout and bounds interactions and are visually inspected. The corrected home label stays within the initial long-route viewport. Core/simulator code is unchanged, so their suites and balance comparisons were not repeated. Tests use unsaved sessions or disposable storage; no native player voyage is claimed.

## Build and preservation

The normal Windows game was running during this work. Its bundle and previous preview directories were left untouched. The new build is under `.dart_tool/chart-bounds-preview/`, with exact final app sources/assets, matching dependency lock and the same original local core package. It was compiled without launching it or writing player saves. Close any running game before opening this preview because normal instances share lineage storage.

The connected UI change is commit `fe666ad87d7bc248c8c04e561faf5e8a12933b7e`; documentation/evidence is a separate commit. The [manifest](evidence/chart-bounds-2026-11-05/manifest.json) retains canonical source hashes, raw input/evidence hashes and check counts. [Native source verification](evidence/chart-bounds-2026-11-05/native-source-verification.json) records exact app/asset correspondence and executable identity. The [player screenshot](../../playtests/2026-11-05/chart-bounds/01-map-bounds-and-width.png) is retained byte-for-byte. Previous audits, player saves and the stock simulator report are unchanged. Human replay remains useful for the revised width, margins and ornament placement.
