import {spawn,spawnSync} from 'node:child_process';
import {createReadStream,mkdtempSync,openSync,closeSync,rmSync} from 'node:fs';
import {createInterface} from 'node:readline';
import {tmpdir} from 'node:os';
import {resolve,join,delimiter} from 'node:path';
import fs from 'node:fs';

const moduleName=process.argv[2]??'Std';
const expected=Number(process.argv[3]??'114029');
const rootStart=Number(process.argv[4]??'0');
const rootCount=Number(process.argv[5]??String(expected));
const baseChunk=Number(process.argv[6]??process.env.PSKERNEL_BASE_ROOTS??'500');
const minChunk=Number(process.argv[7]??process.env.PSKERNEL_MIN_ROOTS??'25');
for(const [n,v] of Object.entries({expected,rootStart,rootCount,baseChunk,minChunk})){
  if(!Number.isSafeInteger(v)||v<0||(n!=='rootStart'&&v===0))throw new Error(`adaptive-root-oracle: invalid ${n}=${v}`);
}
if(minChunk>baseChunk)throw new Error('adaptive-root-oracle: minChunk must be <= baseChunk');

const candidates=[process.env.LEAN434_BIN,'/mnt/data/work/lean4src/lean4-4.34.0/build/release/stage1/bin',...(process.env.PATH??'').split(delimiter)]
  .filter(Boolean).map(p=>resolve(p));
const bin=candidates.find(p=>fs.existsSync(join(p,'lean')));
if(!bin)throw new Error('adaptive-root-oracle: set LEAN434_BIN or put Lean 4.34 on PATH');
const lean=join(bin,'lean');
const envVars={...process.env,PATH:`${bin}:${process.env.PATH??''}`};
const workerHeapMiB=Number(process.env.PSKERNEL_WORKER_HEAP_MIB??'4096');
const workerTimeoutMs=Number(process.env.PSKERNEL_WORKER_TIMEOUT_MS??'90000');
if(!Number.isSafeInteger(workerTimeoutMs)||workerTimeoutMs<10000)throw new Error(`adaptive-root-oracle: invalid PSKERNEL_WORKER_TIMEOUT_MS ${process.env.PSKERNEL_WORKER_TIMEOUT_MS}`);
const tmp=mkdtempSync(join(tmpdir(),'pskernel-adaptive-'));
let attempts=0,leaves=0,directRoots=0,totalRecords=0,totalDecls=0,totalReplayConstants=0,maxBatchConstants=0,maxWorkerRssMiB=0,maxDepth=0;

function runExport(start,count,path){
  const fd=openSync(path,'w');
  const r=spawnSync(lean,['--run','oracle/replay-probe/DependencyExport.lean',moduleName,'--root-range',String(start),String(count)],{
    cwd:resolve('.'),env:envVars,stdio:['ignore',fd,'pipe'],encoding:'utf8'
  });
  closeSync(fd);
  if(r.error)throw r.error;
  if(r.status!==0||r.signal)throw new Error(`root ${start}+${count} exporter failed code=${r.status} signal=${r.signal??'none'}\n${r.stderr??''}`);
}
async function inspect(path){
  const rl=createInterface({input:createReadStream(path),crlfDelay:Infinity});
  let environment=null,batch=null;
  for await(const line of rl){
    if(!line.trim())continue;
    let x;try{x=JSON.parse(line);}catch{continue;}
    if(x.environment)environment=x.environment;
    if(x.batch){batch=x.batch;break;}
  }
  rl.close();
  return {environment,batch};
}
async function runWorker(path){
  const fd=openSync(path,'r');
  const child=spawn(process.execPath,['--expose-gc',`--max-old-space-size=${workerHeapMiB}`,'scripts/batch-replay-worker.mjs'],{
    cwd:resolve('.'),stdio:[fd,'pipe','pipe']
  });
  let out='',err='';child.stdout.setEncoding('utf8');child.stdout.on('data',d=>out+=d);child.stderr.setEncoding('utf8');child.stderr.on('data',d=>err+=d);
  let timedOut=false;
  const timer=setTimeout(()=>{timedOut=true;child.kill('SIGKILL');},workerTimeoutMs);
  const [code,signal]=await new Promise(r=>child.on('close',(c,s)=>r([c,s])));
  clearTimeout(timer);
  closeSync(fd);
  if(code===0&&!signal&&!timedOut){
    let summary;try{summary=JSON.parse(out.trim());}catch{throw new Error(`invalid worker summary: ${out}\n${err}`);}
    return {ok:true,summary};
  }
  const oom=/heap out of memory|Allocation failed|Reached heap limit|CALL_AND_RETRY_LAST/i.test(err)||signal==='SIGABRT';
  return {ok:false,oversized:oom||timedOut,oom,timedOut,code,signal,err};
}
async function verify(start,count,depth=0){
  attempts++;maxDepth=Math.max(maxDepth,depth);
  const path=join(tmp,`roots-${start}-${count}.ndjson`);
  runExport(start,count,path);
  const {environment,batch}=await inspect(path);
  if(!environment||!batch)throw new Error(`root ${start}+${count}: missing export markers`);
  if(Number(environment.constants)!==expected)throw new Error(`environment constants ${environment.constants} != expected ${expected}`);
  const actual=Number(batch.directRoots);
  if(actual!==Math.min(count,expected-start))throw new Error(`root ${start}+${count}: direct roots ${actual} mismatch`);
  console.error(`[adaptive] try start=${start} count=${actual} depth=${depth} modules=${batch.firstModule}..${batch.lastModule}`);
  const result=await runWorker(path);
  rmSync(path,{force:true});
  if(result.ok){
    const s=result.summary;leaves++;directRoots+=actual;totalRecords+=s.stats.lines;totalDecls+=s.stats.declarations;totalReplayConstants+=s.constants;
    maxBatchConstants=Math.max(maxBatchConstants,s.constants);maxWorkerRssMiB=Math.max(maxWorkerRssMiB,s.maxRssMiB);
    console.error(`[adaptive] PASS start=${start} count=${actual} constants=${s.constants} rssMiB=${s.maxRssMiB}`);
    return;
  }
  if(!result.oversized)throw new Error(`root ${start}+${actual} replay failed code=${result.code} signal=${result.signal??'none'}\n${result.err}`);
  const reason=result.timedOut?'timeout':'OOM';
  if(actual<=minChunk)throw new Error(`root ${start}+${actual} still ${reason} at minimum chunk ${minChunk}\n${result.err}`);
  const left=Math.max(1,Math.floor(actual/2));
  const right=actual-left;
  console.error(`[adaptive] ${reason} start=${start} count=${actual}; split ${left}+${right}`);
  await verify(start,left,depth+1);
  if(right>0)await verify(start+left,right,depth+1);
}

try{
  const stop=Math.min(expected,rootStart+rootCount);
  if(rootStart>=stop)throw new Error(`empty root interval ${rootStart}..${stop}`);
  for(let start=rootStart;start<stop;start+=baseChunk){
    await verify(start,Math.min(baseChunk,stop-start),0);
  }
  if(directRoots!==stop-rootStart)throw new Error(`coverage ${directRoots} != expected interval ${stop-rootStart}`);
  console.log(JSON.stringify({ok:true,module:moduleName,rootStart,rootStop:stop,directRoots,attempts,leaves,maxDepth,baseChunk,minChunk,workerHeapMiB,workerTimeoutMs,totalRecords,totalDecls,totalReplayConstants,maxBatchConstants,maxWorkerRssMiB:Number(maxWorkerRssMiB.toFixed(1))},null,2));
} finally { rmSync(tmp,{recursive:true,force:true}); }
