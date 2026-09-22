import {spawn,spawnSync} from 'node:child_process';
import {createInterface} from 'node:readline';
import {createReadStream,mkdtempSync,openSync,closeSync,rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {resolve,join,delimiter} from 'node:path';
import fs from 'node:fs';

const moduleName=process.argv[2]??'Init.Prelude';
const expectedArg=process.argv[3];
const maxRootsArg=process.argv[4]??process.env.PSKERNEL_BATCH_ROOTS??'4000';
const maxRoots=Number(maxRootsArg);
const rangeStart=process.argv[5]===undefined?0:Number(process.argv[5]);
const rangeCount=process.argv[6]===undefined?0:Number(process.argv[6]);
const expectedTotalBatches=process.argv[7]===undefined?null:Number(process.argv[7]);
if(!Number.isSafeInteger(maxRoots)||maxRoots<=0)throw new Error(`batch-stream-oracle: invalid maxRoots ${maxRootsArg}`);
if(!Number.isSafeInteger(rangeStart)||rangeStart<0||!Number.isSafeInteger(rangeCount)||rangeCount<0)throw new Error('batch-stream-oracle: invalid batch range');
if(expectedTotalBatches!==null&&(!Number.isSafeInteger(expectedTotalBatches)||expectedTotalBatches<=0))throw new Error('batch-stream-oracle: invalid expected total batch count');

const candidates=[process.env.LEAN434_BIN,'/mnt/data/work/lean4src/lean4-4.34.0/build/release/stage1/bin',...(process.env.PATH??'').split(delimiter)]
  .filter(Boolean).map(p=>resolve(p));
const bin=candidates.find(p=>fs.existsSync(join(p,'lean')));
if(!bin)throw new Error('batch-stream-oracle: set LEAN434_BIN or put Lean 4.34 on PATH');
const lean=join(bin,'lean');
const envVars={...process.env,PATH:`${bin}:${process.env.PATH??''}`};
const workerHeapMiB=Number(process.env.PSKERNEL_WORKER_HEAP_MIB??'4096');
if(!Number.isSafeInteger(workerHeapMiB)||workerHeapMiB<512)throw new Error(`batch-stream-oracle: invalid PSKERNEL_WORKER_HEAP_MIB ${process.env.PSKERNEL_WORKER_HEAP_MIB}`);

const manifestRun=spawnSync(lean,['--run','oracle/replay-probe/DependencyExport.lean',moduleName,'--batch-manifest',String(maxRoots)],{
  cwd:resolve('.'),env:envVars,encoding:'utf8',maxBuffer:16*1024*1024
});
if(manifestRun.error)throw manifestRun.error;
if(manifestRun.status!==0)throw new Error(`Lean manifest exporter exited ${manifestRun.status}: ${manifestRun.stderr}`);
let manifest;
try{manifest=JSON.parse(manifestRun.stdout.trim()).environment;}catch{throw new Error(`invalid batch manifest: ${manifestRun.stdout.slice(0,500)}`);}
if(!manifest)throw new Error('missing batch manifest environment');
const totalBatches=Number(manifest.batches);
const environmentConstants=Number(manifest.constants);
const batchSizes=manifest.batchSizes.map(Number);
if(batchSizes.length!==totalBatches)throw new Error(`manifest batchSizes length ${batchSizes.length} != batches ${totalBatches}`);
if(expectedTotalBatches!==null&&totalBatches!==expectedTotalBatches)throw new Error(`exporter batch count ${totalBatches} != expected ${expectedTotalBatches}`);
const expected=expectedArg?Number(expectedArg):environmentConstants;
if(environmentConstants!==expected)throw new Error(`exporter constant count ${environmentConstants} != expected ${expected}`);
const rangeStop=rangeCount===0?totalBatches:Math.min(totalBatches,rangeStart+rangeCount);
if(rangeStart>=totalBatches)throw new Error(`batch range starts at ${rangeStart}, but only ${totalBatches} batches exist`);
const selectedRoots=batchSizes.slice(rangeStart,rangeStop).reduce((a,b)=>a+b,0);

const tmp=mkdtempSync(join(tmpdir(),'pskernel-batches-'));
let batches=0,directRoots=0,totalRecords=0,totalDecls=0,totalReplayConstants=0,maxBatchConstants=0,maxWorkerRssMiB=0;

async function readMarkers(path){
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
async function exportBatch(index,path){
  const fd=openSync(path,'w');
  const child=spawn(lean,['--run','oracle/replay-probe/DependencyExport.lean',moduleName,'--batch-range',String(maxRoots),String(index),'1'],{
    cwd:resolve('.'),env:envVars,stdio:['ignore',fd,'pipe']
  });
  let stderr='';child.stderr.setEncoding('utf8');child.stderr.on('data',d=>stderr+=d);
  const [code,signal]=await new Promise(r=>child.on('close',(c,s)=>r([c,s])));
  closeSync(fd);
  if(code!==0||signal)throw new Error(`batch ${index} Lean exporter exited code=${code} signal=${signal??'none'}\n${stderr}`);
}
async function replayBatch(index,path){
  const fd=openSync(path,'r');
  const child=spawn(process.execPath,['--expose-gc',`--max-old-space-size=${workerHeapMiB}`,'scripts/batch-replay-worker.mjs'],{cwd:resolve('.'),stdio:[fd,'pipe','pipe']});
  let out='',err='';child.stdout.setEncoding('utf8');child.stdout.on('data',d=>out+=d);child.stderr.setEncoding('utf8');child.stderr.on('data',d=>err+=d);
  const [code,signal]=await new Promise(r=>child.on('close',(c,s)=>r([c,s])));
  closeSync(fd);
  if(code!==0||signal)throw new Error(`batch ${index} replay worker exited code=${code} signal=${signal??'none'}\n${err}`);
  try{return JSON.parse(out.trim());}catch{throw new Error(`batch ${index} invalid worker summary: ${out}\n${err}`);}
}

try{
  for(let index=rangeStart;index<rangeStop;index++){
    const file=join(tmp,`batch-${index}.ndjson`);
    await exportBatch(index,file); // Lean exits here; its large heap is reclaimed before TS replay starts.
    const {environment,batch}=await readMarkers(file);
    if(!environment||!batch)throw new Error(`batch ${index} missing export markers`);
    if(Number(batch.index)!==index)throw new Error(`requested batch ${index}, exporter emitted ${batch.index}`);
    if(Number(batch.directRoots)!==batchSizes[index])throw new Error(`batch ${index} direct roots ${batch.directRoots} != manifest ${batchSizes[index]}`);
    batches++;directRoots+=Number(batch.directRoots);
    console.error(`[batch-stream] batch=${index}/${totalBatches} selected=${batches}/${rangeStop-rangeStart} roots=${directRoots}/${selectedRoots} modules=${batch.firstModule}..${batch.lastModule}`);
    const summary=await replayBatch(index,file);
    totalRecords+=summary.stats.lines;
    totalDecls+=summary.stats.declarations;
    totalReplayConstants+=summary.constants;
    maxBatchConstants=Math.max(maxBatchConstants,summary.constants);
    maxWorkerRssMiB=Math.max(maxWorkerRssMiB,summary.maxRssMiB);
    rmSync(file,{force:true});
  }
} finally { rmSync(tmp,{recursive:true,force:true}); }

if(batches!==rangeStop-rangeStart)throw new Error(`observed batches ${batches} != selected batches ${rangeStop-rangeStart}`);
if(directRoots!==selectedRoots)throw new Error(`direct root coverage ${directRoots} != selected direct roots ${selectedRoots}`);
console.log(JSON.stringify({
  ok:true,module:moduleName,modules:Number(manifest.modules),totalBatches,batches,maxRoots,rangeStart,rangeStop,directRoots,environmentConstants,
  records:totalRecords,declarations:totalDecls,totalReplayConstants,maxBatchConstants,workerHeapMiB,maxWorkerRssMiB:Number(maxWorkerRssMiB.toFixed(1))
},null,2));
