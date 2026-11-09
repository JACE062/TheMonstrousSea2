# Home and lineage layout audit — 9 November 2026

The user requested the same 115% layout review for home port, blueprints/upgrades and lineage menus. Fixtures use normal debug/pause chrome, cached game fonts, autosave-disabled home controllers and memory-only lineage stores. Existing progression, save rules and player data are unchanged.

## Findings and fixes

The initial 99-case matrix reproduced **12 compact Covenant failures**: all four progression states across Pacts, Relics and Monuments. Its heading overflowed by up to 167 pixels; tabs, pact title/burden pairs and upgrade rows also exceeded their available width. The heading and status pairs now wrap, and compact tabs/relic/monument actions stack with gaps. Wide layouts retain their rows and all command callbacks, costs and availability rules.

Visual review also found a home-port title squeezed beside the purse/pause controls, breaking Hunter's Respite into fragments despite no RenderFlex exception. The compact header and vessel summary now stack. The hull meter gets the card's width, and the three fitting marks use a centered line below the mount count rather than splitting the last mark. Compact altar text and Commune also stack. Regression checks explicitly protect title and meter width.

A separate maximum-length-label probe found Continue's selected-save subtitle truncated at 360 pixels. That subtitle now wraps completely. Other `InkButton` subtitles retain their existing two-line limit. Save labels, validation, creation, selection, branching and persistence behavior are unchanged.

## Coverage and results

| Matrix area | Cases |
| --- | ---: |
| Home, blueprints and three Covenant tabs × four progression states × three sizes, 115% | 60 |
| Nine lineage-list states × three sizes, 115% | 27 |
| Five New Lineage dialog states × three sizes, 115% | 15 |
| Four additional hulls × home/blueprints × two progression states × two sizes, 115% | 32 |
| Eight Boon/Quirk description pairs × two sizes, 115% | 16 |
| Five home/upgrade views × three sizes, 130% | 15 |
| Lineage list, invalid input and keyboard inset × three sizes, 130% | 9 |
| **New matrix** | **174** |

The sizes are **360×900, 800×480 and 1280×850**. Hull/trait-specific extensions use the first and last sizes. States cover unavailable and affordable unlocks/upgrades, all five commissioned hulls, ancestral Tiers I–III, forged relics, active pacts, material/trophy ledgers, full/expanded belts, and unbuilt/Rank 2/Rank 10 monuments. Rank 10 is a test state, not a monument cap. Inputs are controlled render states, not a campaign or balance simulation.

Menu coverage includes no saves, sixteen saved lineages, unreadable slots, catalog/open/create errors, completed hunts with/without a branch snapshot, an existing alternate, and a 60-character wide-glyph save label. New Lineage covers empty input, a long label, invalid submission, failed creation and a 240-pixel keyboard inset. Layout browsing, tab selection, scrolling and rejected submissions leave captured profile/ship/chart and lineage-store snapshots unchanged.

**All 174 cases pass with game fonts. The same matrix and 60 related existing checks pass offline: 234 total.** The offline matrix uses Flutter's bundled Roboto/Material Icons; cached Pirata One/IM Fell English remain the illustrated typography/ellipsis oracle. Checks cover control reachability, viewport/dialog bounds, complete boxed labels/subtitles with game fonts, checkbox access and compact title/meter width. Existing tests exercise real blueprint purchases/commissioning, armament upgrades, Covenant actions, lineage creation/branching/errors, isolated storage safeguards and unchanged shared button behavior. Analysis, format and documentation results are retained in the manifest.

## Evidence and limits

[The manifest](evidence/home-layout-2026-11-09/manifest.json) records source hashes, logs and staged captures. Selected proofs: [compact home and fittings summary](evidence/home-layout-2026-11-09/visual/final/home-stats-overview-rich-standard-360-1.15.png), [blueprint actions](evidence/home-layout-2026-11-09/visual/final/home-blueprints-rich-standard-360-1.15-controls.png), [compact monuments](evidence/home-layout-2026-11-09/visual/final/home-monuments-rich-standard-360-1.15-controls.png), [desktop pacts](evidence/home-layout-2026-11-09/visual/final/home-pacts-rich-standard-1280-1.15.png), and [full selected save label](evidence/home-layout-2026-11-09/visual/final/home-menu-wideLabel-list-360-1.15.png). Before/probe captures and logs remain distinguishable from final proofs. Dialog content intentionally scrolls; this pass does not replace the overall menu design, change approved copy or select new artwork. Player confirmation of reading and navigation remains useful.

A fresh Windows Debug preview builds at `.dart_tool/home-lineage-layout-preview/build/windows/x64/runner/Debug/monstrous_sea.exe`; it was not launched. [Preview correspondence](evidence/home-layout-2026-11-09/preview-correspondence.json) verifies copied app/config/Windows sources, bundled artwork, unchanged shared-core inputs and the executable hash. Existing previews, prior audits, player saves and provisional tuning remain untouched.
