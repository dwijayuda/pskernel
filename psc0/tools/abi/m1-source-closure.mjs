// Full combined source-closure gate after a frontend change. The prior M1
// artifact is reused only when every current compiler source digest matches.
// Build a baseline with the already-qualified Translate.ps or a candidate with
// all five v7 modules, each in one ordered preparation. A separate job compares
// their complete products. Historical Translate.lean is NOT the right baseline.
import assert from 'node:assert/strict';
import {readFile,writeFile,mkdir} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {createRequire} from 'node:module';
import {spawnSync} from 'node:child_process';
import {pathToFileURL} from 'node:url';
import path from 'node:path';
import {transferPscv0Ast,V7_REFERENCE_SHA} from './transport.mjs';

assert.equal(process.platform,'linux');
assert(process.argv[2]&&process.argv[3]&&process.argv[4]&&['baseline','candidate'].includes(process.argv[5]),
 'pass M1 bootstrap artifact, retained compiler, source commit, and baseline/candidate');
const cache=path.resolve(process.argv[2]),installed=path.resolve(process.argv[3]);
const hash=b=>createHash('sha256').update(b).digest('hex');
const prior=JSON.parse(await readFile(path.join(cache,'report.json'),'utf8'));
assert.equal(prior.schema,'psc0-v7-m1-compiler-qualification/1');
assert.equal(prior.source,process.argv[4]);
// The initial job's generation and 28-case gate passed; its later comparison
// used historical Translate.lean by mistake. Accept only that exact diagnosed
// failure, or a complete bootstrap receipt. The new pair restores the correct
// Translate.ps baseline and still requires full admission/TS/JS equality.
if(prior.phase!=='complete'){
 assert.equal(prior.phase,'real v7 source Ps.Syntax.Translate');
 assert(prior.failure.startsWith('Ps.Syntax.Translate canonical admissions changed'));
 assert.equal(prior.sourceChecks.length,0);
}
assert.equal(prior.prepared.length,21);
assert.equal(prior.generatedCorpusPassed,true);
assert.equal(prior.referenceSha256,V7_REFERENCE_SHA);
assert.equal(prior.closure.length,21);
assert.equal(hash(await readFile('PSCV0_LANGUAGE_REFERENCE.md')),V7_REFERENCE_SHA);
const start=performance.now();
const paths=new Set(),modules=new Set();
for(const row of prior.closure){
 assert(/^packages\/(syntax|foundation)\/src\/Ps\/(Syntax|Foundation)\/(?:[A-Za-z_0-9]+\/)*[A-Za-z_0-9]+\.lean$/.test(row.path));
 assert(!paths.has(row.path)&&!modules.has(row.module),'duplicate source input');
 paths.add(row.path);modules.add(row.module);
 assert.equal(hash(await readFile(row.path)),row.rawSha256,'M1_CACHE_STALE: '+row.path);
}
const oldTS=await readFile(path.join(cache,'index.ts'),'utf8');
const oldAdmissions=await readFile(path.join(cache,'bridge.admissions.json'),'utf8');
assert.equal(hash(oldTS),prior.typeScriptSha256);
assert.equal(hash(oldAdmissions),prior.admissionsSha256);
assert.equal(hash(await readFile(path.join(cache,'index.js'))),prior.jsSha256);
const compilerFile=path.join(installed,'node_modules/@proofscript/compiler/dist/index.js');
assert.equal(prior.builderJsSha256,'6cddc3c34c38f1524ef9a355c46b0eb17949c45c54fd59367ea370c1af861ab3');
assert.equal(hash(await readFile(compilerFile)),prior.builderJsSha256);
const B=await import(pathToFileURL(path.join(cache,'index.js')).href);
const C=await import(pathToFileURL(compilerFile).href);
assert.equal(B.psPscv0ReferenceSha256,V7_REFERENCE_SHA);
assert.equal(typeof B.psPscv0ReadAnnotation,'function');
const first=JSON.parse(await readFile('pscv0-authoring.json','utf8'));
const more=JSON.parse(await readFile('pscv0-fast-candidates.json','utf8'));
assert.equal(first.referenceSha256,V7_REFERENCE_SHA);
assert.equal(more.referenceSha256,V7_REFERENCE_SHA);
const available=[...first.modules,...more.modules];
assert.deepEqual(available.map(m=>m.module).sort(),['Ps.Foundation.List','Ps.Foundation.Source','Ps.Syntax.Cursor','Ps.Syntax.Token','Ps.Syntax.Translate']);
const selected=new Map(available.map(m=>[m.module,m]));
assert.equal(selected.size,5);
for(const [module,m] of selected){
 const row=prior.closure.find(x=>x.module===module);
 assert(row&&row.path===(m.baseline||m.baselineSource));
}
const mode=process.argv[5];
if(mode==='baseline')for(const module of selected.keys())if(module!=='Ps.Syntax.Translate')selected.delete(module);

function imports(source){
 const items=[];
 for(const line of source.split(/\r?\n/u)){
  if(!/^\s*import\b/u.test(line))continue;
  const match=line.match(/^\s*import\s+([A-Za-z_][A-Za-z_0-9.]*)\s*$/u);
  assert(match,'unrecognized source import: '+JSON.stringify(line));
  items.push(match[1]);
 }
 assert.equal(new Set(items).size,items.length,'duplicate source import');
 return items;
}
const tag=o=>o&&typeof o==='object'?
 Object.getOwnPropertySymbols(o).map(s=>o[s]).find(v=>typeof v==='string'):undefined;
function ok(v,context){
 if(tag(v)!=='ok')throw Error(context+': '+String(v?.error??tag(v)));
 return v.value;
}
const consumed=text=>text.split(/\r?\n/u).filter(s=>!/^\s*import\s+[A-Za-z_][A-Za-z_0-9.]*\s*$/u.test(s)).join('\n');

const dir=path.resolve('dist/pscv0-m1-source-closure/'+mode);
await mkdir(dir,{recursive:true});
const report={schema:'psc0-v7-m1-combined-source-closure/2',mode,source:process.env.GITHUB_SHA,
 frontendSource:prior.source,frontendJsSha256:prior.jsSha256,
 referenceSha256:V7_REFERENCE_SHA,builderJsSha256:prior.builderJsSha256,
 sourceValidationMs:Math.round(performance.now()-start),phase:'prepare',modules:[],
 selectedV7Modules:selected.size,totalModules:21,windowsTestsExecuted:false,kernelTestsExecuted:false,
 independentlyKernelAdmitted:false,fullV7Conformance:false,fullCompilerSelfhostFixedPoint:false};
const checkpoint=()=>writeFile(path.join(dir,'report.json'),JSON.stringify(report,null,2)+'\n');
try{
 await checkpoint();
 let state=C.psCompilerPreparationStart(C.PsCompilerSourceKind.lean);
 const prepStart=performance.now();
 for(const row of prior.closure){
  const t0=performance.now(),m=selected.get(row.module),raw=await readFile(row.path,'utf8');
  report.phase='prepare '+row.module;await checkpoint();
  let ast,sourcePath=row.path,sourceSha=row.rawSha256,nodes=null;
  if(m){
   const source=await readFile(m.source,'utf8');
   assert.deepEqual(imports(source),imports(raw));
   const surface=ok(B.psPscv0ParseSource(true,source),row.module+' v7 parse');
   assert.equal(B.psPscv0ReplayOriginal(surface),source);
   const lowered=ok(B.psPscv0LowerModule(surface),row.module+' v7 lowering');
   const transferred=transferPscv0Ast(B,C,lowered,source);
   ast=transferred.module;sourcePath=m.source;sourceSha=hash(source);nodes=transferred.receipt.normalizedNodes;
  }else ast=ok(C.psCompilerParseSource(C.PsCompilerSourceKind.lean,consumed(raw)),row.module+' retained Lean');
  state=ok(C.psCompilerPreparationStepParsedWithOrigins(state,ast),row.module+' prepare').state;
  const item={module:row.module,path:sourcePath,sourceKind:m?'pscv0-v7':'lean-retained',
   sourceSha256:sourceSha,astNodes:nodes,elapsedMs:Math.round(performance.now()-t0)};
  report.modules.push(item);console.log('PSCV0_M1_CLOSURE_PREPARED: '+JSON.stringify(item));await checkpoint();
 }
 report.preparationMs=Math.round(performance.now()-prepStart);
 report.phase='emit';await checkpoint();
 const emitStart=performance.now();
 const prepared=ok(C.psCompilerPreparationFinish(state),'finish');
 const admissions=ok(C.psCompilerAdmissionsFromPrepared(prepared),'admissions');
 const ts=ok(C.psCompilerTypeScriptFromPrepared(prepared),'TypeScript');
 await writeFile(path.join(dir,'index.ts'),ts);
 await writeFile(path.join(dir,'bridge.admissions.json'),admissions);
 await writeFile(path.join(dir,'package.json'),'{"type":"module","private":true}\n');
 report.admissionsSha256=hash(admissions);report.typeScriptSha256=hash(ts);
 report.emissionMs=Math.round(performance.now()-emitStart);
 report.generatedTypeScriptBytes=Buffer.byteLength(ts);await checkpoint();
 report.phase='typescript7';await checkpoint();
 const tsStart=performance.now();
 const req=createRequire(path.join(installed,'package.json'));
 const metaPath=req.resolve('typescript/package.json'),meta=JSON.parse(await readFile(metaPath,'utf8'));
 assert.equal(meta.version,'7.0.2');
 const bin=path.join(path.dirname(metaPath),typeof meta.bin==='string'?meta.bin:meta.bin.tsc);
 const compiled=spawnSync(process.execPath,[bin,'--ignoreConfig',path.join(dir,'index.ts'),
 '--target','ES2022','--module','ES2022','--moduleResolution','bundler','--strict',
 '--declaration','--sourceMap','--skipLibCheck','--noEmitOnError','--pretty','false'],
 {encoding:'utf8',timeout:180000,maxBuffer:8*1024*1024});
 assert(!compiled.error&&compiled.status===0,String(compiled.error||compiled.stderr||compiled.stdout));
 const js=await readFile(path.join(dir,'index.js'));
 report.jsSha256=hash(js);report.generatedJavaScriptBytes=js.length;
 report.typeScriptCompileMs=Math.round(performance.now()-tsStart);
 report.phase='runtime';await checkpoint();
 const runtimeStart=performance.now();
 const checked=spawnSync(process.execPath,['scripts/pscv0-m1-check.mjs',path.join(dir,'index.js')],
 {encoding:'utf8',timeout:120000,maxBuffer:8*1024*1024});
 process.stdout.write(checked.stdout||'');
 assert(!checked.error&&checked.status===0,String(checked.error||checked.stderr||checked.stdout));
 report.generatedCorpusPassed=true;report.generatedCorpusMs=Math.round(performance.now()-runtimeStart);
 report.phase='complete';report.elapsedMs=Math.round(performance.now()-start);await checkpoint();
 console.log('PSCV0_M1_CLOSURE_STAGE: PASS '+JSON.stringify(report));
}catch(error){report.failure=error.message;report.elapsedMs=Math.round(performance.now()-start);await checkpoint();throw error;}
