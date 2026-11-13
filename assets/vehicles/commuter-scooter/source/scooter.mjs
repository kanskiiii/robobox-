import {Mesh,v,add,sub,mul,unit,mix,tau} from '../../sm50/source/geometry.mjs';

export const materials={
  paint:['Graphite powder coated aluminium','#353e40',.55,.38,'Metal'],
  alloy:['Machined aluminium','#aab3b1',.76,.33,'Metal'],
  trim:['Signal orange anodized aluminium','#dc6b2e',.46,.34,'Metal'],
  rubber:['Tire rubber','#262a29',0,.91,'Rubber'],
  tread:['Tread recess and grip rubber','#171d1c',0,.96,'Rubber'],
  black:['Black nylon','#242b2a',0,.68,'SmoothPlastic'],
  steel:['Brushed rotor steel','#bbc0bc',.86,.42,'Metal'],
  cell:['Teal battery cell sleeve','#399582',.06,.54,'SmoothPlastic'],
  pcb:['Solder masked circuit board','#2b5445',.08,.74,'SmoothPlastic'],
  copper:['Tinned copper connector','#aa7450',.74,.38,'Metal'],
  red:['Red lamp polycarbonate','#b53037',.03,.24,'SmoothPlastic'],
  ivory:['LED diffuser','#e0e9de',0,.29,'SmoothPlastic'],
  screen:['Smoked acrylic display','#263f45',.14,.24,'Glass',.23],
  amber:['Amber reflector','#cb782a',.02,.31,'SmoothPlastic'],
};
export const components=[];
const X=[1,0,0], Y=[0,1,0];
const front=v(0,.125,.469), rear=v(0,.125,-.469);
const hinge=v(0,.279,.338), bars=v(0,1.037,.220), battery=v(0,.107,-.023);
const controller=v(0,.132,.233);
export const datums={FrontAxle:front,RearAxle:rear,FoldHinge:hinge,Handlebar:bars,BatteryBay:battery};
export const proxies=[
  {name:'DeckProxy',target:'DeckFrame',center:v(0,.130,-.028),size:[.184,.076,.566]},
  {name:'FrontWheelProxy',target:'FrontTire',center:front,size:[.057,.250,.250],shape:'Cylinder'},
  {name:'RearWheelProxy',target:'RearTire',center:rear,size:[.057,.250,.250],shape:'Cylinder'},
];
function part(category,name,pivot,key,draw,attachments={},interaction='Remove / install'){
  const layers={};
  const layer=(mat,build)=>build(layers[mat]??=new Mesh());
  layer(key,m=>draw(m,layer));
  components.push({category,name,pivot,layers,attachments,interaction});
}
function box(m,p,w,h,d,bevel=.0025){
  const [x,y,z]=p,s=-z,a=Math.min(bevel,w*.2,h*.2,d*.2);
  m.plate([[y-h/2,s-d/2+a],[y-h/2+a,s-d/2],[y+h/2-a,s-d/2],[y+h/2,s-d/2+a],
    [y+h/2,s+d/2-a],[y+h/2-a,s+d/2],[y-h/2+a,s+d/2],[y-h/2,s+d/2-a]],x,w,a);
}
function turn(m,p,axis,width,r,sides=24){
  const w=width/2;
  m.lathe(p,axis,[[-w,.001],[-w,r*.90],[-w*.75,r],[w*.75,r],[w,r*.90],[w,.001]],sides);
}
const offset=(p,x)=>add(p,[x,0,0]);
const polar=(p,x,r,t)=>add(p,[x,r*Math.cos(t),r*Math.sin(t)]);
const bolt=(m,p,axis,r=.004)=>turn(m,p,axis,.004,r,6);

part('Chassis','DeckFrame',v(0,.129,-.02),'paint',(m,l)=>{
  for(const s of [-1,1]){
    const x=s*.084;
    m.plate([[.089,-.321],[.080,-.257],[.079,.213],[.102,.297],[.149,.300],
      [.170,.247],[.171,-.292],[.150,-.327]],x,.022,.005);
    l('alloy',b=>box(b,v(s*.094,.108,-.028),.007,.013,.507));
    l('amber',b=>box(b,v(s*.100,.137,.187),.006,.018,.062));
  }
  for(const z of [-.284,-.193,.152,.245]) box(m,v(0,.137,z),.174,.065,.027);
  l('trim',b=>{for(const s of [-1,1]) box(b,v(s*.096,.150,-.244),.004,.008,.084,.001);});
},{BatteryBay:battery,Neck:v(0,.164,.259),RearPivot:v(0,.156,-.305),Floorboard:v(0,.174,-.029)});
part('Chassis','Floorboard',v(0,.174,-.029),'alloy',(m,l)=>{
  m.shell([[-.309,.170,.075,.006],[-.263,.170,.091,.007],[.178,.170,.091,.007],
    [.245,.170,.073,.006],[.268,.170,.060,.005]],16,.43);
  l('tread',b=>{
    box(b,v(0,.180,-.032),.162,.009,.503);
    for(let i=0;i<12;i++) for(const s of [-1,1]){
      const z=-.260+i*.041;
      b.tube([v(s*.011,.185,z-.008),v(s*.045,.186,z),v(s*.071,.185,z-.008)],
        [[.002,.005],[.002,.005],[.002,.004]],6,Y);
    }
  });
  for(const x of [-.083,.083]) for(const z of [-.257,.190]) bolt(m,v(x,.177,z),Y);
},{CoverMount:v(0,.174,-.029)},'Remove top plate to access electronics');
part('Chassis','BatteryAccessPan',v(0,.080,-.018),'black',(m,l)=>{
  m.shell([[-.304,.087,.074,.008],[-.264,.081,.089,.010],[.178,.081,.089,.010],
    [.227,.084,.073,.008],[.245,.092,.056,.006]],14,.49);
  l('alloy',b=>{for(const x of [-.079,.079]) for(const z of [-.252,-.033,.176]) bolt(b,v(x,.075,z),Y);});
},{BatteryBay:battery},'Remove underside service panel');
part('Chassis','HeadTube',hinge,'paint',(m,l)=>{
  m.tube([v(0,.121,.232),v(0,.147,.267),v(0,.207,.320),v(0,.267,.342)],
    [[.032,.062],[.038,.055],[.033,.046],[.029,.030]],16);
  l('alloy',b=>{
    m.rod(v(0,.244,.344),v(0,.310,.330),.022,18);
    turn(b,v(0,.264,.341),unit(v(0,1,-.19)),.015,.027);
  });
},{SteeringLower:v(0,.243,.348),SteeringUpper:v(0,.308,.335),FoldHinge:hinge});
part('Chassis','RearSwingarm',v(0,.156,-.305),'paint',(m,l)=>{
  for(const s of [-1,1]){
    m.tube([v(s*.069,.156,-.300),v(s*.057,.148,-.376),v(s*.049,.125,-.469)],
      [[.016,.023],[.014,.020],[.013,.019]],10);
    l('alloy',b=>bolt(b,v(s*.065,.125,-.469),X,.011));
  }
  m.rod(v(-.061,.157,-.315),v(.061,.157,-.315),.014,12);
},{Pivot:v(0,.156,-.305),Axle:rear,Shock:v(0,.158,-.395)},'Pivot about +X');
part('Suspension','RearDamper',v(0,.180,-.314),'black',(m,l)=>{
  const a=v(0,.180,-.314),b=v(0,.158,-.395),axis=unit(sub(b,a));
  m.rod(a,mix(a,b,.59),.015,14);
  l('alloy',k=>k.rod(mix(a,b,.49),b,.008,12));
  l('trim',k=>{
    const points=Array.from({length:45},(_,i)=>{
      const t=i/44, phase=t*4*tau;
      return add(mix(a,b,.11+t*.73),[.018*Math.cos(phase),.017*Math.sin(phase),-.005*Math.sin(phase)]);
    });
    k.tube(points,points.map(()=>.0027),7);
    turn(k,mix(a,b,.12),axis,.006,.018);
    turn(k,mix(a,b,.83),axis,.006,.018);
  });
},{Upper:v(0,.180,-.314),Lower:v(0,.158,-.395)});
part('Suspension','ForkCrown',v(0,.260,.379),'paint',(m,l)=>{
  m.tube([v(-.056,.261,.407),v(-.025,.269,.392),v(0,.271,.376),
    v(.025,.269,.392),v(.056,.261,.407)],[.016,.017,.020,.017,.016],12);
  l('alloy',b=>b.rod(v(0,.258,.357),v(0,.322,.334),.015,16));
},{Steering:v(0,.308,.335),ForkL:v(-.049,.260,.411),ForkR:v(.049,.260,.411)},'Steer around head tube axis');
for(const [name,x] of [['L',-.049],['R',.049]]){
  const a=v(x,.260,.411), b=offset(front,x);
  part('Suspension','ForkSlider_'+name,b,'paint',(m,l)=>{
    m.tube([mix(a,b,.42),mix(a,b,.55),mix(a,b,.93),b],[.014,.017,.016,.014],16);
    l('alloy',k=>{k.rod(a,mix(a,b,.55),.010,16);bolt(k,offset(b,Math.sign(x)*.015),X,.009);});
    l('amber',k=>box(k,offset(mix(a,b,.70),Math.sign(x)*.016),.005,.020,.014));
  },{ForkAxis:a,Axle:b},'Translate along the fork axis');
}

part('Steering','FoldingBase',hinge,'paint',(m,l)=>{
  m.tube([v(0,.281,.346),hinge,v(0,.327,.326)],[.023,.029,.023],18);
  l('trim',b=>{for(const x of [-.033,.033]) turn(b,offset(hinge,x),X,.009,.013,18);});
},{FoldAxis:hinge,Steering:v(0,.308,.335)},'Fold steering stem about +X');
part('Steering','FoldLatch',v(.029,.302,.332),'trim',(m,l)=>{
  m.tube([v(.029,.284,.331),v(.041,.303,.328),v(.036,.345,.319)],
    [[.007,.009],[.007,.010],[.006,.008]],10);
  l('steel',b=>bolt(b,v(.045,.303,.328),X,.005));
},{LatchPin:v(.039,.303,.328)},'Release folding latch');
part('Steering','SteeringStem',hinge,'paint',(m,l)=>{
  m.tube([v(0,.324,.326),v(0,.347,.321),v(0,.576,.292),v(0,.949,.235),v(0,1.034,.222)],
    [[.024,.025],[.021,.022],[.019,.020],[.018,.019],[.020,.021]],18);
  l('alloy',b=>b.rod(v(0,.978,.232),bars,.021,18));
  l('trim',b=>b.rod(v(0,.363,.319),v(0,.388,.316),.021,18));
},{FoldAxis:hinge,BarClamp:bars,Headlight:v(0,.876,.262)},'Steer or fold with hinge');
part('Controls','Handlebar',bars,'paint',(m,l)=>{
  m.tube([v(-.250,1.045,.179),v(-.180,1.044,.194),v(-.088,1.031,.213),bars,
    v(.088,1.031,.213),v(.180,1.044,.194),v(.250,1.045,.179)],
    [.009,.009,.010,.012,.010,.009,.009],14);
  l('alloy',b=>{for(const x of [-.018,.018]) bolt(b,v(x,1.049,.219),Y);});
},{Clamp:bars,GripL:v(-.191,1.044,.192),GripR:v(.191,1.044,.192)});
for(const [s,name] of [[-1,'LeftGrip'],[1,'RightGrip']]){
  const a=v(s*.145,1.042,.200), b=v(s*.250,1.045,.179),axis=unit(sub(b,a));
  part('Controls',name,a,'tread',(m,l)=>{
    m.tube([a,mix(a,b,.10),mix(a,b,.88),b],[.016,.014,.014,.016],18);
    l('rubber',k=>{for(let i=0;i<10;i++) turn(k,mix(a,b,.16+.073*i),axis,.0018,.0147,14);});
  },{BarAxis:a,End:b});
}
part('Controls','BrakeLever',v(-.137,1.036,.219),'alloy',(m,l)=>{
  m.tube([v(-.137,1.036,.219),v(-.168,1.031,.237),v(-.204,1.030,.234),
    v(-.229,1.031,.227)],[.006,.006,.0045,.0055],10);
  l('black',b=>b.rod(v(-.133,1.043,.202),v(-.137,1.036,.220),.010,12));
},{Hinge:v(-.137,1.036,.219),Cable:v(-.134,1.042,.214)},'Pivot about +Y');
part('Controls','ThumbThrottle',v(.122,1.040,.204),'black',(m,l)=>{
  turn(m,v(.122,1.040,.204),X,.022,.019,18);
  m.tube([v(.120,1.033,.194),v(.124,1.015,.180),v(.136,1.009,.173)],
    [.008,.007,.010],10);
  l('trim',b=>bolt(b,v(.135,1.009,.171),Y,.007));
},{Pivot:v(.122,1.040,.204)},'Rotate about +X');
part('Controls','Display',v(0,1.058,.218),'black',(m,l)=>{
  m.shell([[.184,1.053,.027,.010],[.205,1.059,.036,.012],[.238,1.061,.034,.011],
    [.255,1.061,.024,.008]],16,.60);
  l('screen',b=>b.shell([[.193,1.064,.021,.003],[.208,1.071,.030,.003],
    [.237,1.073,.028,.003],[.247,1.070,.019,.003]],14,.55));
  l('ivory',b=>{for(const x of [-.012,0,.012]) box(b,v(x,1.072,.218),.006,.0015,.009,.0003);});
},{Harness:v(0,1.047,.242),Mount:bars});

for(const [name,p] of [['Front',front],['Rear',rear]]){
  const axle={Axle:p};
  part('Wheels',name+'Tire',p,'rubber',(m,l)=>{
    m.lathe(p,X,[[-.017,.079],[-.025,.089],[-.029,.103],[-.024,.115],[-.015,.123],
      [0,.125],[.015,.123],[.024,.115],[.029,.103],[.025,.089],[.017,.079]],72);
    l('tread',b=>{
      for(let i=0;i<28;i++) for(const s of [-1,1]){
        const t=(i+(s>0?.5:0))*tau/28;
        b.tube([polar(p,s*.004,.1245,t+.05),polar(p,s*.014,.123,t),polar(p,s*.024,.1155,t-.08)],
          [[.001,.002],[.001,.002],[.001,.001]],6,X);
      }
    });
  },axle,'Rotate about +X');
  part('Wheels',name+'Rim',p,'alloy',(m,l)=>{
    m.lathe(p,X,[[-.024,.065],[-.024,.084],[-.020,.087],[-.015,.084],
      [.015,.084],[.020,.087],[.024,.084],[.024,.065]],48);
    if(name==='Front') l('paint',b=>{
      for(let i=0;i<7;i++){
        const t=i*tau/7;
        b.tube([polar(p,0,.020,t),polar(p,0,.050,t+.10),polar(p,0,.074,t+.16)],
          [[.013,.012],[.010,.010],[.008,.010]],8,X);
      }
    });
  },axle,'Rotate about +X');
}
part('Wheels','FrontHub',front,'paint',(m,l)=>{
  turn(m,front,X,.071,.024,28);
  l('alloy',b=>{for(const x of [-.043,.043]) turn(b,offset(front,x),X,.012,.012);});
},{Axle:front},'Rotate about +X');
part('Motor','RearHubMotor',rear,'paint',(m,l)=>{
  m.lathe(rear,X,[[-.032,.013],[-.032,.056],[-.024,.067],[.024,.067],[.032,.056],[.032,.013]],48);
  l('alloy',b=>{for(const x of [-.033,.033]) for(let i=0;i<8;i++) bolt(b,polar(rear,x,.049,i*tau/8),X,.003);});
},{Axle:rear,PhaseCable:offset(rear,.045)},'Driven hub housing');
part('Motor','MotorStator',rear,'copper',(m,l)=>{
  m.lathe(rear,X,[[-.016,.018],[-.016,.041],[.016,.041],[.016,.018]],36);
  for(let i=0;i<18;i++){
    const t=i*tau/18;
    m.rod(polar(rear,-.016,.042,t),polar(rear,.016,.042,t),.005,8);
  }
  l('steel',b=>turn(b,rear,X,.052,.019));
},{Axle:rear,PhaseCable:offset(rear,.034)},'Expose by removing rear hub shell');
part('Brakes','FrontBrakeDisc',front,'steel',(m,l)=>{
  const p=offset(front,-.037);
  m.lathe(p,X,[[-.0015,.044],[-.0015,.063],[.0015,.063],[.0015,.044]],48,
    (i,j)=>j===1||j===2?.001*Math.cos(i*tau/8):0);
  l('paint',b=>{
    for(let i=0;i<5;i++){
      const t=i*tau/5;
      b.tube([polar(front,-.039,.018,t),polar(front,-.039,.037,t+.16),polar(front,-.039,.048,t+.20)],
        [.005,.005,.0045],8);
    }
  });
},{Axle:front},'Rotate about +X');
part('Brakes','FrontCaliper',v(-.040,.173,.439),'black',(m,l)=>{
  for(const x of [-.047,-.031]) box(m,v(x,.175,.431),.012,.035,.028,.003);
  m.rod(v(-.055,.185,.428),v(-.026,.185,.428),.009,10);
  l('alloy',b=>bolt(b,v(-.057,.181,.429),X,.004));
},{Mount:v(-.051,.173,.435),Cable:v(-.045,.192,.427)});

for(const [name,p,range] of [['FrontFender',front,[-.88,.81]],['RearFender',rear,[-.81,1.16]]]){
  const pivot=add(p,[0,.137,0]);
  part('Bodywork',name,pivot,'black',(m,l)=>{
    const sections=Array.from({length:19},(_,i)=>{
      const t=i/18, angle=range[0]+(range[1]-range[0])*t;
      return [-(p[2]+.138*Math.sin(angle)),p[1]+.138*Math.cos(angle),
        .033+.006*Math.sin(t*Math.PI),.005];
    });
    m.shell(sections.reverse(),14,.55);
    if(name==='RearFender') l('paint',b=>{for(const s of [-1,1]){
      b.rod(offset(rear,s*.048),v(s*.034,.237,-.545),.004,8);
    }});
  },{FenderMount:pivot,WheelAxle:p});
}
part('Bodywork','Kickstand',v(-.086,.114,-.185),'paint',(m,l)=>{
  m.tube([v(-.086,.114,-.185),v(-.114,.080,-.184),v(-.164,.026,-.169)],
    [.010,.008,.007],12);
  box(m,v(-.166,.025,-.169),.025,.007,.027);
  l('alloy',b=>bolt(b,v(-.098,.114,-.185),X,.006));
},{Pivot:v(-.086,.114,-.185)},'Fold about +X');
part('Electrical','Headlamp',v(0,.876,.262),'black',(m,l)=>{
  m.shell([[.240,.878,.029,.020],[.262,.877,.040,.021],[.282,.875,.039,.020]],16,.50);
  l('ivory',b=>b.shell([[.279,.876,.036,.016],[.285,.876,.034,.015]],16,.57));
},{Mount:v(0,.876,.252),Connector:v(0,.875,.241)});
part('Electrical','TailLamp',v(0,.216,-.572),'red',(m,l)=>{
  m.shell([[-.590,.212,.027,.009],[-.583,.214,.034,.010],[-.570,.218,.031,.009]],14,.54);
  l('black',b=>box(b,v(0,.216,-.566),.063,.021,.011));
},{Mount:v(0,.219,-.565),Connector:v(0,.215,-.563)});
part('Electrical','BatteryPack',battery,'black',(m,l)=>{
  box(m,v(0,.112,-.031),.145,.055,.331,.005);
  l('trim',b=>{for(const z of [-.161,.099]) box(b,v(0,.140,z),.139,.004,.024);});
  l('alloy',b=>box(b,v(0,.144,-.033),.044,.002,.078,.001));
},{Bay:battery,Connector:v(.048,.123,.143),Grip:v(0,.140,-.043)},'Disconnect and remove battery pack');
part('Electrical','BatteryCells',battery,'cell',(m,l)=>{
  for(let row=0;row<3;row++) for(let i=0;i<10;i++){
    const p=v(-.045+.045*row,.110,-.170+i*.030);
    turn(m,p,X,.039,.012,14);
    l('steel',b=>{for(const s of [-1,1]) turn(b,offset(p,s*.020),X,.002,.008,14);});
  }
},{BatteryBay:battery},'Expose cell modules by removing the pack enclosure');
part('Electrical','ControllerHousing',controller,'alloy',(m,l)=>{
  box(m,controller,.136,.043,.080,.004);
  for(let i=0;i<8;i++) box(m,add(controller,[-.060+i*.017,.022,0]),.005,.010,.073,.001);
  l('black',b=>box(b,add(controller,[0,-.003,.041]),.131,.033,.007));
},{Mount:controller,Motor:v(.053,.131,.192),Power:v(.045,.132,.187)},'Remove heat sink housing');
part('Electrical','ControllerBoard',controller,'pcb',(m,l)=>{
  box(m,add(controller,[0,-.011,0]),.119,.003,.066,.002);
  l('black',b=>{
    for(let i=0;i<6;i++) box(b,add(controller,[-.046+i*.018,-.004,-.014]),.010,.009,.014);
    for(const x of [-.032,-.013,.011]) turn(b,add(controller,[x,0,.014]),Y,.013,.006,12);
  });
  l('copper',b=>{for(let i=0;i<6;i++) box(b,add(controller,[-.045+i*.018,-.007,.030]),.006,.005,.006);});
},{Connector:v(.043,.126,.194)},'Service after removing controller housing');
part('Electrical','ChargePort',v(.099,.123,.171),'black',(m,l)=>{
  turn(m,v(.098,.123,.171),X,.015,.014,18);
  l('copper',b=>turn(b,v(.104,.123,.171),X,.006,.006,16));
  l('trim',b=>b.rod(v(.102,.131,.156),v(.111,.145,.157),.004,9));
},{Plug:v(.108,.123,.171)});
part('Electrical','WiringHarness',hinge,'tread',(m,l)=>{
  m.tube([v(-.134,1.042,.214),v(-.076,1.007,.218),v(-.027,.867,.227),v(-.024,.479,.286),
    v(-.047,.315,.330),v(-.070,.230,.294),v(-.060,.135,.247)],
    [.003,.003,.003,.003,.003,.003,.003],8);
  m.tube([v(.053,.131,.192),v(.071,.122,.090),v(.071,.119,-.236),
    v(.066,.134,-.320),v(.054,.140,-.405),offset(rear,.045)],
    [.004,.004,.004,.004,.004,.004],8);
  l('trim',b=>b.rod(v(.045,.132,.187),v(.048,.123,.143),.003,8));
},{Controller:v(.053,.131,.192),Motor:offset(rear,.045),Display:v(-.134,1.042,.214)});
