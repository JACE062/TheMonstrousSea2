# Clipper rigging progression and upgrade purse — 29 October 2026

Historical verification receipt. [Current game](../../CURRENT_GAME.md#utility-behavior) owns utility rules; [PT2-30](../../BACKLOG.md#pt2-30--clipper-utility-tempering-has-no-visible-or-implemented-mk-progression) records the accepted progression and [PT2-11](../../BACKLOG.md#pt2-11--combat-ui-does-not-function-as-a-readable-command-station) records purse visibility and Sargasso clarification.

Player evidence: [stronghold purse/upgrade menu](../../playtests/2026-10-29/16-port-purse-player.png), [stale Mk III wording](../../playtests/2026-10-29/17-rigging-wording-player.png), [Apex Shark zero dodge](../../playtests/2026-10-29/18-apex-dodge-player.png), and [clarified Sargasso message](../../playtests/2026-10-29/19-sargasso-message-player.png). The stronghold screenshot does show 417g in the captain line; the requested usability improvement places the balance with upgrade costs too.

Delivered:

- The shared Haven/stronghold shipwright shows a live purse directly above upgrade costs. A real purchase refreshes both balance and affordability; existing summary/home displays remain.
- The user explicitly approved Evasive Rigging bonuses of +25/+40/+55 percentage points above base at Mk I/II/III. `ShipState.evasiveRiggingBonus` / `evasiveRiggingEvasion` supply activation and the shared inspection/battle description. Fresh base25 totals are 50/65/80%; hull IV base40 totals are 65/80/95%. Captain/Basalt additions and the final 95% dodge cap remain. This is an additive replacement for doubling, so higher-tier Mk I hulls can receive less dodge than before. Reuse does not stack; successful dodge consumes the boost. Movement, grapple gates, two-turn cooldown and existing kelp/utility interaction remain.
- Hot restart was not the missing wording fix: both source strings were still fixed “doubles” text before this work. New copy gives the actual current hull/Mk value. Player saves/marks are not rewritten.
- The player clarified that “+10% monster evasion” was an interpretation of Obscurity. Apex Shark's 0% dodge is correct; hazard narration now explicitly assigns −10% evasion to the ship and distinguishes Obscurity. A regression checks that a nonzero accuracy modifier does not change dodge. A separate known gap is documented: Sargasso's Obscured flag can have zero effect on species with a default zero accuracy modifier. No new regional defense amount was selected or added.

Verification: all 697 core tests and 382 app tests passed, with core/app analysis clean. New coverage includes 29 core utility tests plus the updated legacy additive-bonus test, numeric inspection/tooltips for all marks, four purse checks and the Apex/Obscurity readout check. All 32 simulator tests excluding the report-writing balance audit passed. Two additional isolated Georgia/Material Icons checks rendered 360/1280 widths at 130% text; reviewed [compact purse](../../playtests/2026-10-29/20-shipwright-purse-compact.png) and [tier IV Mk III description](../../playtests/2026-10-29/21-rigging-mk3-desktop.png). These are widget review captures, not native-build or final typography approval. Documentation and diff checks passed. Saves, native build output and tracked simulator reports were untouched.

## Bounded paired observation

900 starts used CautiousBot with seeds `42 + 31*i`, `i=0..49`, fixed Clipper, no Boon, Quirk none/Reckless Helmsman/Impatient, ancestral I and 25 gold. Only Clipper ownership was added beyond the core's default Standard. Builds were fresh hull I/Mk I and synthetic hull IV/all-Mk II or all-Mk III; later rewards/upgrades were normal. Each run continued to true expedition victory/death with a 2,500-command cap. Both snapshots retain the earlier range and Wait & Reload corrections. The sole rule difference is activation's old doubling assignment versus the new shared getter; no older committed baseline was substituted. A later hazard-narration wording clarification does not affect combat or RNG.

| Per 450 starts | Old doubling | Additive progression |
| --- | ---: | ---: |
| Kraken clears | 303 | 303 |
| World Serpent clears | 186 | 187 |
| Final expedition clears | 32 | 34 |
| Deaths | 418 | 416 |
| Utility activations | 2,897 | 2,927 |
| Exceptions / command caps | 0 / 0 | 0 / 0 |

Only Impatient used this utility under CautiousBot. Hull IV/Mk III Impatient final clears were 4/50 → 6/50; hull IV/Mk II stayed 2/50. Other captains' runs do not establish this utility's strength because they never activated it. Fresh results were identical in 149/150 rows: seed507/Impatient diverged only after normal hull upgrades reached base35, making old Mk I 70% versus new 60%; initial base25 activations both gave50%. Hull IV base40 makes Mk II equal the old80%, while Mk III reaches95%. This is descriptive evidence from one bot and 50 seeds per cell, not a human balance target.

Experimental [audit](evidence/rigging-progression-2026-10-29/audit.dart), [summary](evidence/rigging-progression-2026-10-29/summary.json), [source difference](evidence/rigging-progression-2026-10-29/source-diff.patch) and verification/preparation/trace scripts are retained together. Package snapshots and raw result rows remain ignored under `.dart_tool/rigging-progression-audit/`. Verification checks hashes, isolated core bindings, identical audit scripts, the one-assignment difference and the seed507 trace. Reproduction starts by copying evidence scripts into that ignored directory on a checkout without snapshots, running `prepare.py` from the repository root, copying `audit.dart` into each generated `monstrous_sim`, then using `run.ps1`. Its saved seed507 trace files support the separate verification. Preparation refuses existing snapshots. Evidence does not define production rules.
