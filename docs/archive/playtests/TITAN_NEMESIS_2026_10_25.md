# Titan Nemesis exclusion — 25 October 2026

Implementation receipt for the PT2-24 eligibility follow-up. Current rules live
in [Current game](../../CURRENT_GAME.md#meta-progression-heirs-and-endings).
The separate intent-tooltip/detail complaint remains deferred in PT2-11.

## Behavior verified

- Kraken, World Serpent and Ancient Leviathan deaths do not create a Nemesis,
  emit its ascension event, or offer Blood Oath/Vendetta. An older active target
  is cleared on a Titan death. Each death still records exactly one captain.
- All five ordinary species, including their Apex forms, still create Nemeses
  and offer Vendetta. Selecting Vendetta requires an eligible active target.
- Legacy Titan Nemesis records are filtered at profile construction/assignment
  and serialization. Standalone legacy record decoding remains supported.
  Death history, materials and other progression are preserved.
- Unsupported pending Vendetta offers receive a deterministic catalog-based
  replacement, preserving names, boons and other heirs. Repeated restore/save
  cycles are stable and use no replacement RNG draws. Previously selected
  captains and their traits are not rerolled.
- Saved course sets containing a Titan Nemesis regenerate through the normal
  helm flow during restore, leaving three usable non-Nemesis headings in the
  affected second-half fixtures. Valid saved choices and completed voyage
  history are preserved.
- App death screens and an isolated controller reload of a legacy Kraken death
  show no Nemesis banner, bounty or unsupported Vendetta choice.

## Verification

- Core: `dart analyze` clean; all **484** tests passed. The **29** focused Titan,
  succession and compatibility regressions also passed after the final
  assignment/selection checks and diff cleanup.
- Simulator: `dart analyze` clean; all **33** tests passed, including its existing
  1,000-run audit. That audit's locked Standard profiles are verification
  fixtures, not a human win-rate target or a before/after balance comparison.
- App: `flutter analyze` clean; all **27** tests passed across
  `titan_death_ui_test.dart`, `death_screen_and_controller_test.dart`,
  `startup_restore_test.dart` and `lineage_store_test.dart`.
- Documentation: `python tools/check_docs.py`; whitespace: `git diff --check`.

Tests use injected RNG and in-memory/disposable storage. No player save files
were edited, and the shared Windows application was not rebuilt. The generated
simulator report was retained under ignored tooling output; its tracked report
was restored rather than treating generated results as a design change.
