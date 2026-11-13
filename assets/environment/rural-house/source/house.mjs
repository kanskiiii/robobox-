import {Mesh,v} from '../../../vehicles/sm50/source/geometry.mjs';

export const materials={
  lime:['Warm lime render','#d3c4a6',0,.93,'Plaster'],
  stone:['Grey foundation render','#777671',0,.94,'Concrete'],
  sill:['Cast pale stone','#aeaa98',0,.82,'Concrete'],
  roof:['Red clay roof tile','#914837',0,.85,'ClayRoofTiles'],
  ridge:['Fired ridge tile','#773e35',0,.79,'ClayRoofTiles'],
  dark:['Painted steel rainwater goods','#474944',.42,.62,'Metal'],
  wood:['Stained pine joinery','#704b36',0,.72,'Wood'],
  boards:['Dark brown fascia boards','#53453a',0,.78,'Wood'],
  glass:['Dusty insulated window glazing','#839a97',.07,.20,'Glass',.38],
  curtain:['Cotton curtains','#dcd2ba',0,.91,'Fabric'],
  metal:['Brass fittings','#a18a53',.72,.43,'Metal'],
  brick:['Red brick chimney','#9f5748',0,.95,'Brick'],
  rubble:['Grey courtyard pavers','#908c78',0,.92,'Cobblestone'],
};
export const components=[];
export const proxies=[];
const X=[1,0,0],Y=[0,1,0];
const wallX=3.72, wallZ=2.83, eave=2.78, ridge=4.55;
const door=v(.92,.26,2.87);
export const datums={Door:door,Floor:v(0,.24,0),Front:v(0,.24,wallZ),RoofRidge:v(0,ridge,0)};

function part(category,name,pivot,key,draw,attachments={},interaction='Static scenery'){
  const layers={};
  const layer=(material,fn)=>fn(layers[material]??=new Mesh());
  layer(key,m=>draw(m,layer));
  components.push({category,name,pivot,layers,attachments,interaction});
}
function box(m,x,y,z,w,h,d,bevel=.006){
  const a=Math.min(bevel,w*.17,h*.17,d*.17);
  m.plate([[y-h/2,z-d/2+a],[y-h/2+a,z-d/2],[y+h/2-a,z-d/2],[y+h/2,z-d/2+a],
    [y+h/2,z+d/2-a],[y+h/2-a,z+d/2],[y-h/2+a,z+d/2],[y-h/2,z+d/2-a]],x,w,a);
}
function solid(name,target,x,y,z,w,h,d){
  proxies.push({name,center:v(x,y,z),size:[w,h,d],target});
}
function wallSections(openings,from,to,minY,maxY){
  const xs=[from,...openings.flatMap(([x,w])=>[x-w/2,x+w/2]),to].sort((a,b)=>a-b);
  const ys=[...new Set([minY,...openings.flatMap(([, ,lo,hi])=>[lo,hi]),maxY])].sort((a,b)=>a-b);
  return xs.slice(0,-1).flatMap((x,i)=>ys.slice(0,-1).flatMap((y,j)=>{
    const w=xs[i+1]-x,h=ys[j+1]-y,cx=x+w/2,cy=y+h/2;
    if(openings.some(([u,d,lo,hi])=>Math.abs(cx-u)<d/2 && cy>lo && cy<hi)) return [];
    return [[cx,cy,w,h]];
  }));
}

part('Structure','Foundation',v(0,0,0),'stone',(m,l)=>{
  box(m,0,.12,0,7.70,.24,5.89,.022);
  l('sill',b=>box(b,0,.242,0,7.60,.027,5.78,.008));
  l('rubble',b=>{
    for(let i=0;i<11;i++) for(let j=0;j<4;j++){
      box(b,.03+i*.178,.014,3.15+j*.187,.172,.049,.179,.008);
    }
  });
},{Floor:datums.Floor,Entry:door});
solid('Foundation','Foundation',0,.12,0,7.7,.24,5.89);

const frontOpen=[[-2.16,1.20,1.00,2.09],[-.55,1.06,1.00,2.09],[1.37,.96,.24,2.35],[2.83,1.05,1.00,2.09]];
const rearOpen=[[-2.05,1.17,1.07,2.13],[.12,1.08,1.07,2.13],[2.20,1.17,1.07,2.13]];
for(const [name,z,openings] of [['FrontWall',wallZ,frontOpen],['BackWall',-wallZ,rearOpen]]){
  const sections=wallSections(openings,-wallX,wallX,.24,eave);
  part('Structure',name,v(0,.24,z),'lime',(m,l)=>{
    for(const [x,y,w,h] of sections) box(m,x,y,z,w,h,.237,.001);
    l('stone',b=>{
      for(const [x,w] of z>0?[[-1.43,4.58],[2.78,1.88]]:[[0,7.44]]){
        box(b,x,.346,z+Math.sign(z)*.121,w,.207,.031,.008);
      }
    });
  },name==='FrontWall'?{Door:door}:{});
  for(const [i,[x,y,w,h]] of sections.entries()) solid(name+'_'+i,name,x,y,z,w,h,.237);
}
for(const s of [-1,1]){
  const name=s<0?'GableWest':'GableEast',x=wallX*s;
  part('Structure',name,v(x,.24,0),'lime',(m,l)=>{
    box(m,x,1.510,0,.237,2.54,5.44,.007);
    m.plate([[eave-.038,-2.91],[ridge-.055,0],[eave-.038,2.91]],x,.235,.003);
    l('stone',b=>box(b,x+s*.122,.346,0,.030,.207,5.42,.006));
    l('wood',b=>{
      const cx=x+s*.126;
      for(let i=0;i<5;i++) box(b,cx,3.400+i*.051,0,.041,.025,.309,.004);
      for(const z of [-.182,.182]) box(b,cx,3.505,z,.046,.302,.035,.006);
    });
  },{GablePeak:v(x,ridge,0)});
  solid(name,name,x,1.51,0,.237,2.54,5.44);
}

for(const [side,z,openings] of [['Front',wallZ,frontOpen],['Rear',-wallZ,rearOpen]]){
  let index=0;
  for(const [x,w,lo,hi] of openings){
    if(lo<.5) continue;
    const s=Math.sign(z), depth=z+s*.106, h=hi-lo, y=(lo+hi)/2;
    part('Joinery',side+'Window'+(++index),v(x,y,z),'wood',(m,l)=>{
      for(const dx of [-w*.48,0,w*.48]) box(m,x+dx,y,depth,.041,h,.071);
      for(const dy of [-h*.48,0,h*.48]) box(m,x,y+dy,depth,w,.039,.071);
      l('glass',b=>{for(const sx of [-1,1]) for(const sy of [-1,1]){
        box(b,x+sx*w*.25,y+sy*h*.25,depth+s*.006,w*.465,h*.46,.011,.001);
      }});
      l('curtain',b=>{
        for(const sx of [-1,1]){
          const px=x+sx*w*.348;
          b.tube([v(px,y+.463*h,depth-s*.035),v(px+sx*.032,y,depth-s*.056),
            v(px+sx*.062,y-.458*h,depth-s*.040)],[[.016,.161],[.018,.135],[.016,.101]],12,[0,0,1]);
        }
      });
      l('sill',b=>box(b,x,lo-.024,depth+s*.052,w+.170,.054,.181,.007));
    },{Latch:v(x+.021,y,depth+s*.031)},'Independent window assembly');
  }
}
part('Joinery','EntryFrame',v(1.37,.24,wallZ),'wood',(m,l)=>{
  for(const x of [.911,1.829]) box(m,x,1.283,2.90,.056,2.083,.156,.005);
  box(m,1.37,2.32,2.90,.977,.063,.161);
  l('sill',b=>{
    box(b,1.37,.257,2.995,1.03,.063,.346,.011);
    box(b,1.37,.104,3.182,1.19,.202,.384,.013);
    box(b,1.37,.035,3.438,1.28,.069,.163,.009);
  });
},{DoorHinge:door,Threshold:v(1.37,.287,3.075)});
solid('EntryStep','EntryFrame',1.37,.104,3.182,1.19,.202,.384);
part('Joinery','EntryDoor',door,'wood',(m,l)=>{
  box(m,1.370,1.305,2.918,.844,1.998,.064,.009);
  l('boards',b=>{
    for(const y of [.687,1.294,1.892]) box(b,1.37,y,2.951,.630,.477,.012,.004);
  });
  l('metal',b=>{
    box(b,1.697,1.288,2.956,.044,.109,.010,.005);
    b.rod(v(1.697,1.315,2.953),v(1.697,1.315,3.002),.010,12);
    b.rod(v(1.697,1.315,2.999),v(1.584,1.315,2.999),.011,12);
  });
},{Hinge:door,Handle:v(1.643,1.315,2.999)},'Pivot about +Y to open');

for(const s of [-1,1]){
  const name=s<0?'RoofNorth':'RoofSouth';
  const height=z=>ridge-Math.abs(z)*(ridge-eave)/2.91;
  part('Roof',name,v(0,ridge,0),'roof',(m,l)=>{
    m.plate([[height(s*3.22)-.075,s*3.22],[ridge-.082,0],[ridge-.013,0],
      [height(s*3.22)-.008,s*3.22]],0,8.23,.008);
    l('ridge',b=>{
      for(let i=0;i<17;i++){
        const x=(i-8)*.479;
        for(const [a,k] of [[.014,1.11],[1.11,2.18],[2.18,3.22]]){
          const p=v(x,height(s*a)+.002,s*a), q=v(x,height(s*k)+.002,s*k);
          b.rod(p,q,.021,7);
        }
      }
      for(let i=1;i<12;i++){
        const z=s*i*.271, y=height(z)-.006;
        b.rod(v(-4.104,y,z),v(4.104,y,z),.013,8);
      }
    });
    l('boards',b=>{
      b.rod(v(-4.12,height(3.23)-.095,s*3.22),v(4.12,height(3.23)-.095,s*3.22),.059,8);
      for(const x of [-4.102,4.102]) b.rod(v(x,ridge-.063,0),v(x,height(3.19)-.071,s*3.19),.052,8);
    });
  },{Ridge:v(0,ridge,0),Eave:v(0,height(s*3.22),s*3.22)},'Hide roof half for interior inspection');
}
part('Roof','RidgeCap',datums.RoofRidge,'ridge',m=>{
  for(let i=0;i<16;i++){
    const x=-4.10+i*.516;
    m.rod(v(x,ridge+.015,0),v(x+.501,ridge+.015,0),.053,12);
  }
},{Ridge:datums.RoofRidge});
part('Roof','Chimney',v(-1.84,3.83,-.95),'brick',(m,l)=>{
  box(m,-1.84,4.268,-.95,.47,1.104,.505,.009);
  l('sill',b=>{
    box(b,-1.84,4.796,-.95,.575,.107,.604,.009);
    box(b,-1.84,4.875,-.95,.505,.053,.532,.006);
  });
  l('dark',b=>{
    for(const x of [-1.95,-1.73]) b.lathe(v(x,4.928,-.95),Y,
      [[-.028,.031],[-.028,.050],[.043,.045],[.043,.028]],16);
  });
},{Roof:v(-1.84,3.98,-.95)});
for(const s of [-1,1]){
  const z=s*3.25,x=s*3.92,name=s<0?'RearGutter':'FrontGutter';
  part('Roof',name,v(0,2.50,z),'dark',(m,l)=>{
    m.rod(v(-4.1,2.505,z),v(4.1,2.485,z),.049,14);
    m.tube([v(x,2.497,z),v(x,2.37,z*.96),v(x*.97,2.247,s*2.970),
      v(x*.97,.391,s*2.970),v(x*.96,.248,s*3.035)],[.036,.034,.032,.032,.033],12);
    l('metal',b=>{
      for(const y of [.57,1.30,2.07]) b.lathe(v(x*.97,y,s*2.970),Y,
        [[-.011,.031],[-.011,.039],[.011,.039],[.011,.031]],12);
    });
  },{Drain:v(x*.96,.248,s*3.035)});
}
