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

Keep cross-voyage profile data, current-voyage build/checkpoint data, and combat-only boosts distinct. The current shared-port transition clears more than it should at strongholds; PT2-19/21 in the backlog track this known bug. Do not turn that implementation defect into a persistence requirement. Verify actual checkpoint/load/delete paths when changing lifecycle behavior, including completed-Titan saves and legacy migration.

A save reset is a separate user action. Documentation/verification tooling must not modify a real player's profile. Use injected storage and isolated game state in tests.

## Presentation and art

Use the approved ink-and-parchment palette, fonts and transparent curated nautical PNGs selected through `PilotArt` / `SvgAssetView`. Preserve actual alpha, approved ship/monster silhouettes, sparse contours and asset orientation (ships/weapons right, monsters left). Only approved app art belongs in the Flutter bundle; neither archive belongs there.

Retain the [asset manifest](docs/art/sea_map_art_manifest.json), [revision records](docs/art/sea_map_revisions_v5.json), and [chart-marker provenance](docs/art/chart_icon_prompts.json). These preserve details such as the approved Freighter, Ironclad, Squid and Kraken revisions; generic future styling instructions must not overwrite those choices.

SVG and `CustomPainter` remain appropriate for structural cartouches, compass roses, animated waves, borders and gauges. New entity/item art uses the user's established curated workflow when that work is explicitly scheduled. Do not generate art during a documentation or mapping audit. Missing/misassigned images are tracked in the backlog's deferred-art section.

Preserve readable controls and labels at 115% default text and the larger supported scales. A passing overflow check does not establish that intent, logs or damage effects are readable; review realistic desktop and compact layouts when UI changes.

## Tooling on Windows

Dart/Flutter analysis and test workers can stall in restricted Windows sandboxes because they use child processes and local IPC/loopback. Use the execution tool's supported permission override when needed; the available API here is `sandbox_permissions: "require_escalated"`, not the historical `BypassSandbox` / `manage_task` arguments.

Run commands from the relevant package directory, and never analyze the monorepo root indiscriminately. Use the tools actually available in the current session; a historical Flutter-driver or MCP capability description does not establish present access. Poll a running process through its returned session identifier at reasonable intervals and report material progress.

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
- Native/integration tests are useful for storage, startup and navigation changes; keep their state isolated. Inspect screenshots when presentation changes.
- Documentation-only reorganization needs link/anchor, source-section coverage, archive-body integrity and screenshot checks; it does not require rerunning the unrelated game suites.
- Avoid repeating broad suites after no new changes or unresolved concerns. Never claim a command passed without its result.

The simulator's report/CSV are generated evidence, not balance targets. Keep dated verification receipts in the archive. Java parity tests can continue to validate deliberately retained helpers without authorizing legacy mechanics in the current session flow.

## Documentation and agent discipline

Read the relevant current references before task-specific code. Normal searches exclude `docs/archive/` and `docs/art/archive/` through `.rgignore`. Use explicit, scoped historical access only when needed, then reconcile it against current decisions. Root [AGENTS.md](AGENTS.md) owns the user's delegation/model policy; do not duplicate or override its table here.

Maintain stable issue IDs, clear statuses and one owner per rule. A proposed family name, future Master Refit, or archived sample catalog is not an implemented feature. Prefer repository-relative Markdown links in repository documents; user-facing responses should use absolute local-file links supported by the app. Do not add `file://` links that depend on one developer's checkout.
