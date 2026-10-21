# Tentacle scaling and counterplay verification — 20 October 2026

Historical PT2-22 receipt. Current rules belong in `docs/CURRENT_GAME.md`; these results are evidence, not a second balance specification.

## Initial limb/HP change, before continued damage growth

The player approved ordinary squid growing from 4 to at most 8 tentacles, Apex adding 2, and Kraken having 12 while retaining its default 300 HP and 38-base-Blast maelstrom. Ordinary squid start at 40 HP and gain 20 per additional level. These are starting values for player evaluation.

| Encounter | HP before → after | Tentacles before → after | All-hit base sweep before → after |
| --- | --- | --- | --- |
| Late R1, level 4 squid | 180 → 100 | 20 → 7 | 60 → 21 |
| Opening R2, level 5 squid | 225 → 120 | 25 → 8 | 100 → 32 |
| Opening R2 Apex squid | 293 → 156 | 30 → 10 | 120 → 40 |
| Late R2, level 8 squid | 360 → 180 | 40 → 8 | 160 → 32 |
| Opening R3, level 9 squid | 405 → 200 | 45 → 8 | 180 → 32 |
| Default Kraken | 300 → 300 | 25 → 12 | 100 → 48 |

The old sweep could instead randomly select one Ram hit. The table describes the old full tentacle branch, not every old attack. The new sweep selects a Tentacle weapon consistently and attacks once per intact limb. Other squid intents retain their existing attack selection; the Kraken maelstrom remains a separate fixed attack. Per-tentacle damage, hit/dodge mechanics, armor and the other species' regional formulas were not retuned.

## Counterplay and presentation

Bombardier's Slicing Howitzers and Corsair's Chain-Shot/Harpoon retain severing. Standard, Ironclad and Clipper are not given a new severing property. All hulls can retreat to Long before a Short/Medium sweep; bracing, armor, barriers and weakening remain useful. Each severed limb now removes a larger fraction of a smaller barrage. Missing Tentacle armament does not substitute a Ram. Zero-limb sweeps produce narration rather than a fabricated miss.

The live preview shows strike count, per-hit base Blast and a gross maximum before hit/dodge rolls and defenses. Severing updates it immediately; helm escape previews zero damage. Widget tests check 360px/1280px and 115%/130% text. Two native Windows checks using readable system fallback fonts passed, and their captures were visually inspected at `apps/monstrous_sea/build/tentacle-feedback-native-1.15.png` and `tentacle-feedback-native-1.3.png` (ignored local output). This does not complete the deferred command-station redesign or final themed-font review.

## Isolated encounter comparison

Baseline engine: `d9efae6`, with the same new `packages/monstrous_sim/bin/audit_tentacles.dart` harness present before tuning. Candidate: subsequent working-tree implementation. Run from the simulator package with `dart run bin/audit_tentacles.dart 100`.

Each version runs 240 cells / 24,000 battles: five blueprints × six encounter types × stock or Hull-II/Mk-II × fire-only or simple helm/utility tactics × intrinsic or removed-starting-armor control × 100 seeds (`42 + 31*i`). Encounters enter through real course/session handling, including regional hazards. Each starts at full health; no blessings, consumables, permanent stat upgrades or unavailable Master Refits are supplied. Removed-starting-armor controls still allow utilities to build armor. Seeds and policies match, though removing the random sweep selection deliberately changes subsequent RNG consumption.

Representative victories per 100 for Hull-II/Mk-II, intrinsic armor and helm/utility tactics:

| Blueprint | Opening R2 before → after | Apex R2 before → after | Late R2 before → after | Kraken before → after |
| --- | --- | --- | --- | --- |
| Standard | 92 → 99 | 41 → 95 | 12 → 74 | 1 → 1 |
| Ironclad | 100 → 100 | 100 → 100 | 100 → 100 | 100 → 100 |
| Clipper | 96 → 100 | 67 → 97 | 26 → 85 | 0 → 0 |
| Bombardier | 98 → 100 | 79 → 99 | 40 → 92 | 99 → 99 |
| Corsair | 66 → 100 | 25 → 97 | 4 → 91 | 79 → 82 |

In the opening-R2 cell, Standard's mean remaining hull fraction across all outcomes rises from 0.318 to 0.639; Clipper from 0.454 to 0.708; Corsair from 0.227 to 0.709. Ironclad's armor/utility advantage remains intentional. Baseline has 10 unfinished stock Ironclad Apex-R2 fights at the 240-command guard; candidate has none. This is not evidence that the old fights were engine soft locks.

The simple tactics are not optimized and these results are not voyage or human win rates. In particular, unblessed Standard/Clipper still perform poorly against Kraken in this policy, and opening-R3 Hull-II/Mk-II results remain difficult. Do not retune all other attacks or maelstrom damage to equalize these cells. Player evaluation should include actual accumulated damage, blessings, consumables, routing and later hull/weapon progression.

## Voyage audit and checks

The existing 1,000-voyage audit also passed: 250 fresh Standard voyages each for Reckless, Cautious, Greedy and Random, base seed 42, Random strategy seed 777, other blueprints locked. Aggregate Kraken victories move from 1/1,000 at `d9efae6` to 3/1,000 (Cautious, Greedy and Random each 1/250). It stops after the first Kraken and does not establish later-region balance. This receipt does not compare these simple bots directly with the player's shrine-heavy successful run.

- Core analysis clean; 421 tests passed, including all-blueprint stock/upgraded sweep damage, armor, severing, helm escape, regional spawning, zero/missing limbs and unchanged maelstrom coverage.
- Simulator analysis clean; 33 tests passed, plus the separate 24,000-candidate encounter audit.
- App analysis clean; 133 tests passed, including live barrage updates and existing sprite/resize checks with the new Kraken count.
- Native Windows: two feedback tests passed at 115% and 130% text.
- Documentation and diff checks passed. New tests/audits used isolated state and no production saves. Generated reports and probe output are excluded from the working diff; no gameplay art was created or changed.

## Accepted follow-up: continued per-tentacle damage growth

After reviewing the original damage plateau, the player approved preserving early damage and adding one point every two levels: 5 at levels 7–8, 6 at 9–10, and 7 at 11–12. Levels 1–2 retain their 2–3 roll; levels 3–4 remain 3 and levels 5–6 remain 4. The previously approved smaller limb pools and HP remain intact. Default level-5 Kraken remains 12 × 4 with its independent 38-base-Blast maelstrom. No additional Apex per-hit multiplier is introduced.

| Ordinary squid stage | Per-tentacle base damage | Full 8-limb sweep before avoidance/defenses |
| --- | --- | --- |
| Levels 5–6 | 4 | 32 |
| Levels 7–8 | 5 | 40 |
| Levels 9–10 | 6 | 48 |
| Levels 11–12 | 7 | 56 |

This supersedes the later-region damage totals in the initial comparison table above. The actual generator follows `2 + ((level - 1) ~/ 2)` after level 2. Current ordinary region levels end at 12; later hypothetical difficulties have not been balanced by this audit.

The same unchanged audit harness and 100 seeds per cell were rerun for another 24,000 encounters, comparing the preceding smaller-pool/4-damage stage with this curve. All 160 cells for late R1, Kraken, opening R2 and Apex opening R2 are identical. There are no command-limit outcomes in either of these two smaller-pool stages.

Hull-II/Mk-II, intrinsic armor, helm/utility victories per 100:

| Blueprint | Late R2, 4 → 5 damage | Opening R3, 4 → 6 damage |
| --- | --- | --- |
| Standard | 74 → 72 | 33 → 33 |
| Ironclad | 100 → 100 | 3 → 3 |
| Clipper | 85 → 85 | 38 → 35 |
| Bombardier | 92 → 92 | 62 → 62 |
| Corsair | 91 → 91 | 60 → 55 |

Mean remaining hull across all outcomes falls even in some cells with unchanged victories: late-R2 Standard 0.278 → 0.263; opening-R3 Bombardier 0.259 → 0.245. Helm avoids many sweeps, so fire-only cells show a greater effect: opening-R3 upgraded Bombardier falls from 26 to 9 victories, and Corsair from 15 to 10. These are intentionally simple tactics, with no blessings/consumables, and the same limitations as the initial comparison apply. Do not infer full-campaign fairness or a human target win rate from them. The matrix measures level 8 and 9 effects; level 11/12 damage is covered deterministically, not by a new late-R3 matrix cell.

Armor remains a deliberate counter. Hull-II Ironclad's 6 flat reduction can nullify the 5-damage level-8 limbs, while other attacks and regional hazards remain relevant. No minimum damage or armor bypass was added to force every sweep through it.

Follow-up verification: core analysis clean and 441 tests passed; simulator analysis clean and 33 tests passed; app analysis clean and 133 tests passed. Twenty new all-blueprint tests resolve actual level-7/9/11/12 sweeps, including per-hit armor; the content test covers every level 1–12. The existing compact/desktop 115%/130% preview tests now use a real level-12 squid and verify 8 × 7 = 56, then 3 × 7 = 21 after severing. The existing 1,000 fresh-Standard voyage audit remains exactly at 3 Kraken victories (one each for Cautious/Greedy/Random), as expected for unchanged first-region damage. Native Windows visuals were already checked for the unchanged layout in the initial batch; they were not rerun for this formula-only follow-up.


## Later correction — inherited UI fixtures were not fully isolated

An audit on 20 October 2026 found older UI/art fixtures with default autosave and no injected storage. Full app test runs that included those fixtures could overwrite production profiles with fixture data, including unpaid blueprint unlocks. Earlier blanket statements that verification left production saves untouched were not established for those runs; the passing test counts above do not prove isolation. The specialized tests that explicitly disabled autosave/injected storage remain distinct from that inherited full-suite risk. The fixtures are now corrected and a tested per-suite disposable storage fallback protects future default controllers. See the test-save isolation and battle-art receipt in the archive index and PT2-27 in the live backlog. No historical test result is being relabeled as a storage-isolation check.
