# Flutter/Flame versus Godot: bounded combat presentation comparison

**Recommendation: retain Flutter/Flame for the planned combat work. Godot is a viable alternative and had a simpler launch cycle, but this comparison did not demonstrate enough presentation or maintenance benefit to justify porting the game.**

This is evidence from a small code-driven fixture, not a general engine ranking. Neither presentation is an approved combat UI design. No migration, gameplay port or production UI change was started.

## Recordings

All four recordings contain actual native Windows-rendered frames, 1000×620, encoded at 30 fps. No headless renderer, web substitute or synthesized game imagery was used.

| Engine | Baseline: 1×, simultaneous barrier/hull update | Revised: 2×, absorption before hull damage |
| --- | --- | --- |
| Flutter 3.47.0 / Flame 1.38.2 | [Baseline video](evidence/flutter/baseline/recording.mp4) | [Final revised video](evidence/flutter/revised-final/recording.mp4) |
| Godot 4.7.2 / GDScript | [Baseline video](evidence/godot/baseline/recording.mp4) | [Revised video](evidence/godot/revised/recording.mp4) |

Baseline recordings are 10.03 seconds, revised recordings 5.03 seconds. The 2× setting is a maintenance test, not a proposed default pace. Presentation details differ slightly (waves, impact shape, text arrangement); the supplied facts, font, art, geometry requirements and requested timing change are shared.

## What was tested

Both implementations consume [the same JSON fixture](fixture.json) and identical copies of the approved Standard ship and serpent art. Outcomes are synthetic presentation facts, not a claim that the serpent has a new four-hit attack or any new balance rule.

The sequence moves the ship from Medium to Short, deals 18 damage to the monster, grants a 10-point barrier, applies Burn, resolves four 6-point hits, triggers 4 Burn damage and expires Burn. Final state: ship 82/100, monster 42/60, barrier 0, Burn absent, Short range.

The follow-up was given only after each baseline was captured and frozen. Both were changed to consume barrier immediately, delay the hull update/red damage cue by **240 logical ms** when absorption occurred, and play at 2×. Unabsorbed hits and Burn damage remain immediate. At 2×, the 240 logical ms delay is 120 ms of video time.

The parent independently checked **904 displayed-state samples across the four final recordings**, every fixture event, intermediate movement, all PNG dimensions, shared hashes and the paired engine states. Flutter's actual HUD-builder labels/bar values were also checked against its Flame state. All four MP4s were fully decoded to verify their frame counts, dimensions and cadence. [Completion audit](completion.json).

Key images reviewed include the mixed second hit before and after the delayed hull update:

| Engine | Absorption, hull still 100 | Hull now 98 |
| --- | --- | --- |
| Flutter/Flame | [Blue absorption cue](evidence/flutter/revised-final/keyframes/absorption.png) | [Red hull cue](evidence/flutter/revised-final/keyframes/hull.png) |
| Godot | [Blue absorption cue](evidence/godot/revised/keyframes/absorption.png) | [Red hull cue](evidence/godot/revised/keyframes/hull.png) |

State receipts establish correctness of this sequence; they do not establish that all real battles will be easy to understand. A player review of the recordings remains useful.

## Development friction observed

Two separate workers used the same configured model and reasoning level, with a parent-owned contract/oracle and independent review. They worked in parallel; elapsed times are not additive and are not controlled measures of developer productivity.

| Observation | Flutter/Flame | Godot |
| --- | --- | --- |
| Authoring approach | Standalone Dart app; real Flame scene plus Flutter HUD and notifier | GDScript and text scene; direct Node2D drawing |
| Setup for this phase | Created standalone Windows project; cached dependencies | Reused official portable runtime from the earlier feasibility check |
| Compile/launch cycle | First successful native release build 51.6s; later builds roughly 21–28s | Source loaded on launch; no separate build/editor stage |
| Baseline repairs | One inherited-name collision; a trace-string edit and shell/path mistakes corrected | No scene/script repair needed |
| Requested maintenance change | About 90s including patch, analysis, build and export; revised build 20.9s | Source read/edit 19s; revised capture 17.9s, excluding documentation/review |
| Render review | Parent caught red “−0 hull” on fully absorbed hit; guarded and recaptured | Fully absorbed hits already avoided a red hull cue |
| Manual editor work | None | None |
| Environment restrictions | Two stalled restricted SDK commands stopped through their own handles; escalation worked | Restricted run reported certificate-store error; elevated environment check had empty stderr |

The Godot runtime download/checksum/setup cost was already paid in the preceding feasibility phase (about eight minutes overall); it is not treated as free migration work. The report distinguishes implementation repairs from SDK/environment friction. [Flutter baseline receipt](evidence/flutter/baseline/RECEIPT.md), [maintenance receipt](evidence/flutter/revised/RECEIPT.md), [review correction](evidence/flutter/revised-final/RECEIPT.md), [Godot receipts](godot/README.md).

Flutter's release-build path was used for reproducible native captures. **Hot reload was not measured**, so the build gap does not establish the gap in the best normal development workflow. GPU readback/PNG export times are not gameplay frame-rate measurements. Both required custom capture and trace hooks.

## What the evidence supports

- Both stacks support the specific movement, defense, multi-hit, status and synchronized-health presentation without changing gameplay rules.
- Godot's source-to-launch workflow was straightforward and avoided a separate native compilation step for this fixture.
- Flutter/Flame's two rendering/UI layers can stay synchronized when they share explicit displayed state. The current game's feedback limitations are not evidence that this is impossible.
- The follow-up required similar event-ordering concepts in both: separate absorption from subsequent hull changes. Changing engine does not remove that design requirement.
- This code-driven comparison did not exercise Godot's visual animation editor, AnimationPlayer workflow or sophisticated scene composition. Those possible advantages remain unmeasured.

## Boundaries and preservation

The comparison began `2026-10-27T05:05:09Z` (26 October 23:05:09 America/Denver), with a two-hour deadline. Actual elapsed time is recorded in [completion.json](completion.json). Work stopped after the report and verification; unused time was not spent expanding scope.

[Baseline hashes](baseline.json) cover 635 pre-existing tracked/untracked repository files, including the previous feasibility artifacts and existing user changes. The completion audit verifies no changes to them and no newly added repository files outside this evaluation. The app was never built or run from its production directory. The fixtures do not import production storage or access its saves. This is source/path isolation, not a full OS filesystem trace.

The pre-review Flutter revised run is retained in `evidence/flutter/revised/`; the final video uses the corrected `revised-final` run. Baseline/revised source snapshots and patches remain with their evidence. Raw PNG sequences and build/runtime/profile directories are local ignored outputs; MP4s and selected byte-identical keyframes are retained. No new art or sound was generated.

This did not test full gameplay, save migration, native input, sound, compact/large-text UI, extensive reactive chains, real-time capture pacing, 3D, shaders, C#, web export or production packaging. Static/keyframe inspection and state checks cannot substitute for evaluating perceived motion and comprehension.

## Reproduction

From the repository root, with the existing Flutter SDK and previous portable Godot runtime:

Repository packaging excludes the copied Windows Segoe UI font. Run `prepare.py` on Windows before building either fixture; it recreates both ignored font copies from `C:/Windows/Fonts/segoeui.ttf`. This packaging adjustment was made after the recorded comparison and does not change its captured evidence.

```powershell
python tools/evaluations/combat-presentation-2026-10-26/prepare.py
python tools/evaluations/combat-presentation-2026-10-26/godot/capture.py --run NEW_GODOT_LABEL
```

For Flutter, build the isolated app using the commands in [its receipt](evidence/flutter/baseline/RECEIPT.md), then launch its `flutter/build/windows/x64/runner/Release/combat_comparison.exe` with `--out=<absolute fresh evidence directory>`. Current sources are revised; baseline source snapshots preserve the earlier version. Do not overwrite the production application to reproduce this fixture.

The encoder uses the workspace-local `imageio-ffmpeg` 0.6.0 package in `runtime/python`; no system-wide install was made. Capture/integration commands required supported sandbox escalation in this environment.

```powershell
python tools/evaluations/combat-presentation-2026-10-26/audit_run.py godot revised --speed 2 --barrier-delay 240
python tools/evaluations/combat-presentation-2026-10-26/audit_run.py flutter revised-final --speed 2 --barrier-delay 240
python tools/evaluations/combat-presentation-2026-10-26/encode.py godot revised
python tools/evaluations/combat-presentation-2026-10-26/encode.py flutter revised-final
python tools/evaluations/combat-presentation-2026-10-26/audit_all.py
```

Godot's shorter launch cycle is a useful benefit, but this small test does not establish that it outweighs rebuilding rules integration, interfaces, persistence and verification. The recommended next development direction is a discussed, scoped improvement to combat presentation within the current stack. That work has not been started by this goal.
