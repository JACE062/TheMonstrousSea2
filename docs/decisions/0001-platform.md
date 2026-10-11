# ADR 0001: Technical Platform - Flutter & Flame with Decoupled Pure Dart Engine

## Context
The original game (`TheMonstrousSea_Original`) is an object-oriented Java console game containing ~40 classes. It featured turn-based naval combat against sea monsters, loot collection, a port economy, and an inheritance mechanic where an heir continues after a captain's death.

The objective of V2 is to add visuals and UI while preserving the core game logic and enabling goal-oriented, autonomous agentic development.

Evaluated options:
1. **Flutter + Flame (Dart):** Multiplatform (Windows desktop primary, Web/Mobile capable). The agent development environment includes a full Dart MCP server (`widget_inspector`, `flutter_driver_command`, `get_runtime_errors`, hot reload).
2. **TypeScript Web (Phaser + React):** Portable and web-first, but lacks native deep Dart/Flutter MCP inspection tooling.
3. **Java (JavaFX / libGDX):** Retains original codebase, but lacks modern multiplatform deployment and agent inspection hooks.
4. **Godot / Unity:** High fidelity visual capability, but not installed on host machine and difficult for autonomous agents to iterate on.

## Decision
Adopt **Flutter + Flame** for the UI/presentation layer, coupled with a **pure Dart domain engine (`packages/monstrous_core`)** having zero UI or framework dependencies.

## Structure
1. `packages/monstrous_core`: Pure Dart package containing all game rules, models, RNG abstractions, balance configurations, and command/event state machines. Fully testable via `dart test`.
2. `packages/monstrous_sim`: Headless balance simulator CLI for bot simulations and Monte Carlo balance tuning.
3. `apps/monstrous_sea`: Flutter application with Flame component integration for the combat rendering and nautical ink-and-parchment UI.

## Consequences
- **Positive:**
  - Game logic is 100% testable headlessly without UI overhead or mocking Flutter widgets.
  - Agents can drive end-to-end integration tests using `flutter_driver_command` and visually verify components via screenshots.
  - Multiplatform capability (Windows desktop native + Web export).
- **Negative:**
  - Requires translating Java domain models to Dart, which will be verified against Java oracle fixtures.
