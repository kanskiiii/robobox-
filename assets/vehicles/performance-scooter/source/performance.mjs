import {Mesh,v,sub,add,mix,unit,tau} from '../../sm50/source/geometry.mjs';
import {components as commuter,datums as commuterDatums,materials as commuterMaterials,proxies as commuterProxies}
  from '../../commuter-scooter/source/scooter.mjs';

export const materials={
  ...commuterMaterials,
  paint:['Black textured powder coat','#2c3335',.48,.46,'Metal'],
  trim:['Scarlet anodized aluminium','#bf3738',.53,.32,'Metal'],
  spring:['Scarlet suspension spring','#9e3432',.22,.38,'Metal'],
};
const scale=[1.32,1.12,1.20];
const transform=p=>p.map((x,i)=>x*scale[i]);
const omit=new Set(['FrontHub','RearDamper','Floorboard','Headlamp','TailLamp','WiringHarness']);
function copyComponent(original,name=original.name,map=transform){
  const layers=Object.fromEntries(Object.entries(original.layers).map(([key,geometry])=>{
    const mesh=new Mesh();
    mesh.vertices=geometry.vertices.map(map);
    mesh.triangles=geometry.triangles.map(face=>face.slice());
    mesh.solids=geometry.solids.map(s=>({...s}));
    return [key,mesh];
  }));
  return {...original,name,layers,pivot:map(original.pivot),
    attachments:Object.fromEntries(Object.entries(original.attachments).map(([k,p])=>[k,map(p)]))};
}
const byName=new Map(commuter.map(p=>[p.name,p]));
export const components=commuter.filter(p=>!omit.has(p.name)).map(p=>copyComponent(p));
export const datums=Object.fromEntries(Object.entries(commuterDatums).map(([k,p])=>[k,transform(p)]));
export const proxies=commuterProxies.map(p=>({...p,center:transform(p.center),size:transform(p.size)}));
const X=[1,0,0],Y=[0,1,0];
const front=datums.FrontAxle,rear=datums.RearAxle;
const toFront=p=>add(transform(p),sub(front,rear));
components.push(copyComponent(byName.get('RearHubMotor'),'FrontHubMotor',toFront));
components.push(copyComponent(byName.get('MotorStator'),'FrontMotorStator',toFront));
const toRear=p=>add(transform(p),sub(rear,front));
components.push(copyComponent(byName.get('FrontBrakeDisc'),'RearBrakeDisc',toRear));
components.push(copyComponent(byName.get('FrontCaliper'),'RearCaliper',toRear));
const controller=transform(byName.get('ControllerHousing').pivot);
const rearController=add(controller,[0,0,.087]);
for(const name of ['ControllerHousing','ControllerBoard']){
  const original=byName.get(name);
  components.push(copyComponent(original,'Auxiliary'+name,p=>add(transform(p),[0,0,.087])));
}

function part(category,name,pivot,key,draw,attachments={},interaction='Remove / install'){
  const layers={};
  const layer=(mat,fn)=>fn(layers[mat]??=new Mesh());
  layer(key,m=>draw(m,layer));
  components.push({category,name,pivot,layers,attachments,interaction});
}
function box(m,x,y,z,w,h,d,bevel=.003){
  const a=Math.min(bevel,w*.17,h*.17,d*.17);
  m.plate([[y-h/2,z-d/2+a],[y-h/2+a,z-d/2],[y+h/2-a,z-d/2],[y+h/2,z-d/2+a],
    [y+h/2,z+d/2-a],[y+h/2-a,z+d/2],[y-h/2+a,z+d/2],[y-h/2,z+d/2-a]],x,w,a);
}
function turn(m,p,axis,w,r,n=16){
  m.lathe(p,axis,[[-w/2,.001],[-w/2,r*.87],[-w*.36,r],[w*.36,r],[w/2,r*.87],[w/2,.001]],n);
}
const deck=v(0,.206,-.031);
part('Chassis','Floorboard',deck,'alloy',(m,l)=>{
  m.shell([[-.373,.194,.097,.008],[-.307,.194,.124,.011],[.193,.194,.124,.010],
    [.269,.195,.104,.008],[.308,.198,.077,.006]],18,.41);
  l('tread',b=>{
    box(b,0,.205,-.032,.219,.011,.578);
    for(let i=0;i<16;i++) for(const s of [-1,1]){
      const z=-.294+i*.035;
      b.tube([v(s*.011,.212,z-.017),v(s*.056,.213,z),v(s*.096,.211,z-.009)],
        [[.004,.006],[.004,.007],[.003,.006]],8,Y);
    }
  });
  l('trim',b=>{for(const x of [-.119,.119]) for(const z of [-.287,.197]) turn(b,v(x,.204,z),Y,.006,.008,8);});
},{CoverMount:deck},'Remove top plate to access battery and both controllers');

for(const [s,side] of [[-1,'L'],[1,'R']]){
  const a=v(s*.065,.218,-.333),b=v(s*.067,.155,-.502);
  part('Suspension','RearCoilover_'+side,a,'paint',(m,l)=>{
    m.rod(a,mix(a,b,.53),.018,16);
    m.rod(add(a,[s*.032,-.014,0]),add(mix(a,b,.45),[s*.032,0,0]),.012,14);
    l('alloy',k=>k.rod(mix(a,b,.46),b,.010,16));
    l('spring',k=>{
      const p=Array.from({length:59},(_,i)=>{
        const t=i/58, angle=t*5*tau;
        return add(mix(a,b,.15+t*.70),[.021*Math.cos(angle),.019*Math.sin(angle),-.007*Math.sin(angle)]);
      });
      k.tube(p,p.map(()=>.0033),8);
    });
    l('trim',k=>{for(const t of [.14,.87]) turn(k,mix(a,b,t),unit(sub(b,a)),.009,.024);});
  },{Upper:a,Lower:b},'Pivot at the upper eye and compress along the shaft');
}
part('Electrical','TwinHeadlamp',v(0,.942,.321),'paint',(m,l)=>{
  for(const x of [-.042,.042]){
    m.shell([[.307,.943,.029,.026,x],[.335,.942,.031,.025,x],[.364,.940,.028,.023,x]],16,.62);
    l('ivory',b=>b.shell([[.362,.940,.025,.020,x],[.370,.940,.024,.019,x]],16,.58));
  }
  m.rod(v(-.070,.942,.314),v(.070,.942,.314),.012,12);
},{StemMount:v(0,.942,.302),LightL:v(-.042,.94,.371),LightR:v(.042,.94,.371)});
part('Electrical','RearMarkerAssembly',v(0,.238,-.697),'black',(m,l)=>{
  m.shell([[-.726,.235,.042,.012],[-.699,.239,.058,.014],[-.670,.246,.062,.013]],14,.52);
  l('red',b=>b.shell([[-.733,.235,.044,.008],[-.726,.235,.049,.010]],14,.48));
  l('amber',b=>{for(const x of [-.065,.065]) box(b,x,.241,-.693,.021,.010,.025);});
},{TailLight:v(0,.237,-.733)});

part('Electrical','DualMotorHarness',datums.FoldHinge,'tread',(m,l)=>{
  const rearWire=[rearController,v(.087,.137,.011),v(.092,.134,-.286),v(.078,.155,-.427),add(rear,[.059,0,0])];
  const frontWire=[controller,v(-.077,.144,.284),v(-.073,.205,.365),v(-.072,.230,.500),add(front,[-.059,0,0])];
  const display=[v(-.164,1.165,.261),v(-.069,1.099,.275),v(-.028,.896,.300),
    v(-.033,.555,.355),v(-.051,.360,.410),v(-.070,.245,.368),controller];
  for(const route of [rearWire,frontWire,display]) m.tube(route,route.map(()=>.0041),9);
  l('trim',b=>b.rod(add(controller,[.043,0,0]),add(rearController,[.043,0,0]),.004,9));
},{Controller:controller,RearController:rearController,FrontMotor:add(front,[-.059,0,0]),
  RearMotor:add(rear,[.059,0,0])},'Install both motor leads and controller interconnect');
