import {Mesh,v,tau} from '../../../vehicles/sm50/source/geometry.mjs';

export const materials={
  zinc:['Weathered galvanized steel','#959d97',.70,.49,'Metal'],
  concrete:['Weathered cast concrete','#888577',0,.90,'Concrete'],
  wire:['Black steel wire','#303533',.55,.71,'Metal'],
  green:['Old green paint','#495f51',.24,.68,'Metal'],
  wood:['Oiled softwood','#877055',0,.82,'Wood'],
  enamel:['Blue painted steel','#345d70',.30,.52,'Metal'],
  lens:['Frosted lamp lens','#dbd9ba',0,.42,'SmoothPlastic'],
  bark:['Grey brown bark','#6c5b48',0,.95,'Wood'],
  birch:['Pale birch bark','#bbb4a1',0,.91,'Wood'],
  barkMark:['Birch bark fissure','#4b473e',0,.94,'Wood'],
  leaves:['Muted birch leaf green','#586d39',0,.91,'Grass'],
  lightLeaves:['Sun-facing leaf green','#71834b',0,.92,'Grass'],
  shadowLeaves:['Hedgerow leaf green','#465b36',0,.93,'Grass'],
  grass:['Roadside grass','#687345',0,.95,'Grass'],
  rubber:['Old black rubber','#282d28',0,.92,'Rubber'],
};
export const components=[];
export const proxies=[];
const X=[1,0,0],Y=[0,1,0];
const base=(x,z=0)=>v(x,0,z);
export const datums={KitOrigin:base(0),FenceStart:base(-5,-1.5),FenceEnd:base(-5,1.5)};

function part(category,name,pivot,key,draw,attachments={},interaction='Place as modular scenery'){
  const layers={};
  const layer=(mat,fn)=>fn(layers[mat]??=new Mesh());
  layer(key,m=>draw(m,layer));
  components.push({category,name,pivot,layers,attachments,interaction});
}
function box(m,x,y,z,w,h,d,bevel=.004){
  const a=Math.min(bevel,w*.19,h*.19,d*.19);
  m.plate([[y-h/2,z-d/2+a],[y-h/2+a,z-d/2],[y+h/2-a,z-d/2],[y+h/2,z-d/2+a],
    [y+h/2,z+d/2-a],[y+h/2-a,z+d/2],[y-h/2+a,z+d/2],[y-h/2,z+d/2-a]],x,w,a);
}
function proxy(name,target,x,y,z,w,h,d){
  proxies.push({name,target,center:v(x,y,z),size:[w,h,d]});
}
function turn(m,p,axis,w,r,n=12){
  m.lathe(p,axis,[[-w/2,.001],[-w/2,r*.86],[-w*.34,r],[w*.34,r],[w/2,r*.86],[w/2,.001]],n);
}

part('Fences','WireFencePanel',base(-5),'zinc',(m,l)=>{
  for(const z of [-1.50,1.50]){
    m.rod(v(-5,-.045,z),v(-5,1.325,z),.031,12);
    turn(m,v(-5,1.342,z),Y,.030,.035);
    l('concrete',b=>box(b,-5,.035,z,.165,.095,.165));
  }
  for(const y of [.214,1.246]) m.rod(v(-5,y,-1.49),v(-5,y,1.49),.009,8);
  l('wire',b=>{
    for(let j=0;j<30;j++){
      const z=-1.44+j*.098;
      for(const s of [-1,1]){
        const a=Math.max(-1.465,z-.38),k=Math.min(1.465,z+.38);
        const height=t=>Math.max(.220,Math.min(1.241,.735+s*(t-z)*1.35));
        b.rod(v(-4.999,height(a),a),v(-4.999,height(k),k),.0017,5);
      }
    }
  });
},{Start:datums.FenceStart,End:datums.FenceEnd});
proxy('FenceBarrier','WireFencePanel',-5,.75,0,.074,1.22,3);

part('Utilities','ConcreteUtilityPole',base(-1.8),'concrete',(m,l)=>{
  m.tube([v(-1.80,-.08,0),v(-1.80,1.04,0),v(-1.80,5.32,0),v(-1.80,6.27,0)],
    [[.129,.140],[.126,.136],[.091,.107],[.075,.089]],8);
  l('zinc',b=>{
    for(const y of [5.43,5.91]){
      b.rod(v(-2.48,y,0),v(-1.12,y,0),.041,8);
      for(const x of [-2.42,-1.80,-1.18]) b.rod(v(x,y,0),v(x,y+.17,0),.011,10);
    }
  });
  l('wood',b=>{for(const x of [-2.42,-1.80,-1.18]) for(const y of [5.63,6.10]){
    for(const dy of [-.043,0,.043]) turn(b,v(x,y+dy,0),Y,.023,.032,12);
  }});
},{CableTopL:v(-2.42,6.14,0),CableTopC:v(-1.80,6.14,0),CableTopR:v(-1.18,6.14,0)});
proxy('PoleContact','ConcreteUtilityPole',-1.8,2.86,0,.218,5.72,.228);
part('Utilities','OverheadWireSpan',v(-1.8,6.14,2.65),'wire',m=>{
  for(const x of [-2.42,-1.80,-1.18]){
    const points=Array.from({length:17},(_,i)=>{
      const t=i/16;
      return v(x,6.14-.44*4*t*(1-t),2.65+t*8);
    });
    m.tube(points,points.map(()=>.005),6);
  }
},{Start:v(-1.8,6.14,2.65),End:v(-1.8,6.14,10.65)},'Snap to overhead pole cable markers');
part('Utilities','StreetLamp',base(2.1),'zinc',(m,l)=>{
  m.tube([v(2.1,-.03,0),v(2.1,1.04,0),v(2.1,4.45,0),v(2.103,4.78,.071),
    v(2.10,5.02,.353),v(2.10,5.09,.665),v(2.10,5.08,1.09)],
    [.066,.058,.042,.041,.039,.034,.032],14);
  l('concrete',b=>box(b,2.1,.045,0,.258,.109,.258));
  l('green',b=>b.shell([[1.02,5.077,.047,.025,2.1],[1.18,5.087,.106,.037,2.1],
    [1.39,5.085,.111,.033,2.1],[1.48,5.078,.075,.025,2.1]],14,.55));
  l('lens',b=>b.shell([[1.16,5.050,.067,.012,2.1],[1.29,5.050,.095,.016,2.1],
    [1.42,5.050,.073,.010,2.1]],14,.54));
},{LightSource:v(2.1,5.035,1.29),Foot:base(2.1)},'Attach light at diffuser marker');
proxy('LampContact','StreetLamp',2.1,2.35,0,.117,4.7,.117);

part('Storage','WasteDumpster',base(4.2),'green',(m,l)=>{
  m.shell([[-.415,.492,.555,.390,4.2],[-.335,.505,.593,.407,4.2],
    [.332,.505,.593,.407,4.2],[.420,.492,.553,.392,4.2]],16,.27);
  l('zinc',b=>{
    for(const z of [-.420,.420]){
      b.rod(v(3.62,.862,z),v(4.78,.862,z),.025,10);
      for(const x of [3.69,3.84,4.00,4.16,4.31,4.46,4.62,4.76]) {
        b.rod(v(x,.202,z),v(x,.835,z),.011,7);
      }
    }
    b.rod(v(3.58,.958,-.355),v(4.82,.958,-.355),.013,10);
  });
  l('rubber',b=>{for(const x of [3.77,4.63]) for(const z of [-.30,.30]) turn(b,v(x,.072,z),X,.041,.069,16);});
},{LidHinge:v(4.2,.958,-.355),WheelBase:v(4.2,.072,0)},'Static bin or independent lid interaction');
part('Storage','DumpsterLid',v(4.2,.958,-.355),'enamel',(m,l)=>{
  m.shell([[-.391,.945,.592,.020,4.2],[-.262,.974,.606,.041,4.2],[.069,1.011,.608,.035,4.2],
    [.302,.971,.594,.030,4.2],[.421,.930,.559,.024,4.2]],20,.35);
  l('zinc',b=>{
    b.rod(v(4.018,.948,.389),v(4.382,.948,.389),.011,10);
    for(const x of [4.021,4.379]) b.rod(v(x,.944,.348),v(x,.948,.391),.009,8);
  });
},{Hinge:v(4.2,.958,-.355),Handle:v(4.2,.947,.389)},'Pivot about +X');
proxy('DumpsterContact','WasteDumpster',4.2,.465,0,1.13,.88,.83);

function crown(m,x,y,z,w,h,d,seed){
  const sections=[[-.91,.28],[-.54,.79],[-.03,1],[.52,.77],[.93,.22]];
  m.rings(sections.map(([dy,r],j)=>Array.from({length:11},(_,i)=>{
    const a=i*tau/11+(j%2)*.21;
    const noise=.89+.13*Math.sin(seed*13+i*9+j*2);
    return v(x+w*r*noise*Math.sin(a),y+h*dy,z+d*r*noise*Math.cos(a));
  })),{flip:true});
}
part('Vegetation','BirchTree',base(7.8),'birch',(m,l)=>{
  m.tube([v(7.80,-.07,0),v(7.79,.71,.01),v(7.74,2.26,.08),v(7.88,3.70,.04),
    v(7.84,4.76,.14),v(7.96,5.83,.05)],[.151,.123,.101,.072,.037,.014],12);
  for(const [x,z,y,start] of [[6.59,.17,4.76,2.81],[8.86,.52,5.04,3.14],
    [7.77,-.89,4.60,3.17],[7.68,1.02,4.68,3.57],[8.51,-.29,5.61,4.19]]){
    l('bark',b=>b.tube([v(7.82,start,.07),v((x+7.82)*.5,start+.66,z*.44),v(x,y,z)],
      [.047,.026,.010],8));
  }
  l('barkMark',b=>{
    for(let i=0;i<28;i++){
      const y=.17+i*.127,r=.146-i*.0029,t=i*2.39;
      b.rod(v(7.80+r*Math.cos(t),y,r*Math.sin(t)),
        v(7.80+r*Math.cos(t+.36),y+.023,r*Math.sin(t+.36)),.008,6);
    }
  });
  for(const [i,x,y,z,w] of [[0,6.59,4.79,.18,.91],[1,8.88,5.04,.52,.94],
    [2,7.77,4.63,-.92,.85],[3,7.67,4.68,1.08,.77],[4,8.51,5.57,-.29,.86],
    [5,7.73,5.95,.17,.81],[6,7.82,5.17,-.11,1.16]]){
    l(i%2?'leaves':'lightLeaves',b=>crown(b,x,y,z,w,.69,w*.85,i));
  }
},{Trunk:base(7.8),Canopy:v(7.8,5.18,0)});
proxy('BirchTrunk','BirchTree',7.8,1.48,0,.29,2.96,.29);
part('Vegetation','HedgeSegment',base(10.6),'shadowLeaves',(m,l)=>{
  for(let i=0;i<9;i++){
    const z=-1.25+i*.31;
    crown(m,10.6+.12*Math.sin(i),.53+.09*Math.sin(i*.7),z,.42,.53,.44,i);
    l('leaves',b=>crown(b,10.60-.15*Math.sin(i+.8),.85+.10*Math.cos(i),z+.08,.42,.40,.36,i+13));
  }
},{Start:base(10.6,-1.5),End:base(10.6,1.5)});
part('Vegetation','GrassTuft',base(12.15),'grass',(m,l)=>{
  for(let i=0;i<31;i++){
    const t=i*2.39996,r=.012+.012*Math.sqrt(i),h=.085+.04*Math.sin(i*6.11);
    const p=v(12.15+r*Math.cos(t),-.004,r*Math.sin(t));
    const q=v(12.15+(r+.055)*Math.cos(t),h,(r+.055)*Math.sin(t));
    (i%4===0?l('lightLeaves',b=>b.tube([p,q],[[.004,.002],[.0008,.0008]],4)):
      m.tube([p,q],[[.004,.002],[.0008,.0008]],4));
  }
},{Ground:base(12.15)});
