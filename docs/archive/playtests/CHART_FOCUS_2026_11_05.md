# Chart focus and tooltip follow-up — 5 November 2026

Completed the next player feedback batch: specific Nemesis identification, map/page wheel conflict, excessive zoom-out, combining chart/course selection, aged map presentation and thematic tooltips. This receipt preserves verification; [Current game](../../CURRENT_GAME.md#map-focused-helm-and-tooltips--5-november-2026) owns delivered behavior. The initial refactor and first playtest-fix evidence remain unchanged.

## Delivered presentation

- The helm is one **Nautical Sea Chart** surface. Desktop lookout reports float on the map with their own scroll thumb; compact/short windows show the chart and reports in one scrolling page. The separate Consult Sea Chart button is removed from the helm. Voyage Log and Inspect Vessel open dismissible panels there; other stops retain their read-only chart. Hull, purse, wind, region and leg remain visible.
- Known Nemeses have a crimson **NEMESIS** tag. Ordinary identified encounters retain their type, and fogged ordinary encounters gain no identifying label. History/tooltips also distinguish a recorded Nemesis.
- Wheel signals over the viewport zoom the map and are claimed before the page can consume them. At the zoom limit, the page still stays put. Over reports or elsewhere, normal local/page scrolling remains. Drag, wheel/pinch, keyboard arrows/Home/End and zoom/frame/locate controls remain available.
- Framing uses vertical extent, leaving long horizontal journeys to panning. The starting zoom-out bound permits at most twice the greater of padded route height, viewport height and a 320-world-unit legibility floor. Maximum zoom remains 3×. This is adjustable presentation tuning for replay, without gameplay or economy effects.
- The paper is warmer than the surrounding app, with gently worn wavy edges, ruled border, faint folds, graticule/rhumb lines, waves and a compass. Existing approved harbor/cargo illustrations replace the rough Haven/salvage symbols. Dedicated shrine/wreck and other entity art remains a separate curated pass. The supplied antique map is inspiration/evidence, not a new game asset or revealed geography.
- Shared Material tooltips use parchment fill, dark ink, a fine border, restrained shadow and the selected font mode. Long text wraps on compact screens. The wider app palette remains unchanged.

## Behavior and safety

The full committed route and explicit arrival/pass/victory/cargo outcomes remain deterministic and retained across regions. Camera changes, logbook and inspection do not mutate chart JSON or roll gameplay RNG. Hidden plans/future offers, cadence, encounter difficulty, rewards, service rules, Storm-Seer, captain restrictions and emergency triage retain their behavior. Header/report widgets are captured before lazy layout so the outgoing helm cannot replace its offers during departure; duplicate/stale action guards remain.

The running Windows game was detected. Its executable and bundle were left untouched. A separate ignored build project under `.dart_tool/chart-preview/` uses copied app sources/assets/windows files, the same dependency versions and the original core package through an explicit local path. It was compiled without launching or writing any player save. Close the running game before launching this preview, since normal app instances use the same lineage storage. Native player replay was not performed by the agent.

## Verification

| Check | Result |
| --- | --- |
| Complete app suite | **435 passed** |
| App static analysis | No issues |
| Font-loaded chart/service tests | **19 passed**, with final compact/desktop/short-window captures inspected |
| Windows Debug preview | Successful isolated build from final app sources |
| Documentation/whitespace | Retained check output in the evidence directory |

New tests exercise crimson Nemesis versus ordinary/fogged tags, floating report wheel ownership, map wheel ownership at the height bound, normal scrolling outside it, 36-leg horizontal panning, route-height scaling, illustrated harbor/cargo markers, tooltip wrapping/color, log/inspection dismissal and unchanged chart state. Existing tests cover three-region layout/reduced motion, keyboard access, Storm-Seer and forced headings, emergency repair, direct reward-to-helm flow and outgoing-offer/stale-callback protection. The chart uses remaining bounded height to prevent overflow in a short standalone viewport.

Final screenshots include 1280×850, 1600×1000, 360×900 and 800×480 helm/logbook views at 130% text, a compact tooltip and three-region/preparation layouts. Widget fixtures disable autosave or use the established disposable storage guard. Core/simulator behavior was unchanged; their suites were not unnecessarily repeated. No balance simulation or new numeric economy approval is claimed.

## Source and evidence

The tooltip/palette change and unified chart are separate logical code commits; full IDs, canonical source hashes, isolated-build source verification, check logs and image hashes are in the [manifest](evidence/chart-focus-2026-11-05/manifest.json). This receipt and owning-document updates form the final evidence commit. The five new player attachments are preserved byte-for-byte under [chart-focus inputs](../../playtests/2026-11-05/chart-focus/).

Earlier archived evidence and the stock simulator report are unchanged. No player save was repaired, reset or otherwise deliberately written in this batch. Human replay remains necessary to assess the map feel and presentation trial.
