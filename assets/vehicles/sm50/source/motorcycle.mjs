import {Mesh, v, tau, mix, add, sub, mul, unit} from './geometry.mjs';

const distance = process.argv.includes('--distance');
const serviceParts = new Set(['Piston','Crankshaft','ConnectingRod','ClutchBasket','ClutchPlateStack',
  'ClutchPressurePlate','GearboxInputShaft','GearboxOutputShaft','AirFilter']);

export const materials = {
  frame: ['Graphite painted steel', '#363b40', .55, .34, 'Metal'],
  body: ['Petrol blue injection-moulded plastic', '#067e89', .02, .36, 'SmoothPlastic'],
  trim: ['Warm ivory plastic', '#f1e7ca', .02, .38, 'SmoothPlastic'],
  black: ['Textured black nylon', '#20262a', 0, .73, 'Plastic'],
  seat: ['Grained black vinyl', '#272a2a', 0, .81, 'Fabric'],
  rubber: ['Road tire rubber', '#27292a', 0, .94, 'Rubber'],
  tread: ['Recessed tread rubber', '#131718', 0, .98, 'Rubber'],
  alloy: ['Machined aluminium', '#b7c0c4', .8, .28, 'Metal'],
  cast: ['Cast aluminium', '#888b84', .67, .65, 'Metal'],
  rotor: ['Brushed brake steel', '#a9aead', .8, .46, 'Metal'],
  chrome: ['Hard chromed fork tube', '#c7d7df', .95, .17, 'Metal'],
  anodized: ['Black anodized aluminium', '#383b3c', .69, .38, 'Metal'],
  spring: ['Mustard yellow powder coat', '#e2ad42', .26, .34, 'Metal'],
  pipe: ['Heat stained stainless steel', '#896f55', .76, .43, 'Metal'],
  weld: ['Stainless weld bead', '#b09979', .72, .56, 'Metal'],
  grease: ['Greased drive steel', '#4e4940', .63, .65, 'Metal'],
  dirty: ['Dusty unpainted polymer', '#4a4740', 0, .89, 'Plastic'],
  glass: ['Clear polycarbonate', '#dce8dd', 0, .12, 'Glass', .63],
  reflector: ['Headlamp reflector', '#e3e7d6', .38, .24, 'Metal'],
  red: ['Red tail lamp lens', '#a61a21', .06, .19, 'SmoothPlastic'],
  amber: ['Amber reflector', '#ce6020', .05, .24, 'SmoothPlastic'],
};

export const components = [];
const X = [1,0,0], Y = [0,1,0];
const rear = v(0,.299,-.664), front = v(0,.301,.664);
const swing = v(0,.448,-.204), stem = v(0,.876,.384);
const crank = v(0,.375,.049), output = v(-.109,.402,-.174);
const cylinder = v(0,.489,.073), bore = unit(v(0,1,.23));
const upperShock = v(0,.726,-.272), lowerShock = v(0,.429,-.432);
const bar = v(0,1.006,.334);

function part(category, name, pivot, material, draw, attachments = {}, interaction = 'Remove / install') {
  if(distance && serviceParts.has(name)) return;
  const component = {category, name, pivot, attachments, interaction, layers: {}};
  components.push(component);
  const layer = (key, build) => {
    const mesh = component.layers[key] ??= new Mesh();
    build(mesh);
  };
  layer(material, mesh => draw(mesh, layer));
}
const segment = (m,a,b,r,n) => m.rod(a,b,r,n);
const near = (p, x) => add(p,[x,0,0]);
const profile = (m,p,a,w,r,h=.003,n=32) =>
  m.lathe(p,a,[[-w/2,.001],[-w/2,r-h],[-w/2+h,r],[w/2-h,r],[w/2,r-h],[w/2,.001]],n);
const bolt = (m,p,a,r=.006,w=.006) => profile(m,p,a,w,r,Math.min(.001,w/4),6);
const polar = (p,x,r,a) => add(p,[x,r*Math.cos(a),r*Math.sin(a)]);
const shell = (m, rows, sides=12, power=.5) => m.shell(rows,sides,power);

part('Chassis','MainFrame',v(0,.47,0),'frame',(m,l)=>{
  m.tube([v(0,.925,.363),v(0,.895,.225),v(0,.813,-.029),v(0,.737,-.241)],
    [[.028,.043],[.032,.042],[.031,.038],[.027,.030]],16);
  m.tube([v(0,.804,.409),v(0,.700,.355),v(0,.513,.267),v(0,.348,.233)],
    [.028,.031,.030,.028],14);
  m.tube([v(0,.786,.424),v(0,.935,.353)],[.040,.040],20);
  for (const s of [-1,1]) {
    const x=.102*s;
    m.tube([v(0,.368,.239),v(x*.68,.306,.210),v(x,.283,.125),v(x,.284,-.122),
      v(x,.352,-.202),v(x,.469,-.206),v(x*.75,.646,-.253),v(0,.742,-.242)],
      [.021,.022,.021,.020,.022,.026,.024,.026],12);
    m.plate([[.392,-.274],[.367,-.206],[.390,-.130],[.500,-.142],[.533,-.214],[.483,-.276]],
      x,.024,.004);
    m.plate([[.766,.342],[.804,.424],[.903,.365],[.849,.235]],x*.22,.022,.004);
  }
  for (const [y,s] of [[.315,.197],[.309,-.129],[.448,-.204],[.718,-.269]]) {
    segment(m,v(-.107,y,s),v(.107,y,s),.015);
  }
  l('alloy',b=>{
    for (const s of [-1,1]) for(const [y,z] of [[.448,-.204],[.336,-.115],[.354,.201],[.723,-.272]]) {
      bolt(b,v(s*.119,y,z),X,.010,.009);
    }
  });
},{SteeringAxis:stem,SwingarmAxis:swing,EngineFront:v(0,.354,.201),EngineRear:v(0,.336,-.115),
   ShockUpper:upperShock,SubframeFront:v(0,.740,-.238),TankMount:v(0,.871,.165)});

part('Chassis','Subframe',v(0,.74,-.238),'frame',(m,l)=>{
  for(const s of [-1,1]) {
    m.tube([v(s*.084,.749,-.232),v(s*.082,.805,-.422),v(s*.073,.830,-.653),
      v(s*.056,.835,-.798)],[.014,.014,.013,.012]);
    m.tube([v(s*.080,.560,-.238),v(s*.090,.619,-.358),v(s*.083,.739,-.549),
      v(s*.068,.825,-.673)],[.014,.014,.013,.012]);
  }
  for(const [y,s,w] of [[.749,-.235,.085],[.817,-.494,.080],[.835,-.754,.066]]) {
    segment(m,v(-w,y,s),v(w,y,s),.012);
  }
  l('alloy',b=>{for(const s of [-1,1]) bolt(b,v(s*.100,.748,-.248),X,.007);});
},{SeatCatch:v(0,.838,-.573),TailLamp:v(0,.829,-.831),AirboxMount:v(0,.694,-.371)});

part('Chassis','Swingarm',swing,'alloy',(m,l)=>{
  for(const s of [-1,1]) {
    m.tube([v(s*.104,.449,-.192),v(s*.139,.413,-.310),v(s*.137,.363,-.484),
      v(s*.134,.300,-.681),v(s*.134,.297,-.711)],
      [[.023,.043],[.025,.036],[.022,.027],[.020,.023],[.015,.017]],12,[0,1,0]);
    m.plate([[.272,-.701],[.275,-.629],[.318,-.622],[.332,-.671],[.317,-.717]],s*.134,.041,.006);
  }
  segment(m,v(-.128,.417,-.360),v(.128,.417,-.360),.027);
  l('frame',b=>{for (const x of [-.019,.019]) segment(b,v(x,.410,-.369),v(x,.435,-.443),.013);});
  l('anodized',b=>{for (const s of [-1,1]) b.plate([[.286,-.693],[.286,-.637],[.313,-.637],[.313,-.693]],s*.157,.009);});
},{Pivot:swing,RearAxle:rear,ShockLower:lowerShock,ChainGuide:v(-.109,.232,-.532)},'Pivot about +X');

part('Chassis','SteeringAssembly',stem,'anodized',(m,l)=>{
  for (const [y,s] of [[.784,.461],[.961,.382]]) {
    m.shell([[s-.035,y,.102,.014],[s-.011,y,.126,.019],[s+.018,y,.125,.018],
      [s+.041,y,.096,.013]],12,.68);
    for(const x of [-.102,.102]) profile(m,v(x,y,s),Y,.036,.035,.003,24);
  }
  l('alloy',b=>{
    segment(b,v(0,.756,.444),v(0,.977,.361),.020);
    bolt(b,v(0,.984,.377),Y,.018,.010);
    for(const x of [-.121,.121]) for(const y of [.789,.963]) bolt(b,v(x,y,y>.9?.385:.466),X);
  });
},{SteeringUpper:v(0,.935,.353),SteeringLower:v(0,.786,.424),ForkTopL:v(-.102,.961,.382),
   ForkTopR:v(.102,.961,.382),HandlebarClamp:bar},'Rotate about the SteeringLower-to-SteeringUpper axis');

for(const [side,x] of [['L',-.102],['R',.102]]) {
  const top=v(x,.984,.371), axle=near(front,x);
  const p=t=>mix(top,axle,t);
  part('Suspension','ForkUpper_'+side,top,'anodized',(m,l)=>{
    m.tube([p(0),p(.02),p(.17),p(.52),p(.56)],[.027,.032,.030,.027,.028],24);
    l('alloy',b=>profile(b,top,unit(sub(top,axle)),.012,.026,.003,20));
    l('black',b=>segment(b,p(.55),p(.577),.027,20));
  },{ForkTop:top,SliderAxis:p(.56)},'Steers with triple clamps');
  part('Suspension','ForkLower_'+side,axle,'chrome',(m,l)=>{
    segment(m,p(.48),p(.963),.021,24);
    l('cast',b=>{
      b.tube([p(.79),p(.85),p(.967),p(.995)],[.024,.026,.028,.025],18);
      profile(b,axle,X,.035,.033,.004,24);
      if (side==='R') segment(b,v(.096,.390,.623),v(.085,.411,.591),.013);
    });
    l('body',b=>b.plate([[.337,.663],[.365,.698],[.532,.641],[.548,.610],[.510,.584],[.361,.644]],x,.060,.009));
  },{FrontAxle:axle,ForkSlider:p(.62)},'Translate along fork axis');
}

part('Suspension','ShockBody',upperShock,'anodized',(m,l)=>{
  const p=t=>mix(upperShock,lowerShock,t);
  m.tube([p(.04),p(.18),p(.25),p(.53),p(.56)],[.013,.018,.030,.028,.021],20);
  profile(m,upperShock,X,.038,.018,.003,20);
  l('alloy',b=>{
    segment(b,p(.23),p(.28),.037,24);
    segment(b,v(.041,.676,-.318),v(.041,.608,-.357),.020,20);
    segment(b,p(.25),v(.041,.676,-.318),.011);
  });
},{ShockUpper:upperShock,SpringSeat:mix(upperShock,lowerShock,.25)},'Pivot at upper shock eye');
part('Suspension','ShockShaft',lowerShock,'chrome',(m,l)=>{
  segment(m,mix(upperShock,lowerShock,.49),lowerShock,.010,16);
  l('cast',b=>profile(b,lowerShock,X,.036,.016,.003,20));
  l('alloy',b=>segment(b,mix(upperShock,lowerShock,.77),mix(upperShock,lowerShock,.81),.035,24));
},{ShockLower:lowerShock,SpringSeat:mix(upperShock,lowerShock,.79)},'Translate along shock axis');
part('Suspension','ShockSpring',upperShock,'spring',m=>{
  const centers=Array.from({length:117},(_,i)=>{
    const t=i/116,a=t*6.5*tau;
    return add(mix(upperShock,lowerShock,.28+.49*t),[.029*Math.cos(a),.014*Math.sin(a),-.025*Math.sin(a)]);
  });
  m.tube(centers,centers.map(()=>.0046),8);
},{SpringUpper:mix(upperShock,lowerShock,.28),SpringLower:mix(upperShock,lowerShock,.77)},'Compress along shock axis');

for(const [label,p,w,r] of [['Front',front,.105,.301],['Rear',rear,.132,.299]]) {
  const axle = {Axle:p};
  const rim = .226;
  const brakeX = label==='Front'?.083:.103;
  const disc = label==='Front'?.139:.106;
  const ring = (m,profile,sides=72) => m.lathe(p,X,profile,distance ? Math.min(32,sides) : sides);
  part('Wheels',label+'Tire',p,'rubber',(m,l)=>{
    ring(m,[[-w*.34,.217],[-w*.45,.234],[-w*.50,r-.043],[-w*.44,r-.022],
      [-w*.32,r-.009],[-w*.16,r-.002],[0,r],[w*.16,r-.002],[w*.32,r-.009],
      [w*.44,r-.022],[w*.50,r-.043],[w*.45,.234],[w*.34,.217],[w*.25,.218],[-w*.25,.218]],96);
    if(!distance) l('tread',b=>{
      for(let i=0;i<32;i++) for(const s of [-1,1]) {
        const a=tau*(i+(s>0?.50:0))/32;
        const centers=[[.12,.022,.0004],[.23,0,.0044],[.35,-.026,.0119],[.44,-.055,.0218]]
          .map(([x,offset,drop])=>polar(p,s*x*w,r-drop,a+offset));
        b.tube(centers,centers.map((_,j)=>[.0014,.0029-j*.00023]),6,X);
      }
    });
  },axle,'Rotate with wheel around +X');
  part('Wheels',label+'Rim',p,'anodized',(m,l)=>{
    ring(m,[[-w*.41,rim-.016],[-w*.42,rim],[-w*.35,rim+.001],[-w*.31,rim-.006],
      [-w*.25,rim-.009],[-w*.18,rim-.014],[w*.18,rim-.014],[w*.25,rim-.009],
      [w*.31,rim-.006],[w*.35,rim+.001],[w*.42,rim],[w*.41,rim-.016],
      [w*.27,rim-.022],[-w*.27,rim-.022]]);
    l('alloy',b=>{
      for(let i=0;i<(distance?0:36);i++){
        const a=i*tau/36;
        segment(b,polar(p,w*.16*(i%2?1:-1),.202,a),polar(p,w*.15*(i%2?1:-1),.215,a),.0030,8);
      }
      segment(b,polar(p,0,.192,.42),polar(p,0,.215,.42),.004,8);
    });
  },axle,'Rotate with wheel around +X');
  part('Wheels',label+'Hub',p,'cast',(m,l)=>{
    ring(m,[[-.068,.013],[-.068,.032],[-.053,.035],[-.043,.048],[-.033,.048],
      [-.024,.030],[.023,.028],[.036,.048],[.045,.048],[.053,.037],[.066,.032],[.066,.013]],36);
    l('anodized',b=>{for(const s of [-1,1]) b.lathe(near(p,s*.065),X,
      [[-.004,.011],[-.004,.025],[.004,.025],[.004,.011]],32);});
  },axle,'Rotate with wheel around +X');
  part('Wheels',label+'SpokeSet',p,'alloy',m=>{
    for(let i=0;i<36;i++){
      const s=i%2?1:-1, a=i*tau/36;
      segment(m,polar(p,s*.041,.043,a+(i%4<2?.41:-.41)),polar(p,s*w*.16,.204,a),.0017,distance?3:6);
    }
  },axle,'Rotate with wheel around +X');
  part('Brakes',label+'BrakeDisc',p,'rotor',(m,l)=>{
    const center=near(p,brakeX);
    m.lathe(center,X,[[-.002,disc*.72],[-.002,disc-.001],[.002,disc-.001],[.002,disc*.72]],
      distance?32:72,(i,j)=> !distance && (j===1||j===2) ? .0015*Math.cos(tau*i/9) : 0);
    l('anodized',b=>{
      b.lathe(near(p,brakeX-.003),X,[[-.003,.021],[-.003,.049],[.003,.049],[.003,.021]],48);
      for(let i=0;i<6;i++){
        const a=i*tau/6;
        b.tube([polar(p,brakeX-.004,.043,a),polar(p,brakeX-.004,disc*.61,a+.17),
          polar(p,brakeX-.003,disc*.75,a+.21)],[[.004,.010],[.004,.009],[.004,.009]],8);
        bolt(b,polar(p,brakeX+.003,disc*.74,a+.21),X,.005,.005);
      }
    });
    l('alloy',b=>{for(let i=0;i<6;i++) bolt(b,polar(p,brakeX+.004,.037,i*tau/6),X,.005,.004);});
    if(!distance) l('tread',b=>{
      for(let i=0;i<21;i++){
        const a=tau*i/21;
        for(const [r,offset] of [[.805,0],[.906,.055]]){
          // Flush dark recess detail on both faces of the rotor.
          for(const s of [-1,1]) profile(b,polar(p,brakeX+s*.0022,disc*r,a+offset),X,.00055,.0027,.00014,7);
        }
      }
    });
  },axle,'Rotate with wheel around +X');
  const caliper = polar(p,brakeX,disc*.92,label==='Front'?.63:-.59);
  const [cx,cy,cz]=caliper, cs=-cz;
  part('Brakes',label+'BrakeCaliper',caliper,'anodized',(m,l)=>{
    for(const side of [-1,1]) m.plate([[cy-.030,cs-.026],[cy-.033,cs+.012],[cy-.008,cs+.034],
      [cy+.029,cs+.030],[cy+.036,cs-.005],[cy+.015,cs-.029]],cx+side*.012,.016,.003);
    segment(m,add(caliper,[-.016,.026,-.019]),add(caliper,[.017,.026,-.019]),.011);
    l('alloy',b=>{
      for(const [dy,ds] of [[-.014,.016],[.011,-.010]]) {
        bolt(b,v(cx+.023,cy+dy,cs+ds),X,.005,.005);
      }
      segment(b,v(cx+.006,cy+.025,cs-.011),v(cx+.006,cy+.045,cs-.011),.005,8);
    });
  },{Mount:caliper,Hose:v(cx+.006,cy+.045,cs-.011)},'Mounts to fork lower or swingarm');
}

const engineProfile = [[.315,-.173],[.294,-.096],[.291,.062],[.316,.154],[.364,.189],
  [.428,.168],[.483,.114],[.486,.044],[.448,-.024],[.444,-.121],[.422,-.175]];
const intake = v(0,.525,.004);
const exhaustPort = v(.013,.538,.133);
const atBore = t => add(cylinder,mul(bore,t));
const clutchAxis = v(0,.371,-.053);
const input = v(0,.378,-.057);
const plug = atBore(.169);

for(const s of [-1,1]) {
  part('Engine',s<0?'Crankcase_L':'Crankcase_R',crank,'cast',(m,l)=>{
    m.plate(engineProfile,s*.042,.081,.010);
    for(const [y,z] of [[.352,.201],[.337,-.117]]) {
      segment(m,v(s*.071,y,z),v(s*.102,y,z),.013);
    }
    l('alloy',b=>{
      for(const [y,z] of [[.326,-.140],[.317,.075],[.366,.165],[.448,.120],[.462,.052],[.435,-.139]]) {
        bolt(b,v(s*.085,y,z),X,.0057,.005);
      }
    });
  },{CrankAxis:crank,Deck:cylinder,OutputShaft:output,MountFront:v(0,.354,.201),MountRear:v(0,.336,-.115)});
}
part('Engine','GearboxHousing',input,'cast',(m,l)=>{
  m.plate([[.310,-.179],[.301,-.094],[.337,-.039],[.399,-.037],[.448,-.083],[.448,-.165],
    [.420,-.208],[.364,-.219],[.329,-.201]],0,.181,.008);
  l('anodized',b=>profile(b,v(-.094,.402,-.174),X,.021,.027,.003,24));
},{InputShaft:input,OutputShaft:output,ShiftAxis:v(-.108,.352,-.112)});
part('Engine','ClutchCover',clutchAxis,'anodized',(m,l)=>{
  m.plate([[.303,-.121],[.299,-.052],[.313,.026],[.361,.064],[.416,.051],[.453,-.009],
    [.447,-.097],[.404,-.142],[.343,-.147]],.095,.036,.007);
  profile(m,near(clutchAxis,.116),X,.016,.058,.007);
  l('cast',b=>profile(b,near(clutchAxis,.124),X,.009,.044,.004));
  l('alloy',b=>{
    for(const [y,z] of [[.313,-.103],[.323,.032],[.407,.043],[.443,-.035],[.392,-.125]]) {
      bolt(b,v(.115,y,z),X,.006,.0045);
    }
    bolt(b,v(.121,.435,-.071),X,.009,.007);
  });
},{ClutchAxis:clutchAxis,OilFill:v(.121,.435,-.071)});
part('Engine','IgnitionCover',crank,'anodized',(m,l)=>{
  profile(m,near(crank,-.092),X,.032,.066,.007);
  profile(m,near(crank,-.112),X,.011,.052,.004);
  l('alloy',b=>{for(let i=0;i<4;i++) bolt(b,polar(crank,-.106,.056,i*tau/4+.24),X,.0045,.006);});
},{CrankAxis:crank});

part('Engine','Cylinder',cylinder,'cast',(m,l)=>{
  m.lathe(atBore(.062),bore,[[-.070,.0202],[-.070,.038],[.066,.040],[.066,.0202]],40);
  for(let i=0;i<6;i++){
    const t=.014+i*.019;
    const r=.049+(i<4?.008:0);
    m.lathe(atBore(t),bore,[[-.003,.038],[-.003,r-.002],[0,r],[.003,r-.001],[.003,.038]],32,
      (j,k)=> k>0&&k<4 ? .004*Math.cos(j*tau/8) : 0);
  }
  l('alloy',b=>segment(b,atBore(.043),exhaustPort,.017,20));
},{BoreBase:cylinder,BoreTop:atBore(.128),Intake:intake,Exhaust:exhaustPort});
part('Engine','CylinderHead',atBore(.137),'cast',(m,l)=>{
  m.lathe(atBore(.14),bore,[[-.016,.008],[-.017,.041],[-.012,.053],[.004,.052],
    [.012,.045],[.024,.035],[.026,.008]],40);
  l('alloy',b=>{for(const x of [-.031,.031]) for(const z of [-.025,.025]){
    bolt(b,add(atBore(.158),[x,0,z]),bore,.006,.008);
  }});
},{BoreTop:atBore(.128),SparkPlug:plug,CoolantOut:v(.035,.634,.104)});
part('Engine','SparkPlug',plug,'alloy',(m,l)=>{
  profile(m,add(plug,mul(bore,.006)),bore,.018,.007,.001,6);
  l('trim',b=>b.tube([.010,.019,.024,.029,.034,.039].map(t=>add(plug,mul(bore,t))),
    [.005,.005,.004,.005,.004,.003],14));
},{Thread:plug,Cap:add(plug,mul(bore,.037))});

part('Engine','Piston',atBore(.056),'alloy',(m,l)=>{
  m.lathe(atBore(.056),bore,[[-.018,.016],[-.018,.0195],[.009,.0195],[.010,.0188],
    [.012,.0196],[.016,.0196],[.019,.018],[.021,.002],[.017,.002],[.013,.015],[-.012,.016]],40);
  l('anodized',b=>b.lathe(atBore(.066),bore,[[-.001,.0188],[-.001,.0198],[.001,.0198],[.001,.0188]],40));
},{WristPin:atBore(.047),BoreAxis:cylinder},'Translate along bore axis');
const crankPin=add(crank,[0,.018,-.007]);
part('Engine','Crankshaft',crank,'rotor',(m,l)=>{
  segment(m,near(crank,-.077),near(crank,.081),.0095,24);
  for(const x of [-.024,.024]) profile(m,near(crank,x),X,.015,.036,.002,40);
  l('alloy',b=>segment(b,near(crankPin,-.028),near(crankPin,.028),.007,24));
},{CrankAxis:crank,CrankPin:crankPin},'Rotate around +X');
part('Engine','ConnectingRod',crankPin,'rotor',m=>{
  const p=atBore(.047);
  for(const [c,r,d,w] of [[crankPin,.015,.0075,.009],[p,.008,.0045,.008]]) {
    m.lathe(c,X,[[-w/2,d],[-w/2,r],[w/2,r],[w/2,d]],24);
  }
  m.tube([mix(crankPin,p,.08),mix(crankPin,p,.33),mix(crankPin,p,.76),mix(crankPin,p,.96)],
    [.010,.007,.006,.006],10);
},{BigEnd:crankPin,SmallEnd:atBore(.047)},'Pivot between crank pin and wrist pin');
part('Engine','ClutchBasket',clutchAxis,'cast',(m,l)=>{
  const p=near(clutchAxis,.071);
  m.lathe(p,X,[[-.016,.010],[-.016,.043],[-.012,.046],[.014,.046],[.014,.038],
    [-.009,.038],[-.009,.010]],48,(i,j)=>j===2||j===3?(i%4<2?.002:0):0);
  l('grease',b=>profile(b,near(clutchAxis,.051),X,.007,.045,.002,64));
},{ClutchAxis:clutchAxis},'Rotate around +X');
part('Engine','ClutchPlateStack',clutchAxis,'grease',(m,l)=>{
  const draw = (mesh, i) => mesh.lathe(near(clutchAxis,.063+i*.003),X,
    [[-.0012,.015],[-.0012,.034],[.0012,.034],[.0012,.015]],32);
  for(let i=0;i<7;i++) {
    if (i%2===0) draw(m,i);
    else l('alloy',b=>draw(b,i));
  }
},{ClutchAxis:clutchAxis},'Remove clutch plates as a stack');
part('Engine','ClutchPressurePlate',clutchAxis,'alloy',(m,l)=>{
  profile(m,near(clutchAxis,.086),X,.006,.036,.001,36);
  l('rotor',b=>{for(let i=0;i<4;i++) bolt(b,polar(clutchAxis,.092,.023,i*tau/4),X,.0045,.005);});
},{ClutchAxis:clutchAxis});
for(const [name, p, sizes, offset] of [
  ['GearboxInputShaft',input,[.019,.021,.023,.026,.028,.030],0],
  ['GearboxOutputShaft',v(0,.402,-.174),[.030,.028,.026,.023,.021,.019],.001],
]){
  part('Engine',name,p,'grease',(m,l)=>{
    l('alloy',b=>segment(b,near(p,-.077),near(p,.047),.007,18));
    sizes.forEach((r,i)=>{
      const a=near(p,-.050+i*.015+offset);
      m.lathe(a,X,[[-.005,.007],[-.005,r-.002],[-.003,r],[.003,r],[.005,r-.002],[.005,.007]],
        48,(j,k)=>k===2||k===3?(j%4<2?.0014:0):0);
    });
  },{ShaftAxis:p},'Six-ratio gear cluster, rotate around +X');
}

const carb = v(0,.532,-.095), air = v(0,.636,-.320);
part('Intake','IntakeManifold',intake,'rubber',m=>{
  m.tube([intake,v(0,.532,-.026),v(0,.535,-.059)],[.017,.018,.018],18);
},{ReedBlock:intake,CarbOutlet:v(0,.535,-.059)});
part('Intake','Carburetor',carb,'cast',(m,l)=>{
  m.tube([v(0,.535,-.055),v(0,.536,-.074),v(0,.537,-.122),v(0,.543,-.145)],
    [.017,.025,.025,.021],20);
  shell(m,[[-.125,.498,.019,.012],[-.111,.496,.027,.018],[-.082,.496,.027,.018],[-.068,.500,.021,.012]]);
  l('alloy',b=>profile(b,v(0,.562,-.099),Y,.017,.015,.003,20));
  l('weld',b=>{segment(b,v(.018,.540,-.092),v(.036,.553,-.095),.004,10);bolt(b,v(.029,.522,-.112),X,.004);});
},{Intake:v(0,.543,-.145),Outlet:v(0,.535,-.059),ThrottleCable:v(0,.571,-.099)});
part('Intake','AirboxBoot',air,'rubber',m=>{
  m.tube([v(0,.543,-.141),v(0,.548,-.173),v(0,.576,-.212),v(0,.614,-.262),air],
    [.021,.024,.026,.029,.033],20);
},{Carburetor:v(0,.543,-.145),Airbox:air});
part('Intake','Airbox',air,'dirty',m=>{
  shell(m,[[-.475,.704,.038,.044],[-.420,.690,.070,.064],[-.336,.673,.068,.061],[-.286,.645,.043,.038]],12,.54);
},{Boot:air,ServiceCover:v(-.073,.691,-.387)});
part('Intake','AirFilter',v(0,.685,-.378),'spring',(m,l)=>{
  shell(m,[[-.417,.692,.036,.033],[-.407,.686,.048,.039],[-.358,.679,.048,.039],[-.349,.679,.035,.031]],16);
  l('black',b=>shell(b,[[-.354,.679,.048,.038],[-.343,.679,.048,.038]],16));
},{AirboxSeat:v(0,.685,-.378)});

for(const s of [-1,1]){
  const p=v(s*.077,.701,.240);
  part('Cooling',s<0?'Radiator_L':'Radiator_R',p,'alloy',(m,l)=>{
    for(const [y,z] of [[.751,.208],[.633,.254]]) segment(m,v(s*.041,y,z),v(s*.109,y,z),.013,16);
    for(const x of [s*.040,s*.110]) segment(m,v(x,.633,.254),v(x,.751,.208),.006,10);
    l('anodized',b=>{for(let i=1;i<17;i++){
      const t=i/17;
      segment(b,v(s*.044,.633+.118*t,.254-.046*t),v(s*.106,.633+.118*t,.254-.046*t),.0027,6);
    }});
  },{Upper:v(s*.076,.751,.208),Lower:v(s*.076,.633,.254),FrameMount:p});
}
part('Cooling','CoolantHoses',plug,'rubber',(m,l)=>{
  m.tube([v(.035,.634,.104),v(.047,.644,.129),v(.072,.701,.166),v(.076,.751,.208)],
    [.009,.009,.009,.009],12);
  m.tube([v(-.076,.633,.254),v(-.092,.557,.215),v(-.088,.482,.164),v(-.077,.422,.153)],
    [.009,.009,.009,.009],12);
  segment(m,v(-.066,.748,.206),v(.066,.748,.206),.008,12);
  l('alloy',b=>segment(b,v(.043,.641,.119),v(.048,.649,.133),.0103,12));
},{Head:v(.035,.634,.104),Pump:v(-.077,.422,.153)});

const rearDrive=near(rear,-.109);
for(const [name,p,r,teeth] of [['FrontSprocket',output,.029,12],['RearSprocket',rearDrive,.090,48]]){
  part('Drivetrain',name,p,'grease',(m,l)=>{
    const inner=name==='FrontSprocket'?.010:.044;
    m.lathe(p,X,[[-.003,inner],[-.003,r-.004],[-.002,r],[.002,r],[.003,r-.004],[.003,inner]],
      distance?32:teeth*4,(i,j)=> !distance && (j===2||j===3) ? (i%4===1||i%4===2?.0031:-.0027) : 0);
    l('alloy',b=>{
      if(name==='FrontSprocket') bolt(b,near(p,-.006),X,.012,.006);
      else for(let i=0;i<6;i++){
        const a=i*tau/6;
        segment(b,polar(p,.003,.031,a),polar(p,.002,.054,a),.007,10);
        bolt(b,polar(p,-.006,.053,a),X,.0045,.005);
      }
    });
  },{SprocketAxis:p},'Rotate around +X in the left chain plane');
}
function chainPath() {
  // External tangents of unequal pitch circles in the Y/Z plane.
  const [small,big]=[.029,.090], d=sub(output,rearDrive);
  const theta=Math.atan2(d[2],d[1]), half=Math.acos((big-small)/Math.hypot(d[1],d[2]));
  const a=theta-half, b=theta+half;
  const nodes=[];
  for(let i=0;i<=48;i++) nodes.push(polar(output,0,small,a+(b-a)*i/48));
  for(let i=0;i<=64;i++) nodes.push(polar(rearDrive,0,big,b+(tau-(b-a))*i/64));
  const lengths=nodes.map((p,i)=>Math.hypot(...sub(nodes[(i+1)%nodes.length],p)));
  const total=lengths.reduce((a,b)=>a+b);
  const linkCount=2*Math.round(total/(distance?.0508:.0254));
  let j=0, start=0;
  return Array.from({length:linkCount},(_,i)=>{
    const distance=total*i/linkCount;
    while(start+lengths[j]<distance) start+=lengths[j++];
    return mix(nodes[j],nodes[(j+1)%nodes.length],(distance-start)/lengths[j]);
  });
}
part('Drivetrain','Chain',output,'grease',(m,l)=>{
  const path=chainPath();
  if(distance){
    const strip = path.map((p,i)=>{
      const a=path[(i+path.length-1)%path.length], b=path[(i+1)%path.length];
      const d=unit(sub(b,a));
      const n=[0,d[2],-d[1]];
      return [[-.005,-.003],[.005,-.003],[.005,.003],[-.005,.003]]
        .map(([x,y])=>add(near(p,x),mul(n,y)));
    });
    m.rings(strip,{closed:true});
    return;
  }
  path.forEach((p,i)=>{
    const q=path[(i+1)%path.length], offset=i%2?.0064:.0046;
    for(const s of [-1,1]) {
      const a=near(p,s*offset), b=near(q,s*offset);
      m.tube([mix(a,b,-.14),mix(a,b,.10),mix(a,b,.50),mix(a,b,.90),mix(a,b,1.14)],
        [[.001,.002],[.0011,.0044],[.0011,.003],[.0011,.0044],[.001,.002]],6,X);
    }
    l('rotor',b=>segment(b,near(p,-.0065),near(p,.0065),.003,8));
  });
},{FrontSprocket:output,RearSprocket:rearDrive},'Animate along the pitch path in the left drive plane');
part('Drivetrain','ChainGuide',v(-.109,.231,-.542),'black',(m,l)=>{
  for(const x of [-.124,-.095]){
    m.plate([[.224,-.592],[.218,-.504],[.239,-.493],[.260,-.521],[.256,-.577]],x,.008,.002);
  }
  l('alloy',b=>segment(b,v(-.124,.258,-.561),v(-.130,.345,-.542),.006,10));
},{SwingarmMount:v(-.134,.320,-.542)});

const headerEnd=v(.094,.369,.251), chamberEnd=v(.151,.649,-.337), silencerEnd=v(.128,.807,-.763);
part('Exhaust','Header',exhaustPort,'pipe',(m,l)=>{
  m.tube([exhaustPort,v(.018,.526,.159),v(.040,.493,.200),v(.069,.443,.228),v(.086,.402,.247),headerEnd],
    [.014,.015,.016,.017,.018,.021],20);
  l('weld',b=>segment(b,v(.014,.538,.129),v(.015,.534,.144),.020,24));
},{ExhaustPort:exhaustPort,ChamberInlet:headerEnd});
part('Exhaust','ExpansionChamber',headerEnd,'pipe',(m,l)=>{
  const rows=[
    [headerEnd,.021],[v(.115,.351,.236),.029],[v(.134,.343,.207),.041],[v(.146,.346,.171),.049],
    [v(.154,.356,.106),.056],[v(.159,.399,.000),.052],[v(.158,.460,-.091),.044],
    [v(.155,.523,-.189),.030],[v(.151,.593,-.276),.016],[chamberEnd,.012]];
  m.tube(rows.map(x=>x[0]),rows.map(x=>x[1]),26);
  l('weld',b=>{
    for(let i=2;i<9;i++){
      const [p,r]=rows[i], axis=unit(sub(rows[i+1][0],rows[i-1][0]));
      b.lathe(p,axis,[[-.002,r-.001],[-.001,r+.0009],[.001,r+.0009],[.002,r-.001]],26);
    }
  });
},{Header:headerEnd,SilencerInlet:chamberEnd,FrameStay:v(.158,.460,-.091)});
part('Exhaust','Silencer',chamberEnd,'alloy',(m,l)=>{
  const bodyStart=v(.144,.729,-.477);
  const centers=[bodyStart,v(.143,.735,-.493),v(.131,.785,-.699),v(.129,.792,-.723)];
  m.tube(centers,[[.023,.028],[.034,.039],[.033,.037],[.022,.028]],20);
  l('pipe',b=>{
    b.tube([chamberEnd,v(.146,.695,-.401),bodyStart],[.012,.013,.014],16);
    b.lathe(v(.129,.802,-.746),unit(sub(silencerEnd,centers.at(-1))),
      [[-.020,.008],[-.020,.015],[.016,.014],[.016,.0095],[.012,.008]],22);
  });
  l('anodized',b=>{
    b.tube([v(.144,.728,-.470),v(.144,.735,-.492)],[[.023,.029],[.031,.036]],20);
    b.tube([v(.132,.782,-.694),v(.129,.798,-.733)],[[.033,.037],[.020,.023]],20);
  });
},{Inlet:chamberEnd,Outlet:silencerEnd,Mount:v(.130,.782,-.656)});
part('Exhaust','ExhaustMounts',v(.112,.556,-.237),'frame',(m,l)=>{
  segment(m,v(.087,.596,-.291),v(.152,.558,-.233),.009,10);
  segment(m,v(.067,.817,-.667),v(.130,.782,-.656),.010,10);
  l('alloy',b=>{bolt(b,v(.159,.556,-.233),X);bolt(b,v(.163,.784,-.653),X);});
},{MidPipe:v(.152,.558,-.233),Silencer:v(.130,.782,-.656)});

part('Bodywork','FuelTank',v(0,.865,.070),'black',(m,l)=>{
  shell(m,[[-.228,.864,.039,.034],[-.168,.856,.069,.043],[-.070,.858,.096,.052],
    [.069,.873,.122,.058],[.181,.895,.114,.048],[.267,.900,.061,.033],[.292,.898,.037,.018]],20);
  l('body',b=>shell(b,[[-.167,.886,.056,.012],[-.087,.900,.088,.015],[.069,.925,.104,.018],
    [.173,.936,.096,.017],[.248,.929,.056,.011],[.281,.918,.035,.005]],20));
  l('anodized',b=>profile(b,v(0,.955,.154),Y,.011,.027,.002,24));
  l('alloy',b=>bolt(b,v(0,.962,.154),Y,.012,.005));
},{FrameMount:v(0,.871,.165),FuelCap:v(0,.962,.154),FuelOutlet:v(-.058,.814,-.095)});
part('Bodywork','Seat',v(0,.848,-.348),'seat',(m,l)=>{
  const rows=[[-.764,.855,.041,.011],[-.710,.869,.056,.020],[-.580,.870,.081,.024],
    [-.414,.868,.083,.023],[-.259,.867,.069,.024],[-.117,.881,.059,.021],
    [-.026,.909,.046,.015],[.018,.925,.037,.009]];
  shell(m,rows,20,.54);
  l('black',b=>shell(b,rows.slice(0,-1).map(([s,y,w,h])=>[s,y-h*.66,w*.94,.005]),14));
  l('anodized',b=>{for(const s of [-1,1]) {
    b.tube(rows.slice(1,-1).map(([z,y,w,h])=>v(s*w*.955,y-h*.29,z)),Array(6).fill(.0011),6);
  }});
},{FrontTongue:v(0,.889,-.079),Latch:v(0,.838,-.573)});
for(const s of [-1,1]) {
  const side=s<0?'L':'R';
  part('Bodywork','RadiatorShroud_'+side,v(s*.111,.826,.148),'body',(m,l)=>{
    shell(m,[[-.225,.783,.006,.025,s*.079],[-.177,.800,.014,.043,s*.103],
      [-.085,.811,.022,.052,s*.113],[.026,.796,.025,.075,s*.121],
      [.124,.780,.022,.108,s*.119],[.214,.799,.023,.107,s*.109],
      [.289,.826,.021,.067,s*.091],[.311,.847,.009,.029,s*.074]],14,.56);
    l('trim',b=>shell(b,[[-.134,.808,.0035,.008,s*.125],[-.071,.812,.005,.015,s*.133],
      [.051,.823,.005,.018,s*.145],[.161,.855,.005,.015,s*.136],[.251,.872,.003,.006,s*.116]],10,.58));
    l('black',b=>shell(b,[[.052,.743,.005,.010,s*.141],[.102,.745,.005,.029,s*.139],
      [.169,.758,.005,.033,s*.139],[.214,.777,.004,.012,s*.129]],10,.58));
    l('alloy',b=>{bolt(b,v(s*.135,.832,-.085),X,.005,.004);bolt(b,v(s*.127,.878,.235),X,.004,.004);});
  },{Upper:v(s*.116,.882,.179),Lower:v(s*.109,.688,.212)});
  part('Bodywork','SidePanel_'+side,v(s*.088,.785,-.412),'trim',(m,l)=>{
    shell(m,[[-.765,.837,.005,.013,s*.063],[-.674,.821,.011,.026,s*.080],
      [-.551,.778,.021,.067,s*.089],[-.412,.747,.023,.091,s*.098],
      [-.325,.755,.019,.084,s*.103],[-.248,.799,.015,.051,s*.093],[-.217,.815,.007,.024,s*.076]],16,.49);
    l('body',b=>shell(b,[[-.716,.839,.004,.006,s*.078],[-.619,.828,.004,.012,s*.095],
      [-.489,.807,.005,.015,s*.111],[-.374,.783,.005,.018,s*.122],[-.300,.754,.004,.010,s*.119]],10));
    l('alloy',b=>bolt(b,v(s*.127,.783,-.374),X,.005,.004));
  },{Front:v(s*.096,.803,-.271),Rear:v(s*.080,.820,-.648)});
}
part('Bodywork','RearFender',v(0,.836,-.679),'body',(m,l)=>{
  shell(m,[[-.928,.851,.030,.007],[-.897,.852,.051,.012],[-.824,.850,.073,.015],
    [-.720,.842,.077,.015],[-.606,.834,.072,.014],[-.514,.824,.064,.010]],16,.61);
  l('black',b=>shell(b,[[-.890,.826,.033,.012],[-.831,.823,.055,.016],[-.708,.819,.051,.013]],12));
},{Mount:v(0,.836,-.679),TailLamp:v(0,.827,-.861),PlateBracket:v(0,.808,-.891)});
part('Bodywork','FrontFender',v(0,.754,.483),'body',(m,l)=>{
  shell(m,[[.324,.697,.039,.006],[.388,.730,.059,.008],[.472,.751,.069,.012],
    [.574,.743,.075,.013],[.681,.725,.074,.013],[.785,.697,.066,.012],
    [.878,.672,.057,.010],[.930,.661,.035,.007]],16,.56);
  l('black',b=>shell(b,[[.402,.720,.050,.004],[.492,.739,.061,.006],[.595,.730,.059,.004]],12));
},{Mount:v(0,.764,.486)},'Steers with lower triple clamp');

const lamp=v(0,.887,.464);
part('Bodywork','HeadlightMask',lamp,'body',(m,l)=>{
  shell(m,[[.399,.908,.077,.077],[.422,.914,.100,.086],[.452,.916,.104,.079],
    [.484,.906,.082,.068],[.506,.888,.060,.050]],16,.63);
  l('trim',b=>shell(b,[[.453,.965,.076,.027],[.477,.965,.083,.029],[.498,.953,.061,.019]],12,.60));
},{SteeringMount:v(0,.887,.425),Lamp:lamp},'Steers with the fork assembly');
part('Electrical','Headlight',lamp,'black',(m,l)=>{
  shell(m,[[.485,.884,.059,.037],[.507,.887,.068,.036],[.526,.888,.057,.029]],16,.55);
  l('reflector',b=>{
    shell(b,[[.524,.887,.052,.026],[.529,.889,.054,.025],[.530,.888,.048,.021]],16,.66);
    for(const x of [-.028,0,.028]) segment(b,v(x,.877,.529),v(x,.899,.529),.0016,8);
  });
  l('glass',b=>shell(b,[[.528,.888,.055,.026],[.535,.888,.052,.023],[.537,.888,.047,.020]],16,.59));
},{Mask:lamp,Connector:v(0,.891,.481)});
part('Electrical','TailLight',v(0,.824,-.860),'red',(m,l)=>{
  shell(m,[[-.889,.826,.030,.007],[-.883,.824,.047,.010],[-.861,.821,.052,.011],[-.847,.819,.043,.009]],16);
  l('black',b=>shell(b,[[-.860,.814,.045,.010],[-.837,.815,.052,.013],[-.824,.818,.044,.011]],12));
},{Fender:v(0,.827,-.861)});
part('Bodywork','NumberPlate',v(0,.754,-.891),'trim',(m,l)=>{
  shell(m,[[-.910,.755,.073,.023],[-.907,.755,.077,.026],[-.903,.755,.076,.025]],16,.26);
  l('black',b=>shell(b,[[-.905,.756,.080,.029],[-.899,.756,.079,.029],[-.887,.769,.055,.022]],16,.42));
  l('black',b=>b.tube([v(0,.825,-.860),v(0,.806,-.884),v(0,.772,-.894)],
    [[.027,.008],[.025,.007],[.026,.006]],12,[0,0,1]));
  l('alloy',b=>{for(const x of [-.048,.048]) bolt(b,v(x,.772,-.912),[0,0,1],.003,.003);});
  l('amber',b=>shell(b,[[-.912,.713,.034,.008],[-.907,.713,.034,.008]],12));
},{Bracket:v(0,.808,-.891)});

part('Controls','Handlebar',bar,'anodized',(m,l)=>{
  m.tube([v(-.361,1.048,.268),v(-.252,1.049,.299),v(-.195,1.047,.318),
    v(-.098,1.012,.335),v(-.050,1.003,.339),v(.050,1.003,.339),
    v(.098,1.012,.335),v(.195,1.047,.318),v(.252,1.049,.299),v(.361,1.048,.268)],
    [.011,.011,.011,.013,.014,.014,.013,.011,.011,.011],16);
  for(const x of [-.044,.044]) segment(m,v(x,.963,.365),v(x,1.007,.337),.016);
  l('alloy',b=>{for(const x of [-.044,.044]) for(const s of [.325,.350]) bolt(b,v(x,1.021,s),Y,.0045,.005);});
},{Clamp:bar,GripL:v(-.313,1.049,.283),GripR:v(.313,1.049,.283)},'Steers with the triple clamps');
for(const s of [-1,1]){
  const side=s<0?'L':'R', grip=v(s*.258,1.049,.297), end=v(s*.366,1.048,.267);
  const axis=unit(sub(end,grip));
  part('Controls',s<0?'LeftGrip':'ThrottleGrip',grip,'rubber',(m,l)=>{
    m.tube([grip,mix(grip,end,.09),mix(grip,end,.17),mix(grip,end,.94),end],
      [.022,.021,.0155,.016,.019],20);
    if(!distance) l('tread',b=>{for(let i=0;i<13;i++){
      b.lathe(mix(grip,end,.22+i*.054),axis,[[-.0006,.0153],[-.0006,.017],[.0006,.017],[.0006,.0153]],16);
    }});
  },{HandlebarAxis:grip,BarEnd:end},s<0?'Remove grip':'Rotate around the local bar axis');
  const lever=v(s*.244,1.039,.336);
  part('Controls',s<0?'ClutchLever':'FrontBrakeLever',lever,'alloy',(m,l)=>{
    m.tube([lever,v(s*.275,1.034,.345),v(s*.311,1.031,.342),v(s*.346,1.033,.328),
      v(s*.356,1.035,.327)],[[.005,.007],[.005,.008],[.004,.007],[.004,.006],[.006,.006]],10);
    l('black',b=>segment(b,v(s*.238,1.048,.302),v(s*.244,1.040,.336),.012,12));
  },{Hinge:lever,Perch:v(s*.238,1.048,.302)},'Pivot about local +Y');
}
part('Controls','FrontBrakeMasterCylinder',v(.224,1.059,.315),'black',(m,l)=>{
  shell(m,[[.292,1.059,.021,.011,.218],[.305,1.065,.025,.017,.217],[.332,1.063,.025,.016,.217],
    [.340,1.061,.021,.011,.216]],12);
  l('alloy',b=>{for(const x of [.199,.232]) bolt(b,v(x,1.081,.316),Y,.004,.002);});
},{Lever:v(.244,1.039,.336),Hose:v(.213,1.059,.337)});
part('Controls','InstrumentCluster',v(0,.990,.414),'black',(m,l)=>{
  shell(m,[[.375,.991,.034,.012],[.392,1.000,.049,.014],[.435,.996,.044,.014],[.448,.990,.034,.009]],12);
  l('reflector',b=>shell(b,[[.397,1.014,.032,.002],[.428,1.010,.030,.002]],12));
},{Bracket:v(0,.978,.405)});
part('Controls','ControlLines',v(0,.938,.342),'black',m=>{
  m.tube([v(.213,1.059,.337),v(.166,1.010,.424),v(.131,.871,.478),v(.123,.703,.506),
    v(.108,.529,.575),v(.089,.453,.580)],[.003,.003,.003,.003,.003,.003],8);
  m.tube([v(-.236,1.045,.315),v(-.185,1.058,.363),v(-.108,1.017,.361),
    v(-.050,.856,.361),v(.010,.718,.246),v(.065,.609,.102),v(.103,.454,-.026)],
    [.0025,.0025,.0025,.0025,.0025,.0025,.0025],8);
  m.tube([v(.251,1.057,.299),v(.164,1.026,.363),v(.077,.967,.365),v(.028,.791,.289),
    v(.024,.672,.108),v(0,.571,-.099)],Array(6).fill(.0025),8);
},{SteeringGuide:v(0,.938,.342),Throttle:v(0,.571,-.099)});

for (const s of [-1,1]) {
  const p=v(s*.127,.365,-.239), toe=v(s*.220,.367,-.239);
  part('Chassis',s<0?'FootPeg_L':'FootPeg_R',p,'anodized',(m,l)=>{
    m.tube([p,mix(p,toe,.23),mix(p,toe,.89),toe],[[.013,.017],[.013,.024],[.012,.024],[.011,.018]],10);
    l('alloy',b=>{for(let i=0;i<7;i++) for(const o of [-.014,.014]){
      const a=mix(p,toe,.25+i*.100);
      segment(b,add(a,[0,.009,o]),add(a,[0,.016,o]),.003,6);
    }});
  },{FoldAxis:p},'Fold about local Z');
}
part('Chassis','SideStand',v(-.113,.345,-.267),'frame',(m,l)=>{
  m.tube([v(-.113,.345,-.267),v(-.143,.344,-.297),v(-.166,.318,-.397),
    v(-.160,.294,-.526),v(-.151,.278,-.589)],[.011,.009,.009,.008,.007],12);
  m.plate([[.270,-.614],[.269,-.570],[.282,-.559],[.292,-.596]],-.153,.024,.004);
  l('alloy',b=>bolt(b,v(-.127,.345,-.267),X,.009,.007));
},{Hinge:v(-.113,.345,-.267)},'Rotate stand about +X');
for(const [name,p,s,points] of [
  ['GearShifter',v(-.111,.354,-.108),-1,[[.349,-.073],[.324,.003],[.321,.072]]],
  ['RearBrakePedal',v(.116,.355,-.198),1,[[.338,-.149],[.305,-.037],[.319,.071]]],
  ['Kickstarter',v(.123,.421,-.122),1,[[.463,-.156],[.515,-.170],[.550,-.161]]],
]){
  part('Controls',name,p,'alloy',(m,l)=>{
    const nodes=[p,...points.map(([y,z],i)=>v(s*(.128+i*.006),y,z))];
    m.tube(nodes,[.010,.008,.006,.006],10);
    bolt(m,near(p,s*.009),X,.009,.007);
    l('rubber',b=>segment(b,nodes.at(-1),near(nodes.at(-1),s*.034),.008,12));
  },{Hinge:p},'Pivot about +X');
}

export const datums = {FrontAxle:front,RearAxle:rear,Steering:stem,Swingarm:swing,Crankshaft:crank};
export const proxies = [
  {name:'ChassisProxy',center:v(0,.565,-.020),size:[.240,.535,.665],target:'MainFrame'},
  {name:'SeatProxy',center:v(0,.838,-.373),size:[.154,.106,.613],target:'Subframe'},
  {name:'FrontWheelProxy',center:front,size:[.105,.602,.602],target:'FrontTire',shape:'Cylinder'},
  {name:'RearWheelProxy',center:rear,size:[.132,.598,.598],target:'RearTire',shape:'Cylinder'},
];
