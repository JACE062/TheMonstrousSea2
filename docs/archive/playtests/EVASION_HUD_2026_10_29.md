# Effective evasion readouts — 29 October 2026

The player reported that the evasion percentage beside ship/monster names did not always match current behavior, particularly with region effects and Quirk bonuses. This follows the separately approved global range-evasion removal; the Clipper Mk progression decision remains open.

## Delivered correction

`ShipState.effectiveEvasion` now owns the exact existing dodge threshold: current evasion (including current regional reductions and temporary boosts), captain bonus and a live Basalt Aegis dodge bonus, clamped to 0–95%. The combat trait, HUD and ship effect readouts share this getter. The previous HUD omitted Basalt's bonus and the final cap. No dodge rule, RNG draw or boost-consumption behavior was changed by extracting the calculation.

The monster getter continues to share Pin and Flare handling with combat. Its final value is normalized to the actual 0–100 d100 threshold, after Pin's halving, preserving every roll outcome and draw gate even for out-of-range legacy values. Both panels keep 0% visible; an actual Flare setting raw evasion to zero no longer hides the readout. Tooltips distinguish accuracy from dodge and explain the ship's unavoidable-attack exception.

Captain Boon/Quirk IDs now travel in immutable transient effect snapshots and their obscurity-preserving copies. Detached presentation actors refresh that context on initial/idle synchronization and event playback. This fixes context that previously remained from initial scene construction. HUD numbers read the displayed actors, including the immediate loss of Basalt dodge when barrier HP reaches zero, without leaking later live state. Snapshot fields are not new checkpoint data.

## Verification

All **662 core tests** and **374 app tests** passed; core/app analysis passed. Core checks exhaust every d100 roll for representative current/regional-debuff inputs, captain bonuses, Basalt tiers 1–3 and live/expired states, lower/upper bounds, and monster Pin/Flare combinations. They also verify RNG call counts and frozen captain context through snapshot copies. The prior all-hull/all-range regressions remain intact.

Ten focused app tests passed, including actual Sargasso encounter startup with normal and Volatile Environs penalties, with/without Reckless Helmsman, at 360 and 1280 pixels / 130% text. Additional cases check the 95% ship cap, visible zero for each side, Pin/Flare, idle captain refresh, and captured effect playback against deliberately advanced live state. The sequence displays ship dodge 25 → 55 on the captured captain/barrier effect, 35 at barrier depletion, then 7 on the later captured expiry; it does not jump directly to the already-resolved live value.

The same focused suite passed with Georgia and Material icons loaded. The [desktop](../../playtests/2026-10-29/12-effective-evasion-desktop.png) and [compact](../../playtests/2026-10-29/13-effective-evasion-compact.png) captures show the real stronger Sargasso penalty with Reckless Helmsman: Clipper's current 5 plus the Quirk's 10 displays **15%**, while the World Serpent displays **30%** dodge. These are isolated widget renders, not native player replay. Existing full-suite art, flow, input and combat presentation checks passed.

One Sol Medium worker owned the shared core calculations, snapshot fields and core regressions. The parent reviewed the diff and integrated HUD/presentation changes and app verification. The previous seeded balance comparison was not repeated: this follow-up preserves dodge outcomes and RNG, verified at every d100 boundary. It introduces no utility Mk tuning, gold/material changes, save migration, new art, Goal or native build. Production player saves and all prior uncommitted range-removal work were preserved.
