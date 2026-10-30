# Global ship range-evasion removal — 29 October 2026

During discussion of Clipper utility upgrades, the user discovered that every ship received +15% dodge at Long range and −15% at Short. The ordinary HUD omitted that adjustment. The user approved removing the blanket modifier because it further rewarded ships already suited to Long range.

## Delivered rule

Removed only the range conditional from `EvasionTrait.onIncomingAttack`. Ship dodge still sums current evasion, the captain bonus and a live Basalt Aegis bonus, then clamps the roll threshold to 0–95%. Successful dodges still consume temporary evasion, and unavoidable attacks still bypass it. No random roll was added or skipped by the removed arithmetic. Monster threat bands, attack accuracy, weapon range damage, movement and ability cooldowns are unchanged.

Without other effects, stock Clipper is now 25% at every range and stock Ironclad is 0%. Clipper's current utility still raises its evasion to 50% until a successful dodge. Proposed Mk II/III bonuses remain unselected under PT2-30. Gold/material tuning remains separate under PT2-28/29.

## Verification

All **659 core tests**, **33 simulator tests** and **364 app tests** passed; core/simulator analysis passed. Core regressions exercise all five blueprint dodge thresholds at all three ranges through real attack resolution, captain/live/inactive Basalt bonuses, utility persistence and consumption, the 95% ceiling and unavoidable attacks. The old range-bonus assertion now checks the newly agreed behavior. Existing threat, range-damage, monster-dodge and playback checks passed.

One Sol Medium worker ran an isolated paired comparison against baseline `ea2dec20f1bcd968cab82c481669b33d4f710dc1`. The after snapshot differed only in the trait file. There were 100 seeds per hull/build/variant (`42 + 31*i`, i=0…99), totaling **2,000 starts**, using CautiousBot and a 2,500-command limit. All five hulls were unlocked solely to choose a fixed hull. Both variants began with 25 gold, ancestral I and no captain traits, initial blessings, monuments, relics, pacts or other profile progression. Normal voyage rewards, repairs, upgrades and shrine choices remained available.

Fresh starts used hull I/Mk I. The separate synthetic progressed cohort used hull IV/Mk III from the first encounter, constructed with the normal factory/tempering helpers. It is an encounter-progression control, not an attainable starting profile or an economy replay. Runs continued through the final `expeditionVictory` phase, before the Caldera choice; the ordinary simulator's first-Kraken `won` flag was not treated as campaign completion.

Counts below are **before → after**, each out of 100:

| Hull | Fresh Kraken clears | Progressed World Serpent clears | Progressed final Leviathan clears |
| --- | ---: | ---: | ---: |
| Standard | 0 → 0 | 61 → 58 | 11 → 11 |
| Ironclad | 1 → 1 | 39 → 45 | 4 → 12 |
| Clipper | 0 → 2 | 58 → 67 | 14 → 16 |
| Bombardier | 42 → 41 | 65 → 66 | 15 → 15 |
| Corsair | 9 → 11 | 69 → 79 | 12 → 23 |

Fresh final campaign clears were zero in both variants; progressed Kraken clears were 100 for every hull in both. All starts ended in death or final victory, with zero exceptions or command-limit outcomes. Removing the Short penalty can improve some outcomes even as Long loses its bonus. This is not a universal survival nerf. One bot and these two builds do not establish human win-rate targets or resolve the economy/iron concerns. Identical initial seeds do not preserve later routes or random draws once combat outcomes diverge.

The exact [audit script](evidence/range-evasion-2026-10-29/audit.dart) is retained as experimental verification evidence, not production gameplay. To reproduce, create isolated copies of core/simulator at the baseline and with only the approved trait change, copy the script to each simulator's `bin/range_evasion_audit.dart`, resolve cached dependencies, and run `dart run bin/range_evasion_audit.dart 100` and `dart run bin/range_evasion_audit.dart 100 progressed`. The original snapshots, raw per-run JSON and expanded receipt remain in ignored `.dart_tool/range-evasion-audit/`.

Simulator tests regenerated the tracked report; its original bytes were restored and both report/CSV hashes verified. The parent reviewed the production/test diff and audit setup/results. No production saves, shared native build, save fields, UI layout, art or Goal were changed. Documentation/link and whitespace checks are part of this task's final verification.
