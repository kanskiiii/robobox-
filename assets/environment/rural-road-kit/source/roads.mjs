import {Mesh,v,tau} from '../../../vehicles/sm50/source/geometry.mjs';

export const materials={
  asphalt:['Weathered asphalt','#50504b',0,.95,'Asphalt'],
  gravel:['Compacted gravel','#7a7363',0,.97,'Pebble'],
  dirt:['Compacted earth','#785c46',0,.96,'Ground'],
  shoulder:['Roadside turf','#647046',0,.98,'Grass'],
  paint:['Faded white road paint','#ccc7ac',.01,.81,'SmoothPlastic'],
  concrete:['Cast concrete curb','#a39d89',0,.87,'Concrete'],
  paver:['Grey concrete paving blocks','#8c887b',0,.86,'Concrete'],
  paverAlt:['Dark paving blocks','#737467',0,.91,'Concrete'],
  zinc:['Galvanized guardrail steel','#a3a8a4',.80,.37,'Metal'],
  black:['Sign pole boot','#303333',.15,.74,'Plastic'],
  white:['Reflective white sign face','#e8e6d8',.08,.41,'SmoothPlastic'],
  red:['Traffic sign red','#a73230',.08,.46,'SmoothPlastic'],
  amber:['Guardrail reflector','#df9a31',.05,.40,'SmoothPlastic'],
};
export const components=[];
export const proxies=[];
export const datums={StraightStart:v(0,0,-6),StraightEnd:v(0,0,6),CurveStart:v(15,0,-4.5),
  CurveEnd:v(19.5,0,0),JunctionBranch:v(0,0,18),DirtStart:v(29,0,-5),DirtEnd:v(29,0,5)};

function part(category,name,pivot,material,draw,attachments={},interaction='Place as a modular environment asset'){
  const layers={};
  const layer=(key,fn)=>fn(layers[key]??=new Mesh());
  layer(material,m=>draw(m,layer));
  components.push({category,name,pivot,attachments,interaction,layers});
}
function slab(mesh,polygon,top=0,bottom=-.13){
  // Convex X/station polygon in clockwise top view. Smooth edges use separate cap vertices.
  const area=polygon.reduce((n,[x,z],i)=>{
    const [nx,nz]=polygon[(i+1)%polygon.length];
    return n+x*nz-nx*z;
  },0);
  const ordered=area<0?polygon.slice().reverse():polygon;
  mesh.rings([bottom,top].map(y=>ordered.map(([x,z])=>v(x,y,z))));
}
function rect(mesh,x,z,w,d,top=0,bottom=-.13){
  slab(mesh,[[x-w/2,z-d/2],[x+w/2,z-d/2],[x+w/2,z+d/2],[x-w/2,z+d/2]],top,bottom);
}
function proxy(name,x,y,z,w,h,d,target){
  proxies.push({name,center:v(x,y,z),size:[w,h,d],target});
}
function paintDash(mesh,x,z,d){rect(mesh,x,z,.105,d,.003,.0005);}

part('Roads','AsphaltStraight',v(0,0,0),'asphalt',(m,l)=>{
  rect(m,0,0,5.60,12);
  l('gravel',b=>{for(const s of [-1,1]) rect(b,s*3.035,0,.470,12,-.021,-.133);});
  l('paint',b=>{for(const z of [-4.5,-1.5,1.5,4.5]) paintDash(b,0,z,1.24);});
},{Start:datums.StraightStart,End:datums.StraightEnd,LeftEdge:v(-2.8,0,0),RightEdge:v(2.8,0,0)});
proxy('StraightRoadSurface',0,-.064,0,5.60,.128,12,'AsphaltStraight');

part('Roads','AsphaltTurn90',datums.CurveStart,'asphalt',(m,l)=>{
  const center=[19.5,-4.5];
  const pos=(r,a)=>[center[0]+r*Math.cos(a),center[1]+r*Math.sin(a)];
  const panels=(mesh,inner,outer,from,to,top,bottom)=>{
    const a=from,b=to;
    slab(mesh,[pos(outer,a),pos(outer,b),pos(inner,b),pos(inner,a)],top,bottom);
  };
  for(let i=0;i<18;i++){
    const a=Math.PI-(i+1)*Math.PI/36,b=Math.PI-i*Math.PI/36;
    panels(m,1.70,7.30,a,b,0,-.13);
    l('gravel',k=>{panels(k,1.23,1.70,a,b,-.021,-.133);panels(k,7.30,7.77,a,b,-.021,-.133);});
  }
  l('paint',b=>{for(const k of [.10,.38,.66]) panels(b,4.4475,4.5525,Math.PI*(1-k/2-.055),Math.PI*(1-k/2),.003,.0005);});
},{Start:datums.CurveStart,End:datums.CurveEnd,ArcCenter:v(19.5,0,-4.5)},'Use a per-segment or mesh collision shape');

part('Roads','AsphaltTJunction',v(0,0,14),'asphalt',(m,l)=>{
  rect(m,0,12,12,5.60);
  rect(m,0,16.4,5.60,3.2);
  l('gravel',b=>{
    rect(b,0,8.94,12,.50,-.024,-.133);
    for(const s of [-1,1]){
      rect(b,s*4.62,15.08,2.76,.55,-.024,-.133);
      rect(b,s*3.03,16.76,.46,2.48,-.024,-.133);
    }
  });
  l('paint',b=>{
    for(const x of [-4.8,-3.35,3.35,4.8]) rect(b,x,12,.70,.102,.003,.0005);
    for(let i=0;i<8;i++) rect(b,-2.43+i*.28,15.87,.180,.225,.003,.0005);
    paintDash(b,0,17.42,.65);
  });
},{West:v(-6,0,12),East:v(6,0,12),Branch:datums.JunctionBranch});
proxy('JunctionThrough',0,-.064,12,12,.128,5.60,'AsphaltTJunction');
proxy('JunctionBranch',0,-.064,16.4,5.60,.128,3.2,'AsphaltTJunction');

part('Roads','DirtLaneStraight',v(29,0,0),'dirt',(m,l)=>{
  const z=[-5,-3.75,-2.5,-1.25,0,1.25,2.5,3.75,5];
  const edge=(i,s)=>29+s*(1.66+.10*Math.sin(i*1.83+s));
  for(let i=0;i<z.length-1;i++){
    slab(m,[[edge(i,-1),z[i]],[edge(i,1),z[i]],[edge(i+1,1),z[i+1]],[edge(i+1,-1),z[i+1]]],-.019,-.13);
    l('gravel',b=>{
      for(const s of [-1,1]){
        const a=29+s*(.62+.10*Math.sin(i*.88)),k=29+s*(.62+.10*Math.sin((i+1)*.88));
        slab(b,[[a-.23,z[i]],[a+.23,z[i]],[k+.23,z[i+1]],[k-.23,z[i+1]]],-.014,-.018);
      }
    });
    l('shoulder',b=>{
      for(const s of [-1,1]) slab(b,[[edge(i,s),z[i]],[29+s*2.12,z[i]],
        [29+s*2.12,z[i+1]],[edge(i+1,s),z[i+1]]],-.032,-.13);
    });
  }
},{Start:datums.DirtStart,End:datums.DirtEnd},'Join on the lane axis');
proxy('DirtSurface',29,-.073,0,3.23,.11,10,'DirtLaneStraight');

part('Pedestrian','RaisedCurb',v(-4,0,0),'concrete',(m,l)=>{
  for(let i=0;i<12;i++){
    const z=-5.5+i;
    m.plate([[.001,z-.493],[.139,z-.493],[.145,z-.471],[.145,z+.471],[.139,z+.493],[.001,z+.493]],
      -4,.164,.012);
    l('gravel',b=>rect(b,-4,z+.496,.166,.007,.132,.001));
  }
},{Start:v(-4,0,-6),End:v(-4,0,6)});
proxy('CurbSurface',-4,.072,0,.16,.144,12,'RaisedCurb');

part('Pedestrian','SidewalkStraight',v(-5.12,.14,0),'paver',(m,l)=>{
  rect(m,-5.12,0,1.91,12,.131,-.018);
  for(let row=0;row<24;row++) for(let col=0;col<6;col++){
    const key=(row+col*3)%7===0?'paverAlt':'paver';
    l(key,b=>rect(b,-5.909+col*.314,-5.75+row*.50,.303,.487,.149,.130));
  }
  l('concrete',b=>{for(const x of [-6.08,-4.16]) rect(b,x,0,.063,12,.144,-.020);});
},{Start:v(-5.12,.149,-6),End:v(-5.12,.149,6)});
proxy('SidewalkSurface',-5.12,.064,0,1.98,.17,12,'SidewalkStraight');

part('Roadside','GuardrailSegment',v(4,0,0),'zinc',(m,l)=>{
  const section=[[3.930,.663],[3.900,.680],[3.940,.721],[3.893,.762],[3.922,.785],
    [3.942,.768],[3.918,.747],[3.957,.720],[3.920,.685],[3.948,.672]];
  for(const [a,b] of [[-3,-.045],[-.05,3]]){
    m.rings([a,b].map(z=>section.map(([x,y])=>v(x,y,z))));
  }
  for(const z of [-2.6,0,2.6]){
    rect(m,4.025,z,.064,.091,.776,-.055);
    rect(m,3.995,z,.112,.114,.750,.682);
    l('black',b=>rect(b,4.025,z,.101,.125,.009,-.014));
  }
  l('amber',b=>{for(const z of [-2.64,.01,2.58]) rect(b,3.887,z,.011,.091,.774,.729);});
},{Start:v(4,0,-3),End:v(4,0,3),Reflector:v(3.887,.751,0)});
proxy('GuardrailContact',3.97,.72,0,.15,.13,6,'GuardrailSegment');

part('Roadside','YieldSign',v(6.75,0,11.2),'zinc',(m,l)=>{
  m.rod(v(6.75,-.054,11.20),v(6.75,1.91,11.20),.023,12);
  const sign=(mesh,r,depth)=>{
    const polygon=Array.from({length:3},(_,i)=>{
      const a=i*tau/3-Math.PI/2;
      return [6.75+r*Math.cos(a),1.82+r*Math.sin(a)];
    });
    mesh.rings([11.218+depth,11.230+depth].map(z=>polygon.map(([x,y])=>v(x,y,z))),{flip:true});
  };
  sign(m,.379,0);
  l('red',b=>sign(b,.365,.013));
  l('white',b=>sign(b,.267,.024));
  l('concrete',b=>rect(b,6.75,11.20,.21,.21,.026,-.075));
},{Ground:v(6.75,0,11.20),Face:v(6.75,1.82,11.265)});
