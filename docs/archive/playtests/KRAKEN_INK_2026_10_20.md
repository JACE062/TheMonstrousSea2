# Kraken release and ink verification — 20 October 2026

Historical verification receipt for PT2-17/18. Current rules belong in `docs/CURRENT_GAME.md`; this is not a competing implementation brief.

## Accepted change

The player accepted a dedicated 38-base-Blast Kraken maelstrom, unavoidable once released, with normal mitigation and interruption retained. Ink remains an accuracy penalty and is explained accurately in deployment logs, the health-area status and weapon tooltips. No independent ink dodge roll was added.

The Kraken release now has its own attack profile instead of selecting a normal weapon. It bypasses accuracy and dodge hooks but uses the shared damage pipeline for armor, Drill bracing, barriers, Corroded/Electro-Jolt and reactive powers. It does not consume an evasive-maneuver boost. No ordinary hit-roll event is fabricated. The preview identifies base Blast damage before weakening and defenses. Other Titan attacks retain their existing ordinary accuracy/dodge resolution.

Ink deployment events now expose `accuracyPenalty` with a compatibility `acBonus` reader. Both narration paths explain percentage points and clearing conditions. The monster HUD uses the same effective obscurity getter as hit calculations. Opening-shot tooltips include range, temporary gunnery boosts, Flare, target dodge and Ghostwake's obscurity bypass. A dispersed cloud gets an explicit clear message. Legacy ink specials cannot redeploy under Flare.

## Reproduction and deterministic checks

Before the fix, seed 42 creates a level-5 Kraken with 4-damage tentacles and a 26-damage ram. Forcing those selections and successful rolls resolves its 1.65× release to 7 or 43 damage, both against the same 38-damage preview. Separate forced d100 rolls reproduce an accuracy miss and a ship dodge. This establishes a sufficient cause for the playtest symptom without claiming the exact historical player build was recovered.

Core regressions cover:

- All five fresh hulls at Short, Medium and Long, with 95% current ship evasion and a 100-point monster accuracy penalty. The release performs neither accuracy/dodge rolls nor random weapon selection.
- A Kraken without usable normal weapons or remaining tentacles still releases its dedicated attack. An older serialized 1.65× intent multiplier cannot multiply its fixed damage again.
- Fresh Standard takes 38, or 30 under Drill brace. Fresh Ironclad takes 35 through its starting 3 flat armor. A valid 20-HP Basalt barrier absorbs 20 after armor/brace; combined Standard brace/barrier leaves 10 hull damage and still triggers barrier retaliation. Three Corroded stacks plus Electro-Jolt reduce the base to 24 before defenses, or 19 while braced.
- The windup grants a complete no-strike turn before release. Stun, Harpoon and Fault-Line Shatter cancel the catastrophe through actual session handlers. Existing suites also retain other disruption coverage.
- Ordinary Kraken and other Titan attacks can still miss.
- Squid/Kraken obscurity subtracts the actual 20/25 percentage points from Standard accuracy; it adds no dodge. Misses do not disperse ink, a successful hit can clear it, Flare suppresses the penalty/dodge, and legacy deployment is blocked while illuminated.

## Seeded voyage comparison

Baseline: `dd66530`, including the fixed Serpent. Candidate: subsequent working-tree Kraken/ink patch. The baseline result is recorded in the preceding Serpent receipt. Candidate runs used the same `test/balance_audit_test.dart` and were reproduced within the full simulator suite: 1,000 fresh Standard-only voyages, other blueprints locked, base seed 42, 250 each for Reckless, Cautious, Greedy and Random; Random strategy RNG seed 777.

| Strategy | Kraken victories before → after | Average monsters before → after | Average rounds/fight before → after |
| --- | --- | --- | --- |
| Reckless | 0/250 → 0/250 | 2.6 → 2.6 | 7.2 → 7.2 |
| Cautious | 31/250 → 1/250 | 3.9 → 3.7 | 9.8 → 8.4 |
| Greedy | 0/250 → 0/250 | 1.9 → 1.9 | 9.6 → 8.8 |
| Random | 0/250 → 0/250 | 1.4 → 1.4 | 9.5 → 9.5 |

Aggregate Kraken victories fall from 31/1,000 to 1/1,000. This substantial increase in threat is recorded, not hidden by unrelated tuning. Cautious prioritizes ready weapons and only proactively fortifies an injured Ironclad; it does not time Standard's Drill for the catastrophe. These bots do not establish a human win-rate target or full-campaign balance. The default audit stops after the first Kraken. Keep the accepted 38 base damage for player evaluation; broader boss difficulty and PT2-22 tentacle/regional scaling remain open.

## Player follow-up after implementation

The player subsequently defeated the Kraken, reporting roughly 30% hull remaining before a last-turn Hull Patch Kit brought it to roughly 50%. The voyage included three blessing shrines, a Tier II Brinemother Signature (damage and Corroded weakening), Earthshaker-blessed rigging with a 15-HP barrier activated before impact, and several shrine/wreck choices instead of battles. The player explicitly identified both the strong blessing build and avoided chip damage as factors. Blueprint, hull/weapon marks, arrival HP and permanent-upgrade state were not supplied; this must not be labeled a fresh-Standard baseline result.

The player described the Kraken as strong but appropriate for roguelite progression: early failures are expected, with mechanical learning and permanent upgrades improving later consistency. This is positive evidence for defensive timing and route/build preparation, not proof that every build has fair odds. Preserve the accepted 38-base-damage release while evaluating less shrine-favored builds, more combat-heavy routes and the separate tentacle/regional-scaling issue. The bot audit alone is not a reason to lower the damage.

## Presentation and checks

- Core: analysis clean; 390 tests passed.
- Simulator: analysis clean; 33 tests passed.
- App: analysis clean; 129 tests passed.
- Native Windows: two feedback tests passed at 115% and 130% text using readable system fallback fonts. Captures were visually inspected at `apps/monstrous_sea/build/kraken-feedback-native-1.15.png` and `kraken-feedback-native-1.3.png` (ignored local output). They verify this feedback, not the deferred command-station redesign or final themed-font presentation.
- Widget coverage additionally checks 360px and 1280px layouts at both text scales, updated Flare state/tooltips and actual controller deployment logs. An overflowing compact OBSCURED badge was replaced by the explicit inline penalty.
- Documentation checks and `git diff --check` completed with this batch. New tests and probes used isolated game state and disabled autosave; no player saves were changed.

Generated simulator report churn and temporary probes were removed from the working diff. No gameplay art was generated or replaced.
