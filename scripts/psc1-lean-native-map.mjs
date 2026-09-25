import {spawnSync} from 'node:child_process';
import {readFileSync,writeFileSync} from 'node:fs';
import {delimiter,join,resolve} from 'node:path';
import fs from 'node:fs';

const [moduleName,inputPath,outputPath]=process.argv.slice(2);
if(!moduleName||!inputPath||!outputPath){
  throw new Error('usage: psc1-lean-native-map <module> <lean4export.ndjson> <native.tsv>');
}

const expectedHash='293d5d0c0c3f3dded4688b3ccd6a33939ac5102b';
const leanExe=process.platform==='win32'?'lean.exe':'lean';
const candidates=[process.env.LEAN434_BIN,...(process.env.PATH??'').split(delimiter)]
  .filter(Boolean).map(p=>resolve(p));
const bin=candidates.find(p=>fs.existsSync(join(p,leanExe)));
if(!bin)throw new Error('psc1 native map: pinned Lean 4.34 executable not found');
const lean=join(bin,leanExe);
const env={...process.env,PATH:`${bin}${delimiter}${process.env.PATH??''}`};

const hash=spawnSync(lean,['--githash'],{encoding:'utf8',timeout:5000,env});
if(hash.error||hash.status!==0||hash.stdout.trim()!==expectedHash){
  throw new Error(`psc1 native map: Lean githash mismatch: ${hash.error?.message??hash.stderr??hash.stdout}`);
}

let names=new Map([[0,'']]);
let exprs=new Map();
const requests=new Map();

const dotted=(parent,part)=>parent?parent+'.'+part:String(part);
const getName=(i)=>{
  const n=names.get(i);
  if(n===undefined)throw new Error(`psc1 native map: undefined Name index ${i}`);
  return n;
};
const getExpr=(i)=>{
  const e=exprs.get(i);
  if(e===undefined)throw new Error(`psc1 native map: undefined Expr index ${i}`);
  return e;
};
const addRequest=(kind,name)=>{
  const old=requests.get(name);
  if(old!==undefined&&old!==kind){
    throw new Error(`psc1 native map: constant ${name} requested as both ${old} and ${kind}`);
  }
  requests.set(name,kind);
};
const inspectApp=(node)=>{
  const fn=getExpr(node.fn),arg=getExpr(node.arg);
  if(fn.kind!=='const'||fn.levels!==0||arg.kind!=='const')return;
  if(fn.name==='Lean.reduceNat')addRequest('nat',arg.name);
  else if(fn.name==='Lean.reduceBool')addRequest('bool',arg.name);
};

let physicalLines=0,segments=0;
for(const raw of readFileSync(inputPath,'utf8').split(/\r?\n/)){
  if(!raw.trim())continue;
  physicalLines++;
  let x;
  try{x=JSON.parse(raw);}catch(e){
    throw new Error(`psc1 native map: invalid JSON at line ${physicalLines}`,{cause:e});
  }
  if(x.segment){
    names=new Map([[0,'']]);
    exprs=new Map();
    segments++;
    continue;
  }
  if(Number.isSafeInteger(x.in)){
    let name;
    if(x.str){
      name=dotted(getName(Number(x.str.pre)),String(x.str.str));
    }else if(x.num){
      name=dotted(getName(Number(x.num.pre)),Number(x.num.i));
    }else{
      throw new Error(`psc1 native map: malformed Name record at line ${physicalLines}`);
    }
    if(names.has(Number(x.in)))throw new Error(`psc1 native map: duplicate Name index ${x.in}`);
    names.set(Number(x.in),name);
    continue;
  }
  if(Number.isSafeInteger(x.ie)){
    let node={kind:'other'};
    if(x.const){
      node={
        kind:'const',
        name:getName(Number(x.const.name)),
        levels:Array.isArray(x.const.us)?x.const.us.length:-1,
      };
    }else if(x.app){
      node={kind:'app',fn:Number(x.app.fn),arg:Number(x.app.arg)};
    }
    if(exprs.has(Number(x.ie)))throw new Error(`psc1 native map: duplicate Expr index ${x.ie}`);
    exprs.set(Number(x.ie),node);
    if(node.kind==='app')inspectApp(node);
  }
}

const rows=[];
for(const [name,kind] of [...requests.entries()].sort((a,b)=>a[0].localeCompare(b[0]))){
  const r=spawnSync(
    lean,
    ['--run','oracle/replay-probe/NativeEval.lean',moduleName,kind,name],
    {cwd:resolve('.'),env,encoding:'utf8',timeout:Number(process.env.PSC1_NATIVE_TIMEOUT_MS??'60000'),maxBuffer:16*1024*1024}
  );
  if(r.error||r.status!==0||r.signal){
    throw new Error(`psc1 native map: Lean native evaluation failed for ${kind} ${name}: ${r.error?.message??r.stderr??r.signal??r.status}`);
  }
  let payload;
  try{payload=JSON.parse(r.stdout.trim());}
  catch(e){throw new Error(`psc1 native map: invalid oracle JSON for ${kind} ${name}: ${r.stdout}`,{cause:e});}
  if(kind==='nat'){
    if(payload?.kind!=='nat'||typeof payload.value!=='string'||!/^[0-9]+$/.test(payload.value)){
      throw new Error(`psc1 native map: invalid Nat oracle payload for ${name}`);
    }
    rows.push(`nat\t${name}\t${payload.value}`);
  }else{
    if(payload?.kind!=='bool'||typeof payload.value!=='boolean'){
      throw new Error(`psc1 native map: invalid Bool oracle payload for ${name}`);
    }
    rows.push(`bool\t${name}\t${payload.value?'true':'false'}`);
  }
}
writeFileSync(outputPath,rows.length?rows.join('\n')+'\n':'');
console.log(JSON.stringify({
  ok:true,
  module:moduleName,
  input:inputPath,
  output:outputPath,
  segments,
  physicalLines,
  nativeRequests:rows.length,
  requests:[...requests.entries()].map(([name,kind])=>({kind,name})),
},null,2));
