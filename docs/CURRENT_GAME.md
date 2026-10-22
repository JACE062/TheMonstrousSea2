# Current game rules

Status: current approved rules and implementation baseline, updated 20 October 2026 through Phase 3B, playtest fixes, and stronghold/home-port separation. Read the [documentation authority rules](README.md#authority-and-status) and relevant [open issues](BACKLOG.md) before changing behavior.

## Game identity and voyage lifecycle

The game is a generational naval roguelite centered on one Bloodbound Flagship, shaped by five ancestral blueprints: Standard, Ironclad, Clipper, Bombardier, Corsair. Tactical decisions, supplies, and voyage buildcrafting should sustain early-region tension even after permanent unlocks; repeated runs should not become automatic victories through unrestricted vertical stat growth.

The debug-only [playtest menu](../README.md#playtest-menu-debug-builds) can launch configured, disposable scenarios for development. Its blueprint/build grants and shortcuts are isolated fixtures, not alternate normal starting rules or permanent unlocks.

- A fresh profile sees the brief introduction, names a captain, commissions Standard, and enters the first combat directly. Standard is the only starting unlocked blueprint. Expanded exposition and a permanent family surname are pending design work: PT2-01/02.
- After death, the next captain chooses from three heirs with boon/quirk pairs, may customize their name, and prepares at the ancestral home port. `Davy Jones` remains the existing hidden Flying Dutchman cheat, not a normal blueprint or starting choice.
- Home port supports permanent blueprint unlocks/commissioning, ancestral armament progression, and the applicable Covenant/relic/monument systems. Unlocking requires an explicit purchase that spends the listed materials; having enough resources does not grant ownership, and commissioning an owned blueprint does not charge its unlock cost again. A test-save leakage path that can create unpaid Ironclad ownership is fixed in PT2-27; existing player unlocks are preserved. Every true new voyage begins at hull level 1 and Mk I hardpoints; permanent armament progression is separate.
- Mid-voyage strongholds have their own `stronghold` phase and preserve the captain, current blueprint, gold, belt, hull tier, hardpoint marks, and blessings. Arrival, merchant visits, reloads, and departure continue the current voyage. Permanent blueprint unlocks/upgrades and commissioning remain home-only, enforced in the engine as well as the UI. Returning home from a rest area is no longer a legal shortcut; home becomes available after succession (PT2-19/21).
- Havens and strongholds share the same gold-funded voyage shipwright: hull tiers cap at 4 with upgrade costs 100/250/500g; hardpoints cap at Mk III with tempering costs 60/120g. The home port offers neither voyage upgrade. Permanent ancestral armament progression uses meta-materials and is separate from these run tiers. Master Refits remain deferred work (PT2-20).
- A captain's ordinary death continues the bloodline. Heir selection offers Continue the Hunt, with no Abandon Hunt control (PT2-14). Application exit and actual ending choices are separate; the retained headless termination command is not an offered player action.

Sources: [GameSession](../packages/monstrous_core/lib/src/session/game_session.dart), [ProfileData](../packages/monstrous_core/lib/src/persistence/profile_data.dart), [blueprint catalog](../packages/monstrous_core/lib/src/model/flagship_blueprint.dart). Narrative rationale lives in [Lore](LORE.md).

## Navigation and regions

Dead Reckoning offers Port, Dead Ahead, and Starboard lookout headings. They are upcoming course choices, not freely selectable tiles of the old Java battle grid. Scouting identifies or describes encounters; fog and Covenant modifiers must respect that information boundary.

| Region | Legs | Guaranteed midpoint Haven | Regional Titan | Following stronghold |
| --- | --- | --- | --- | --- |
| The Siren Shoals | 10 | 5 | The Kraken, leg 10 | Fort Krakenwatch |
| The Sargasso Drift | 12 | 6 | The World Serpent, leg 12 | The Iron Bastion |
| The Boiling Reach | 14 | 7 | The Ancient Leviathan, leg 14 | Caldera ending choice |

Hunter's Respite is the ancestral home. Havens and Titans use a single convergent heading. Reckless Helmsman blocks Dead Ahead when alternatives exist, with the convergence exception preventing a soft lock; Blood Oath can compel the Nemesis course. Heading availability must be communicated by the UI (PT2-15).

The voyage's leg/history and course state are persisted alongside legacy coordinates. Chart redesign, direct post-loot course selection, and the heading flash are open PT2-08/09/10; they are not already implemented by this document. Sources: [SeaChart](../packages/monstrous_core/lib/src/rules/sea_chart.dart), [HelmScreen](../apps/monstrous_sea/lib/src/screens/helm_screen.dart).

## Hardpoints

Each blueprint has exactly three intrinsic mounts: Broadside (0T reload), Signature (1T cooldown), and Utility (2T cooldown). Intrinsic weapons cannot be bought as random equipment, unequipped, stacked in extra mounts, or swapped from cargo. Three baseline belt slots hold consumables; Corsair has four, and the permanent belt expansion adds capacity without pre-tempering the Broadside.

| Blueprint | Broadside | Signature | Utility |
| --- | --- | --- | --- |
| Standard | Naval Cannon Battery — Piercing | Twin Chaser Cannons — Piercing | Gunnery Drill |
| Ironclad | Heavy Carronades — Piercing | Reinforced Prow Ram — Piercing | Fortify Iron Plates |
| Clipper | Long-Barrel Swivel Guns — Piercing | Precision Culverin — Piercing | Evasive Rigging |
| Bombardier | Shrapnel Howitzers — Slicing | Heavy Siege Mortar — Blast | Phosphor Spotter Flare |
| Corsair | Chain-Shot Broadside — Slicing | Harpoon Winch — Piercing | Drifting Tether-Trap |

### Range and accuracy baseline

These are current level-1 weapon rolls and range damage efficiencies before tempering, ancestral signature tiers, blessings, and other modifiers. Accuracy is a percentile hit-roll input; target evasion is a separate avoidance step.

| Weapon | Base damage | Base accuracy | Short | Medium | Long |
| --- | --- | --- | --- | --- | --- |
| Naval Cannon Battery | 8–12 | 85% | 85% | 100% | 65% |
| Heavy Carronades | 12–15 | 85% | 100% | 80% | 35% |
| Long-Barrel Swivel Guns | 9–11 | 90% | 75% | 100% | 100% |
| Shrapnel Howitzers | 10–13 | 85% | 70% | 100% | 75% |
| Chain-Shot Broadside | 10–13 | 85% | 100% | 85% | 45% |
| Twin Chaser Cannons | 16–20 | 95% | 75% | 100% | 90% |
| Reinforced Prow Ram | 20–25 | 90% | 100% | 125%, charge into Short | Unusable |
| Precision Culverin | 16–20 | 95% | 40% | 85% | 100% |
| Heavy Siege Mortar | 22–28 | 80% | 70%, with self-backfire | 85% | 100% |
| Harpoon Winch | 14–18 | 85% | 85% | 100% | 85% |

Long-range Naval Cannon shots also lose 15 percentage points of accuracy. Culverin pierces half of Carapace; Heavy Mortar deals 2× shell damage and has 25% point-blank backfire based on its dealt-damage calculation. Harpoon pulls the monster closer, severs tentacles, and Pins; Chain-Shot gains 20% damage against Pinned targets. Resolve exact modifier ordering from [combat.dart](../packages/monstrous_core/lib/src/rules/combat.dart) and [traits](../packages/monstrous_core/lib/src/traits/trait.dart), not older range-affinity diagrams. Weapon rolls/types come from [ship_weapons.dart](../packages/monstrous_core/lib/src/content/ship_weapons.dart).

### Utility behavior

| Utility | Current role |
| --- | --- |
| Gunnery Drill | Brace for 20% reduced incoming damage this round; empower the next volley with +15% accuracy and a baseline +20% damage bonus, scaled by utility mark where implemented. |
| Fortify Iron Plates | Build combat-only damage reduction and anchor against push/pull for the current round. |
| Evasive Rigging | Increase evasion until a successful dodge consumes the boost; open range by one band when not blocked by grapple. |
| Phosphor Spotter Flare | Clear obscurity and suppress monster evasion; illuminate for two turns with baseline +15% shot accuracy and +25% Blast damage, scaled by utility mark. Howitzers remain Slicing and receive no Blast-only bonus. |
| Drifting Tether-Trap | Place a drifting trap according to range; movement/current and Harpoon pulls can bring it into contact. Detonation deals Slicing damage and Pins. |

Source for cooldowns, scaling, and trap timing: [GameSession utility handler](../packages/monstrous_core/lib/src/session/game_session.dart). Utility activation can also trigger its dedicated Ocean Power blessing.

## Combat resolution and monster behavior

- Helm orders and intrinsic mobility act within the three Short/Medium/Long bands. Monster intent previews describe threatened ranges, movement timing, and windups. Out-of-range attacks and intentional interruption are important counterplay.
- Hit chance is a bounded d100 percentage, currently clamped to 25–95 after applicable accuracy modifiers. AC and d20 hit bonuses are retired. Dodge is resolved separately after a successful hit roll; UI explanations of “accuracy” must not conflate the two probabilities.
- Ship range modifies ship evasion (+15 at Long, −15 at Short). Serpents have fixed innate dodge: 20% normally and 30% for Apex/World Serpents. Recoil retreats without adding dodge. Pin halves monster dodge for the turn and prevents recoil movement; Spotter Flare suppresses dodge. The monster HUD shows this effective dodge separately from weapon accuracy (PT2-12).
- Ink obscurity reduces shot accuracy by the monster's penalty in percentage points (normally 20 for squid, 25 for the level-5 Kraken), separately from dodge and subject to the normal hit-chance bounds. Successful hits have a 25% chance to disperse it; Spotter Flare clears/suppresses it. There is no fixed ink duration. Ink narration intentionally stays brief without naming a counter hardpoint; Spotter Flare's tooltip explains its clearing/suppression capabilities. The monster HUD and opening-shot tooltips explain the current effect; the internal `obscuredAcMod` name is legacy compatibility, not an AC mechanic (PT2-17).
- Ordinary Blast damage shatters Carapace at 1.5×; Heavy Mortar uses 2×. Fire bypasses shell. Piercing/Slicing/Shock are normally absorbed point-for-point, with weapon/blessing-specific exceptions. Massive targets provide the implemented Blast accuracy synergy; normal intrinsic weapons do not become elemental by default.
- Ordinary squid have `40 + 20 * (level - 1)` HP and `clamp(level + 3, 4, 8)` tentacles; Apex adds 2 limbs alongside its existing HP/Carapace enhancements. Kraken has 12 limbs while retaining its default 300 HP and 38-base-Blast maelstrom. Sweeping Tentacles consistently uses a Tentacle weapon, striking once per remaining limb at Short/Medium. The preview displays the strike count and gross damage before avoidance/defenses; Long range avoids the sweep. Slicing and Harpoon hits sever limbs, while all hulls retain helm and defensive counterplay. Per-hit armor remains valuable. These accepted starting values still need broader player balance feedback (PT2-22); Blade Launcher is not reinstated as loot.
- Tentacle hits deal 2–3 base damage at levels 1–2, then increase by 1 every two levels: 3 at levels 3–4, 4 at 5–6, 5 at 7–8, 6 at 9–10 and 7 at 11–12. With 8 intact limbs, ordinary sweeps reach 32–40 base damage in Region 2 and 48–56 in Region 3 before accuracy, dodge, weakening and defenses. Apex adds limbs rather than another per-hit multiplier. The default level-5 Kraken retains 4 damage per tentacle and its separate 38-base-Blast release.
- Monster Stun deterministically denies one action and then clears. Windup interruption uses the implemented Stun/weapon/blessing identities; no new damage-threshold Poise mechanic is authorized by leftover fields.
- The uninterrupted Kraken maelstrom releases 38 base Blast damage at all ranges, bypassing accuracy and dodge. Armor, Gunnery Drill bracing, Basalt Aegis and Corroded/Electro-Jolt weakening still apply through normal damage resolution. The full windup turn and existing disruption remain counterplay. The preview labels base damage before weakening/defenses. This rule applies only to the Kraken release; overall difficulty still needs player replay (PT2-18).
- Apex monsters have species-specific enhancements, additional HP and Carapace. Their stacked generated names need cleanup (PT2-13). Region 2 introduces kelp evasion drag and obscurity; Region 3 introduces periodic thermal scald, with stronger variants under the applicable Covenant pact.

Sources: [combat rules](../packages/monstrous_core/lib/src/rules/combat.dart), [monster intent/AI](../packages/monstrous_core/lib/src/rules/monster_ai.dart), [monster content](../packages/monstrous_core/lib/src/content/monsters.dart), [intent data](../packages/monstrous_core/lib/src/model/monster_intent.dart). Existing code is evidence of baseline behavior, not proof that the open balance concerns are resolved.

## Ocean Powers and shrines

There are four powers: Magma Vent-Lord, Tempest Sovereign, Brinemother, Earthshaker Titan. Every Broadside, Signature, and Utility socket can hold one dedication at Tier I–III. A socket dedicated to one power cannot be overwritten by another; the same power can upgrade it until Tier III. Blessings are voyage-scoped and survive region transitions and checkpoints (PT2-21).

Shrines sample two eligible powers without replacement, weighted 2.5× toward powers already able to upgrade/expand the current build. Fewer eligible powers produce fewer offerings. The player chooses a manifested power, then a socket to dedicate/upgrade. One dedication or rune choice consumes the shrine. “Read the Ancient Runes” remains the fallback when all sockets are sovereign: it refreshes a non-stacking +10% accuracy benefit for the entire next combat and reveals chart information. The actual command uses `ShrineChoice.ancientRunes`; no nonexistent `divination` enum is required.

Sources: [Ocean Power model](../packages/monstrous_core/lib/src/model/ocean_power.dart), [shrine rules](../packages/monstrous_core/lib/src/rules/shrine.dart), [combat riders](../packages/monstrous_core/lib/src/rules/combat.dart), [session lifecycle](../packages/monstrous_core/lib/src/session/game_session.dart).

### Blessing catalog

The tables below retain the accepted Phase 3B numerical design. Implementation decisions and modifier ordering immediately following them resolve its earlier conceptual API names and unspecified details. Future tuning must update this catalog alongside code and meaningful verification.

#### Magma Vent-Lord

| Hardpoint | Blessing Name | Tier I (Initiate) | Tier II (Resonant) | Tier III (Sovereign) |
| :--- | :--- | :--- | :--- | :--- |
| **Broadside (`0T`)** | **Magma Volley** | **`+10%`** weapon dmg; inflicts **Burn** (`6` Fire dmg/turn for 3T). | **`+20%`** weapon dmg; inflicts **Burn** (`10` Fire dmg/turn for 3T). | **`+30%`** weapon dmg; inflicts **Burn** (`15` Fire dmg/turn for 3T). |
| **Signature (`1T`)** | **Caldera Eruption** | **`+15%`** weapon dmg. If target is Burning, triggers **Thermal Detonation** (**`+25%`** Blast dmg, `1.5x` vs Carapace). | **`+25%`** weapon dmg. If target is Burning, triggers **Thermal Detonation** (**`+40%`** Blast dmg, `1.5x` vs Carapace). | **`+40%`** weapon dmg; inflicts **Burn** AND immediately triggers **Thermal Detonation** (**`+60%`** Blast dmg). |
| **Utility (`2T`)** | **Boiling Wake** | Activating Utility inflicts **Burn** (`3T`) and boils the water for `2T`: if the monster moves or charges a range band, it takes **`12` Fire dmg**. | Boiling Wake lasts `2T` and deals **`20` Fire dmg** whenever the monster moves or charges. | Boiling Wake lasts `3T`, deals **`30` Fire dmg** on monster movement, and increases all Burn tick damage by `+50%`. |

#### Tempest Sovereign

| Hardpoint | Blessing Name | Tier I (Initiate) | Tier II (Resonant) | Tier III (Sovereign) |
| :--- | :--- | :--- | :--- | :--- |
| **Broadside (`0T`)** | **Galvanic Broadside** | **`+10%`** weapon dmg; applies **`+1 Static Stack`** on hit. | **`+18%`** weapon dmg; applies **`+1 Static Stack`** on hit. | **`+25%`** weapon dmg; applies **`+1 Static Stack`** (`35%` chance for **`+2 Stacks`**). |
| **Signature (`1T`)** | **Thunderclap Prow** | **`+15%`** weapon dmg, **`+15%` Crit Chance**, and applies **`+2 Static Stacks`** on hit. | **`+25%`** weapon dmg, **`+15%` Crit Chance**, and applies **`+2 Static Stacks`** on hit. | **`+35%`** weapon dmg, **`+20%` Crit Chance**, and applies **`+3 Static Stacks`** (instant **Arc Discharge**!). |
| **Utility (`2T`)** | **Storm-Arc Rigging** | Activating Utility applies **`+1 Static Stack`** and charges hull for `2T`: when monster attacks you, arcs back for **`10` Shock dmg** + **`+1 Static Stack`**. | Hull charge arcs back for **`18` Shock dmg** + **`+1 Static Stack`** when attacked (`2T`). | Activating Utility applies **`+2 Static Stacks`**; hull charge arcs for **`26` Shock dmg** + **`+1 Static Stack`** (`2T`). |

#### Brinemother

| Hardpoint | Blessing Name | Tier I (Initiate) | Tier II (Resonant) | Tier III (Sovereign) |
| :--- | :--- | :--- | :--- | :--- |
| **Broadside (`0T`)** | **Caustic Volley** | **`+10%`** weapon dmg; strips **`2x` Carapace** (plus `+4` flat Carapace melt) and applies **`+1 Corroded Stack`**. | **`+18%`** weapon dmg; strips **`2x` Carapace** (plus `+8` flat Carapace melt) and applies **`+1 Corroded Stack`**. | **`+25%`** weapon dmg; strips **`2x` Carapace** (plus `+12` flat Carapace melt) and applies **`+2 Corroded Stacks`**. |
| **Signature (`1T`)** | **Acid-Bore Strike** | **`+15%`** weapon dmg; **pierces 100% of Carapace** to damage flesh directly (while still stripping Carapace) and applies **`+2 Corroded Stacks`**. | **`+25%`** weapon dmg; **pierces 100% of Carapace** and applies **`+2 Corroded Stacks`**. | **`+35%`** weapon dmg; **pierces 100% of Carapace**, applies **`+3 Corroded Stacks`**, and deals `+15%` bonus dmg if target has 0 Carapace. |
| **Utility (`2T`)** | **Verdigris Miasma** | Activating Utility clears **Monster Obscurity (ink/fog)**, melts **`8` Carapace**, and applies **`+1 Corroded Stack`**. | Clears **Monster Obscurity**, melts **`14` Carapace**, and applies **`+2 Corroded Stacks`**. | Clears **Monster Obscurity**, melts **`22` Carapace**, and applies **`+3 Corroded Stacks`**. |

#### Earthshaker Titan

| Hardpoint | Blessing Name | Tier I (Initiate) | Tier II (Resonant) | Tier III (Sovereign) |
| :--- | :--- | :--- | :--- | :--- |
| **Broadside (`0T`)** | **Tremor Volley** | **`+15%`** kinetic weapon dmg (`1.5x` vs Carapace) and shakes the beast (**`-10%` Monster Accuracy** for `1T`). | **`+25%`** kinetic weapon dmg (`1.5x` vs Carapace) and shakes the beast (**`-15%` Monster Accuracy** for `1T`). | **`+35%`** kinetic weapon dmg (`1.5x` vs Carapace) and shakes the beast (**`-20%` Monster Accuracy** for `1T`). |
| **Signature (`1T`)** | **Fault-Line Shatter** | **`+20%`** kinetic weapon dmg (`1.5x` vs Carapace). Striking during a **Lethal Windup** deals **`+25%` bonus dmg** and **cancels the windup** into a normal attack. | **`+35%`** kinetic weapon dmg (`1.5x` vs Carapace) + **Windup Cancel** (`+25%` bonus dmg). | **`+50%`** kinetic weapon dmg (`1.5x` vs Carapace) + **Windup Cancel** (`+35%` bonus dmg & `1T` Stun on windup break). |
| **Utility (`2T`)** | **Basalt Aegis** | Activating Utility encrusts hull with a **`15 HP` Stone Barrier** (`2T`) and surging wake (**`+15%` Ship Evasion** while barrier holds). When monster hits or breaks the barrier, a **Tidal Shockwave** deals **`12` Kinetic dmg** back (`1.5x` vs Carapace). | **`25 HP` Stone Barrier** (`2T`), **`+15%` Ship Evasion**, and **`20` Kinetic dmg** reactive **Tidal Shockwave**. | **`35 HP` Stone Barrier** (`2T`), **`+20%` Ship Evasion**, and **`30` Kinetic dmg** reactive **Tidal Shockwave**. |

### Integration and lifecycle rules

- Percentage blessing weapon buffs combine with range efficiency. Thermal Detonation uses weapon/range damage before the direct blessing bonus, applies Corroded once, preserves Burn, and preserves the weapon's intrinsic damage type.
- Magma ignition starts at 6/10/15 Fire per tick for its tiers; the implemented regional factor is +10% per region after the first. Boiling Wake responds to monster movement, including Harpoon pulls, rather than ship movement alone.
- Tempest critical hits use 1.5× damage. Three Static stacks trigger Arc Discharge: lethal windups are broken with a one-action Stun; ordinary actions receive Electro-Jolt (−30 accuracy, −25% damage) instead of an automatic hard stun.
- Corroded stacks cap at three and refresh their three-turn duration. They amplify damage by 8% per stack, or 12% with the relevant Tier III Brinemother upgrade; they are not the older “−15% monster damage / 5 plating per turn” concept.
- Earthshaker kinetic effects use the existing Piercing damage type with their explicit 1.5× shell multiplier. No extra Kinetic enum is required. Its normal windup cancellation substitutes a plain strike, not an unrelated species special attack.
- Direct weapon hits and extra blessing-damage events must not proc a relic twice. Simultaneous fatal retaliation must not revive a dead captain by resolving monster defeat first.
- Barriers, charged rigging, wakes, and other combat-only counters clear between battles; stored dedications persist for the voyage. Old saved Rams/Howitzers migrate to Piercing/Slicing. True new voyages clear dedications; stronghold departures preserve them.

## Supplies, encounters, and upgrades

Every consumable is single-use with fixed base potency/value independent of item rarity or region. Old bottles normalize to one remaining use or stay depleted. A quick belt action costs no turn; normally one is allowed per round, or two for Drillmaster, alongside helm + hardpoint action. Brace/reload is an emergency pass shown only when no offensive or utility hardpoint can end the turn; quick items do not count as turn-ending actions.

| Consumable | Current baseline role |
| --- | --- |
| Hull Patch Kit | Restore 30% max hull, subject to active healing rules. |
| Bottled Kraken Ink | Temporary +25% ship evasion smoke screen. |
| Alchemical Pitch Flask | Empower the next volley with the implemented incendiary coating/Burn interaction. |
| Unstable Tincture | Apply a random Burn, Poison, or Stun. |
| Blast Pack | Instant Blast attack. |
| Chakram | Instant Slicing attack. |

The last two currently use 75% hit / 5 base damage in [consumable effects](../packages/monstrous_core/lib/src/content/consumables.dart); no rarity scaling should be restored. Merchants trade tactical supplies with the existing markup/sale rules, not random hardpoint weapons. [Tactical victory loot](../packages/monstrous_core/lib/src/rules/loot.dart) drops consumables; older generic loot helpers are compatibility/parity code rather than the live loot specification.

At islands the three shore duties are mutually exclusive: careen, drill, or forage. Careen restores 30% at a Grand Haven or 20% at a cove; drills currently grant +15% accuracy rather than the old +5% note. Havens and strongholds offer the same voyage shipwright refits/tempering; secluded coves and home do not. Strongholds also offer paid repairs and merchant supplies; Master Refits remain deferred (PT2-20). After ordinary victory loot is stowed or explicitly left, the app opens Setting Course directly, with inspection collapsed below the headings. The core Rest phase remains a compatibility checkpoint; the app also bypasses it when restoring older saves. Titan reward resolution reaches the next stronghold or final ending choice instead. Emergency triage remains available on the helm, restoring only to the 25% hull floor at the existing two-gold-per-HP cost.

Shipwreck Search Hold always grants 2–4 Sea Glass, with independent chances of 25% for 1 Depth-Wrought Iron and 50% for one single-use consumable, in all regions. Strongbox grants 60–120 gold and 2–4 Sea Glass. Timbers restore up to 25% max hull under existing healing penalties and grant 1–2 Sea Glass. The results screen shows actual quantities/healing, including no usable consumable or zero hull healing. Full-belt supplies wait visibly for stowing, jettisoning a belt item, or explicitly leaving the supply. Departure requires resolving overflow. The spent salvage action, receipt, pending item and ship state persist across reload.

Keep these progression systems distinct:

| System | Scope | Current state |
| --- | --- | --- |
| Blueprint unlock/commission | Permanent unlock; selection at home between voyages. | Implemented; restricted to home, including after stronghold arrival (PT2-19). |
| Ancestral signature armament Tier I–III | Permanent blueprint-specific damage progression using trophies/materials. | Implemented; baseline multipliers 1.0× / 1.25× / 1.45×. Confusing inspection label: PT2-03. |
| Hull level / hardpoint Mk I–III | Temporary voyage upgrades. | Implemented at midpoint Havens and strongholds; preserved between regions (PT2-19/20). |
| Shrine dedication Tier I–III | Temporary voyage blessing on one of three sockets. | Implemented; retained between regions and across stronghold checkpoints (PT2-21). |
| Master Refit | Transformative voyage choice, intended after each of the first two Titans. | Deferred Phase 4; catalog, Standard coverage, economy and persistence need specification in PT2-20. |

## Meta-progression, heirs, and endings

Meta-materials and organics persist: Sea Glass, Monster Bone, Depth-Wrought Iron, Abyssal Barnacles. Titans always grant their trophy: Kraken's Beak, World Serpent's Scale, Leviathan Core. Gold is transient voyage spending, not a permanent bank. The first trophy should unlock meaningful capability; repeated trophies should have diminishing returns rather than trivializing earlier regions.

Three heir candidates carry one Maritime Boon and one Curious Quirk each. Current trait identities are Veteran Cannoneer, Storm Seer, Iron Constitution, Smuggler's Kin, Drillmaster; Blood Oath, Reckless Helmsman, Superstitious, Salt-Addict, Overzealous Gunner. The [BloodlineTrait catalog](../packages/monstrous_core/lib/src/model/bloodline_trait.dart) preserves current IDs, but several [TraitLore descriptions](../packages/monstrous_core/lib/src/lore/trait_lore.dart) are stale or lack matching runtime effects; do not treat that prose as approved gameplay requirements. The full Boon/Quirk audit and redesign discussion is tracked in [PT2-26](BACKLOG.md#pt2-26--revamp-heir-boons-and-quirks-for-current-mechanics); replacement rules remain undecided. The user's proposed permanent surname is not implemented by renaming this documentation.

A Nemesis records the killer and rewards vengeance. It is guaranteed as one of three navigation choices in the predecessor's region after the midpoint Haven and before the Titan. It remains available on eligible legs until engaged; avoiding it is allowed unless Blood Oath compels that heading. Side-heading placement keeps it reachable for Reckless Helmsman. Haven and Titan remain the only single-heading convergence points. The helm visibly disables quirk-restricted headings with the engine's shared reason, a persistent explanation and a tooltip; single-heading convergence remains exempt from Reckless Helmsman. Outgoing headings remain stable during the departure fade and ignore duplicate clicks. Courses are generated with the active Nemesis and Covenant context on approaching the helm; already offered helm choices persist across reload. See [SeaChart](../packages/monstrous_core/lib/src/rules/sea_chart.dart) and PT2-24 for the fix and verification status.

Only completed captain deaths enter the lineage ledger; unchosen heir candidates do not. The follow-up count of four was verified against four distinct saved records, including earlier playtesting (PT2-23). A new voyage does not reset cross-voyage lineage history.

After the Ancient Leviathan the player chooses Shatter the Core (end the curse) or Claim the Core (continue the bloodline with the Covenant unlocked). **Pact Burden** is the current difficulty term. Seven implemented pacts are Abyssal Vigor, Calcified Carapace, Feeding Frenzy, Choking Fog, Brittle Oak, Volatile Environs, Apex Emergence. Primordial Cinders come from Titan victories under active Pact Burden, not trivial ordinary encounters.

The Caldera choice screen explains the consequences before commitment; the full outcome then appears on a separate, scrollable reading screen. Choice labels, summaries, narration and outcome prose use `EldritchLore`. Acknowledgement does not reapply the choice: Shatter proceeds to a completed-hunt screen with no Start control, while Claim proceeds to heir selection. Claim retains its existing Core/Covenant/loop and ledger effects, with wording that the flagship returned alone rather than a declared ascension. Historical ledger text is preserved. The headless engine retains its existing `ended`/`death` phases; the app gates continuation on the outcome's read state.

Permanent signature tiers, blueprint-specific Eldritch Relics (Siphon Ram, Ghostwake Culverin, Brimstone Mortar, Sinew Winch), and Harbor Monuments exist in the current progression code. They are separate from the unimplemented Master Refit system and from the broader proposed living-town restoration. Exact current costs/effects live in [the progression catalog](../packages/monstrous_core/lib/src/model/covenant_of_the_deep.dart) and [its lore](../packages/monstrous_core/lib/src/lore/eldritch_lore.dart). Narrative ending canon is in [Lore](LORE.md#the-caldera-and-ending-choices); cinematic epilogues and Ancestral Chronicles are deferred presentation/features, not assumed delivered.

## Persistence and presentation

Load storage before deciding onboarding. `player_profile.json` stores cross-voyage lineage, materials and permanent unlocks; `voyage_save.json` stores checkpoint state including chart/history and blessings. Loot and shipwreck rewards retain checkpoints, including the victory-gold banner and exact wreck receipt. Strongholds and their merchants retain checkpoints, with the merchant's return location persisted. Legacy regional `port` checkpoints restore as strongholds. Home preparation and ordinary death clear the voyage checkpoint. The unresolved Caldera choice and resolved outcomes are checkpointed exceptions: choice/read state and offered heirs survive restart without reapplying rewards or rerolling candidates. Claim's checkpoint clears when an heir is chosen; Shatter retains its completed ending state. Older shattered-Font profiles without a checkpoint open the completed-hunt screen. Save operations capture state before I/O and execute in order so an older write cannot resurrect a voyage after ordinary death.

[StorageService](../apps/monstrous_sea/lib/src/services/storage_service.dart) stores Windows saves in `%LOCALAPPDATA%\TheMonstrousSea2\Saves`, outside the redirected Documents/OneDrive folder. Other platforms use their application-support directory under `TheMonstrousSea2/Saves`. There is no temporary-directory fallback for new saves. Injected directories isolate tests from real player data.

On first access, import the old Documents save pair (or the former system-temp fallback if no Documents save exists), keeping originals untouched as backups. Never overwrite saves already present in the new location or pair a newer profile with a stale legacy voyage. Migration completes before loading gameplay and resumes an interrupted copy before reads/writes proceed. A completion marker prevents future re-import after death or reset. A location/import failure shows a retry screen instead of starting a fresh voyage.

For a deliberately requested full-save reset, close the game, back up and delete only `player_profile.json` and `voyage_save.json` in the new directory, and retain `.legacy_migration_complete`. Deleting that marker with the whole folder makes the original backups eligible for import again. Documentation maintenance never resets a player's save.

The live Chronicle holds the current voyage's messages in session memory. Succession and fresh home departure clear older messages; ordinary encounters and strongholds retain the voyage history. Opening the Chronicle starts at the latest messages, and new entries follow the live end until the player scrolls back. **Latest Messages** resumes following; combat actions preserve deliberate history reading. Combat-log persistence and a historical archive are not implemented. The broader command-station layout remains pending in PT2-11.

Use approved transparent nautical raster art for entities/items; structural linework may use SVG or CustomPainter. Ships/weapons face right and monsters left. Preserve approved silhouettes, connected anatomy/rigging, true alpha, sparse ink detail, and the existing asset bundle; archived art is not added to it. Base text scale is 115%; percentage accuracy and meaningful text labels replace colorful emoji. Missing imagery remains deferred work in [the backlog](BACKLOG.md#deferred-ui-art-and-icons). Battle illustration load/decode failures now use a labeled cartouche with an inline retry, leaving combat active; successful recovery restores the approved art without changing battle state. The original intermittent Standard-asset failure still needs player replay (PT2-25).

## Retired systems and compatibility boundaries

The following are retired and must not be reintroduced by following historical instructions:

- AC/d20 combat, displayed hit-roll bonuses, and new defense modifiers based on AC.
- Flee/retreat-to-home gameplay and unrestricted mid-voyage returns to ancestral port.
- Freely equipped/swapped/dropped weapon inventory, cargo-tonnage/weapon-weight build constraints, and the fourth auxiliary weapon mount.
- Standalone Torpedo/Blade Launcher/Railgun/Flamethrower loot or shop stock. Their saved enums/art can remain for compatibility or deliberately designed future transformations.
- Consumable rarity tiers, region/rarity-based potency and prices, and multi-charge bottles.
- The fixed 4×5 grid as the player's current navigation design; legacy coordinates remain serialization/internal compatibility data.
- A starting ship-variation picker, starting Mk II expansion bonus, and home-port drydock/run tempering.
- Generic old “Heat” modifiers, damage-threshold Poise prescriptions, and superseded Ocean Power state diagrams.
- The SVG-only/no-raster art mandate.

Compatibility fields/helpers and legacy tests can retain old names. Removing them requires a separately scoped code/save migration; their continued presence does not restore the gameplay above. New ideas derived from history first belong in [Backlog](BACKLOG.md) as explicitly proposed designs.
