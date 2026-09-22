import {spawn} from 'node:child_process';
import {createInterface} from 'node:readline';
import {once} from 'node:events';
import {resolve, join, delimiter} from 'node:path';
import fs from 'node:fs';

const moduleName=process.argv[2]??'Init.Prelude';
const expectedArg=process.argv[3];
const maxRootsArg=process.argv[4]??process.env.PSKERNEL_BATCH_ROOTS??'4000';
const maxRoots=Number(maxRootsArg);
const rangeStartArg=process.argv[5];
const rangeCountArg=process.argv[6];
const rangeStart=rangeStartArg===undefined?0:Number(rangeStartArg);
const rangeCount=rangeCountArg===undefined?0:Number(rangeCountArg);
const expectedBatchesArg=process.argv[7];
const expectedTotalBatches=expectedBatchesArg===undefined?null:Number(expectedBatchesArg);
if(!Number.isSafeInteger(maxRoots)||maxRoots<=0)throw new Error(`batch-stream-oracle: invalid maxRoots ${maxRootsArg}`);
if(!Number.isSafeInteger(rangeStart)||rangeStart<0||!Number.isSafeInteger(rangeCount)||rangeCount<0)throw new Error('batch-stream-oracle: invalid batch range');
if(expectedTotalBatches!==null&&(!Number.isSafeInteger(expectedTotalBatches)||expectedTotalBatches<=0))throw new Error('batch-stream-oracle: invalid expected total batch count');

const candidates=[process.env.LEAN434_BIN,'/mnt/data/work/lean4src/lean4-4.34.0/build/release/stage1/bin',...(process.env.PATH??'').split(delimiter)]
  .filter(Boolean).map(p=>resolve(p));
const bin=candidates.find(p=>fs.existsSync(join(p,'lean')));
if(!bin)throw new Error('batch-stream-oracle: set LEAN434_BIN to Lean 4.34.0 bin directory');
const lean=join(bin,'lean');
const envVars={...process.env,PATH:`${bin}:${process.env.PATH??''}`};
const exportArgs=rangeCount>0||rangeStart>0?['--run','oracle/replay-probe/DependencyExport.lean',moduleName,'--batch-range',String(maxRoots),String(rangeStart),String(rangeCount)]:['--run','oracle/replay-probe/DependencyExport.lean',moduleName,'--batch-stream',String(maxRoots)];
const exporter=spawn(lean,exportArgs,{
  cwd:resolve('.'),env:envVars,stdio:['ignore','pipe','pipe']
});
const exporterClosed=once(exporter,'close');
const rl=createInterface({input:exporter.stdout,crlfDelay:Infinity});
let exporterStderr='';exporter.stderr.setEncoding('utf8');exporter.stderr.on('data',d=>exporterStderr+=d);

let header=null,current=null,worker=null,workerOut='',workerErr='',workerInputErr=null;
let batches=0,directRoots=0,totalRecords=0,totalDecls=0,totalReplayConstants=0,maxBatchConstants=0,maxWorkerRssMiB=0;
let fatal=null;

const startWorker=()=>{
  workerOut='';workerErr='';workerInputErr=null;
  const w=spawn(process.execPath,['scripts/batch-replay-worker.mjs'],{cwd:resolve('.'),stdio:['pipe','pipe','pipe']});
  w.closed=once(w,'close');
  w.stdout.setEncoding('utf8');w.stdout.on('data',d=>workerOut+=d);
  w.stderr.setEncoding('utf8');w.stderr.on('data',d=>workerErr+=d);
  w.stdin.on('error',e=>{workerInputErr=e;});
  return w;
};
const workerFailure=(code,signal)=>new Error(
  `batch ${current?.index??'?'} replay worker exited code=${code} signal=${signal??'none'}`+
  (workerInputErr?` stdin=${workerInputErr.code??workerInputErr.message}`:'')+
  (workerErr?`\nstderr:\n${workerErr}`:'')
);
const finishWorker=async()=>{
  if(!worker)return;
  const w=worker;
  if(w.exitCode===null&&!w.stdin.destroyed&&!w.stdin.writableEnded)w.stdin.end();
  const [code,signal]=await w.closed;
  if(code!==0||signal)throw workerFailure(code,signal);
  let summary;
  try{summary=JSON.parse(workerOut.trim());}catch{throw new Error(`batch ${current?.index??'?'} invalid worker summary: ${workerOut}\n${workerErr}`);}
  totalRecords+=summary.stats.lines;
  totalDecls+=summary.stats.declarations;
  totalReplayConstants+=summary.constants;
  maxBatchConstants=Math.max(maxBatchConstants,summary.constants);
  maxWorkerRssMiB=Math.max(maxWorkerRssMiB,summary.maxRssMiB);
  worker=null;
};
try{
  for await(const line of rl){
    if(!line.trim())continue;
    let marker=null;
    try{marker=JSON.parse(line);}catch{}
    if(marker?.environment){
      if(header)throw new Error('duplicate environment header');
      header=marker.environment;
      continue;
    }
    if(marker?.batch){
      await finishWorker();
      current=marker.batch;
      batches++;
      directRoots+=Number(current.directRoots);
      worker=startWorker();
      console.error(`[batch-stream] batch=${current.index}/${header?.batches??'?'} selected=${batches} roots=${directRoots}/${header?.selectedDirectRoots??header?.constants??'?'} modules=${current.firstModule}..${current.lastModule}`);
      continue;
    }
    if(!worker)throw new Error(`record before first batch: ${line.slice(0,120)}`);
    if(worker.exitCode!==null||workerInputErr){
      await finishWorker();
      throw new Error(`batch ${current?.index??'?'} replay worker closed before exporter finished`);
    }
    if(!worker.stdin.write(line+'\n')){
      const outcome=await Promise.race([
        once(worker.stdin,'drain').then(()=> 'drain'),
        worker.closed.then(()=> 'closed')
      ]);
      if(outcome==='closed')await finishWorker();
    }
  }
  await finishWorker();
}catch(e){fatal=e;exporter.kill('SIGTERM');if(worker)worker.kill('SIGTERM');}
const [code]=await exporterClosed;
if(fatal)throw fatal;
if(code!==0)throw new Error(`Lean exporter exited ${code}: ${exporterStderr}`);
if(!header)throw new Error('missing environment header');
const expected=expectedArg?Number(expectedArg):Number(header.constants);
if(expectedTotalBatches!==null&&Number(header.batches)!==expectedTotalBatches)throw new Error(`exporter batch count ${header.batches} != expected ${expectedTotalBatches}`);
if(Number(header.constants)!==expected)throw new Error(`exporter constant count ${header.constants} != expected ${expected}`);
const expectedBatches=Number(header.selectedBatches??header.batches);
const expectedDirectRoots=Number(header.selectedDirectRoots??header.constants);
if(expectedBatches!==batches)throw new Error(`observed batches ${batches} != selected batches ${expectedBatches}`);
if(directRoots!==expectedDirectRoots)throw new Error(`direct root coverage ${directRoots} != selected direct roots ${expectedDirectRoots}`);
console.log(JSON.stringify({
  ok:true,module:moduleName,modules:Number(header.modules),totalBatches:Number(header.batches),batches,maxRoots,rangeStart:Number(header.rangeStart??0),rangeStop:Number(header.rangeStop??header.batches),directRoots,environmentConstants:expected,
  records:totalRecords,declarations:totalDecls,totalReplayConstants,maxBatchConstants,maxWorkerRssMiB:Number(maxWorkerRssMiB.toFixed(1))
},null,2));
