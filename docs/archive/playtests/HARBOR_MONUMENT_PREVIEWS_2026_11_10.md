# Harbor Monument previews — 10 November 2026

Completed receipt for showing the next Harbor Monument rank's effects before spending home-port materials. [Current game](../../CURRENT_GAME.md#meta-progression-heirs-and-endings) owns delivered behavior. The separate [living-town proposal](../../BACKLOG.md#atmosphere-and-living-port-presentation) remains deferred.

## Delivered behavior

Each monument card compares its current and next rank and total permanent bonus: maximum hull HP, bounty gold percentage or weapon damage percentage. The existing material quote appears directly above the boxed upgrade button. The comparison uses the same gold-accented arrows and wrapping renderer as the preceding upgrade previews, with readable default text styles.

Current and next bonuses come from the core profile getters at the existing and selected next civic level. The preview builds a detached level map; it does not spend materials, mutate live state, create a vessel, dispatch a command or use RNG. The original command still owns payment, rank changes and Obelisk hull restoration. Successful purchases refresh the card's rank, total bonus, quote and affordability. Unaffordable cards retain their next-rank preview.

Ranks remain uncapped. The existing cost calculation clamps its rank input to 99, but purchases and bonuses continue beyond that rank. No maximum state or new balance rule is introduced. Existing per-rank effects, costs, Covenant/home-only gates, player saves, art and native bundles remain unchanged.

## Verification

[Evidence manifest](evidence/harbor-monument-preview-2026-11-10/manifest.json) retains source hashes, logs and six cached-font captures.

- 20 preview-model cases pass. All three monuments at ranks 0, 1, 2, 10, 99 and 100 match real paid upgrades and exact material deductions. Hardcoded increments check the displayed units; unrelated ranks stay unchanged. The Obelisk preserves missing hull while adding the existing fixed current/maximum HP. Preview snapshots preserve profile, ship and chart. Additional cases cover locked/poor profiles and the existing rank-99 price clamp.
- 27 new UI cases pass. The 24-case layout matrix checks all three cards in poor, fresh, established and rank-100 states at 360×900, 800×480 and 1280×900, with 115/130% text. Buttons stay on screen when scrolled into view, text is not truncated, and browsing/closing leaves snapshots unchanged. Three purchase flows buy successive ranks, check new displayed prices and bonuses, then spend an exact balance and verify that the unaffordable next-rank preview remains.
- The final 52-case app run includes those 47 new cases and five existing Covenant/ending/ancestral UI regressions. The initial run passed 51 and exposed stale ancestral assertions from the preceding preview change; they now expect the actual current/next labels. The existing monument regression likewise checks the new rank comparison rather than removed badges.
- A separate 15-case full monument-dialog matrix passes at 115–130%, including the short window and all existing wealth presets. Together the final runs contain 67 passing targeted tests. Initial and final runs overlap and are not additive. An attempted multi-name filter failed in the Windows wrapper before tests started; its invocation output is retained separately, and the plain monument filter succeeds.
- Six screenshots show every monument in desktop and compact views. The Obelisk desktop and Brazier compact captures were visually inspected. Only test assertions changed after capture; product rendering remained identical.
- App analysis reports no issues. Documentation links and whitespace are checked with `python tools/check_docs.py` and `git diff --check`.

All fixtures use fresh in-memory sessions and disable autosave. Production storage was not opened, and no native game or shared preview bundle was launched or rebuilt. Existing saves and earlier audit/artwork evidence remain intact. Player replay remains pending.
