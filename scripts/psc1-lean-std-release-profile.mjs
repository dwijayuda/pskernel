import {spawnSync} from 'node:child_process';
import {closeSync,createReadStream,mkdtempSync,openSync,rmSync} from 'node:fs';
import {createInterface} from 'node:readline';
import {tmpdir} from 'node:os';
import {delimiter,join,resolve} from 'node:path';
import fs from 'node:fs';

const EXPECTED_STD_CONSTANTS=114029;
const args=process.argv.slice(2);
const arg=(name, fallback)=>{
  const i=args.indexOf(name);
  return i>=0?args[i+1]:fallback;
};
const start=Number(arg('--start','0'));
const count=Number(arg('--count','64'));
const label=arg('--label',`roots-${start}-${count}`);
const baseChunk=Number(arg('--chunk',process.env.PSC1_LEAN_STD_CHUNK??'32'));
const exportTimeoutMs=Number(process.env.PSC1_LEAN_EXPORT_TIMEOUT_MS??'180000');
const replayTimeoutMs=Number(process.env.PSC1_LEAN_REPLAY_TIMEOUT_MS??'600000');

for(const [name,value] of Object.entries({start,count,baseChunk,exportTimeoutMs,replayTimeoutMs})){
  const invalidStart=name==='start'&&value<0;
  const invalidPositive=name!=='start'&&value<=0;
  if(!Number.isSafeInteger(value)||invalidStart||invalidPositive)
    throw new Error(`invalid ${name}=${value}`);
}
if(start<0||start>=EXPECTED_STD_CONSTANTS)throw new Error(`invalid start=${start}`);
if(start+count>EXPECTED_STD_CONSTANTS)throw new Error(`range ${start}+${count} exceeds Std corpus ${EXPECTED_STD_CONSTANTS}`);

const leanExe=process.platform==='win32'?'lean.exe':'lean';
const candidates=[process.env.LEAN434_BIN,...(process.env.PATH??'').split(delimiter)]
  .filter(Boolean).map(p=>resolve(p));
const bin=candidates.find(p=>fs.existsSync(join(p,leanExe)));
if(!bin)throw new Error('PSC1 Lean Std assurance: pinned Lean 4.34 not found');
const lean=join(bin,leanExe);
const lake=process.platform==='win32'?'lake.exe':'lake';
const lakePath=fs.existsSync(join(bin,lake))?join(bin,lake):lake;
const root=resolve('.');
const replayBinText=process.env.PSC1_LEAN_REPLAY_BIN;
const replayBin=replayBinText?resolve(replayBinText):null;
if(replayBin&&!fs.existsSync(replayBin))
  throw new Error(`PSC1 Lean Std assurance: replay binary not found: ${replayBin}`);
const temp=mkdtempSync(join(tmpdir(),'psc1-lean-std-'));
let leaves=0,attempts=0,directRoots=0,totalDeclarations=0,maxDepth=0;

function exportRange(rangeStart,rangeCount,path){
  const fd=openSync(path,'w');
  const rootRangeMode=process.env.PSC1_LEAN_SEGMENT_DECLARATIONS==='1'
    ?'--root-range-segmented'
    :'--root-range';
  const r=spawnSync(
    lean,
    ['--run','oracle/replay-probe/DependencyExport.lean','Std',rootRangeMode,String(rangeStart),String(rangeCount)],
    {
      cwd:root,
      env:{...process.env,PATH:`${bin}${delimiter}${process.env.PATH??''}`},
      stdio:['ignore',fd,'pipe'],
      encoding:'utf8',
      timeout:exportTimeoutMs,
      maxBuffer:64*1024*1024,
    }
  );
  closeSync(fd);
  return r;
}

async function inspectExport(path){
  const rl=createInterface({input:createReadStream(path),crlfDelay:Infinity});
  let environment=null,batch=null;
  try{
    for await(const line of rl){
      if(!line.trim())continue;
      let x;
      try{x=JSON.parse(line);}catch{continue;}
      if(x.environment)environment=x.environment;
      if(x.batch){batch=x.batch;break;}
    }
  }finally{
    rl.close();
  }
  return {environment,batch};
}

function replayRange(path){
  const command=replayBin??lakePath;
  const argv=replayBin
    ?[path]
    :['env','lean','--run','PSC1Kernel/Test/ReplayFile.lean',path];
  return spawnSync(
    command,
    argv,
    {
      cwd:replayBin?root:join(root,'psc1-kernel'),
      env:{...process.env,PATH:`${bin}${delimiter}${process.env.PATH??''}`},
      encoding:'utf8',
      timeout:replayTimeoutMs,
      maxBuffer:64*1024*1024,
    }
  );
}

function failureText(r){
  return [
    r.error?.message??'',
    r.signal?`signal=${r.signal}`:'',
    r.status!==null?`status=${r.status}`:'',
    r.stderr??'',
    r.stdout??''
  ].filter(Boolean).join('\n');
}

async function verify(rangeStart,rangeCount,depth=0){
  attempts++;
  maxDepth=Math.max(maxDepth,depth);
  const path=join(temp,`std-${rangeStart}-${rangeCount}.ndjson`);
  const exported=exportRange(rangeStart,rangeCount,path);
  if(exported.status!==0||exported.signal||exported.error){
    rmSync(path,{force:true});
    if(rangeCount>1){
      const left=Math.floor(rangeCount/2), right=rangeCount-left;
      console.error(`[psc1-lean-std] export split ${rangeStart}+${rangeCount} -> ${left}+${right}`);
      await verify(rangeStart,left,depth+1);
      await verify(rangeStart+left,right,depth+1);
      return;
    }
    throw new Error(`Std export failed at root ${rangeStart}\n${failureText(exported)}`);
  }

  const {environment,batch}=await inspectExport(path);
  if(Number(environment?.constants)!==EXPECTED_STD_CONSTANTS){
    rmSync(path,{force:true});
    throw new Error(`Std constant count drift: expected ${EXPECTED_STD_CONSTANTS}, got ${environment?.constants}`);
  }
  const expectedDirect=Math.min(rangeCount,EXPECTED_STD_CONSTANTS-rangeStart);
  if(Number(batch?.directRoots)!==expectedDirect){
    rmSync(path,{force:true});
    throw new Error(`direct root count mismatch at ${rangeStart}: expected ${expectedDirect}, got ${batch?.directRoots}`);
  }

  console.error(`[psc1-lean-std] replay label=${label} start=${rangeStart} count=${rangeCount} depth=${depth}`);
  const replayed=replayRange(path);
  rmSync(path,{force:true});
  if(replayed.status!==0||replayed.signal||replayed.error){
    if(rangeCount>1){
      const left=Math.floor(rangeCount/2), right=rangeCount-left;
      console.error(`[psc1-lean-std] replay split ${rangeStart}+${rangeCount} -> ${left}+${right}`);
      await verify(rangeStart,left,depth+1);
      await verify(rangeStart+left,right,depth+1);
      return;
    }
    throw new Error(`PSC1 Lean replay failed at Std root ${rangeStart}\n${failureText(replayed)}`);
  }
  const m=(replayed.stdout??'').match(/declarations=(\d+)/);
  if(m)totalDeclarations+=Number(m[1]);
  directRoots+=rangeCount;
  leaves++;
  console.error((replayed.stdout??'').trim());
}

try{
  let offset=0;
  while(offset<count){
    const n=Math.min(baseChunk,count-offset);
    await verify(start+offset,n,0);
    offset+=n;
  }
  if(directRoots!==count)throw new Error(`coverage ${directRoots} != requested ${count}`);
  console.log(JSON.stringify({
    ok:true,
    profile:'psc1-lean-std-release-assurance-v1',
    label,
    corpusConstants:EXPECTED_STD_CONSTANTS,
    rootStart:start,
    rootCount:count,
    rootStop:start+count,
    directRoots,
    attempts,
    leaves,
    maxDepth,
    baseChunk,
    replayedDeclarations:totalDeclarations,
    declarationSegmented:process.env.PSC1_LEAN_SEGMENT_DECLARATIONS==='1'
  },null,2));
}finally{
  rmSync(temp,{recursive:true,force:true});
}
