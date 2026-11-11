# Eldritch Relic forge previews — 10 November 2026

Completed receipt for showing exactly what forging adds before home-port materials are spent. [Current game](../../CURRENT_GAME.md#meta-progression-heirs-and-endings) owns delivered behavior; the [copy review](../../design/mechanic-copy-review.md#reviewed-and-recommended-to-retain) records the clarified effect summaries. Deferred Master Refits remain separate.

## Delivered behavior and selected clarification

Relic cards show the associated hull/signature and compare only the added effects: Siphon's 30% flesh-damage healing, Ghostwake's Obscurity bypass and 8 base Shock per flesh hit, Brimstone's Burning and Sinew Winch's Poison. The existing material quote remains visible even when poor or missing the blueprint. The original forge gates and command remain in place.

Already-forged cards show their benefits without another next-tier offer, and identify the hull they apply to. Saved inactive flags remain visible and unchanged. The presentation no longer says a relic is active on the currently commissioned hull when it belongs to another blueprint. No activation toggle or new relic tier is introduced.

The old summaries mixed intrinsic weapon traits into relic benefits. They now describe the added effects consistently in the altar and vessel inspection. Ghostwake's old critical-only text also disagreed with combat. The user explicitly chose **Describe current behavior**, retaining its existing rider on ordinary flesh hits. No combat effect, trigger, minimum healing, modifier or rounding rule changed.

`EldritchRelicEffects` supplies shared core parameters to combat and the read-only preview. Previewing never creates/rolls a vessel, mutates a weapon/profile/chart, consumes RNG or dispatches a purchase. Forging adds the existing permanent profile effect without replacing the signature or changing its base stats. Linked Burning, Poison and Obscurity labels use the established keyword help. Costs, saves, art, native bundles and earlier evidence remain preserved.

## Verification

[Evidence manifest](evidence/eldritch-relic-preview-2026-11-10/manifest.json) records source hashes, logs and initial/final font-loaded captures.

- The final 40-case core run passes: 10 new deterministic relic cases plus existing Covenant/trophy and Sargasso/Obscurity regressions. These check effects before/after forging, misses, flesh versus armor damage, ordinary noncritical Ghostwake hits and temporary accuracy bypass without clearing Obscurity. The initial new test module failed to load because a fixture assigned a read-only penalty getter; it now sets the existing backing field. Existing regression cases passed throughout.
- The final 66-case app run passes: 21 read-only preview/model cases, 40 UI cases and five existing Covenant/ending/ancestral regressions. All four real forge purchases spend the exact cost, activate ownership, remove the purchase button and preserve the commissioned ship. Preview snapshots preserve profile, ship and chart across browsing.
- The relic matrix covers five states (blueprint-locked, poor, ready, forged and saved inactive), three window sizes (360×900, 800×480, 1280×900) and 115/130% text. Buttons remain reachable and text untruncated. Six mouse tests cover condition help at 130% in compact/desktop views, including closing on exit and viewport clearance.
- 88 compact hull/fitting/ancestral/monument comparison cases pass with the renderer's optional keyword-label support. A separate 15-case full relic-dialog matrix passes at 115–130%, including the short window and existing wealth presets. Together the final runs contain 209 passing targeted tests; initial and focused reruns overlap and are not additional unique cases.
- Eight final captures show all four relics at compact/desktop widths. Ghostwake desktop and Siphon compact were visually inspected. Initial captures retain the earlier verbose blueprint prefix; the final pass uses the plain hull name.
- Core and final app analysis report no issues. Earlier app test-brace lint findings and their corrections remain in the logs. Documentation links and staged whitespace are checked with `python tools/check_docs.py` and `git diff --cached --check`.

Fixtures use fresh in-memory sessions with autosave disabled and cached atmospheric fonts. No production storage was opened, no player save was edited, and no native game/shared preview bundle was launched or rebuilt. Player replay remains pending for the new presentation.
