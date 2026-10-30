# Current game rules

Status: current approved rules and implementation baseline, updated 20 October 2026 through Phase 3B, playtest fixes, and stronghold/home-port separation. Read the [documentation authority rules](README.md#authority-and-status) and relevant [open issues](BACKLOG.md) before changing behavior.

## Game identity and voyage lifecycle

The game is a generational naval roguelite centered on one Bloodbound Flagship, shaped by five ancestral blueprints: Standard, Ironclad, Clipper, Bombardier, Corsair. Tactical decisions, supplies, and voyage buildcrafting should sustain early-region tension even after permanent unlocks; repeated runs should not become automatic victories through unrestricted vertical stat growth.

The debug-only [playtest menu](../README.md#playtest-menu-debug-builds) can launch configured, disposable scenarios for development. Its blueprint/build grants and shortcuts are isolated fixtures, not alternate normal starting rules or permanent unlocks.

- Normal startup opens the title menu: Continue a selected lineage, create a New Lineage, open Settings or Exit Game. A fresh lineage sees the introduction, names a captain, commissions Standard, and enters the first combat directly. Standard is the only starting unlocked blueprint. Expanded exposition and a permanent family surname are pending design work: PT2-01/02.
- After death, the next captain chooses from three heirs with boon/quirk pairs, may customize their name, and prepares at the ancestral home port. `Davy Jones` remains the existing hidden Flying Dutchman cheat, not a normal blueprint or starting choice.
- Home port supports permanent blueprint unlocks/commissioning, ancestral armament progression, and the applicable Covenant/relic/monument systems. Unlocking requires an explicit purchase that spends the listed materials; having enough resources does not grant ownership, and commissioning an owned blueprint does not charge its unlock cost again. A test-save leakage path that can create unpaid Ironclad ownership is fixed in PT2-27; existing player unlocks are preserved. Every true new voyage begins at hull level 1 and Mk I fittings; permanent armament progression is separate.
- Mid-voyage strongholds have their own `stronghold` phase and preserve the captain, current blueprint, gold, belt, hull tier, fitting marks, and blessings. Arrival, merchant visits, reloads, and departure continue the current voyage. Permanent blueprint unlocks/upgrades and commissioning remain home-only, enforced in the engine as well as the UI. Returning home from a rest area is no longer a legal shortcut; home becomes available after succession (PT2-19/21).
- Havens and strongholds share the same gold-funded voyage shipwright: hull tiers cap at 4 with upgrade costs 100/250/500g; fittings cap at Mk III with tempering costs 60/120g. The home port offers neither voyage upgrade. Permanent ancestral armament progression uses meta-materials and is separate from these run tiers. Master Refits remain deferred work (PT2-20).
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

## Ship fittings

The player-facing collective name is **Ship Fittings**, with **fitting** for an individual Broadside, Signature or Utility. Standard's utility is **Gun-Deck Bracing**: the crew sets built-in hull and gun-deck braces to take the coming impact and steady the next volley. The former Hardpoint/Gunnery Drill terminology remains in historical evidence and internal compatibility identifiers; the rename changes no combat rule.

Each blueprint has exactly three intrinsic mounts: Broadside (0T reload), Signature (1T cooldown), and Utility (2T cooldown). Intrinsic weapons cannot be bought as random equipment, unequipped, stacked in extra mounts, or swapped from cargo. Three baseline belt slots hold consumables; Corsair has four, and the permanent belt expansion adds capacity without pre-tempering the Broadside.

| Blueprint | Broadside | Signature | Utility |
| --- | --- | --- | --- |
| Standard | Naval Cannon Battery — Piercing | Twin Chaser Cannons — Piercing | Gun-Deck Bracing |
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

Prow Ram closes to Short before its attack attempt and impact. It retains the approved +25% momentum bonus when launched from Medium; its Short impact does not remove that charge bonus. Harpoon resolves its attack using the launch range, then pulls the monster closer. Skirmisher’s committed helm follows either action and its intrinsic movement.

Long-range Naval Cannon shots also lose 15 percentage points of accuracy. Culverin pierces half of Carapace; Heavy Mortar deals 2× shell damage and has 25% point-blank backfire based on its dealt-damage calculation. Harpoon pulls the monster closer, severs tentacles, and Pins; Chain-Shot gains 20% damage against Pinned targets. Resolve exact modifier ordering from [combat.dart](../packages/monstrous_core/lib/src/rules/combat.dart) and [traits](../packages/monstrous_core/lib/src/traits/trait.dart), not older range-affinity diagrams. Weapon rolls/types come from [ship_weapons.dart](../packages/monstrous_core/lib/src/content/ship_weapons.dart).

### Utility behavior

| Utility | Current role |
| --- | --- |
| Gun-Deck Bracing | Brace for 20% reduced incoming damage this round; empower the next volley with +15% accuracy and a baseline +20% damage bonus, scaled by utility mark where implemented. |
| Fortify Iron Plates | Build combat-only damage reduction and anchor against push/pull for the current round. |
| Evasive Rigging | Set evasion to base +25%/+40%/+55% at Mk I/II/III until a successful dodge consumes the boost; open range by one band when not blocked by grapple. Captain/Basalt bonuses apply separately, with 95% final dodge cap. Repeated activation refreshes rather than stacks. |
| Phosphor Spotter Flare | Clear obscurity and suppress monster evasion; illuminate for two turns with baseline +15% shot accuracy and +25% Blast damage, scaled by utility mark. Howitzers remain Slicing and receive no Blast-only bonus. |
| Drifting Tether-Trap | Place a drifting trap according to range; movement/current and Harpoon pulls can bring it into contact. Detonation deals Slicing damage and Pins. |

Source for cooldowns, scaling, and trap timing: [GameSession utility handler](../packages/monstrous_core/lib/src/session/game_session.dart). Utility activation can also trigger its dedicated Ocean Power blessing.

**Evasive Rigging progression, approved and implemented 29 October 2026:** The utility uses an additive +25/+40/+55 percentage points over the current hull's base evasion. A fresh Clipper's base 25 gives 50/65/80%; a tier IV Clipper's base 40 gives 65/80/95% before captain/blessing bonuses and the final cap. Inspection and battle tooltips share numeric copy derived from the same core getters as activation. The two-turn cooldown, successful-dodge consumption, one-band movement and grapple limits are retained. See [PT2-30](BACKLOG.md#pt2-30--clipper-utility-tempering-has-no-visible-or-implemented-mk-progression).

## Combat resolution and monster behavior

Titan approach calls use The Kraken, The World Serpent and The Ancient Leviathan, matching their battle identities. Restored pending Titan offers receive the same correction; ordinary generated names, Nemesis identities and completed voyage history retain their own text.

- Helm orders and intrinsic mobility act within the three Short/Medium/Long bands. Monster intent previews describe threatened ranges, movement timing, and windups. Out-of-range attacks and intentional interruption are important counterplay.
- Hit chance is a bounded d100 percentage, currently clamped to 25–95 after applicable accuracy modifiers. AC and d20 hit bonuses are retired. Dodge is resolved separately after a successful hit roll; UI explanations of “accuracy” must not conflate the two probabilities.
- Ship dodge uses current ship evasion plus captain and active Basalt Aegis bonuses, clamped to 0–95%. There is no automatic Short/Medium/Long modifier: the former +15% at Long and −15% at Short were removed by user decision on 29 October 2026. A stock Clipper has 25% dodge at every range (50% while its current Mk I Evasive Rigging boost is active); a stock Ironclad has 0%. Successful dodges still consume the temporary evasion boost, and unavoidable attacks bypass dodge. Monster threatened ranges, attack accuracy and weapon range damage retain their existing roles.
- Ship and monster name-panel percentages use the same effective dodge thresholds as combat, including current regional debuffs, captain bonuses, active defenses, caps, Pin and Flare. A zero value remains visible. Captain context travels in transient effect snapshots, so playback updates these numbers at the corresponding effect/barrier event rather than reading future live state. Tooltips distinguish dodge from accuracy and explain the unavoidable-attack exception.
- Serpents have fixed innate dodge: 20% normally and 30% for Apex/World Serpents. Recoil retreats without adding dodge. Pin halves monster dodge for the turn and prevents recoil movement; Spotter Flare suppresses dodge. The monster HUD shows this effective dodge separately from weapon accuracy (PT2-12).
- Ink obscurity reduces shot accuracy by the monster's penalty in percentage points (normally 20 for squid, 25 for the level-5 Kraken), separately from dodge and subject to the normal hit-chance bounds. Successful hits have a 25% chance to disperse it; Spotter Flare clears/suppresses it. There is no fixed ink duration. Ink narration intentionally stays brief without naming a counter fitting; Spotter Flare's tooltip explains its clearing/suppression capabilities. The monster HUD and opening-shot tooltips explain the current effect; the internal `obscuredAcMod` name is legacy compatibility, not an AC mechanic (PT2-17).
- Ordinary Blast damage shatters Carapace at 1.5×; Heavy Mortar uses 2×. Fire bypasses shell. Piercing/Slicing/Shock are normally absorbed point-for-point, with weapon/blessing-specific exceptions. Massive targets provide the implemented Blast accuracy synergy; normal intrinsic weapons do not become elemental by default.
- Ordinary squid have `40 + 20 * (level - 1)` HP and `clamp(level + 3, 4, 8)` tentacles; Apex adds 2 limbs alongside its existing HP/Carapace enhancements. Kraken has 12 limbs while retaining its default 300 HP and 38-base-Blast maelstrom. Sweeping Tentacles consistently uses a Tentacle weapon, striking once per remaining limb at Short/Medium. The preview displays the strike count and gross damage before avoidance/defenses; Long range avoids the sweep. Slicing and Harpoon hits sever limbs, while all hulls retain helm and defensive counterplay. Per-hit armor remains valuable. These accepted starting values still need broader player balance feedback (PT2-22); Blade Launcher is not reinstated as loot.
- Tentacle hits deal 2–3 base damage at levels 1–2, then increase by 1 every two levels: 3 at levels 3–4, 4 at 5–6, 5 at 7–8, 6 at 9–10 and 7 at 11–12. With 8 intact limbs, ordinary sweeps reach 32–40 base damage in Region 2 and 48–56 in Region 3 before accuracy, dodge, weakening and defenses. Apex adds limbs rather than another per-hit multiplier. The default level-5 Kraken retains 4 damage per tentacle and its separate 38-base-Blast release.
- Poison deals `5 × current difficulty` HP damage after the monster response under the default balance configuration, bypassing attack armor/barriers; Iron Constitution halves its damage. Each nonfatal tick has a 25% recovery chance rather than a fixed duration. Ship combat statuses clear at battle cleanup and encounter startup, so unresolved Poison/Burn/Stun cannot carry into later fights. Serialized ships already omit combat statuses; non-battle in-memory checkpoint restoration also clears them without healing or changing the build.
- Monster Stun deterministically denies one response, including its movement and attack, then clears. Stun does not apply Pin or reduce dodge; independent pinning effects can coexist with it. Windup interruption uses the implemented Stun/weapon/blessing identities; no new damage-threshold Poise mechanic is authorized by leftover fields.
- The uninterrupted Kraken maelstrom releases 38 base Blast damage at all ranges, bypassing accuracy and dodge. Armor, Gun-Deck Bracing, Basalt Aegis and Corroded/Electro-Jolt weakening still apply through normal damage resolution. The full windup turn and existing disruption remain counterplay. The preview labels base damage before weakening/defenses. This rule applies only to the Kraken release; overall difficulty still needs player replay (PT2-18).
- Apex monsters have species-specific enhancements, additional HP and Carapace. Their stacked generated names need cleanup (PT2-13). An Apex Shark retains 0% dodge.
- Sargasso encounters start with Phosphor Haze: a minimum 10-percentage-point shot-accuracy penalty, preserving stronger squid ink at 20/25 rather than stacking. The user approved this minimum on 30 October 2026. Haze uses the existing hit-based Obscurity dispersal and Flare clearing rules; it adds no monster dodge or recurring reapplication. Ghostwake's Culverin bypass remains. Tangled Kelp separately lowers ship evasion by 10, or 20 under Volatile Environs; that pact does not increase haze. Narration and the monster HUD show the actual accuracy penalty. Region 3 retains periodic thermal scald, with its stronger pact variant.

Sources: [combat rules](../packages/monstrous_core/lib/src/rules/combat.dart), [ship dodge and defenses](../packages/monstrous_core/lib/src/traits/trait.dart), [monster intent/AI](../packages/monstrous_core/lib/src/rules/monster_ai.dart), [monster content](../packages/monstrous_core/lib/src/content/monsters.dart), [intent data](../packages/monstrous_core/lib/src/model/monster_intent.dart). Existing code is evidence of baseline behavior, not proof that the open balance concerns are resolved.

## Ocean Powers and shrines

There are four powers: Magma Vent-Lord, Tempest Sovereign, Brinemother, Earthshaker Titan. Every Broadside, Signature, and Utility socket can hold one dedication at Tier I–III. A socket dedicated to one power cannot be overwritten by another; the same power can upgrade it until Tier III. Blessings are voyage-scoped and survive region transitions and checkpoints (PT2-21).

Shrines sample two eligible powers without replacement, weighted 2.5× toward powers already able to upgrade/expand the current build. Fewer eligible powers produce fewer offerings. The player chooses a manifested power, then a socket to dedicate/upgrade. One dedication or rune choice consumes the shrine. “Read the Ancient Runes” remains the fallback when all sockets are sovereign: it refreshes a non-stacking +10% accuracy benefit for the entire next combat and reveals chart information. The actual command uses `ShrineChoice.ancientRunes`; no nonexistent `divination` enum is required.

Sources: [Ocean Power model](../packages/monstrous_core/lib/src/model/ocean_power.dart), [shrine rules](../packages/monstrous_core/lib/src/rules/shrine.dart), [combat riders](../packages/monstrous_core/lib/src/rules/combat.dart), [session lifecycle](../packages/monstrous_core/lib/src/session/game_session.dart).

### Blessing catalog

The tables below retain the accepted Phase 3B numerical design. Implementation decisions and modifier ordering immediately following them resolve its earlier conceptual API names and unspecified details. Future tuning must update this catalog alongside code and meaningful verification.

#### Magma Vent-Lord

| Fitting | Blessing Name | Tier I (Initiate) | Tier II (Resonant) | Tier III (Sovereign) |
| :--- | :--- | :--- | :--- | :--- |
| **Broadside (`0T`)** | **Magma Volley** | **`+10%`** weapon dmg; inflicts **Burn** (`6` Fire dmg/turn for 3T). | **`+20%`** weapon dmg; inflicts **Burn** (`10` Fire dmg/turn for 3T). | **`+30%`** weapon dmg; inflicts **Burn** (`15` Fire dmg/turn for 3T). |
| **Signature (`1T`)** | **Caldera Eruption** | **`+15%`** weapon dmg. If target is Burning, triggers **Thermal Detonation** (**`+25%`** Blast dmg, `1.5x` vs Carapace). | **`+25%`** weapon dmg. If target is Burning, triggers **Thermal Detonation** (**`+40%`** Blast dmg, `1.5x` vs Carapace). | **`+40%`** weapon dmg; inflicts **Burn** AND immediately triggers **Thermal Detonation** (**`+60%`** Blast dmg). |
| **Utility (`2T`)** | **Boiling Wake** | Activating Utility inflicts **Burn** (`3T`) and boils the water for `2T`: if the monster moves or charges a range band, it takes **`12` Fire dmg**. | Boiling Wake lasts `2T` and deals **`20` Fire dmg** whenever the monster moves or charges. | Boiling Wake lasts `3T`, deals **`30` Fire dmg** on monster movement, and increases all Burn tick damage by `+50%`. |

#### Tempest Sovereign

| Fitting | Blessing Name | Tier I (Initiate) | Tier II (Resonant) | Tier III (Sovereign) |
| :--- | :--- | :--- | :--- | :--- |
| **Broadside (`0T`)** | **Galvanic Broadside** | **`+10%`** weapon dmg; applies **`+1 Static Stack`** on hit. | **`+18%`** weapon dmg; applies **`+1 Static Stack`** on hit. | **`+25%`** weapon dmg; applies **`+1 Static Stack`** (`35%` chance for **`+2 Stacks`**). |
| **Signature (`1T`)** | **Thunderclap Prow** | **`+15%`** weapon dmg, **`+15%` Crit Chance**, and applies **`+2 Static Stacks`** on hit. | **`+25%`** weapon dmg, **`+15%` Crit Chance**, and applies **`+2 Static Stacks`** on hit. | **`+35%`** weapon dmg, **`+20%` Crit Chance**, and applies **`+3 Static Stacks`** (instant **Arc Discharge**!). |
| **Utility (`2T`)** | **Storm-Arc Rigging** | Activating Utility applies **`+1 Static Stack`** and charges hull for `2T`: when monster attacks you, arcs back for **`10` Shock dmg** + **`+1 Static Stack`**. | Hull charge arcs back for **`18` Shock dmg** + **`+1 Static Stack`** when attacked (`2T`). | Activating Utility applies **`+2 Static Stacks`**; hull charge arcs for **`26` Shock dmg** + **`+1 Static Stack`** (`2T`). |

#### Brinemother

| Fitting | Blessing Name | Tier I (Initiate) | Tier II (Resonant) | Tier III (Sovereign) |
| :--- | :--- | :--- | :--- | :--- |
| **Broadside (`0T`)** | **Caustic Volley** | **`+10%`** weapon dmg; strips **`2x` Carapace** (plus `+4` flat Carapace melt) and applies **`+1 Corroded Stack`**. | **`+18%`** weapon dmg; strips **`2x` Carapace** (plus `+8` flat Carapace melt) and applies **`+1 Corroded Stack`**. | **`+25%`** weapon dmg; strips **`2x` Carapace** (plus `+12` flat Carapace melt) and applies **`+2 Corroded Stacks`**. |
| **Signature (`1T`)** | **Acid-Bore Strike** | **`+15%`** weapon dmg; **pierces 100% of Carapace** to damage flesh directly (while still stripping Carapace) and applies **`+2 Corroded Stacks`**. | **`+25%`** weapon dmg; **pierces 100% of Carapace** and applies **`+2 Corroded Stacks`**. | **`+35%`** weapon dmg; **pierces 100% of Carapace**, applies **`+3 Corroded Stacks`**, and deals `+15%` bonus dmg if target has 0 Carapace. |
| **Utility (`2T`)** | **Verdigris Miasma** | Activating Utility clears **Monster Obscurity (ink/fog)**, melts **`8` Carapace**, and applies **`+1 Corroded Stack`**. | Clears **Monster Obscurity**, melts **`14` Carapace**, and applies **`+2 Corroded Stacks`**. | Clears **Monster Obscurity**, melts **`22` Carapace**, and applies **`+3 Corroded Stacks`**. |

#### Earthshaker Titan

| Fitting | Blessing Name | Tier I (Initiate) | Tier II (Resonant) | Tier III (Sovereign) |
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

Every consumable is single-use with fixed base potency/value independent of item rarity or region. Old bottles normalize to one remaining use or stay depleted. A quick belt action costs no turn; normally one is allowed per round, or two for Drillmaster, alongside helm + fitting action. **Wait & Reload** is an emergency/recovery pass shown only when no offensive or utility fitting can end the turn, including Impatient recovery; quick items do not count as turn-ending actions. It resolves any committed helm, the monster response and normal fitting cooldowns, granting no evasion bonus. Skirmisher does not make it available while a fitting action remains usable.

The shared voyage shipwright panel at midpoint Havens and strongholds shows the live purse directly above hull/fitting upgrade costs; spending refreshes the balance and affordability. The existing home-port gold badge and stronghold captain summary remain available.

| Consumable | Current baseline role |
| --- | --- |
| Hull Patch Kit | Restore 30% max hull, subject to active healing rules. |
| Bottled Kraken Ink | Temporary +25% ship evasion smoke screen. |
| Alchemical Pitch Flask | Empower the next volley with the implemented incendiary coating/Burn interaction. |
| Unstable Tincture | Apply a random Burn, Poison, or Stun. |
| Blast Pack | Instant Blast attack. |
| Chakram | Instant Slicing attack. |

The last two currently use 75% hit / 5 base damage in [consumable effects](../packages/monstrous_core/lib/src/content/consumables.dart); no rarity scaling should be restored. Merchants trade tactical supplies with the existing markup/sale rules, not random fitting weapons. [Tactical victory loot](../packages/monstrous_core/lib/src/rules/loot.dart) drops consumables; older generic loot helpers are compatibility/parity code rather than the live loot specification.

At islands the three shore duties are mutually exclusive: careen, drill, or forage. Careen restores 30% at a Grand Haven or 20% at a cove; drills currently grant +15% accuracy rather than the old +5% note. Havens and strongholds offer the same voyage shipwright refits/tempering; secluded coves and home do not. Strongholds also offer paid repairs and merchant supplies; Master Refits remain deferred (PT2-20). After ordinary victory loot is stowed or explicitly left, the app opens Setting Course directly, with inspection collapsed below the headings. The core Rest phase remains a compatibility checkpoint; the app also bypasses it when restoring older saves. Titan reward resolution reaches the next stronghold or final ending choice instead. Emergency triage remains available on the helm, restoring only to the 25% hull floor at the existing two-gold-per-HP cost.

Shipwreck Search Hold always grants 2–4 Sea Glass, with independent chances of 25% for 1 Depth-Wrought Iron and 50% for one single-use consumable, in all regions. Strongbox grants 60–120 gold and 2–4 Sea Glass. Timbers restore up to 25% max hull under existing healing penalties and grant 1–2 Sea Glass. The results screen shows actual quantities/healing, including no usable consumable or zero hull healing. Full-belt supplies wait visibly for stowing, jettisoning a belt item, or explicitly leaving the supply. Departure requires resolving overflow. The spent salvage action, receipt, pending item and ship state persist across reload.

Keep these progression systems distinct:

| System | Scope | Current state |
| --- | --- | --- |
| Blueprint unlock/commission | Permanent unlock; selection at home between voyages. | Implemented; restricted to home, including after stronghold arrival (PT2-19). |
| Ancestral signature armament Tier I–III | Permanent blueprint-specific damage progression using trophies/materials. | Implemented; baseline multipliers 1.0× / 1.25× / 1.45×. Confusing inspection label: PT2-03. |
| Hull level / fitting Mk I–III | Temporary voyage upgrades. | Implemented at midpoint Havens and strongholds; preserved between regions (PT2-19/20). |
| Shrine dedication Tier I–III | Temporary voyage blessing on one of three sockets. | Implemented; retained between regions and across stronghold checkpoints (PT2-21). |
| Master Refit | Transformative voyage choice, intended after each of the first two Titans. | Deferred Phase 4; catalog, Standard coverage, economy and persistence need specification in PT2-20. |

## Meta-progression, heirs, and endings

Meta-materials and organics persist: Sea Glass, Monster Bone, Depth-Wrought Iron, Abyssal Barnacles. Titans always grant their trophy: Kraken's Beak, World Serpent's Scale, Leviathan Core. Gold is transient voyage spending, not a permanent bank. The first trophy should unlock meaningful capability; repeated trophies should have diminishing returns rather than trivializing earlier regions.

Three heir candidates each carry one Maritime Boon and one Curious Quirk. The implemented catalog has **eight Boons and eight Quirks**. Boons provide a benefit; Quirks provide a thematic bonus with a direct drawback or a required risky/restrictive playstyle. Daredevil's low-hull requirement is sufficient without another stat penalty. Trait descriptions come from [TraitLore](../packages/monstrous_core/lib/src/lore/trait_lore.dart), with the catalog and IDs in [BloodlineTrait](../packages/monstrous_core/lib/src/model/bloodline_trait.dart).

| Boon | Implemented effect |
| --- | --- |
| Veteran Cannoneer | Broadside/Signature hits deal 25% additional Carapace damage without a direct HP damage bonus. |
| Storm-Seer | Read the Winds redraws ordinary headings once per region at Set Course. Fixed Haven/Titan courses and the exact offered Nemesis course stay unchanged. Vendetta compulsion disables redraw; fog/reveals/pacts still apply. No progress, resources or rewards change; identical random offers still spend the use. |
| Iron Constitution | Ship Burn/Poison tick damage is reduced by 50%; normal recovery chances remain. |
| Smuggler's Kin | Choose one free stock consumable per smuggler encounter; smuggler repair prices are 25% lower. A full belt does not consume the gift. |
| Drillmaster | Two quick belt items per turn instead of one. All captains already have zero-turn item use. |
| Precise Commander | +5% shot accuracy for weapon attacks, within the normal bounds. |
| Skilled Carpenter | All healing restores 20% more hull. |
| Quartermaster | One additional tactical belt slot, stacking with the blueprint and permanent belt expansion, without stacking again on reload. |

| Quirk | Implemented effect / tradeoff |
| --- | --- |
| Blood Oath (Vendetta) | +30% weapon damage against an eligible Nemesis; its offered heading is compulsory. |
| Reckless Helmsman | Passive +10% evasion in every battle, including Titans; refuses Dead Ahead when alternative headings exist. The captain bonus survives successful dodges. |
| Superstitious | Ordinary heading Shrine chance is 10% instead of 7%, with the extra chance taken from combat. An omen forbids one of two manifested powers; a sole eligible power stays available. Normal dedication eligibility, existing-power weighting, fitting choice, runes and departure remain. |
| Exacting Shipwright | Incoming attack damage is reduced by 10% after armor/bracing and before barriers; all healing restores 25% less hull. Burn, Poison and environmental damage are not attacks. |
| Overzealous Gunner | Broadside/Signature weapon damage +20%, shot accuracy −10%. Utility and belt effects retain their normal potency. |
| Daredevil | Broadside/Signature weapon damage +30% while at or below 50% hull, checked when the weapon action begins. No separate healing/evasion penalty. |
| Impatient | Optionally Push the Crew: activate Utility, then one weapon action before the monster responds. The following recovery turn blocks fittings, but helm, belt and Wait & Reload remain available. Normal Utility use remains available. |
| Skirmisher | The helm commitment always resolves after the main action and its intrinsic movement, before the enemy responds. No always-available pass or extra defensive bonus. |

Impatient's combination is a commitment: after Utility, fire a legal ready weapon; no second helm maneuver, Utility or Wait & Reload can replace it. Both used fittings retain their normal cooldowns. Recovery ends through Wait & Reload (including Hold Line while grappled), or combat ending. Quick items do not repay recovery. The former Brace evasion bonus was removed by user decision on 29 October 2026; waiting neither adds nor stacks evasion. Skirmisher permits one committed helm order per turn; weapon accuracy/damage use the pre-helm firing range. Ram/Harpoon movement occurs before its late helm, and action-specific response forecasts show that resulting range. The shared intent forecast is labeled as helm-only when an action may change it. Armory inspection includes the captain's current trait names/descriptions; battle shows whether Daredevil's bonus is active using the same threshold gate as actual attacks.

Healing modifiers multiply before a single whole-HP rounding and the missing-hull cap. Haven careening restores 30% of maximum hull normally, 36% with Skilled Carpenter, 22.5% with Exacting Shipwright, and 27% with both before integer rounding. Paid repairs and emergency triage receive the same healing-efficiency modifiers; quotes show actual HP/cost, and triage prices the material needed to reach the 25% floor in one purchase. Hull refits retain their full maximum-hull increase, while their accompanying HP restoration uses the same healing modifiers. Fractional Exacting attack protection carries between hits within a battle so mitigation is not lost on small tentacle hits; it resets between battles.

Heir selection uses injected RNG, with three distinct Boons, Quirks and default names within each offer. Vendetta remains guaranteed among offered heirs when an eligible Nemesis exists and is excluded otherwise. Recent-offer weighting remains a proposal under [PT2-26](BACKLOG.md#pt2-26--revamp-heir-boons-and-quirks-for-current-mechanics). Pending offers persist across restart. The old `saltAddict` ID reads as Exacting Shipwright; historical rule versions are not retained. Verification never deletes player saves. A permanent family-surname redesign remains separate work.

Storm-Seer's usage and current offers persist across checkpoints; availability refreshes in a new region and resets at true home departure/succession. Shrine manifestations and Superstitious's forbidden power are deterministic for a persisted voyage omen seed and region/leg, including re-entry from the preceding helm checkpoint. This does not add Shrine/battle saving to the supported stop phases.

A Nemesis records an ordinary or Apex beast that killed a captain and rewards vengeance. The three Region Titans (Kraken, World Serpent and Ancient Leviathan) cannot become Nemeses. A Titan death clears any earlier active Nemesis, and its heirs cannot receive Blood Oath (Vendetta). The quirk is offered and selectable only with an eligible active Nemesis. Valid Nemeses are guaranteed as one of three navigation choices in the predecessor's region after the midpoint Haven and before the Titan. They remain available on eligible legs until engaged; avoiding them is allowed unless Blood Oath compels that heading. Side-heading placement keeps them reachable for Reckless Helmsman. Haven and Titan remain the only single-heading convergence points. The helm visibly disables quirk-restricted headings with the engine's shared reason, a persistent explanation and a tooltip; single-heading convergence remains exempt from Reckless Helmsman. Outgoing headings remain stable during the departure fade and ignore duplicate clicks. Courses are generated with the active Nemesis and Covenant context on approaching the helm; valid already offered helm choices persist across reload. See [SeaChart](../packages/monstrous_core/lib/src/rules/sea_chart.dart) and PT2-24 for the fix and verification status.

Legacy active Titan Nemesis records are discarded on load; the captain's death ledger, resources and progression remain intact. Saved pending Vendetta offers without an eligible target receive a stable replacement quirk without rerolling names, boons or other heir offers. Saved course sets containing a Titan Nemesis are discarded for normal helm regeneration; valid offers and the completed voyage log remain unchanged. Previously selected captains and their saved traits are not rerolled by this pending-offer repair.

Only completed captain deaths enter the lineage ledger; unchosen heir candidates do not. The follow-up count of four was verified against four distinct saved records, including earlier playtesting (PT2-23). A new voyage does not reset cross-voyage lineage history.

After the Ancient Leviathan the player chooses Shatter the Core (end the curse) or Claim the Core (continue the bloodline with the Covenant unlocked). **Pact Burden** is the current difficulty term. Seven implemented pacts are Abyssal Vigor, Calcified Carapace, Feeding Frenzy, Choking Fog, Brittle Oak, Volatile Environs, Apex Emergence. Primordial Cinders come from Titan victories under active Pact Burden, not trivial ordinary encounters.

The Caldera choice screen explains the consequences before commitment; the full outcome then appears on a separate, scrollable reading screen. Choice labels, summaries, narration and outcome prose use `EldritchLore`. Acknowledgement does not reapply the choice: Shatter proceeds to a completed-hunt screen with no Start control, while Claim proceeds to heir selection. Claim retains its existing Core/Covenant/loop and ledger effects, with wording that the flagship returned alone rather than a declared ascension. Historical ledger text is preserved. The headless engine retains its existing `ended`/`death` phases; the app gates continuation on the outcome's read state.

The completed-hunt screen offers Exit Game and, in a normal slotted game, Return to Menu. Normal sessions finish a final queued profile/ending save before requesting native application exit; failed saving or closing leaves a retryable message. Debug playtest sessions exit without saving. The title menu preserves independent lineages and completed hunts; Continue on a completed lineage displays its ending. For a completed original lineage with a valid pre-choice snapshot, the title menu offers Explore the Other Fate. It creates one independent alternate save at the Caldera decision; reopening continues that branch. Each save keeps its own progression and rewards, and the peaceful ending remains intact. Branches cannot spawn further branches. Older endings without a usable snapshot cannot be reconstructed. Ancestral Chronicles remains planned under [FUT-06](BACKLOG.md#completed-hunts-lineage-saves-and-alternate-fates).

Permanent signature tiers, blueprint-specific Eldritch Relics (Siphon Ram, Ghostwake Culverin, Brimstone Mortar, Sinew Winch), and Harbor Monuments exist in the current progression code. They are separate from the unimplemented Master Refit system and from the broader proposed living-town restoration. Exact current costs/effects live in [the progression catalog](../packages/monstrous_core/lib/src/model/covenant_of_the_deep.dart) and [its lore](../packages/monstrous_core/lib/src/lore/eldritch_lore.dart). Narrative ending canon is in [Lore](LORE.md#the-caldera-and-ending-choices); cinematic epilogues and Ancestral Chronicles are deferred presentation/features, not assumed delivered.

## Persistence and presentation

Load storage before deciding onboarding. Each lineage's `player_profile.json` stores cross-voyage history, materials and permanent unlocks; `voyage_save.json` stores supported checkpoint state including chart/history and blessings. Loot, wrecks, strongholds and merchants retain their existing checkpoint fields and legacy stronghold migration. Normal slotted controllers additionally retain home preparation and ordinary death's exact heir offers; these are preparation checkpoints, not revived captains. Direct-controller compatibility adapters retain their older home/death deletion policy. Caldera choice/read state survives restart without reapplying rewards or rerolling heirs. Succession clears the Caldera outcome and saves the new heir's home preparation; Shatter retains its completed ending. Older shattered-Font profiles without a checkpoint open the completed-hunt screen. Saves snapshot state before I/O and execute in order so older writes cannot restore stale voyage state after death.

A dedicated `pre_caldera_choice.json` stores a matched profile/voyage pair before an ending changes progression. It is published before resolved-ending writes and is separate from the active checkpoint; normal play never rewinds to it. The alternate save receives exactly that state, with no new reward grants. Failed branch publication retries against the same identity, while an already published branch is never overwritten by reopening it. Debug scenarios do not save snapshots.

The pause menu opens with Esc or an on-screen pause icon. It contains Resume, Settings, current lineage information, Save & Return to Title and Save & Exit Game. Saving and leaving are limited to captain creation, home, strongholds, helm, loot, wrecks, merchants, the Caldera choice, heir selection or a completed hunt, and wait for battle playback to finish. Combat, shrine, smuggler and island encounters require continuing to a supported stop because their complete live state is not serialized. Individual combat turns are not resumable saves. Failed saving or native exit leaves a retryable error; saving blocks input and dismissal until queued writes finish. The departing route unmounts before its controller is disposed. The F10 debug launcher remains available from a slotted game.

Pause blocks new pointer and keyboard gameplay input, while an action already underway and decorative animation continue. Resume restores the prior gameplay focus when it still exists. Esc dismisses nested settings/help dialogs before Pause; it never saves, exits or executes a battle action. The Chronicle remains directly accessible at the battle dock. Unsaved playtest sessions are identified as such and never write progress when exiting.

[StorageService](../apps/monstrous_sea/lib/src/services/storage_service.dart) uses `%LOCALAPPDATA%\TheMonstrousSea2\Saves` on Windows, outside redirected Documents/OneDrive. Other platforms use application support under `TheMonstrousSea2/Saves`. [LineageStore](../apps/monstrous_sea/lib/src/services/lineage_store.dart) owns `lineages.json` and `lineages/<slot-id>/` directories containing each lineage's save pair. Labels are independent of generated safe directory IDs; catalog IDs are validated. Catalog changes are serialized within the app and published by a flushed temporary-file rename. No production temporary-directory fallback is used. Injected directories isolate tests from player data.

On first access, finish the existing Documents/temp-to-LocalAppData migration before creating the slot catalog. Validate the root save pair, then copy it byte-for-byte to “Original Lineage,” retaining root and legacy files as backups. A pending slot-import marker permits retry before publishing the complete catalog. An existing catalog is authoritative and prevents re-importing stale root saves; a missing catalog beside populated slot directories is reported rather than overwriting them. Slot reads are strict: missing/unreadable profiles and malformed checkpoints are errors, not fresh games. A broken slot does not prevent selecting a readable one; catalog/import errors show Retry. These safeguards do not establish transactional atomicity of the existing separate profile/checkpoint writes or support simultaneous app processes writing the same catalog.

Use New Lineage for a fresh start without resetting an existing save. Destructive deletion/reset is a separate user-requested maintenance action requiring a backup and exact slot scope; deleting the catalog or migration markers is not a reset workflow. Documentation maintenance never resets player data.

The battle HUD and Flame scene share detached displayed combat state. Commands still resolve immediately in core; playback advances health, shell, barrier, limbs, effects, bearing and intent at their corresponding outcomes. Healing and reactive damage retain their separate causes. Local cues distinguish damage, mitigation, barrier absorption, shell changes, avoidance and status lifecycle; ordinary Burn/Poison/Stun share one horizontal wrapping row with existing power badges, separated from the health meter by 8 pixels when effects are present. Shell damage cues retain their amount when breaking the shell (SHELL −N · BROKEN); flesh damage remains a separate HP impact. Decision controls refresh when playback finishes, and action-dependent forecasts are withheld while resolving. Ordinary text stays stationary over a length-sensitive 1.8–3.8-second lifetime, remaining solid for the first half (0.9 seconds for short cues), then fading over the second half; the whole cartouche fades together. Each combatant retains up to three local cues, with newest nearest the combatant and older cues above it. Cues keep independent lifetimes across successive actions; expiry or a full stack removes older entries. Ordinary outcomes advance 400–500 ms apart without waiting for fades, while attack names retain their 100 ms lead. Health and effects still update at their corresponding event, and ordinary playback can finish while its final cues remain visible. Measured rows reflow on resize/text-scale changes; compact arenas can retain fewer cues to protect the HUD and artwork. Ordinary damage numbers hold for 0.85 seconds and fade for 0.85 seconds. Barrages retain individual outcomes and longer-lived cues: only the opening strike receives normal reading pauses. From strike two, source beats take 90 ms and outcome waits use half their base duration, capped at 200 ms, even when a defense, damage or status cue first appears later in the sweep. Range feedback identifies both the actual mover and the actor causing a pull/push, placing the cue by the moved combatant. A beast retreat cannot be described as ship movement. Reduced motion retains state changes and readable cues without bobbing, floating, fading or shaking. This is an implemented feedback foundation, with comprehension and timing still requiring player replay under PT2-11; the broader layout and final visual vocabulary remain open.

The command-station trial retains the upper health/status panels. At wider widths the lower area splits helm/actions 40/60, with large, equal-width helm controls, two aligned weapon buttons and a full-width utility row. Broadside, Signature and Utility each have a heading; blessings attach below their buttons without shifting the weapon alignment. Narrow windows stack helm above actions; commands scroll when height or text scale requires it. The belt is pinned to the dock's bottom edge beside Pause and Chronicle, wrapping on roomy windows and scrolling horizontally with a visible scrollbar when width or height is limited. Weapon cards show opening shot accuracy and the range damage multiplier; accuracy precedes target dodge, and the range percentage is not a final damage estimate.

The lookout shows intent, threatened bands, movement/windup timing and a short selected-helm forecast. It sits beside the monster on large windows, with scene space reserved for it, or above the scrolling commands in compact windows. A scrollable, squared parchment Inspect dialog holds descriptions, live sweep calculations, range stages and counterplay. Additional action-movement notes are limited to the current ship and active Skirmisher timing; defense caveats appear with damage estimates, and per-hit sweep guidance appears only for sweeps. Intrinsic action movement makes the helm-only forecast conditional; action tooltips retain their response forecasts. Already-applied helm previews preserve the committed order for head-on collision prediction without applying movement twice. Resolving actions suppress forecasts. Spatial bearing animation, affected-area zones and status icons remain separate work under PT2-11.

The live Chronicle holds the current voyage's messages in session memory and opens as a modal beside Pause. Succession and fresh home departure clear older messages; ordinary encounters and strongholds retain the voyage history. The first opening in each battle starts at the latest messages, and new entries follow the live end until the player scrolls back. Closing and reopening within that battle preserves the reading position and follow-latest choice. **Latest Messages** resumes following; combat actions preserve deliberate history reading. Existing playback continues behind the modal while new gameplay input is blocked. Close/Escape dismisses it before Pause and restores surviving prior focus. Combat-log persistence and a historical archive are not implemented. The command-station trial still needs player evaluation.

Battle belt buttons use compact item names and effect summaries. A small question-mark control to the left of the items opens Belt Help by pointer or keyboard, including when item use is disabled. Its scrollable dialog explains single-use, zero-turn actions, the per-round limit and current usage, and each carried item's effect. Item tooltips and screen-reader hints contain only the effect and any current use restriction; shared rules and the usage counter stay in help. This presentation adds no first-acquisition tutorial state and does not change quick-item rules. Fitting inspection shows blessing details only for dedicated sockets, without an empty blessing message beforehand. The victory-loot capacity/full-belt warning wraps when space is limited; stowing and jettisoning keep their existing rules.

Page headers and fixed footers share the parchment cartouche with the page body, keeping debug/pause controls and Embark inside its inset. Lineage identity and save management are in Pause rather than a persistent gameplay header. Prologue text scrolls independently of its fixed footer.

Use approved transparent nautical raster art for entities/items; structural linework may use SVG or CustomPainter. Ships/weapons face right and monsters left. Preserve approved silhouettes, connected anatomy/rigging, true alpha, sparse ink detail, and the existing asset bundle; archived art is not added to it. Base text scale is 115%; percentage accuracy and meaningful text labels replace colorful emoji. Missing imagery remains deferred work in [the backlog](BACKLOG.md#deferred-ui-art-and-icons). Battle illustration load/decode failures now use a labeled cartouche with an inline retry, leaving combat active; successful recovery restores the approved art without changing battle state. The original intermittent Standard-asset failure still needs player replay (PT2-25).

Player-facing percentage modifiers use `%`, including accuracy/evasion changes; avoid `pp` and the phrase “percentage points” in the HUD, tooltips and narration. This is notation only: an additive accuracy penalty of 25 still changes 85% to 60%. Mathematical distinctions may remain explicit in technical rules and tests.

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
