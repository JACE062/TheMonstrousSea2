# Voyage economy audit — 30 October 2026

Historical evidence, not an implementation brief. Audited production revision: `84d5cb2dabf19af622b7418ace9f10fde35a61a5`. No production rewards, costs, route rules or player saves were changed. [PT2-28/29](../../BACKLOG.md#economy-and-utility-progression-follow-up) own open work; the [current discussion](../../design/voyage-economy.md) distinguishes the selected late-Region-3 upgrade target from unapproved tuning and service proposals.

## Source findings

- All voyage hull/fitting upgrades cost 1,390g: hull 100/250/500 and three fittings 60/120 each. Purchases are unlimited at each eligible stop. Five shipwright stops exist: three forced midpoint Havens and two post-Titan strongholds. The final stop is Region 3 leg 7/14.
- Ordinary victory gold from difficulty 5 is `floor(100 × 1.35^difficulty) + uniformInteger(0,49)`, followed by Apex and monument modifiers. The session passes actual chart difficulty, not the offered difficulty or a separate Titan bonus. Difficulty 13 pays 4,946–4,995g before modifiers, explaining the player's 4,989g receipt without an exploit.
- Wreck strongboxes pay 60–120g; Haven/cove forage pays 40–60/25–35g. Combat drops are single-use consumables with fixed value. The legacy exponential treasure generator is not the live victory path. Merchant discounts and captain gifts can create finite resale gains; neither explains the repeated late bounty scale.
- Havens offer one free careen/drill/forage duty and upgrades, not a paid repair button. Strongholds offer full paid repair; smugglers offer repeated quarter-hull repairs. Real purchased hull upgrades have class-specific capacity growth, unlike synthetic high-level factory fixtures. The audit uses actual purchases and healing quotes.
- Search Hold at a wreck is the only iron earning path: 25% for one iron, every region. Iron persists immediately through death. Titans supply their own trophies but no iron. Bombardier/Corsair cost eight iron and six barnacles each. Other iron sinks include ancestral Tier III, Covenant progression and an engine-reachable auxiliary purchase without app UI; that legacy purchase is not treated as ordinary player spending.

Relevant sources: [loot](../../../packages/monstrous_core/lib/src/rules/loot.dart), [ship costs/refits](../../../packages/monstrous_core/lib/src/content/ships.dart), [session transactions](../../../packages/monstrous_core/lib/src/session/game_session.dart), [navigation](../../../packages/monstrous_core/lib/src/rules/sea_chart.dart).

## Real-engine purchase audit

Each version used five blueprints × two progression profiles × two purchase priorities × 30 seeds (`42 + 31i`): 600 starts. Fresh profiles had ancestral I and no Idol; modestly progressed profiles had ancestral II and Idol I (+10% bounty). Both started hull I/Mk I, 25g, empty belt, no captain traits/relics/pacts. Chosen blueprints were explicitly unlocked fixtures, not claims that fresh players own all ships.

CautiousBot was wrapped to buy legal hull/fitting upgrades at Havens after shore duty and strongholds after affordable full repair. Hull-first and balanced fitting-first priorities were compared. Smuggler repair behavior was retained; no island paid repairs, partial stronghold repairs, purchases of retired weapons or player storage were used. Every run's ledger reconciled: `25 + gross income − spending = final purse`.

The baseline had 599 deaths, one complete expedition, no errors or caps. This is not a human win-rate estimate. Stock bots do not temper fittings or buy Haven hull upgrades, so their ordinary reports cannot answer this pacing question.

| Metric | Current | Reward-only candidate | Reward + final-price candidate |
| --- | ---: | ---: | ---: |
| R1 Haven visitors / any purchase | 582 / 514 | 582 / 514 | 582 / 514 |
| R2 Haven fully upgraded / visitors | 33 / 36 | 1 / 28 | 0 / 30 |
| Post-Serpent fully upgraded / visitors | 10 / 10 | 6 / 8 | 0 / 4 |
| R3 Haven fully upgraded / visitors | 4 / 4 | 1 / 1 | 0 / 0 |
| Expedition completions | 1 | 1 | 0 |
| Unaffordable smuggler quarter-repair observations | 14 | 15 | 15 |

The reward-only candidate replaced the difficulty ≥5 base with `200 + 25 × (difficulty − 4)`, preserving variance, early rewards and prices. The stronger candidate also changed final hull cost 500→1,200 and final fitting cost 120→350, for a total 2,780g build. These were isolated copied packages, never production changes. An instrumentation-only 600-start control reproduced all original rows exactly; it is a replication, not another independent cohort.

Baseline first-max outcomes were all at R2 Haven. Reward-only had one there and five first-max at the post-Serpent stronghold: the late-Region-3 target is not established. Its first-Haven purchase behavior matched baseline exactly. There was only one R3 Haven visitor across both candidates, so later-region conclusions are especially limited. Reduced repair spending also reflects earlier deaths.

The baseline completed example earned 21,504g, spent 1,390 on upgrades and 363 on repairs, and ended with 19,776g. The reward-only winner was a different seed/build, ending with 1,624g; it is not a paired winner comparison. See [completed example ledgers](evidence/voyage-economy-2026-10-30/completed_examples.json), [baseline summary](evidence/voyage-economy-2026-10-30/baseline_summary.json), and [candidate summary](evidence/voyage-economy-2026-10-30/comparison_summary.json).

## Iron opportunity model

The exact source-table model assumes survival to each endpoint, zero starting iron/spending, no traits/pacts/Nemesis, and Search Hold at every visited wreck. Uniform-heading and wreck-first routes are opportunity models, not simulated player outcomes. Ordinary offers have 15% wreck probability each; region-entry side offers are random while Dead Ahead is forced combat. Forced Haven/Titan legs provide no wreck.

Current full-campaign mean iron is 1.06 under uniform headings, or 2.74 with wreck-first selection. Wreck-first has only a 0.44% chance to reach eight iron. Eight iron requires 32 searched wrecks on average at the current drop rate.

The proposed guaranteed-one-per-Search-Hold plus two-per-Titan candidate gives uniform-heading means of 3.05 after Kraken, 6.50 after Serpent and 10.25 after a full campaign. Iron-only probability of eight is about 94% for a complete campaign or 84.5% across three independent Kraken clears. Barnacles and competing purchases are excluded, so this is not blueprint affordability. Optional route changes invalidate the current opportunity counts and require recalculation. See [source model](evidence/voyage-economy-2026-10-30/iron_access_model.json) and [guarantee comparisons](evidence/voyage-economy-2026-10-30/iron_guaranteed_candidates.json).

## Separate navigation discrepancy

Offers use leg-derived difficulty; actual monsters and gold use legacy coordinates. A real SteerCourse fixture reproduced Region 2 leg 4 offering difficulty 6 then spawning a non-Titan difficulty-9 encounter at the legacy boss coordinate. Across the baseline, 1,578 of 2,173 comparable completed battles disagreed with their offer. Audits above use actual runtime difficulty. Correcting preview versus encounter scaling needs a separate decision; no difficulty change was made. See [probe result](evidence/voyage-economy-2026-10-30/navigation_probe.json).

## Reproduction and limits

Small audit sources and summaries are retained in [the evidence directory](evidence/voyage-economy-2026-10-30/baseline.dart). To reproduce at the audited revision, copy `baseline.dart` to `.dart_tool/gold-economy-audit/baseline.dart`; run from repository root using Dart with `--packages=packages/monstrous_core/.dart_tool/package_config.json`. Resolved core/simulator dependencies are required. The two pilot scripts are archived as `prepare_pilots.py`/`compare_pilots.py`; restore them to `.dart_tool/gold-economy-audit/pilots/prepare.py` and `compare.py`. Preparation creates isolated package copies and explicit manifests. Run each generated `pilot.dart` using its generated `package_config.json`. Restore the archived `prepare_control.py` and `check_control.py` to that pilots directory as well. Generate `control.dart` with the former, run it using the production core package configuration, and verify it with the latter before running the comparison. The control only adds repair-shortfall instrumentation. Multi-megabyte all-run ledgers remain ignored and can be regenerated; completed examples are retained above.

Iron scripts are archived with `iron_` filename prefixes; restore their original `access_model.py` and `guaranteed_candidates.py` names to reproduce matching JSON outputs. They use Python's standard library only. The navigation probe is diagnostic, not a frequency estimate. A separate fixed-path budget replay was used only as exploratory sensitivity; it was not combat simulation and does not validate a new refit service or survivability.

Next verification belongs to an agreed implementation: deterministic rewards/material persistence, legal service flow, repair affordability, actual upgrade timing, representative route/build replays and player evaluation. These audit outcomes do not approve numbers, additional service stops, save grants, monster nerfs or a target bot win rate.
