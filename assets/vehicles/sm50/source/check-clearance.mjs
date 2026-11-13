import {writeFileSync} from 'node:fs';
import {components, datums} from './motorcycle.mjs';
import {add, sub, mul, cross, unit, mix} from './geometry.mjs';

const byName = new Map(components.map(part => [part.name, part]));
const vertices = names => names.flatMap(name => Object.values(byName.get(name).layers).flatMap(mesh => mesh.vertices));
const dot = (a,b) => a.reduce((sum,x,i)=>sum+x*b[i],0);
const around = (p,origin,axis,angle) => {
  const d=sub(p,origin);
  return add(origin,add(add(mul(d,Math.cos(angle)),mul(cross(axis,d),Math.sin(angle))),
    mul(axis,dot(axis,d)*(1-Math.cos(angle)))));
};
const mm = n => Math.round(n*1000);
const deg = n => n*Math.PI/180;
const main = byName.get('MainFrame').attachments;
const triple = byName.get('SteeringAssembly').attachments;
const steerAxis = unit(sub(triple.SteeringUpper,triple.SteeringLower));
const forkAxis = unit(sub(byName.get('ForkUpper_L').attachments.ForkTop,
  byName.get('ForkLower_L').attachments.FrontAxle));
const frontWheel = datums.FrontAxle;
const rearWheel = datums.RearAxle;
const frontFixed = ['MainFrame','FuelTank','RadiatorShroud_L','RadiatorShroud_R','Header','ExpansionChamber']
  .map(name=>[name,vertices([name])]);
const frontFender = vertices(['FrontFender']);
const rearFixed = vertices(['Subframe','RearFender','SidePanel_L','SidePanel_R','Silencer','Airbox','TailLight','NumberPlate']);

// Approximate the rubber by a smooth tire envelope through measured cross sections.
// Negative values mean a component vertex enters this envelope.
const sections = [[0,0],[.16,.002],[.32,.009],[.44,.022],[.50,.043]];
function clearance(p, center, width, radius) {
  const d=sub(p,center);
  const x=Math.abs(d[0])/width;
  const r=Math.hypot(d[1],d[2]);
  if(x>.5) return Math.hypot((x-.5)*width,Math.max(0,r-(radius-.043)));
  if(r<.217) return .217-r;
  for(let i=1;i<sections.length;i++){
    const [a,b]=sections[i-1], [c,e]=sections[i];
    if(x<=c) return r-(radius-mix([b],[e],(x-a)/(c-a))[0]);
  }
  throw Error('Invalid tire section');
}
function minimum(points, center, w, r) {
  let result=Infinity;
  for(const point of points) result=Math.min(result,clearance(point,center,w,r));
  return result;
}

const front = [];
for(const compression of [0,.05,.08,.10,.12]){
  const center=add(frontWheel,mul(forkAxis,compression));
  const fenderMm=mm(minimum(frontFender,center,.105,.301));
  let chassisMm=Infinity, closest, steeringDeg;
  for(const yaw of [-32,-24,-16,-8,0,8,16,24,32]){
    for(const [name,points] of frontFixed){
      const distance=mm(minimum(points.map(p=>around(p,triple.SteeringLower,steerAxis,-deg(yaw))),center,.105,.301));
      if(distance<chassisMm){
        chassisMm=distance;
        closest=name;
        steeringDeg=yaw;
      }
    }
  }
  front.push({compressionMm:mm(compression),fenderMm,chassisMm,closest,steeringDeg});
}
const rear = [];
for(const swingDeg of [0,5,10,15,20]){
  const center=around(rearWheel,main.SwingarmAxis,[1,0,0],-deg(swingDeg));
  rear.push({swingDeg,verticalTravelMm:mm(center[1]-rearWheel[1]),
    chassisAndBodyMm:mm(minimum(rearFixed,center,.132,.299))});
}
const result = {
  method:'Sampled component vertices against nominal tire envelope. Static mesh screening.',
  limits:'Distances are approximate. Triangle interiors, deformation, dynamic clearances, brake and chain sweep, and gear engagement need separate checks.',
  steeringDeg:[-32,32],front,rear,
};
writeFileSync(new URL('../exports/SM50-clearance.json',import.meta.url),JSON.stringify(result,null,2)+'\n');
console.log(JSON.stringify(result,null,2));
