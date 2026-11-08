# Encounter button consistency — 8 November 2026

The user requested a sweep of the remaining encounter screens after the shrine departure correction. Four bare text actions now use compact boxed `InkButton`s, preserving their labels, keys, callbacks and enabled-state conditions:

- Combat artwork recovery: Retry Art / Loading Art, with a small gap below its notice.
- Impatient's Utility + Weapon combination, with spacing below the utility fitting.
- Home-port blueprint dialog Close.
- Home-port Covenant/monument dialog Close.

## Audit scope

Source review covers battle, helm/chart, shrine, wreck, smuggler, merchant, respite island/Haven/final refit, rest, stronghold, loot, Caldera outcome and voyage-ending screens, plus their shared supply, inspection, material trade and shipwright widgets. Existing actions there already use `InkButton` or deliberately styled selected cards/icon controls. No encounter `TextButton` remains. The remaining raw text-button references belong to title/lineage, settings and development-launcher UI.

No gameplay, persistence, navigation, prices, artwork or provisional tuning changed. Existing builds, player saves and earlier evidence are preserved.

## Verification and limits

- **33 existing app UI cases passed:** battle-art failure/retry/playback, expanded captain roster, blueprint drafting/unlock/commissioning and Covenant/relic/monument actions. Analysis and formatting are clean. No new regression tests were added for these reversible styling changes.
- **Twelve font-loaded captures** retain 360/1280 combat at 115–130% text, and 360/1200 port dialogs at 130%. Visually inspected [compact Impatient](evidence/encounter-buttons-2026-11-08/visual/impatient-360-1.3.png), [desktop Impatient](evidence/encounter-buttons-2026-11-08/visual/impatient-1280-1.3.png), [compact Retry Art](evidence/encounter-buttons-2026-11-08/visual/retry-360-1.3.png), [desktop Retry Art](evidence/encounter-buttons-2026-11-08/visual/retry-1280-1.3.png), [compact blueprint Close](evidence/encounter-buttons-2026-11-08/visual/blueprint-close-360.png) and [desktop monument Close](evidence/encounter-buttons-2026-11-08/visual/monument-close-1200.png). The existing Flame placeholder text has an unloaded font in the retry captures; the Flutter action being checked is readable.
- The initial combined font-capture run was interrupted after 32 completed cases when the Covenant fixture stalled. Isolated font setup then passed all **four existing Impatient timing cases**. An isolated desktop Covenant capture/dismissal also passed. Temporary capture hooks were restored byte-for-byte, and all controllers used disposable unsaved state/copy-cached fonts.
- **Separate existing compact Covenant defect:** the [360-pixel capture](evidence/encounter-buttons-2026-11-08/visual/monument-close-360.png) and failing isolated log show horizontal overflow in the dialog heading, tab rows and monument layout at 130% text. Those rows are unchanged in this commit; the new boxed Close button remains visible. This is recorded as open work in the current backlog, not presented as a passing compact-dialog check. The desktop version fits.
- A separate Windows Debug build succeeded at `.dart_tool/encounter-buttons-preview/build/windows/x64/runner/Debug/monstrous_sea.exe`, without launching it. [The manifest](evidence/encounter-buttons-2026-11-08/manifest.json) retains source/asset/lock correspondence and capture/build hashes; [raw logs](evidence/encounter-buttons-2026-11-08/checks/) retain the passing, failed and interrupted runs. Documentation and whitespace checks pass.
