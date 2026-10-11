// Linux-only, compiler-package source milestone.
// Compile the qualified 20-source PSC0 syntax/foundation closure once,
// selecting five actual PSCV0 v7-authored compiler modules simultaneously.
// The old compiler is the retained self-host bootstrap; the generated PSCV0
// frontend is an exact SHA-guarded artifact. No kernel or Windows tests.
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFile,mkdir,writeFile } from 'node:fs/promises';
import { createRequire } from 'node:module';
import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { transferPscv0Ast,AST_ABI_VERSION,V7_REFERENCE_SHA } from './transport.mjs';
import { loadQualifiedCompilerCache,hash } from './qualified-cache.mjs';

assert(process.platform==='linux','this compiler-development qualification runs only on Linux');
assert(process.argv[2]&&process.argv[3],
 'pass existing exact generated bootstrap cache and pinned retained compiler');
const root=process.cwd();
const artifact=path.resolve(process.argv[2]),installed=path.resolve(process.argv[3]);
const begin=performance.now();
const {B,C,report:sourceReport,sourceValidationMs}=
 await loadQualifiedCompilerCache({root,cache:artifact,installed});
const candidate=JSON.parse(await readFile(path.join(root,'pscv0-linux-source-closure.json'),'utf8'));
assert.equal(candidate.schema,'psc0-linux-v7-compiler-source-closure/1');
assert.equal(candidate.status,'candidate-unqualified-until-cloud-linux-run-success');
assert.equal(candidate.referenceSha256,V7_REFERENCE_SHA);
assert.equal(candidate.verifiedCachedFrontendSource,sourceReport.source);
assert.equal(candidate.compilerOnly,true);
assert.equal(candidate.linuxOnly,true);
assert.equal(candidate.windows,'static-portability-pattern-only-not-executed');
assert.equal(candidate.independentlyCheckedKernelTests,false);
assert.equal(candidate.sourceAuthority,'sole-v7');
assert.equal(candidate.expectedGeneratedCompilerClosureModules,sourceReport.closure.length);
assert(Array.isArray(candidate.selectedModules)&&candidate.selectedModules.length===5);
const selected=new Set(candidate.selectedModules);
assert.equal(selected.size,5,'duplicate selected source module');
const first=JSON.parse(await readFile(path.join(root,candidate.firstModuleAuthoring),'utf8'));
assert.equal(first.referenceSha256,V7_REFERENCE_SHA);
assert.equal(first.language,'pscv0');
assert.equal(first.sourcePolicy,'pscv0-v7-only-no-legacy-fallback');
assert.equal(first.backwardCompatibilityRequired,false);
assert.equal(first.modules.length,1);
const others=JSON.parse(await readFile(path.join(root,candidate.sourceRegistry),'utf8'));
assert.equal(others.schema,'psc0-compiler-source-candidates/1');
assert.equal(others.referenceSha256,V7_REFERENCE_SHA);
assert(others.modules.length>=4&&others.modules.length<=16);
const locations=new Map();
for(const [type,m] of [['first',first.modules[0]],...others.modules.map(m=>['additional',m])]){
 assert(/^Ps\.(?:Syntax|Foundation)\.[A-Za-z_][A-Za-z_0-9]*$/.test(m.module),
   'invalid compiler module identity');
 assert(selected.has(m.module),'selected module missing from exact source manifest: '+m.module);
 assert(!locations.has(m.module),'duplicate selected module in source registry');
 const [namespace,pkg,file]=m.module.split('.');
 const owner=pkg.toLowerCase();
 const baseline=type==='first'?m.baselineSource:m.baseline;
 assert.equal(baseline,'packages/'+owner+'/src/Ps/'+pkg+'/'+file+'.lean',
   'historical baseline path does not match module identity');
 assert.equal(m.source,'packages/'+owner+'/src-ps/Ps/'+pkg+'/'+file+'.ps',
   'PSCV0 source path must derive from exact module identity');
 locations.set(m.module,{sourcePath:m.source,baselinePath:baseline});
}
assert.equal(locations.size,selected.size,'candidate manifest does not cover all selections');
const upstream=JSON.parse(await readFile(path.join(artifact,'build-report.json'),'utf8'));
assert.equal(upstream.schema,'psc0-pscv0-portable-bridge-build/1');
assert.equal(upstream.stage,'ps-authoring-candidate');
assert.equal(upstream.source,sourceReport.source);
assert.equal(upstream.referenceSha256,V7_REFERENCE_SHA);
assert.equal(upstream.bridgeJsSha256,hash(await readFile(path.join(artifact,'index.js'))));
const oldTS=await readFile(path.join(artifact,'index.ts'),'utf8');
const oldAdmissions=await readFile(path.join(artifact,'bridge.admissions.json'),'utf8');
assert.equal(hash(oldTS),upstream.bridgeTypeScriptSha256);
assert.equal(hash(oldAdmissions),upstream.admissionsSha256);

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
function diff(left,right){
 if(left===right)return null;
 let i=0;while(i<left.length&&i<right.length&&left[i]===right[i])i++;
 return {byte:i,old:left.slice(Math.max(0,i-110),i+200),
   new:right.slice(Math.max(0,i-110),i+200),oldBytes:left.length,newBytes:right.length};
}
const dir=path.join(root,'dist/pscv0-linux-source-closure');
await mkdir(dir,{recursive:true});
const checkpoint=async progress=>writeFile(path.join(dir,'progress.json'),JSON.stringify(progress,null,2)+'\n');
const progress={phase:'prepare',compiler:'retained self-hosted PSC0 JS',source:process.env.GITHUB_SHA||null,
  sourceInputSha256:hash(await readFile(path.join(root,'pscv0-linux-source-closure.json'))),
  selectedV7:[...selected],prepared:[],failure:null};
await checkpoint(progress);
let state=C.psCompilerPreparationStart(C.PsCompilerSourceKind.lean);
const preparedModules=[];
const startPrep=performance.now();
for(const row of sourceReport.closure){
 const start=performance.now();
 const useV7=selected.has(row.module);
 progress.phase='prepare '+row.module;
 await checkpoint(progress);
 const oldPath=path.join(root,row.path);
 const oldFile=await readFile(oldPath,'utf8');
 assert.equal(hash(oldFile),row.rawSha256,'original source closure unexpectedly changed');
 let ast,sourceSha,sourcePath,nodes=null;
 if(useV7){
  const chosen=locations.get(row.module);
  assert(chosen&&chosen.baselinePath===row.path,
    'selected v7 source lacks precisely matched baseline record');
  const source=await readFile(path.join(root,chosen.sourcePath),'utf8');
  assert(Buffer.byteLength(source,'utf8')<=1048576,'v7 module size budget exceeded');
  assert.deepEqual(imports(source),imports(oldFile),
    row.module+' v7 import closure differs from baseline');
  const surface=ok(B.psPscv0ParseSource(true,source),row.module+' v7 source parse');
  assert.equal(B.psPscv0ReplayOriginal(surface),source,
    row.module+' v7 source byte fidelity lost');
  const lowered=ok(B.psPscv0LowerModule(surface),row.module+' v7 source lowering');
  const transferred=transferPscv0Ast(B,C,lowered,source);
  assert.equal(transferred.receipt.schema,AST_ABI_VERSION);
  assert.equal(transferred.receipt.sourceSha256,hash(source));
  ast=transferred.module;
  nodes=transferred.receipt.normalizedNodes;
  sourceSha=hash(source);
  sourcePath=chosen.sourcePath;
 }else{
  ast=ok(C.psCompilerParseSource(C.PsCompilerSourceKind.lean,consumed(oldFile)),
    row.module+' retained Lean AST');
  sourceSha=hash(oldFile);
  sourcePath=row.path;
 }
 const stepped=ok(C.psCompilerPreparationStepParsedWithOrigins(state,ast),
   row.module+' ordered compiler elaboration');
 state=stepped.state;
 const record={module:row.module,sourceKind:useV7?'pscv0-v7':'lean-retained',
   path:sourcePath,sourceSha256:sourceSha,sourceAstNodes:nodes,
   elapsedMs:Math.round(performance.now()-start)};
 preparedModules.push(record);progress.prepared.push(record);
 console.log('PSCV0_LINUX_CLOSURE_PREPARED: '+JSON.stringify(record));
 await checkpoint(progress);
}
assert(preparedModules.length===sourceReport.closure.length);
assert.equal(preparedModules.filter(x=>x.sourceKind==='pscv0-v7').length,selected.size);
const prepMs=Math.round(performance.now()-startPrep);
progress.phase='emit';
await checkpoint(progress);
const prepared=ok(C.psCompilerPreparationFinish(state),'finish complete v7 source closure');
const admissions=ok(C.psCompilerAdmissionsFromPrepared(prepared),
  'canonical compiler admissions from five selected v7 modules');
const ts=ok(C.psCompilerTypeScriptFromPrepared(prepared),
  'TypeScript7 from complete v7-authored compiler closure');
await writeFile(path.join(dir,'index.ts'),ts);
await writeFile(path.join(dir,'bridge.admissions.json'),admissions);
await writeFile(path.join(dir,'package.json'),'{"private":true,"type":"module"}\n');
const admissionsMismatch=diff(oldAdmissions,admissions),typeScriptMismatch=diff(oldTS,ts);
const evidence={
 schema:'psc0-linux-compiler-source-closure/1',
 stage:'source-closure-development-candidate',
 sourceRevision:process.env.GITHUB_SHA||null,
 frontendArtifactSource:sourceReport.source,
 frontendBootstrapSha256:sourceReport.bridgeJsSha256,
 retainedCompilerSha256:sourceReport.builderJsSha256,
 v7ReferenceSha256:V7_REFERENCE_SHA,
 totalModules:preparedModules.length,
 selectedV7Modules:preparedModules.filter(x=>x.sourceKind==='pscv0-v7').length,
 modules:preparedModules,
 sourceCacheValidationMs:sourceValidationMs,
 compilerPreparationMs:prepMs,
 admissionsSha256:hash(admissions),
 previousAdmissionsSha256:hash(oldAdmissions),
 admissionsByteIdentical:admissionsMismatch===null,
 previousTypeScriptSha256:hash(oldTS),
 newTypeScriptSha256:hash(ts),
 typeScriptBytesIdentical:typeScriptMismatch===null,
 admissionsDifference:admissionsMismatch,
 typeScriptDifference:typeScriptMismatch,
 independentlyKernelAdmitted:false,
 kernelOrKernelProofTestsExecuted:false,
 windowsTestsExecuted:false,
 windows:'static-portability-pattern-only-not-executed',
 fullCompilerSelfhostFixedPoint:false,
 fullV7Conformance:false
};
await writeFile(path.join(dir,'source-closure-report.json'),JSON.stringify(evidence,null,2)+'\n');
if(admissionsMismatch||typeScriptMismatch){
 console.log('PSCV0_LINUX_CLOSURE_DIFFERENTIAL: FAIL '+JSON.stringify({
  admissionsMismatch,typeScriptMismatch}));
 throw Error('Changed five-source closure does not match qualified compiler products; inspect first source difference');
}

progress.phase='typescript7';
await checkpoint(progress);
const tsStart=performance.now();
const req=createRequire(path.join(installed,'package.json'));
const metaFile=req.resolve('typescript/package.json');
const meta=JSON.parse(await readFile(metaFile,'utf8'));
assert.equal(meta.version,'7.0.2');
const cli=path.join(path.dirname(metaFile),typeof meta.bin==='string'?meta.bin:meta.bin.tsc);
const result=spawnSync(process.execPath,[cli,'--ignoreConfig',path.join(dir,'index.ts'),
 '--target','ES2022','--module','ES2022','--moduleResolution','bundler','--strict',
 '--declaration','--sourceMap','--skipLibCheck','--noEmitOnError','--pretty','false'],
 {encoding:'utf8',timeout:180000,maxBuffer:8*1024*1024});
assert(!result.error&&result.status===0,
 'full Linux source-closure TS7 compilation refused: '+String(result.error||result.stderr||result.stdout));
const output=await readFile(path.join(dir,'index.js'));
assert.equal(hash(output),upstream.bridgeJsSha256,
 'Linux source closure generated JavaScript differs from qualified selected-v7 predecessor');
evidence.generatedJsSha256=hash(output);
evidence.previousGeneratedJsSha256=upstream.bridgeJsSha256;
evidence.jsBytesIdentical=true;
evidence.typeScriptCompileMs=Math.round(performance.now()-tsStart);
progress.phase='runtime';
await checkpoint(progress);
const F=await import(pathToFileURL(path.join(dir,'index.js')).href);
const entries=F.List.cons(7n,F.List.cons(9n,F.List.nil()));
assert.equal(F.psListLength(entries),2n);
assert.equal(F.psListIsEmpty(F.List.nil()),true);
assert.equal(F.psTokenKindEq(F.PsTokenKind.identifier,F.PsTokenKind.identifier),true);
assert.equal(F.psLexCursorDone({remaining:F.List.nil(),position:{byteOffset:0n,line:1n,column:1n}}),true);
assert.equal(typeof F.psPscv0ParseSource,'function');
evidence.linuxRuntimePassed=true;
evidence.totalElapsedMs=Math.round(performance.now()-begin);
await writeFile(path.join(dir,'source-closure-report.json'),JSON.stringify(evidence,null,2)+'\n');
progress.phase='complete';
await checkpoint(progress);
console.log('PSCV0_LINUX_V7_FIVE_MODULE_CLOSURE: PASS '+JSON.stringify({
 sourceRevision:evidence.sourceRevision,
 modules:evidence.totalModules,v7AuthoredModules:evidence.selectedV7Modules,
 sourceCacheValidationMs:evidence.sourceCacheValidationMs,
 compilerPreparationMs:evidence.compilerPreparationMs,
 tsSha256:evidence.newTypeScriptSha256,jsSha256:evidence.generatedJsSha256,
 canonicalAdmissionsIdentical:true,typescriptIdentical:true,javascriptIdentical:true,
 linuxRuntimePassed:true,totalElapsedMs:evidence.totalElapsedMs,
 windowsTestsExecuted:false,kernelTestsExecuted:false,fullCompilerSelfhostFixedPoint:false
}));
