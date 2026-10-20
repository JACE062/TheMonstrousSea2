> **HISTORICAL / SUPERSEDED — NOT IMPLEMENTATION GUIDANCE.** Archived 20 October 2026 from `docs/agents/phase0_foundation.md` at commit `c16a1a2`. Old approvals, locked specifications, instructions and test counts below apply only to that historical revision. Use the [current documentation guide](../../README.md) and open backlog for present work. Retain this file for explicitly requested historical reference only.

# Agent Brief: Foundation & Phase 0 (Orchestrator)

## Mission
Establish the workspace structure, tooling, Java test fixture oracle, and baseline pure Dart package skeleton.

## Owned Files
- `tools/java_oracle/**`
- `packages/monstrous_core/pubspec.yaml`
- `packages/monstrous_core/analysis_options.yaml`
- `packages/monstrous_core/lib/monstrous_core.dart`
- `packages/monstrous_core/lib/src/rng/game_rng.dart`
- `packages/monstrous_core/lib/src/config/balance_config.dart`
- `packages/monstrous_core/lib/src/session/commands.dart`
- `packages/monstrous_core/lib/src/session/events.dart`

## Acceptance Criteria
1. Java oracle compiles and generates `tools/java_oracle/fixtures/*.json` statistical baselines.
2. `packages/monstrous_core` is initialized, runs `dart analyze` with zero warnings, and exports foundation classes.
