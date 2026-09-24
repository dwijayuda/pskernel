import {spawn} from 'node:child_process';
import {createInterface} from 'node:readline';
import {delimiter,join} from 'node:path';

const bin=process.env.LEAN434_BIN;
if(!bin)throw new Error('LEAN434_BIN missing');
const lean=join(bin,process.platform==='win32'?'lean.exe':'lean');
const env={...process.env,PATH:`${bin}${delimiter}${process.env.PATH??''}`};
const stop=2400;
const start=Date.now();
const child=spawn(lean,['--run','oracle/replay-probe/DependencyExport.lean','Std','--module-stream'],{env,stdio:['ignore','pipe','pipe']});
const rl=createInterface({input:child.stdout,crlfDelay:Infinity});
let shards=0,last=null,header=null,killed=false,stderr='';
child.stderr.setEncoding('utf8');child.stderr.on('data',d=>stderr+=d);
for await(const line of rl){
  if(!line.trim())continue;
  let x;try{x=JSON.parse(line);}catch{continue;}
  if(x.environment)header=x.environment;
  if(x.shard){
    if(shards===stop){
      killed=true;
      child.kill('SIGTERM');
      break;
    }
    shards++;
    last=x.shard;
    if(shards===1||shards%25===0){
      console.error(`[export-prefix] shard=${shards}/${header?.plannedShards??'?'} module=${last.module} part=${last.part} elapsedSec=${((Date.now()-start)/1000).toFixed(3)}`);
    }
  }
}
const [code,signal]=await new Promise(r=>child.on('close',(c,s)=>r([c,s])));
if(shards!==stop)throw new Error(`exporter stopped at shard ${shards}, expected ${stop}; code=${code} signal=${signal??'none'}\n${stderr}`);
console.log(JSON.stringify({ok:true,exporterOnly:true,shards,last,elapsedSec:Number(((Date.now()-start)/1000).toFixed(3)),killed,code,signal},null,2));
