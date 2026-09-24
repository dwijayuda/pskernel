import {spawn,spawnSync} from 'node:child_process';
import {createInterface} from 'node:readline';
import {resolve,join,delimiter} from 'node:path';
import fs from 'node:fs';
import {Environment} from '../dist/src/core/environment.js';
import {LEAN434_PINNED_GITHASH,Lean4ExportReplay} from '../dist/src/integration/lean4export.js';
import {createLeanNativeEvaluator} from './lean-native-evaluator.mjs';

const maxShards=Number(process.argv[2]??'2400');
const explicitGc=process.argv[3]==='gc';
const candidates=[process.env.LEAN434_BIN,...(process.env.PATH??'').split(delimiter)].filter(Boolean).map(p=>resolve(p));
const leanExe=process.platform==='win32'?'lean.exe':'lean';
const bin=candidates.find(p=>fs.existsSync(join(p,leanExe)));
if(!bin)throw new Error('missing Lean 4.34 bin');
const lean=join(bin,leanExe);
const envVars={...process.env,PATH:`${bin}${delimiter}${process.env.PATH??''}`};
const hash=spawnSync(lean,['--githash'],{encoding:'utf8',env:envVars}).stdout?.trim();
if(hash!==LEAN434_PINNED_GITHASH)throw new Error(`Lean hash drift ${hash}`);
const nativeEvaluator=createLeanNativeEvaluator({lean,moduleName:'Std',cwd:resolve('.'),env:envVars});
const child=spawn(lean,['--run','oracle/replay-probe/DependencyExport.lean','Std','--module-stream'],{cwd:resolve('.'),env:envVars,stdio:['ignore','pipe','pipe']});
const rl=createInterface({input:child.stdout,crlfDelay:Infinity});
const shared=new Environment();
let replay=null,shards=0,current=null,stopped=false,stderr='';
const t0=Date.now();
child.stderr.setEncoding('utf8');child.stderr.on('data',d=>stderr+=d);
const finish=()=>{
  if(!replay)return;
  replay.finish();
  replay=null;
  if(explicitGc)global.gc?.();
};
for await(const line of rl){
  if(!line.trim())continue;
  let marker=null;try{marker=JSON.parse(line);}catch{}
  if(marker?.environment)continue;
  if(marker?.shard){
    finish();
    if(shards>=maxShards){
      stopped=true;
      child.kill('SIGTERM');
      break;
    }
    replay=new Lean4ExportReplay(shared,{nativeEvaluator});
    current=marker.shard.module;
    shards++;
    if(shards===1||shards%25===0){
      const mem=process.memoryUsage();
      console.error(`[capped-stream] shard=${shards} elapsedSec=${((Date.now()-t0)/1000).toFixed(1)} module=${current} part=${marker.shard.part??0} constants=${shared.size} rssMiB=${(mem.rss/1048576).toFixed(1)} heapMiB=${(mem.heapUsed/1048576).toFixed(1)} explicitGc=${explicitGc}`);
    }
    continue;
  }
  if(!replay)throw new Error('record before shard');
  replay.replayLine(line);
}
if(replay&&!stopped)finish();
const [code,signal]=await new Promise(r=>child.on('close',(c,s)=>r([c,s])));
if(!stopped)throw new Error(`stream ended before cap code=${code} signal=${signal??'none'} stderr=${stderr}`);
const mem=process.memoryUsage();
console.log(JSON.stringify({ok:true,maxShards,shards,explicitGc,constants:shared.size,elapsedSec:Number(((Date.now()-t0)/1000).toFixed(1)),rssMiB:Number((mem.rss/1048576).toFixed(1)),heapMiB:Number((mem.heapUsed/1048576).toFixed(1))},null,2));
