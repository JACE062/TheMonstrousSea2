# Combat command station — 28 October 2026

The user asked to move on from individual label refinements and approved the next command-layout slice. They selected **two weapon cards side by side with a utility row beneath**, rather than three stacked hardpoints. Flutter/Dart/Flame remains the production stack; the earlier engine-comparison fixtures are experimental evidence, not source components or approved designs.

## Implemented trial

The upper health/status panels remain. On wider windows the bottom dock splits helm/actions 40/60. Helm holds bearing, the three labeled orders and their timing. Hardpoints show two offensive cards with opening accuracy and range damage percentages, followed by utility and a wrapping belt. Existing cooldown, range, grapple, consumable and captain-trait restrictions remain.

Large windows place a brief lookout beside the monster with reserved scene width. Other windows keep a compact lookout above independently scrolling commands; Pause and Chronicle remain fixed. Narrow layouts stack helm over actions. Measured dock/HUD insets bound the existing artwork and local feedback without changing event cadence or tying input unlock to decorative label expiry.

The lookout shows intent, threatened bands, movement/windup timing and a short helm forecast. Inspect holds descriptions, live limb/base-damage calculations, range stages, defense caveats and counterplay. Action movement makes helm-only assessments conditional; relevant action tooltips retain their own response forecasts. Forecasts are withheld during playback. A preview-only correction preserves the selected Advance identity after predictable action movement, without applying the helm twice, and aligns the collision warning with the existing resolver. Combat resolution itself was not changed.

Chronicle opens as a modal instead of occupying the dock. It initially follows latest and remembers manual reading/follow-latest state across reopenings within that battle. It still holds only the current voyage in session memory. Existing playback continues underneath while gameplay input is blocked. Close/Escape removes the modal before Pause and restores surviving prior focus. A fresh battle starts at latest. No round grouping or persisted log archive was added.

## Verification

- All **358 app tests** and **629 core tests** passed. App and core analysis passed.
- Five layout fixtures cover Standard at 1280×900 / 115%, Bombardier/Kraken at 1440×1000 / 130%, Corsair/Kraken at 600×1000 / 130%, Ironclad at 360×900 / 130%, and Clipper at 1024×768 / 130%. They include blessings and expanded, filled belts.
- Layout checks cover the two cards/utility placement, 40/60 split, desktop art clearance, fixed lookout during command scrolling, reachable belt help, modal bounds and Escape dismissal. Existing raster ink/bounds checks remain intact; compact interaction fixtures now scroll to controls before tapping.
- Existing Skirmisher/Impatient, Ram/Harpoon, cooldown, belt, live intent and sweep tests passed with dense mechanic assertions moved into Inspect. Deterministic preview tests cover applied/unapplied helm, collision parity with actual response, Hold Line and Pin.
- Chronicle tests cover initial/latest/manual/reopened positions, incoming messages, gameplay blocking after playback unlocks, surviving focus and Escape priority alongside Pause. Existing art recovery and terminal playback checks passed.
- Two Sol Medium workers owned the separate lookout and Chronicle components. The parent integrated them, reviewed the actual changes, corrected compact placement and reserved scene space, and inspected the captures below.

These are font-loaded Flutter widget renders using Georgia and Material icons, not native player replays. The fixtures use isolated injected sessions and replace combatants for layout coverage; their initial Chronicle messages can belong to the original seeded encounter. Their purpose is layout and interaction verification. A passing overflow test does not prove comprehension or preferred proportions. Compact commands deliberately require scrolling, and the narrowest lookout can also scroll within its bounded strip.

| Capture | Evidence |
| --- | --- |
| Standard desktop | [1280×900](../../playtests/2026-10-28/04-command-station-desktop.png) |
| Bombardier and Kraken | [1440×1000](../../playtests/2026-10-28/05-command-station-kraken.png) |
| Corsair compact | [600×1000](../../playtests/2026-10-28/06-command-station-compact.png) |
| Ironclad narrow | [360×900](../../playtests/2026-10-28/07-command-station-narrow.png) |
| Chronicle modal | [Desktop](../../playtests/2026-10-28/08-command-station-chronicle.png) |
| Intent inspection | [Compact](../../playtests/2026-10-28/09-command-station-inspect.png) |

Production saves and the shared Windows executable/bundle were untouched. No new art, sound, Goal, native rebuild, save schema or gameplay tuning was introduced. Spatial movement, threat zones, status icons, maritime backgrounds, main-menu changes and richer logbook styling remain separate. Player review of this trial is still pending.
