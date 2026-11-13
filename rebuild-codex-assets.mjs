import {mkdirSync} from 'node:fs';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';

const root=fileURLToPath(new URL('./',import.meta.url));
for (const directory of ["vehicles/sm50","vehicles/commuter-scooter","vehicles/performance-scooter","environment/starter-garage","environment/rural-road-kit","environment/rural-house","environment/roadside-props"]) {
  mkdirSync(new URL('assets/'+directory+'/exports/',import.meta.url),{recursive:true});
}
mkdirSync(new URL('assets/vehicles/sm50/audio/',import.meta.url),{recursive:true});
function run(script,...args) {
  const result=spawnSync(process.execPath,['assets/vehicles/sm50/source/'+script,...args],{cwd:root,stdio:'inherit'});
  if(result.status!==0) throw result.error ?? new Error('Asset build failed: '+script+' '+args.join(' '));
}
for(const flags of [[],['--distance'],['--garage'],['--scooter'],['--performance-scooter'],['--roads'],['--house'],['--props'],['--catalog'],['--world-catalog'],['--catalog','--pbr']]) run('build.mjs',...flags);
for(const script of ['check-clearance.mjs','check-catalog.mjs','build-audio.mjs']) run(script);
