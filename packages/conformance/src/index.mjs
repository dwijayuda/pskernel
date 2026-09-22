import {readdirSync,statSync} from 'node:fs';
import {join,relative,sep} from 'node:path';
import {fileURLToPath} from 'node:url';
import {spawn} from 'node:child_process';

const workerPath=fileURLToPath(new URL('../bin/case-worker.mjs',import.meta.url));

function fail(message){throw new Error(`@proofscript/conformance: ${message}`);}

export function discoverArenaCases(root,{includePerf=false}={}){
  const files=[];
  const walk=p=>{
    for(const name of readdirSync(p)){
      const path=join(p,name),st=statSync(path);
      if(st.isDirectory())walk(path);
      else if(path.endsWith('.ndjson'))files.push(path);
    }
  };
  walk(root);
  files.sort();
  return files
    .filter(file=>includePerf||!relative(root,file).split(sep).includes('perf'))
    .map(file=>{
      const rel=relative(root,file),parts=rel.split(sep);
      const expected=parts[0]==='good'?'accept':parts[0]==='bad'?'reject':null;
      if(!expected)fail(`case is not under good/ or bad/: ${rel}`);
      return {file,rel,expected};
    });
}

export async function runConformanceCase(testCase,{timeoutMs=60000,stackKiB=65500}={}){
  if(!Number.isSafeInteger(timeoutMs)||timeoutMs<1000)fail('timeoutMs must be an integer >= 1000');
  if(!Number.isSafeInteger(stackKiB)||stackKiB<1024)fail('stackKiB must be an integer >= 1024');
  return await new Promise(resolve=>{
    const child=spawn(process.execPath,[`--stack-size=${stackKiB}`,workerPath,testCase.file],{
      stdio:['ignore','pipe','pipe']
    });
    let out='',err='',timedOut=false;
    child.stdout.setEncoding('utf8');child.stderr.setEncoding('utf8');
    child.stdout.on('data',d=>out+=d);child.stderr.on('data',d=>err+=d);
    const timer=setTimeout(()=>{timedOut=true;child.kill('SIGKILL');},timeoutMs);
    child.on('close',(code,signal)=>{
      clearTimeout(timer);
      const outcome=timedOut?'timeout':code===0?'accept':code===1?'reject':'error';
      resolve({
        ...testCase,
        outcome,
        ok:outcome===testCase.expected,
        code,
        signal,
        detail:(outcome==='accept'?out:err).trim().slice(-4000)
      });
    });
  });
}

export async function runArenaSuite(root,{
  includePerf=false,
  workers=6,
  timeoutMs=60000,
  stackKiB=65500,
  onResult
}={}){
  if(!Number.isSafeInteger(workers)||workers<1)fail('workers must be a positive integer');
  const cases=discoverArenaCases(root,{includePerf});
  let next=0;
  const rows=[];
  async function worker(){
    while(true){
      const i=next++;
      if(i>=cases.length)return;
      const row=await runConformanceCase(cases[i],{timeoutMs,stackKiB});
      rows.push(row);
      onResult?.(row);
    }
  }
  await Promise.all(Array.from({length:Math.min(workers,cases.length||1)},()=>worker()));
  rows.sort((a,b)=>a.rel.localeCompare(b.rel));
  const mismatches=rows.filter(r=>!r.ok);
  return {
    ok:mismatches.length===0,
    total:rows.length,
    accept:rows.filter(r=>r.outcome==='accept').length,
    reject:rows.filter(r=>r.outcome==='reject').length,
    timeouts:rows.filter(r=>r.outcome==='timeout').length,
    errors:rows.filter(r=>r.outcome==='error').length,
    includePerf,
    mismatches:mismatches.map(({rel,expected,outcome,detail})=>({rel,expected,outcome,detail})),
    rows
  };
}
