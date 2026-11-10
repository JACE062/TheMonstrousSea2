# Tooltip typography follow-up — 10 November 2026

The player requested smaller, less prominent keywords using weapon accuracy gold, and correction of excess space below weapon help. The [reported screenshot](evidence/tooltip-type-2026-11-10/player/01-keyword-and-footer.png) is preserved.

## Changes

Keywords use `InkTheme.goldAccent` and weight 600 rather than crimson/800. The inner Text now uses `TextScaler.noScaling`: Flutter's WidgetSpan already scales its child, so inherited scaling previously enlarged keywords twice. This preserves the selected text size while bringing keywords into proportion with surrounding text. Help cursors, no-underline styling and the fitting hover inset remain.

Weapon and utility messages join nonempty details/forecast lines. A missing movement forecast previously left a trailing newline, creating the blank footer. Existing Ram, Harpoon and Evasive Rigging forecasts remain; no combat or copy mechanics change.

## Verification and limits

Before production edits, all 14 initial cases failed against `df34dd6`: four rendered-size comparisons exposed double scaling, and ten real combat-screen checks found the trailing fitting line. The final 14 presentation cases cover both font modes, body/caption keywords and every hull at 115–130%. Reference-size comparisons allow small glyph/letter-spacing differences while rejecting the former 15–30% enlargement. Real fitting help is opened with F1 and all three fitting messages are checked without dispatching combat actions.

Those cases and the preceding 14 handoff cases pass with cached game fonts: **28 focused cases**. The **347-case offline regression run passes**, including the existing interaction, mechanic, dodge, overlay, shore and Chronicle checks. Analysis, formatting and documentation checks pass. [Gold linked help](evidence/tooltip-type-2026-11-10/visual/final/tip-carapace-1280-1.15.png) and [Clipper Signature help](evidence/tooltip-type-2026-11-10/visual/final/tip-clipper-signature-1.15.png) show the result.

Probe logs distinguish fixture corrections: the first run initialized font styles before the cached font provider and was stopped; the next measurement/input probe used an overly strict subpixel tolerance and a mouse point in a clipped utility row. Final checks use reference-size tolerance and explicit help activation; existing handoff tests still exercise mouse travel. These are widget-rendered proofs, not a native playthrough of every build.

## Preservation and preview

The [manifest](evidence/tooltip-type-2026-11-10/manifest.json) records checks and source/proof hashes. All scenarios are unsaved in-memory fixtures. Shared-core code, gameplay values, saves, artwork, earlier audits and provisional tuning are unchanged.

A fresh Windows Debug preview is built separately at `.dart_tool/tooltip-type-preview/build/windows/x64/runner/Debug/monstrous_sea.exe` and was not launched. [Correspondence](evidence/tooltip-type-2026-11-10/preview-correspondence.json) verifies app/config/Windows inputs, bundled assets, unchanged core inputs and build hashes.
