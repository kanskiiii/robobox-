import {readFileSync} from 'node:fs';
import {fileURLToPath} from 'node:url';
import {createHash} from 'node:crypto';

const assetRoot=new URL('../../../',import.meta.url);
const primary=JSON.parse(readFileSync(new URL('ASSET_MANIFEST.json',assetRoot)));
const sequence=[
  ['assemblyCatalog','Zefir SM 50 Assembly Catalog'],
  ['worldCatalog','Two-Stroke World Catalog'],
  ['sm50','Two-Stroke SM50'],
  ['distanceModel','Two-Stroke SM50 Distance'],
  ['starterGarage','Two-Stroke Starter Garage'],
  ['commuterScooter','Two-Stroke Commuter Scooter'],
  ['performanceScooter','Two-Stroke Performance Scooter'],
  ['ruralRoadKit','Two-Stroke Rural Road Kit'],
  ['ruralHouse','Two-Stroke Rural House'],
  ['roadsideProps','Two-Stroke Roadside Props'],
];
const uploads=sequence.map(([key,displayName])=>{
  const manifestPath=key==='sm50'?'ASSET_MANIFEST.json':primary.relatedAssets[key];
  const manifest=JSON.parse(readFileSync(new URL(manifestPath,assetRoot)));
  const exportPath=new URL(manifest.export,assetRoot);
  const bytes=readFileSync(exportPath);
  if(bytes.toString('ascii',0,4)!=='glTF' || bytes.readUInt32LE(8)!==bytes.length
    || bytes.length>20*1024*1024) throw Error('Invalid upload file '+manifest.export);
  return {key,displayName,file:fileURLToPath(exportPath),manifest:fileURLToPath(new URL(manifestPath,assetRoot)),
    bytes:bytes.length,sha256:createHash('sha256').update(bytes).digest('hex')};
});
if(new Set(uploads.map(entry=>entry.file)).size!==uploads.length) throw Error('Duplicate upload file');
console.log(JSON.stringify({placeId:'112877997436632',creatorId:'7970593771',uploads},null,2));
