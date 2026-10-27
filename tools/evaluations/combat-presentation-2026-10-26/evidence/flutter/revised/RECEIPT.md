# Flutter maintenance receipt

- Baseline frozen before edits under baseline/source (source hash in baseline receipt). Maintenance edit began~05:14:10 UTC; revised capture completed~05:15:40 UTC; about90s to patch, analyze, build and export.
- Exact change: speed1x→2x; absorbed ship impacts immediately reduce barrier and show blue absorption text. Hull state and red hull cue are scheduled for fixture event `at_ms + 240`, independent of sampling observation time. Nonabsorbed impacts and Burn remain immediate. Added `barrier_hull_delay_ms=240` to trace and cue colors; logical stepping still30fps output.
- `flutter analyze lib`: no issues (4.2s). `flutter build windows --release --no-pub`: succeeded20.9s. No maintenance code repair or manual UI intervention.
- Native executable launched using Start-Process -WindowStyle Hidden -PassThru, `--out=.../evidence/flutter/revised`; waited on this exact process. exit0; export wall9.3746111s. This is offline capture cost, not a performance benchmark.
- 151 real1000x620 PNGs. Actual revised frame83 (5533.33ms) shows HP100, barrier0 and blue absorption; frame87 (5800ms) shows HP98 and red hull2 damage. Final HP82, monster42, barrier0, Burn absent, Short, shipx420.
- Floating final timestamp is9999.999999999998ms (numerical epsilon to10000); event comparisons use0.001ms tolerance. Delayed observed_events additionally record `hit1_hull`/`hit2_hull`; per-frame event_markers retain fixture IDs. HUD labels and bars come from actual Flutter builder.
- `maintenance.patch` is the actual source diff from frozen baseline. Revised main.dart SHA2566D017B41B12FBCD15D23474CF0A21F28ECD0CA68F1F089A7110BA8BAA27DD156. Source snapshot under revised/source. Shared asset hashes verified equal in ../asset_hashes.json.
- No production files, storage, migration, engine or other evaluation implementation changed.
