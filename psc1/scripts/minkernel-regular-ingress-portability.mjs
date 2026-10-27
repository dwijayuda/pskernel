// All project execution in this driver belongs to GitHub Actions Linux.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { pathToFileURL } from 'node:url';
import { resolveTypeScriptCli, typeScriptProfileArgs } from './typescript-cli.mjs';
import { createRegularCoreIngress, regularIngressLimits } from '../packages/pskernel-min/host/ingress.mjs';
assert.equal(process.platform,'linux');
assert.match(process.env.GITHUB_SHA||'',/^[a-f0-9]{40}$/);
const dir='dist/pskernel-min/regular-ingress',stem=path.join(dir,'vectors');
fs.mkdirSync(dir,{recursive:true});
fs.writeFileSync(path.join(dir,'package.json'),'{"type":"module"}\n');
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
function run(command,args,input,cwd,timeout=240000){
 const r=spawnSync(command,args,{input,cwd,encoding:'utf8',timeout,maxBuffer:32*1024*1024});
 assert.equal(r.error,undefined,String(r.error));assert.equal(r.status,0,r.stdout+'\n'+r.stderr);return r.stdout;
}
if(process.argv[2]==='--generated-self'){
 const G=await import(pathToFileURL(path.resolve(stem+'.js')).href);
 const bytes=new Uint8Array(fs.readFileSync(path.join(dir,'runtime.admissions.json')));
 const start=performance.now(),result=createRegularCoreIngress(G)(bytes);
 const observation={accepted:result.accepted,code:result.code,delegated:result.delegated,
  bytes:bytes.length,sha256:sha(bytes),elapsedMs:performance.now()-start,resourceUsage:process.resourceUsage()};
 fs.writeFileSync(path.join(dir,'generated-self.json'),JSON.stringify(observation,null,2)+'\n');
 console.log('PSC1_MIN_REGULAR_INGRESS_GENERATED_SELF '+JSON.stringify(observation));
 assert.equal(result.accepted,true,'complete owned runtime self-admission');
 process.exit(0);
}
run('lake',['env','lean','--run','scripts/MinKernelSourceCompile.lean','regular-ingress']);
const admissionBytes=fs.readFileSync(stem+'.admissions.json');
const official=JSON.parse(run('.lake/build/bin/psc1_independent_checker',['--check'],admissionBytes));
assert.equal(official.accepted,true);
assert.equal(official.leanVersion,'4.35.0');
assert.equal(official.leanCommit,'eb6cafb7290e8bd5f2937522d8d804f58f02bafc');
const report=JSON.parse(fs.readFileSync(stem+'.source.json'));
assert.equal(report.moduleCount,10);assert.equal(report.origins.length,10);
run(process.execPath,[resolveTypeScriptCli(),...typeScriptProfileArgs([stem+'.ts','--target','ES2022',
 '--module','ES2022','--moduleResolution','bundler','--strict','--skipLibCheck','--noEmitOnError','--pretty','false'])]);
const G=await import(pathToFileURL(path.resolve(stem+'.js')).href);
const check=createRegularCoreIngress(G);
const cases=JSON.parse(fs.readFileSync('scripts/minkernel-regular-ingress-cases.json'));
run('lake',['build','minkernel_regular_ingress_tests'],undefined,'packages/pskernel-min');
const native=run('.lake/build/bin/minkernel_regular_ingress_tests',
 ['--cases','../../scripts/minkernel-regular-ingress-cases.json'],undefined,'packages/pskernel-min');
fs.writeFileSync(path.join(dir,'native-tests.log'),native);
const nativeRows=[...native.matchAll(/^PSC1_MIN_REGULAR_INGRESS_VECTOR ([0-9]+) (true|false)$/gm)];
assert.equal(nativeRows.length,cases.length);
const observations=[],officialCommon=[];
for(const c of cases){
 assert.equal(nativeRows[c.index][2],String(c.expected),c.id+' native');
 const bytes=new Uint8Array(Buffer.from(c.source)),result=check(bytes);
 observations.push({id:c.id,index:c.index,expected:c.expected,accepted:result.accepted,code:result.code,bytes:bytes.length,sha256:sha(bytes)});
 fs.writeFileSync(path.join(dir,'observations.json'),JSON.stringify(observations,null,2)+'\n');
 assert.equal(result.accepted,c.expected,c.id+' generated '+result.code);
 assert.equal(result.delegated,false);
 if(c.expected){const answer=JSON.parse(run('.lake/build/bin/psc1_independent_checker',['--check'],c.source));
  officialCommon.push({id:c.id,accepted:answer.accepted});assert.equal(answer.accepted,true,c.id+' official');}
}
let touched=0;
const sample=new Uint8Array(Buffer.from(cases[1].source));
const hostile=[['object',{get length(){touched++;throw Error('get');}}],['array',Array.from(sample)],
 ['buffer',Buffer.from(sample)],['proxy',new Proxy(sample,{get(){touched++;throw Error('proxy');}})],
 ['subclass',new (class extends Uint8Array{})(sample)],['dataview',new DataView(sample.buffer)],
 ['cyclic',(()=>{const x={};x.x=x;return x;})()],['oversize',new Uint8Array(regularIngressLimits.bytes+1)],
 ['invalid-utf8',new Uint8Array([255])],['json-depth',new Uint8Array(Buffer.from('['.repeat(770)+']'.repeat(770)))],
 ['json-containers',new Uint8Array(Buffer.from('['+'{},'.repeat(131072)+'{}]'))]];
if(typeof SharedArrayBuffer==='function')hostile.push(['shared',new Uint8Array(new SharedArrayBuffer(1))]);
for(const [id,input]of hostile){const r=check(input);assert.equal(r.accepted,false,id);assert.equal(r.delegated,false,id);
 observations.push({id:'host-'+id,accepted:false,code:r.code});}
assert.equal(touched,0);
const own=new Uint8Array(sample);
Object.defineProperty(own,'length',{get(){touched++;throw Error('length');}});
Object.defineProperty(own,Symbol.iterator,{get(){touched++;throw Error('iterator');}});
assert.equal(check(own).accepted,true);assert.equal(touched,0);
const stable=v=>Array.isArray(v)?v.map(stable):v&&typeof v==='object'
 ?Object.fromEntries(Object.keys(v).sort().map(k=>[k,stable(v[k])])):v;
const key=n=>JSON.stringify(stable(n));
const wire=JSON.parse(admissionBytes),runtimeOrigins=report.origins.slice(0,9);
const names=new Set(runtimeOrigins.flatMap(m=>m.batches.flatMap(b=>b.members.map(x=>key(x.nameWire)))));
const owned=r=>r.kind==='constant'?[r.declaration.n]:r.kind==='inductive'
 ?r.declaration.ts.flatMap(t=>[t.n,...t.cs.map(c=>c.n)]):[];
const runtimeRecords=wire.admissions.filter(r=>owned(r).some(n=>names.has(key(n))));
const runtime={...wire,admissions:runtimeRecords},runtimeBytes=JSON.stringify(runtime);
fs.writeFileSync(path.join(dir,'runtime.admissions.json'),runtimeBytes);
assert.ok(Buffer.byteLength(runtimeBytes)<=regularIngressLimits.bytes,'complete runtime packet exceeds declared profile');
const runtimeOfficial=JSON.parse(run('.lake/build/bin/psc1_independent_checker',['--check'],runtimeBytes));
assert.equal(runtimeOfficial.accepted,true);
const sources=['RegularProfile','RegularCheck','OperationalProfile','OperationalCheck','CoreBytes','CoreIngress',
 'RegularIngressProfile','RegularIngressCheck','RegularIngressBytes'].map(n=>'packages/pskernel-min/src/Ps/MinKernel/Profile/'+n+'.lean');
const receipt={schema:'psc1-min-regular-ingress-portability/1',commit:process.env.GITHUB_SHA,authoritative:false,
 productionCanonicalMinDual:false,sourceIdentities:sources.map(p=>({path:p,bytes:fs.statSync(p).size,sha256:sha(fs.readFileSync(p))})),
 sourceReport:report,officialSourceAdmission:official,officialCommon,runtimeOfficial,
 generatedTsBytes:fs.statSync(stem+'.ts').size,generatedJsBytes:fs.statSync(stem+'.js').size,
 runtime:{modules:9,originMembers:names.size,admissionRecords:runtimeRecords.length,bytes:Buffer.byteLength(runtimeBytes),sha256:sha(runtimeBytes)},
 positives:cases.filter(c=>c.expected).length,refusals:cases.filter(c=>!c.expected).length,hostile:hostile.length,observations,
 nativeSelf:false,generatedSelf:false,boundary:'Runtime execution evidence; full raw source and streaming wire proof obligations remain separate.'};
const save=()=>fs.writeFileSync(path.join(dir,'receipt.json'),JSON.stringify(receipt,null,2)+'\n');save();
console.log('PSC1_MIN_REGULAR_INGRESS_FIXTURES_PASS '+JSON.stringify(receipt.runtime));
const selfNative=run('.lake/build/bin/minkernel_regular_ingress_tests',
 ['--self','../../'+path.join(dir,'runtime.admissions.json')],undefined,'packages/pskernel-min');
fs.writeFileSync(path.join(dir,'native-self.log'),selfNative);
assert.match(selfNative,/PSC1_MIN_REGULAR_INGRESS_NATIVE_SELF true/);receipt.nativeSelf=true;save();
const selfGenerated=run(process.execPath,['--max-old-space-size=256','scripts/minkernel-regular-ingress-portability.mjs','--generated-self']);
fs.writeFileSync(path.join(dir,'generated-self.log'),selfGenerated);
receipt.generatedSelf=true;receipt.generatedSelfObservation=JSON.parse(fs.readFileSync(path.join(dir,'generated-self.json')));save();
console.log('PSC1_MIN_REGULAR_INGRESS_PORTABILITY_PASS');
