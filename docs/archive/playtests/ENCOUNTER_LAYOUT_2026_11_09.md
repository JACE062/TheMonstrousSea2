# Encounter layout audit — 9 November 2026

The user requested the same 115% layout review for other encounters, especially merchants, Havens, shrines and strongholds. This pass uses the normal debug header and pause control with isolated, unsaved controllers. It also covers coves/final shipwrights, smuggler ketches and battle/wreck supply recovery; it does not reopen mechanics or the accepted copy selections.

The initial 87-case matrix found one failure: at 360 pixels/115%, the side-by-side Take All / Leave Leftover footer ellipsized “Leave Leftover & Continue.” The footer now uses the shared responsive row helper: full-width stacked buttons below 500 pixels, unchanged horizontal arrangement above. Visual inspection also found carried Patch Kit and Jettison boxes touching on compact supply cards. An 8-pixel gap now separates compact item actions. All existing command callbacks, labels and item ownership remain intact. The existing pending/carried full-belt rows were retested at 130%; the older recorded overflow was not reproduced in the current responsive layout.

## Coverage and results

| New matrix area | Cases |
| --- | ---: |
| 30 encounter states, 360×900 / 800×480 / 1280×850, 115% | 90 |
| Five blueprints: maxed Haven, stronghold inspection, shrine comparison | 30 |
| All four shrine powers at three widths | 12 |
| Ten selected demanding states at 360/1280, 130% | 20 |
| Additional Siren Shoals / Boiling Reach merchant, Haven and forbidden-shrine states | 12 |
| Iron Bastion inspection at 360/1280 | 2 |
| **New matrix** | **166** |

States include rich/poor/full-belt/empty-stock merchants, with stronghold returns and the final specialist’s return to the helm; materials and sell tabs; carried kits; fresh/spent/maxed/inspection Havens; coves; final refit and exhausted repair work; ordinary, comparison, forbidden, sovereign and completed shrines; both strongholds; Kin gifts, sales and armory at a ketch; full/available loot and wreck assessment/receipt. Fixtures use current models/catalogs with seed 42 and an explicitly chosen state; they are controlled UI coverage, not a simulated voyage or native player replay.

The **166 new cases plus 36 existing service/loot/shrine/inspection cases passed: 202 total**. The matrix also passes **166 cases** with ordinary hermetic test fonts. Analysis and formatting are clean. Every boxed action is scrolled into reach and checked against the viewport; real-font tests also check that action labels do not exceed their line limits. Compact loot additionally verifies the patch/jettison gap. Non-mutating review of tabs, selection and inspection leaves serialized ship/profile/chart, merchant stock, pending supplies and repair-work state unchanged. Existing functional checks cover actual material purchases, repairs, shrine choices and departures.

The visual proofs load cached game fonts and item art. Inspected examples: [compact full merchant](evidence/encounter-layout-2026-11-09/visual/encounter-merchantFull-360-1.15-standard-content.png), [material trade](evidence/encounter-layout-2026-11-09/visual/encounter-materials-360-1.15-standard-content.png), [Haven duties and refits](evidence/encounter-layout-2026-11-09/visual/encounter-haven-1280-1.15-standard-content.png), [shrine comparison](evidence/encounter-layout-2026-11-09/visual/encounter-shrineCompare-1280-1.15-standard-content.png), [compact stronghold inspection](evidence/encounter-layout-2026-11-09/visual/encounter-strongholdInspect-360-1.15-standard-controls.png) and [readable stacked loot actions](evidence/encounter-layout-2026-11-09/visual/encounter-lootAvailable-360-1.15-standard-controls.png). The [manifest](evidence/encounter-layout-2026-11-09/manifest.json) indexes these and the passing related-flow captures/logs. No additional layout failure remains in the covered merchant/Haven/shrine/stronghold states; player confirmation remains valuable.

A separate Windows Debug bundle builds at `.dart_tool/encounter-layout-preview/build/windows/x64/runner/Debug/monstrous_sea.exe`; it was not launched. The manifest verifies app source/assets/lock and bundled assets, fingerprints unchanged shared core inputs and records the executable hash. Documentation and whitespace checks pass. Player saves, approved art, previous bundles/audit evidence, copy, gameplay rules and provisional tuning are unchanged.
