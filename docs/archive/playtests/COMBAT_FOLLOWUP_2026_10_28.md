# Combat follow-up — 28 October 2026

The player found the three-label stack harder to read as entries move upward, reported World Serpent Poison surviving into the next region’s crab fight, and saw “Abyssal Wyrm” in the Titan approach message. [Original Poison carryover screenshot](../../playtests/2026-10-28/01-poison-next-region-player.png).

## Delivered fixes

Ordinary outcomes now advance 400–500 ms apart, up from 300–400 ms. Text labels live 1.8–3.8 seconds, up from 1.4–3.4; their solid/fade halves each gain 0.2 seconds. Ordinary numbers hold for 0.85 seconds and fade for 0.85 seconds. Capacity and measured compact eviction still bound the stack. The 100 ms attack-name lead, independent lifetimes, state-at-impact behavior and accepted first-slow/then-fast sweep cadence are unchanged. A controlled Long → Medium helm → Short Ram now reaches impact at 900 ms without waiting for movement labels to disappear. [900 ms impact capture](../../playtests/2026-10-28/03-ram-impact-900ms.png).

ShipState.resetCombatBoosts omitted statusEffects, allowing live-session Poison/Burn/Stun to survive victory and cross encounters/regions. Combat reset now clears statuses. Non-battle in-memory snapshot restoration also clears them without healing or changing the build. Ship JSON already omits/ignores combat statuses: this was a running-session leak, not evidence that Poison persisted in normal save files. No save schema, file migration or player-save access was introduced.

Poison’s existing rules remain: default tick damage is 5×difficulty, with 25% recovery after each nonfatal tick; armor/barrier bypass and Iron Constitution remain intact. A long within-fight duration is possible under failed recovery rolls. No guaranteed duration or damage retuning was added.

Titan approach copy was hardcoded as Abyssal Wyrm in Region 2 and Leviathan Prime in Region 3, despite canonical battle names. Both now match The World Serpent/The Ancient Leviathan. The Kraken remains unchanged. Pending cached Titan offers are repaired without rerolling them, editing ordinary/Nemesis calls or rewriting completed voyage history.

## Verification

All 620 core tests, 33 simulator tests and 57 targeted app tests passed; core/simulator/app analysis and documentation/whitespace checks passed. A Sol Medium worker implemented the small core fixes and 18 deterministic regressions; the parent reviewed the actual diff. Tests cover recovery rolls 75/76/100, repeated failed recovery in one fight, actual World Serpent victory → stronghold → reload → Region 3 crab, unchanged build/HP, no spurious next-fight Poison tick, dirty in-memory and serialized checkpoint handling, and all three Titan approach/battle identities plus cached offers. Terminal event snapshots preserve the final impact’s preceding effects.

App checks cover updated 900 ms movement timing, opaque text at 880 ms while later damage is already displayed, eventual expiry, normal/reduced motion, compact stacking, the real 12-hit sweep and Pause/flow/belt/art recovery. Two focused font-loaded scenarios also passed. The [880 ms capture](../../playtests/2026-10-28/02-label-solid-880ms.png) was visually checked using Georgia and the production renderer. These are isolated widget checkpoints, not a native player replay.

The simulator’s seeded 1,000-voyage audit passed and its pre-existing generated report was restored byte-for-byte. A paired comparison used 250 voyages per strategy with base seed 42 and RandomBot seed 777, Standard-only unlocked profiles, and the default stop after the first Kraken. The isolated before-core copy preserves all preceding work and restores only this follow-up’s three changed core files to their pre-fix contents; working sources were never reverted. Wins were unchanged (0/1/0/0); average monsters defeated changed as follows:

| Strategy | Before | After |
| --- | ---: | ---: |
| Reckless | 2.680 | 2.848 |
| Cautious | 3.736 | 3.748 |
| Greedy | 2.052 | 2.068 |
| Random | 1.516 | 1.492 |

The comparison checks impact of status cleanup; it does not establish later-region or World Serpent balance. The cross-region deterministic regression verifies that reported lifecycle separately. Raw comparison JSON and the audit report remain in ignored .dart_tool outputs. No production player saves or shared Windows executable were touched; all pre-existing changes remain intact. Broader layout/art work remains separate, and player replay is still needed for label pacing.
