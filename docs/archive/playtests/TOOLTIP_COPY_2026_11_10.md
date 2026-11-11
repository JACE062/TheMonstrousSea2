# Tooltip copy selections — 10 November 2026

Completed verification receipt. The current selection owner is [the E review](../../design/mechanic-copy-review.md#pending-tooltip-copy-review); this receipt does not approve the six remaining choices or fitting tempering work.

## Implemented scope

- User-approved E01–E02, E06–E15, E17–E18, E20–E24 and E26–E33: 27 edits. E03–E05, E16, E19 and E25 retain their prior wording pending questions-feature answers.
- Shorter dodge, status, condition, helm and control hints. Live bonus/damage values still come from the same displayed context.
- Generic mechanic cards no longer display Action details or its following gap. Named keyword cards retain their titles. Pointer, F1, touch, semantic dismissal, nested placement and route ownership are unchanged.
- Outside-battle Patch Kit buttons keep their labels, accessible descriptions and commands without repeating the label in a tooltip.
- Blessing badges retain their visible tier, while their tooltip omits its repeated tier/subtitle. Thermal Detonation's linked definition retains that Burning remains. Basalt Aegis omits the ordinary Blast multiplier as approved, without adding a new keyword.
- Chart waypoint hints show destination/outcome; the full voyage log retains region/leg counters. Chronicle and Pause shortcuts retain their actions.

## Verification

[Evidence manifest](evidence/tooltip-copy-2026-11-10/manifest.json) retains source hashes, checks and captures.

- The 121-case cached-font run passed 120 cases and found one stale displayed-state assertion expecting `+30% accuracy` instead of the approved `+30% shot accuracy`. Its log is retained, not overwritten.
- Updated that assertion; the subsequent 44-case affected combat/status run passed, including the previously failing detached-state case. These cases overlap the first run and are not additive totals.
- The broader run includes linked definitions, all five hull fitting cards, direct Signature-to-Carapace pointer travel and real tooltip producers across combat/shore/home/inspection/chart/debug screens, including 115% and selected 130% text states. No other layout/input failures occurred.
- All four existing blessing-model cases passed. Flutter app and Dart core analysis both reported no issues.
- Font-loaded captures retain real fitting help without generic headings and nested keyword cards with named headings. Selected desktop/compact proofs were visually inspected.
- Documentation links and whitespace checked with `python tools/check_docs.py` and `git diff --check`.

## Isolation and remaining work

No gameplay rules, numerical tuning, save schema, approved art or player saves changed. Existing audit records and preview bundles are preserved. Tests use isolated, autosave-disabled fixtures; no live game was launched or shared native bundle rebuilt. Core edits affect blessing description strings only.

The six unanswered copy choices remain pending. Pre-purchase current-to-next fitting tempering information is separately recorded as the next task under [PT2-20](../../BACKLOG.md#pt2-20--stronghold-hull-upgrades-mk-tempering-and-master-refits-are-missing); no upgrade preview or new tempering effect is implemented here.
