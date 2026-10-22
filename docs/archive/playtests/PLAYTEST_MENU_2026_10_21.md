# Configurable debug playtest menu — 21 October 2026

Implemented the requested development launcher for reaching later builds, regional Titans and the Caldera decision without a complete voyage. The root README owns usage instructions; `CLAUDE.md` owns technical behavior.

## Capabilities and boundaries

Debug builds offer a Playtest Menu toolbar button and F10 shortcut. `--dart-define=PLAYTEST=true` opens the menu directly, deferring the normal game's creation/storage load until the menu closes. Release/profile builds expose neither the menu nor scenario creation.

Configuration covers all five blueprints; hull tiers 1–4; ancestral signature tiers 1–3; each canonical hardpoint's Mk I–III, optional warden and blessing tier I–III; starting gold; seed; and region. Destinations are the selected region's opening helm, its Titan battle, or the final Caldera choice with one test Core. Relaunch recreates the same configuration/seed, Change Scenario retains values for editing, and closing resumes the normal game.

Each launch uses a fresh profile/controller, autosave disabled, and a separate injected temporary storage path as a second guard. Normal launches create no test save folder. The suspended normal controller is never used as scenario state. Tests do not resume across process restart. No original save was reset, relocked or repaired.

The debug adapter uses the actual flagship factory, temper helper, blessing model, chart region generation and heading/encounter commands. The synthetic rest setup bypasses home's intentional fresh-voyage build reset; it does not duplicate combat rules. Titan startup therefore includes real stats, intents and regional hazards. Rewards then follow ordinary loot, stronghold and ending paths. These fixture grants do not change normal unlocks, prices, starting builds or balance.

## Verification

- App analysis clean and **215 app tests passed** under the disposable storage guard. The earlier ending/core changes remain separately verified; this launcher adds no core or simulator implementation changes, so those broad suites were not repeated.
- Twenty-three scenario regressions cover all 15 blueprint/Titan combinations, preserved upgrades/blessings, Region 2 hazards, actual victory/stronghold/final routing, all region starts, real temper damage, both endings, repeatable independent sessions, numeric bounds and save-path/autosave isolation.
- Seven menu regressions cover 360/1280px at 115%/130% text, blueprint/tier/wardens selection, removing a dedication, gold input, validation, relaunch, retained menu settings, F10 entry from the actual app, both ending shortcuts, normal-controller preservation and deferred normal-game mounting on direct startup.
- Font-loaded widget captures in `apps/monstrous_sea/build/playtest-{360,1280}-menu.png` were inspected at 130% text. The launch action is pinned below the scrolling configuration so simple ending shortcuts do not require scrolling past every hardpoint. Dropdown choices and edit actions remain reachable. The seven focused cases passed again after that layout refinement. These ignored captures use readable system fonts and material icons, not native replay or final themed-font approval. No new art or native executable rebuild was involved.
- Documentation/link checks and diff review accompany the implementation.
