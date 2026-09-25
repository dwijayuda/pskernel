import {spawnSync} from 'node:child_process';
import {delimiter,dirname,join,resolve} from 'node:path';
import {readFileSync,writeFileSync} from 'node:fs';
import fs from 'node:fs';

const args=process.argv.slice(2);
function take(name){
  const i=args.indexOf(name);
  if(i<0||i+1>=args.length)throw new Error(`missing ${name}`);
  const value=args[i+1];
  args.splice(i,2);
  return value;
}
const moduleName=take('--module');
const out=take('--out');
const requestsFile=args.includes('--requests-file')?take('--requests-file'):null;
const fileRequests=requestsFile
  ?readFileSync(requestsFile,'utf8').split(/\r?\n/).map(x=>x.trim()).filter(Boolean)
  :[];
const requests=[...fileRequests,...args];
if(requests.length===0)throw new Error('expected at least one nat:Name or bool:Name request');

const leanExe=process.platform==='win32'?'lean.exe':'lean';
const candidates=[
  process.env.LEAN434_BIN,
  ...(process.env.PATH??'').split(delimiter),
].filter(Boolean).map(p=>resolve(p));
const bin=candidates.find(p=>fs.existsSync(join(p,leanExe)));
if(!bin)throw new Error('psc1 native map: pinned Lean 4.34 not found');
const lean=join(bin,leanExe);

const hash=spawnSync(lean,['--githash'],{encoding:'utf8',timeout:5000});
if(hash.error||hash.status!==0)throw hash.error??new Error(hash.stderr);
const gotHash=hash.stdout.trim();
const expectedHash='293d5d0c0c3f3dded4688b3ccd6a33939ac5102b';
if(gotHash!==expectedHash)throw new Error(`psc1 native map: expected Lean ${expectedHash}, got ${gotHash}`);

const seen=new Set();
const lines=[];
for(const request of requests){
  const colon=request.indexOf(':');
  if(colon<=0||colon===request.length-1)throw new Error(`invalid request '${request}'`);
  const kind=request.slice(0,colon);
  const name=request.slice(colon+1);
  if(kind!=='nat'&&kind!=='bool')throw new Error(`invalid native kind '${kind}'`);
  const key=`${kind}:${name}`;
  if(seen.has(key))throw new Error(`duplicate native request '${key}'`);
  seen.add(key);

  const r=spawnSync(
    lean,
    ['--run','oracle/replay-probe/NativeEval.lean',moduleName,kind,name],
    {
      cwd:resolve('.'),
      env:{...process.env,PATH:`${bin}${delimiter}${process.env.PATH??''}`},
      encoding:'utf8',
      timeout:Number(process.env.PSC1_NATIVE_EVAL_TIMEOUT_MS??'60000'),
      maxBuffer:16*1024*1024,
      killSignal:'SIGKILL',
    }
  );
  if(r.error)throw new Error(`native evaluation failed for ${key}: ${r.error.message}`);
  if(r.status!==0||r.signal){
    throw new Error(`native evaluation failed for ${key}: code=${r.status} signal=${r.signal??'none'}\n${r.stderr??''}`);
  }
  let payload;
  try{payload=JSON.parse((r.stdout??'').trim());}
  catch(e){throw new Error(`invalid native JSON for ${key}: ${r.stdout??''}`,{cause:e});}
  if(kind==='nat'){
    if(payload?.kind!=='nat'||typeof payload.value!=='string'||!/^[0-9]+$/.test(payload.value))
      throw new Error(`invalid Nat result for ${key}`);
    lines.push(`nat\t${name}\t${payload.value}`);
  }else{
    if(payload?.kind!=='bool'||typeof payload.value!=='boolean')
      throw new Error(`invalid Bool result for ${key}`);
    lines.push(`bool\t${name}\t${payload.value?'true':'false'}`);
  }
}
writeFileSync(out,lines.join('\n')+'\n');
console.log(JSON.stringify({ok:true,module:moduleName,leanGitHash:gotHash,entries:lines.length,out},null,2));
