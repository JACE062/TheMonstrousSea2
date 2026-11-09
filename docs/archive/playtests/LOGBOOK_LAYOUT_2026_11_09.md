# Voyage log and combat Chronicle layout audit — 9 November 2026

The user requested the same 115% layout review for the voyage log and combat Chronicle, including long entries, expanded details and scrolling. Both existing views show their complete entries rather than per-entry expanders. This audit exercises their full details and long multiline accounts without introducing a new expansion interaction, rewriting messages or changing their history scope.

## Findings and changes

The first valid **33-case baseline passed 24 cases and failed nine**: in history-reading, live-update and resize states, Latest Messages covered the bottom of the Chronicle's text viewport at every reviewed size. The retained compact screenshot shows the control obscuring a long beast account. It now occupies a small footer beneath that scroll area, above the existing fixed Close action. Returning to latest removes the footer and restores live following.

A separate six-case keyboard probe found Page Up/Page Down did not scroll either open log. The Chronicle now uses a dialog-owned controller exposed above its focus/close controls through `PrimaryScrollController`; its log view uses that same controller and removes its listener on unmount. The route disposes the controller only after removal completes. The shared voyage panel explicitly uses its primary reading scroll, which also enables keyboard paging for vessel inspection. Pointer/touch scrolling, the Chronicle's transient bookmark and controller ownership are verified together.

The voyage log's card layout, full bearing/outcome/species details and fixed boxed Close Logbook action passed without resizing or shortening text. Chronicle title, actor badges, ambient/critical styling and full messages retain their existing sizes and appearance. Long accounts remain scrollable from their opening through their final line. No new gameplay command or save field was added.

## Coverage and results

| Matrix area | Cases |
| --- | ---: |
| Fifteen log/input states × three sizes at 115%, atmospheric font | 45 |
| Same states/sizes at 115%, plain font | 45 |
| Seven demanding states × three sizes × both fonts at 130% | 42 |
| Three mobile-style states × two scales × both fonts | 12 |
| Additional long vessel/beast/ambient accounts, critical and ordinary | 15 |
| **New matrix** | **159** |

Desktop/compact sizes are **360×900, 800×480 and 1280×850**. Mobile-style cases use **360×760** with Android scroll behavior and touch dragging. The atmosphere-font run loads cached Pirata One/IM Fell English; Flutter's bundled Roboto and Material Icons support plain-font/offline cases. Primary entry fixtures use 240 mixed variable-height Chronicle entries and a 39-arrival, three-region voyage history; a focused two-card view includes a Nemesis victory and recovered wreck cargo with an Apex fight. Full destination/outcome/bearing/species details are verified through the normal helm and stronghold-chart log openers. Fixture histories are layout inputs, not claims of a newly approved encounter schedule or balance replay.

The long name is “Alexandrina Waverley-Montgomery of the Saltbound Watch,” paired with an extended Nemesis identity. A five-paragraph account is taller than compact reading areas. Cases cover empty/short/full logs; all three Chronicle actors; critical/ordinary messages; touch drag, wheel, scrollbar drag and keyboard paging; long-entry start/end; resize; append while following; append while reading; close/reopen; Latest Messages; fixed Close positions and Escape/focus restoration. Profile, ship, chart, phase, playback flag and monster HP snapshots remain unchanged. Existing entries retain their exact objects/text; only explicitly injected live-update entries are appended by the fixture.

**All 159 layout cases pass with game fonts.** The matrix plus 37 existing regressions pass offline (196 cases), as do 87 shared-panel inspection regressions: **283 total**. Related tests retain the real voyage-reset boundaries, same-voyage continuity, battle playback/input blocking, focus/dismissal and shared-panel inspection checks. Exact suite counts and outputs are retained in [the manifest](evidence/logbook-layout-2026-11-09/manifest.json).

## Evidence and limits

Selected proofs: [obscured history before](evidence/logbook-layout-2026-11-09/visual/before/log-chronicleReading-360-1.15-ink-2-true-reading.png), [separate footer after](evidence/logbook-layout-2026-11-09/visual/final/log-chronicleReading-360x900-1.15-ink-2-true-windows-reading.png), [short landscape at 130%](evidence/logbook-layout-2026-11-09/visual/final/log-chronicleReading-800x480-1.3-ink-2-true-windows-reading.png), [full account opening](evidence/logbook-layout-2026-11-09/visual/final/log-chronicleDetails-360x900-1.15-ink-2-true-windows-detail-start.png) and [full voyage details](evidence/logbook-layout-2026-11-09/visual/final/log-voyageDetails-360x900-1.15-ink-2-true-windows-open.png).

The initial fixture compile/scope probes and footer/detail compile probes are retained separately from application findings. The fixture needed the existing button's actual focus API, a supported monster snapshot field, a scoped Nemesis finder and the decorated ambient-message matcher. The `before` proofs use the initial valid baseline, `first-fix` shows the footer correction, and `final` uses the complete source/coverage. All controllers are autosave-disabled and use generated in-memory sessions; no live profile path, player departure, trade or combat action is invoked by this layout fixture.

A fresh Windows Debug preview is built at `.dart_tool/logbook-layout-preview/build/windows/x64/runner/Debug/monstrous_sea.exe` and was not launched. [Preview correspondence](evidence/logbook-layout-2026-11-09/preview-correspondence.json) checks the copied app/config/Windows source, bundled art, unchanged core inputs and build hashes. Native scrolling feel remains useful player replay. Earlier previews/evidence, approved art/copy, player saves, combat effects, voyage cadence and provisional tuning remain unchanged.
