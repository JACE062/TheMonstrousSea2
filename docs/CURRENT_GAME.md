# Current game rules

Status: consolidated approved rules and implementation baseline as of 20 October 2026, after Phase 3B and the October 19 fixes. Read the [documentation authority rules](README.md#authority-and-status) and relevant [open issues](BACKLOG.md) before changing behavior. This consolidation introduces no gameplay changes or new feature approvals.

## Game identity and voyage lifecycle

The game is a generational naval roguelite centered on one Bloodbound Flagship, shaped by five ancestral blueprints: Standard, Ironclad, Clipper, Bombardier, Corsair. Tactical decisions, supplies, and voyage buildcrafting should sustain early-region tension even after permanent unlocks; repeated runs should not become automatic victories through unrestricted vertical stat growth.

- A fresh profile sees the brief introduction, names a captain, commissions Standard, and enters the first combat directly. Standard is the only starting unlocked blueprint. Expanded exposition and a permanent family surname are pending design work: PT2-01/02.
- After death, the next captain chooses from three heirs with boon/quirk pairs, may customize their name, and prepares at the ancestral home port. `Davy Jones` remains the existing hidden Flying Dutchman cheat, not a normal blueprint or starting choice.
- Home port supports permanent blueprint unlocks/commissioning, ancestral armament progression, and the applicable Covenant/relic/monument systems. Every true new voyage begins at hull level 1 and Mk I hardpoints; permanent armament progression is separate.
- **Approved target / known gap:** Mid-voyage strongholds must preserve the captain and current run build. They must not offer home-only blueprint switching or trigger new-voyage resets. The current shared `port` phase violates this boundary and can erase blessings/upgrades: PT2-19/21.
- A captain's ordinary death continues the bloodline; the remaining Abandon Hunt control is to be removed (PT2-14). Application exit and actual ending choices are separate from that gameplay branch.

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
- Ship range modifies effective evasion (+15 at Long, −15 at Short). Serpent Slither has its own avoidance behavior, currently capable of reaching 80% in the intent path; its fairness, buildup, and inconsistent legacy cap are under review (PT2-12).
- Monster ink currently reduces player accuracy through the legacy-named `obscuredAcMod`. The `+AC` log text is a bug, and converting ink to a true evasion bonus is not an implicit approved math change (PT2-17).
- Ordinary Blast damage shatters Carapace at 1.5×; Heavy Mortar uses 2×. Fire bypasses shell. Piercing/Slicing/Shock are normally absorbed point-for-point, with weapon/blessing-specific exceptions. Massive targets provide the implemented Blast accuracy synergy; normal intrinsic weapons do not become elemental by default.
- Slicing and Harpoon hits can sever squid/Kraken tentacles. Region scaling, per-tentacle attacks, armor interaction, and accessible counterplay need review (PT2-22); Blade Launcher is not reinstated as loot.
- Monster Stun deterministically denies one action and then clears. Windup interruption uses the implemented Stun/weapon/blessing identities; no new damage-threshold Poise mechanic is authorized by leftover fields.
- **Approved target / known gap:** The uninterrupted Kraken maelstrom must connect unavoidably and deliver a meaningful boss attack. Current normal-weapon selection and ordinary hit/dodge resolution do not yet guarantee this. Damage and mitigation details remain PT2-18 design/verification work.
- Apex monsters have species-specific enhancements, additional HP and Carapace. Their stacked generated names need cleanup (PT2-13). Region 2 introduces kelp evasion drag and obscurity; Region 3 introduces periodic thermal scald, with stronger variants under the applicable Covenant pact.

Sources: [combat rules](../packages/monstrous_core/lib/src/rules/combat.dart), [monster intent/AI](../packages/monstrous_core/lib/src/rules/monster_ai.dart), [monster content](../packages/monstrous_core/lib/src/content/monsters.dart), [intent data](../packages/monstrous_core/lib/src/model/monster_intent.dart). Existing code is evidence of baseline behavior, not proof that the open balance concerns are resolved.

## Ocean Powers and shrines

There are four powers: Magma Vent-Lord, Tempest Sovereign, Brinemother, Earthshaker Titan. Every Broadside, Signature, and Utility socket can hold one dedication at Tier I–III. A socket dedicated to one power cannot be overwritten by another; the same power can upgrade it until Tier III. Blessings are voyage-scoped and should survive region transitions and checkpoints (known violation: PT2-21).

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
- Barriers, charged rigging, wakes, and other combat-only counters clear between battles; stored dedications persist for the voyage. Old saved Rams/Howitzers migrate to Piercing/Slicing. True new voyages clear dedications; stronghold departures must not do so.

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

At islands the three shore duties are mutually exclusive: careen, drill, or forage. Careen restores 30% at a Grand Haven or 20% at a cove; drills currently grant +15% accuracy rather than the old +5% note. Havens offer voyage shipwright refits/tempering; secluded coves do not. Mid-voyage stronghold services are still missing (PT2-20). Shipwreck salvage gives supplies/materials, gold, or healing according to its choice; misleading weapon text and invisible receipts remain PT2-16.

Keep these progression systems distinct:

| System | Scope | Current state |
| --- | --- | --- |
| Blueprint unlock/commission | Permanent unlock; selection at home between voyages. | Implemented, with improper stronghold exposure tracked in PT2-19. |
| Ancestral signature armament Tier I–III | Permanent blueprint-specific damage progression using trophies/materials. | Implemented; baseline multipliers 1.0× / 1.25× / 1.45×. Confusing inspection label: PT2-03. |
| Hull level / hardpoint Mk I–III | Temporary voyage upgrades. | Implemented at midpoint Havens; stronghold availability and accidental resets remain open. |
| Shrine dedication Tier I–III | Temporary voyage blessing on one of three sockets. | Implemented; cross-region preservation bug remains open. |
| Master Refit | Transformative voyage choice, intended after each of the first two Titans. | Deferred Phase 4; catalog, Standard coverage, economy and persistence need specification in PT2-20. |

## Meta-progression, heirs, and endings

Meta-materials and organics persist: Sea Glass, Monster Bone, Depth-Wrought Iron, Abyssal Barnacles. Titans always grant their trophy: Kraken's Beak, World Serpent's Scale, Leviathan Core. Gold is transient voyage spending, not a permanent bank. The first trophy should unlock meaningful capability; repeated trophies should have diminishing returns rather than trivializing earlier regions.

Three heir candidates carry one Maritime Boon and one Curious Quirk each. Current trait identities are Veteran Cannoneer, Storm Seer, Iron Constitution, Smuggler's Kin, Drillmaster; Blood Oath, Reckless Helmsman, Superstitious, Salt-Addict, Overzealous Gunner. Use [BloodlineTrait](../packages/monstrous_core/lib/src/model/bloodline_trait.dart) and [TraitLore](../packages/monstrous_core/lib/src/lore/trait_lore.dart) for their actual rules. The user's proposed permanent surname is not implemented by renaming this documentation.

A Nemesis records the killer and rewards vengeance. It is guaranteed as one of three navigation choices in the predecessor's region after the midpoint Haven and before the Titan. It remains available on eligible legs until engaged; avoiding it is allowed unless Blood Oath compels that heading. Side-heading placement keeps it reachable for Reckless Helmsman. Haven and Titan remain the only single-heading convergence points. Courses are generated with the active Nemesis and Covenant context on approaching the helm; already offered helm choices persist across reload. See [SeaChart](../packages/monstrous_core/lib/src/rules/sea_chart.dart) and PT2-24 for the fix and verification status.

Only completed captain deaths enter the lineage ledger; unchosen heir candidates do not. The follow-up count of four was verified against four distinct saved records, including earlier playtesting (PT2-23). A new voyage does not reset cross-voyage lineage history.

After the Ancient Leviathan the player chooses Shatter the Core (end the curse) or Claim the Core (continue the bloodline with the Covenant unlocked). **Pact Burden** is the current difficulty term. Seven implemented pacts are Abyssal Vigor, Calcified Carapace, Feeding Frenzy, Choking Fog, Brittle Oak, Volatile Environs, Apex Emergence. Primordial Cinders come from Titan victories under active Pact Burden, not trivial ordinary encounters.

Permanent signature tiers, blueprint-specific Eldritch Relics (Siphon Ram, Ghostwake Culverin, Brimstone Mortar, Sinew Winch), and Harbor Monuments exist in the current progression code. They are separate from the unimplemented Master Refit system and from the broader proposed living-town restoration. Exact current costs/effects live in [the progression catalog](../packages/monstrous_core/lib/src/model/covenant_of_the_deep.dart) and [its lore](../packages/monstrous_core/lib/src/lore/eldritch_lore.dart). Narrative ending canon is in [Lore](LORE.md#the-caldera-and-ending-choices); cinematic epilogues and Ancestral Chronicles are deferred presentation/features, not assumed delivered.

## Persistence and presentation

Load storage before deciding onboarding. `player_profile.json` stores cross-voyage lineage, materials and permanent unlocks; `voyage_save.json` stores checkpoint state including chart/history and blessings. New runs and captain death have different lifetimes from stronghold visits. The current controller clears the checkpoint at every `port` phase, which needs the same lifecycle audit as PT2-19/21.

[StorageService](../apps/monstrous_sea/lib/src/services/storage_service.dart) stores Windows saves in `%LOCALAPPDATA%\TheMonstrousSea2\Saves`, outside the redirected Documents/OneDrive folder. Other platforms use their application-support directory under `TheMonstrousSea2/Saves`. There is no temporary-directory fallback for new saves. Injected directories isolate tests from real player data.

On first access, import the old Documents save pair (or the former system-temp fallback if no Documents save exists), keeping originals untouched as backups. Never overwrite saves already present in the new location or pair a newer profile with a stale legacy voyage. Migration completes before loading gameplay and resumes an interrupted copy before reads/writes proceed. A completion marker prevents future re-import after death or reset. A location/import failure shows a retry screen instead of starting a fresh voyage.

For a deliberately requested full-save reset, close the game, back up and delete only `player_profile.json` and `voyage_save.json` in the new directory, and retain `.legacy_migration_complete`. Deleting that marker with the whole folder makes the original backups eligible for import again. Documentation maintenance never resets a player's save.

Use approved transparent nautical raster art for entities/items; structural linework may use SVG or CustomPainter. Ships/weapons face right and monsters left. Preserve approved silhouettes, connected anatomy/rigging, true alpha, sparse ink detail, and the existing asset bundle; archived art is not added to it. Base text scale is 115%; percentage accuracy and meaningful text labels replace colorful emoji. Missing imagery remains deferred work in [the backlog](BACKLOG.md#deferred-ui-art-and-icons).

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
