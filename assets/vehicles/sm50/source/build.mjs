import {writeFileSync, readFileSync} from 'node:fs';
import {zstdCompressSync} from 'node:zlib';
import {cross, length, sub} from './geometry.mjs';
import {buildAtlas} from './material-atlas.mjs';

const asset = process.argv.includes('--garage') ? {
  id:'starter-garage', folder:'environment/starter-garage', source:'garage.mjs', name:'StarterGarage',
} : process.argv.includes('--scooter') ? {
  id:'commuter-scooter', folder:'vehicles/commuter-scooter', source:'scooter.mjs', name:'CommuterScooter',
} : process.argv.includes('--performance-scooter') ? {
  id:'performance-scooter', folder:'vehicles/performance-scooter', source:'performance.mjs', name:'PerformanceScooter',
} : process.argv.includes('--roads') ? {
  id:'rural-road-kit', folder:'environment/rural-road-kit', source:'roads.mjs', name:'RuralRoadKit',
} : process.argv.includes('--house') ? {
  id:'rural-house', folder:'environment/rural-house', source:'house.mjs', name:'RuralHouse',
} : process.argv.includes('--props') ? {
  id:'roadside-props', folder:'environment/roadside-props', source:'props.mjs', name:'RoadsideProps',
} : process.argv.includes('--catalog') ? {
  id:'sm50-catalog', folder:'vehicles/sm50', source:'catalog.mjs', name:'ZefirSM50Catalog',
} : process.argv.includes('--senda') ? {
  id:'senda-catalog', folder:'vehicles/sm50', source:'senda.mjs', name:'SendaSM50Catalog',
} : process.argv.includes('--world-catalog') ? {
  id:'world-catalog', folder:'environment/starter-garage', source:'world-catalog.mjs', name:'TwoStrokeWorldCatalog',
} : {
  id:'sm50', folder:'vehicles/sm50', source:'motorcycle.mjs', name:'SM50',
};
const distance = process.argv.includes('--distance');
const textured = process.argv.includes('--pbr');
const sm50 = asset.id === 'sm50';
if(!sm50 && distance) throw Error('The selected asset has one detail level');
if(textured && !['sm50-catalog','senda-catalog'].includes(asset.id)) throw Error('PBR mode requires a bike catalog');
const {id:vehicle,folder,name:baseName,source} = asset;
const texturePrefix = vehicle === 'senda-catalog' ? 'SendaSM50' : 'ZefirSM50';
const {components, datums, materials, proxies} = await import('../../../'+folder+'/source/'+source);
const output = '../../../'+folder+'/exports/';
const suffix = distance ? '-distance' : textured ? '-pbr' : '';
const exportName = baseName+suffix+'.glb';
const file = path => new URL(path,import.meta.url);
const glb = {
  asset:{version:'2.0',generator:'Project Two-Stroke asset generator'},
  scene:0, scenes:[{nodes:[0]}], nodes:[{name:baseName,children:[]}],
  buffers:[{}], bufferViews:[], accessors:[], materials:[], meshes:[],
};
const packed = [];
let byteLength = 0;
const round = n => Math.round(n*1e6)/1e6;
const rounded = p => p.map(round);
const color = hex => hex.slice(1).match(/../g).map(s=>parseInt(s,16)/255);
const linear = n => n<=.04045?n/12.92:((n+.055)/1.055)**2.4;
const palette = Object.keys(materials);
const atlas = textured ? buildAtlas(materials) : null;
for(const [name,hex,metallicFactor,roughnessFactor,,transparency=0] of Object.values(materials)) {
  const material={name,pbrMetallicRoughness:{baseColorFactor:[...color(hex).map(linear),1-transparency],
    metallicFactor,roughnessFactor}};
  if(transparency) material.alphaMode='BLEND';
  glb.materials.push(material);
}
function bufferView(buffer,target){
  glb.bufferViews.push({buffer:0,byteOffset:byteLength,byteLength:buffer.length,...(target?{target}:{})});
  const bytes=pad(buffer);
  packed.push(bytes);
  byteLength+=bytes.length;
  return glb.bufferViews.length-1;
}
if(atlas){
  glb.images=['baseColor','orm','normal'].map(key=>({name:key,mimeType:'image/png',bufferView:bufferView(atlas.images[key])}));
  glb.textures=glb.images.map((_,source)=>({source,sampler:0}));
  glb.samplers=[{magFilter:9729,minFilter:9987,wrapS:33071,wrapT:33071}];
  glb.materials[palette.indexOf('vertex')]={
    name:baseName+' material atlas',
    pbrMetallicRoughness:{baseColorTexture:{index:0},metallicRoughnessTexture:{index:1},
      metallicFactor:1,roughnessFactor:1},normalTexture:{index:2,scale:.62},
  };
  for(const key of ['baseColor','normal','roughness','metalness']){
    writeFileSync(file(output+texturePrefix+'-'+key+'.png'),atlas.images[key]);
  }
}
function bounds(points) {
  const low=[Infinity,Infinity,Infinity], high=[-Infinity,-Infinity,-Infinity];
  for(const p of points) for(let i=0;i<3;i++){
    low[i]=Math.min(low[i],p[i]);
    high[i]=Math.max(high[i],p[i]);
  }
  return {min:rounded(low),max:rounded(high),size:rounded(sub(high,low))};
}
function pad(buffer,value=0) {
  return Buffer.concat([buffer,Buffer.alloc((4-buffer.length%4)%4,value)]);
}
function accessor(values, type, {indices=false, bounded=false}={}) {
  const buffer = Buffer.from(indices ? Uint16Array.from(values.flat()).buffer : Float32Array.from(values.flat()).buffer);
  const view=bufferView(buffer,indices?34963:34962);
  const entry={bufferView:view,componentType:indices?5123:5126,
    count:indices?values.length*3:values.length,type};
  if(bounded) {
    entry.min=[0,1,2].map(i=>Math.min(...values.map(p=>Math.fround(p[i]))));
    entry.max=[0,1,2].map(i=>Math.max(...values.map(p=>Math.fround(p[i]))));
  }
  glb.accessors.push(entry);
  return glb.accessors.length-1;
}
function child(parent, props) {
  const node = glb.nodes.length;
  glb.nodes.push(props);
  (glb.nodes[parent].children ??= []).push(node);
  return node;
}

function validateMesh(mesh, label) {
  if(mesh.triangles.length>20000 || mesh.vertices.length>65535) throw new Error(label+' exceeds mesh limits');
  for(const solid of mesh.solids) validateSolid(mesh,solid,label);
}
function validateSolid(mesh,{startVertex,endVertex,startFace,endFace},label) {
  const welded = new Map();
  const ids=mesh.vertices.slice(startVertex,endVertex).map(p=>{
    if(p.some(x=>!Number.isFinite(x))) throw new Error(label+' has a non-finite vertex');
    const k=rounded(p).join(',');
    if(!welded.has(k)) welded.set(k,welded.size);
    return welded.get(k);
  });
  const edges=new Map();
  let volume=0;
  for(const [a,b,c] of mesh.triangles.slice(startFace,endFace)){
    if(length(cross(sub(mesh.vertices[b],mesh.vertices[a]),sub(mesh.vertices[c],mesh.vertices[a])))<1e-11) {
      throw new Error(label+' has a degenerate face');
    }
    const n=cross(mesh.vertices[b],mesh.vertices[c]);
    volume+=mesh.vertices[a].reduce((sum,x,i)=>sum+x*n[i],0)/6;
    const [u,v,w]=[a,b,c].map(i=>ids[i-startVertex]);
    for(const [i,j] of [[u,v],[v,w],[w,u]]){
      const key=i<j?i+','+j:j+','+i;
      const edge=edges.get(key)??{use:0,orientation:0};
      edge.use++;
      edge.orientation+=i<j?1:-1;
      edges.set(key,edge);
    }
  }
  if([...edges.values()].some(edge=>edge.use!==2 || edge.orientation!==0)) {
    throw new Error(label+' has an open edge, non-manifold edge, or inconsistent winding at face '+startFace);
  }
  if(volume<=0) throw new Error(label+' has inward-facing geometry at face '+startFace);
}
const categories = new Map();
const studioGroups = new Map();
const parts = [];
const allPoints=[];
const known = new Set();
for(const {category,name,pivot,layers,attachments,interaction} of components){
  if(known.has(name)) throw new Error('Duplicate component: '+name);
  known.add(name);
  if(!categories.has(category)) {
    categories.set(category,child(0,{name:category,children:[]}));
    studioGroups.set(category,[]);
  }
  const attachmentLocal = Object.fromEntries(Object.entries(attachments).map(([k,p])=>[k,rounded(sub(p,pivot))]));
  child(categories.get(category),{name,mesh:glb.meshes.length,translation:pivot,
    extras:{assetId:vehicle+'.'+name,attachmentLocal}});
  const primitives=[], studioLayers=[], points=[], materialBounds={};
  let triangles=0;
  for(const [key,mesh] of Object.entries(layers)){
    validateMesh(mesh,name+'/'+key);
    const normals=mesh.normals();
    if(normals.some(n=>n.some(x=>!Number.isFinite(x)))) throw new Error(name+' has invalid normals');
    const local=mesh.vertices.map(p=>sub(p,pivot));
    materialBounds[key]=bounds(local);
    const attributes={POSITION:accessor(local,'VEC3',{bounded:true}),NORMAL:accessor(normals,'VEC3')};
    if(mesh.colors) {
      if(atlas) attributes.TEXCOORD_0=accessor(local.map((p,i)=>atlas.uv(p,mesh.colors[i])),'VEC2');
      else attributes.COLOR_0=accessor(mesh.colors.map(k=>color(materials[k][1]).map(linear)),'VEC3');
    }
    primitives.push({attributes,
      indices:accessor(mesh.triangles,'SCALAR',{indices:true}),material:palette.indexOf(key)});
    points.push(...mesh.vertices);
    triangles+=mesh.triangles.length;
    studioLayers.push({key,vertices:local,normals,faces:mesh.triangles,colors:mesh.colors});
  }
  glb.meshes.push({name:name+'_Geometry',primitives});
  allPoints.push(...points);
  parts.push({assetId:vehicle+'.'+name,name,category,vehicleCompatibility:folder.startsWith('environment/')?['sm50','commuter-scooter']:[vehicle],file:folder+'/exports/'+exportName,
    node:name,dimensionsM:bounds(points).size,pivotM:rounded(pivot),attachmentLocalM:attachmentLocal,
    materials:Object.keys(layers),materialBoundsM:materialBounds,triangles,
    collision:proxies.filter(p=>p.target===name).map(p=>p.name),interaction});
  studioGroups.get(category).push({name,pivot,attachments:attachmentLocal,layers:studioLayers});
}

const bin=Buffer.concat(packed);
glb.buffers[0].byteLength=bin.length;
const chunk = (data,type) => {
  const header=Buffer.alloc(8);
  header.writeUInt32LE(data.length);
  header.writeUInt32LE(type,4);
  return Buffer.concat([header,data]);
};
const chunks=[chunk(pad(Buffer.from(JSON.stringify(glb)),32),0x4e4f534a),chunk(bin,0x004e4942)];
const header=Buffer.alloc(12);
header.write('glTF');
header.writeUInt32LE(2,4);
header.writeUInt32LE(12+chunks.reduce((n,b)=>n+b.length,0),8);
writeFileSync(file(output+exportName),Buffer.concat([header,...chunks]));

// Reopen the export and verify every primitive references complete binary data.
const saved=readFileSync(file(output+exportName));
const jsonLength=saved.readUInt32LE(12);
const index=JSON.parse(saved.subarray(20,20+jsonLength));
if(saved.readUInt32LE(8)!==saved.length || saved.readUInt32LE(20+jsonLength)!==bin.length
  || index.meshes.length!==parts.length) throw new Error('GLB header or mesh count mismatch');
for(const mesh of index.meshes) for(const p of mesh.primitives){
  const positions=index.accessors[p.attributes.POSITION], normals=index.accessors[p.attributes.NORMAL];
  const indices=index.accessors[p.indices];
  if(positions.count!==normals.count || indices.count%3) throw new Error('GLB attribute count mismatch');
  for(const name of ['COLOR_0','TEXCOORD_0']){
    if(name in p.attributes && index.accessors[p.attributes[name]].count!==positions.count){
      throw Error('GLB '+name+' count mismatch');
    }
  }
  const view=index.bufferViews[indices.bufferView];
  for(let i=0;i<indices.count;i++){
    if(saved.readUInt16LE(28+jsonLength+view.byteOffset+i*2)>=positions.count) throw new Error('GLB index out of bounds');
  }
}
for(const img of index.images??[]){
  const view=index.bufferViews[img.bufferView];
  const offset=28+jsonLength+view.byteOffset;
  if(saved.readUInt32BE(offset)!==0x89504e47 || saved.readUInt32BE(offset+16)!==1024
    || saved.readUInt32BE(offset+20)!==1024) throw Error('Invalid embedded atlas image');
}

const manifest={
  schemaVersion:1,assetId:vehicle,name:baseName,stage:'First production pass',source:folder+'/source/'+source,
  export:folder+'/exports/'+exportName,orientation:{units:'m',up:'+Y',forward:'-Z',riderLeft:'-X',metresPerStud:.28},
  boundsM:bounds(allPoints),...(sm50?{wheelbaseM:1.328,nominalSeatHeightM:.891,wheelSize:'17-inch rim class'}:{}),
  ...(!sm50||distance?{}:{relatedAssets:{
    distanceModel:folder+'/exports/SM50-distance.manifest.json',
    starterGarage:'environment/starter-garage/exports/StarterGarage.manifest.json',
    commuterScooter:'vehicles/commuter-scooter/exports/CommuterScooter.manifest.json',
    ruralRoadKit:'environment/rural-road-kit/exports/RuralRoadKit.manifest.json',
    ruralHouse:'environment/rural-house/exports/RuralHouse.manifest.json',
    roadsideProps:'environment/roadside-props/exports/RoadsideProps.manifest.json',
    performanceScooter:'vehicles/performance-scooter/exports/PerformanceScooter.manifest.json',
    assemblyCatalog:folder+'/exports/ZefirSM50Catalog.manifest.json',
    worldCatalog:'environment/starter-garage/exports/TwoStrokeWorldCatalog.manifest.json',
  }}),
  datumsM:datums,proxies,materials:Object.fromEntries(Object.entries(materials).map(([key,[name,hex,metallic,roughness,studioMaterial,transparency=0]])=>
    [key,{name,hex,metallic,roughness,studioMaterial,transparency}])),components:parts,
  stats:{triangles:parts.reduce((n,p)=>n+p.triangles,0),components:parts.length,
    materialLayers:glb.meshes.reduce((n,p)=>n+p.primitives.length,0),
    maxTrianglesPerComponent:Math.max(...parts.map(p=>p.triangles))},
};
if(atlas) manifest.textureAtlas={resolution:1024,uvSet:0,projection:'Bounded diagonal projection per material. Shared across all parts.',
  files:Object.keys(atlas.images).filter(k=>k!=='orm')
  .map(key=>folder+'/exports/'+texturePrefix+'-'+key+'.png')};
if(distance){
  manifest.stage='Distance model';
  const detailed=JSON.parse(readFileSync(file('../../../ASSET_MANIFEST.json')));
  const originals=new Map(detailed.components.map(p=>[p.assetId,p]));
  for(const p of parts){
    const original=originals.get(p.assetId);
    for(const key of ['pivotM','attachmentLocalM']){
      if(JSON.stringify(p[key])!==JSON.stringify(original[key])) throw Error(p.name+' changed its '+key);
    }
  }
  manifest.omittedServiceParts=detailed.components.filter(p=>!known.has(p.name)).map(p=>p.name);
}
writeFileSync(file(!sm50||distance?output+baseName+suffix+'.manifest.json':'../../../ASSET_MANIFEST.json'),
  JSON.stringify(manifest,null,2)+'\n');

// The preview loader shares source geometry with the GLB without requiring asset uploads.
// Each batch is an independent compressed buffer for the Studio edit tool.
const batches={};
const studioPalette=Object.fromEntries(Object.entries(manifest.materials));
for(const [category, group] of studioGroups){
  const pack = batch => {
    const chunks=[];
    const meta=batch.map(({name,pivot,attachments,layers})=>({name,pivot,attachments,layers:layers.map(({key,vertices,normals,faces,colors})=>{
      const position=Float32Array.from(vertices.flat());
      const normal=Int8Array.from(normals.flat(),n=>Math.round(n*127));
      const index=Uint16Array.from(faces.flat());
      chunks.push(Buffer.from(position.buffer),Buffer.from(normal.buffer),Buffer.from(index.buffer));
      if(colors) chunks.push(Buffer.from(colors.map(k=>palette.indexOf(k))));
      return {key,v:vertices.length,f:faces.length,hasColors:!!colors};
    })}));
    const json=Buffer.from(JSON.stringify({category,parts:meta,palette:studioPalette,colorKeys:palette}));
    const length=Buffer.alloc(4);
    length.writeUInt32LE(json.length);
    return zstdCompressSync(Buffer.concat([length,json,...chunks])).toString('base64');
  };
  // Bound the size of individual Studio calls, including the larger wheel meshes.
  let batch=[], i=1;
  for(const part of group){
    if(batch.length && pack([...batch,part]).length>95000){
      batches[category+i++]=pack(batch);
      batch=[];
    }
    batch.push(part);
  }
  if(batch.length) batches[category+i]=pack(batch);
}
if(!atlas) writeFileSync(file(output+baseName+suffix+'.studio.json'),JSON.stringify({proxies,batches}));
console.log(JSON.stringify({stats:manifest.stats,bounds:manifest.boundsM,batches:Object.keys(batches)},null,2));
