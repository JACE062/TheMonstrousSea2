# Grappled Ram reach — 10 November 2026

Completed receipt for the user's explicit follow-up: Ram must be unavailable at Medium while Grappled because the ship cannot close, and remain usable at Short. [Current game](../../CURRENT_GAME.md) and [E25](../../design/mechanic-copy-review.md#pending-tooltip-copy-review) own the resulting rule. This supersedes the initial movement-only handling in [the prior clarification receipt](TOOLTIP_CLARIFICATIONS_2026_11_10.md), whose evidence remains preserved.

## Change

- The shared weapon range-legality helper accepts the acting ship's Grappled state. Session commands, direct volley resolution, Impatient combo eligibility, UI weapon/emergency-pass checks and all simulator bots pass that context.
- A Medium Ram command while Grappled is rejected before attacks, cooldowns, prepared buffs or monster response. Short Ram remains legal. Ungrappled Medium charge and existing Long-range rejection remain.
- The disabled Medium button says GRAPPLED; its help says “Grappled: cannot close to Short Range to ram.” Short retains normal attack information and activation. Core and screen-reader rejection reasons match the restriction.
- When a blocked Ram is the only ready weapon and utility is cooling, Wait & Reload remains available. An Impatient combo cannot start with only an unusable Ram; a legal Short Ram can complete the combo.
- Numerical weapon values, range damage curves, Grappled duration, Rigging and other fitting effects are unchanged. No player save, approved art or earlier audit evidence was touched; no live game or native preview bundle was launched/rebuilt.

## Verification

[Evidence manifest](evidence/grappled-ram-reach-2026-11-10/manifest.json) retains the reproduction, checks, source hashes and eight captures.

- A corrected six-case baseline passed four cases and failed Medium Ram rejection plus Impatient eligibility. The initial test compile probe is separately retained; it is not counted as a behavioral baseline.
- 89 core range/attribution, trait, intent and combat cases passed. The new rejection assertion verifies unchanged ship state (including cooldowns and prepared buffs), monster HP and range; direct volley resolution is also rejected. Short attacks and combos remain functional.
- 14 simulator cases passed, including all four bots at both Short and Medium with only Ram ready.
- 26 app cases passed, including eight focused button/emergency-pass checks for Short/Medium, ordinary/Skirmisher and 115/130% text. Browsing preserves session snapshots. Font-loaded captures of enabled Short and disabled Medium were visually inspected.
- App, core and simulator analysis reported no issues. Documentation links and whitespace checked with `python tools/check_docs.py` and `git diff --check`.

Fitting tempering previews remain the next separate task under PT2-20; this fix changes no upgrade service or tuning.
