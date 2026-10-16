// Deterministic raster proofs of the native SVGs, never game art sources.
// node tools/art/render_asset_proofs.cjs <output-dir> <sharp-module-path>
const fs = require('node:fs');
const path = require('node:path');
const sharp = require(process.argv[3] || 'sharp');
const root = path.resolve(__dirname, '../..');
const out = path.resolve(process.argv[2]);
fs.mkdirSync(out, { recursive: true });
const categories = {
  ships: ['ship_ironclad', 'ship_freighter', 'ship_corvette', 'ship_standard', 'ship_flying_dutchman'],
  monsters: ['monster_shark', 'monster_serpent', 'monster_jellyfish', 'monster_squid', 'monster_crustacean', 'monster_kraken'],
  equipment: ['icon_unstable_tincture', 'icon_blast_pack', 'icon_chakram', 'icon_cannon', 'icon_torpedo_launcher', 'icon_blade_launcher', 'icon_lightning_railgun', 'icon_flamethrower'],
};
const ink = '#1B1612', parchment = '#F4ECD8';
async function main() {
  for (const [category, names] of Object.entries(categories)) {
    const columns = category === 'ships' ? 5 : category === 'monsters' ? 3 : 4;
    const cell = 280, rows = Math.ceil(names.length / columns);
    const layers = [];
    for (const [i, name] of names.entries()) {
      const input = path.join(root, 'docs/art/archive/svg', name + '.svg');
      const size = 224;
      const pixels = await sharp(input, { density: 192 }).resize(size, size).png().toBuffer();
      await sharp(pixels).toFile(path.join(out, name + '.png'));
      // Require visible padding on all four edges; catches strokes clipped by the viewBox.
      const { data, info } = await sharp(input, { density: 192 }).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
      let edgePixels = 0;
      for (let x = 0; x < info.width; x++) {
        edgePixels += data[x * 4 + 3] > 0;
        edgePixels += data[((info.height - 1) * info.width + x) * 4 + 3] > 0;
      }
      for (let y = 1; y < info.height - 1; y++) {
        edgePixels += data[(y * info.width) * 4 + 3] > 0;
        edgePixels += data[(y * info.width + info.width - 1) * 4 + 3] > 0;
      }
      if (edgePixels) throw new Error(`${name}: ${edgePixels} opaque pixels at viewBox boundary`);
      const left = (i % columns) * cell, top = Math.floor(i / columns) * cell;
      layers.push({ input: pixels, left: left + 28, top: top + 4 });
      const label = name.replace(/^(ship|monster|icon)_/, '').replaceAll('_', ' ');
      const text = `<svg width="280" height="40"><text x="140" y="24" text-anchor="middle" font-size="16" font-family="Georgia" fill="${ink}">${label}</text></svg>`;
      layers.push({ input: Buffer.from(text), left, top: top + 228 });
    }
    await sharp({ create: { width: columns * cell, height: rows * cell, channels: 4, background: parchment } })
      .composite(layers).png().toFile(path.join(out, category + '.png'));
    console.log(`${category}: ${names.length} SVGs rendered; no clipped boundary pixels`);
  }
  // A second proof checks recognition at the actual 36/48 px UI sizes.
  const layers = [];
  for (const [i, name] of categories.equipment.entries()) {
    for (const [j, size] of [36, 48].entries()) {
      layers.push({ input: await sharp(path.join(root, 'docs/art/archive/svg', name + '.svg')).resize(size, size).png().toBuffer(),
        left: i * 90 + (90 - size) / 2, top: j * 80 + 15 });
    }
  }
  await sharp({ create: { width: 720, height: 160, channels: 4, background: parchment } })
    .composite(layers).png().toFile(path.join(out, 'equipment-small.png'));
}
main().catch(error => { console.error(error); process.exitCode = 1; });
