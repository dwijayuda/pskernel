import {spawn,spawnSync} from 'node:child_process';
import {createInterface} from 'node:readline';
import {resolve, join, delimiter} from 'node:path';
import fs from 'node:fs';
import {Environment} from '../dist/src/core/environment.js';
import {LEAN434_PINNED_GITHASH,Lean4ExportReplay} from '../dist/src/integration/lean4export.js';
import {createLeanNativeEvaluator} from './lean-native-evaluator.mjs';

const moduleName=process.argv[2]??'Init.Prelude';
const expectedArg=process.argv[3];
const logEveryShard=Number(process.env.PSKERNEL_LOG_EVERY_SHARD??'25');
if(!Number.isSafeInteger(logEveryShard)||logEveryShard<1)throw new Error(`module-stream-oracle: invalid PSKERNEL_LOG_EVERY_SHARD ${process.env.PSKERNEL_LOG_EVERY_SHARD}`);
const candidates=[process.env.LEAN434_BIN,'/mnt/data/work/lean4src/lean4-4.34.0/build/release/stage1/bin',...(process.env.PATH??'').split(delimiter)].filter(Boolean).map(p=>resolve(p));
const leanExe=process.platform==='win32'?'lean.exe':'lean';
const bin=candidates.find(p=>fs.existsSync(join(p,leanExe)));
if(!bin)throw new Error('module-stream-oracle: set LEAN434_BIN to Lean 4.34.0 bin directory');
const lean=join(bin,leanExe);
const envVars={...process.env,PATH:`${bin}${delimiter}${process.env.PATH??''}`};
const expectedVersion=/^Lean \(version 4\.34\.0(?:,|\)).*Release\)?$/;
const versionRun=spawnSync(lean,['--version'],{encoding:'utf8',timeout:5000,env:envVars});
const leanVersion=versionRun.stdout?.trim()??'';
if(versionRun.error||versionRun.status!==0||!expectedVersion.test(leanVersion)){
  throw new Error(`module-stream-oracle: Lean version drift/failure: ${versionRun.error?.message??versionRun.stderr??leanVersion}`);
}
const hashRun=spawnSync(lean,['--githash'],{encoding:'utf8',timeout:5000,env:envVars});
const leanGitHash=hashRun.stdout?.trim()??'';
if(hashRun.error||hashRun.status!==0||leanGitHash!==LEAN434_PINNED_GITHASH){
  throw new Error(`module-stream-oracle: Lean git hash drift/failure: expected ${LEAN434_PINNED_GITHASH}, got ${hashRun.error?.message??hashRun.stderr??leanGitHash}`);
}
const nativeEvaluator=createLeanNativeEvaluator({lean,moduleName,cwd:resolve('.'),env:envVars});
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
     if(header.rootOrder!=='olean-module-constNames')throw new Error(`unexpected canonical root order ${header.rootOrder??'<missing>'}`);
     if(header.rootOrderMeaning!=='serialized-module-sequence')throw new Error(`unexpected root-order meaning ${header.rootOrderMeaning??'<missing>'}`);
     if(header.rootDedup!=='first-serialized-occurrence')throw new Error(`unexpected root dedup policy ${header.rootDedup??'<missing>'}`);
     if(header.emissionOrder!=='dependency-first')throw new Error(`unexpected emission order ${header.emissionOrder??'<missing>'}`);
     if(header.canonicalScope!=='pskernel-project-protocol')throw new Error(`unexpected canonical scope ${header.canonicalScope??'<missing>'}`);
     if(header.replayPolicy!=='Lean.Kernel.Environment.replay')throw new Error(`unexpected replay policy ${header.replayPolicy??'<missing>'}`);
     continue;
   }
   if(marker?.shard){
     if(replay){const s=replay.finish();totalLines+=s.lines;totalDecls+=s.declarations;replay=null;global.gc?.();}
     replay=new Lean4ExportReplay(shared,{nativeEvaluator});
     current=marker.shard.module;shards++;
     const mem=process.memoryUsage(),rss=mem.rss/1048576,heap=mem.heapUsed/1048576;maxRssMiB=Math.max(maxRssMiB,rss);maxHeapMiB=Math.max(maxHeapMiB,heap);
     if(shards===1||shards%logEveryShard===0)console.error(`[module-stream] shard=${shards}/${header?.plannedShards??'?'} module=${current} part=${marker.shard.part??0} roots=${marker.shard.roots??'?'} rootStart=${marker.shard.rootStart??'?'} firstRoot=${marker.shard.firstRoot??'?'} lastRoot=${marker.shard.lastRoot??'?'} constants=${shared.size} rssMiB=${rss.toFixed(1)} heapMiB=${heap.toFixed(1)}`);
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
const expectedTotal=expectedArg?Number(expectedArg):Number(header.constants);
const totalConstants=Number(header.constants);
const replayableConstants=Number(header.replayableConstants);
const skippedUnsafe=Number(header.skippedUnsafe);
const skippedPartial=Number(header.skippedPartial);
if(totalConstants!==expectedTotal)throw new Error(`exporter total constant count ${totalConstants} != expected corpus count ${expectedTotal}`);
if(!Number.isSafeInteger(replayableConstants)||!Number.isSafeInteger(skippedUnsafe)||!Number.isSafeInteger(skippedPartial))throw new Error('invalid canonical replay accounting in exporter header');
if(replayableConstants+skippedUnsafe+skippedPartial!==totalConstants)throw new Error(`canonical replay accounting mismatch: replayable=${replayableConstants} unsafe=${skippedUnsafe} partial=${skippedPartial} total=${totalConstants}`);
if(shared.size!==replayableConstants)throw new Error(`replayed constants ${shared.size} != replayable exporter count ${replayableConstants}`);
const finalMem=process.memoryUsage();maxRssMiB=Math.max(maxRssMiB,finalMem.rss/1048576);maxHeapMiB=Math.max(maxHeapMiB,finalMem.heapUsed/1048576);
if(header.plannedShards!==undefined&&shards!==Number(header.plannedShards))throw new Error(`observed shards ${shards} != planned ${header.plannedShards}`);
console.log(JSON.stringify({
  ok:true,
  protocol:'canonical-module-stream-v2',
  canonical:true,
  leanVersion,
  leanGitHash,
  rootOrder:header.rootOrder,
  rootOrderMeaning:header.rootOrderMeaning,
  rootDedup:header.rootDedup,
  emissionOrder:header.emissionOrder,
  canonicalScope:header.canonicalScope,
  replayPolicy:header.replayPolicy,
  module:moduleName,
  modules:Number(header.modules),
  plannedShards:Number(header.plannedShards??shards),
  shards,
  rootsPerShard:Number(header.rootsPerShard??0),
  records:totalLines,
  declarations:totalDecls,
  totalConstants,
  replayableConstants,
  skippedUnsafe,
  skippedPartial,
  replayedConstants:shared.size,
  rssMiB:Number((finalMem.rss/1048576).toFixed(1)),
  heapMiB:Number((finalMem.heapUsed/1048576).toFixed(1)),
  maxRssMiB:Number(maxRssMiB.toFixed(1)),
  maxHeapMiB:Number(maxHeapMiB.toFixed(1))
},null,2));
