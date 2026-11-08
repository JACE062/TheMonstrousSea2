# Independent combat status help — 8 November 2026

The [player screenshot](../../playtests/2026-11-08/status-tooltips/01-player.png) showed Illuminated inheriting dodge help from the monster's whole stats row; the user reported the same problem with Ironclad damage reduction.

## Result

`ShipCombatStats` and `MonsterCombatStats` render separate wrapping stat/effect targets. Dodge/Evade keep the avoidance explanations. Fortified, Anchored, Braced Volley, Pitch Coated, Frenzy, Obscurity, Pinned, Illuminated and the drifting trap have their own effect help. Neutral level/class/tentacle text no longer triggers dodge help. Shared parchment styling and hover/long-press access remain.

All values come from the detached actors already supplied to the battle HUD. Flare accuracy/Blast bonuses and current fortification cannot reveal future live state during playback. Braced Volley's damage label also follows the displayed fitting mark rather than always claiming +20%. No core rules, save fields, artwork or provisional tuning changed.

## Verification

- **31 focused app tests passed:** evasion readouts, combat flow, power badges and the command station. The final readout file then passed all **14 cases** with the real game fonts, including mouse movement between Illuminated/Fortified/Dodge/Evade at 360/1280 widths and 130% text, long-press access and unchanged HP/phase. Causal effect-event assertions reject future live fortification and Flare values.
- **Eight font-loaded captures:** four independent hover targets at each width. [Desktop Illuminated](evidence/combat-status-tooltips-2026-11-08/visual/status-illuminated-1280.png), [compact Illuminated](evidence/combat-status-tooltips-2026-11-08/visual/status-illuminated-360.png), [compact Fortified](evidence/combat-status-tooltips-2026-11-08/visual/status-fortified-360.png) and [desktop Evade](evidence/combat-status-tooltips-2026-11-08/visual/status-evade-1280.png) were visually inspected. The capture helper waits for tooltip fade-in before recording. Headless Flutter lacks the existing sun emoji's system fallback; the label text and tooltip remain readable. Icon replacement is outside this fix.
- Final app analysis is clean. Documentation and whitespace checks pass. [Raw logs](evidence/combat-status-tooltips-2026-11-08/checks/) retain command output.
- A separate Windows Debug build succeeded at `.dart_tool/status-tooltip-preview/build/windows/x64/runner/Debug/monstrous_sea.exe`, without launching it. The [manifest](evidence/combat-status-tooltips-2026-11-08/manifest.json) records source/asset/lock correspondence and executable hash. Earlier preview bundles and player saves were not touched.

The tests use isolated unsaved controllers and copied cached fonts. No player profile was loaded or modified. Player replay remains pending.
