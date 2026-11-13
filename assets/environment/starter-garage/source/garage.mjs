import {Mesh,v,sub,unit,mix} from '../../../vehicles/sm50/source/geometry.mjs';

export const materials={
  concrete:['Trowelled grey concrete','#8d8c81',0,.96,'Concrete'],
  joint:['Recessed expansion joints','#55574f',0,.95,'Concrete'],
  plaster:['Weathered lime plaster','#c6ba9e',0,.88,'Plaster'],
  plinth:['Green oil-painted plinth','#4d6561',.02,.65,'SmoothPlastic'],
  brick:['Terracotta block','#9b503b',0,.94,'Brick'],
  roof:['Graphite corrugated steel','#4d4e4b',.45,.62,'Metal'],
  enamel:['Green painted steel','#405c53',.30,.44,'Metal'],
  metal:['Zinc plated steel','#acada0',.75,.32,'Metal'],
  black:['Charcoal steel and molded plastic','#262a28',.30,.67,'Metal'],
  rubber:['Used rubber','#252621',0,.92,'Rubber'],
  timber:['Oiled pine','#967047',0,.78,'Wood'],
  plywood:['End grain and worn timber','#745237',0,.80,'Wood'],
  red:['Oxide red enamel','#94372e',.12,.53,'Metal'],
  blue:['Blue tool-case polymer','#3a5b72',0,.65,'Plastic'],
  yellow:['Mustard equipment paint','#cb9a45',.15,.54,'Metal'],
  ivory:['Opaque light diffuser','#f6f0d7',0,.31,'Neon'],
  plastic:['Cream bottle polymer','#c5bba0',0,.74,'Plastic'],
  paper:['Kraft cardboard','#a68a5f',0,.91,'Plastic'],
  glass:['Dusty window glass','#9ab7ae',0,.31,'Glass',.64],
};
export const components=[];
export const proxies=[];
const X=[1,0,0], Y=[0,1,0];
function part(category,name,pivot,mat,draw,attachments={},interaction='Static scenery'){
  const layers={};
  const layer=(key,draw)=>draw(layers[key]??=new Mesh());
  layer(mat,m=>draw(m,layer));
  components.push({category,name,pivot,attachments,interaction,layers});
}
function box(mesh,p,w,h,d,bevel=.006){
  const [x,y,z]=p, s=-z, a=Math.min(bevel,h*.2,d*.2,w*.2);
  mesh.plate([[y-h/2,s-d/2+a],[y-h/2+a,s-d/2],[y+h/2-a,s-d/2],[y+h/2,s-d/2+a],
    [y+h/2,s+d/2-a],[y+h/2-a,s+d/2],[y-h/2+a,s+d/2],[y-h/2,s+d/2-a]],x,w,a);
}
const rod=(mesh,a,b,r,sides=10)=>mesh.rod(a,b,r,sides);
const turn=(mesh,p,axis,w,r,sides=20)=>mesh.lathe(p,axis,
  [[-w/2,.001],[-w/2,r*.94],[-w*.41,r],[w*.41,r],[w/2,r*.94],[w/2,.001]],sides);
function collision(name,center,size,target){
  proxies.push({name,center,size,target});
}

export const datums={VehicleStand:v(-.55,0,.1),DoorHinge:v(0,2.39,2.90),
  WorkbenchTop:v(-1.91,.93,-1.20),Threshold:v(0,0,2.93),GarageCenter:v(0,0,0)};

part('Structure','ConcreteSlab',v(0,0,0),'concrete',(m,l)=>{
  for(const x of [-1.31,1.31]) for(const z of [-1.46,1.46]){
    box(m,v(x,-.092,z),2.605,.184,2.908,.010);
  }
  l('joint',b=>{
    box(b,v(0,-.075,0),.019,.132,5.82);
    box(b,v(0,-.076,0),5.22,.130,.019);
  });
  l('metal',b=>{
    box(b,v(0,.005,2.885),3.22,.012,.081,.003);
    for(let i=0;i<12;i++) box(b,v(-1.45+i*.26,.012,2.884),.073,.004,.014,.001);
  });
},{Threshold:datums.Threshold,VehicleStand:datums.VehicleStand});
collision('Floor',v(0,-.091,0),[5.22,.182,5.82],'ConcreteSlab');

for(const s of [-1,1]){
  const name=s<0?'LeftWall':'RightWall';
  part('Structure',name,v(s*2.53,0,0),'plaster',(m,l)=>{
    if(s<0) box(m,v(s*2.55,1.29,0),.19,2.58,5.64);
    else {
      for(const [y,h] of [[.655,1.31],[2.337,.486]]) box(m,v(2.55,y,0),.19,h,5.64);
      box(m,v(2.55,1.703,-1.695),.19,.786,2.25);
      box(m,v(2.55,1.703,1.493),.19,.786,2.64);
    }
    l('plinth',b=>box(b,v(s*2.446,.30,0),.022,.60,5.61));
    l('brick',b=>{
      for(let i=0;i<5;i++) for(let j=0;j<6;j++){
        box(b,v(s*2.655,.098+i*.083,-2.70+j*.218+(i%2)*.087),.018,.068,.207,.003);
      }
    });
  },s>0?{Window:v(2.55,1.703,-.20)}:{Workbench:datums.WorkbenchTop});
  if(s<0) collision('LeftWallSolid',v(-2.55,1.29,0),[.19,2.58,5.64],name);
  else for(const [label,y,h,z,d] of [['Lower',.655,1.31,0,5.64],['Upper',2.337,.486,0,5.64],
    ['Back',1.703,.786,-1.695,2.25],['Front',1.703,.786,1.493,2.64]]){
    collision('RightWall'+label,v(2.55,y,z),[.19,h,d],name);
  }
}
part('Structure','BackWall',v(0,0,-2.83),'plaster',(m,l)=>{
  box(m,v(0,1.29,-2.83),4.92,2.58,.185);
  l('plinth',b=>box(b,v(0,.30,-2.727),4.92,.60,.022));
  l('brick',b=>{
    for(let i=0;i<7;i++) for(let j=0;j<8;j++){
      box(b,v(-2.28+j*.217+(i%2)*.09,.11+i*.082,-2.929),.204,.067,.017,.003);
    }
  });
},{Shelf:v(1.60,.60,-2.727)});
collision('BackWallSolid',v(0,1.29,-2.83),[4.92,2.58,.185],'BackWall');
part('Structure','FrontWall',v(0,0,2.83),'plaster',(m,l)=>{
  for(const x of [-2.067,2.067]) box(m,v(x,1.29,2.83),.80,2.58,.185);
  box(m,v(0,2.478,2.83),3.34,.204,.185);
  l('brick',b=>{
    for(const s of [-1,1]) for(let i=0;i<26;i++){
      box(b,v(s*(1.708+.074*(i%2)),.064+i*.088,2.928),.142,.070,.025,.003);
    }
  });
  l('plinth',b=>{for(const x of [-2.074,2.074]) box(b,v(x,.30,2.725),.777,.60,.021);});
},{DoorHinge:datums.DoorHinge});
for(const x of [-2.067,2.067]) collision('FrontPier'+(x<0?'L':'R'),v(x,1.29,2.83),[.80,2.58,.185],'FrontWall');
collision('DoorLintel',v(0,2.478,2.83),[3.34,.204,.185],'FrontWall');

part('Structure','Window',v(2.55,1.70,-.199),'enamel',(m,l)=>{
  for(const z of [-.574,-.199,.175]) box(m,v(2.55,1.70,z),.13,.786,.047);
  for(const y of [1.327,2.074]) box(m,v(2.55,y,-.199),.13,.043,.80);
  l('glass',b=>{for(const z of [-.385,-.012]) box(b,v(2.56,1.70,z),.011,.699,.326,.002);});
  l('metal',b=>box(b,v(2.54,1.305,-.199),.29,.035,.847,.004));
},{Latch:v(2.473,1.65,-.220)},'Window latch');
part('Structure','RoofAssembly',v(0,2.64,0),'roof',(m,l)=>{
  const section=[[-2.76,2.552],[0,2.723],[2.76,2.552],[2.76,2.584],[0,2.755],[-2.76,2.584]];
  m.rings([-3.11,3.11].map(z=>section.map(([x,y])=>[x,y,z])));
  for(let i=0;i<33;i++){
    const x=(i-16)*.167;
    const y=2.752-Math.abs(x)*.062;
    rod(m,v(x,y+.007,-3.086),v(x,y+.007,3.086),.012,6);
  }
  l('timber',b=>{
    for(const z of [-2.53,-1.18,.20,1.56,2.53]) for(const s of [-1,1]){
      b.tube([v(0,2.671,z),v(s*2.62,2.510,z)],[[.048,.058],[.048,.058]],8);
    }
  });
  l('plaster',b=>{
    for(const s of [-1,1]) for(let i=-14;i<=14;i++){
      const x=i*.17, h=.166-Math.abs(x)*.062;
      box(b,v(x,2.578+h/2,s*2.83),.171,h,.183,.002);
    }
  });
},{RoofLift:v(0,2.675,0)},'Hide roof for interior inspection');

const hinge=datums.DoorHinge;
const doorAngle=1.46;
const atDoor=(x,t,offset=0)=>v(x,hinge[1]-t*Math.cos(doorAngle)+offset*Math.sin(doorAngle),
  -hinge[2]+t*Math.sin(doorAngle)+offset*Math.cos(doorAngle));
part('Structure','GarageDoor',hinge,'enamel',(m,l)=>{
  for(let i=0;i<20;i++){
    const x=(i-9.5)*.158;
    m.tube([atDoor(x,.026),atDoor(x,1.13),atDoor(x,2.28)],
      [[.077,.016],[.077,.016],[.077,.016]],8,X);
  }
  l('metal',b=>{
    for(const t of [.053,1.14,2.25]) rod(b,atDoor(-1.583,t,.020),atDoor(1.583,t,.020),.019,8);
    for(const s of [-1,1]) rod(b,atDoor(s*1.579,.045,.010),atDoor(s*1.579,2.25,.010),.019,8);
  });
  l('black',b=>{
    rod(b,atDoor(-.094,2.09,-.055),atDoor(.094,2.09,-.055),.011,12);
    for(const s of [-1,1]) rod(b,atDoor(s*.094,2.09,0),atDoor(s*.094,2.09,-.055),.009);
  });
},{Hinge:hinge,Handle:atDoor(0,2.09,-.055)},'Tilt-up door. Preview is open about +X');
part('Structure','DoorHardware',hinge,'metal',(m,l)=>{
  for(const s of [-1,1]){
    box(m,v(s*1.645,1.178,2.828),.060,2.345,.107);
    rod(m,v(s*1.62,2.372,2.85),atDoor(s*1.60,1.38,.02),.014,10);
    l('black',b=>{for(const t of [0,.07,.14,.21,.28]) rod(b,v(s*1.64,1.79+t,2.74),v(s*1.64,1.83+t,2.74),.019,10);});
  }
},{Hinge:hinge});

part('Lighting','StripLight',v(0,2.468,-.29),'black',(m,l)=>{
  box(m,v(0,2.47,-.29),1.34,.062,.124);
  l('ivory',b=>{for(const z of [-.318,-.266]) rod(b,v(-.596,2.424,z),v(.596,2.424,z),.014,12);});
  l('metal',b=>{for(const x of [-.625,.625]) box(b,v(x,2.431,-.292),.047,.049,.111);});
},{LightSource:v(0,2.405,-.29)},'Attach ceiling light at marker');
part('Lighting','WorkshopWiring',v(-2.40,1.22,2.49),'black',(m,l)=>{
  rod(m,v(-2.421,1.22,2.46),v(-2.421,2.41,2.46),.008,8);
  rod(m,v(-2.421,2.41,2.46),v(-2.421,2.41,-.27),.008,8);
  rod(m,v(-2.421,2.41,-.27),v(-.64,2.46,-.27),.008,8);
  l('plastic',b=>box(b,v(-2.421,1.24,2.46),.064,.082,.069));
},{Switch:v(-2.380,1.24,2.46)});

part('Furniture','Workbench',datums.WorkbenchTop,'enamel',(m,l)=>{
  for(const x of [-2.285,-1.565]) for(const z of [-2.08,-.42]){
    box(m,v(x,.436,z),.058,.85,.058);
    box(m,v(x,.021,z),.085,.035,.085);
  }
  for(const x of [-2.285,-1.565]) for(const y of [.230,.820]) box(m,v(x,y,-1.25),.041,.048,1.70);
  for(const z of [-2.08,-.42]) box(m,v(-1.927,.819,z),.75,.049,.043);
  l('timber',b=>{
    for(const x of [-2.256,-2.035,-1.814,-1.593]) box(b,v(x,.882,-1.25),.220,.096,1.88,.009);
    box(b,v(-1.925,.215,-1.25),.748,.035,1.69);
  });
  l('plywood',b=>box(b,v(-1.49,.884,-1.25),.026,.084,1.86,.005));
},{Surface:datums.WorkbenchTop,Vise:v(-1.58,.933,-1.92),ToolSpot:v(-1.83,.934,-.96)},'Work surface and tool staging');
collision('WorkbenchTop',v(-1.925,.882,-1.25),[.89,.095,1.88],'Workbench');
part('Furniture','ToolBoard',v(-2.397,1.365,-1.26),'plywood',(m,l)=>{
  box(m,v(-2.407,1.38,-1.26),.034,.63,1.79);
  l('black',b=>{
    for(let j=0;j<5;j++) for(let i=0;i<20;i++){
      turn(b,v(-2.387,1.139+j*.118,-2.10+i*.087),X,.0018,.004,6);
    }
  });
  l('metal',b=>{
    for(const z of [-2.09,-1.8,-1.56,-1.29,-1.03,-.78,-.48]){
      rod(b,v(-2.392,1.51,z),v(-2.345,1.51,z),.0045,8);
    }
  });
},{PegRow:v(-2.38,1.51,-1.26)},'Tool storage');
part('Furniture','ShelfUnit',v(1.52,0,-2.38),'enamel',(m,l)=>{
  for(const x of [.90,2.13]) for(const z of [-2.62,-2.09]) box(m,v(x,.924,z),.043,1.84,.043);
  for(const y of [.235,.685,1.135,1.585]){
    for(const z of [-2.62,-2.09]) box(m,v(1.515,y,z),1.27,.055,.038);
    l('plywood',b=>box(b,v(1.515,y+.04,-2.355),1.27,.024,.554));
  }
  l('metal',b=>{
    rod(b,v(.90,.22,-2.64),v(2.13,1.56,-2.64),.014,8);
    rod(b,v(2.13,.22,-2.652),v(.90,1.56,-2.652),.014,8);
  });
},{Lower:v(1.52,.286,-2.35),Middle:v(1.52,.736,-2.35),Upper:v(1.52,1.186,-2.35)},'Parts storage');
part('Furniture','ToolChest',v(1.77,.47,.75),'red',(m,l)=>{
  box(m,v(1.77,.47,.75),.49,.78,.55,.017);
  l('black',b=>{
    box(b,v(1.77,.882,.75),.52,.052,.57);
    for(const x of [1.60,1.94]) for(const z of [.55,.95]) turn(b,v(x,.062,z),X,.032,.049);
  });
  l('metal',b=>{for(const y of [.25,.413,.571,.724]) rod(b,v(1.503,y,.552),v(1.503,y,.944),.011,8);});
  l('joint',b=>{for(const y of [.32,.482,.64,.792]) box(b,v(1.522,y,.752),.012,.011,.504,.002);});
},{DrawerFace:v(1.50,.53,.75),Top:v(1.77,.909,.75)},'Tool drawer storage');

part('Equipment','MotorcycleStand',datums.VehicleStand,'yellow',(m,l)=>{
  for(const s of [-1,1]){
    const x=-.55+s*.217;
    rod(m,v(x,.034,-.180),v(x,.034,.380),.028,8);
    rod(m,v(x,.046,-.125),v(-.55+s*.125,.252,-.035),.024,8);
    rod(m,v(x,.046,.321),v(-.55+s*.125,.252,.235),.024,8);
  }
  box(m,v(-.55,.264,.10),.313,.036,.301);
  l('rubber',b=>{
    box(b,v(-.55,.288,.10),.303,.013,.289);
    for(const z of [-.008,.046,.10,.154,.208]) box(b,v(-.55,.298,z),.281,.005,.016,.001);
  });
},{VehicleSupport:v(-.55,.300,.10),Floor:datums.VehicleStand},'Support motorcycle during servicing');
collision('StandTop',v(-.55,.267,.1),[.313,.055,.301],'MotorcycleStand');
part('Equipment','BenchVise',v(-1.58,.933,-1.92),'blue',(m,l)=>{
  turn(m,v(-1.58,.949,-1.92),Y,.032,.091);
  box(m,v(-1.585,1.019,-1.92),.199,.112,.111,.014);
  for(const x of [-1.655,-1.505]) box(m,v(x,1.102,-1.92),.062,.094,.136,.010);
  l('metal',b=>{
    for(const x of [-1.629,-1.531]) box(b,v(x,1.143,-1.92),.014,.028,.138,.002);
    rod(b,v(-1.495,1.011,-1.92),v(-1.434,1.011,-1.92),.014);
    rod(b,v(-1.444,.959,-1.939),v(-1.444,1.061,-1.902),.007);
  });
},{Base:v(-1.58,.933,-1.92),JawCenter:v(-1.58,1.136,-1.92)},'Bench clamping');

for(const [i,x,y,z] of [[1,1.05,.287,-2.33],[2,1.51,.287,-2.36],[3,1.95,.736,-2.38],[4,1.72,0,-1.72]]){
  const w=i===4?.45:.31, h=i===3?.203:.242;
  part('Storage','PartsBox'+i,v(x,y,z),'paper',(m,l)=>{
    box(m,v(x,y+h/2,z),w,h,.265,.008);
    l('plywood',b=>box(b,v(x,y+h-.013,z),w+.014,.043,.280,.005));
    l('plastic',b=>box(b,v(x,y+h-.055,z+.134),.102,.040,.007,.002));
  },{Grip:v(x,y+h*.65,z+.14)},'Carry parts box');
}
for(const [i,x,y,z] of [[1,.944,.737,-2.35],[2,1.13,.737,-2.35],[3,-2.17,.933,-.55]]){
  const p=v(x,y,z);
  part('Storage','OilBottle'+i,p,i===2?'plastic':'black',(m,l)=>{
    m.shell([[z-.055,y+.080,.041,.065,x],[z-.037,y+.085,.046,.074,x],
      [z+.036,y+.085,.046,.074,x],[z+.053,y+.080,.043,.066,x]],12,.47);
    l(i===1?'red':'yellow',b=>turn(b,v(x-.019,y+.163,z-.022),Y,.025,.025,16));
    l('plastic',b=>box(b,v(x,y+.085,z+.053),.064,.066,.008,.004));
  },{Grip:v(x,y+.107,z),Cap:v(x-.019,y+.178,z-.022)},'Carry oil bottle');
}
for(const [i,x,y,z,r] of [[1,1.87,.299,-1.22,.298],[2,1.59,.292,-1.19,.290]]){
  part('Parts','SpareTire'+i,v(x,y,z),'rubber',m=>{
    m.lathe(v(x,y,z),X,[[-.038,.218],[-.053,.247],[-.045,r-.016],[-.023,r-.005],
      [0,r],[.023,r-.005],[.045,r-.016],[.053,.247],[.038,.218],[0,.219]],48);
  },{Axle:v(x,y,z)},'Carry spare tire');
}

function openWrench(m,p,end,w){
  const d=unit(sub(end,p)), point=(c,t)=>c.map((x,i)=>x+d[i]*t);
  m.tube([p,point(p,.028),point(end,-.025),end],[[w*.18,.0035],[w*.13,.0035],
    [w*.13,.0035],[w*.20,.004]],8,Y);
  const z=[-d[2],0,d[0]];
  const jaw=(t,r)=>point(end,t).map((x,i)=>x+z[i]*r);
  for(const s of [-1,1]) m.tube([jaw(-.009,s*w*.08),jaw(.005,s*w*.41),jaw(.021,s*w*.42)],
    [[w*.16,.004],[w*.13,.004],[w*.11,.004]],8,Y);
  m.lathe(p,Y,[[-.0035,w*.23],[-.0035,w*.44],[.0035,w*.44],[.0035,w*.23]],12);
}
for(const [i,z,w] of [[1,-1.42,.028],[2,-1.34,.033],[3,-1.24,.038]]){
  const p=v(-1.93,.939,z), end=v(-1.75,.939,z+.036);
  part('Tools','CombinationWrench'+i,p,'metal',m=>openWrench(m,p,end,w),
    {Grip:mix(p,end,.53),Fastener:end},'Pick up combination wrench');
}
for(const [name,x,z,mat] of [['FlatScrewdriver',-1.93,-1.01,'red'],['PhillipsScrewdriver',-1.96,-.91,'yellow']]){
  const p=v(x,.954,z), end=v(x+.188,.951,z+.021);
  part('Tools',name,p,mat,(m,l)=>{
    m.tube([p,mix(p,end,.10),mix(p,end,.34),mix(p,end,.43)],[.012,.014,.012,.008],10);
    l('metal',b=>rod(b,mix(p,end,.37),end,.0038));
  },{Grip:mix(p,end,.19),Tip:end},'Pick up screwdriver');
}
part('Tools','TorqueWrench',v(-2.09,.950,-.78),'metal',(m,l)=>{
  rod(m,v(-2.09,.948,-.78),v(-1.66,.948,-.67),.008,12);
  turn(m,v(-1.66,.950,-.67),Y,.015,.019);
  l('black',b=>rod(b,v(-2.093,.948,-.779),v(-1.951,.948,-.742),.014,12));
},{Grip:v(-2.032,.948,-.763),Socket:v(-1.66,.950,-.67)},'Pick up torque wrench');
part('Tools','Pliers',v(-1.89,.948,-.58),'red',(m,l)=>{
  for(const s of [-1,1]){
    m.tube([v(-1.985,.948,-.580+s*.029),v(-1.930,.947,-.580+s*.020),v(-1.872,.946,-.580+s*.005)],
      [.009,.009,.006],9);
    l('metal',b=>b.tube([v(-1.899,.947,-.580+s*.013),v(-1.865,.947,-.580+s*.011),
      v(-1.828,.947,-.580+s*.004)],[[.008,.005],[.010,.005],[.004,.004]],8,Y));
  }
},{Grip:v(-1.936,.948,-.58),Jaw:v(-1.827,.947,-.58)},'Pick up pliers');
part('Tools','SocketTray',v(-2.13,.932,-1.66),'blue',m=>box(m,v(-2.13,.950,-1.66),.23,.037,.124),
  {Tray:v(-2.13,.971,-1.66)},'Carry tray');
for(let i=0;i<6;i++){
  const p=v(-2.218+.034*i,.984,-1.655), r=.009+.0011*i;
  part('Tools','Socket'+(8+i*2),p,'metal',m=>{
    m.lathe(p,Y,[[-.013,r*.46],[-.013,r],[-.008,r+.001],[.013,r],[.013,r*.58],[-.006,r*.58]],18);
  },{Drive:p},'Pick up individual socket');
}
part('Tools','SparkPlugWrench',v(-1.82,.951,-1.10),'metal',m=>{
  m.lathe(v(-1.82,.951,-1.10),X,[[-.049,.008],[-.049,.012],[.049,.012],[.049,.009]],12);
  rod(m,v(-1.857,.953,-1.151),v(-1.857,.953,-1.051),.0039,8);
},{Grip:v(-1.857,.953,-1.10),Socket:v(-1.771,.951,-1.10)},'Pick up spark plug wrench');
part('Tools','TireLever',v(-2.07,.951,-2.04),'metal',m=>{
  m.tube([v(-2.286,.946,-2.05),v(-2.23,.950,-2.05),v(-1.944,.951,-2.034),v(-1.907,.965,-2.028)],
    [[.009,.003],[.009,.004],[.008,.004],[.011,.003]],10,Y);
},{Grip:v(-2.092,.951,-2.04),Spoon:v(-1.907,.965,-2.028)},'Pick up tire lever');
part('Equipment','EngineStand',v(.24,0,-1.98),'red',(m,l)=>{
  for(const x of [-.02,.50]) rod(m,v(x,.049,-2.24),v(x,.049,-1.75),.026,8);
  for(const z of [-2.23,-1.76]) rod(m,v(-.04,.052,z),v(.52,.052,z),.025,8);
  rod(m,v(.24,.063,-2.20),v(.24,.670,-2.20),.043,8);
  l('metal',b=>{
    rod(b,v(.24,.626,-2.205),v(.24,.626,-1.973),.024,14);
    for(const s of [-1,1]) rod(b,v(.24,.626,-1.990),v(.24+s*.124,.573,-1.937),.014,8);
  });
},{EngineAxis:v(.24,.626,-1.975),Floor:v(.24,0,-1.98)},'Support loose engine');
part('Parts','LooseCylinder',v(1.47,1.186,-2.26),'metal',m=>{
  const p=v(1.47,1.245,-2.26);
  m.lathe(p,Y,[[-.058,.022],[-.058,.046],[.057,.043],[.057,.022]],32);
  for(let i=0;i<5;i++) m.lathe(v(1.47,1.207+i*.021,-2.26),Y,
    [[-.003,.039],[-.003,.057],[.003,.057],[.003,.039]],28);
},{Bore:v(1.47,1.245,-2.26)},'Carry spare cylinder');
part('Parts','LoosePiston',v(1.68,1.188,-2.25),'metal',m=>{
  m.lathe(v(1.68,1.209,-2.25),Y,[[-.021,.016],[-.021,.021],[.009,.021],[.010,.019],
    [.012,.021],[.021,.020],[.022,.002],[.018,.002],[.015,.016]],32);
},{WristPin:v(1.68,1.197,-2.25)},'Carry spare piston');
