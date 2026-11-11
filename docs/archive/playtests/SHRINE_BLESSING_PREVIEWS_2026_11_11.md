# Shrine blessing previews — 11 November 2026

Completed receipt for showing what each dedication or blessing upgrade changes before the shrine choice. [Current game](../../CURRENT_GAME.md#ocean-powers-and-shrines) owns the delivered behavior.

## Delivered behavior

All twelve power/socket paths show the current and offered tier, a short trigger summary and exact changing values. First dedications include new effects; upgrades compare damage, durations, stacks, chances, barriers, retaliations and Tier III additions as applicable. Full current/next prose is no longer repeated. Linked terms retain condition details without adding those explanations to every offer.

Shared Burning, Arc Discharge and Corroded potency use the whole build's highest relevant dedication. Regional Burning and conditional Tier III wake amplification remain separate. A higher existing dedication can leave shared potency unchanged, so those rows are omitted. Carapace comparisons preserve Mortar's native shell crush and Culverin's penetration. Sockets dedicated to another power and sovereign sockets show their current effects and existing restriction without inventing a replacement or fourth tier.

`ShrineBlessingPreview` uses the real core preview gate and a detached serialized vessel, explicitly copying derived captain trait IDs for contextual help. Shared model getters and Carapace helpers expose the existing resolver parameters without changing effects, rounding or Tempest RNG order. The original command remains responsible for communion. Shrine manifestations, taboos, weighted eligibility, rune fallback, one-choice consumption, costs and save schema are unchanged.

## Verification

[Evidence manifest](evidence/shrine-blessing-preview-2026-11-11/manifest.json) records source hashes, commands, logs and cached-font captures.

- The focused core run passes 75 existing cases covering all blessing tiers, elemental riders, native shell/penetration interactions, damage amplification, critical/static behavior, utility retaliation and shrine lifecycle/status boundaries.
- Fifty-three model cases pass. The 48 power/socket/tier cases each exercise five blueprints and three regions: 720 build scenarios, including 540 successful real dedications/upgrades and 180 capped states. Additional checks cover foreign-power locks, omitted shared-potency gains, regional Burning/wake help, native fitting interactions and new Tier III effects. Previewing preserves profile, ship and chart; actual communion matches the detached result and cannot be repeated.
- The final app run passes 195 cases: those 53 model cases, 128 new UI cases, seven existing Ocean Power UI cases and seven existing linked-help cases. The new matrix covers all four powers, empty/Tier I/Tier II/sovereign/mixed sockets, 360×900 and 1280×900 at 115/130%, and 800×480 at 130%. It verifies complete comparison/button bounds, scrolling, text without truncation, 36 actual choices and eight prospective keyword-help paths, including compact nested Static Charge → Arc Discharge. Merely viewing offers/help preserves state.
- A separate 45-case existing shrine-host layout run passes, including forbidden, sovereign, completed and comparison states across hulls/regions. The three final regression runs contain 315 passing targeted cases; intermediate reruns overlap and are not additive totals.
- Initial analysis exposed nullable utility accesses and Brine integer typing in the extraction; those were corrected. New brace/unused-import lints were also fixed. The first UI run incorrectly hit-tested noninteractive Wrap centers, which can fall between text runs; those now use visible bounds, while actual controls retain hit testing. Nested keyword text includes widget spans, requiring a scoped link/partial-text lookup and a real pointer transfer onto the nested card. An existing test searched for the replaced “Ignites” label; it now opens the first linked “Burning” term. All initial failures remain in the evidence logs. Final core/app analysis reports no issues.
- Twenty-four final first-dedication screenshots retain all twelve offers at compact/desktop widths, with two additional nested-help proofs at 130%. Earlier review captures are preserved. Magma desktop, Brinemother compact and compact nested help were visually inspected. Documentation links and working/staged whitespace are checked separately.

Fixtures use fresh in-memory sessions with autosave disabled and cached atmospheric fonts. Production storage was not opened, player saves were not modified, and no native game/shared preview bundle was launched or rebuilt. Art, earlier evidence and provisional tuning remain intact. Player replay remains pending.
