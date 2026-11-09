# Combat layout audit — 9 November 2026

The user requested a combat layout review at 115% text, including all ship types, trait combinations, full belts and multiple active effects. Fixtures use the normal debug/pause hosts, cached game fonts and isolated controllers with autosave disabled. They do not load or write player saves.

## Findings and changes

- In the initial short-window probe, all five crowded hull HUDs overlapped the command dock at 800×600. The HUD now has a bounded scroll viewport with a visible scrollbar. Arena insets measure that viewport rather than the height of offscreen details. Integrity meters precede detailed stats/effects, so initial health remains visible on compact screens.
- Dock and lookout budgets now use the actual combat body after shell controls, rather than the entire window. Visual review also caught a clipped brief forecast on crowded desktop screens; those layouts now reserve enough room for the brief, with visible scrollbars for longer reports. The command scroll and horizontal belt scroll remain independent; belt/Pause/Chronicle stay fixed while commands scroll. The arena retains room for both combatants.
- At 360 pixels/115%, reloading names clipped for Heavy Carronades, Long-Barrel Swivel Guns, Shrapnel Howitzers and Chain-Shot Broadside. The name no longer repeats the cooldown already displayed directly beneath it. The reload subtitle, exact remaining turns, semantic description and readiness gates are retained.

No combat resolver, effect values, playback timing, progression, save format, artwork or provisional tuning changed. Existing compact monster-name ellipsis remains separate from the open naming work in PT2-13.

## Coverage

| Matrix area | Cases |
| --- | ---: |
| Five hulls × eight Boons × eight Quirks, crowded effects/full belts, 1280×900/115% | 320 |
| Five hulls: dense HUD at 360×900, 800×600 and 1280×900; ready compact state | 20 |
| Ten additional states × five hulls × three sizes, 115% | 150 |
| Five hulls: dense effects and dialogs at three sizes, 130% | 15 |
| **New matrix** | **505** |

The additional states are fitting cooldowns, Impatient's pending combination and recovery, spent quick-item allowance, empty belt, Kraken windup/release, Long range, Storm Rigging and Boiling Wake. Those cases use 360×900, 800×600 and 1672×952. Enemy coverage includes Apex squid, crustacean, serpent, shark and jellyfish plus the non-Apex Kraken. Fixtures use Mk III fittings, Tier III blessings and an expanded filled belt, including Quartermaster capacity in the dense cases. Dense effects exercise Grappled, accuracy loss, Pitch Coated, Braced Volley/Braced, Fortified/Anchored, Basalt Barrier, Corroded, Shaken, Burning/Poison/Stun, Illuminated, Pin and tether placement as appropriate to the hull. Storm/Wake cases separately cover Static Charge, Electro-Jolt, Frenzy and timed Burning. This is controlled render-state saturation, not a claim that every supplied combination arose in one simulated fight.

Checks verify HUD/dock separation, initial integrity visibility, two mounted combatants inside the arena, boxed-action and helm reachability, complete action bounds, fixed footer position and access to every active effect. Real-font checks also reject clipped action labels/subtitles. At 130%, Belt Help, intent inspection, Chronicle and stat/effect explanations open within the viewport and dismiss without dispatching combat. Ship/profile/chart and captured encounter-state snapshots remain unchanged through review. The manifest records final matrix and related functional results.

The **505-case matrix passes with cached game fonts**. The same matrix plus **130 existing combat/UI cases passes offline: 635 total**, using Flutter's bundled fallback for the new matrix. Existing regressions exercise actual belt limits, firing/recovery gates, displayed-state playback, artwork recovery, Chronicle reading/focus and linked effect help.

## Evidence and limits

[The manifest](evidence/combat-layout-2026-11-09/manifest.json) indexes source hashes, logs and selected game-font captures. Examples include the [crowded desktop Standard](evidence/combat-layout-2026-11-09/visual/reviewed/battle-standard-dense-1280-1.15.png), [compact Standard](evidence/combat-layout-2026-11-09/visual/reviewed/battle-standard-dense-360-1.15.png), [short-window Ironclad](evidence/combat-layout-2026-11-09/visual/reviewed/battle-ironclad-dense-800-1.15.png) and [Bombardier effect help](evidence/combat-layout-2026-11-09/visual/reviewed/battle-bombardier-status-help-1672-1.3.png). Compact screens deliberately scroll details and commands; they do not display every fitting and effect simultaneously. Native player replay remains useful for comprehension and pacing.

Preliminary logs are retained transparently. The first probe also had ten fixture failures from checking Belt Help after scrolling it out of view; these were not game defects. A later tooltip probe incorrectly expected Obscurity while Flare suppressed it; that assertion now checks Illuminated instead. The paused Flame fixture was strengthened to await lifecycle readiness and require both mounted combatants before visual capture. One subsequent capture was blocked by a Windows viewer holding an earlier PNG open; the layout matrix was then rerun without overwriting viewed images, with captures retried in a fresh directory. These setup/artifact failures are distinct from the reproduced layout defects above.

The default test run loads Flutter's bundled Roboto and Material Icons offline rather than using Ahem's oversized square glyphs. Game-font runs remain the typography/ellipsis oracle. The retained Ahem probe is a fixture comparison, not a claim about player rendering. The existing stat-hover regression now scrolls each target into view before hover/long press, matching the bounded HUD.

A fresh Windows Debug preview builds at `.dart_tool/combat-layout-reviewed-preview/build/windows/x64/runner/Debug/monstrous_sea.exe`; it was not launched. [Preview correspondence](evidence/combat-layout-2026-11-09/preview-correspondence.json) verifies 120 app/config/Windows files, all 34 bundled art assets, 53 unchanged shared-core inputs and the executable hash. Existing saves, earlier previews and earlier audit evidence remain untouched.
