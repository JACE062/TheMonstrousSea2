# Final layout sweep — 9 November 2026

The user requested a final 115% sweep of remaining screens, confirmation dialogs, empty states and errors. This pass inventories the runtime screens and explicit dialogs, compares them with the preceding audits, and exercises the remaining branches. It preserves approved copy/art, existing choices and callbacks, player saves, earlier evidence and provisional tuning.

## Coverage reconciliation

| Area | Previous coverage | Remaining work in this sweep |
| --- | --- | --- |
| Helm and shore sea chart | Navigation audit | No new layout branch required |
| Merchants, havens, shrines, smugglers, strongholds, loot and wrecks | Encounter audit | Empty loot, sold-out materials/wares/belt, missing wreck state |
| Home, blueprints, Covenant upgrades and lineage menu | Home/lineage audit | Pending catalog/open/alternate-fate operations, branch/exit/long summary errors, long-label cancellation |
| Intro, captain naming, death/heirs, Caldera choices/outcomes and completed hunt | Lifecycle audit | Existing choices/validation already covered |
| Battle, trait/build combinations, Belt Help and intent Inspect | Combat audit | Missing/retrying illustration notices, waiting state, integrity/fitting text and shortest dock |
| Pause, Settings, inspection, native/contextual/nested help | Overlay audit | Existing disabled/error/saving/dismissal states already covered |
| Voyage log and combat Chronicle | Logbook audit | Existing long entries, live/manual reading and scrolling already covered |
| Retained rest screen | No dedicated large-text receipt | Full/critical/no-ship view, long vessel name and stats |
| Startup and debug playtest launcher | Behavior tests, limited layout evidence | Loading, retry, normal/invalid/keyboard/choice/active launcher views |

[The machine-readable inventory](evidence/final-layout-2026-11-09/coverage-inventory.json) records every current screen file, the additional startup/debug routes and explicit dialog/help callsites with their owning tests. New Lineage retains create/cancel. Blueprint/Covenant progression and the Caldera retain their existing decision controls; save/exit gates remain in Pause/title controls. No new confirmation or deletion flow was introduced. The rest screen remains the retained `restArea` adapter; testing it does not restore a mandatory stop between encounters or change navigation routing.

## Findings and changes

The valid **69-case baseline passed 60 and failed nine**. Compact rest stats overflowed horizontally; its critical workbench header also overflowed, and the long vessel name was squeezed beside the illustration. It now stacks vessel details below the art when compact, wraps stats into rows and lets the critical heading share a wrapping header.

Artwork-failure/retry cases exposed ellipsized integrity labels at compact width and a one-pixel vertical overflow in short combat windows. Integrity labels now wrap. At command budgets below 200 logical pixels, the lookout joins the command scroll above helm/fittings; the belt, Pause and Chronicle stay fixed. This avoids spending the entire dock on its fixed lookout/footer before commands can receive space. Wider layouts retain their existing arrangement. Compact monster names retain their existing ellipsis with a full-name tooltip.

The expanded plain-font run found four fitting-name failures: Naval Cannon Battery needed more than two lines at 360 pixels. Fitting buttons now allow complete names and accuracy/range stats to wrap; the existing equal-height side-by-side row remains. `InkButton` keeps its two-line default elsewhere. Playtest numeric-validation messages also clipped at compact width; they now allow three lines, with the same limits and wording.

Startup/retry, pending lineage operations, alternate-fate and native-exit rejection, long unreadable-summary text, New Lineage cancellation and the remaining empty/waiting views needed no behavioral or prose changes. The debug launcher retains its existing controls and safely creates only an isolated unsaved scenario.

## Verification

| New matrix area | Cases |
| --- | ---: |
| Twenty-three remaining states × three sizes, atmospheric 115% | 69 |
| Same states/sizes, plain 115% | 69 |
| Eleven demanding states × three sizes × both fonts, 130% | 66 |
| **New matrix** | **204** |

The sizes are **360×900, 800×480 and 1280×850**. The stress vessel name is “The Unreturning Waverley-Montgomery Bloodbound Flagship”; lineage labels include a 60-character unbroken name. A 240-pixel keyboard inset checks the launch control above the keyboard area. Definitions/dropdown names that deliberately elide retain their complete text in prompt tooltips; action names, integrity labels and validation errors are checked for clipping.

**204 cases pass with cached game fonts. The same matrix plus 729 existing regressions pass offline: 933 cases.** The related suites cover every hull/trait pair, combat dialogs/readiness, home/blueprint/Covenant layouts, lineage operations, debug launcher, artwork recovery, shore UI and Pause. Twelve focused game-font keyboard cases additionally verify that controls remain above the inset, without counting those repeated cases twice. Analysis, formatting and documentation checks pass.

The game-font run loads cached Pirata One/IM Fell English and bundled Roboto/Material Icons for plain mode. Layout helpers assert no Flutter layout exception, viewport/keyboard control bounds, complete essential text and unchanged profile/ship/chart/phase/monster-HP and memory-store snapshots. Startup retries increment only the injected load counter. Native exits are intercepted and cancelled; pending mock operations complete after unmount and cannot reach player storage. The artwork fixture loads in real async time, awaits mounted component readiness and pauses decorative updates for capture; retry is held on an injected asset future. Reading/scanning never dispatches player combat, purchase or departure commands. Scenario creation uses the existing isolated debug adapter.

## Evidence and limits

[The manifest](evidence/final-layout-2026-11-09/manifest.json) retains source hashes, checks and staged screenshots. Examples: [overflowing rest view before](evidence/final-layout-2026-11-09/visual/before/sweep-restCritical-360x900-1.15-ink.png), [wrapping rest details](evidence/final-layout-2026-11-09/visual/reviewed/sweep-restCritical-360x900-1.15-ink.png), [short combat recovery](evidence/final-layout-2026-11-09/visual/reviewed/sweep-artFailed-800x480-1.3-ink.png), [full numeric error](evidence/final-layout-2026-11-09/visual/reviewed/sweep-playtestInvalid-360x900-1.15-ink.png) and [keyboard clearance](evidence/final-layout-2026-11-09/visual/reviewed/sweep-playtestKeyboard-360x900-1.15-ink.png). The artifact-layout probe identifies the overflowing command column; the plain-fitting probe predates the final wrapping fix. `before`, `first-fix` and `final` retain earlier stages; `reviewed` is the final complete game-font matrix.

A fresh Windows Debug preview is built at `.dart_tool/final-layout-preview/build/windows/x64/runner/Debug/monstrous_sea.exe`; it was not launched. [Preview correspondence](evidence/final-layout-2026-11-09/preview-correspondence.json) verifies copied app/config/Windows source, bundled approved art, unchanged core inputs and build hashes. This closes the recorded layout inventory, not every possible future string/window/state combination. Native player replay and the separate helm/status-art work remain valuable; gameplay tuning and deferred Master Refits are unchanged.
