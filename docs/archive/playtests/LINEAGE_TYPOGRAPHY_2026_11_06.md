# New Lineage typography — 6 November 2026

Fixed the renewed [player report](../../playtests/2026-11-06/lineage-type/01-player.png) of serif body text with sans-serif title/actions. `InkTheme.textTheme` now supplies `headlineSmall` and `labelLarge` from the selected Ink styles. The installed Flutter Material 3 dialog/text-button defaults use those slots; omitted values had inherited Material's sans-serif defaults. Serif mode now uses the established heading/action typography, while plain mode remains clean type. The dialog's labels, validation, 60-character limit, actions and save behavior are unchanged.

The existing layout check renders the real theme in both modes at 360/1280 widths and 115/130% text: four cases, **eight captures**. Cached game fonts provide the serif faces; SDK Roboto is loaded only for plain-mode test rendering, avoiding Flutter's Ahem test blocks without overriding the theme. Both modes were visually inspected.

## Verification and ancillary corrections

- App analysis is clean; **452 app tests passed**.
- **Four font-layout cases passed**, each exercising both modes. No new implementation-mirroring unit tests were added.
- The full run found an existing 14-pixel overflow in a borderline 130% course-report overlay. A copied-UI check with the new typography slots removed reproduced it, so it predates this fix. The report-fit guard now leaves more room for borders/scaled metrics and uses the established single-page fallback rather than clipping. No font shrinking, course or service change was introduced.
- Two wreck-warning expectations still named the pre-clarification Apex sentence. They now verify the approved “an Apex may be lurking” wording, retaining the same condition/choice coverage.
- A Windows Debug build succeeded under `.dart_tool/lineage-type-preview/`, with exact final app sources/assets and matching dependency lock. It was compiled without launching the game. Previous bundles, captures, audit files and player saves are preserved. Core/simulator code, mechanics and approved art are unchanged.

The broader save-menu usability/layout review remains deferred. Source commits are `80a76ef` (typography and real-mode captures) and `139c2c2` (existing layout guard/stale expectations). Documentation/evidence is separate. The [manifest](evidence/lineage-typography-2026-11-06/manifest.json) retains canonical source hashes, the byte-preserved player image, all final captures/checks, the separately labeled baseline diagnostic and native correspondence.
