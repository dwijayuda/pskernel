import {spawn} from 'node:child_process';
import {createInterface} from 'node:readline';
import {delimiter,join,resolve} from 'node:path';
import fs from 'node:fs';

const target=Number(process.argv[2]??'2400');
const moduleName=process.argv[3]??'Std';
const candidates=[process.env.LEAN434_BIN,...(process.env.PATH??'').split(delimiter)].filter(Boolean).map(resolve);
const lean=candidates.map(p=>join(p,process.platform==='win32'?'lean.exe':'lean')).find(fs.existsSync);
if(!lean)throw new Error('Lean 4.34 binary not found');
const child=spawn(lean,['--run','oracle/replay-probe/DependencyExport.lean',moduleName,'--module-stream'],{cwd:resolve('.'),env:{...process.env,PATH:`${resolve(lean,'..')}${delimiter}${process.env.PATH??''}`},stdio:['ignore','pipe','pipe']});
const rl=createInterface({input:child.stdout,crlfDelay:Infinity});
let stderr='';child.stderr.setEncoding('utf8');child.stderr.on('data',d=>stderr+=d);
let shards=0,last=null,started=Date.now(),reached=false;
for await(const line of rl){
  if(!line.trim())continue;
  let x;try{x=JSON.parse(line);}catch{continue;}
  if(x?.shard){
    shards++;last=x.shard;
    if(shards===1||shards%25===0){
      console.error(`[prefix] shard=${shards} module=${x.shard.module} part=${x.shard.part} elapsedSec=${((Date.now()-started)/1000).toFixed(1)}`);
    }
    if(shards>=target){
      reached=true;child.kill('SIGTERM');break;
    }
  }
}
const code=await new Promise(r=>child.on('close',r));
if(!reached)throw new Error(`exporter stopped before target: shards=${shards} code=${code}\n${stderr}`);
console.log(JSON.stringify({ok:true,target,shards,last,elapsedSec:Number(((Date.now()-started)/1000).toFixed(1))}));
