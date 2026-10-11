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

### Stream 2C: Visual Styling, SVG & Asset Integration
- **Files:** `apps/monstrous_sea/assets/art/**`, `apps/monstrous_sea/lib/src/widgets/painters/**`
- **Scope:**
  - **Strict rule:** No AI-generated raster images.
  - Ink-and-parchment styled assets:
    - Procedural `CustomPainter` rendering for parchment backgrounds, wave motion, compass roses, and chart borders.
    - License-free / public-domain SVG vector illustrations (or hand-crafted vector paths) for:
      - 4 ships: Standard Barque, Freighter, Ironclad, Corvette.
      - 5 monsters + Kraken: Shark, Serpent, Jellyfish, Squid, Crustacean, Colossal Kraken.
      - Weapon, treasure, and consumable icons.
- **Exit Criteria:** Vector/SVG asset pipeline integrated cleanly without generic AI raster images.

---

### Stream 2D: Integration QA & Flutter Driver Automation
- **Files:** `apps/monstrous_sea/integration_test/**`
- **Scope:**
  - Automated integration test driving a complete voyage from title screen to Kraken encounter.
  - Automated screenshots taken at each milestone screen for visual review.
- **Exit Criteria:** `flutter test integration_test/voyage_test.dart -d windows` passes without errors.
