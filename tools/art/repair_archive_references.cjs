// Update review paths after archive_unused_art.ps1; exact image prompts stay unchanged.
const fs=require('node:fs'),path=require('node:path');
const root=path.resolve(__dirname,'../..'),docs=path.join(root,'docs/art'),archive=path.join(docs,'archive');
const readJson=p=>JSON.parse(fs.readFileSync(p,'utf8').replace(/^\uFEFF/,''));
const index=readJson(path.join(archive,'manifest.json'));
if(index.state!=='archived')throw Error('Archive moves must finish before updating references');
const moves=index.archivedFiles;
const byName=new Map(moves.map(m=>[m.filename,m]));
const posix=p=>p.split(path.sep).join('/');
function mappedPath(value){
 for(const m of moves){
  const oldNative=path.join(root,m.originalRelativePath),newNative=path.join(root,m.archivedRelativePath);
  if(value.toLowerCase()===oldNative.toLowerCase())return newNative;
  if(value.toLowerCase()===posix(oldNative).toLowerCase())return posix(newNative);
  if(value===m.originalRelativePath)return m.archivedRelativePath;
  if(value==='../../'+m.originalRelativePath)return posix(path.relative(docs,newNative));
  if(value==='assets/art/'+m.filename)return m.archivedRelativePath;
 }
 return value;
}
function update(value,key=''){
 if(typeof value==='string')return key==='prompt'?value:mappedPath(value);
 if(Array.isArray(value))return value.map(v=>update(v,key));
 if(value&&typeof value==='object'){
  const result=Object.fromEntries(Object.entries(value).map(([k,v])=>[k,update(v,k)]));
  const file=byName.get(result.filename);
  if(file){result.assetPath=file.archivedRelativePath;result.archived=true}
  const target=byName.get(result.target);
  if(target)result.targetPath=target.archivedRelativePath;
  return result;
 }
 return value;
}
let changed=0;
function rewrite(dir){
 for(const entry of fs.readdirSync(dir,{withFileTypes:true})){
  const file=path.join(dir,entry.name);
  if(file===archive)continue;
  if(entry.isDirectory()){rewrite(file);continue}
  if(!['.json','.html','.svg'].includes(path.extname(file)))continue;
  const before=fs.readFileSync(file,'utf8');
  let after=before;
  if(path.extname(file)==='.json'){
   const original=JSON.parse(before),updated=update(original);
   if(JSON.stringify(original)!==JSON.stringify(updated))after=JSON.stringify(updated,null,2)+'\n';
  }else{
   for(const m of moves){
    const newUrl=posix(path.relative(path.dirname(file),path.join(root,m.archivedRelativePath)));
    for(const oldUrl of ['../../'+m.originalRelativePath,posix(path.join(root,m.originalRelativePath)),path.join(root,m.originalRelativePath),m.originalRelativePath]){
     after=after.replaceAll(oldUrl,newUrl);
    }
   }
  }
  if(after!==before){fs.writeFileSync(file,after);changed++}
 }
}
rewrite(docs);
const esc=s=>s.replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('"','&quot;');
const cards=ext=>moves.filter(m=>m.filename.endsWith('.'+ext)).map(m=>{
 const url=ext+'/'+m.filename;
 return '<article><a href="'+url+'"><img src="'+url+'" loading="lazy" alt="'+esc(m.filename)+'"></a><code>'+esc(m.filename)+'</code><small>'+Math.round(m.bytes/1024)+' KiB</small></article>';
}).join('\n');
const html='<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>The Monstrous Sea — Art Archive</title><style>body{margin:0;background:#f4ecd8;color:#1b1612;font-family:Georgia,serif}main{max-width:1200px;margin:auto;padding:28px}p{line-height:1.6}a{color:inherit}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(210px,1fr));gap:16px}article{padding:12px;border:1px solid #d5c4a1;text-align:center}img{width:100%;height:190px;object-fit:contain}code{display:block;font-size:11px;overflow-wrap:anywhere}small{display:block;margin-top:8px}</style></head><body><main><h1>Art Archive</h1><p>16 PNG drafts and alternatives, plus 23 historical SVGs, retained outside the Flutter asset bundle. The game keeps its 26 active PNGs. Every moved file and active image was verified with SHA-256; nothing was discarded.</p><p><a href="../sea_map_collection.html">Current collection</a> · <a href="manifest.json">Archive paths, sizes and checksums</a></p><h2>Earlier raster designs</h2><div class="grid">'+cards('png')+'</div><h2>Historical vector designs</h2><div class="grid">'+cards('svg')+'</div></main></body></html>\n';
fs.writeFileSync(path.join(archive,'index.html'),html);
console.log(changed+' review/prompt records updated; exact prompts preserved; archive index written.');

