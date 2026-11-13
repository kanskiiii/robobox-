import {writeFileSync} from 'node:fs';

const sampleRate = 48000;
const output = new URL('../audio/', import.meta.url);
const tau = 2 * Math.PI;
const lerp = (a,b,t) => a+(b-a)*t;
const clamp = (x,a,b) => Math.max(a,Math.min(b,x));
const fract = n => n-Math.floor(n);
function rng(seed) {
  return () => {
    seed = (Math.imul(seed,1664525)+1013904223)>>>0;
    return seed/4294967296*2-1;
  };
}
function envelope(t,attack,decay) {
  return (1-Math.exp(-Math.max(0,t)/attack))*Math.exp(-Math.max(0,t)/decay);
}
function write(name, samples, ceiling=.89) {
  const peak=samples.reduce((max,n)=>Math.max(max,Math.abs(n)),0);
  if(!Number.isFinite(peak) || peak===0) throw Error('Invalid signal '+name);
  const gain=peak>ceiling?ceiling/peak:1;
  const buffer=Buffer.alloc(44+samples.length*2);
  buffer.write('RIFF',0); buffer.writeUInt32LE(buffer.length-8,4);
  buffer.write('WAVEfmt ',8); buffer.writeUInt32LE(16,16);
  buffer.writeUInt16LE(1,20); buffer.writeUInt16LE(1,22);
  buffer.writeUInt32LE(sampleRate,24); buffer.writeUInt32LE(sampleRate*2,28);
  buffer.writeUInt16LE(2,32); buffer.writeUInt16LE(16,34);
  buffer.write('data',36); buffer.writeUInt32LE(samples.length*2,40);
  for(let i=0;i<samples.length;i++) buffer.writeInt16LE(Math.round(samples[i]*gain*32767),44+2*i);
  writeFileSync(new URL(name+'.wav',output),buffer);
  return {file:name+'.wav',samples:samples.length,seconds:samples.length/sampleRate,
    peakDbfs:+(20*Math.log10(peak*gain)).toFixed(2),
    rmsDbfs:+(10*Math.log10(samples.reduce((sum,x)=>sum+(x*gain)**2,0)/samples.length)).toFixed(2)};
}

function exhaust(phase, rpm, on) {
  // One firing event per revolution. Use smooth periodic functions so the
  // pressure waveform, exhaust return and overtones repeat across loop seams.
  const a=tau*phase;
  const pulse=Math.exp((on?6.1:4.3)*(Math.cos(a-.38)-1));
  const returnWave=Math.exp(5.3*(Math.cos(a-2.13)-1));
  const pipe=.31*Math.sin(a+.6)+.14*Math.sin(2*a+.1)+.08*Math.sin(3*a-.9);
  let reed=0;
  const limit=Math.min(37,Math.floor(16000/(rpm/60)));
  for(let i=5;i<=limit;i++){
    const frequency=i*rpm/60;
    const center=on?1170:1630;
    const distance=Math.log(frequency/center);
    const resonance=.25+.75*Math.exp(-distance*distance/.66);
    reed+=resonance*Math.sin(i*a+i*.49+Math.sin(i*.83)*1.8)/(i**.94);
  }
  return (pulse-.42*returnWave-.14)*.49+pipe*.51+reed*(on?.70:.53);
}
const cycles = [];
for(const rpm of [1500,5000,8000,10500]) for(const on of [false,true]){
  const n=Math.round(sampleRate*2.4), turns=rpm*n/(sampleRate*60);
  if(!Number.isInteger(turns)) throw Error('Loop does not end on a revolution boundary');
  const noise=rng(rpm+(on?17:31));
  const harmonics=Array.from({length:36},(_,i)=>[i*31+17,noise()*Math.PI,noise()*.0024]);
  const samples=Float64Array.from({length:n},(_,i)=>{
    const t=i/n, a=t*tau;
    const phase=t*turns+(rpm===1500?.050:.014)*Math.sin(3*a)+.009*Math.sin(7*a);
    const shiver=1+.075*Math.sin(4*a-.65)+.037*Math.sin(13*a+.91);
    const grit=harmonics.reduce((sum,[frequency,angle,amp])=>sum+amp*Math.sin(frequency*a+angle),0);
    return exhaust(phase,rpm,on)*shiver*(on?.79:.48)+grit*(on?1.3:1);
  });
  const avg=samples.reduce((sum,n)=>sum+n,0)/n;
  for(let i=0;i<n;i++) samples[i]-=avg;
  const step=Math.abs(samples.at(-1)-samples[0]);
  if(step>0.085) throw Error('Large loop seam '+rpm);
  cycles.push({...write('zefir_'+rpm+'_'+(on?'on':'off'),samples),rpm,throttle:on?'on':'off',
    loop:true,loopStartSample:0,loopEndSample:n,seamStep:+step.toFixed(5)});
}
function event(name,seconds,draw) {
  const noise=rng(name.length*1001);
  let previous=0;
  const samples=Float64Array.from({length:Math.round(sampleRate*seconds)},(_,i)=>{
    const t=i/sampleRate, s=noise(), hiss=s-previous*.70;
    previous=s;
    const fade=clamp(t/.002,0,1)*clamp((seconds-t)/.028,0,1);
    return fade*draw(t,hiss);
  });
  return {...write(name,samples),loop:false};
}
const impact=(t,hiss,tones,decay)=>t<0?0:envelope(t,.0008,decay)*(
  tones.reduce((sum,[f,g])=>sum+g*Math.sin(tau*t*f),0)+hiss*.15);
const transients=[
  event('zefir_kickstart',.78,(t,hiss)=>{
    const mechanical=impact(t-.032,hiss,[[178,.24],[420,.13],[1470,.079]],.044)
      +impact(t-.151,hiss,[[131,.21],[510,.09],[2080,.08]],.032);
    const crank=t-.107;
    if(crank<0) return mechanical;
    const speed=lerp(430,1450,clamp(crank/.29,0,1));
    const phase=(430*crank+(speed-430)*crank*.52)/60;
    const firing=envelope(crank,.063,.18)*exhaust(phase,speed,true)*.74;
    return mechanical+firing;
  }),
  event('zefir_gear_clunk',.24,(t,hiss)=>impact(t-.015,hiss,[[124,.30],[311,.19],[983,.11],[2202,.07]],.039)
    +impact(t-.048,hiss,[[183,.15],[672,.08],[1788,.051]],.025)),
  event('zefir_stall',.67,(t,hiss)=>{
    const phase=25*t-15*t*t;
    const rpm=Math.max(430,1500-1800*t);
    const tick=impact(t-.405,hiss,[[128,.11],[512,.07],[1530,.036]],.041);
    const uneven=.72+.28*Math.sin(tau*fract(phase)*.5);
    return tick+.59*exhaust(phase,rpm,false)*uneven*envelope(t,.012,.18)*clamp((.53-t)/.18,0,1);
  }),
];
const manifest={asset:'zefir-sm50',sampleRate,channels:1,pcmBits:16,source:'Procedural synthesis',
  loops:cycles,events:transients,
  integration:'Crossfade neighbouring RPM loops. Start at a gain of zero and ramp each voice before switching. Blend on/off throttle by load.',
  limitation:'Synthetic development audio. Final vehicle audio requires reference recordings and in-game mixing.'};
writeFileSync(new URL('AUDIO_MANIFEST.json',output),JSON.stringify(manifest,null,2)+'\n');
console.log(JSON.stringify({loops:cycles.length,events:transients.length,maxSeamStep:Math.max(...cycles.map(x=>x.seamStep))}));
