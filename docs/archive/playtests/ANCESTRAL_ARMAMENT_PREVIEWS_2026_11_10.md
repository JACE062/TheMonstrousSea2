# Ancestral armament previews — 10 November 2026

Completed receipt for showing the next permanent signature tier before spending home-port materials, following the fitting and hull preview passes. [Current game](../../CURRENT_GAME.md#supplies-encounters-and-upgrades) owns delivered behavior; [PT2-03](../../BACKLOG.md#pt2-03--signature-armament-has-two-unexplained-tier-labels) retains the separate inspection terminology issue.

## Delivered behavior

Every owned blueprint in the drafting dialog now compares its current and next ancestral tier and signature damage multiplier. The currently commissioned blueprint also shows its actual mounted signature base damage before and after the purchase. This preserves the current roll and existing rounding rather than guessing a fresh factory result. Inactive blueprints show their exact multiplier change without inventing unrolled damage, commissioning a ship or consuming RNG.

The existing material quote and purchase button remain together with the comparison. Unaffordable offers retain their preview. Successful purchases refresh tiers, damage, material balances and affordability; maximum Tier III shows current values without a next-tier offer. Locked blueprints retain their original unlock gate. Comparison arrows and gold accents share the hull/fitting renderer and wrap without shrinking text.

## Related purchase correction

The live Standard ancestral-purchase handler also scaled its broadside, unlike the documented signature-only progression and fresh commissioned ships. The failing baseline reproduces both tier purchases and a previously enhanced broadside being scaled again. Future purchases now modify signature weapons only. Existing broadside damage, including an already-enhanced saved weapon, is preserved. No save migration or retroactive adjustment occurs.

The new shared `BlueprintArmamentProgression.damageAfterUpgrade` keeps the existing mounted-weapon rounding. For example, Tier II damage 23 becomes 27 at Tier III; this pass does not replace that with a fresh factory roll. Prices, multipliers, fitting marks, other blueprint rules and provisional tuning remain unchanged. Deferred Master Refits remain separate.

## Verification

[Evidence manifest](evidence/ancestral-armament-preview-2026-11-10/manifest.json) retains source hashes, logs and font-loaded screenshots.

- Before the signature-only correction, 3 of 13 core cases failed, all reproducing Standard broadside mutation. The final 30-case core run passes, including all five blueprints at both purchase tiers, inactive upgrades, preserved existing broadside damage and purchase-gate regressions. The added helper test checks hardcoded rounding and the cap.
- The initial 99-case app run passed 97 cases. Two purchase tests exposed a test-fixture phase error: commissioning in captain creation did not enter the actual home-port phase. Those fixtures now use `ChooseShip` and assert the port phase before purchase. The retained focused correction run passes both cases.
- The final 187-case app preview run passes: 16 model cases, 82 ancestral UI cases, the existing blueprint drafting check and 88 shared hull/fitting/purse cases. Model previews match actual paid commands and material deductions; browsing preserves profile, ship and chart snapshots. Actual UI purchases reach Tier III and refresh an inactive blueprint without changing the current vessel.
- A separate 31-case complete blueprint-dialog matrix passes at 115–130% text, including the short 800×480 window. Together with the 30 core cases and 187 preview cases, the final runs contain 248 passing targeted tests. Earlier/focused runs overlap and are not additional unique cases.
- The ancestral matrix covers all five blueprints, poor/rich/owned/maxed states, 360/1280 widths and 115/130% text. Buttons stay reachable, preview text is not truncated, and maximum offers have no purchase button. Ten final ancestral captures retain each blueprint at both widths; Standard desktop and Ironclad compact were visually inspected. Additional final captures verify the extracted hull/fitting renderer.
- App and core analysis report no issues. The initial app lint finding and its fix are retained. Documentation and whitespace checks use `python tools/check_docs.py` and `git diff --check`.

Verification uses fresh in-memory controllers with autosave disabled and cached fonts. No production storage was opened, no player saves were edited, and no native game or preview bundle was launched or rebuilt. Existing art, bundles and earlier evidence remain intact. Player replay remains valuable for the new presentation.
