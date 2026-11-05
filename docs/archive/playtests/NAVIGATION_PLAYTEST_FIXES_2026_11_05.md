# Navigation playtest fixes — 5 November 2026

Completed follow-up to the player's five screenshots and Jellyfish feedback. This is a dated verification receipt; [Current game](../../CURRENT_GAME.md) owns delivered behavior and [Backlog](../../BACKLOG.md) owns unresolved work. Initial navigation/economy evidence remains in the [earlier receipt](NAVIGATION_REFACTOR_2026_11_05.md), unchanged. Numerical economy tuning remains provisional.

## Commit boundaries

The original refactor was committed before making playtest fixes:

| Commit | Scope |
| --- | --- |
| `aa81719` | Accepted design and preserved economy audit |
| `a686986` | Core navigation, wrecks, recovery and finite trade |
| `b58a653` | App integration and initial chart/services |
| `d41eda6` | Full-voyage spending and matched wreck audit tools |
| `b428e60` | Verification receipt and provisional tuning status |

The subsequent fixes are separate logical changes:

| Commit | Scope |
| --- | --- |
| `e1b8f96` | Documents-only automatic legacy discovery; home trading removed in UI/core; simulator guards |
| `a24d7e4` | Short Jellyfish lunge, Medium/Long pressure and contact-only collision feedback |
| `d16ff62` | Shared wreck/battle supplies, readable merchant cards and concise paid repairs |
| `32606cd` | Cumulative nautical geometry, pan/zoom, fit/locate and interaction/layout coverage |

Full IDs and source/evidence hashes are in the [manifest](evidence/navigation-playtest-fixes-2026-11-05/manifest.json). This receipt and the current-rule updates are a final documentation/evidence commit.

## Delivered fixes

- **Wreck supplies:** `LootSuppliesView` is now the common established battle-loot menu, including art, descriptions, stats, full-belt jettison/stow/leave decisions and carried/pending Patch Kits. Wreck departure retains its source-specific guard. Creature rewards and exactly-once cargo settlement stay separate. Compact full-belt captures of the two sources have identical pixels in the fixture.
- **Merchant:** Cards retain 72-pixel leading art beside the item name. At compact widths, description/stats/prices span the card beneath that row; wider layouts place wares and belt sections side by side. Repeated Single Use/value prose is removed. The home supply merchant and direct item/material buy/sell commands are unavailable, including old home-shop checkpoints; those checkpoints can still leave safely. Stronghold, specialist and ketch trading remains available.
- **Future broker:** The user's Hades-inspired limited meta-material exchange is recorded as **FUT-08**, proposed/deferred. Rates, quantities, refresh rules and UI remain undecided; no broker trades were implemented.
- **Paid repairs:** The menu shows remaining capacity as a percentage of current maximum hull, plus actual HP/gold quote buttons. Normal-work counts, refit explanation and captain-healing tutorial paragraphs are removed. The allowance ledger, first-purchase latch, rounding, prices and healing modifiers are unchanged.
- **Jellyfish:** The user selected a Short-only Nematocyst Lunge with a separate Medium/Long threat. The lunge closes before striking Short; from Medium, holding/advancing is threatened and falling back avoids it. Stationary Nematocyst Curtain threatens Medium/Long and is chosen at Long; Medium alternates the pair. Short retains Embrace/lunge pressure. Stable intent IDs, damage, accuracy and status values remain. Collision impact events require a connecting hit, so an out-of-range strike, accuracy miss or dodge cannot falsely report the bonus; previews retain possible collision danger.
- **Chart:** Each recorded leg advances east from the preceding point, with additive northward port or southward starboard displacement. Ahead retains the lateral offset. Repeated port choices form a diagonal without lane limits or return-to-center bounces. The growing map supports drag, wheel/pinch zoom, fit/locate and arrows/Home/End. Water marks, compass rose and ink nautical symbols accompany the dotted wake. Full regional history/outcomes persist; camera state is transient. No future offers are exposed, and rendering consumes no gameplay RNG. Difficulty, cadence, rewards and service access are unchanged.

## Ironclad investigation and approved save repair

Read-only inspection found an old shared-system-temp profile already owning Ironclad with no voyage history/materials, no Documents profile, and a newly imported LocalAppData root profile byte-identical to that old temp file. Original Lineage inherited that grant before play; death/succession did not purchase it. The earlier fixture-write problem and its isolation safeguards remain documented separately under PT2-27.

Automatic legacy discovery now checks Documents only. Missing/failed Documents lookup returns no source, rather than searching arbitrary shared temp files. Explicit restoration still preserves legitimate saved ownership and copies original bytes. No general ownership reset, save deletion or navigation migration system was added.

The user explicitly approved backing up the active profile and removing only its unpaid Ironclad unlock. With the game closed, the original bytes were backed up and the corrected profile atomically replaced after a source-hash check. Backup filename:

`player_profile.before-unpaid-ironclad-fix-20261105T152110Z.json`

It is retained beside the active profile in the Original Lineage directory. Only `unlockedBlueprints` changed; Standard, active ship, materials, captain history and every other JSON field were verified unchanged. The original root/temp evidence remains intact. The [sanitized repair verification](evidence/navigation-playtest-fixes-2026-11-05/save-repair-verification.json) records hashes and the one-field comparison without tracking player save contents.

## Verification

| Check | Result |
| --- | --- |
| Core complete suite | **910 passed**, including every legal Jellyfish range/helm pair, miss/out-of-zone collisions and home trade rejection |
| App complete suite | **427 passed** |
| Combat/presentation/wreck UI after final contact-event adjustment | **29 passed** |
| Simulator complete suite after voyage-only merchant guards | **43 passed** |
| Font-loaded integrated chart and follow-up UI | **19 passed**; 360/1280 layouts at 130% text, regional history, full belt, merchant and repair captures inspected |
| Core, app and simulator analysis | No issues |
| Windows Debug build from committed code | Successful; game checked closed before building |
| Documentation and whitespace | See retained check output and manifest |

Regression tests also check 40 consecutive port choices, stable route prefixes, straight segments, mouse pan/zoom, keyboard controls and fit/locate without altering committed chart JSON. Existing reduced-motion, pause, save isolation and battle-to-cargo playback checks remain. Tests use disabled autosave or disposable storage; the approved one-field repair above is the only deliberate live-save write.

The [evidence directory](evidence/navigation-playtest-fixes-2026-11-05/) retains final logs and inspected screenshots. The five original player attachments are preserved byte-for-byte under [5 November playtests](../../playtests/2026-11-05/). Prior October and initial refactor audit evidence and the stock simulator report were not replaced.

Player replay remains necessary to assess the new Jellyfish pattern and map feel. No new economy balance approval, human win rate or completed native player voyage is claimed.
