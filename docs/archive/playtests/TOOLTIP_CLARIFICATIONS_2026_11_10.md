# Tooltip clarification selections — 10 November 2026

Completed receipt for the six answers following [the initial E copy selections](TOOLTIP_COPY_2026_11_10.md). [The current review](../../design/mechanic-copy-review.md#pending-tooltip-copy-review) owns all selected wording. Earlier proposals and evidence remain intact.

## Selected wording

- E03: retain Fortified's original amount and full-battle duration.
- E04: “Your next volley gains +15% accuracy and +N% damage.”
- E05: “Your next volley gains +25% damage and applies Burning on hit.”
- E16: “Clears enemy Obscurity. For 2 turns: grants +A% shot accuracy and +B% Blast damage dealt, and prevents enemy dodge.” Live/prospective values still come from the same context.
- E19: “Armor plating absorbs damage before flesh. Blast deals an extra +50% damage against Carapace, and Fire ignores it. Certain weapons specify different interactions.”
- E25: condition/badge help says “Prevents all ship movement this turn.” Disabled helm help says “Grappled: prevents all ship movement this turn.”

All 33 E decisions are now resolved: 32 select edits and E03 selects retention. No fitting tempering preview is included.

## Grappled movement correction

The user's E25 answer requires Grappled to prevent fitting-driven ship movement as well as helm movement. Inspection found the helm and Evasive Rigging already guarded; Prow Ram's charge and `previewResponseRange` lacked that guard.

Four focused cases reproduce Grappled Ram/Rigging use from Short and Medium. Before the fix, the Medium Ram case emitted ship movement, while the other three passed. Both the charge and preview now respect `isGrappled`. The tests confirm no ship displacement, matching predicted/actual range, normal action execution and existing grapple expiry. This is a movement restriction correction; weapon damage, range tables, fitting cooldowns, evasion and other effects are unchanged. Harpoon moves the monster rather than the grappled ship and is untouched.

## Verification and isolation

[Evidence manifest](evidence/tooltip-clarifications-2026-11-10/manifest.json) retains the baseline, source hashes, checks and font-loaded captures.

- 80 core range/attribution, monster intent, full trait roster and ship evasion checks passed, including the four Grappled cases.
- 83 app mechanic/keyword, direct hover handoff, scrolling/nested placement, fitting presentation and displayed-state cases passed with cached game fonts at 115% and selected 130% text states.
- App and core analysis reported no issues. Documentation links and whitespace checked with `python tools/check_docs.py` and `git diff --check`.
- Visually inspected the updated Carapace card at 800×480/130% and nested Illuminated help at 360×900/130%; named headings, readable wrapping and separated cards remain.

No player storage, saved progression, tuning values, assets, earlier audit evidence or existing preview bundle changed. Pure-core fixtures have no disk storage, and UI fixtures disable autosave. No live game was launched or shared native bundle rebuilt. Fitting tempering previews remain the next task under PT2-20, distinct from deferred Master Refits.
