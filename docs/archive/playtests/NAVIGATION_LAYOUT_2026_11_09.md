# Trait and navigation layout audit — 9 November 2026

The user requested a wider audit after the Storm-Seer collapse, especially at 115% text. This pass checks the normal debug header and pause control as well as the helm, rather than relying only on a bare screen fixture. Courses come from real seeded session generation; assertions confirm that optional and compulsory Nemesis cases actually contain a Nemesis. No gameplay or copy selection was reopened.

The initial 124-case subset reproduced one additional collapse: Region 2 midpoint, Storm-Seer plus Reckless Helmsman, at 1672×952/115%. The fit check reserved 108 pixels around the course stack despite the actual chart using 32-pixel top/bottom insets. It now reserves 64, keeping all cards visible in that desktop column without smaller text. The expanded matrix also guards genuinely constrained layouts: their map uses available height minus a visible report lead-in (100 pixels, existing 260 minimum) instead of the former 58% height / 440 maximum. The lookout heading remains visible for normal page scrolling outside the map; wheel events over the map still zoom without moving the page. No nested course scroll was added.

## Retained verification

| Matrix area | Cases |
| --- | ---: |
| All 8 Boons × 8 Quirks, ordinary and low hull | 128 |
| Eleven states × three regions × three desktop sizes at 115% | 99 |
| Selected midpoint/Nemesis/triage, compact/desktop, 115% and 130% | 18 |
| Selected high-legibility mode checks at 115% | 3 |
| Home/stronghold read-only chart, three sizes | 9 |
| **New matrix total** | **257** |

States cover region entry/opening, ordinary choices, midpoint Haven, final preparation, Titan approach, sole-heading Vendetta, Choking Fog, spent Storm-Seer, emergency triage, identified tags and optional long-named Nemesis. All 64 pairs exercise healing-dependent repair quotes with low hull as well as normal hull. Full desktop cases check all course/auxiliary actions inside the map; constrained cases check map size, visible report lead-in and every action's reachability after scrolling. Captured chart state remains unchanged by rendering.

The matrix plus **62 existing chart/helm/trait/shore/settings cases passed: 319 total**. Analysis is clean. The default map font proofs use cached Pirata One/IM Fell English at the selected 115%/130% scales. High-legibility checks validate that mode's layout/reachability with the widget-test font environment; they are not a claim of exact native system-font rasterization. The ordinary hermetic-font run also checks usable map size and reachable controls; strict 115% desktop-placement assertions use the actual game-font run because the test font has deliberately different glyph metrics. Native player replay remains valuable. A first attempt to fill every pixel with the scrolling map hid the report heading; the existing wheel test caught this, and the final visible lead-in resolves it. Only passing final checks are reported as passing.

Inspected examples: [115% Sargasso midpoint](evidence/navigation-layout-2026-11-09/visual/chart-midpoint-region2-115.png), [long Nemesis and blocked heading](evidence/navigation-layout-2026-11-09/visual/chart-longNemesis-region2-115.png), [1280-pixel scrolling map and visible heading](evidence/navigation-layout-2026-11-09/visual/chart-fallback-1280-1.15.png), [130% scrolling layout](evidence/navigation-layout-2026-11-09/visual/chart-fallback-1280-1.3.png) and [stronghold chart](evidence/navigation-layout-2026-11-09/visual/chart-stronghold-region3.png). Additional final regression captures and logs are indexed in the [manifest](evidence/navigation-layout-2026-11-09/manifest.json).

A new Windows Debug preview builds at `.dart_tool/navigation-layout-preview/build/windows/x64/runner/Debug/monstrous_sea.exe`, without launching it. The manifest verifies app source/assets/lock, bundled assets and executable hashes, and fingerprints unchanged shared core inputs. Documentation and whitespace checks pass. Player saves, prior audit/build evidence, artwork, course rules/restrictions, text size and provisional tuning remain intact.
