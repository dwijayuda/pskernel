// Actual admitted compiler module and separate test consumers; Linux Actions only.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {pathToFileURL} from 'node:url';
import {readOwnedCompilerSources} from '../host-tools/compiler-source-inputs.mjs';
import {resolveTypeScriptCli,typeScriptProfileArgs} from './typescript-cli.mjs';
assert.equal(process.platform,'linux');assert.equal(process.env.GITHUB_ACTIONS,'true');
const root='dist/pskernel-min/module-matrix',dir=path.join(root,'source-runtime');fs.mkdirSync(dir,{recursive:true});
fs.writeFileSync(path.join(dir,'package.json'),'{"type":"module"}\n');
const sha=x=>crypto.createHash('sha256').update(x).digest('hex');
function run(command,args,input){const r=spawnSync(command,args,{input,encoding:'utf8',timeout:240000,maxBuffer:32*1024*1024});
 assert.equal(r.error,undefined,String(r.error));assert.equal(r.status,0,r.stdout+'\n'+r.stderr);return r.stdout;}
const matrix=JSON.parse(fs.readFileSync(path.join(root,'matrix.json')));
const row=matrix.rows.find(r=>r.module==='Ps.Foundation.Source');assert.equal(row.admissionQualified,true);
const sources=readOwnedCompilerSources('Ps.MinKernel.Tests.SourcePositions');assert.equal(sources.length,2);
const actual=sources.find(s=>s.module==='Ps.Foundation.Source');assert.ok(actual);assert.equal(sha(actual.text),row.source.sha256);
fs.writeFileSync(path.join(dir,'inputs.json'),JSON.stringify(sources.map(s=>({moduleName:s.module.split('.'),source:s.text}))));
fs.writeFileSync(path.join(dir,'native.log'),run('lake',['env','lean','--run','scripts/MinKernelActualSourceModule.lean']));
run(process.execPath,[resolveTypeScriptCli(),...typeScriptProfileArgs([path.join(dir,'module.ts'),'--target','ES2022','--module','ES2022',
 '--moduleResolution','bundler','--strict','--skipLibCheck','--noEmitOnError','--pretty','false'])]);
const G=await import(pathToFileURL(path.resolve(dir,'module.js')).href);
const rows=JSON.parse(fs.readFileSync(path.join(dir,'native.json')));assert.equal(rows.length,525);
for(const test of rows){const values=test.values.map(BigInt),actual=G[test.name](...values);assert.equal(typeof actual,'bigint');assert.equal(String(actual),test.expected,test.name);}
const raw=fs.readFileSync(path.join(dir,'module.admissions.json'));assert.equal(raw.at(-1),10);
const bytes=raw.subarray(0,-1),file=path.join(dir,'module.canonical.json');fs.writeFileSync(file,bytes);
const answer=JSON.parse(run(process.execPath,['--max-old-space-size=256','scripts/minkernel-module-matrix-worker.mjs',file]));
assert.equal(answer.accepted,true,'actual module plus projection consumers must be admitted');assert.equal(answer.delegated,false);
const official=JSON.parse(run('.lake/build/bin/psc1_independent_checker',['--check'],bytes));
assert.equal(official.accepted,true);assert.equal(official.leanVersion,'4.35.0');assert.equal(official.leanCommit,'eb6cafb7290e8bd5f2937522d8d804f58f02bafc');
const policy=JSON.parse(fs.readFileSync(path.join(dir,'policy.json')));
for(const k of ['sourceAccepted','targetAccepted','originalIrAccepted'])assert.equal(policy[k],true);
for(const k of ['providerChecked','semanticContractQualified','strictSh1Qualified'])assert.equal(policy[k],false);
const receipt={schema:'psc1-first-actual-compiler-module-runtime/1',head:process.env.GITHUB_SHA,module:row.module,
 moduleSource:{path:actual.path,bytes:Buffer.byteLength(actual.text),sha256:sha(actual.text)},testConsumerCountedAsCompilerModule:false,
 cases:rows.length,nativeAndGeneratedPassed:true,min:answer,official,policy,
 files:['module.ts','module.js','module.ir.json','module.admissions.json','module.canonical.json','native.json'].map(file=>{
  const data=fs.readFileSync(path.join(dir,file));return{file,bytes:data.length,sha256:sha(data)};}),
 compilerPreservation:'not-proved',fullyCompilerQualified:false,boundary:'Real admitted compiler data module plus separately labelled projection consumers. Finite native/generated ABI observations do not establish general compiler preservation or self-hosting.'};
fs.writeFileSync(path.join(dir,'receipt.json'),JSON.stringify(receipt,null,2)+'\n');
row.runtimeQualification={cases:rows.length,finiteNativeGeneratedValidated:true,consumerPublicMinAccepted:true,receipt:'source-runtime/receipt.json',formalCompilerPreservation:false};
matrix.counts.runtimeValidatedAdmittedModules=1;
fs.writeFileSync(path.join(root,'matrix.json'),JSON.stringify(matrix,null,2)+'\n');
console.log('PSC1_FIRST_ACTUAL_MODULE_RUNTIME_PASS '+JSON.stringify({module:row.module,cases:rows.length,minAccepted:true,fullyCompilerQualified:false}));
