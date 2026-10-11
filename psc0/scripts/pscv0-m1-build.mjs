// Regenerate the current 21-module frontend once, then reuse live immutable
// preparation prefixes to qualify five real v7 source modules. Linux compiler
// development only: no kernel check, native parser fallback or cached grammar.
import assert from 'node:assert/strict';
import {readFile,writeFile,mkdir} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {createRequire} from 'node:module';
import {spawnSync} from 'node:child_process';
import {pathToFileURL} from 'node:url';
import path from 'node:path';
import {transferPscv0Ast,V7_REFERENCE_SHA} from '../tools/abi/transport.mjs';

assert.equal(process.platform,'linux');
assert(process.argv[2]&&process.argv[3],'pass old provenance artifact and retained compiler');
const root=process.cwd(),cache=path.resolve(process.argv[2]),installed=path.resolve(process.argv[3]);
const dir=path.join(root,'dist/pscv0-m1');
const hash=b=>createHash('sha256').update(b).digest('hex');
const tag=o=>o&&typeof o==='object'?Object.getOwnPropertySymbols(o).map(s=>o[s]).find(v=>typeof v==='string'):undefined;
const printable=o=>typeof o==='bigint'?o.toString():!o||typeof o!=='object'?o:
 Object.fromEntries([...Object.entries(o).map(([k,v])=>[k,printable(v)]),...(tag(o)?[['constructor',tag(o)]]:[])]);
function ok(r,phase){
 if(tag(r)!=='ok')throw Error(phase+': '+JSON.stringify(printable(r)));
 return r.value;
}
const old=JSON.parse(await readFile(path.join(cache,'bootstrap/build-report.json'),'utf8'));
assert.equal(old.source,'a640a2d22adeabd4ca7919839a8991667bcc3eae');
assert.equal(old.referenceSha256,V7_REFERENCE_SHA);
assert.equal(old.closure.length,20);
assert.equal(hash(await readFile('PSCV0_LANGUAGE_REFERENCE.md')),V7_REFERENCE_SHA);
const compilerFile=path.join(installed,'node_modules/@proofscript/compiler/dist/index.js');
const builderSha=hash(await readFile(compilerFile));
assert.equal(builderSha,'6cddc3c34c38f1524ef9a355c46b0eb17949c45c54fd59367ea370c1af861ab3');
assert.equal(builderSha,old.builderJsSha256);
const C=await import(pathToFileURL(compilerFile).href);
const first=JSON.parse(await readFile('pscv0-authoring.json','utf8'));
const more=JSON.parse(await readFile('pscv0-fast-candidates.json','utf8'));
assert.equal(first.referenceSha256,V7_REFERENCE_SHA);assert.equal(more.referenceSha256,V7_REFERENCE_SHA);
const selected=new Map([...first.modules,...more.modules].map(m=>[m.module,m]));
assert.equal(selected.size,5);
const imports=s=>s.split(/\r?\n/u).filter(x=>/^\s*import\s/u.test(x)).map(x=>{
 const m=x.match(/^\s*import\s+(Ps\.(?:Foundation|Syntax)\.[A-Za-z_0-9.]+)\s*$/u);
 assert(m,'unapproved import '+x);return m[1];
});
const consumed=s=>s.split(/\r?\n/u).filter(x=>!/^\s*import\s/u.test(x)).join('\n');
const order=[],seen=new Set(),active=new Set();
async function visit(module){
 assert(!active.has(module),'import cycle '+module);if(seen.has(module))return;
 assert(/^Ps\.(?:Foundation|Syntax)\.[A-Za-z_0-9.]+$/.test(module));
 const parts=module.split('.'),file='packages/'+parts[1].toLowerCase()+'/src/'+parts.join('/')+'.lean';
 const raw=await readFile(file,'utf8');active.add(module);
 for(const dep of imports(raw))await visit(dep);
 active.delete(module);seen.add(module);
 order.push({module,path:file,rawSha256:hash(raw),sourceKind:'lean',source:consumed(raw)});
}
await visit('Ps.Syntax.Pscv0.Module');
assert.equal(order.length,21);
const frozen=old.closure.filter(x=>!x.module.startsWith('Ps.Syntax.Pscv0.'));
assert.equal(frozen.length,15);
for(const row of frozen){
 const current=order.find(x=>x.module===row.module);
 assert(current&&current.path===row.path);
 assert.equal(current.rawSha256,row.rawSha256,'frozen predecessor changed: '+row.module);
}
assert(order.filter(x=>x.module.startsWith('Ps.Syntax.Pscv0.')).length===6);
await mkdir(dir,{recursive:true});
const start=performance.now();
const report={schema:'psc0-v7-m1-compiler-qualification/1',source:process.env.GITHUB_SHA,
 referenceSha256:V7_REFERENCE_SHA,builderJsSha256:builderSha,phase:'preflight',
 closure:order.map(({source,...row})=>row),prepared:[],sourceChecks:[],
 windowsTestsExecuted:false,kernelTestsExecuted:false,independentlyKernelAdmitted:false,
 fullV7Conformance:false,fullCompilerSelfhostFixedPoint:false};
const checkpoint=()=>writeFile(path.join(dir,'report.json'),JSON.stringify(report,null,2)+'\n');
const parsed=new Map(),prefixes=new Map();
try{
 await checkpoint();
 for(const row of order){
  parsed.set(row.module,ok(C.psCompilerParseSource(C.PsCompilerSourceKind.lean,row.source),'parse '+row.module));
 }
 let state=C.psCompilerPreparationStart(C.PsCompilerSourceKind.lean);
 const prepStart=performance.now();
 for(const row of order){
  const before=state,t0=performance.now();
  report.phase='prepare '+row.module;await checkpoint();
  console.log('PSCV0_M1_PREPARING: '+row.module);
  state=ok(C.psCompilerPreparationStepParsedWithOrigins(state,parsed.get(row.module)),'prepare '+row.module).state;
  if(selected.has(row.module))prefixes.set(row.module,{before,after:state});
  const item={module:row.module,elapsedMs:Math.round(performance.now()-t0)};
  report.prepared.push(item);console.log('PSCV0_M1_PREPARED: '+JSON.stringify(item));
  await checkpoint();
 }
 report.preparationMs=Math.round(performance.now()-prepStart);
 report.phase='emit';await checkpoint();
 const prepared=ok(C.psCompilerPreparationFinish(state),'finish');
 const admissions=ok(C.psCompilerAdmissionsFromPrepared(prepared),'admissions');
 const ts=ok(C.psCompilerTypeScriptFromPrepared(prepared),'TypeScript');
 await writeFile(path.join(dir,'index.ts'),ts);
 await writeFile(path.join(dir,'bridge.admissions.json'),admissions);
 await writeFile(path.join(dir,'package.json'),'{"type":"module","private":true}\n');
 report.typeScriptSha256=hash(ts);report.admissionsSha256=hash(admissions);
 report.phase='typescript7';await checkpoint();
 const req=createRequire(path.join(installed,'package.json'));
 const metaPath=req.resolve('typescript/package.json'),meta=JSON.parse(await readFile(metaPath,'utf8'));
 assert.equal(meta.version,'7.0.2');
 const bin=path.join(path.dirname(metaPath),typeof meta.bin==='string'?meta.bin:meta.bin.tsc);
 const compiled=spawnSync(process.execPath,[bin,'--ignoreConfig',path.join(dir,'index.ts'),
 '--target','ES2022','--module','ES2022','--moduleResolution','bundler','--strict',
 '--declaration','--sourceMap','--skipLibCheck','--noEmitOnError','--pretty','false'],
 {encoding:'utf8',timeout:180000,maxBuffer:8*1024*1024});
 assert(!compiled.error&&compiled.status===0,String(compiled.error||compiled.stderr||compiled.stdout));
 report.jsSha256=hash(await readFile(path.join(dir,'index.js')));
 report.phase='generated corpus';await checkpoint();
 const checked=spawnSync(process.execPath,['scripts/pscv0-m1-check.mjs',path.join(dir,'index.js')],
 {encoding:'utf8',timeout:120000,maxBuffer:8*1024*1024});
 process.stdout.write(checked.stdout||'');
 assert(!checked.error&&checked.status===0,String(checked.error||checked.stderr||checked.stdout));
 report.generatedCorpusPassed=true;
 const B=await import(pathToFileURL(path.join(dir,'index.js')).href);
 assert.equal(B.psPscv0ReferenceSha256,V7_REFERENCE_SHA);
 for(const [module,m] of selected){
  report.phase='real v7 source '+module;await checkpoint();
  const t0=performance.now(),source=await readFile(m.source,'utf8');
  const row=order.find(x=>x.module===module);
  assert.equal(m.baseline||m.baselineSource,row.path);
  assert.deepEqual(imports(source),imports(await readFile(row.path,'utf8')));
  const surface=ok(B.psPscv0ParseSource(true,source),'v7 parse '+module);
  assert.equal(B.psPscv0ReplayOriginal(surface),source);
  const syntax=ok(B.psPscv0LowerModule(surface),'lower '+module);
  const transferred=transferPscv0Ast(B,C,syntax,source);
  const prefix=prefixes.get(module);assert(prefix);
  const next=ok(C.psCompilerPreparationStepParsedWithOrigins(prefix.before,transferred.module),'v7 preparation '+module).state;
  const baseline=ok(C.psCompilerPreparationFinish(prefix.after),'baseline finish '+module);
  const candidate=ok(C.psCompilerPreparationFinish(next),'v7 finish '+module);
  const oldAdmissions=ok(C.psCompilerAdmissionsFromPrepared(baseline),'baseline admissions');
  const newAdmissions=ok(C.psCompilerAdmissionsFromPrepared(candidate),'v7 admissions');
  const oldTS=ok(C.psCompilerTypeScriptFromPrepared(baseline),'baseline TS');
  const newTS=ok(C.psCompilerTypeScriptFromPrepared(candidate),'v7 TS');
  assert.equal(newAdmissions,oldAdmissions,module+' canonical admissions changed');
  assert.equal(newTS,oldTS,module+' TypeScript changed');
  const item={module,path:m.source,sourceSha256:hash(source),astNodes:transferred.receipt.normalizedNodes,
   admissionsSha256:hash(newAdmissions),typeScriptSha256:hash(newTS),
   admissionsIdentical:true,typeScriptIdentical:true,elapsedMs:Math.round(performance.now()-t0)};
  report.sourceChecks.push(item);console.log('PSCV0_M1_V7_SOURCE: PASS '+JSON.stringify(item));await checkpoint();
 }
 report.phase='complete';report.elapsedMs=Math.round(performance.now()-start);await checkpoint();
 console.log('PSCV0_M1_PORTABLE: PASS '+JSON.stringify(report));
}catch(error){
 report.failure=error.message;report.elapsedMs=Math.round(performance.now()-start);
 await checkpoint();throw error;
}
