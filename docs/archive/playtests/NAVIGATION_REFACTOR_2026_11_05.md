# Navigation refactor verification — 5 November 2026

Implemented WP0–WP6 under the user’s Goal. Mechanics follow the accepted navigation plan; numbers remain provisional. No production saves or prior October audit evidence were changed. The user chose offered encounter progression and will remove old saves themselves; no new migration engine was added. This report is evidence, not an instruction source or approval of final balance.

## Method and reproducibility

Each income bundle has 10,800 trajectories: 200 matched seeds (base 20261105, stride 31), three routing policies, six builds and three explicit modes. LIVE preserves real combat and death. Mild attrition REPLAY substitutes 15/22/30 ordinary hull loss by region; harsh REPLAY uses 30/40/50. Both use 35/50/70 Titan loss, force creature settlement, clamp the hull at 1 and count otherwise fatal shortfalls. Replay completion means assumed access to the full route. It is never a win-rate observation. Every recovery, upgrade, shop purchase and cargo claim still uses core commands.

All builds use Standard. Progressed adds Tier II ancestral signature and carried 6 glass/4 bone/2 iron/1 barnacle, without inherited gold or monument grants. Other cells isolate Carpenter, Exacting, their combination, or zero cove weight (the latter transfers three points to hunt). Policies share limited combat tactics, prioritize a favored broadside, buy hull/fitting upgrades and repairs, use kits, shop within a reserve, and differ in heading/risk preferences. They do not represent human skill or optimize all blessings. The default simulator’s historical `won` flag is not used: terminal phase and all three Titans are tracked directly.

From `packages/monstrous_sim`, reproduce with `dart run bin/navigation_audit.dart NEW_OUTPUT_DIRECTORY 200` and `dart run bin/matched_encounter_audit.dart NEW_OUTPUT_FILE.json.gz`. Add `initial-income` after the seed count to reproduce the initial bundle; 108 reproduced trajectories matched its retained outcomes and complete ledgers. Existing receipt paths are refused. `tools/analyze_navigation_audit.py` produces this summary. Source hashes, parameters, CSVs, compressed raw receipts, checks and visual captures are retained in the [evidence directory](evidence/navigation-refactor-2026-11-05/manifest.json).

## Income comparison and retained provisional bundle

Initial normal bands were 40–50 / 70–90 / 100–130g. Revised bands are **40–50 / 55–70 / 70–90g**. Apex remains ×1.5; Titans use twice their own normal regional roll, without a second Apex multiplier. Upgrade cost remains 1,390g; no corpse loot, safety rule or material coverage was removed. The initial mild danger replay reached full upgrades in Region 2 in 26/200 fresh trajectories. The revision removes that early completion in this sample and leaves mixed-route completion concentrated at Region 3 final preparation. Danger routes still tend to max at the Region 3 midpoint: this is an unresolved pacing sensitivity, not proof that every route meets the target.

| Bundle (mild replay) | Policy | Max R2 | R3 start | R3 midpoint | R3 final prep | Unmaxed | Earned g | Upgrade g | Final g |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| initial | conservative | 0 | 0 | 7 | 64 | 129 | 1708.1 | 1060.2 | 448.9 |
| initial | mixed | 0 | 2 | 135 | 62 | 1 | 2470.3 | 1387.5 | 801.0 |
| initial | danger | 26 | 46 | 124 | 4 | 0 | 3133.7 | 1390.0 | 1426.1 |
| revised | conservative | 0 | 0 | 0 | 3 | 197 | 1327.0 | 846.9 | 276.6 |
| revised | mixed | 0 | 0 | 23 | 142 | 35 | 1897.2 | 1302.5 | 367.1 |
| revised | danger | 0 | 3 | 157 | 40 | 0 | 2407.8 | 1390.0 | 723.1 |

Avoiding fights can leave the conservative route unable to finance full upgrades. Aggressive routes earn more, but their real survival is much worse in this bot sample. The revision is a bounded provisional response to income/pacing evidence, not tuning combat to a target human win rate.

## Real combat outcomes, including early deaths

| Build | Policy | N | Kraken crossed | Full completion | Deaths | Error/limit | Earned g | Spent g |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| fresh | conservative | 200 | 23 | 0 | 200 | 0 | 150.7 | 103.3 |
| fresh | mixed | 200 | 20 | 0 | 200 | 0 | 182.3 | 115.7 |
| fresh | danger | 200 | 1 | 0 | 200 | 0 | 182.5 | 108.5 |
| progressed | conservative | 200 | 43 | 0 | 200 | 0 | 186.3 | 142.0 |
| progressed | mixed | 200 | 33 | 0 | 200 | 0 | 215.9 | 161.3 |
| progressed | danger | 200 | 2 | 0 | 200 | 0 | 213.5 | 141.4 |
| carpenter | conservative | 200 | 22 | 0 | 200 | 0 | 151.3 | 104.5 |
| carpenter | mixed | 200 | 23 | 0 | 200 | 0 | 185.5 | 119.6 |
| carpenter | danger | 200 | 1 | 0 | 200 | 0 | 184.2 | 108.0 |
| exacting | conservative | 200 | 31 | 0 | 200 | 0 | 161.1 | 120.4 |
| exacting | mixed | 200 | 28 | 0 | 200 | 0 | 197.6 | 139.1 |
| exacting | danger | 200 | 1 | 0 | 200 | 0 | 188.8 | 118.0 |
| combined | conservative | 200 | 35 | 0 | 200 | 0 | 165.4 | 122.2 |
| combined | mixed | 200 | 35 | 0 | 200 | 0 | 205.6 | 146.2 |
| combined | danger | 200 | 3 | 0 | 200 | 0 | 195.0 | 122.1 |
| noCove | conservative | 200 | 22 | 0 | 200 | 0 | 153.1 | 105.5 |
| noCove | mixed | 200 | 18 | 0 | 200 | 0 | 195.4 | 134.5 |
| noCove | danger | 200 | 3 | 0 | 200 | 0 | 190.2 | 112.9 |

No LIVE trajectory completed all three regions. There is therefore no live survivor cohort from which to estimate late-game affordability or fairness. Raw Titan snapshots record actual HP/build/purse when reached; absent later arrivals are not silently replaced with replay values. Player replay must assess early attrition, later difficulty, compulsory-service pressure and the value of different builds. No boss nerf or extra bailout was added to manufacture bot completions.

## First Haven and recovery budget

| Mode | Policy | R1 Haven arrivals | Afford fitting + quote | Afford hull + quote | Paid work | Paid HP | Careen HP | Refit HP | Kits got/used | Full-belt kit uses | Fatal replay shortfalls |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| live | conservative | 148 | 139 | 106 | 21.7 | 21.7 | 13.2 | 13.0 | 1.0/1.0 | 0.03 | 0.00 |
| live | mixed | 140 | 136 | 121 | 19.6 | 19.6 | 13.5 | 16.5 | 1.1/1.1 | 0.03 | 0.00 |
| live | danger | 126 | 126 | 121 | 11.7 | 11.7 | 14.3 | 19.8 | 1.2/1.2 | 0.04 | 0.00 |
| attritionReplay | conservative | 190 | 178 | 133 | 196.4 | 196.4 | 69.5 | 99.5 | 4.8/4.6 | 3.94 | 0.00 |
| attritionReplay | mixed | 199 | 199 | 187 | 220.3 | 220.3 | 94.7 | 141.2 | 7.5/7.1 | 6.39 | 0.00 |
| attritionReplay | danger | 199 | 199 | 195 | 207.8 | 207.8 | 93.7 | 150.0 | 9.9/9.1 | 8.37 | 0.00 |
| harshReplay | conservative | 183 | 170 | 82 | 293.4 | 293.4 | 122.9 | 91.2 | 4.7/4.5 | 3.88 | 0.86 |
| harshReplay | mixed | 197 | 196 | 132 | 360.8 | 360.8 | 147.3 | 107.8 | 7.2/7.0 | 6.29 | 2.67 |
| harshReplay | danger | 198 | 198 | 178 | 351.2 | 351.2 | 153.3 | 148.2 | 9.9/9.6 | 8.79 | 2.33 |

Affordability uses the arrival’s current paid quote before a free duty/refit, not an assumed heal or a guaranteed purchase. Work is distinct from modifier-adjusted restoration; all three free-duty counts, paid work/cost, triage, kit HP, supplies left and fixed refit growth are in each raw ledger. Mild replay has no fatal shortfalls in these cells; harsh replay exposes service/kit droughts even though its clamp still reaches the end. Means include unsuccessful/short voyages where applicable.

## Wreck versus hunt receipts

The controlled comparison has 3,600 pairs across all regions, fresh/capped builds, neutral/combined healing and all three wreck conditions. It substitutes the identical normal shark factory, opening intent and combat RNG for setup noise, then runs actual combat. Both sides must match HP, death/victory, gold, organics and tactical consumables before cargo or the audit fails. Forced normal approach ambushes deliberately isolate the extra cargo after a won identical fight; this is not an estimate of voluntary Apex risk or overall wreck safety.

| Condition | Matched pairs | Won pairs | Extra glass / win | Extra iron / win | Extra gold / win | Extra supplies / win |
| --- | --- | --- | --- | --- | --- | --- |
| pickedClean | 1200 | 482 | 1.52 | 0.08 | 2.15 | 0.32 |
| uncertain | 1200 | 482 | 2.52 | 0.45 | 5.04 | 0.67 |
| fresh | 1200 | 482 | 3.03 | 1.00 | 6.74 | 0.81 |

A won wreck fight pays strictly more because ordinary creature rewards remain intact and cargo is additional. Whole-route comparisons below include the peaceful/quick recovery opportunities and hunts forgone. The danger policy is not dominant in LIVE survival (fresh Kraken crossing 1/200 versus 23/200 conservative and 20/200 mixed), despite higher replay earnings. That does not prove wrecks balanced: no real complete-route comparison exists, and different human decisions can change the tradeoff. Keep cargo/weights provisional; do not silently remove ordinary loot or make safe services dangerous.

## Materials, purchase competition and shrine saturation

| Mild replay build | Policy | Material g | Glass/iron bought | Final glass/iron | Final bone/barnacles | Afford whole roster | Shrine opportunities/visits/dedications | All 9 blessing tiers |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| fresh | conservative | 22.7 | 0.8/0.2 | 15.8/1.0 | 26.4/4.2 | 0 | 3.94/3.65/3.65 | 0 |
| fresh | mixed | 21.8 | 0.7/0.2 | 26.8/4.3 | 39.4/6.0 | 0 | 3.90/3.63/3.63 | 0 |
| fresh | danger | 108.7 | 2.6/1.4 | 33.8/6.5 | 52.5/7.3 | 0 | 3.98/0.03/0.03 | 0 |
| progressed | conservative | 22.7 | 0.8/0.2 | 21.8/3.0 | 30.4/5.2 | 0 | 3.94/3.65/3.65 | 0 |
| progressed | mixed | 21.8 | 0.7/0.2 | 32.8/6.3 | 43.4/7.0 | 0 | 3.90/3.63/3.63 | 0 |
| progressed | danger | 108.7 | 2.6/1.4 | 39.8/8.5 | 56.5/8.3 | 0 | 3.98/0.03/0.03 | 0 |

Final inventories include carried starting resources for progressed profiles. Per-blueprint affordability and full receipts remain in the raw data; individual unlocks compete with other permanent purchases, while no mid-voyage commission is authorized. Stores use finite separate allocations with the same bounds in every region; no quota or new monster iron was introduced. Full-route shrine opportunities average well below nine, and fully saturated blessings are counted separately from early deaths.

## No-cove / poor-kit stress and remaining replay

| Mode, zero-cove scenario | Policy | Naturally ≤1 kit | LIVE/actual deaths in subset | Replay fatal shortfalls in subset | Ambushes / trajectory | Paid repair g | Triage g |
| --- | --- | --- | --- | --- | --- | --- | --- |
| live | conservative | 142 | 142 | 0.00 | 0.28 | 25.0 | 4.5 |
| live | mixed | 124 | 124 | 0.00 | 0.24 | 23.0 | 5.8 |
| live | danger | 123 | 123 | 0.00 | 0.24 | 11.7 | 5.1 |
| attritionReplay | conservative | 10 | 0 | 0.00 | 1.18 | 205.7 | 1.7 |
| attritionReplay | mixed | 1 | 0 | 0.00 | 1.06 | 244.7 | 9.0 |
| attritionReplay | danger | 0 | 0 | 0.00 | 1.35 | 212.1 | 3.5 |
| harshReplay | conservative | 8 | 0 | 1.38 | 1.18 | 316.2 | 80.6 |
| harshReplay | mixed | 0 | 0 | 0.00 | 0.66 | 396.0 | 278.4 |
| harshReplay | danger | 0 | 0 | 0.00 | 1.35 | 370.8 | 211.0 |

Poor-kit is a naturally observed subset, not a guarantee or a forced stock removal. Early-death means cannot establish adequate recovery. Player replay remains necessary for clarity, tension, voluntary Apex warnings, specialist tradeoffs and realistic repair pressure; the harsh replay’s clamped fatal events explicitly prevent a survival claim. Aggressive midpoint maxing and weak late conservative purchasing remain numerical sensitivities. Accepted mechanics are implemented; final balance approval remains open.

## Correctness and presentation verification

Core analysis and 889 tests pass; app analysis and 414 tests pass; simulator analysis and 43 tests pass. Coverage includes all cadences, hidden-plan/shrine/quirk restrictions, committed difficulty, full three-region boundary flow, wreck exactly-once creature-plus-cargo settlement, death/overflow/stale callbacks, repair rounding/first-purchase ordering, traits, fixed refits, whole-battle drilling, exact pending/carried kits, finite stock and supported checkpoints. Real Flame playback reaches loot only after the final impact and returns to wreck cargo correctly. Rendering does not consume gameplay RNG.

Font-loaded 360/1280px captures at 130% text were inspected. Helm integrates the travelled route with current choices, stable bearing geometry, visited discoveries and explicit arrival/pass/victory/cargo markers; course cards scroll independently. Full history persists across strongholds. Reduced motion restores the endpoint, keyboard access passes, and ordinary pause/save/playback gates retain regression coverage. Existing approved art is reused. No shared native Windows build or human playthrough was performed; original saves and October evidence remain untouched.
