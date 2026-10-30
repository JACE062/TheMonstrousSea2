# Wait & Reload correction — 29 October 2026

Historical verification receipt. [Current game](../../CURRENT_GAME.md#supplies-encounters-and-upgrades) owns the implemented rule; [PT2-26](../../BACKLOG.md#pt2-26--revamp-heir-boons-and-quirks-for-current-mechanics) records the accepted correction.

The user approved removing Skirmisher's always-available Brace option and the pass's evasion bonus. The remaining **Wait & Reload** button appears for Impatient recovery or when every offensive/utility fitting action is unavailable. Its tooltip explains turn completion and cooldowns. Skirmisher still resolves committed helm after the action, and a necessary pass still resolves late helm. The internal `BraceForImpact` command remains usable by engine callers. Waiting grants no evasion, cannot accumulate a dodge boost, and does not replace an Impatient combination's required weapon action. Trait descriptions and monster counterplay no longer advertise Brace as a defensive choice.

Verification:

- All 668 core tests and 374 app tests passed; core/app analysis was clean. Six new core regressions cover repeated waits at 0/25/50/95 current evasion, an actual incoming hit without free dodge, and cooldown/late-helm resolution. Updated UI coverage checks Skirmisher availability, a ready Utility, all fittings unavailable, and clicking the grappled Impatient recovery button through complete playback.
- All 32 simulator tests outside the report-writing balance audit passed. The tracked simulator report and CSV stayed unchanged.
- Four additional font-loaded layout checks passed at 360/1280 widths and 115/130% text. Reviewed [desktop](../../playtests/2026-10-29/14-wait-reload-desktop.png) and [compact](../../playtests/2026-10-29/15-wait-reload-compact.png) recovery captures show the fallback label without overflow; compact commands scroll to it. These use the isolated Georgia/Material Icons review fixture, not a native build or final typography approval.
- Documentation and diff checks passed. Player saves, checkpoint serialization and the shared Windows build were untouched.

The paired simulation used CautiousBot, seeds `42 + 31*i` for `i=0..29`, all five forced blueprints, no Boon, and fixed Quirk none/Skirmisher/Impatient. All blueprints were unlocked only to select the hull. Starting builds were fresh hull I/Mk I and synthetic hull IV/Mk III, ancestral I and 25 gold; normal rewards/upgrades followed. Each run continued to actual expedition victory or death, with a 2,500-command cap. The two 900-start snapshots shared current source, including the previously approved range-evasion removal; the baseline restored only the former evasion increment and effect capture. This did not compare against an older committed range formula.

| Per 900 starts | Former pass bonus | Bonus removed |
| --- | ---: | ---: |
| Kraken clears | 506 | 508 |
| World Serpent clears | 285 | 279 |
| Full expedition clears | 61 | 57 |
| Deaths | 839 | 843 |
| Pass commands | 3,538 | 3,297 |
| Exceptions / command caps | 0 / 0 | 0 / 0 |

Only Impatient issued passes under this bot policy. Fresh Impatient expedition clears were 1/150 → 0/150; progressed Impatient were 13/150 → 10/150. Every non-Impatient result row was identical between versions. This is a bounded check of bonus removal, not a human win-rate target or a test of the former Skirmisher UI exception.

Experimental evidence: [audit script](evidence/wait-reload-2026-10-29/audit.dart), [summary](evidence/wait-reload-2026-10-29/summary.json), and [isolated source difference](evidence/wait-reload-2026-10-29/source-diff.patch). Preparation, execution, summarization and verification scripts plus source hashes are retained beside them. For reproduction on a checkout without audit snapshots, copy these scripts into `.dart_tool/wait-reload-audit/`, run its `prepare.py` from the repository root, copy `audit.dart` into each generated `monstrous_sim` snapshot, then use the ignored directory's `run.ps1`. Existing snapshots are preserved by refusing replacement. Raw results and package snapshots remain ignored under that directory. Verification checked snapshot hashes, each simulator's own core binding, identical audit scripts, the exact two-statement baseline difference, and unchanged non-Impatient rows. These scripts/results are evidence, not production rules.
