# Full captain roster — 26 October 2026

Completion receipt for PT2-26's eight Boons and eight Quirks. Current rules and values belong to CURRENT_GAME; remaining offer-weighting and balance discussion belongs to BACKLOG. This extends the 25 October Storm-Seer/Overzealous receipt rather than replacing its historical results.

## Implemented and reviewed

- All sixteen catalog entries have working current effects and descriptions. Exacting Shipwright replaces Salt-Addict; the old serialized ID resolves to the current replacement. No player saves were deleted or rewritten by verification.
- Healing uses multiplicative factors, one rounding and a final missing-hull cap. Coverage includes 91 HP fractional cases, Hull Patches, careening, wreck timbers, Siphon, paid repairs, triage and refit restoration. Refits retain their full maximum-hull increase. Repair quotes match actual HP and costs.
- Quartermaster's slot does not accumulate across reloads; commission and succession allocate it before transferring supplies so the extra slot's contents are preserved.
- Exacting attack reduction carries fractions between hits within combat, after armor/bracing and before barriers; it does not reduce environmental/status damage. Veteran's extra shell damage adds no direct HP damage. Precise and Reckless effects reach real rolls and displayed values without doubling.
- Impatient commits Utility plus one weapon action before the enemy response, then blocks hardpoints for the recovery turn. Belt/helm/Brace remain legal; grappled Hold Line plus Brace can finish recovery. Cooldowns and reset boundaries are covered.
- Skirmisher resolves the committed helm after the main action's intrinsic movement. Ram/Harpoon regression cases verify that Medium + Fall Back returns to Medium after their forced approach. Their tooltips use an action-aware response-range helper; the shared helm-only forecast is visibly conditional.
- Superstitious keeps ordinary encounter guarantees and shrine eligibility, with one forbidden power only when two appear. A persisted voyage seed plus region/leg fixes both manifestations and taboo for re-entry from the preceding helm. Smuggler gifts remain unclaimed on a full belt and can be selected once per encounter.
- Offers use injected RNG, distinct trait IDs within a set and deterministic repair of duplicate default names. Vendetta's existing eligible-target guarantee remains; recent-offer weighting was not implemented.
- Armory inspection shows current captain trait names/descriptions. Daredevil's battle hint uses the same activation gate as actual weapon damage, with a compact-layout regression covering the transition to half hull.

## Verification

- **533 core tests passed**; full core analysis clean.
- **33 simulator tests passed**; full simulator analysis clean. The legacy audit's generated tracked reports were restored byte-for-byte.
- **315 app tests passed**, including 18 new roster widget cases. App package analysis passed before the final forecast/reminder changes; focused analysis of the changed controller/battle/Armory/test files passed afterward. A later Flutter analysis worker stalled and was canceled; it was not reported as passing.
- Documentation validation and `git diff --check` passed.
- Font-loaded shrine, smuggler, Impatient pending/recovery and range-forecast captures were reviewed at 360/1280 widths and 115%/130% text. Disposable captures remain under the app's ignored `.dart_tool/roster-review/`. Known compact battle HUD/name crowding remains PT2-11 work. No native Windows build or production-storage fixture was used.

## Representative seeded comparison

Reusable harness: `packages/monstrous_sim/bin/audit_captain_traits.dart`. Run from the simulator package with `dart run bin/audit_captain_traits.dart --runs 100 --later-runs 50 --seed 42`. Markdown and per-run CSV are written to ignored `.dart_tool/captain-traits-report.*` files.

The audit performed **18,000 disposable starts**: 16,000 trait conditions and 2,000 cached matched baselines. Every one of sixteen traits was compared across five hulls, with 100 seeds per hull in Region 1 and 50 each in Regions 2/3. Seeds are `42 + 31*i`. CautiousBot uses the real commands and captain-specific legal action stages.

Starting builds: Region 1 hull I/Mk I, Region 2 hull III/Mk II, Region 3 hull IV/Mk III; ancestral armament I, 25 gold, no initial blessings, relics, monuments, pacts or other progression. Both sides receive the same factory hull/build. Vendetta alone has a fixed eligible ordinary shark Nemesis, with an identically conditioned baseline. Normal command-driven rewards, upgrades and blessings remain available. Later scenarios start at their region through the normal helm route, with no earlier rewards carried over.

Each run stops at its regional Titan boundary, final expedition-victory phase, death or 2,500 commands. Later-region clears are not full campaign wins; the final ending choice is not part of the comparison. There were **zero exceptions and zero command caps**. Baseline no-Nemesis regional clears were 56/500, 34/250 and 19/250; matched Nemesis baselines were 36/500, 26/250 and 16/250.

Selected pooled changes in regional clear rate, in percentage points:

| Trait | Region 1 | Region 2 | Region 3 |
| --- | ---: | ---: | ---: |
| Skilled Carpenter | −1.4 | +0.4 | +2.4 |
| Exacting Shipwright | 0.0 | −3.6 | +0.8 |
| Impatient | +2.0 | −4.8 | −6.0 |
| Skirmisher | −0.2 | +6.0 | +2.4 |

These are observations under one strategy and fixed starting conditions, not target win rates or proof that every trait is equally strong. Changed decisions and attacks diverge later RNG/routes; small per-hull samples and baseline bot limitations constrain interpretation. In particular, automatic use of Impatient whenever available is not an optimized human policy. Player replay should evaluate timing choices, blueprint differences, later regions and mixed Boon/Quirk builds before tuning values.
