# Approved Hull Patch Kit artwork — 7 November 2026

The user selected the rope replacement of the leather-bundle draft: squared shoring planks, cord around the wood and the separate square-headed mallet. The [approved original](../../art/candidates/artwork-pass-2026-11-06/icon_hull_patch_kit_rope_from_leather_v1.png) is copied byte-for-byte into the app bundle. `PilotArt.hullPatchKit` and `SvgAssetView.pathForItem` replace the tincture image previously reused for this item.

Merchant stock/sales and battle/wreck loot share that item-art selector. Inspection and the combat belt currently use text controls; their layout is unchanged. Other new art remains outside the bundle pending its own selection. Candidate images, prompts and declined concepts remain in the [review record](../../art/artwork-pass-2026-11-06.md). No save, healing, price or other gameplay rule changed.

## Verification

- Flutter analysis: no issues.
- Existing raster bundle/alpha checks: **28 passed**, covering exactly 27 active illustrations and real transparency, including the selected kit.
- Existing navigation follow-up, consumable trade and combat belt checks: **25 passed**.
- The existing merchant fixture was rerun for **two visual captures**, using copied cached game fonts and isolated unsaved controllers. The [360-wide](evidence/patch-kit-art-2026-11-07/visual/approved-merchant-360.0.png) and [1280-wide](evidence/patch-kit-art-2026-11-07/visual/approved-merchant-1280.0.png) layouts at 130% text were visually inspected. The helper now precaches the dedicated kit PNG.
- A separate Windows Debug build succeeded at `.dart_tool/patch-kit-preview/build/windows/x64/runner/Debug/monstrous_sea.exe`. It was compiled without launching. All copied app sources/assets, the dependency lock and the built kit PNG match the working sources/approval; [the manifest](evidence/patch-kit-art-2026-11-07/manifest.json) records hashes and scope. Existing bundles and player saves are preserved.
- The collection proof renderer's small-icon canvas now allocates its height from the row count, accommodating the additional approved item. `node --check` passes; the older collection proof images were not overwritten.

No new tests duplicating the one-line selector were added. The existing bundle, flow and capture checks cover the integration.
