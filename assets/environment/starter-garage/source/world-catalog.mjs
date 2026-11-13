import {Mesh,v,add,sub} from '../../../vehicles/sm50/source/geometry.mjs';
import {components as garage,materials as garageMaterials} from './garage.mjs';

export const materials={...garageMaterials,vertex:['Catalog vertex colours','#ffffff',.14,.64,'SmoothPlastic']};
export const components=[];
export const datums={};
export const proxies=[];
const byName=new Map(garage.map(p=>[p.name,p]));
function merge(target,source,key,map=p=>p){
  for(const s of source.solids){
    const startVertex=target.vertices.length,startFace=target.triangles.length;
    for(const p of source.vertices.slice(s.startVertex,s.endVertex)){
      target.vertices.push(map(p));target.colors.push(key);
    }
    for(const face of source.triangles.slice(s.startFace,s.endFace)){
      target.triangles.push(face.map(i=>i-s.startVertex+startVertex));
    }
    target.solids.push({startVertex,startFace,endVertex:target.vertices.length,endFace:target.triangles.length});
  }
}
function entry(name,pivot,attachments={},interaction='Place as world scenery'){
  const mesh=new Mesh();
  mesh.colors=[];
  components.push({category:'World',name,pivot,layers:{vertex:mesh},attachments,interaction});
  return mesh;
}
function source(target,name,map,selected=()=>true){
  for(const [key,mesh] of Object.entries(byName.get(name).layers)) if(selected(key)) merge(target,mesh,key,map);
}
function create(target,key,draw){
  const mesh=new Mesh();
  draw(mesh);
  merge(target,mesh,key);
}
function box(m,x,y,z,w,h,d,bevel=.004){
  const a=Math.min(bevel,w*.19,h*.19,d*.19);
  m.plate([[y-h/2,z-d/2+a],[y-h/2+a,z-d/2],[y+h/2-a,z-d/2],[y+h/2,z-d/2+a],
    [y+h/2,z+d/2-a],[y+h/2-a,z+d/2],[y-h/2+a,z+d/2],[y-h/2,z+d/2-a]],x,w,a);
}
const garageMap=([x,y,z])=>[-x*1.71,y,-z*1.33];
const bay=entry('Garage_Bay',[0,0,0],{Entry:[0,0,3.75],Workbench:[0,.90,-3.19],Stand:[0,.30,0]});
for(const name of ['ConcreteSlab','LeftWall','RightWall','BackWall','FrontWall','Window','RoofAssembly','StripLight','ShelfUnit','MotorcycleStand']){
  const map=name==='MotorcycleStand'?p=>sub(p,byName.get(name).pivot):garageMap;
  source(bay,name,map,key=>key!=='brick');
}
const bench=([x,y,z])=>[-(z-1.25)*(4.50/1.88),y*.968,-3.19+(x+1.925)];
source(bay,'Workbench',bench);
create(bay,'brick',m=>{
  for(let i=0;i<15;i++) for(const s of [-1,1]){
    box(m,s*(2.90+(i%2)*.072),.071+i*.151,3.89,.158,.108,.016,.002);
  }
});
const tools={
  Tool_spanner_set:['CombinationWrench1','CombinationWrench2','CombinationWrench3'],
  Tool_socket_set:['SocketTray','Socket8','Socket10','Socket12','Socket14','Socket16','Socket18'],
  Tool_screwdriver:['FlatScrewdriver'],Tool_pliers:['Pliers'],Tool_plug_wrench:['SparkPlugWrench'],
};
for(const [i,[name,names]] of Object.entries(tools).entries()){
  const pivot=v(5+i*.40,.95,0);
  const m=entry(name,pivot,{Grip:pivot},'Pick up workshop tool');
  const reference=byName.get(names[0]).pivot;
  for(const sourceName of names) source(m,sourceName,p=>add(pivot,sub(p,reference)));
}
const canP=v(5,0,-1.1),can=entry('Prop_fuel_can',canP,{Grip:v(5,.31,-1.1),Spout:v(5.072,.284,-1.139)},'Carry fuel can');
create(can,'red',m=>{
  m.shell([[-1.177,.136,.093,.108,5],[-1.147,.139,.104,.132,5],[-1.052,.139,.104,.132,5],
    [-1.025,.138,.092,.109,5]],14,.4);
  m.tube([v(4.945,.260,-1.107),v(4.945,.309,-1.108),v(4.966,.327,-1.106),
    v(5.052,.327,-1.102),v(5.061,.263,-1.102)],[.012,.014,.014,.014,.012],10);
});
create(can,'black',m=>m.rod(v(5.073,.269,-1.14),v(5.077,.294,-1.144),.021,16));
const kioskP=v(8.1,0,-1.8),kiosk=entry('Prop_parts_counter',kioskP,{Counter:v(8.1,1.04,-1.35)});
create(kiosk,'plaster',m=>{
  box(m,8.1,.98,-2.30,2.24,1.96,.141);
  for(const x of [7.04,9.16]) box(m,x,1.00,-1.79,.137,2,.95);
  box(m,8.1,.483,-1.31,2.17,.93,.134);
});
create(kiosk,'timber',m=>{
  box(m,8.1,.987,-1.303,2.31,.111,.43);
  for(const y of [.59,1.41]) box(m,8.1,y,-2.12,1.98,.038,.37);
});
create(kiosk,'roof',m=>{
  box(m,8.1,2.11,-1.76,2.58,.14,1.43);
  for(let i=0;i<11;i++) m.rod(v(6.9+i*.24,2.177,-2.45),v(6.9+i*.24,2.177,-1.08),.016,6);
});
const pumpP=v(5.9,0,-2.5),pump=entry('Prop_fuel_pump',pumpP,{Nozzle:v(6.16,1.06,-2.60)});
create(pump,'red',m=>{
  box(m,5.90,.665,-2.50,.482,1.278,.357,.026);
  box(m,5.90,1.357,-2.50,.516,.161,.375,.031);
});
create(pump,'plastic',m=>{
  box(m,5.9,1.124,-2.301,.397,.351,.033,.012);
  box(m,5.9,.510,-2.316,.383,.498,.019,.012);
});
create(pump,'black',m=>{
  box(m,5.90,1.177,-2.280,.255,.104,.014);
  m.tube([v(6.14,.583,-2.60),v(6.285,.355,-2.61),v(6.407,.380,-2.64),
    v(6.405,.685,-2.65),v(6.212,1.05,-2.62)],[.015,.015,.014,.014,.012],10);
});
create(pump,'metal',m=>m.rod(v(6.212,1.049,-2.62),v(6.148,1.139,-2.601),.011,12));
