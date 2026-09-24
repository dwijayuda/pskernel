import {spawn} from 'node:child_process';
import {createInterface} from 'node:readline';
import {resolve,join,delimiter} from 'node:path';
import fs from 'node:fs';

const target=Number(process.argv[2]??'2400');
const candidates=[process.env.LEAN434_BIN,...(process.env.PATH??'').split(delimiter)].filter(Boolean).map(p=>resolve(p));
const leanExe=process.platform==='win32'?'lean.exe':'lean';
const bin=candidates.find(p=>fs.existsSync(join(p,leanExe)));
if(!bin)throw new Error('missing Lean 4.34 bin');
const lean=join(bin,leanExe);
const env={...process.env,PATH:`${bin}${delimiter}${process.env.PATH??''}`};
const child=spawn(lean,['--run','oracle/replay-probe/DependencyExport.lean','Std','--module-stream'],{cwd:resolve('.'),env,stdio:['ignore','pipe','pipe']});
const rl=createInterface({input:child.stdout,crlfDelay:Infinity});
let shards=0,records=0,stopped=false;
const t0=Date.now();
for await(const line of rl){
  records++;
  let x;try{x=JSON.parse(line);}catch{continue;}
  if(x?.shard){
    shards++;
    if(shards===1||shards%25===0)console.error(`[export-speed] shard=${shards} elapsedSec=${((Date.now()-t0)/1000).toFixed(1)} module=${x.shard.module} part=${x.shard.part??0}`);
    if(shards>=target){
      stopped=true;
      child.kill('SIGTERM');
      break;
    }
  }
}
const [code,signal]=await new Promise(r=>child.on('close',(c,s)=>r([c,s])));
if(!stopped)throw new Error(`export ended early code=${code} signal=${signal??'none'} shards=${shards}`);
console.log(JSON.stringify({ok:true,target,shards,records,elapsedSec:Number(((Date.now()-t0)/1000).toFixed(1)),termination:signal??code},null,2));
