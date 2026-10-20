> **HISTORICAL / SUPERSEDED — NOT IMPLEMENTATION GUIDANCE.** Archived 20 October 2026 from `docs/agents/phase2_visuals.md` at commit `c16a1a2`. Old approvals, locked specifications, instructions and test counts below apply only to that historical revision. Use the [current documentation guide](../../README.md) and open backlog for present work. Retain this file for explicitly requested historical reference only.

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

### Stream 2C: Visual Styling & Asset Integration
- **Files:** `apps/monstrous_sea/assets/art/**`, `apps/monstrous_sea/lib/src/widgets/painters/**`
- **Scope:**
  - **Asset policy (updated 2026-10-12):** The user approved simple raster sea-map art, superseding the earlier SVG-only restriction. All 5 ships, 6 monsters, 8 equipment icons, 4 utility icons, and 3 chart markers use transparent PNGs selected by `PilotArt` and `SvgAssetView`. Keep broad uneven ink contours, cream/tan forms, and sparse interior marks. Masts connect to decks, sails to spars, and monster limbs to clear body roots. Ships and weapons face RIGHT; enemies face LEFT. The freighter was reverted at the user request to `ship_freighter_pilot_v2.png`; retain that previous silhouette. The ironclad (`ship_ironclad_map_v2.png`) has a conventional bow WITHOUT A RAM and one mast with a square sail. The normal squid (`monster_squid_map_v5.png`) retains the preferred rounded silhouette. Suction cups appear only within tan arm undersides; pale dorsal surfaces remain clear. The user moved the bottom-centre row to the tan underside of the lower-left arm in v5. `docs/art/archive/png/monster_squid_alternate_map_v1.png` is an archived long-mantle review option, excluded from the app bundle. Preserve the larger Kraken (`monster_kraken_boss_v5.png`), its jagged mantle, narrow crimson eyes, and smooth collar above readable arm roots. The tincture (`icon_unstable_tincture_map_v4.png`) contains a murky roiling mix of muted slate, olive, plum, rust, ochre and taupe to suggest unpredictable future status effects without favoring any element or using explicit symbols; the torpedo body stays inside its tube with only the nose protruding; the flamethrower has a raised upward-facing spout. Current paths and history are in `docs/art/sea_map_art_manifest.json`; exact revision prompts and the before/after review are in `docs/art/sea_map_revisions_v5.json` and `docs/art/sea_map_revisions_v5.html`. Preserve alpha; parchment belongs to the UI. Only the 26 active PNGs belong in `apps/monstrous_sea/assets/art`. Historical SVGs live in `docs/art/archive/svg` and older PNG drafts in `docs/art/archive/png`; preserve them as source history. Archive paths and SHA-256 hashes are listed in `docs/art/archive/manifest.json`. Legacy tools and tests read from the archive; archived artwork must not be added to the Flutter asset bundle.
  - Sea Chart markers: `icon_port_haven_map.png` for the harbor, `icon_skull_map.png` for defeated sectors, and `icon_fog_map.png` for unrevealed sectors. Each is an exact 1024x1024 RGBA PNG with a 102px fully transparent border. Retain the chart labels, vessel markers, semantics, and existing reveal rules. Prompts/export records are in `docs/art/chart_icon_prompts.json`; review at `docs/art/chart_icons.html`.
  - Ink-and-parchment styled assets:
    - Procedural `CustomPainter` rendering for parchment backgrounds, wave motion, compass roses, and chart borders.
    - Simple transparent sea-map illustrations for:
      - 5 ships: Standard Sloop, Freighter, Ironclad, Corvette, Flying Dutchman.
      - 5 monsters + Kraken: Shark, Serpent, Jellyfish, Squid, Crustacean, Colossal Kraken.
      - Weapon, treasure, and consumable icons.
- **Exit Criteria:** Approved simple sea-map illustrations load in Flutter and Flame with real transparency, readable small icons, and combat sprites fitting between HUD and action dock at wide and compact sizes. Keep vector support for historical assets and procedural UI decoration.

---

### Stream 2D: Integration QA & Flutter Driver Automation
- **Files:** `apps/monstrous_sea/integration_test/**`
- **Scope:**
  - Automated integration test driving a complete voyage from title screen to Kraken encounter.
  - Automated screenshots taken at each milestone screen for visual review.
- **Exit Criteria:** `flutter test integration_test/voyage_test.dart -d windows` passes without errors.
