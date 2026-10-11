# Agent Brief: Phase 2 - Visual Presentation Layer (Flutter + Flame)

Phase 2 builds the presentation and UI layers on top of `packages/monstrous_core`.

---

### Stream 2A: Ink Theme & UI Screens
- **Files:** `apps/monstrous_sea/lib/src/screens/**`, `widgets/**`, `theme/**`
- **Scope:**
  - Ink & parchment theme with sepia backgrounds, iron-gall typography, styled borders.
  - Intro screen with typewriter dialogue effect.
  - Captain creation & Heir selection.
  - Port screen (Merchant modal, Repair station, Sea chart modal, Sail button).
  - Rest area screen (Heal/rest, inspect cargo, return to port).
  - Death & Lineage screen.
- **Exit Criteria:** All non-combat screens render cleanly with zero overflow errors.

---

### Stream 2B: Flame Combat Scene
- **Files:** `apps/monstrous_sea/lib/src/battle/**`
- **Scope:**
  - Flame 2D game widget integration.
  - Animated wave/ocean parchment canvas.
  - Ship sprite & Monster sprite rendering.
  - Kraken tentacle visualization (dynamically rendering remaining tentacles).
  - Attack animation queues: cannon smoke, damage floats, screen shake, ink cloud overlay.
- **Exit Criteria:** Combat scene seamlessly plays back events emitted by `GameSession.dispatch()`.

---

### Stream 2C: Art & Visual Asset Generation
- **Files:** `apps/monstrous_sea/assets/art/**`
- **Scope:**
  - Ink-and-parchment styled assets (vector/image assets):
    - 4 ships: Standard Barque, Freighter, Ironclad, Corvette.
    - 5 monsters + Kraken: Shark, Serpent, Jellyfish, Squid, Crustacean, Colossal Kraken.
    - Weapon & item icons.
- **Exit Criteria:** Asset pack integrated; fallback vector rendering available if images missing.

---

### Stream 2D: Integration QA & Flutter Driver Automation
- **Files:** `apps/monstrous_sea/integration_test/**`
- **Scope:**
  - Automated integration test driving a complete voyage from title screen to Kraken encounter.
  - Automated screenshots taken at each milestone screen for visual review.
- **Exit Criteria:** `flutter test integration_test/voyage_test.dart -d windows` passes without errors.
