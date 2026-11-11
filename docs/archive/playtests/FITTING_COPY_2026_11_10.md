# Concise fitting help — 10 November 2026

The player requested removal of repeated enemy dodge from weapon help and the secondary lookout prediction from movement actions. Original screenshots are retained for [weapon help](evidence/fitting-copy-2026-11-10/player/01-target-dodge.png) and [Evasive Rigging](evidence/fitting-copy-2026-11-10/player/02-secondary-forecast.png).

Broadside/Signature tooltips keep computed opening accuracy and their direct effects. The enemy HUD retains Dodge. Fitting tooltips omit “After action” response predictions, including Rigging, Ram and Harpoon. Movement remains described by the action; the main lookout and Inspect panel retain their existing presentation. The now-unused tooltip forecast helper and its private argument plumbing are removed. No combat values, movement ordering, save data or tuning change.

The existing all-hull presentation and pointer-handoff fixtures pass with game fonts at 115% and 130%: **28 cases**. They check concise fitting messages, retained accuracy/movement effects, the enemy Dodge readout and unchanged browsing snapshots. The **66-case related regression run passes**, retaining late Skirmisher action ordering, conditional lookout/Inspect, Obscurity accuracy and effective dodge checks. Its earlier copy assertions now reflect this user selection. Formatting, analysis and documentation checks pass.

[The manifest](evidence/fitting-copy-2026-11-10/manifest.json) records sources, checks and final captures. Example: [Clipper utility at 115%](evidence/fitting-copy-2026-11-10/visual/tip-clipper-utility-1.15.png). Earlier audit receipts preserve the previously displayed forecasts as history; current guidance and D41's final selection record this follow-up.

A fresh Windows Debug preview is built separately at `.dart_tool/fitting-copy-preview/build/windows/x64/runner/Debug/monstrous_sea.exe` and was not launched. [Correspondence](evidence/fitting-copy-2026-11-10/preview-correspondence.json) verifies app/config/Windows files, bundled assets and unchanged core inputs. Player saves, the running shared build and earlier evidence/previews remain untouched.
