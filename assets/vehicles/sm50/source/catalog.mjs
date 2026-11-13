import {components as model,materials as sourceMaterials} from './motorcycle.mjs';
import {Mesh,v,add,sub,mul,mix,tau} from './geometry.mjs';

export const materials={...sourceMaterials,
  vertex:['Catalog vertex colours','#ffffff',.18,.54,'SmoothPlastic'],
  gold:['Anodised gold','#bc8b38',.55,.43,'Metal'],
  raceRed:['Aftermarket red','#a63d35',.29,.44,'Metal'],
};
const parts=new Map(model.map(p=>[p.name,p]));
const chassis=v(0,.55,-.014);
const shift=p=>sub(p,chassis);
const point=name=>parts.get(name).pivot;
const front=v(0,-.25,.70), rear=v(0,-.25,-.65);
const mounts={
  FrontFork:shift(parts.get('SteeringAssembly').attachments.SteeringLower),
  Handlebar:shift(point('Handlebar')),FrontWheel:front,FrontBrake:add(front,[.083,0,0]),
  Swingarm:shift(point('Swingarm')),RearShock:shift(point('ShockBody')),
  RearWheel:rear,RearBrake:add(rear,[.103,0,0]),RearSprocket:add(rear,[-.109,0,0]),
  EngineBlock:shift(point('Crankshaft')),Clutch:shift(add(point('ClutchBasket'),[.071,0,0])),
  FrontSprocket:shift(point('FrontSprocket')),Piston:shift(point('Piston')),
  Cylinder:shift(point('Cylinder')),CylinderHead:shift(point('CylinderHead')),
  SparkPlug:shift(point('SparkPlug')),Carburetor:shift(point('Carburetor')),AirFilter:shift(point('Airbox')),
  Exhaust:shift(point('Header')),Ignition:v(-.08,.15,-.30),Chain:shift(point('Chain')),
  Radiator:shift(point('Radiator_R')),FuelTank:shift(point('FuelTank')),
  FuelLine:shift(parts.get('FuelTank').attachments.FuelOutlet),Seat:shift(point('Seat')),
};
export const datums={...Object.fromEntries(Object.entries(mounts).map(([k,p])=>['Mount_'+k,p])),
  ChassisOrigin:[0,0,0]};
export const proxies=[];
export const components=[];

function append(target, mesh, map, key, select=()=>true){
  for(const [i,s] of mesh.solids.entries()){
    if(!select(i,s)) continue;
    const {startVertex,endVertex,startFace,endFace}=s;
    const base=target.vertices.length;
    for(const p of mesh.vertices.slice(startVertex,endVertex)){
      target.vertices.push(map(p));target.colors.push(key);
    }
    const f=target.triangles.length;
    for(const face of mesh.triangles.slice(startFace,endFace)){
      target.triangles.push(face.map(j=>j-startVertex+base));
    }
    target.solids.push({startVertex:base,endVertex:target.vertices.length,startFace:f,endFace:target.triangles.length});
  }
}
const begin=(name,pivot,markers={},category='Parts')=>{
  const mesh=new Mesh();
  mesh.colors=[];
  const component={name,category,pivot,layers:{vertex:mesh},attachments:markers,interaction:'Install using the matching frame mount'};
  components.push(component);
  return mesh;
};
function source(target,name,map=shift,colors={},selection=()=>true){
  for(const [key,mesh] of Object.entries(parts.get(name).layers)){
    append(target,mesh,map,colors[key]??key,(i,s)=>selection(key,i,s));
  }
}
const synth=(target,key,draw)=>{
  const mesh=new Mesh();
  draw(mesh);
  append(target,mesh,p=>p,key);
};
const boltPoints=(p,n,r,axis='X')=>Object.fromEntries(Array.from({length:n},(_,i)=>{
  const t=i*2*Math.PI/n;
  return ['Bolt_'+(i+1),add(p,axis==='X'?[0,r*Math.cos(t),r*Math.sin(t)]:[r*Math.cos(t),0,r*Math.sin(t)])];
}));
const realBolts=(...points)=>Object.fromEntries(points.map((p,i)=>['Bolt_'+(i+1),shift(p)]));
function assembled(id,mount,names,{bolts={},map=shift,colors={},selection}={}){
  const mesh=begin('Part_'+id,mounts[mount],bolts);
  for(const name of names) source(mesh,name,map,colors,selection);
  return mesh;
}
const frame=begin('Frame',[0,0,0],Object.fromEntries(Object.entries(datums).filter(([k])=>k.startsWith('Mount_'))),'Vehicles');
for(const name of ['MainFrame','Subframe','FootPeg_L','FootPeg_R','SideStand']) source(frame,name);

const engine=assembled('block_am6','EngineBlock',['Crankcase_L','Crankcase_R','GearboxHousing',
  'IgnitionCover','Crankshaft','ConnectingRod','GearboxInputShaft','GearboxOutputShaft','Kickstarter'],
  {bolts:realBolts(v(0,.354,.201),v(0,.336,-.115),v(0,.439,-.162))});
synth(engine,'alloy',m=>{
  const p=shift(point('Cylinder'));
  for(const x of [-.035,.035]) for(const z of [-.028,.028]){
    const a=add(p,[x,-.004,z]);
    m.rod(a,add(a,[0,.021,-.004]),.0032,9);
  }
  const side=add(mounts.Clutch,[.016,0,0]);
  m.lathe(side,[1,0,0],[[-.012,.046],[-.012,.052],[.012,.052],[.012,.046]],40);
});
const piston=assembled('piston_40','Piston',['Piston'],{bolts:boltPoints(mounts.Piston,2,.019)});
synth(piston,'alloy',m=>m.rod(add(mounts.Piston,[-.017,-.009,0]),add(mounts.Piston,[.017,-.009,0]),.0042,16));
assembled('cylinder_50','Cylinder',['Cylinder'],{bolts:boltPoints(mounts.Cylinder,4,.048,'Y')});
assembled('head_std','CylinderHead',['CylinderHead'],{bolts:boltPoints(mounts.CylinderHead,4,.037,'Y')});
assembled('plug_std','SparkPlug',['SparkPlug'],{bolts:{Bolt_1:mounts.SparkPlug}});
function clutch(id,key){
  const p=mounts.Clutch;
  const mesh=assembled(id,'Clutch',['ClutchBasket','ClutchPlateStack','ClutchPressurePlate'],{bolts:boltPoints(p,5,.022)});
  synth(mesh,key,m=>{
    for(let i=0;i<5;i++){
      const a=i*2*Math.PI/5;
      const c=add(p,[.021,.025*Math.cos(a),.025*Math.sin(a)]);
      const nodes=Array.from({length:29},(_,j)=>{
        const t=j/28, angle=t*7*Math.PI;
        return add(c,[t*.012,.0035*Math.cos(angle),.0035*Math.sin(angle)]);
      });
      m.tube(nodes,nodes.map(()=>.0008),6);
    }
  });
}
clutch('clutch_std','rotor');
assembled('carb_17','Carburetor',['IntakeManifold','Carburetor'],
  {bolts:realBolts(v(0,.535,-.057),v(0,.543,-.145))});
assembled('filter_std','AirFilter',['Airbox','AirboxBoot'],{bolts:realBolts(v(-.073,.691,-.387))});
const exhaustBolts=realBolts(point('Header'),v(.152,.558,-.233),v(.130,.782,-.656));
assembled('exhaust_std','Exhaust',['Header','ExpansionChamber','Silencer','ExhaustMounts'],{bolts:exhaustBolts});

const atAxle=(p,original,target)=>add(shift(p),sub(target,shift(original)));
const frontDelta=sub(front,shift(point('FrontTire')));
const rearDelta=sub(rear,shift(point('RearTire')));
const frontFit=p=>{
  const t=Math.min(1,Math.max(0,(.81-p[1])/.51));
  return add(shift(p),mul(frontDelta,t));
};
const rearFit=p=>{
  const t=Math.min(1,Math.max(0,(-p[2]-.20)/.46));
  return add(shift(p),mul(rearDelta,t));
};
assembled('fork_std','FrontFork',['SteeringAssembly','ForkUpper_L','ForkUpper_R','ForkLower_L','ForkLower_R','FrontFender','HeadlightMask','Headlight'],
  {map:frontFit,bolts:realBolts(v(-.121,.789,.466),v(.121,.789,.466),v(-.121,.963,.385),v(.121,.963,.385))});
const fitHandlebar=p=>shift([p[0]*1.051,p[1],p[2]]);
const gripMarkers=parts.get('Handlebar').attachments;
assembled('handlebar_std','Handlebar',['Handlebar','LeftGrip','ThrottleGrip','ClutchLever','FrontBrakeLever',
  'FrontBrakeMasterCylinder','InstrumentCluster'],{map:fitHandlebar,
  bolts:{...realBolts(v(-.044,1.021,.325),v(.044,1.021,.325),v(-.044,1.021,.350),v(.044,1.021,.350)),
    GripL:fitHandlebar(gripMarkers.GripL),GripR:fitHandlebar(gripMarkers.GripR)}});
for(const [label,r,target] of [['Front',.295,front],['Rear',.307,rear]]){
  const original=point(label+'Tire');
  const r0=label==='Front'?.301:.299;
  const map=p=>{
    const d=sub(p,original);
    return add(target,[d[0],d[1]*r/r0,d[2]*r/r0]);
  };
  const mesh=assembled('wheel_'+label.toLowerCase()+'_17',label+'Wheel',
    [label+'Tire',label+'Rim',label+'Hub',label+'SpokeSet'],{map,bolts:{Bolt_1:target},
      selection:(key,i)=>key!=='tread'&&(key!=='alloy'||i%2===0)});
  const envelope=Math.max(...mesh.vertices.map(p=>Math.hypot(p[1]-target[1],p[2]-target[2])));
  if(Math.abs(envelope-r)>.000001) throw Error(label+' wheel radius drift');
}
assembled('swingarm_std','Swingarm',['Swingarm','ChainGuide'],{map:rearFit,bolts:{Bolt_1:mounts.Swingarm}});
assembled('shock_std','RearShock',['ShockBody','ShockShaft','ShockSpring'],
  {colors:{spring:'raceRed'},bolts:realBolts(point('ShockBody'),point('ShockShaft'))});
assembled('tank_std','FuelTank',['FuelTank','RadiatorShroud_L','RadiatorShroud_R'],
  {bolts:realBolts(v(-.116,.882,.179),v(.116,.882,.179))});
assembled('seat_std','Seat',['Seat','SidePanel_L','SidePanel_R','RearFender','TailLight','NumberPlate'],
  {bolts:realBolts(v(0,.889,-.079),v(0,.838,-.573))});
assembled('radiator_std','Radiator',['Radiator_L','Radiator_R','CoolantHoses'],
  {bolts:realBolts(v(-.076,.751,.208),v(.076,.751,.208),v(.035,.634,.104))});
for(const [label,axle] of [['Front',front],['Rear',rear]]){
  const original=point(label+'Tire');
  assembled('brake_'+label.toLowerCase()+'_std',label+'Brake',[label+'BrakeDisc',label+'BrakeCaliper'],
    {map:p=>atAxle(p,original,axle),selection:key=>key!=='tread',bolts:boltPoints(mounts[label+'Brake'],2,.035)});
}
for(const [label,counts,r] of [['f',[11,12,13,14],.029],['r',[47,50,53],.090]]){
  const mount=label==='f'?'FrontSprocket':'RearSprocket',p=mounts[mount];
  for(const count of counts){
    const mesh=begin('Part_sprocket_'+label+'_'+count,p,boltPoints(p,label==='f'?1:6,label==='f'?0:.050));
    const radius=r*(count/(label==='f'?12:48)), inner=label==='f'?.010:.043;
    synth(mesh,'grease',m=>m.lathe(p,[1,0,0],[[-.003,inner],[-.003,radius-.005],[-.002,radius],
      [.002,radius],[.003,radius-.005],[.003,inner]],count*4,
      (i,j)=>j===2||j===3?(i%4===1||i%4===2?.0026:-.0021):0));
    synth(mesh,'alloy',m=>{
      if(label==='f') m.rod(add(p,[-.008,0,0]),add(p,[-.002,0,0]),.012,6);
      else for(let i=0;i<6;i++){
        const a=i*Math.PI/3;
        m.rod(add(p,[0,.032*Math.cos(a),.032*Math.sin(a)]),add(p,[0,.061*Math.cos(a),.061*Math.sin(a)]),.006,8);
      }
    });
  }
}
const chain=begin('Part_chain_420',mounts.Chain,{Bolt_1:mounts.Chain});
const pitchFront=mounts.FrontSprocket,pitchRear=mounts.RearSprocket;
const separation=sub(pitchFront,pitchRear), small=.029,big=.094;
const theta=Math.atan2(separation[2],separation[1]);
const angle=Math.acos((big-small)/Math.hypot(separation[1],separation[2]));
const polar=(p,r,t)=>add(p,[0,r*Math.cos(t),r*Math.sin(t)]);
const a=theta-angle,b=theta+angle;
const samples=[
  ...Array.from({length:25},(_,i)=>polar(pitchFront,small,a+(b-a)*i/24)),
  ...Array.from({length:41},(_,i)=>polar(pitchRear,big,b+(tau-(b-a))*i/40)),
];
const segmentLengths=samples.map((p,i)=>Math.hypot(...sub(samples[(i+1)%samples.length],p)));
const loop=segmentLengths.reduce((sum,n)=>sum+n,0), links=2*Math.round(loop/.0254);
const pitchPath=[];
for(let i=0,j=0,start=0;i<links;i++){
  const d=loop*i/links;
  while(d>start+segmentLengths[j]) start+=segmentLengths[j++];
  pitchPath.push(mix(samples[j],samples[(j+1)%samples.length],(d-start)/segmentLengths[j]));
}
synth(chain,'grease',m=>{
  for(let i=0;i<links;i++){
    const p=pitchPath[i],q=pitchPath[(i+1)%links],spacing=i%2?.0056:.0042;
    for(const side of [-1,1]){
      const x=[side*spacing,0,0];
      m.tube([add(mix(p,q,-.09),x),add(mix(p,q,.09),x),add(mix(p,q,.91),x),add(mix(p,q,1.09),x)],
        [[.0008,.0025],[.0009,.004],[.0009,.004],[.0008,.0025]],4,[1,0,0]);
    }
  }
});
function ignition(id,color){
  const p=mounts.Ignition;
  const m=begin('Part_'+id,p,{Bolt_1:p});
  synth(m,color,k=>k.shell([[.267,p[1],.023,.019,p[0]],[.295,p[1],.026,.020,p[0]],
    [.325,p[1],.023,.018,p[0]]],12,.48));
  synth(m,'rubber',k=>k.tube([add(p,[0,0,-.024]),add(p,[.029,.052,-.126]),
    add(mounts.SparkPlug,[0,.063,.096]),add(mounts.SparkPlug,[0,.031,-.004])],
    [.004,.004,.004,.004],8));
}
ignition('cdi_restricted','black');
const fuel=begin('Part_fuel_line',mounts.FuelLine,{Bolt_1:mounts.FuelLine,Bolt_2:mounts.Carburetor});
const fuelEnd=add(mounts.Carburetor,[.027,.021,-.003]);
synth(fuel,'rubber',m=>m.tube([mounts.FuelLine,add(mounts.FuelLine,[.022,-.051,-.008]),
  add(fuelEnd,[.011,.047,.013]),fuelEnd],[.0034,.0034,.0034,.0034],10));
synth(fuel,'alloy',m=>{for(const p of [mounts.FuelLine,fuelEnd]) m.rod(add(p,[0,-.004,0]),add(p,[0,.002,0]),.0046,10);});

const around=(p,k)=>q=>add(p,mul(sub(shift(q),p),k));
assembled('piston_47','Piston',['Piston'],{map:around(mounts.Piston,47.6/40.3),bolts:boltPoints(mounts.Piston,2,.023)});
assembled('cylinder_70','Cylinder',['Cylinder'],{map:around(mounts.Cylinder,1.10),colors:{cast:'alloy'},
  bolts:boltPoints(mounts.Cylinder,4,.051,'Y')});
assembled('head_hc','CylinderHead',['CylinderHead'],{colors:{cast:'gold'},bolts:boltPoints(mounts.CylinderHead,4,.037,'Y')});
clutch('clutch_race','gold');
assembled('carb_21','Carburetor',['Carburetor'],{map:around(mounts.Carburetor,1.16),colors:{cast:'alloy'},
  bolts:realBolts(v(0,.535,-.057),v(0,.543,-.145))});
const filter=begin('Part_filter_sport',mounts.AirFilter,{Bolt_1:mounts.AirFilter});
synth(filter,'raceRed',m=>m.lathe(mounts.AirFilter,[0,0,1],[[-.055,.024],[-.055,.033],
  [-.042,.038],[.031,.044],[.043,.040],[.043,.023]],48,
  (i,j)=>j>0&&j<5?.003*Math.cos(i*Math.PI/2):0));
const racePipe=begin('Part_exhaust_sport',mounts.Exhaust,exhaustBolts);
source(racePipe,'Header',shift,{pipe:'chrome'});
source(racePipe,'ExpansionChamber',p=>{
  const station=-p[2];
  // Keep the inlet, stinger and mounting points fixed while expanding the belly.
  const t=Math.max(0,Math.min(1,(station+.20)/.43));
  const swell=.011*Math.sin(Math.PI*t)**2;
  return shift([p[0]+swell,p[1]-swell*.34,p[2]]);
},{pipe:'anodized',weld:'alloy'});
source(racePipe,'Silencer',p=>{
  const station=-p[2];
  const inset=Math.max(0,Math.min(.074,(-.48-station)*.33));
  return shift([p[0],p[1]-inset*.22,p[2]-inset]);
},{alloy:'chrome',anodized:'frame'});
source(racePipe,'ExhaustMounts');
ignition('cdi_open','gold');
