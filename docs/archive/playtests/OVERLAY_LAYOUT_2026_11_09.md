# Pause, Settings, inspection and help layout audit — 9 November 2026

The user requested the same 115% layout review for Pause, Settings, vessel inspection and tooltips, including nested keyword help. This pass uses the normal pause/settings/panel widgets, cached game fonts and isolated controllers with a memory-only storage substitute. It preserves player saves, approved descriptions and artwork, gameplay effects and provisional tuning.

## Findings and changes

The 54-case baseline passed 48 cases and found two issues: the Settings heading ellipsized at 360 pixels in three settings states, and hover-opened nested help did not consume Escape before Pause in three sizes. Settings now lets its heading wrap. Open keyword explanations share a route-aware early Escape handler, closing the front card without taking focus away from a hovered control. Newer modal dialogs retain priority, keyboard repeats close one layer per event, and closing/disposal unregisters the handler.

Visual review then found a third-level keyword explanation covering an earlier card at the bottom-right desktop corner, despite free space to its left. Placement now considers every ancestor card before choosing side space. A compact viewport still uses bounded, scrollable help rather than forcing cards off-screen. New desktop assertions prevent ancestor overlap in the tested three-card stacks.

Pause and vessel inspection required no layout or copy changes. Pause continues to scroll when necessary, preserves long lineage labels, exposes save/native-exit errors and blocks dismissal while saving. Inspection keeps long ship/captain names, full fitting/blessing/relic/belt details and a fixed boxed close control, with its details scrolling above it. Settings keeps the existing text sizes, fonts and option controls; no labels or explanations were shortened for this pass.

## Coverage and results

| Matrix area | Cases |
| --- | ---: |
| Twenty overlay/input states × three sizes at 115% | 60 |
| Every session phase × compact/desktop Pause | 30 |
| Five hulls × fresh/full with each of four powers × three sizes | 75 |
| Seventeen keyword definitions × three sizes | 51 |
| Plain-font Settings/nesting × 115%/130% × three sizes | 24 |
| Four desktop corners × nested/action/native help × 115%/130% | 24 |
| **New matrix** | **264** |

Sizes are **360×900, 800×480 and 1280×850**. State coverage includes saved/unsaved Pause, unsupported checkpoints, playback, unavailable title return, save failure, pending save, rejected native exit, live scale/font changes, full belts, Mk III fittings, Tier III blessings, ancestral armament and active relics. Long names use “Alexandrina Waverley-Montgomery of the Saltbound Watch,” a longer ship name and a long lineage label. All five hulls are legitimately commissioned in the fixture; fitting/cargo capacity uses actual progression helpers.

Help checks include hover, F1 without action dispatch, keyword activation, Escape down/repeat/up, three levels of nesting, help inside the real inspection dialog, Settings above open help, edge clamping, resize bounds, complete text and reachable close controls. Native tooltips use an actual fitting description. Existing regression tests retain touch/long-press, outside dismissal, semantics, contextual values, parent ownership/disposal, real save failure and battle-playback checks. Compact nested cards may overlap because there is no side-by-side space; closing the front card exposes its parent.

**264 cases pass with cached game fonts. The matrix and 63 related existing cases pass offline: 327 total.** The offline fixture loads Flutter's bundled Roboto and Material Icons; cached Pirata One/IM Fell English provide the illustrated typography oracle, and Roboto is also loaded for plain-font switching. Assertions cover untruncated labels, viewport bounds, accessible scrolling/actions, unchanged profile/ship/chart/phase/monster state and zero gameplay-action dispatch. Native exit is intercepted and cancelled, and the storage substitute never reaches a live profile directory.

## Evidence and limits

[The manifest](evidence/overlay-layout-2026-11-09/manifest.json) records source hashes, checks, staged proofs and [preview correspondence](evidence/overlay-layout-2026-11-09/preview-correspondence.json). Selected final examples are [compact Settings](evidence/overlay-layout-2026-11-09/visual/final/overlay-settings-360-1.15-ink-31m--1-1-Static_Charge.png), [save failure](evidence/overlay-layout-2026-11-09/visual/final/overlay-pauseSaveError-360-1.15-ink-31m--1-1-Static_Charge.png), [inspection with nested help](evidence/overlay-layout-2026-11-09/visual/final/overlay-inspectionNested-360-1.15-ink-31m--1-1-Static_Charge-help.png) and [three desktop explanations](evidence/overlay-layout-2026-11-09/visual/final/overlay-nested-1280-1.3-ink-31m-11-Static_Charge.png).

The initial fixture compile probe, expanded capture-path/focus probes and placement compile probe are retained separately from application findings. The expanded fixture needed a created output directory, shorter Windows filenames and focus inside the game's shortcut subtree before hover-only tests; these are not player-save or gameplay failures. The `before` directory predates the first fixes, `reviewed` contains the intermediate visual pass, and `final` contains the final source's proofs. Initial passing screenshots alone did not establish correct three-level placement; the final screenshots and assertions do.

A fresh Windows Debug preview is built at `.dart_tool/overlay-layout-preview/build/windows/x64/runner/Debug/monstrous_sea.exe` and was not launched. Earlier previews/evidence and player saves remain untouched. Native pointer/keyboard/touch feel still benefits from player replay; this audit does not change tooltip prose, status mechanics, balance or the deferred icon/art proposals.
