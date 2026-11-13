import {readFileSync,writeFileSync} from 'node:fs';
import {components,datums} from './catalog.mjs';
import {add,cross,length,mul,sub,unit} from './geometry.mjs';

const exportFile=name=>new URL('../exports/'+name,import.meta.url);
const manifest=JSON.parse(readFileSync(exportFile('ZefirSM50Catalog.manifest.json')));
const byName=new Map(components.map(part=>[part.name,part]));
const dimensions=new Map(manifest.components.map(part=>[part.name,part.dimensionsM]));
const envelopes={
  block_am6:[.240,.220,.340],piston_40:[.045,.050,.045],cylinder_50:[.120,.120,.120],
  head_std:[.130,.050,.130],plug_std:[.020,.060,.020],clutch_std:[.050,.160,.160],
  carb_17:[.060,.090,.090],filter_std:[.140,.120,.140],exhaust_std:[.100,.120,.900],
  fork_std:[.180,.750,.100],handlebar_std:[.780,.050,.050],wheel_front_17:[.100,.590,.590],
  wheel_rear_17:[.130,.614,.614],swingarm_std:[.200,.060,.550],shock_std:[.070,.320,.070],
  tank_std:[.260,.160,.420],seat_std:[.220,.070,.500],radiator_std:[.260,.220,.040],
  brake_front_std:[.020,.260,.260],brake_rear_std:[.020,.220,.220],chain_420:[.012,.040,.560],
  cdi_restricted:[.050,.040,.070],fuel_line:[.015,.140,.015],piston_47:[.050,.050,.050],
  cylinder_70:[.130,.120,.130],head_hc:[.130,.050,.130],clutch_race:[.050,.160,.160],
  carb_21:[.070,.100,.100],filter_sport:[.090,.090,.120],exhaust_sport:[.120,.140,.950],
  cdi_open:[.050,.040,.070],
};
for(const tooth of [11,12,13,14]) envelopes['sprocket_f_'+tooth]=[.015,.060,.060];
for(const tooth of [47,50,53]) envelopes['sprocket_r_'+tooth]=[.015,.210,.210];
const oversize=Object.entries(envelopes).flatMap(([name,nominal])=>{
  const actual=dimensions.get('Part_'+name);
  const axes=actual.flatMap((value,i)=>value>nominal[i]*1.2?['XYZ'[i]]:[]);
  return axes.length?[{part:'Part_'+name,nominalM:nominal,actualM:actual,axes}]:[];
});

function radius(name,axle){
  const part=byName.get(name);
  if(length(sub(part.pivot,axle))>1e-7) throw Error('Wrong wheel pivot '+name);
  return Math.max(...part.layers.vertex.vertices.map(p=>Math.hypot(p[1]-axle[1],p[2]-axle[2])));
}
const frontRadiusM=radius('Part_wheel_front_17',datums.Mount_FrontWheel);
const rearRadiusM=radius('Part_wheel_rear_17',datums.Mount_RearWheel);
const wheelbaseM=length(sub(datums.Mount_FrontWheel,datums.Mount_RearWheel));
if(Math.abs(frontRadiusM-.295)>1e-7 || Math.abs(rearRadiusM-.307)>1e-7
  || Math.abs(wheelbaseM-1.35)>1e-7) throw Error('Fixed catalog geometry failed');

const mountCount=Object.keys(byName.get('Frame').attachments).length;
if(mountCount!==25 || manifest.components.length!==39) throw Error('Missing catalog parts or mounts');
const expectedParts=new Set(['Frame',...Object.keys(envelopes).map(id=>'Part_'+id)]);
const expectedMounts=[
  'FrontFork','Handlebar','FrontWheel','FrontBrake','Swingarm','RearShock','RearWheel','RearBrake',
  'RearSprocket','EngineBlock','Clutch','FrontSprocket','Piston','Cylinder','CylinderHead',
  'SparkPlug','Carburetor','AirFilter','Exhaust','Ignition','Chain','Radiator','FuelTank','FuelLine','Seat',
];
for(const name of expectedMounts){
  if(!byName.get('Frame').attachments['Mount_'+name]) throw Error('Missing Mount_'+name);
}
for(const part of manifest.components){
  if(!expectedParts.delete(part.name)) throw Error('Unexpected or duplicate component '+part.name);
  const limit=part.name.includes('wheel')?10000:/block|exhaust/.test(part.name)?20000:8000;
  if(part.triangles>limit || part.materials.length!==1) throw Error('Catalog limit failed for '+part.name);
}
if(expectedParts.size) throw Error('Missing components: '+[...expectedParts].join(', '));

const dot=(a,b)=>a.reduce((sum,x,i)=>sum+x*b[i],0);
function rotate(p,origin,axis,angle){
  const d=sub(p,origin);
  return add(origin,add(add(mul(d,Math.cos(angle)),mul(cross(axis,d),Math.sin(angle))),
    mul(axis,dot(d,axis)*(1-Math.cos(angle)))));
}
function meshPoints(names){
  return names.flatMap(name=>byName.get(name).layers.vertex.vertices);
}
function radialGap(points,center,radius,halfWidth){
  return Math.min(...points.map(p=>{
    const d=sub(p,center), r=Math.hypot(d[1],d[2]);
    // Screen the outer tread envelope and the space occupied by its wheel plane.
    return Math.max(Math.abs(d[0])-halfWidth,r-radius);
  }));
}
const fixedFront=meshPoints(['Frame','Part_exhaust_std','Part_tank_std','Part_radiator_std']);
const fixedRear=meshPoints(['Frame','Part_seat_std','Part_filter_std','Part_exhaust_std']);
const steeringLower=datums.Mount_FrontFork;
const steeringAxis=unit([0,.149,.071]);
const forkAxis=unit(sub(steeringLower,datums.Mount_FrontWheel));
const mm=n=>Math.round(n*1000);
const frontSweep=[0,.05,.08,.10,.12].map(travel=>{
  const hub=add(datums.Mount_FrontWheel,mul(forkAxis,travel));
  const samples=[-32,-24,-16,-8,0,8,16,24,32].map(degrees=>{
    const angle=-degrees*Math.PI/180;
    const points=fixedFront.map(p=>rotate(p,steeringLower,steeringAxis,angle));
    return {steeringDeg:degrees,gapMm:mm(radialGap(points,hub,.295,.054))};
  });
  return {travelMm:mm(travel),worst:samples.reduce((a,b)=>a.gapMm<=b.gapMm?a:b),samples};
});
const rearSweep=[0,5,10,15,20].map(angle=>{
  const center=rotate(datums.Mount_RearWheel,datums.Mount_Swingarm,[1,0,0],-angle*Math.PI/180);
  return {swingDeg:angle,travelMm:mm(center[1]-datums.Mount_RearWheel[1]),
    gapMm:mm(radialGap(fixedRear,center,.307,.066))};
});
const result={
  wheelbaseM,frontRadiusM,rearRadiusM,mountCount,entries:manifest.components.length,
  catalogTriangles:manifest.stats.triangles,envelopeDeviationsOver20Percent:oversize,
  note:'Claude’s dimensions for part envelopes are placeholders. Deviations include combined functional geometry such as exhaust, radiator hoses, forks, and brake calipers.',
  tireEnvelopeScreen:{
    frontSweep,rearSweep,
    method:'Conservative cylindrical tire envelope tested against sampled vertices of fixed assemblies. Positive values are sampled gaps. Negative values indicate a vertex enters the cylinder, which can include empty wheel space. Recheck with continuous mesh or physics sweeps before authoring travel limits.',
  },
};
writeFileSync(exportFile('ZefirSM50Catalog.validation.json'),JSON.stringify(result,null,2)+'\n');
console.log(JSON.stringify({entries:result.entries,mountCount,wheelbaseM,frontRadiusM,rearRadiusM,
  envelopeDeviations:oversize.length}));
