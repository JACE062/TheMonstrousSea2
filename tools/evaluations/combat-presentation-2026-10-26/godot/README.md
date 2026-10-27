# Godot comparison fixture

Synthetic presentation only: `main.gd` reads the common fixture, PNG bytes and font bytes from the parent directory. It does not import production rules or saves. There is no combat engine, editor-authored animation or proposed game UI here.

Run from the repository root with:

```powershell
python tools/evaluations/combat-presentation-2026-10-26/godot/capture.py --run NEW_LABEL
```

The launcher uses the existing official portable Godot 4.7.2 executable from the earlier feasibility evaluation, normal Windows rendering with `gl_compatibility`, Dummy audio and a hidden/offscreen helper window. It sets APPDATA and LOCALAPPDATA only in the child's environment to `godot/profile`; `user://` uses custom directory `g`. No system-wide installation or production save path is involved.

The capture hook advances logical time deterministically, applies due fixture events to the same state used by `_draw`, waits for `RenderingServer.frame_post_draw`, and reads the rendered viewport to PNG. Frame `i` represents `i * 1000 / 30 * SPEED` ms. Readback/capture throughput is not a runtime performance measurement. Trace frame state is flat; its time key is `logical_time_ms`, event markers are `observed_event_markers`, and the visible transient numbers are included in `visible_feedback`.

## Baseline receipt

- Native capture: `2026-10-27T05:08:44.836597Z` to `05:09:00.860352Z`, 16.032 seconds, exit 0.
- 301 PNG frames, 1000 by 620, 30 fps logical cadence, 0 through 10000 ms, speed 1.
- NVIDIA GeForce RTX 4060 Laptop GPU, OpenGL 3.3.0 NVIDIA 596.58, Godot compatibility renderer.
- Direct GDScript/text scene authoring; no editor work, manual animation wiring, export/build step or asset-import step. The first source attempt ran successfully. No repair attempts.
- Baseline readiness was reported at approximately 05:10Z, well inside the suggested 30-minute baseline budget. This includes reading instructions and the earlier feasibility launch pattern.
- Source frozen under `../evidence/godot/baseline/source/`, with SHA256 manifest beside it. Launch command, timing, logs, state trace and focused verification are preserved there.
- Startup reports `Failed to read the root certificate store`. This did not prevent native rendering and this fixture uses no network API. No script or rendering errors appeared.
- Focused checks verified every supplied outcome at its event frame, all ten event markers, movement endpoint, final state, PNG count/dimensions, fixture hash and renderer. Visual inspection of actual frame 165 showed the second hit's separate barrier/hull numbers, HP 98 and active Burn badge.

The shared art/font remains byte-identical, loaded from the shared paths. Baseline impact feedback lasts 580 logical milliseconds and barrier/hull changes occur together at each impact.

## Maintenance receipt

The current source is revised: speed 2, with barrier consumption and blue absorption feedback at impact, then hull state and red damage feedback 240 logical milliseconds later for absorbed hits. Hits without absorption and Burn ticks remain immediate. Mixed-hit red text occupies a second line 30 pixels below absorption text, preserving all other geometry.

Source reading and editing took 19 seconds by whole-second tool-clock samples (`05:10:35Z` through `05:10:54Z`); this excludes subsequent evidence documentation and checking. No build stage or editor work was required. The first revised launch succeeded without repairs. It captured 151 frames in 17.937 seconds (`05:10:55.760330Z` through `05:11:13.701197Z`), exit 0. This is capture throughput, not game performance.

`../evidence/godot/revised/` contains the revised source snapshot/hash manifest, exact `maintenance.patch`, launch logs, trace, PNGs and verification receipt. Baseline source hashes were rechecked unchanged. All 151 displayed HP and barrier states were checked against fixture timings including the delay. Actual revised frame 87 (5800 logical milliseconds) was visually inspected for separate blue absorption and red hull feedback. The same certificate-store startup error remained; there were no script/render errors.
