# Fitting tempering previews — 10 November 2026

Completed receipt for the user's request to show what each fitting upgrade changes before purchase. [Current game](../../CURRENT_GAME.md#supplies-encounters-and-upgrades) owns delivered behavior; [PT2-20](../../BACKLOG.md#pt2-20--stronghold-hull-upgrades-mk-tempering-and-master-refits-are-missing) retains deferred Master Refits separately.

## Delivered

The shared voyage shipwright view shows each fitting's name, current/next mark and actual rounded values above its purchase button. Broadside and Signature compare base damage using the current rolled weapon and ancestral armament tier. The five utilities compare their own changing effects: Bracing's next-volley damage bonus, Iron Plates reduction per use, Rigging evasion bonus, Trap damage, and Flare shot-accuracy/Blast bonuses.

Offers wrap into one column on compact/enlarged-text views and three columns where there is room. New values use the established gold accent. Arrows are icons rather than missing font glyphs, and accessible labels describe the comparison. No unchanged cooldown/range/status manual was added.

Unaffordable offers retain their comparisons, while the original purse/command gates still control buying. Purchases and hull refits refresh values and affordability. Mk III shows current values and a disabled maximum button. Existing rounding plateaus, including early Iron Plates, are shown without inventing a gain.

## Implementation and isolation

`FittingTemperPreview` tempers a detached copy with the real `temperShipHardpoint` function, without gameplay randomness or live mutation. Shared `ShipState` utility getters supply both activation and preview amounts; their formulas, floating-point ordering, clamps and rounding retain the existing rules. Inspection descriptions use those same values where applicable.

Gold prices, upgrade commands/caps, damage/range rules, blessing effects, saves and art are unchanged. Test sessions disable autosave and browsing snapshots are compared. Existing player saves, evidence and native preview bundles were preserved; no live game was launched or shared native bundle rebuilt.

## Verification

[Evidence manifest](evidence/fitting-temper-preview-2026-11-10/manifest.json) retains source hashes, checks and initial/final visual proofs.

- 181 preview-model cases cover all blueprints, fittings and marks at hull tiers I/IV, ancestral armament tiers I/III, dedicated fittings and exact rounded plateaus. Values match real tempering, and preview creation preserves the original ship.
- The initial 226-case app run included those model cases and shipwright/purse checks. The subsequent final 95-case cached-font run covers the completed preview UI, live hull-refit refresh, purchases, max/poor states, and selected real Haven/stronghold layouts. These app runs overlap and must not be added as independent totals.
- The new UI matrix covers five blueprints, both service phases, 360/1280 widths and 115/130% text; purchases and maximum state have focused checks. Existing shore matrices include short windows, all hulls, region variants and inspection/action reachability.
- 124 core utility/rigging/continuity cases passed, including 60 direct utility activation comparisons across all five blueprints, hull tiers I–IV and Mk I–III. Another 60 blessing/trait cases passed after extracting the shared potency getters.
- Initial font-loaded proofs exposed missing arrow glyphs despite passing layout checks. The final proofs use arrow icons and grouped mark/value pairs; the corrected desktop Bombardier and compact Clipper views were visually inspected. Earlier proofs are retained as the intermediate finding, not final presentation.
- App/core analysis reported no issues. Documentation links and whitespace checked with `python tools/check_docs.py` and `git diff --check`.

This completes the pre-purchase information gap. New tempering effects, balance adjustments, hull-tier preview expansion and transformative Master Refits are outside this change.
