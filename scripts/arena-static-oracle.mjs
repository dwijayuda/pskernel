import {readdirSync,statSync} from 'node:fs';
import {join,relative,sep} from 'node:path';
import {spawn} from 'node:child_process';

const root=process.argv[2];
const includePerf=process.argv.includes('--include-perf');
if(!root){console.error('usage: node scripts/arena-static-oracle.mjs <arena-tests-dir> [--include-perf]');process.exit(2);}
const workers=Number(process.env.ARENA_WORKERS??'6'),timeoutMs=Number(process.env.ARENA_TIMEOUT_MS??'60000');
if(!Number.isSafeInteger(workers)||workers<1||!Number.isSafeInteger(timeoutMs)||timeoutMs<1000)throw new Error('invalid Arena worker configuration');
const files=[];
const walk=p=>{for(const n of readdirSync(p)){const q=join(p,n),s=statSync(q);if(s.isDirectory())walk(q);else if(q.endsWith('.ndjson'))files.push(q);}};
walk(root);files.sort();
const cases=files.filter(f=>includePerf||!relative(root,f).split(sep).includes('perf')).map(file=>{
  const rel=relative(root,file),parts=rel.split(sep),expected=parts[0]==='good'?'accept':parts[0]==='bad'?'reject':null;
  if(!expected)throw new Error(`Arena case is not under good/ or bad/: ${rel}`);
  return{file,rel,expected};
});
let next=0;const rows=[];
async function runCase(c){return await new Promise(resolve=>{
  const child=spawn(process.execPath,['scripts/arena-case-worker.mjs',c.file],{stdio:['ignore','pipe','pipe']});
  let out='',err='',timedOut=false;
  child.stdout.setEncoding('utf8');child.stderr.setEncoding('utf8');
  child.stdout.on('data',d=>out+=d);child.stderr.on('data',d=>err+=d);
  const timer=setTimeout(()=>{timedOut=true;child.kill('SIGKILL');},timeoutMs);
  child.on('close',code=>{clearTimeout(timer);const outcome=timedOut?'timeout':code===0?'accept':code===1?'reject':'error';resolve({...c,outcome,ok:outcome===c.expected,detail:(outcome==='accept'?out:err).trim().slice(-2000)});});
});}
async function worker(){while(true){const i=next++;if(i>=cases.length)return;const row=await runCase(cases[i]);rows.push(row);if(!row.ok)console.error(`[arena] mismatch ${row.expected}->${row.outcome} ${row.rel}\n${row.detail}`);}}
await Promise.all(Array.from({length:Math.min(workers,cases.length)},()=>worker()));
rows.sort((a,b)=>a.rel.localeCompare(b.rel));
const mismatches=rows.filter(r=>!r.ok),accept=rows.filter(r=>r.outcome==='accept').length,reject=rows.filter(r=>r.outcome==='reject').length,timeouts=rows.filter(r=>r.outcome==='timeout').length;
console.log(JSON.stringify({ok:mismatches.length===0,total:rows.length,accept,reject,timeouts,includePerf,mismatches:mismatches.map(({rel,expected,outcome,detail})=>({rel,expected,outcome,detail}))},null,2));
if(mismatches.length)process.exit(1);
