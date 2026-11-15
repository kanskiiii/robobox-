import {deflateSync} from 'node:zlib';

const table=Array.from({length:256},(_,i)=>{
  let value=i;
  for(let bit=0;bit<8;bit++) value=value&1?(value>>>1)^0xedb88320:value>>>1;
  return value>>>0;
});
function pngChunk(type,data){
  const name=Buffer.from(type), body=Buffer.concat([name,data]);
  let crc=0xffffffff;
  for(const byte of body) crc=(crc>>>8)^table[(crc^byte)&255];
  const header=Buffer.alloc(4), checksum=Buffer.alloc(4);
  header.writeUInt32BE(data.length);
  checksum.writeUInt32BE((crc^0xffffffff)>>>0);
  return Buffer.concat([header,body,checksum]);
}
function png(pixels,size){
  const header=Buffer.alloc(13);
  header.writeUInt32BE(size);
  header.writeUInt32BE(size,4);
  header[8]=8;
  header[9]=2;
  const stride=size*3;
  const scanlines=Buffer.alloc((stride+1)*size);
  for(let y=0;y<size;y++) pixels.copy(scanlines,y*(stride+1)+1,y*stride,(y+1)*stride);
  return Buffer.concat([Buffer.from([137,80,78,71,13,10,26,10]),pngChunk('IHDR',header),
    pngChunk('IDAT',deflateSync(scanlines,{level:9})),pngChunk('IEND',Buffer.alloc(0))]);
}
const clamp=(x,lo,hi)=>Math.min(hi,Math.max(lo,x));
const frac=x=>x-Math.floor(x);
const mix=(a,b,t)=>a+(b-a)*t;
function hash(x,y,seed){
  let n=Math.imul(x+13,374761393)+Math.imul(y+11,668265263)+Math.imul(seed,1442695041);
  n=Math.imul(n^(n>>>13),1274126177);
  return ((n^(n>>>16))>>>0)/4294967295;
}
function noise(x,y,seed){
  const a=Math.floor(x),b=Math.floor(y);
  const u=frac(x),v=frac(y),s=u*u*(3-2*u),t=v*v*(3-2*v);
  return mix(mix(hash(a,b,seed),hash(a+1,b,seed),s),mix(hash(a,b+1,seed),hash(a+1,b+1,seed),s),t);
}
const appearance={
  cast:{grain:.15,relief:1.4}, alloy:{grain:.08,brush:.08,relief:.35},
  rotor:{grain:.08,brush:.12,relief:.40}, chrome:{grain:.035,brush:.05,relief:.20},
  frame:{grain:.095,relief:.5}, anodized:{grain:.065,brush:.035,relief:.35},
  pipe:{grain:.16,oxide:.38,relief:.73}, weld:{grain:.16,oxide:.20,relief:1.1},
  grease:{grain:.18,oxide:.13,relief:.64}, dirty:{grain:.22,relief:.71},
  body:{grain:.10,relief:.26}, trim:{grain:.065,relief:.24}, rubber:{grain:.12,relief:.50},
  tread:{grain:.13,relief:.66}, seat:{grain:.16,relief:.62},
  black:{grain:.10,relief:.44}, gold:{grain:.075,brush:.04,relief:.35},
};
export function buildAtlas(materials,size=1024){
  const keys=Object.keys(materials).filter(k=>k!=='vertex'), grid=Math.ceil(Math.sqrt(keys.length));
  const tile=Math.floor(size/grid), edge=4;
  const maps=Object.fromEntries(['baseColor','orm','normal','roughness','metalness']
    .map(key=>[key,Buffer.alloc(size*size*3)]));
  const byte=x=>Math.round(clamp(x,0,255));
  const tiles=new Map();
  for(const [i,key] of keys.entries()){
    const x0=(i%grid)*tile,y0=Math.floor(i/grid)*tile;
    tiles.set(key,[x0,y0]);
    const [,hex,metal,rough]=materials[key];
    const rgb=hex.slice(1).match(/../g).map(x=>parseInt(x,16));
    const {grain=.06,brush=0,oxide=0,relief=.2}=appearance[key]??{};
    const height=(x,y)=>noise(x*.31,y*.31,i)*.58+noise(x*.87,y*.87,i+23)*.42;
    for(let y=0;y<tile;y++) for(let x=0;x<tile;x++){
      const ox=noise(x*.041,y*.05,i+46),dust=noise(x*.018,y*.024,i+61);
      const wear=1+grain*((height(x,y)-.51)*1.7+(dust-.5)*.7)
        +brush*(noise(x*.052,y*.86,i+98)-.5);
      const oxidation=oxide*clamp((ox-.48)*2.6,0,1);
      const roughness=byte((rough+(.6-dust)*.11+oxidation*.39)*255);
      const metalness=byte(metal*(1-oxidation*.81)*255);
      const p=((y0+y)*size+x0+x)*3;
      for(let c=0;c<3;c++){
        maps.baseColor[p+c]=byte(mix(rgb[c]*wear,[119,67,42][c],oxidation));
        maps.roughness[p+c]=roughness;
        maps.metalness[p+c]=metalness;
      }
      maps.orm.set([255,roughness,metalness],p);
      const dx=(height(x-1,y)-height(x+1,y))*relief;
      const dy=(height(x,y-1)-height(x,y+1))*relief;
      const normal=Math.hypot(dx,dy,1);
      maps.normal.set([byte(127.5+127.5*dx/normal),byte(127.5+127.5*dy/normal),byte(127.5+127.5/normal)],p);
    }
  }
  function uv(point,key){
    const [x0,y0]=tiles.get(key);
    const span=tile-2*edge;
    // Bounded diagonal projection keeps every solid inside its assigned tile.
    const u=.5+.47*Math.tanh((point[2]+point[0]*.58)*10);
    const v=.5+.47*Math.tanh((point[1]+point[0]*.29)*10);
    return [(x0+edge+u*span)/size,(y0+edge+v*span)/size];
  }
  return {uv,images:Object.fromEntries(Object.entries(maps).map(([k,data])=>[k,png(data,size)]))};
}
