// Linux Actions only. The actual PSC1 compiler and generated checker run here.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { pathToFileURL } from 'node:url';
import { resolveTypeScriptCli, typeScriptProfileArgs } from './typescript-cli.mjs';
import { createCoreIngress, ingressLimits } from '../packages/pskernel-min/host/ingress.mjs';
assert.equal(process.platform, 'linux');
assert.match(process.env.GITHUB_SHA || '', /^[a-f0-9]{40}$/);
const dir='dist/pskernel-min/ingress';
fs.mkdirSync(dir,{recursive:true});
fs.writeFileSync(path.join(dir,'package.json'),'{"type":"module"}\n');
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
const sources=['RegularProfile','RegularCheck','OperationalProfile','OperationalCheck','CoreBytes','CoreIngress']
  .map(n=>'packages/pskernel-min/src/Ps/MinKernel/Profile/'+n+'.lean');
sources.push('packages/pskernel-min/src/Ps/MinKernel/Tests/IngressVectors.lean');
const sourceIdentities=sources.map(file=>({path:file,bytes:fs.statSync(file).size,sha256:sha(fs.readFileSync(file))}));
function run(command,args,input,cwd) {
  const r=spawnSync(command,args,{input,cwd,encoding:'utf8',timeout:240000,maxBuffer:32*1024*1024});
  assert.equal(r.error,undefined,String(r.error));
  assert.equal(r.status,0,r.stdout+'\n'+r.stderr);
  return r.stdout;
}
run('lake',['env','lean','--run','scripts/MinKernelSourceCompile.lean','ingress']);
const stem=path.join(dir,'vectors'), admissions=fs.readFileSync(stem+'.admissions.json');
const official=JSON.parse(run('.lake/build/bin/psc1_independent_checker',['--check'],admissions));
assert.equal(official.accepted,true);
assert.equal(official.leanVersion,'4.35.0');
assert.equal(official.leanCommit,'eb6cafb7290e8bd5f2937522d8d804f58f02bafc');
const sourceReport=JSON.parse(fs.readFileSync(stem+'.source.json','utf8'));
assert.equal(sourceReport.moduleCount,7);
assert.equal(sourceReport.origins.length,7);
run(process.execPath,[resolveTypeScriptCli(),...typeScriptProfileArgs([
  stem+'.ts','--target','ES2022','--module','ES2022','--moduleResolution','bundler',
  '--strict','--skipLibCheck','--noEmitOnError','--pretty','false'])]);
const G=await import(pathToFileURL(path.resolve(stem+'.js')).href);
const check=createCoreIngress(G);
const cases=JSON.parse(fs.readFileSync('scripts/minkernel-ingress-cases.json','utf8'));
run('lake',['build','minkernel_ingress_tests'],undefined,'packages/pskernel-min');
const native=run('.lake/build/bin/minkernel_ingress_tests',[],undefined,'packages/pskernel-min');
fs.writeFileSync(path.join(dir,'native-tests.log'),native);
const nativeRows=[...native.matchAll(/^PSC1_MIN_INGRESS_VECTOR ([0-9]+) (true|false)$/gm)];
const canonicalRows=[...native.matchAll(/^PSC1_MIN_INGRESS_CANONICAL ([0-9]+) (.+)$/gm)];
assert.equal(nativeRows.length,cases.length);
assert.equal(canonicalRows.length,cases.length);
const observations=[];
for(const c of cases) {
  assert.equal(nativeRows[c.index][2],String(c.expected),c.id+' native');
  assert.equal(canonicalRows[c.index][2],JSON.stringify(c.candidate),c.id+' exact native canonical bytes');
  assert.equal(G.psMinIngressVector(BigInt(c.index)),c.expected,c.id+' generated typed certificate');
  const bytes=new Uint8Array(Buffer.from(c.source,'utf8'));
  const result=check(bytes);
  assert.equal(result.accepted,c.expected,c.id+' public exact-byte entry: '+result.code);
  assert.equal(result.delegated,false);
  observations.push({index:c.index,id:c.id,accepted:result.accepted,code:result.code,
    bytes:bytes.length,sha256:sha(bytes),nativeGeneratedEqual:true});
}
const sample=new Uint8Array(Buffer.from(cases[1].source));
let touched=0;
const hostile=[
  ['plain-object',{get length(){touched++;throw Error('getter');}}],
  ['array',Array.from(sample)],
  ['buffer',Buffer.from(sample)],
  ['proxy',new Proxy(sample,{get(){touched++;throw Error('proxy');}})],
  ['cyclic',(()=>{const a={};a.self=a;return a;})()],
  ['subclass',new (class extends Uint8Array {})(sample)],
  ['dataview',new DataView(sample.buffer)],
  ['oversize',new Uint8Array(ingressLimits.bytes+1)],
  ['invalid-utf8',new Uint8Array([255])],
  ['escape',new Uint8Array(Buffer.from('{"x":"\\\\u0041"}'))],
  ['trailing-utf8',new Uint8Array([...sample,255])],
  ['json-depth',new Uint8Array(Buffer.from('['.repeat(114)+']'.repeat(114)))],
  ['json-nodes',new Uint8Array(Buffer.from('['+'{},'.repeat(4096)+'{}]'))],
];
if(typeof SharedArrayBuffer==='function')hostile.push(['shared-buffer',new Uint8Array(new SharedArrayBuffer(1))]);
for(const [id,input]of hostile) {
  const result=check(input);
  assert.equal(result.accepted,false,id);
  assert.equal(result.delegated,false,id);
  observations.push({id:'host-'+id,accepted:false,code:result.code});
}
assert.equal(touched,0,'hostile input getters/proxies must never be invoked');
const numbered=cases.filter(c=>c.expected);
const common=[];
for(const c of numbered) {
  const answer=JSON.parse(run('.lake/build/bin/psc1_independent_checker',['--check'],c.source));
  assert.equal(answer.accepted,true,c.id+' official common domain');
  common.push({id:c.id,accepted:answer.accepted,provider:answer.provider});
}
// Exact same-compile source origins identify runtime members. This is a census,
// never an admission rule or replacement for the source-preservation theorem.
const stable=v=>Array.isArray(v)?v.map(stable):v&&typeof v==='object'
  ?Object.fromEntries(Object.keys(v).sort().map(k=>[k,stable(v[k])])):v;
const key=n=>JSON.stringify(stable(n));
const wire=JSON.parse(admissions);
const runtimeOrigins=sourceReport.origins.slice(0,6);
const runtimeNames=new Set(runtimeOrigins.flatMap(m=>m.batches.flatMap(b=>b.members.map(m=>key(m.nameWire)))));
const records=wire.admissions;
const owned=r=>r.kind==='constant'?[r.declaration.n]:
  r.kind==='inductive'?r.declaration.ts.flatMap(t=>[t.n,...t.cs.map(c=>c.n)]):[];
const runtimeRecords=records.map((r,index)=>({r,index})).filter(({r})=>owned(r).some(n=>runtimeNames.has(key(n))));
const references=new Map();
const visit=e=>{
  if(!e||typeof e!=='object')return;
  if(e.k==='const'||e.k==='proj')references.set(key(e.n),e.n);
  for(const [k,v]of Object.entries(e)){if(k==='n'||k==='lp')continue;
    if(Array.isArray(v))v.forEach(visit);else if(v&&typeof v==='object')visit(v);}
};
runtimeRecords.forEach(({r})=>visit(r));
const prelude=JSON.parse(fs.readFileSync('dist/pskernel-min/closure/prelude.json','utf8'));
const preludeByName=new Map(prelude.map(d=>[key(d.nameWire),d]));
const reached=new Set();
const add=n=>{
  const k=key(n);if(reached.has(k)||runtimeNames.has(k))return;
  const d=preludeByName.get(k);if(!d)return;
  reached.add(k);
  const todo=new Map(),old=new Map(references);
  references.clear();visit(d.type);visit(d.value);
  for(const [k,v]of references)todo.set(k,v);
  references.clear();for(const [k,v]of old)references.set(k,v);
  for(const v of todo.values())add(v);
};
for(const n of [...references.values()])add(n);
const foundation=prelude.filter(d=>reached.has(key(d.nameWire)));
const semanticContracts=JSON.parse(fs.readFileSync('dist/pskernel-min/operational/foundation-contracts.json','utf8'));
const foundationUnion=new Map(foundation.map(d=>[key(d.nameWire),d]));
for(const d of semanticContracts.contracts)foundationUnion.set(key(d.nameWire),d);
const census={authoritative:false,runtimeModules:6,testModules:1,
  originMembers:runtimeNames.size,runtimeAdmissionRecords:runtimeRecords.length,
  runtimeRecordIndices:runtimeRecords.map(x=>x.index),completeSourceAdmissionRecords:records.length,
  selectedFoundationDeclarations:foundation.length,selectedFoundation:foundation,
  sourceLanguageFoundationDeclarations:semanticContracts.contracts.length,
  combinedFoundationDeclarations:foundationUnion.size,combinedFoundation:[...foundationUnion.values()],
  boundary:'Exact source-only syntactic closure; not minimal-checker self-admission or a foundation-adequacy theorem'};
fs.writeFileSync(path.join(dir,'runtime-frontier.json'),JSON.stringify(census,null,2)+'\n');
const receipt={schema:'psc1-min-core-ingress-portability/1',commit:process.env.GITHUB_SHA,
  authoritative:false,productionCanonicalMinDual:false,profile:'psc1-min-core-simple/1',
  sourceIdentities,sourceReport,officialSourceAdmission:official,sourceAdmissionSha256:sha(admissions),
  sourceOriginsSha256:sha(fs.readFileSync(stem+'.source.json')),
  generatedTsBytes:fs.statSync(stem+'.ts').size,generatedJsBytes:fs.statSync(stem+'.js').size,
  generatedJsSha256:sha(fs.readFileSync(stem+'.js')),hostSha256:sha(fs.readFileSync('packages/pskernel-min/host/ingress.mjs')),
  positiveCases:cases.filter(c=>c.expected).length,refusalCases:cases.filter(c=>!c.expected).length,
  hostileHostCases:hostile.length,observations,commonOfficialCases:common,census,
  boundary:'Safe Lean exact-byte certificate and normalized checker source proofs; generated-code/runtime preservation remains explicit trust'};
fs.writeFileSync(path.join(dir,'receipt.json'),JSON.stringify(receipt,null,2)+'\n');
console.log('PSC1_MIN_CORE_INGRESS_PASS '+JSON.stringify(receipt));
