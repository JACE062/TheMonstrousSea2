# Developer guide — The Monstrous Sea V2

Start with [docs/README.md](docs/README.md) for documentation authority. Gameplay belongs to [Current game](docs/CURRENT_GAME.md), narrative to [Lore](docs/LORE.md), and unresolved work to [Backlog](docs/BACKLOG.md). This guide owns technical architecture and verification, with no second copy of the gameplay specification.

## Architecture and source navigation

| Location | Responsibility |
| --- | --- |
| `packages/monstrous_core/` | Pure Dart models, content, injected RNG, rules, commands/events, session state and serialized data. Zero Flutter, Flame or `dart:ui` dependencies. |
| `packages/monstrous_sim/` | Headless voyage simulation, bot strategies and generated balance reports. Uses the same core commands/rules. |
| `apps/monstrous_sea/` | Flutter screens and accessibility; Flame battle rendering/effects; the controller and platform storage service. |
| `docs/` | Current reference set, evidence and explicitly separated historical archive. |
| `tools/java_oracle/` | Legacy Java fixtures and parity reference. Its old formulas are not the current game-design authority. |
| `TheMonstrousSea_Original/`, `OriginalProjectIdeas&Planning/` | Read-only legacy source/design references. |

Preserve the [accepted platform boundary](docs/decisions/0001-platform.md): Flutter + Flame presentation, a decoupled pure Dart engine, and Windows desktop as the primary target. Other platform capability is not a claim that every target has been verified.

- `GameSession.dispatch(Command)` mutates core state and returns structured `GameEvent`s. UI/controllers and simulator strategies issue commands rather than duplicating game rules.
- Pass gameplay randomness through `GameRng` / `SeededGameRng`; preserve deterministic replay and isolated sessions. Check existing code rather than guessing APIs from completed task briefs.
- Core models live under `lib/src/model/`; rules under `lib/src/rules/`; narration and player-facing content under `lib/src/lore/` and narration formatters. Historical conceptual `models/ship.dart` paths are not a rename requirement.
- `GameController` bridges session state/events to Flutter notifications, combat logs and storage. Flame renders/plays back events; it must not become a second combat engine.
- Preserve docstrings, rationale and test intent when still applicable. Update stale comments deliberately when related code changes; do not delete compatibility logic merely because its field names describe a retired system.

## Persistence and state lifetimes

[StorageService](apps/monstrous_sea/lib/src/services/storage_service.dart) owns disk I/O. Core [ProfileData](packages/monstrous_core/lib/src/persistence/profile_data.dart) and [VoyageSaveData](packages/monstrous_core/lib/src/persistence/voyage_save_data.dart) own serialization. Windows production saves use `%LOCALAPPDATA%\TheMonstrousSea2\Saves`; other platforms use application support under `TheMonstrousSea2/Saves`. New saves never fall back to temporary storage. See [the save-location and migration policy](docs/CURRENT_GAME.md#persistence-and-presentation) for legacy import and reset behavior.

Storage initialization is shared across concurrent calls. A pending migration journal permits retry before loading a partial save pair; a completion marker prevents stale legacy saves from being resurrected. Existing new-location saves are authoritative. Legacy Documents/temp files remain untouched as backups. `baseDirectory` alone disables migration for isolated tests; pass an explicit `legacyDirectory` to test migration. Do not use production storage in verification. Startup must display a retry state on location/import failure instead of proceeding into a fresh profile.

Keep cross-voyage profile data, current-voyage build/checkpoint data, and combat-only boosts distinct.

`MonsterSpecies.isRegionTitan` is the Nemesis exclusion boundary. `ProfileData` filters unsupported Titan records at construction/assignment; their standalone serialized IDs remain readable for compatibility. Checkpoint restoration repairs only pending Blood Oath offers lacking an eligible target, using stable catalog order without RNG draws. `SeaChart` discards saved offer sets containing a Titan Nemesis, preserving valid offered courses and traveled history. Restoring a helm regenerates missing offers after all profile/voyage context is restored, so the repair cannot leave an empty course-selection screen. Do not reroll already selected captains or rewrite historical death records as part of this repair.

`LineageStore` prepares the root through `StorageService.initializeDirectory`, then owns the validated `lineages.json` catalog and independent `lineages/<slot-id>/` pairs. Existing single saves migrate once as Original Lineage with byte-preserved source backups and a pending-import marker. Slot storage uses strict reads. Normal startup uses `LineageMenuScreen`; injected `MonstrousSeaApp.controller` fixtures retain their direct orchestrator entry. A nested navigator keeps slot routes beneath the debug host, preserving F10. Slot controllers enable `retainPreparationCheckpoints` for home/death heir offers. Menu return is limited to fully supported save phases, finishes queued writes with gameplay input disabled and unmounts the route before disposing its controller. Do not broaden that phase set without serializing complete state and testing reward/replay safety. Catalog publication is serialized within one store instance; simultaneous app processes and atomic profile/checkpoint pairs are not provided.

`PauseMenuHost` owns Esc, the modal input/focus boundary and save/return/exit handling. Slot routes supply their lineage label and a post-save navigation callback; direct/debug orchestrators use the same host without a title destination. `canSaveAndLeave` is the shared supported-stop/playback gate. The host fully removes its dialog before popping the slot route, so dialog listeners do not outlive the controller. Nested dialogs consume Esc first; queued writes disable dismissal and controls, and failures remain retryable. Battle marks `isPlayingEvents` before combat dispatch and clears it only after event playback/end delays finish. The orchestrator retains the battle while that flag is set, even if the core already reports loot/death, so parent/menu/settings rebuilds cannot cut its playback short. Pause lets this existing playback continue and blocks new input rather than freezing/replaying the event queue.

The app controller resolves the core's compatibility Rest checkpoint with `TakeHelm` after loot decisions and on old-checkpoint restore, before notifying screens; that command owns stronghold/final routing. Emergency triage remains an engine rule available at the helm. Loot and wreck checkpoints retain pending supplies; wreck snapshots also retain the spent salvage action, name and receipt. Outgoing screens ignore input during AnimatedSwitcher transitions, and the Helm screen freezes its rendered departure view.

`SessionPhase.port` is ancestral home; `SessionPhase.stronghold` is a mid-voyage berth. Stronghold merchants persist their return phase. Legacy regional `port` saves restore as strongholds. Controller persistence snapshots profile/voyage data before awaiting I/O and queues writes, preserving stronghold checkpoints while preventing stale writes after death. Verify completed-Titan saves and legacy migration when changing this lifecycle. Both Havens and strongholds use `VoyageShipwrightView` and the same core costs/caps; permanent progression commands are home-only.

Test fixtures that do not test persistence must set `autoSave: false`; persistence fixtures must inject disposable directories. The app's root `flutter_test_config.dart` also installs a per-suite disposable default via `StorageService.testDefaultDirectory` for the suite's actual `setUpAll`/`tearDownAll` lifetime. Test runner zones do not retain a `main()`-only zone override. `StorageService.withIsolatedStorage` scopes nested asynchronous work; explicit constructor directories take priority. Injected default roots disable legacy import. Never run an unguarded UI fixture against production saves: an audit found older art/UI tests doing exactly that (PT2-27).

A save reset is a separate user action. Documentation/verification tooling must not modify a real player's profile. Use injected storage and isolated game state in tests.

The controller clears the live Chronicle after successful succession/fresh home departure, before appending those events; normal encounters and stronghold departures preserve it. `CombatLogView` owns its scroll state, including initial/live-end layout settlement and manual-history pause/resume. Battle playback must not force a reader back to the bottom. The mutable log list requires a stored prior count to detect appends across widget rebuilds; logs are not checkpoint data.

Caldera choice/outcome checkpoints are exceptions to ordinary terminal-checkpoint deletion. `VoyageSaveData` retains `calderaOutcome`, its acknowledgement flag and the exact offered heirs; the controller also checkpoints `expeditionVictory` before choice. `ResolveCalderaClimax` applies the existing consequences once and reads prose from `EldritchLore`; `AcknowledgeCalderaOutcome` changes only the read flag. Keep core `death`/`ended` phases for headless consumers. The app renders the unread outcome before routing to succession or the completed-hunt screen. Claim's outcome clears on succession; slot controllers retain the new heir's home preparation while direct adapters retain their deletion policy. Shatter remains complete across restart. Historical ascension records can render using the current neutral heading without rewriting saved records.

`CalderaSnapshot` is an app-side envelope containing a deep-copied pre-choice profile and voyage, validated as unresolved expedition victory. `StorageService` publishes `pre_caldera_choice.json` with a flushed temporary-file rename. The controller captures it at the choice checkpoint and before resolving a loaded choice, queues it before outcome writes, and retries failed snapshot publication before saving resolved state. `LineageStore.exploreOtherFate` requires a completed original lineage, publishes one independent alternate with a stable hashed ID and `alternateOf` catalog relationship, and resumes an existing branch rather than replacing it. Missing/corrupt legacy snapshots disable branching without hiding the ending. Branch relationships are validated; branches cannot branch again. Existing separate profile/checkpoint crash-atomicity limitations still apply.

## Presentation and art

Use the approved ink-and-parchment palette, fonts and transparent curated nautical PNGs selected through `PilotArt` / `SvgAssetView`. Preserve actual alpha, approved ship/monster silhouettes, sparse contours and asset orientation (ships/weapons right, monsters left). Only approved app art belongs in the Flutter bundle; neither archive belongs there.

Retain the [asset manifest](docs/art/sea_map_art_manifest.json), [revision records](docs/art/sea_map_revisions_v5.json), and [chart-marker provenance](docs/art/chart_icon_prompts.json). These preserve details such as the approved Freighter, Ironclad, Squid and Kraken revisions; generic future styling instructions must not overwrite those choices.

SVG and `CustomPainter` remain appropriate for structural cartouches, compass roses, animated waves, borders and gauges. New entity/item art uses the user's established curated workflow when that work is explicitly scheduled. Do not generate art during a documentation or mapping audit. Missing/misassigned images are tracked in the backlog's deferred-art section.

Battle scenes load/decode illustration bytes before caching successful images; Flame 1.38.2's failed image futures can emit unhandled errors even when awaited in a catch. Failures must leave the scene/event queue usable with a labeled placeholder and retry, while approved art remains unchanged. Retry only failed assets and handle scene removal before asynchronous completion. Do not rebuild the shared Windows output while a player's game is running; widget/engine checks and font-loaded widget captures can verify recovery without replacing that executable/bundle.

`ParchmentHeaderScope` composes host controls across nested navigators; each `ParchmentScaffold` places those headers, its body and its footer inside a single page frame. Hosts must not add external control rows around framed pages. Page fixtures should use the same scaffold to exercise this contract; battle retains its intentional frameless arena.

`ParchmentScaffold` supplies a small pause control when hosted. Screens with an existing settings/control location use `PauseMenuButton` there and disable the scaffold copy with `showPauseButton: false`; standalone screen fixtures retain Settings as a fallback. Keep the battle Chronicle beside the pause control and keep lineage/save details inside the menu.

Preserve readable controls and labels at 115% default text and the larger supported scales. A passing overflow check does not establish that intent, logs or damage effects are readable; review realistic desktop and compact layouts when UI changes.

## Tooling on Windows

Dart/Flutter analysis and test workers can stall in restricted Windows sandboxes because they use child processes and local IPC/loopback. Use the execution tool's supported permission override when needed; the available API here is `sandbox_permissions: "require_escalated"`, not the historical `BypassSandbox` / `manage_task` arguments.

Run commands from the relevant package directory, and never analyze the monorepo root indiscriminately. Use the tools actually available in the current session; a historical Flutter-driver or MCP capability description does not establish present access. Poll a running process through its returned session identifier at reasonable intervals and report material progress.

## Development playtesting

The root README owns [playtest menu access and launch instructions](README.md#playtest-menu-debug-builds). `MonstrousSeaApp` wraps the normal orchestrator in `PlaytestHost` only under `kDebugMode`. F10/the debug toolbar opens a separate route; `PLAYTEST=true` opens it directly and defers mounting the normal game until the route closes. Release/profile builds have no entry point, and scenario creation itself rejects non-debug builds.

[PlaytestConfig](apps/monstrous_sea/lib/src/playtest/playtest_config.dart) is an app-side debug adapter, not a new core gameplay command or progression entitlement. It creates a fresh profile/session with an explicit seed, the selected blueprint/ancestral tier, a factory-built hull, real `temperShipHardpoint` upgrades, and canonical `HardpointBlessing`s. Region advancement uses the chart's normal generation. A synthetic rest checkpoint approaches the helm without triggering home's intentional new-voyage reset; Titan launches use the real convergent heading and encounter startup, including regional hazards/intents. Caldera launches provide a test Core and the actual ending decision. Subsequent rewards, strongholds and endings use normal commands.

Each scenario controller explicitly disables autosave and injects a separate temporary storage path, with implicit legacy migration disabled. No test folder is created during normal scenario use. Never reuse the live controller/profile/storage for a test build. Menu edits remain available across relaunch, but every launch creates a fresh independent controller; outgoing widgets unmount before their controller is disposed. Test sessions are disposable and do not survive application restart.

## Verification

Run checks appropriate to the change and inspect the actual diff. The commands below are the package-level baseline; fixed counts in archived receipts are historical, not current pass criteria.

| Scope / working directory | Commands |
| --- | --- |
| Core: `packages/monstrous_core` | `dart analyze`; `dart test` |
| Simulator: `packages/monstrous_sim` | `dart analyze`; `dart test` |
| App: `apps/monstrous_sea` | `flutter analyze`; `flutter test` |
| Native voyage flow: app directory | `flutter test integration_test/voyage_test.dart -d windows` |
| Seeded balance comparison: simulator directory | `dart run bin/simulate.dart --runs 1000 --seed 42 --strategy all` |
| Documentation: repository root | `python tools/check_docs.py`; `git diff --check` |

- Gameplay changes need deterministic regression tests for the changed behavior and appropriate package analysis/tests. Changes spanning the engine, strategies and UI need checks across those boundaries.
- Balance-sensitive changes need representative simulation comparisons. State unlock/blueprint conditions, seed and run count; do not compare a locked-hull bot baseline directly with fresh Standard voyages as though only combat changed.
- The default simulator audit stops after the Kraken. To evaluate strongholds/later regions, also use `SimulationRunner(endless: true)`; its `won` flag still records crossing the first Kraken boundary, not proof of a full campaign victory. Inspect region progress, exceptions, and deaths separately.
- Native/integration tests are useful for storage, startup and navigation changes; keep their state isolated. Inspect screenshots when presentation changes.
- Documentation-only reorganization needs link/anchor, source-section coverage, archive-body integrity and screenshot checks; it does not require rerunning the unrelated game suites.
- Avoid repeating broad suites after no new changes or unresolved concerns. Never claim a command passed without its result.

The simulator's report/CSV are generated evidence, not balance targets. Keep dated verification receipts in the archive. Java parity tests can continue to validate deliberately retained helpers without authorizing legacy mechanics in the current session flow.

## Documentation and agent discipline

Read the relevant current references before task-specific code. Normal searches exclude `docs/archive/` and `docs/art/archive/` through `.rgignore`. Use explicit, scoped historical access only when needed, then reconcile it against current decisions. Root [AGENTS.md](AGENTS.md) owns the user's delegation/model policy; do not duplicate or override its table here.

Maintain stable issue IDs, clear statuses and one owner per rule. A proposed family name, future Master Refit, or archived sample catalog is not an implemented feature. Prefer repository-relative Markdown links in repository documents; user-facing responses should use absolute local-file links supported by the app. Do not add `file://` links that depend on one developer's checkout.
