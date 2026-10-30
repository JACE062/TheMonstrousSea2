# Sargasso haze accuracy floor — 30 October 2026

Historical verification receipt. [Current game](../../CURRENT_GAME.md#combat-resolution-and-monster-behavior) owns the implemented rule; [PT2-11](../../BACKLOG.md#pt2-11--combat-ui-does-not-function-as-a-readable-command-station) records the accepted correction.

The user approved a 10-percentage-point minimum shot-accuracy penalty for Sargasso haze, alongside the separate kelp penalty to ship evasion. Encounter startup now uses `max(existing obscurity modifier, 10)` and reports the actual penalty in narration. Stronger squid/Apex squid ink stays 20/25, rather than stacking. Monster dodge is unchanged. Normal hit-based dispersal, Flare clearing and Ghostwake bypass retain their behavior; there is no new timer, recurring application, save field, AC rule or RNG draw.

An ordinary unmodified cannon shot at Short/Medium changes from 85% to 75% accuracy; Long remains subject to its separate −15% penalty, giving 60%. Clipper Culverin accuracy changes from 95% to 85%. Against a Medium-range ordinary Serpent, 75% accuracy and its unchanged 20% dodge give 60% per-shot connection; an Apex/World Serpent's 30% dodge gives 52.5%. These are opening examples before captain, blessing and other modifiers. Later shots can benefit when a successful hit disperses haze.

Verification:

- All 719 core tests passed. The 22 new cases use real encounter startup for all five ordinary species, regular/Apex, the World Serpent, Shark/Squid Nemeses, other regions and Volatile Environs. They also check repeated starts, actual hit boundaries/caps, 25/26 dispersal, miss/dodge exclusion, actual Flare clear/expiry, and Ghostwake's bypass with frozen obscurity facts.
- All 383 app tests passed; core/app analysis was clean. The HUD fixture now enters a real Sargasso Apex Shark encounter and checks 0% dodge alongside −10% Obscurity and the 85% Culverin forecast. At 360/1280 widths and 130% text, two extra Georgia/Material Icons captures passed and were reviewed: [compact](../../playtests/2026-10-30/02-sargasso-haze-compact.png), [desktop](../../playtests/2026-10-30/01-sargasso-haze-desktop.png).
- The compact encounter exposed a pre-existing carapace heading overflow. Its label/value now stack only below the health gauge's text-scaled width threshold; wide layout remains unchanged. The raster-art/resize checks pass, preserving illustration space. This is a bounded layout correction, not the broader combat redesign.
- All 32 simulator tests outside the report-writing balance audit passed. Documentation/diff checks passed. Tracked simulator reports, player saves and the shared native build output were untouched. No commit or Goal was created for this new follow-up.

## Bounded paired Region 2 observation

1,000 starts used CautiousBot, seeds `42 + 31*i`, `i=0..49`, all five forced blueprints and two synthetic Sargasso arrival builds: hull II/all-Mk I and hull IV/all-Mk III. Each began with ancestral I, 25 gold, no captain traits, blessings, relics, pacts or free cargo. Only the chosen blueprint was added beyond the core's default Standard ownership. The actual chart advanced to Region 2 and normal TakeHelm/SteerCourse, rewards and upgrades followed. Region 1 history/rewards were skipped. Runs stopped at death or `timesCompleted >= 2`, confirming a World Serpent clear rather than crediting the skipped Kraken; the cap was 2,500 commands.

The isolated before/after packages differ only by the new minimum-modifier assignment. Both retain the current rigging/range/Wait corrections and new narration, so narration format is not a confound. Verification checked source hashes, isolated package bindings, identical audit scripts, every Sargasso start and battle-entry haze flag, and all terminal outcomes. The after-core source matched production.

| Per 500 starts | Missing haze floor | 10% haze floor |
| --- | ---: | ---: |
| World Serpent clears | 146 | 126 |
| Deaths | 354 | 374 |
| Monsters defeated | 1,493 | 1,403 |
| Verified battle entries | 1,847 | 1,777 |
| Exceptions / command caps | 0 / 0 | 0 / 0 |

Weak arrival builds cleared 1/250 → 2/250; strong builds cleared 145/250 → 124/250. For hull IV/Mk III, clears per 50 were Standard 28→24, Ironclad 21→16, Clipper 31→28, Bombardier 31→26 and Corsair 34→30. First-encounter modifiers changed 0→10 in 410/500 pairs; 80 existing 20-point and 10 existing 25-point modifiers were preserved. This demonstrates increased pressure under one bot policy, not a human balance target or proof every seed becomes harder. Player replay remains needed.

Experimental [audit script](evidence/sargasso-haze-2026-10-30/audit.dart), [summary](evidence/sargasso-haze-2026-10-30/summary.json), [source difference](evidence/sargasso-haze-2026-10-30/source-diff.patch), preparation, runner and verification scripts are retained together. Raw rows and package snapshots remain ignored under `.dart_tool/sargasso-haze-audit/`. For reproduction on a checkout without snapshots, copy evidence scripts into that directory, run its `prepare.py` from the repository root, copy `audit.dart` into each generated `monstrous_sim`, then use its `run.ps1`. Preparation refuses existing snapshots. These artifacts are evidence, not production rules.

Separate known issue: the real Flare handler permanently overwrites innate monster evasion; expiry does not restore it. That mutation is unchanged here and tracked under PT2-12, preserving the agreed haze scope.
