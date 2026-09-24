import {spawn,spawnSync} from 'node:child_process';
import {createInterface} from 'node:readline';
import {resolve,join,delimiter} from 'node:path';
import fs from 'node:fs';

const stopAfter=Number(process.env.PSKERNEL_EXPORT_STOP_AFTER_SHARDS??'2400');
if(!Number.isSafeInteger(stopAfter)||stopAfter<=0)throw new Error('invalid stopAfter');
const candidates=[process.env.LEAN434_BIN,...(process.env.PATH??'').split(delimiter)].filter(Boolean).map(resolve);
const exe=process.platform==='win32'?'lean.exe':'lean';
const bin=candidates.find(p=>fs.existsSync(join(p,exe)));
if(!bin)throw new Error('Lean 4.34 not found');
const lean=join(bin,exe),env={...process.env,PATH:`${bin}${delimiter}${process.env.PATH??''}`};
const v=spawnSync(lean,['--githash'],{encoding:'utf8',env});
if(v.status!==0)throw new Error('Lean identity probe failed');
const started=Date.now();
const child=spawn(lean,['--run','oracle/replay-probe/DependencyExport.lean','Std','--module-stream'],{cwd:resolve('.'),env,stdio:['ignore','pipe','pipe']});
let stderr='',shards=0,lines=0,bytes=0,lastModule='',lastPart=-1;
child.stderr.setEncoding('utf8');child.stderr.on('data',d=>stderr+=d);
const rl=createInterface({input:child.stdout,crlfDelay:Infinity});
for await(const line of rl){
  lines++;bytes+=Buffer.byteLength(line)+1;
  let x=null;try{x=JSON.parse(line);}catch{}
  if(x?.shard){
    shards++;lastModule=x.shard.module;lastPart=x.shard.part??0;
    if(shards===1||shards%25===0)console.error(`[export-only] shard=${shards} module=${lastModule} part=${lastPart} elapsedSec=${((Date.now()-started)/1000).toFixed(1)} MiB=${(bytes/1048576).toFixed(1)}`);
    if(shards>stopAfter){
      child.kill('SIGTERM');break;
    }
  }
}
const [code,signal]=await new Promise(r=>child.on('close',(c,s)=>r([c,s])));
console.log(JSON.stringify({ok:true,diagnostic:true,stopAfter,shardsObserved:Math.min(shards,stopAfter),lines,bytes,elapsedSec:Number(((Date.now()-started)/1000).toFixed(1)),lastModule,lastPart,code,signal},null,2));
