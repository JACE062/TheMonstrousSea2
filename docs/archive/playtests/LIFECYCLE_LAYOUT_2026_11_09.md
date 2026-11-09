# Lifecycle layout audit — 9 November 2026

The user requested a 115% layout review of the intro, captain naming, death/heir selection and ending screens, including long names and trait descriptions. This pass uses normal debug/pause chrome, cached game fonts and isolated autosave-disabled controllers. Player saves and approved prose are untouched.

## Findings and changes

The first 51-case matrix passed 47 cases and found four compact heir-card failures: ordinary Nemesis death, Titan death, keyboard-inset succession and Claim succession. At 360 pixels, the Selected badge reduced a long candidate name to about **149 pixels** of width. The retained before image shows names breaking into many short lines. Compact cards now put Selected beneath the full-width name. Trait labels/names share a wrapping header and their descriptions use the card's width below it; wider cards keep their existing rows. Text, text sizes, colors, offer selection and name-edit callbacks are unchanged.

A focused validation check also found the first-captain error message ellipsized at 360 pixels/130%. It now wraps to up to three lines. The message and empty-name validation rule are unchanged. The intro, death ledger/Nemesis prose, Caldera choice, both full outcomes and completed-hunt prose needed no wording changes or replacement layouts.

## Coverage and results

| New matrix area | Cases |
| --- | ---: |
| Seventeen screen/input states × three sizes, 115% | 51 |
| All eight Boons × eight Quirks × compact/desktop heir cards, 115% | 128 |
| Nine demanding states × three sizes, 130% | 27 |
| Four additional approved hulls × compact/desktop death views | 8 |
| World Serpent and Ancient Leviathan deaths × three sizes | 6 |
| Eighty-character unbroken names in naming, death and final choice × three sizes | 9 |
| **New matrix** | **229** |

The sizes are **360×900, 800×480 and 1280×850**. States include partial and fully revealed intros; first/returning captain naming; invalid input; captain/heir naming with a 240-pixel keyboard inset; ordinary/Apex Nemesis death; all three Titan deaths without a Nemesis; a minimal empty-ledger/no-offer compatibility view; Claim succession; final choice; both outcome readings; a completed hunt with/without Return to Menu; and native-exit rejection. The normal long name is “Alexandrina Waverley-Montgomery of the Saltbound Watch,” extended with heir epithets and ship naming. The unbroken 80-character case is a stress input, not a new name limit.

Each trait-pair case selects all three offered candidates and verifies the corresponding local name input before editing it. The fixture keeps distinct Boons/Quirks within an offer and excludes Vendetta when no eligible Nemesis exists. Full pair coverage uses the Nemesis state. Browsing, scrolling, selection, local name edits, rejected naming and cancelled exit leave captured profile/ship/chart/offers/phase/outcome/read-state snapshots unchanged. No final choice, succession or acknowledgement command is dispatched by layout review.

**229 cases pass with cached game fonts. The same matrix and 54 related existing cases pass offline: 283 total.** The offline matrix loads Flutter's bundled Roboto/Material Icons; cached Pirata One/IM Fell English remain the illustrated typography/ellipsis oracle. Checks cover button reachability and complete labels, viewport/keyboard bounds, compact name/description width, exact selected/local names, full validation text, preserved state and the fixed Embark footer inside the frame as prose scrolls. Existing tests exercise real onboarding, succession, Titan exclusions, final choices/acknowledgement, restart, ending snapshots and menu return.

## Evidence and limits

[The manifest](evidence/lifecycle-layout-2026-11-09/manifest.json) records source hashes, checks and staged proofs. Examples: [before selected heir](evidence/lifecycle-layout-2026-11-09/visual/before/heir-deathNemesis-standard-kraken-360-1.15-selected-heir.png), [readable heir names/traits](evidence/lifecycle-layout-2026-11-09/visual/reviewed/life-deathNemesis-standard-kraken-360-1.15-selected-heir.png), [revealed intro and fixed footer](evidence/lifecycle-layout-2026-11-09/visual/reviewed/life-introComplete-standard-kraken-360-1.15-content.png), [wrapped naming error](evidence/lifecycle-layout-2026-11-09/visual/validation-final/life-captainInvalid-standard-kraken-360-1.3.png), [Claim reading](evidence/lifecycle-layout-2026-11-09/visual/reviewed/life-outcomeClaim-standard-kraken-360-1.15-content.png) and [safe exit-error view](evidence/lifecycle-layout-2026-11-09/visual/reviewed/life-huntExitError-standard-kraken-360-1.15-content.png).

The fixture primes fonts before mounting the continuously animated intro, advances the actual typewriter to full reveal when requested, then freezes its decorative ticker for stable capture. Ordinary Material validation animations remain enabled and advance before final error captures. The initial ticker-frozen error images are preliminary, not final validation evidence. A compile-argument typo in the first fixture attempt is retained separately from the 51-case baseline. Native exits are intercepted and cancelled by the test binding; no application or real save is closed. Scrolling is intentional for long text/cards. Reading pace, the future surname design and cinematic ending delivery remain separate work.

A fresh Windows Debug preview builds at `.dart_tool/lifecycle-layout-preview/build/windows/x64/runner/Debug/monstrous_sea.exe`; it was not launched. [Preview correspondence](evidence/lifecycle-layout-2026-11-09/preview-correspondence.json) verifies app/config/Windows source, bundled artwork, unchanged shared-core inputs and the executable hash. Earlier previews/evidence, player saves, approved art, gameplay/progression and provisional tuning remain unchanged.
