# Deferred UI art and icon backlog

Captured from the [20 October 2026 playtest](PLAYTEST_2026_10_20.md), items PT2-04–07. **Planning only: no icons or illustrations are to be generated or replaced as part of recording this backlog.** Schedule this with the future UI/custom-image pass.

## Style and workflow

- Retain the historical nautical, woodcut / ink-and-parchment style of the approved raster collection. Avoid colorful emoji and unrelated generic symbols.
- Audit [existing art](../apps/monstrous_sea/assets/art/) and [PilotArt](../apps/monstrous_sea/lib/src/widgets/pilot_art.dart) before requesting replacements. Missing UI imagery can be a missing mapping/widget rather than a missing image.
- Prepare a reviewed asset list and briefs for the user's established image workflow when that work is scheduled. Do not generate a new set now.
- Distinct gameplay identities need distinct silhouettes at actual UI size, with legible labels and hover/focus descriptions. An icon must not imply an item is a different consumable.
- Continue using code/vector linework for structural UI where appropriate. Icons supplement readable text; they do not replace accessible names or become the only indicator of an important state.

## Navigation and existing assets

| UI use | Current concern | Existing candidates to audit later |
| --- | --- | --- |
| Home-port Merchant | Button feels empty after icon removal. | `icon_treasure_map.png`, `icon_helm_map.png`; choose by meaning rather than filling space. |
| Home-port Blueprints | Needs a recognizable shipwright/drafting identity. | Existing art may be insufficient; check the gallery before adding a dedicated drafting image to the production list. |
| Sea Chart buttons | Thematic imagery is inconsistent or absent depending on screen. | `icon_helm_map.png`, nautical navigation assets, and prior chart imagery. |
| Other existing navigation controls | Review consistency alongside the above. | `icon_port_haven_map.png`, `icon_anchor_map.png`, `icon_cannons_map.png` as appropriate. |

These are audit candidates, not approved final mappings. Screenshots 4 and 5 in the playtest also show that themed icons still exist in some locations; reconcile usage instead of assuming all icons were removed.

## Consumables

Every current consumable needs its own accurate image. The current mappings below are confirmed in [SvgAssetView.pathForItem](../apps/monstrous_sea/lib/src/widgets/svg_asset_view.dart).

| Identity / enum | Current art | Later work |
| --- | --- | --- |
| Unstable Tincture / `unstableTincture` | `icon_unstable_tincture_map_v4.png` | Audit/reuse approved bottle art. |
| Hull Patch Kit / `hullPatchKit` | Unstable Tincture image | Dedicated repair materials/toolkit image. |
| Blast Pack / `blastPack` | `icon_blast_pack_map.png` | Audit/reuse approved explosive bundle art. |
| Bottled Kraken Ink / `krakenInkBomb` | Blast Pack image | Dedicated ink vessel image, clearly different from pitch and explosives. |
| Alchemical Pitch Flask / `alchemicalPitch` | Blast Pack image | Dedicated pitch vessel image, clearly different from ink and tincture. |
| Chakram / `chakram` | `icon_chakram_map.png` | Audit/reuse approved throwing-disc art. |

Apply the eventual mapping consistently to merchants, loot, belt inspection, salvage results, and battle actions. Consumables remain single-use and have no rarity/charge variants requiring separate pictures.

## Meta-materials and trophies

The [blueprint screenshot](playtests/2026-10-20/02-blueprint-materials.png) shows generic symbols that do not match the intended collection. Plan distinct readable images for every persisted currency in [MetaInventory](../packages/monstrous_core/lib/src/model/meta_inventory.dart).

| Identity | Scope |
| --- | --- |
| Sea Glass | Common exploration material. |
| Monster Bone | Common combat organic. |
| Depth-Wrought Iron | Rare exploration material. |
| Abyssal Barnacles | Rare combat organic. |
| Kraken's Beak | Region 1 Titan trophy. |
| World Serpent's Scale | Region 2 Titan trophy. |
| Leviathan Core | Region 3 trophy / ending relevance. |
| Primordial Cinders | Endgame currency; include when that UI is visible. |

The same material must look the same in costs, inventory, rewards, and progression screens. Counts must remain readable at zero, large quantities, and insufficient-resource states. Do not confuse material rarity with the retired consumable rarity system.

## Hardpoints

Earlier standalone weapon illustrations exist, including cannon, torpedo, blade launcher, railgun, and flamethrower images. They are not automatically accurate pictures of the current intrinsic weapons. The inspection UI also currently omits hardpoint imagery.

Audit these current blueprint identities against [the catalog](../packages/monstrous_core/lib/src/model/flagship_blueprint.dart) and [weapon content](../packages/monstrous_core/lib/src/content/ship_weapons.dart) when creating the final production brief:

| Blueprint | Broadside | Signature | Utility |
| --- | --- | --- | --- |
| Standard | Naval Cannon Battery | Twin Chaser Cannons | Gunnery Drill |
| Ironclad | Heavy Carronades | Reinforced Prow Ram | Fortify Iron Plates |
| Clipper | Long-Barrel Swivel Guns | Precision Culverin | Evasive Rigging |
| Bombardier | Shrapnel Howitzers | Heavy Siege Mortar | Spotter Flare |
| Corsair | Chain-Shot Broadside | Harpoon Winch | Drifting Tether-Trap |

Use the current source names as the final authority for asset briefs; the table describes the identities to cover. Decide whether Mk marks, blessings, and future Master Refits reuse a base illustration with readable overlays or warrant a variant. Do not generate every combination or illustrate a speculative Master Refit before its design is agreed.

## Completion criteria for the eventual pass

- Approved asset inventory distinguishes reusable art, mapping-only repairs, and genuinely missing pictures.
- Each consumable, material, and hardpoint is recognizable and correctly mapped everywhere it appears.
- Navigation imagery is consistent with the parchment palette and nautical subject matter.
- Inspect screenshots at real display size and 115–130% text settings; preserve contrast, labels, accessibility, and compact layouts.
- Add focused mapping/asset-load checks where useful, then review the rendered UI. File existence alone does not establish visual correctness.
