import * as stock from './catalog.mjs';
import {components as detailed} from './motorcycle.mjs';
import {Mesh,add,sub,mul,v,tau} from './geometry.mjs';

export const materials={...stock.materials,
  body:['Electric blue plastics','#1359cf',.02,.37,'SmoothPlastic'],
  trim:['Cold white graphics','#e5eaf3',.02,.42,'SmoothPlastic'],
  accent:['Ice blue graphics','#52baf5',.05,.4,'SmoothPlastic'],
};
export const proxies=[];
export const components=[];
const existing=new Map(stock.components.map(p=>[p.name,p]));
const originals=new Map(detailed.map(p=>[p.name,p]));
const front=[0,-.25,-.70],rear=[0,-.25,.665];
const bodyShift=p=>[p[0],p[1]-.55,-.014+p[2]];
export const datums={...stock.datums,Mount_FrontWheel:front,Mount_RearWheel:rear};

function append(target, mesh, map, material) {
  const base=target.vertices.length, face=target.triangles.length;
  target.vertices.push(...mesh.vertices.map(map));
  target.triangles.push(...mesh.triangles.map(t=>t.map(i=>i+base)));
  target.solids.push(...mesh.solids.map(s=>({
    startVertex:s.startVertex+base,endVertex:s.endVertex+base,
    startFace:s.startFace+face,endFace:s.endFace+face,
  })));
  target.colors.push(...mesh.vertices.map((_,i)=>material ?? mesh.colors[i]));
}
function piece(id,slot,pivot,markers={}) {
  const mesh=new Mesh();
  mesh.colors=[];
  components.push({name:id==='Frame'?id:'Part_sd_'+id,category:id==='Frame'?'Vehicles':'Parts',
    pivot,attachments:markers,layers:{vertex:mesh},interaction:'Install at Mount_'+slot});
  datums['Mount_'+slot]=pivot;
  return mesh;
}
function shape(target,key,draw) {
  const mesh=new Mesh();
  draw(mesh);
  append(target,mesh,p=>p,key);
}
function copy(id,slot,source,offset=[0,0,0],paint) {
  const part=existing.get('Part_'+source);
  const map=p=>add(p,offset);
  const mesh=piece(id,slot,map(part.pivot),Object.fromEntries(Object.entries(part.attachments).map(([k,p])=>[k,map(p)])));
  append(mesh,part.layers.vertex,map,paint);
}
function separate(id,slot,sources,map=bodyShift) {
  const pivot=bodyShift(originals.get(sources[0]).pivot);
  const mesh=piece(id,slot,pivot,{Bolt_1:pivot});
  for(const name of sources) for(const [key,layer] of Object.entries(originals.get(name).layers)) {
    append(mesh,layer,map,key);
  }
}
function panel(id,slot,x,profile,key='body') {
  const pivot=v(x,profile[0][0],profile[0][1]);
  const mesh=piece(id,slot,pivot,{Bolt_1:pivot});
  shape(mesh,key,m=>m.plate(profile,x,.017,.004));
  const side=Math.sign(x)||1;
  const center=mul(profile.reduce(add),1/profile.length);
  for(const [color,k,dx] of [['trim',.69,.010],['accent',.41,.013]]) {
    const stripe=profile.map((p,i)=>add(center,mul(sub(p,center),i===2?k*.55:k)));
    shape(mesh,color,m=>m.plate(stripe,x+side*dx,.004,.001));
  }
  return mesh;
}

const frame=piece('Frame','Frame',[0,0,0]);
append(frame,existing.get('Frame').layers.vertex,p=>p);
shape(frame,'anodized',m=>{
  for(const x of [-.117,.117]) {
    m.plate([[.264,.34],[.211,.40],[.094,.22],[-.054,-.12],[-.103,-.25],[.017,-.20],[.154,.08]],x,.046,.009);
  }
});

function wheel(id,slot,axle,radius,width) {
  const mesh=piece(id,slot,axle,{Bolt_1:axle});
  const axis=[1,0,0], rim=.2159, half=width/2;
  shape(mesh,'rubber',m=>m.lathe(axle,axis,[
    [-half*.76,rim],[-half,radius*.91],[-half*.80,radius*.975],[-half*.41,radius],
    [half*.41,radius],[half*.80,radius*.975],[half,radius*.91],[half*.76,rim],
  ],72));
  shape(mesh,'anodized',m=>{
    m.lathe(axle,axis,[[-half*.78,rim-.018],[-half*.78,rim+.009],[half*.78,rim+.009],[half*.78,rim-.018]],64);
    m.lathe(axle,axis,[[-half,.012],[-half,.047],[half,.047],[half,.012]],32);
    const at=(angle,r,x)=>add(axle,[x,r*Math.cos(angle),r*Math.sin(angle)]);
    for(let i=0;i<10;i++){
      const a=i*tau/10;
      m.tube([at(a,.041,0),at(a+.045,.119,0),at(a+.14,.206,0)],[[.014,.021],[.012,.016],[.008,.011]],8);
    }
  });
  shape(mesh,'accent',m=>{
    for(const s of [-1,1]){
      const x=half*.79*s;
      m.lathe(axle,axis,[[x-.001,rim],[x-.001,rim+.005],[x+.001,rim+.005],[x+.001,rim]],64);
    }
  });
}
wheel('wheel_front_17','FrontWheel',front,.296,.100);
wheel('wheel_rear_17','RearWheel',rear,.307,.130);
copy('brake_front_std','FrontBrake','brake_front_std');
copy('brake_rear_std','RearBrake','brake_rear_std',[0,0,.015]);
copy('handlebar_std','Handlebar','handlebar_std');
const axleDelta=sub(front,bodyShift(originals.get('FrontTire').pivot));
const forkFit=p=>add(bodyShift(p),mul(axleDelta,Math.min(1,Math.max(0,(.81-p[1])/.51))));
separate('fork_std','FrontFork',['SteeringAssembly','ForkUpper_L','ForkUpper_R','ForkLower_L','ForkLower_R'],forkFit);
copy('swingarm_std','Swingarm','swingarm_std');
copy('shock_std','RearShock','shock_std');
const seat=piece('seat_std','Seat',v(0,.27,-.26),{Bolt_1:v(0,.27,-.26)});
shape(seat,'seat',m=>m.shell([
  [-.69,.292,.061,.024],[-.52,.271,.099,.034],[-.29,.230,.093,.032],[-.07,.247,.076,.030],[.11,.293,.049,.022],
],16));
const frontFender=piece('front_fender','FrontFender',v(0,.29,.50),{Bolt_1:v(0,.29,.50)});
shape(frontFender,'body',m=>m.shell([[.35,.265,.048,.014],[.52,.291,.089,.022],[.69,.285,.079,.017],[.88,.251,.051,.010],[1.00,.214,.022,.006]],12));
shape(frontFender,'trim',m=>m.shell([[.55,.313,.024,.004],[.74,.298,.025,.004],[.91,.252,.009,.003]],10));
const mask=piece('headlight_mask','HeadlightMask',v(0,.43,.56),{Bolt_1:v(0,.43,.56)});
shape(mask,'body',m=>m.shell([[.48,.437,.076,.119],[.54,.435,.086,.125],[.59,.413,.077,.092]],14));
shape(mask,'trim',m=>m.shell([[.58,.397,.057,.060],[.615,.390,.045,.058],[.63,.386,.034,.048]],12));
shape(mask,'anodized',m=>m.shell([[.56,.512,.058,.038],[.597,.493,.052,.025]],12));
for(const [side,x] of [['l',-.122],['r',.122]]){
  panel('side_panel_'+side,side==='l'?'SidePanelL':'SidePanelR',x,[[.261,-.67],[.252,-.37],[.211,-.28],[.114,-.40],[.153,-.61]]);
}
separate('tail_plate','TailPlate',['RearFender','TailLight','NumberPlate']);
const tank=piece('tank_std','FuelTank',v(0,.253,.17),{Bolt_1:v(0,.253,.17)});
shape(tank,'anodized',m=>m.shell([[.03,.245,.058,.041],[.15,.251,.096,.058],[.29,.233,.097,.071],[.39,.208,.055,.049]],16));
for(const x of [-.108,.108]){
  const p=[[.268,.11],[.279,.31],[.186,.435],[.092,.301],[.123,.203]];
  shape(tank,'body',m=>m.plate(p,x,.020,.005));
  shape(tank,'trim',m=>m.plate([[.256,.16],[.257,.29],[.190,.38],[.143,.31],[.174,.24]],x+Math.sign(x)*.012,.005,.001));
  shape(tank,'accent',m=>m.plate([[.218,.25],[.207,.36],[.153,.31],[.163,.27]],x+Math.sign(x)*.015,.004,.001));
}
for(const [id,slot,source] of [
  ['fuel_line','FuelLine','fuel_line'],['piston','Piston','piston_40'],
  ['cylinder','Cylinder','cylinder_50'],['head','CylinderHead','head_std'],['plug','SparkPlug','plug_std'],
  ['clutch','Clutch','clutch_std'],['cdi','Ignition','cdi_restricted'],['carb','Carburetor','carb_17'],
  ['airbox','AirFilter','filter_std'],['exhaust','Exhaust','exhaust_std'],['front_sprocket_11','FrontSprocket','sprocket_f_11'],
  ['rear_sprocket_53','RearSprocket','sprocket_r_53'],['chain_420','Chain','chain_420'],
]){
  copy(id,slot,source,id==='rear_sprocket_53'?[0,0,.015]:[0,0,0],id==='exhaust'?'anodized':undefined);
}
const block=piece('block','EngineBlock',existing.get('Part_block_am6').pivot,existing.get('Part_block_am6').attachments);
for(const name of ['Crankcase_L','Crankcase_R','GearboxHousing','Crankshaft','ConnectingRod','GearboxInputShaft','GearboxOutputShaft']){
  for(const [key,mesh] of Object.entries(originals.get(name).layers)) append(block,mesh,bodyShift,key);
}
separate('radiator','Radiator',['Radiator_L','Radiator_R']);
separate('coolant_hoses','CoolantHoses',['CoolantHoses']);
separate('kickstarter','Kickstarter',['Kickstarter']);
separate('gear_lever','GearLever',['GearShifter']);
const flywheel=piece('flywheel_stator','FlywheelStator',v(-.112,-.148,.028),{Bolt_1:v(-.112,-.148,.028)});
shape(flywheel,'alloy',m=>m.lathe(v(-.112,-.148,.028),[1,0,0],[[-.019,.017],[-.019,.058],[.017,.058],[.017,.017]],40));
shape(flywheel,'gold',m=>m.lathe(v(-.094,-.148,.028),[1,0,0],[[-.007,.021],[-.007,.044],[.007,.044],[.007,.021]],32));
const coil=piece('ignition_coil','IgnitionCoil',v(.075,.174,.25),{Bolt_1:v(.075,.174,.25)});
shape(coil,'anodized',m=>m.shell([[.203,.174,.022,.023,.075],[.275,.174,.022,.023,.075]],12));
shape(coil,'rubber',m=>m.tube([v(.075,.174,.203),v(.088,.139,.175),datums.Mount_SparkPlug],[.005,.005,.005],8));
const oilTank=piece('oil_tank','OilTank',v(.075,.138,-.37),{Bolt_1:v(.075,.138,-.37)});
shape(oilTank,'trim',m=>m.shell([[-.47,.134,.031,.045,.075],[-.37,.136,.039,.062,.075],[-.27,.123,.027,.044,.075]],12));
shape(oilTank,'anodized',m=>m.rod(v(.074,.190,-.37),v(.074,.208,-.37),.023,12));
const pump=piece('oil_pump','OilPump',v(.112,-.102,.075),{Bolt_1:v(.112,-.102,.075)});
shape(pump,'alloy',m=>m.rod(v(.102,-.102,.075),v(.137,-.102,.075),.026,16));
const line=piece('oil_line','OilLine',v(.092,.087,-.36),{Bolt_1:v(.092,.087,-.36)});
shape(line,'rubber',m=>m.tube([v(.092,.087,-.36),v(.119,.039,-.25),v(.129,-.083,-.08),v(.137,-.102,.075)],[.004,.004,.004,.004],8));

for(const [name,point] of Object.entries(datums)) if(name.startsWith('Mount_') && name!=='Mount_Frame'){
  components[0].attachments[name]=point;
}
delete datums.Mount_Frame;
if(components.length!==39) throw Error('Senda must contain its frame and 38 removable parts');
