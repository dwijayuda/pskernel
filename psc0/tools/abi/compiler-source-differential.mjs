// PSC0 self-host source migration: cheap differential across every candidate
// in the exact v7-only manifest. No independent kernel/checker/proof test.
// The recipient compiler is the retained self-host JS implementation;
// v7 parsing is performed by the cached, SHA-guarded generated JS frontend.
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFile, mkdir, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { transferPscv0Ast, AST_ABI_VERSION, V7_REFERENCE_SHA } from './transport.mjs';

const root=process.cwd(),cache=path.resolve(process.argv[2]||''),
  installed=path.resolve(process.argv[3]||'');
assert(process.argv[2]&&process.argv[3],'Pass exact cached v7 bootstrap and retained compiler directories');
const hash=b=>createHash('sha256').update(b).digest('hex');
const B=await import(pathToFileURL(path.join(cache,'bootstrap','index.js')).href);
const C=await import(pathToFileURL(path.join(installed,'node_modules/@proofscript/compiler/dist/index.js')).href);
const tag=o=>o&&typeof o==='object'?Object.getOwnPropertySymbols(o).map(s=>o[s]).find(v=>typeof v==='string'):undefined;
const ok=(v,label)=>{
 if(tag(v)!=='ok')throw Error(label+': '+String(v?.error??tag(v)));
 return v.value;
};
const manifest=JSON.parse(await readFile(path.join(root,'pscv0-fast-candidates.json'),'utf8'));
assert.equal(manifest.schema,'psc0-compiler-source-candidates/1');
assert.equal(manifest.status,'candidate-only-not-selected-into-full-generated-bridge');
assert.equal(manifest.referenceSha256,V7_REFERENCE_SHA);
assert(Array.isArray(manifest.modules)&&manifest.modules.length>0&&manifest.modules.length<=24);
const modules=new Set(),locations=new Set();
function ensureOwnSource(module){
 assert(/^Ps\.Foundation\.[A-Za-z_][A-Za-z_0-9]*$/.test(module.module),
   'only named foundation compiler sources admitted in this bounded candidate lane');
 const prefix='packages/foundation/';
 for(const [role,p,segment] of [['candidate',module.source,'src-ps'],['baseline',module.baseline,'src']]){
  assert(typeof p==='string'&&p.startsWith(prefix+segment+'/Ps/Foundation/'),
    'source path must be within canonical '+role+' foundation root');
  assert(!p.includes('..')&&!p.includes('\\')&&p.endsWith(role==='candidate'?'.ps':'.lean'),
    'invalid path traversal or file extension');
  assert(!locations.has(p),'duplicate source path in candidate manifest');
  locations.add(p);
 }
 assert(!modules.has(module.module),'duplicate module declaration');modules.add(module.module);
 assert(Number.isInteger(module.expectedDeclarations)&&module.expectedDeclarations>=1&&module.expectedDeclarations<=200);
}
function declarationCount(list){
 let count=0,value=list;
 while(tag(value)==='cons'){
  count++;
  assert(count<512,'declaration-list budget exceeded');
  value=value.tail;
 }
 assert.equal(tag(value),'nil','malformed syntax declaration list');
 return count;
}
function compile(module,label){
 const s=C.psCompilerPreparationStart(C.PsCompilerSourceKind.lean);
 const step=ok(C.psCompilerPreparationStepParsedWithOrigins(s,module),label+' type elaboration');
 const prepared=ok(C.psCompilerPreparationFinish(step.state),label+' preparation finish');
 return {
  admissions:ok(C.psCompilerAdmissionsFromPrepared(prepared),label+' canonical admission stream'),
  typescript:ok(C.psCompilerTypeScriptFromPrepared(prepared),label+' TS7 backend')
 };
}
function firstDifference(a,b){
 if(a===b)return null;
 let n=0;while(n<a.length&&n<b.length&&a[n]===b[n])n++;
 return {index:n,old:a.slice(Math.max(0,n-80),n+180),
   candidate:b.slice(Math.max(0,n-80),n+180),oldBytes:a.length,candidateBytes:b.length};
}
const reports=[],begin=performance.now();
for(const item of manifest.modules){
 ensureOwnSource(item);
 const start=performance.now();
 const baseline=await readFile(path.join(root,item.baseline),'utf8');
 const candidate=await readFile(path.join(root,item.source),'utf8');
 const oldAst=ok(C.psCompilerParseSource(C.PsCompilerSourceKind.lean,baseline),
   item.module+' original Lean parse');
 const source=ok(B.psPscv0ParseSource(true,candidate),item.module+' v7 source parse');
 assert.equal(B.psPscv0ReplayOriginal(source),candidate,'v7 source byte identity lost');
 const lowered=ok(B.psPscv0LowerModule(source),item.module+' generated v7 AST lowering');
 const transferred=transferPscv0Ast(B,C,lowered,candidate);
 assert.equal(transferred.receipt.schema,AST_ABI_VERSION);
 assert.equal(declarationCount(oldAst.declarations),item.expectedDeclarations,
   item.module+' original source declaration count changed');
 assert.equal(declarationCount(transferred.module.declarations),item.expectedDeclarations,
   item.module+' v7 declaration count mismatches');
 const original=compile(oldAst,item.module+' original');
 const converted=compile(transferred.module,item.module+' v7');
 const admissionMismatch=firstDifference(original.admissions,converted.admissions),
  targetMismatch=firstDifference(original.typescript,converted.typescript);
 const entry={module:item.module,baselineSourceSha256:hash(baseline),
  v7SourceSha256:hash(candidate),oldPhysicalLines:baseline.split('\n').length-1,
  v7PhysicalLines:candidate.split('\n').length-1,
  declarations:item.expectedDeclarations,sourceAstNodes:transferred.receipt.normalizedNodes,
  baselineAdmissionsSha256:hash(original.admissions),v7AdmissionsSha256:hash(converted.admissions),
  baselineTypeScriptSha256:hash(original.typescript),v7TypeScriptSha256:hash(converted.typescript),
  admissionsByteIdentical:admissionMismatch===null,emittedTypeScriptByteIdentical:targetMismatch===null,
  admissionDifference:admissionMismatch,targetDifference:targetMismatch,
  elapsedMs:Math.round(performance.now()-start)};
 reports.push(entry);
 console.log('PSCV0_MODULE_DIFFERENTIAL: '+JSON.stringify(entry));
 if(admissionMismatch||targetMismatch)break;
}
const results={schema:'psc0-multi-module-v7-compiler-only-differential/1',
 status:'compiler-development-only',referenceSha256:V7_REFERENCE_SHA,
 candidateModules:reports.length,sourceManifestSha256:hash(await readFile(path.join(root,'pscv0-fast-candidates.json'))),
 totalElapsedMs:Math.round(performance.now()-begin),modules:reports,
 independentKernelCheckExecuted:false,newFullSelfhostFixedPoint:false,fullV7Conformance:false};
const dir=path.join(root,'dist/pscv0-compiler-fast');
await mkdir(dir,{recursive:true});
await writeFile(path.join(dir,'source-module-differential.json'),JSON.stringify(results,null,2)+'\n');
assert.equal(reports.length,manifest.modules.length,'not all modules were checked');
assert(reports.every(x=>x.admissionsByteIdentical&&x.emittedTypeScriptByteIdentical),
 'Compiler-generated semantics not yet identical: review actual AST/elaboration, not test expected values');
console.log('PSCV0_COMPILER_MULTI_SOURCE: PASS '+JSON.stringify({
  status:results.status,candidateModules:results.candidateModules,
  totalElapsedMs:results.totalElapsedMs,sourceManifestSha256:results.sourceManifestSha256,
  noIndependentKernelTests:true
}));
