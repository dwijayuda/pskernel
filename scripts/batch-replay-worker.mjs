import {createInterface} from 'node:readline';
import {Environment} from '../dist/src/core/environment.js';
import {Lean4ExportReplay} from '../dist/src/integration/lean4export.js';
import {createLeanNativeEvaluator} from './lean-native-evaluator.mjs';

const shared=new Environment();
const nativeEvaluator=process.env.PSKERNEL_NATIVE_LEAN&&process.env.PSKERNEL_NATIVE_MODULE
  ?createLeanNativeEvaluator({lean:process.env.PSKERNEL_NATIVE_LEAN,moduleName:process.env.PSKERNEL_NATIVE_MODULE,cwd:process.cwd(),env:process.env})
  :undefined;
const rl=createInterface({input:process.stdin,crlfDelay:Infinity});
let replay=null;
let lines=0,names=0,levels=0,expressions=0,declarations=0,segments=0;
let maxRssMiB=process.memoryUsage().rss/1048576;
let physicalLines=0;
const heartbeat=setInterval(()=>{console.error(`[batch-worker] lines=${physicalLines} segments=${segments} constants=${shared.entries().length} rssMiB=${(process.memoryUsage().rss/1048576).toFixed(1)}`);},10000);
heartbeat.unref();
const finishSegment=()=>{
  if(!replay)return;
  const s=replay.finish();
  lines+=s.lines;names+=s.names;levels+=s.levels;expressions+=s.expressions;declarations+=s.declarations;
  replay=null;
  if(global.gc)global.gc();
  const rss=process.memoryUsage().rss/1048576;
  if(rss>maxRssMiB)maxRssMiB=rss;
};
for await(const line of rl){
  if(!line.trim())continue;
  physicalLines++;
  let marker=null;try{marker=JSON.parse(line);}catch{}
  if(marker?.environment||marker?.batch)continue;
  if(marker?.segment){
    finishSegment();
    replay=new Lean4ExportReplay(shared,{nativeEvaluator});
    segments++;
    continue;
  }
  if(!replay)replay=new Lean4ExportReplay(shared,{nativeEvaluator}); // backward-compatible unsegmented batches
  replay.replayLine(line);
  const rss=process.memoryUsage().rss/1048576;
  if(rss>maxRssMiB)maxRssMiB=rss;
}
finishSegment();
clearInterval(heartbeat);
console.log(JSON.stringify({
  stats:{lines,names,levels,expressions,declarations},
  constants:shared.entries().length,
  segments,
  maxRssMiB:Number(maxRssMiB.toFixed(1))
}));
