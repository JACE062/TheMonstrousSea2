# Covenant Pact previews — 10 November 2026

Completed receipt for showing exactly what each pact changes before home-port activation. [Current game](../../CURRENT_GAME.md#meta-progression-heirs-and-endings) owns delivered behavior, with wording clarifications in [the copy review](../../design/mechanic-copy-review.md#reviewed-and-recommended-to-retain).

## Delivered behavior

Each pact card compares its current and toggled modifiers, total Pact Burden and changing Titan Cinder rewards. Other active pacts and integer reward plateaus are accounted for. Active cards show the reverse comparison before removal. The existing checkbox/header toggle remains; condition help and comparisons sit outside the activation target. Labels use the shared full-size comparison renderer, with linked Carapace/Frenzy help. The altar retains its current total-burden badge and Cinder context.

`CovenantPactEffects` shares the existing numeric parameters and Cinder formula between the resolver, encounter generation and presentation. The preview applies the existing profile toggle to a detached serialized copy, preserving legacy burden reset semantics and the original profile. It never spends materials, touches the vessel/chart, generates an encounter or consumes RNG.

Feeding Frenzy previously claimed a normal 40% HP threshold that was absent from the current resolver. The preview/summary now identify the existing automatic Shark trigger at 60% HP or less; normal Shark intent behavior and the purge guard are unchanged. Brittle Oak names the actual careening/salvaged-timber and shipwright repair scopes. Ketch pricing, healing modifiers, repair work, paid-repair healing, upgrades and provisional tuning remain unchanged. These are copy clarifications, not balance changes.

## Verification

[Evidence manifest](evidence/covenant-pact-preview-2026-11-10/manifest.json) records source hashes, logs and initial/final cached-font captures.

- The final focused core run passes 99 cases, including 10 new pact parameter/threshold/scald/Cinder cases and existing Covenant/trophy, paid-repair, Sargasso and wreck regressions. Hardcoded values preserve spawn bonuses, healing/pricing, the 60/61% Shark boundary, 2/3-turn scald cadence and all burden 0–9 reward amounts. Existing tests retain fog RNG ordering, haze behavior, Apex eligibility and Brittle Oak's repair-work distinction.
- Ten preview-model cases pass. Seven test every one of the 128 active-pact combinations (896 toggle scenarios) against the real command, including reverse comparisons. Additional cases verify exact baseline displays, unchanged reward omission, legacy burden reset and locked-Covenant rejection. Preview snapshots preserve profile/chart, and real toggles spend no materials.
- The final 51-case app run passes: those 10 model cases, 36 new UI cases and five existing Covenant/ending/ancestral regressions. The UI matrix covers four selection states, three window sizes (360×900, 800×480 and 1280×900) and 115/130% text. Every comparison and checkbox stays reachable without truncation. Seven activation/removal flows preserve resources, vessel and chart. Four Carapace/Frenzy mouse-help cases stay within the viewport and do not toggle a pact; a locked offer remains disabled.
- A separate 15-case complete pact-dialog matrix passes at 115–130% with the existing wealth presets, including the short window. Together the final core/app/dialog runs contain 165 passing targeted cases. Earlier/focused reruns overlap these final cases and are not additive totals.
- The initial compile attempts failed on the new helper's enum import, corrected before runtime checks. The next run passed all new app cases but exposed an old altar test tapping an off-screen tab after scrolling to Apex Emergence. That test now scrolls to headings/tabs before interacting. One new test's brace lint was corrected; core and final app analysis report no issues. These initial findings remain in the logs.
- Fourteen final screenshots retain all seven pacts at compact/desktop widths. Volatile Environs desktop and Feeding Frenzy compact were visually inspected. Initial proofs retain the earlier wording; final proofs show the explicit threshold and shorter Titan names. Documentation links and staged whitespace are checked with `python tools/check_docs.py` and `git diff --cached --check`.

All fixtures use fresh in-memory sessions with autosave disabled and cached atmospheric fonts. Production storage was not opened, player saves were not modified, and no native game/shared preview bundle was launched or rebuilt. Existing art and earlier audit evidence remain intact. Player replay remains pending.
