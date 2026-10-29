# Ship Fittings and Gun-Deck Bracing — 29 October 2026

The user selected **Ship Fittings** as the collective term for Broadside, Signature and Utility, replacing the player-facing Hardpoint terminology. They also selected **Gun-Deck Bracing** for Standard's utility: built-in hull/gun-deck braces set by the crew to take a blow and steady the next volley. This is a naming and flavor change, preserving the ability's mechanics.

Runtime battle, inspection, blueprint, shrine, upgrade, help, accessibility, feedback and narration text now uses the selected terms. Standard's ready-volley display reads **Braced Volley**. Island gunnery training and the Drillmaster trait retain their separate names and behavior. Older screenshots and receipts are unchanged.

`HardpointType`, `gunneryDrill`, `utility_drill`, commands/events, save fields and cooldown/stat calculations remain stable. `HardpointSlot.displayName` resolves the current Standard utility name from its existing ID; its raw `name` and JSON round-trip preserve an older stored label. Battle, inspection and blueprint UI use that display label. Existing live Chronicle history is not rewritten, and no save migration is required.

## Verification

All **632 core tests** and **364 app tests** passed. Core/app analysis and documentation/whitespace checks passed. The core compatibility tests verify the old utility name's exact JSON round-trip, stable ID/cooldown, untouched unrelated names, and activation narration/buff. App fixtures render legacy-named Standard fittings in both battle and inspection, verifying the current display label. Existing fitting, shrine, trait and upgrade checks pass with the updated terminology.

Seven font-loaded layout fixtures also passed across all five hulls at 115–130% text, including desktop, narrow and short windows. The [Standard capture](../../playtests/2026-10-29/10-ship-fittings-standard.png) was visually inspected using Georgia and Material icons. These are isolated widget fixtures, not native player replay. Documentation section-disposition targets now follow the renamed Ship fittings heading; historical source bodies and their hashes are unchanged.

A Sol Medium worker owned core copy/compatibility handling and its tests; the parent reviewed the diff and integrated the app/documentation changes. All preceding uncommitted work was preserved. Production saves and the shared Windows build were untouched. No new art, Goal, gameplay tuning or simulator strategy change was introduced.
