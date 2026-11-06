# Player-facing copy review — 6 November 2026

**Status: proposals awaiting the user's selections.** None of C01–C36 below is implemented. Approve or decline individual IDs, groups, or a replacement of your own. This review concerns wording and placement; it authorizes no mechanic, number, save-format or lore change.

The user wants less procedural explanation and more immersion. The source review indexed 132 longer literals across 45 screen/widget files, then checked the relevant screens, shared help, status labels and live call sites. This is a review of current runtime copy, not a claim that every line was assistant-authored or that all dynamic combat narration has been exhaustively audited. The authored prologue and ending canon are preserved. Legacy/unreachable mechanics are not restored or treated as current merely because a string exists.

## Already handled in this batch

- Removed the standalone chart's “Midpoint choice … Final preparation … Titan afterward” schedule.
- Removed “One finite shipment. Stored with your lineage; no belt slot required. Purchases compete with repairs and refits.” Stock, price and owned quantities remain visible.
- Corrected the Haven's contradictory “deep-water” refuge description to “Calm shallows beneath verdant sanctuary cliffs,” consistent with accepted refuge lore.
- Corrected Runic Guidance's retired “reveal adjacent sea chart nodes” claim to “receive next-leg lookout guidance.” The accuracy bonus and actual guidance rules are unchanged.

## Navigation and planning

| ID | Current copy / location | Proposed change | Why ask first? |
| --- | --- | --- | --- |
| C01 | “Region N of 3,” “Leg N of M,” and “Titan encounter” in [helm](../../apps/monstrous_sea/lib/src/screens/helm_screen.dart) / [standalone chart](../../apps/monstrous_sea/lib/src/screens/sea_chart_screen.dart) headers. | Show the region name and, when applicable, “Anchored in port.” Keep numbered records in the optional Voyage Log/tooltips. | These counters help plan resources, but are the most visibly game-like remaining chart text. |
| C02 | “FRESH WESTERLIES · EVERY HEADING PRESSES ONWARD” in [helm](../../apps/monstrous_sea/lib/src/screens/helm_screen.dart). | “FRESH WESTERLIES” at every width. | Removes an explanation of route rules; the wind phrase itself supplies atmosphere. |
| C03 | “Read the winds once per region to redraw ordinary headings. Haven, Titan and Nemesis courses hold fast.” in [helm](../../apps/monstrous_sea/lib/src/screens/helm_screen.dart). | “Read the winds anew. Once per region; only ordinary headings change.” | Keeps the use limit and scope, but stops enumerating every exception. |
| C04 | “Patch the hull to 25% integrity before choosing a heading.” in [helm triage](../../apps/monstrous_sea/lib/src/screens/helm_screen.dart). | “Patch the hull to 25% integrity.” | The action already precedes sailing; the threshold still matters. |

## Shore services and inspection

| ID | Current copy / location | Proposed change | Why ask first? |
| --- | --- | --- | --- |
| C05 | “Your voyage continues. Refit the vessel, replenish supplies, and prepare for the next region.” in [stronghold](../../apps/monstrous_sea/lib/src/screens/stronghold_screen.dart). | Remove the paragraph. | The surrounding services already express all of it. |
| C06 | “Voyage stronghold · [region]” in [stronghold](../../apps/monstrous_sea/lib/src/screens/stronghold_screen.dart). | Show only the region beneath the named stronghold. | Removes an internal category label; the town name carries the setting. |
| C07 | “Three fixed fittings. Inspect their voyage marks, blessings and ancestral refits here.” in [inspection](../../apps/monstrous_sea/lib/src/widgets/armory_view.dart). | Remove the introduction. | The displayed fittings and sections already explain the view. |
| C08 | “Single-use provisions. Hull Patch Kits can also patch hull between battles. Other supplies are combat quick actions.” in [inspection](../../apps/monstrous_sea/lib/src/widgets/armory_view.dart). | “Patch Kits can be used between battles.” Keep shared quick-item rules in Belt Help. | The between-battle exception is useful; the rest repeats established rules. |
| C09 | “Spend gold on hull refits and fitting tempering. These upgrades last for this voyage.” in [shipwright](../../apps/monstrous_sea/lib/src/widgets/voyage_shipwright_view.dart). | “Refits last for this voyage.” | Retains the temporary/permanent distinction without explaining the purchase buttons. |
| C10 | “Refitting first increases maximum hull used by careening and your first paid repair purchase.” in [Haven](../../apps/monstrous_sea/lib/src/screens/respite_island_screen.dart). | Remove the caption. | Closely resembles the repair explanation the user already disliked; it does reveal an ordering advantage. |
| C11 | “CREW SHORE DUTY (CHOOSE ONE BEFORE TIDE TURNS)” / “CREW SHORE DUTY COMPLETED (PREPARING TO DEPART)” in [Haven](../../apps/monstrous_sea/lib/src/screens/respite_island_screen.dart). | “SHORE DUTY · CHOOSE ONE” / “SHORE DUTY COMPLETE.” | Keeps the mutually exclusive choice and spent state; removes the extra directions. |
| C12 | “... Shore Duty Option,” “Gold Doubloons,” and “Accuracy for the Whole Next Battle” on [shore-duty cards](../../apps/monstrous_sea/lib/src/screens/respite_island_screen.dart). | Keep the actual healing/percentage and gold range, omit “Shore Duty Option,” use “gold,” and say “Accuracy · next battle.” | Preserves decision values/duration while reducing repeated labels. |

## Trading

| ID | Current copy / location | Proposed change | Why ask first? |
| --- | --- | --- | --- |
| C13 | “MERCHANT WARES FOR SALE” beneath the Supplies tab in [merchant](../../apps/monstrous_sea/lib/src/screens/merchant_screen.dart). | Remove this duplicate heading. | Tabs now provide the section identity; the cards are visibly for sale. |
| C14 | “LEAVE CHANDLERY & RETURN TO STRONGHOLD” / “LEAVE CHANDLERY & TAKE THE HELM” in [merchant](../../apps/monstrous_sea/lib/src/screens/merchant_screen.dart). | “RETURN TO STRONGHOLD” / “TAKE THE HELM.” | Makes the destination clear without repeating the place being left. |
| C15 | “A clandestine merchant vessel rides the ocean swell under muffled lanterns, peddling contraband munitions.” in [ketch](../../apps/monstrous_sea/lib/src/screens/smuggler_screen.dart). | “A shadowed ketch trades beneath muffled lanterns.” | This is atmosphere rather than instruction; keeping the longer version is also reasonable. |
| C16 | “DEPART SMUGGLER & CONTINUE EXPEDITION” in [ketch](../../apps/monstrous_sea/lib/src/screens/smuggler_screen.dart). | “DEPART KETCH.” | Shorter and more nautical; navigation behavior stays the same. |

## Wrecks and spoils

| ID | Current copy / location | Proposed change | Why ask first? |
| --- | --- | --- | --- |
| C17 | “COMMITTED RECOVERY: High chance of a creature fight. An Apex predator may appear. Species and tier remain unknown until it appears. [For uncertain wrecks: You cannot take the quick haul as well.]” in [wreck](../../apps/monstrous_sea/lib/src/screens/shipwreck_screen.dart). | “A fight is likely; an Apex may be lurking.” For uncertain wrecks, also retain “The quick haul will be left behind.” | Keeps danger and the irreversible tradeoff; drops the implementation-like identity/tier disclosure. |
| C18 | “THREAT CLEARED. The [remaining small haul / full wreck cargo] is ready to recover. [There is no further fight here / No further risk choice or fight remains.]” in [wreck](../../apps/monstrous_sea/lib/src/screens/shipwreck_screen.dart). | “The wreck is clear. Recover the remaining cargo.” | More natural, but less explicit reassurance that the threat is settled. |
| C19 | “The fresh cargo lies below. Recovering it takes a deliberate commitment; you can still sail past empty.” in [wreck](../../apps/monstrous_sea/lib/src/screens/shipwreck_screen.dart). | “Fresh cargo lies below the broken decks.” Keep the commitment warning and Sail Past Empty action. | Removes repeated instructions without hiding the risk decision. |
| C20 | “These are the defeated creature’s full spoils. The cleared wreck’s separate cargo awaits recovery after these supplies are resolved.” in [loot after a wreck fight](../../apps/monstrous_sea/lib/src/screens/loot_screen.dart). | “The beast's spoils. Wreck cargo still awaits.” | Retains the distinction between two settlements without explaining the UI sequence. |
| C21 | “+N GOLD SALVAGED DIRECTLY TO PURSE (Purse: Ng)” in [loot](../../apps/monstrous_sea/lib/src/screens/loot_screen.dart). | “+N gold · Purse: Ng.” | Keeps the award and new balance; removes the accounting narration. |

## Shrines and the home port

| ID | Current copy / location | Proposed change | Why ask first? |
| --- | --- | --- | --- |
| C22 | “A dedication lasts for this voyage. You may switch wardens above before committing.” in [shrine](../../apps/monstrous_sea/lib/src/screens/shrine_screen.dart). | “Dedications endure for this voyage.” | Keeps duration, but removes the explicit instruction that selecting another warden is still possible. |
| C23 | “Your dedications are complete. Offer respects and seek guidance in the runes.” in [shrine](../../apps/monstrous_sea/lib/src/screens/shrine_screen.dart). | “The wardens have received your vows.” | More thematic; the runes and departure controls remain available. |
| C24 | “Unlock ancestral blueprints with materials recovered at sea. These permanent refits are separate from the fitting marks earned during a voyage.” in [blueprints](../../apps/monstrous_sea/lib/src/screens/port_screen.dart). | “Ancestral blueprints endure across generations.” Keep material costs beside purchases. | Preserves permanence, but drops the comparison with voyage fitting marks. |
| C25 | “The altar hums in the captain’s quarters. Enact Pacts for Primordial Cinders, forge Eldritch Relics, or consecrate Harbor Monuments.” in [home](../../apps/monstrous_sea/lib/src/screens/port_screen.dart). | “The altar hums in the captain’s quarters.” | Keeps atmosphere; the altar's own tabs identify its services. |
| C26 | “Ratify bloodline Pacts to increase Pact Burden. Primordial Cinders drop exclusively from Region Titans defeated under active Pact Burden (> 0)!” in [Covenant](../../apps/monstrous_sea/lib/src/screens/port_screen.dart). | “Defeat Titans under a Pact to earn Primordial Cinders.” Keep Burden values/effects beside each Pact. | Removes jargon and the programming-like comparison, while retaining the earning condition. |
| C27 | Relic/monument introductions explain the recipes and repeat their permanent mounting or future-voyage effects in [Covenant](../../apps/monstrous_sea/lib/src/screens/port_screen.dart). | “Forge a permanent relic for its ancestral hull.” / “Consecrate a monument to bless future generations.” Keep recipe costs and each effect. | Shortens general instructions; permanence and the affected hull/generations still matter. |

## Captains, saves and help

| ID | Current copy / location | Proposed change | Why ask first? |
| --- | --- | --- | --- |
| C28 | “Three fixed fittings. Set your range, fire a volley, and survive the beast ahead. New blueprints await later generations at the home port.” in [first captain](../../apps/monstrous_sea/lib/src/screens/captain_screen.dart). | “Set your range, fire a volley, and survive the beast ahead.” | This is first-voyage onboarding; shortening may make blueprint progression less obvious. |
| C29 | “The beast grows more cunning and ruthless in the deep. Confront it on a future voyage to avenge your ancestor.” in [Nemesis death panel](../../apps/monstrous_sea/lib/src/screens/death_screen.dart). | “On a future voyage, avenge your fallen captain.” | Removes a repeated instruction, but loses some flavor. This should not imply new between-voyage Nemesis growth. |
| C30 | “Name this save. This label is separate from your captain’s name and does not set a permanent family surname.” in [lineage naming](../../apps/monstrous_sea/lib/src/screens/lineage_menu_screen.dart). | “Name this save.” | Much cleaner, but the present surname/save-label distinction was deliberate. It does not settle the surname proposal. |
| C31 | “Each save has its own captains, discoveries and ending. New Lineage starts a separate hunt.” in [lineage menu](../../apps/monstrous_sea/lib/src/screens/lineage_menu_screen.dart). | “Each lineage is a separate hunt.” | Save selection may benefit from explicit independence, especially for a first-time player. |
| C32 | “Your peaceful ending stays intact. The other fate is a separate save with its own progress. Returning here continues that same branch.” in [alternate fate](../../apps/monstrous_sea/lib/src/screens/lineage_menu_screen.dart). | “Explore the other fate in a separate save. Your peaceful ending is preserved.” | Retains the reassurance without explaining repeated reopening; branch reuse must remain unchanged. |
| C33 | “This completed hunt has no usable pre-choice snapshot. Its ending is preserved; older endings cannot be safely reconstructed.” in [unavailable alternate fate](../../apps/monstrous_sea/lib/src/screens/lineage_menu_screen.dart). | “This hunt's final choice was not recorded. Its ending remains safe.” | Replaces implementation terminology with the actual limitation; the disabled action/retry state still matters. |
| C34 | “Adjust text magnification across all screens, charts, and chronicle logs.” / “Switch between atmospheric antique typography and clean high-legibility print.” in [settings](../../apps/monstrous_sea/lib/src/widgets/settings_dialog.dart). | Remove the scale caption; shorten the font caption to “Antique or plain type.” | These are useful accessibility explanations in settings, rather than immersion-breaking text during play. Keeping them is reasonable. |
| C35 | “Each item is single-use and does not end your turn (0 turn cost). You can still give a helm order and use a fitting.” in [Belt Help](../../apps/monstrous_sea/lib/src/screens/battle_screen.dart). | “Single-use supplies cost no turn. Helm and fittings remain available.” Retain the next paragraph's per-round limit/reset explanation. | Keeps all rules while removing the duplicate turn-cost phrasing. Help is intentionally the place for explicit mechanics. |
| C36 | “Permanently adds +N Damage Reduction for this battle...” in [Ironclad battle tooltip](../../apps/monstrous_sea/lib/src/screens/battle_screen.dart), with similar [inspection copy](../../apps/monstrous_sea/lib/src/widgets/armory_view.dart). | “2-turn cooldown. Adds +N damage reduction for the rest of this battle; prevents forced movement this round.” Use the same wording in both places. | Avoids conflicting permanence language while retaining the actual amount, duration, movement protection and cooldown. |

## Retain unless separately requested

Keep visible prices, stock, ownership, healing amounts, caps, cooldowns, threatened ranges, odds/accuracy context and meaningful disabled-state reasons. Keep explicit irreversible choices and save/overwrite/error safeguards. Combat Inspect and Belt Help may need exact rules even when routine menus can be terse. Do not remove one-use limits, the quick-salvage tradeoff, Patch Kit exceptions or permanence distinctions just to reduce word count.

The most useful first selections are C01–C04, C05–C14 and C17–C21. C15, C23, C29 and C34 are more subjective: they remove atmosphere or optional help as well as words. Changes to user-authored story prose, entity names and region-specific art are outside this copy list. [PT2-08](../BACKLOG.md#pt2-08--sea-chart-needs-a-clearer-player-purpose) tracks the connected UI follow-up.
