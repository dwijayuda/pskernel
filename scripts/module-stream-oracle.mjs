import {spawn} from 'node:child_process';
import {createInterface} from 'node:readline';
import {resolve, join, delimiter} from 'node:path';
import fs from 'node:fs';
import {Environment} from '../dist/src/core/environment.js';
import {Lean4ExportReplay} from '../dist/src/integration/lean4export.js';

const moduleName=process.argv[2]??'Init.Prelude';
const expectedArg=process.argv[3];
const candidates=[process.env.LEAN434_BIN,'/mnt/data/work/lean4src/lean4-4.34.0/build/release/stage1/bin',...(process.env.PATH??'').split(delimiter)].filter(Boolean).map(p=>resolve(p));
const leanExe=process.platform==='win32'?'lean.exe':'lean';
const bin=candidates.find(p=>fs.existsSync(join(p,leanExe)));
if(!bin)throw new Error('module-stream-oracle: set LEAN434_BIN to Lean 4.34.0 bin directory');
const lean=join(bin,leanExe);
const envVars={...process.env,PATH:`${bin}${delimiter}${process.env.PATH??''}`};
const child=spawn(lean,['--run','oracle/replay-probe/DependencyExport.lean',moduleName,'--module-stream'],{cwd:resolve('.'),env:envVars,stdio:['ignore','pipe','pipe']});
const rl=createInterface({input:child.stdout,crlfDelay:Infinity});
let stderr='';child.stderr.setEncoding('utf8');child.stderr.on('data',d=>stderr+=d);
const shared=new Environment();
let replay=null,header=null,current=null,shards=0,totalLines=0,totalDecls=0,maxRssMiB=0,maxHeapMiB=0;
let fatal=null;
try{
 for await(const line of rl){
   if(fatal)break;
   if(!line.trim())continue;
   let marker=null;
   try{marker=JSON.parse(line);}catch{}
   if(marker?.environment){
     if(header)throw new Error('duplicate environment header');
     header=marker.environment;
     continue;
   }
   if(marker?.shard){
     if(replay){const s=replay.finish();totalLines+=s.lines;totalDecls+=s.declarations;replay=null;global.gc?.();}
     replay=new Lean4ExportReplay(shared);
     current=marker.shard.module;shards++;
     const mem=process.memoryUsage(),rss=mem.rss/1048576,heap=mem.heapUsed/1048576;maxRssMiB=Math.max(maxRssMiB,rss);maxHeapMiB=Math.max(maxHeapMiB,heap);
     if(shards===1||shards%25===0)console.error(`[module-stream] shard=${shards} module=${current} constants=${shared.size} rssMiB=${rss.toFixed(1)} heapMiB=${heap.toFixed(1)}`);
     continue;
   }
   if(!replay)throw new Error(`record before first shard: ${line.slice(0,120)}`);
   try{replay.replayLine(line);}catch(e){throw new Error(`module ${current}: ${e instanceof Error?e.message:String(e)}`);}
 }
 if(replay){const s=replay.finish();totalLines+=s.lines;totalDecls+=s.declarations;}
}catch(e){fatal=e;child.kill('SIGTERM');}
const code=await new Promise(r=>child.on('close',r));
if(fatal)throw fatal;
if(code!==0)throw new Error(`Lean exporter exited ${code}: ${stderr}`);
if(!header)throw new Error('missing environment header');
const expected=expectedArg?Number(expectedArg):Number(header.constants);
if(Number(header.constants)!==expected)throw new Error(`exporter constant count ${header.constants} != expected ${expected}`);
if(shared.size!==expected)throw new Error(`replayed constants ${shared.size} != expected ${expected}`);
const finalMem=process.memoryUsage();maxRssMiB=Math.max(maxRssMiB,finalMem.rss/1048576);maxHeapMiB=Math.max(maxHeapMiB,finalMem.heapUsed/1048576);
console.log(JSON.stringify({ok:true,module:moduleName,modules:Number(header.modules),shards,records:totalLines,declarations:totalDecls,constants:shared.size,rssMiB:Number((finalMem.rss/1048576).toFixed(1)),heapMiB:Number((finalMem.heapUsed/1048576).toFixed(1)),maxRssMiB:Number(maxRssMiB.toFixed(1)),maxHeapMiB:Number(maxHeapMiB.toFixed(1))},null,2));
