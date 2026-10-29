# Command-station refinement — 29 October 2026

The player approved the modal Chronicle and found the lookout informative, but reported cramped helm choices, uneven hardpoint placement, a missing Utility heading, a raised belt and an overly pale/rounded Inspect dialog with irrelevant cross-blueprint guidance. The lookout's visual identity remains undecided; this follow-up does not redesign it.

## Player evidence

- [Command dock](../../playtests/2026-10-29/01-player-command-dock.png)
- [Chronicle, positively reviewed](../../playtests/2026-10-29/02-player-chronicle.png)
- [Lookout](../../playtests/2026-10-29/03-player-lookout.png)
- [Inspect](../../playtests/2026-10-29/04-player-inspect.png)

## Delivered changes

Helm choices now fill their panel with equal-width cards, 16px base text and 24px icons, replacing the small inline pills. Bearing chips are also larger. The existing 40/60 desktop split and narrow stacked arrangement remain.

Broadside and Signature buttons share their top and bottom edges even when names wrap or one is reloading. Their blessings attach below the buttons in a separate row, leaving an unblessed action aligned. Utility has a matching heading and its blessing below. Marks, cooldowns, range/accuracy previews and action gates retain their meanings.

The belt now shares a bottom footer with Pause and Chronicle, independently of command scrolling. Roomy windows wrap items; short or narrow windows use horizontal belt scrolling with a visible scrollbar. Explicit footer focus ordering prevents deferred belt layout from putting keyboard traversal after the icons. The compact dock reserves enough command space to keep actions reachable while retaining existing art bounds.

Inspect uses the parchment surface, a 4px corner radius and a 2px ink border, matching the Chronicle's blocky treatment. The generic paragraph listing every ship's movement/trait is removed. Optional notes describe only the current ship's Ram, Harpoon or Evasive Rigging and active Skirmisher timing. Harpoon's pull remains unconditional while Pin needs a hit; Evasive Rigging's note respects grapple/range limits. Forecast and counterplay remain. Defense caveats appear with actual damage estimates, and the per-hit defense sentence appears only for sweeps. Resolving playback still suppresses forecasts and action notes.

## Verification and limits

All **364 app tests** passed, and app analysis passed. Seven font-loaded layout/interaction captures passed at 115–130% text: all five hulls, 1920×1080, 1440×1000, 1280×900, 1024×768, 800×600, 600×1000 and 360×900. Checks include partial blessings, a reloading Ram, equal button geometry, full-width helm choices, bottom-edge/stable belt position during command scrolling, current-ship note filtering and modal interaction. Existing raster ink/bounds assertions remain intact. The 12 focused lookout tests cover style, conditional/contextual caveats, keyboard/Escape and resolution suppression.

The wider suite caught bottom overflow and an unreachable button in the 800×600 layout with test fonts. Short windows now use one horizontally scrolling belt row, a smaller bounded lookout and a slightly larger minimum command budget. Belt/action tests and all raster checks passed after that correction. Forward/reverse keyboard traversal also passed after assigning explicit footer order.

One Sol Medium worker owned the Inspect widget/tests and performed a read-only review of the dock. The parent implemented the dock, corrected the two contextual note descriptions against source rules, reviewed the changes and inspected the renders. Core/simulator rules and persistence were unchanged, so their suites were not rerun for this presentation-only follow-up.

These are isolated Flutter widget renders with Georgia and Material icons, not a native replay or a claim of final visual approval:

| Capture | Evidence |
| --- | --- |
| Ironclad, partial blessings and reloading Ram | [Desktop](../../playtests/2026-10-29/05-refined-ironclad-desktop.png) |
| Standard | [Desktop](../../playtests/2026-10-29/06-refined-standard-desktop.png) |
| Corsair | [Compact](../../playtests/2026-10-29/07-refined-corsair-compact.png) |
| Squared, contextual Inspect | [Desktop](../../playtests/2026-10-29/08-refined-inspect.png) |
| Short window and bottom belt | [800×600](../../playtests/2026-10-29/09-refined-small-window.png) |

Source and evidence copies preserve all prior changes. Production saves and the shared Windows executable/bundle were untouched. No new artwork, Goal, save format, balance change, turn cadence or wider spatial/layout redesign was introduced. Player replay is pending.
