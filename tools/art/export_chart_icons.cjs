// Export generated chart symbols to the user-specified RGBA canvas and margins.
// Original ImageGen outputs are retained. This only normalizes export geometry.
// node tools/art/export_chart_icons.cjs <sharp-module-path>
const fs=require('node:fs'),path=require('node:path');
const sharp=require(process.argv[2]||'sharp');
const root=path.resolve(__dirname,'../..'),out=path.join(root,'docs/art');
const manifest=JSON.parse(fs.readFileSync(path.join(out,'chart_icon_prompts.json'),'utf8'));
async function main(){
 const checks=[];
 for(const a of manifest.assets){
  const {data,info}=await sharp(a.source).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  let x0=info.width,y0=info.height,x1=-1,y1=-1;
  for(let y=0;y<info.height;y++)for(let x=0;x<info.width;x++){
   const i=(y*info.width+x)*4;
   if(data[i+3]<=2)data[i+3]=0;
   if(data[i+3]>8){x0=Math.min(x0,x);y0=Math.min(y0,y);x1=Math.max(x1,x);y1=Math.max(y1,y)}
  }
  if(x1<0)throw Error(a.title+': empty source');
  x0=Math.max(0,x0-2);y0=Math.max(0,y0-2);x1=Math.min(info.width-1,x1+2);y1=Math.min(info.height-1,y1+2);
  const content=await sharp(data,{raw:{width:info.width,height:info.height,channels:4}}).extract({left:x0,top:y0,width:x1-x0+1,height:y1-y0+1}).resize({width:818,height:818,fit:'inside'}).png().toBuffer();
  const meta=await sharp(content).metadata(),left=Math.floor((1024-meta.width)/2),top=Math.floor((1024-meta.height)/2);
  await sharp({create:{width:1024,height:1024,channels:4,background:{r:0,g:0,b:0,alpha:0}}}).composite([{input:content,left,top}]).png().toFile(a.destination);
  const exported=await sharp(a.destination).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  let paddingAlpha=0,painted=0;
  for(let y=0;y<1024;y++)for(let x=0;x<1024;x++){
   const alpha=exported.data[(y*1024+x)*4+3];
   if(x<102||y<102||x>=922||y>=922)paddingAlpha=Math.max(paddingAlpha,alpha);
   if(alpha>200)painted++;
  }
  if(paddingAlpha!==0||painted<1024*1024*.05)throw Error(a.title+': invalid export or padding');
  checks.push({title:a.title,width:1024,height:1024,marginPixels:102,paddingAlpha,paintedPixels:painted,sourceCanvas:[info.width,info.height],contentRect:{left,top,width:meta.width,height:meta.height}});
 }
 fs.writeFileSync(path.join(out,'chart_icon_checks.json'),JSON.stringify({checks},null,2)+'\n');
 const layers=[],small=[];
 for(const [i,a]of manifest.assets.entries()){
  layers.push({input:await sharp(a.destination).resize(260,260).png().toBuffer(),left:i*320+30,top:0});
  const svg='<svg width="320" height="44"><text x="160" y="28" text-anchor="middle" font-family="Georgia" font-size="17" fill="#1B1612">'+a.title.replaceAll('&','&amp;')+'</text></svg>';
  layers.push({input:Buffer.from(svg),left:i*320,top:260});
  for(const[j,size]of[32,36,48,64].entries())small.push({input:await sharp(a.destination).resize(size,size).png().toBuffer(),left:i*240+j*58+(58-size)/2,top:14});
 }
 await sharp({create:{width:960,height:310,channels:4,background:'#F4ECD8'}}).composite(layers).png().toFile(path.join(out,'chart_icons.png'));
 await sharp({create:{width:720,height:100,channels:4,background:'#F4ECD8'}}).composite(small.map(x=>({...x,left:Math.round(x.left)}))).png().toFile(path.join(out,'chart_icons_small.png'));
 console.log(checks.length+' icons exported at 1024x1024; 102px padding completely transparent; preview sheets saved.');
}
main().catch(e=>{console.error(e);process.exitCode=1});

