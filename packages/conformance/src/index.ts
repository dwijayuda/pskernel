import {readdirSync,statSync} from 'node:fs';
import {join,relative,sep} from 'node:path';
import {fileURLToPath} from 'node:url';
import {spawn} from 'node:child_process';

export type ExpectedOutcome='accept'|'reject';
export type ConformanceOutcome=ExpectedOutcome|'timeout'|'error';
export interface ArenaCase {readonly file:string;readonly rel:string;readonly expected:ExpectedOutcome}
export interface ConformanceRow extends ArenaCase {readonly outcome:ConformanceOutcome;readonly ok:boolean;readonly code:number|null;readonly signal:NodeJS.Signals|null;readonly detail:string}
export interface RunCaseOptions {readonly timeoutMs?:number;readonly stackKiB?:number}
export interface RunArenaOptions extends RunCaseOptions {readonly includePerf?:boolean;readonly workers?:number;readonly onResult?:(row:ConformanceRow)=>void}
export interface ArenaSuiteResult {readonly ok:boolean;readonly total:number;readonly accept:number;readonly reject:number;readonly timeouts:number;readonly errors:number;readonly includePerf:boolean;readonly mismatches:readonly Pick<ConformanceRow,'rel'|'expected'|'outcome'|'detail'>[];readonly rows:readonly ConformanceRow[]}

const workerPath=fileURLToPath(new URL('../bin/case-worker.js',import.meta.url));
function fail(message:string):never { throw new Error(`@proofscript/conformance: ${message}`); }

export function discoverArenaCases(root:string,{includePerf=false}:{readonly includePerf?:boolean}={}):ArenaCase[] {
  const files:string[]=[];
  const walk=(p:string):void=>{for(const name of readdirSync(p)){const path=join(p,name),st=statSync(path);if(st.isDirectory())walk(path);else if(path.endsWith('.ndjson'))files.push(path);}};
  walk(root);files.sort();
  return files.filter(file=>includePerf||!relative(root,file).split(sep).includes('perf')).map(file=>{
    const rel=relative(root,file),first=rel.split(sep)[0];
    const expected:ExpectedOutcome|undefined=first==='good'?'accept':first==='bad'?'reject':undefined;
    if(expected===undefined)fail(`case is not under good/ or bad/: ${rel}`);
    return {file,rel,expected};
  });
}

export async function runConformanceCase(testCase:ArenaCase,{timeoutMs=60000,stackKiB=65500}:RunCaseOptions={}):Promise<ConformanceRow> {
  if(!Number.isSafeInteger(timeoutMs)||timeoutMs<1000)fail('timeoutMs must be an integer >= 1000');
  if(!Number.isSafeInteger(stackKiB)||stackKiB<1024)fail('stackKiB must be an integer >= 1024');
  return await new Promise(resolve=>{
    const child=spawn(process.execPath,[`--stack-size=${stackKiB}`,workerPath,testCase.file],{stdio:['ignore','pipe','pipe']});
    let out='',err='',timedOut=false;
    child.stdout.setEncoding('utf8');child.stderr.setEncoding('utf8');
    child.stdout.on('data',(d:string)=>out+=d);child.stderr.on('data',(d:string)=>err+=d);
    const timer=setTimeout(()=>{timedOut=true;child.kill('SIGKILL');},timeoutMs);
    child.on('close',(code:number|null,signal:NodeJS.Signals|null)=>{
      clearTimeout(timer);
      const outcome:ConformanceOutcome=timedOut?'timeout':code===0?'accept':code===1?'reject':'error';
      resolve({...testCase,outcome,ok:outcome===testCase.expected,code,signal,detail:(outcome==='accept'?out:err).trim().slice(-4000)});
    });
  });
}

export async function runArenaSuite(root:string,{includePerf=false,workers=6,timeoutMs=60000,stackKiB=65500,onResult}:RunArenaOptions={}):Promise<ArenaSuiteResult> {
  if(!Number.isSafeInteger(workers)||workers<1)fail('workers must be a positive integer');
  const cases=discoverArenaCases(root,{includePerf});let next=0;const rows:ConformanceRow[]=[];
  async function worker():Promise<void>{while(true){const i=next++;if(i>=cases.length)return;const testCase=cases[i];if(testCase===undefined)return;const row=await runConformanceCase(testCase,{timeoutMs,stackKiB});rows.push(row);onResult?.(row);}}
  await Promise.all(Array.from({length:Math.min(workers,cases.length||1)},()=>worker()));
  rows.sort((a,b)=>a.rel.localeCompare(b.rel));const mismatches=rows.filter(r=>!r.ok);
  return {ok:mismatches.length===0,total:rows.length,accept:rows.filter(r=>r.outcome==='accept').length,reject:rows.filter(r=>r.outcome==='reject').length,timeouts:rows.filter(r=>r.outcome==='timeout').length,errors:rows.filter(r=>r.outcome==='error').length,includePerf,mismatches:mismatches.map(({rel,expected,outcome,detail})=>({rel,expected,outcome,detail})),rows};
}
