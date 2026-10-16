// Review composites only; game images remain the original generated PNGs.
// node tools/art/render_sea_map_proofs.cjs <sharp-module-path>
const fs = require('node:fs');
const path = require('node:path');
const sharp = require(process.argv[2] || 'sharp');
const root = path.resolve(__dirname, '../..');
const out = path.join(root, 'docs/art');
const manifest = JSON.parse(fs.readFileSync(path.join(out, 'sea_map_art_manifest.json'), 'utf8'));
function artPath(filename) {
 const active = path.join(root, 'apps/monstrous_sea/assets/art', filename);
 if (fs.existsSync(active)) return active;
 const archived = path.join(out, 'archive', path.extname(filename).slice(1), filename);
 if (fs.existsSync(archived)) return archived;
 throw new Error('Missing active or archived artwork: '+filename);
}
const escaped = s => s.replaceAll('&', '&amp;').replaceAll('<', '&lt;');
const label = (s, w=280) => Buffer.from('<svg width="'+w+'" height="36"><text x="'+w/2+'" y="24" text-anchor="middle" font-size="16" font-family="Georgia" fill="#1B1612">'+escaped(s)+'</text></svg>');
async function main() {
 const checks = [];
 for (const asset of [...manifest.assets, ...(manifest.previewAlternatives || [])]) {
  const input = artPath(asset.filename);
  const {data,info} = await sharp(input).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  let transparent=0, painted=0, edge=0;
  for(let y=0;y<info.height;y++) for(let x=0;x<info.width;x++) {
   const alpha=data[(y*info.width+x)*4+3];
   if(alpha===0) transparent++;
   if(alpha>200) painted++;
   if((x===0 || y===0 || x===info.width-1 || y===info.height-1) && alpha>16) edge++;
  }
  if(edge || transparent<info.width*info.height*.1 || painted<info.width*info.height*.1) throw Error(asset.title+': invalid transparency or clipped edge');
  checks.push({title:asset.title,width:info.width,height:info.height,edgePixels:edge,transparentFraction:transparent/(info.width*info.height)});
 }
 for (const [kind,name,cols] of [['ship','sea_map_ships',5],['monster','sea_map_monsters',3],['icon','sea_map_equipment',4],['chart','sea_map_chart',3]]) {
  const assets=manifest.assets.filter(a=>a.kind===kind), cell=280;
  const layers=[];
  for(const [i,a] of assets.entries()) {
   const left=i%cols*cell,top=Math.floor(i/cols)*cell;
   layers.push({input:await sharp(artPath(a.filename)).resize(240,240).png().toBuffer(),left:left+20,top});
   layers.push({input:label(a.title),left,top:top+240});
  }
  await sharp({create:{width:cols*cell,height:Math.ceil(assets.length/cols)*cell,channels:4,background:'#F4ECD8'}}).composite(layers).png().toFile(path.join(out,name+'.png'));
 }
 const icons=manifest.assets.filter(a=>a.kind==='icon'), cell=180, layers=[];
 for(const [i,a] of icons.entries()) {
  const left=i%4*cell,top=Math.floor(i/4)*110;
  for(const [j,size] of [22,36,48].entries()) layers.push({input:await sharp(artPath(a.filename)).resize(size,size).png().toBuffer(),left:left+16+j*52,top:top+12});
  layers.push({input:label(a.title,cell),left,top:top+68});
 }
 await sharp({create:{width:720,height:330,channels:4,background:'#F4ECD8'}}).composite(layers).png().toFile(path.join(out,'sea_map_icons_small.png'));
 fs.writeFileSync(path.join(out,'sea_map_asset_checks.json'),JSON.stringify({note:'Original PNGs checked; composites used only for review.',checks},null,2)+'\n');
 const revisionFile = manifest.latestRevisionManifest || 'sea_map_revisions_v2.json';
 const revisionStem = path.basename(revisionFile, '.json');
 const revisionsPath = path.join(out, revisionFile);
 if (fs.existsSync(revisionsPath)) {
  const revisions = JSON.parse(fs.readFileSync(revisionsPath, 'utf8')).assets;
  async function plate(assets, cols, cell, name) {
   const layers = [];
   for (const [i, a] of assets.entries()) {
    const left = i % cols * cell, top = Math.floor(i / cols) * cell;
    layers.push({input:await sharp(artPath(a.filename)).resize(cell-40,cell-40).png().toBuffer(),left:left+20,top});
    layers.push({input:label(a.title,cell),left,top:top+cell-40});
   }
   await sharp({create:{width:cols*cell,height:Math.ceil(assets.length/cols)*cell,channels:4,background:'#F4ECD8'}}).composite(layers).png().toFile(path.join(out,name+'.png'));
  }
  const activeRevisions = revisions.filter(a=>!a.previewOnly);
  await plate(activeRevisions,Math.min(3,activeRevisions.length),320,revisionStem);
  for (const a of revisions.filter(a=>!a.previewOnly)) {
   await plate([
    {title:'Before',filename:a.target},
    {title:'Current',filename:a.filename},
   ],2,340,revisionStem+'_'+a.slug);
  }
 }
 console.log(checks.length+' transparent assets passed; no opaque edge pixels. Collection and revision sheets rendered.');
}
main().catch(e=>{console.error(e);process.exitCode=1});

