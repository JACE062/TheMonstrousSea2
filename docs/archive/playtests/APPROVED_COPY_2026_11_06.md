# Approved player-copy selections — 6 November 2026

Applied the user's 30 approved IDs from the [copy review](../../design/player-copy-review.md). C02, C17, C28, C29, C31 and C35 remain unchanged and awaiting clarification; none is treated as declined. The current review preserves every stable ID and records each decision state.

The changes shorten headers, service/inspection guidance, merchant navigation, wreck/loot copy, shrine/Covenant descriptions, save-menu explanations and settings captions. Header progress counters remain in the optional log/tooltips. Resource values, stock, prices, healing, duration/limit rules, irreversible choices, save behavior and lore are unchanged. Ironclad combat and inspection wording now share `ironPlatesDescription`, with the same fitting-derived amount as before and an explicit rest-of-battle duration.

## Verification

- **452 app tests passed**, with clean app analysis.
- **24 font-loaded UI checks passed**, covering representative compact/wide chart, shore, merchant and inspection layouts at established text scales. Selected captures were inspected.
- **Windows Debug build succeeded** in `.dart_tool/approved-copy-preview/`, with exact final app sources/assets, matching lockfile and the same unchanged local core package. The agent compiled but did not launch it. Earlier bundles/previews and player saves are preserved.
- Existing flow-test finders were updated for approved labels; no new tests merely duplicate the copy. Core/simulator code and approved art are unchanged, so their suites and balance comparisons were not repeated.
- The six pending passages are compared with the pre-change source and retained byte-for-byte as normalized source text. The [manifest](evidence/approved-copy-2026-11-06/manifest.json) records approval IDs, pending-text checks, source/artifact hashes, final check output and isolated native verification. Earlier audit/evidence files remain unchanged.

Code commit: `3766247f690aab15cbc97ea21ceddd63a854848b`. Documentation and evidence are recorded separately. The six clarification questions are the only open copy decisions in this batch; no permission is inferred from elapsed time.
