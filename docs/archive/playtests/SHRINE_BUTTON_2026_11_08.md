# Boxed shrine departure — 8 November 2026

The [player screenshot](../../playtests/2026-11-08/shrine-button/01-player.png) showed “Sail past in reverence” as a bare text action. It now uses the same `InkButton` as the other shrine actions, separated from Runic Guidance by 16 logical pixels. Its label, availability and `DepartShrine` callback are unchanged.

All **nine existing Ocean Power/encounter UI cases passed**. The existing ShrineScreen fixture was also rendered with copied game fonts at 130% text for [desktop](../../playtests/2026-11-08/shrine-button/shrine-1200.png) and [compact](../../playtests/2026-11-08/shrine-button/shrine-360.png) inspection. The label is complete and the border is visible at both sizes. Temporary screenshot instrumentation was restored byte-for-byte; no new tests were added for this styling change.

App analysis, documentation and whitespace checks pass. A separate Windows Debug build is available at `.dart_tool/shrine-button-preview/build/windows/x64/runner/Debug/monstrous_sea.exe`; it was not launched. [The verification manifest](evidence/shrine-button-2026-11-08/manifest.json) records preview correspondence and hashes; [logs](evidence/shrine-button-2026-11-08/checks/) retain results. Existing builds, prior evidence, player saves, mechanics and provisional tuning are preserved.
