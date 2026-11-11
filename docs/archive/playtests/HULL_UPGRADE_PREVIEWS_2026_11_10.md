# Hull upgrade previews — 10 November 2026

Completed receipt for showing the next hull tier's exact effects before purchase, following [the fitting tempering pass](FITTING_TEMPER_PREVIEWS_2026_11_10.md). [Current game](../../CURRENT_GAME.md#supplies-encounters-and-upgrades) owns delivered behavior and [PT2-20](../../BACKLOG.md#pt2-20--stronghold-hull-upgrades-mk-tempering-and-master-refits-are-missing) retains deferred Master Refits separately.

## Delivered behavior

The shared voyage shipwright compares current and next hull tiers above the original purchase button. It displays current/maximum HP, actual base damage for mounted weapons, and any changing base evasion, passive damage reduction or level-scaled Iron Plates/Trap effect. It preserves the current weapon rolls, marks, ancestral damage and missing hull rather than displaying factory estimates. Unchanged values are omitted before purchase; maximum tier IV shows current values with no fifth-tier forecast.

The previews remain readable when gold is insufficient and refresh after purchases, including successive hull upgrades. Current and next values share the fitting offers' gold accent, icon arrows and accessible comparison labels. Compact values may wrap before the arrow/target group without shrinking text.

`HullUpgradePreview` applies the real `upgradeShipState` to a detached ship, with no gameplay RNG, live mutation, command dispatch or save writes during preview. Legacy AC and weapon-weight fields are excluded. No core rule, price, healing modifier, save format, art or player progression changes. Earlier evidence and native preview bundles remain intact; no live game was launched or shared native bundle rebuilt.

## Verification

[Evidence manifest](evidence/hull-upgrade-preview-2026-11-10/manifest.json) retains source hashes, logs and intermediate/final captures.

- 21 preview-model cases exercise 240 build scenarios across five blueprints, four current tiers, all fitting marks, ancestral tiers I/III and full/damaged hulls. Previewed values match the actual paid `UpgradeShip` command, with healing traits active, exact prices, retained marks/blessings and unchanged preview snapshots. A separate capped-evasion/trap case checks that unchanged benefits are omitted.
- The initial 109-case app run passed 108 and exposed a 2.2-pixel overflow in the compact fallback-font HP comparison. That finding is retained. The shared comparison renderer now permits a line break before the arrow and target value.
- The final 158-case cached-font run passed: model cases, hull/fitting UI matrices, live purchases/affordability/max state, existing purse checks and selected real Haven/stronghold layouts. Earlier and final runs overlap and are not additive totals.
- New hull UI cases cover both service phases, all five blueprints, 360/1280 widths and 115/130% text. Actual purchases proceed from tier I through IV at Mk III, preserving missing hull and refreshing effects, prices and the maximum state. Unaffordable previews remain visible.
- Ten focused capture cases retain the complete hull summaries at the top of the menu in desktop/compact views. Final Ironclad desktop and Corsair compact summaries were visually inspected.
- App analysis reported no issues after a test-loop formatting correction. Documentation links and whitespace checked with `python tools/check_docs.py` and `git diff --check`.

Fitting tempering previews continue to work through the shared renderer. New hull effects, balance changes and transformative Master Refits are outside this presentation change.
