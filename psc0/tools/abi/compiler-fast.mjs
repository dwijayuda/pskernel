// PSC0 compiler-only fast lane, 2026-10-11.
// Tests selected v7 .ps source -> cached self-hosted JS frontend ->
// closed AST transport -> existing compiler elaboration -> TS7 -> executable JS.
// Does NOT call kernel/pskernel checker, claim checked admissions or certify release.
// Cached frontend is legal ONLY while every source in its frozen 20-file closure
// matches the original artifact's raw SHA-256. Never silently use stale grammar.
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFile, mkdir, writeFile } from 'node:fs/promises';
import { createRequire } from 'node:module';
import { execFileSync, spawnSync } from 'node:child_process';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { transferPscv0Ast, AST_ABI_VERSION, V7_REFERENCE_SHA } from './transport.mjs';

const root=process.cwd();
const artifact=path.resolve(process.argv[2]||'abi/cached');
const installed=path.resolve(process.argv[3]||'');
assert(process.argv[2]&&process.argv[3], 'Pass exact cached generated artifact and retained compiler installation paths');
const digest=v=>createHash('sha256').update(v).digest('hex');
const name='psc0-compiler-only-fast-loop/1';
const timeStart=performance.now();
const stages=[];
const step=async (phase,f)=>{
  const t=performance.now();
  const result=await f();
  stages.push({phase,elapsedMs:Math.round(performance.now()-t)});
  return result;
};
const unwrap=(v,stage)=>{
  const tag=v&&typeof v==='object'?
    Object.getOwnPropertySymbols(v).map(s=>v[s]).find(x=>typeof x==='string'):undefined;
  if(tag!=='ok')throw Error(stage+': expected successful compiler result, got '+String(v?.error??tag));
  return v.value;
};
const B=await import(pathToFileURL(path.join(artifact,'bootstrap','index.js')).href);
const C=await import(pathToFileURL(path.join(installed,'node_modules/@proofscript/compiler/dist/index.js')).href);
const sourceReport=JSON.parse(await readFile(path.join(artifact,'bootstrap','build-report.json'),'utf8'));
assert.equal(sourceReport.stage,'surface-bootstrap');
assert.equal(sourceReport.referenceSha256,V7_REFERENCE_SHA);
const cachedBootstrap=await readFile(path.join(artifact,'bootstrap','index.js'));
assert.equal(digest(cachedBootstrap),sourceReport.bridgeJsSha256,'cached bootstrap JS integrity failure');
assert.equal(sourceReport.closure.length,20,'unexpected bootstrap module count');
const compilerJs=await readFile(path.join(installed,'node_modules/@proofscript/compiler/dist/index.js'));
assert.equal(digest(compilerJs),sourceReport.builderJsSha256,
  'retained compiler differs from the exact generated bootstrap producer');
await step('validate_cached_grammar_source_closure',async()=>{
  for(const module of sourceReport.closure){
    assert.equal(module.sourceKind,'lean','bootstrap closure must be historical Lean source');
    assert(/^(packages\/syntax|packages\/foundation)\/src\//.test(module.path),
      'unapproved path in source closure: '+module.path);
    const raw=await readFile(path.join(root,module.path));
    assert.equal(digest(raw),module.rawSha256,
      'FAST_CACHE_STALE: frontend source '+module.path+' changed: regenerate the milestone bridge; cached frontend cannot qualify new parser code');
  }
});
const selected=await readFile(path.join(root,'packages/syntax/src-ps/Ps/Syntax/Translate.ps'),'utf8');
const authoring=JSON.parse(await readFile(path.join(root,'pscv0-authoring.json'),'utf8'));
assert.equal(authoring.referenceSha256,V7_REFERENCE_SHA);
assert.equal(authoring.modules.length,1,'rapid tier supports one authoritative compiler source module');
assert.equal(authoring.modules[0].module,'Ps.Syntax.Translate');
const candidateSourceSha256=digest(selected);
const slowPrepStart=performance.now();
const selectedAst=await step('parse_and_validate_actual_compiler_module',async()=>{
  const surface=unwrap(B.psPscv0ParseSource(true,selected),'v7 selected module');
  assert.equal(B.psPscv0ReplayOriginal(surface),selected,'selected source byte authority lost');
  const module=unwrap(B.psPscv0LowerModule(surface),'selected module lowering');
  const transfer=transferPscv0Ast(B,C,module,selected);
  assert.equal(transfer.receipt.schema,AST_ABI_VERSION);
  assert.equal(transfer.receipt.sourceSha256,candidateSourceSha256);
  assert(transfer.receipt.normalizedNodes>100,'incomplete selected module source');
  return transfer.receipt;
});
const cases=[
  {label:'grouped-curried-source',
   source:'function add(x: Nat, y: Nat): Nat := Nat.add(x, y)\n'+
          'const grouped: Nat := (add(1))(2)\n',
   field:'grouped',expected:3n},
  {label:'v7-mixed-call-precedence',
   source:'function twice(n: Nat): Nat := Nat.add(n, n)\n'+
          'function inc(n: Nat): Nat := Nat.succ(n)\n'+
          'const result: Nat := twice inc(3)\n',
   field:'result',expected:8n},
  {label:'ordinary-source-call',
   source:'function inc(n: Nat): Nat := Nat.succ(n)\n'+
          'const result: Nat := inc(3)\n',
   field:'result',expected:4n}
];
const target=path.join(root,'dist/pscv0-compiler-fast');
await mkdir(target,{recursive:true});
const requireFromInstalled=createRequire(path.join(installed,'package.json'));
const metaFile=requireFromInstalled.resolve('typescript/package.json');
const meta=JSON.parse(await readFile(metaFile,'utf8'));
assert.equal(meta.version,'7.0.2','fast loop uses exact retained TypeScript 7');
const tsc=path.join(path.dirname(metaFile),typeof meta.bin==='string'?meta.bin:meta.bin.tsc);
const results=[];
for(const [i,fixture] of cases.entries()){
  const data=await step('compiler_elab_emit_execute_'+fixture.label,async()=>{
    const parsed=unwrap(B.psPscv0ParseSource(true,fixture.source),fixture.label+' parse');
    const lowered=unwrap(B.psPscv0LowerModule(parsed),fixture.label+' AST lowering');
    const decoded=transferPscv0Ast(B,C,lowered,fixture.source);
    const state=C.psCompilerPreparationStart(C.PsCompilerSourceKind.lean);
    const stepResult=unwrap(
      C.psCompilerPreparationStepParsedWithOrigins(state,decoded.module),
      fixture.label+' actual compiler elaboration');
    const prepared=unwrap(C.psCompilerPreparationFinish(stepResult.state),fixture.label+' compiler preparation');
    // The stream is informational here. No independent kernel or release
    // admission is executed in this deliberately cheap compiler-only lane.
    const admissions=unwrap(C.psCompilerAdmissionsFromPrepared(prepared),fixture.label+' serialization');
    const typeScript=unwrap(C.psCompilerTypeScriptFromPrepared(prepared),fixture.label+' TS emission');
    const dir=path.join(target,'case-'+i);
    await mkdir(dir,{recursive:true});
    await writeFile(path.join(dir,'index.ts'),typeScript);
    await writeFile(path.join(dir,'package.json'),'{"type":"module"}\n');
    const proc=spawnSync(process.execPath,[tsc,'--ignoreConfig',path.join(dir,'index.ts'),
      '--target','ES2022','--module','ES2022','--moduleResolution','bundler',
      '--strict','--skipLibCheck','--noEmitOnError','--pretty','false'],
      {encoding:'utf8',timeout:90000,maxBuffer:4*1024*1024});
    assert(!proc.error&&proc.status===0,fixture.label+' TS7: '+String(proc.error||proc.stderr||proc.stdout));
    const js=await import(pathToFileURL(path.join(dir,'index.js')).href);
    assert.equal(js[fixture.field],fixture.expected,fixture.label+' JavaScript result differs from compiler source semantics');
    return {case:fixture.label,result:fixture.expected.toString(),
      nodes:decoded.receipt.normalizedNodes,admissionsSha256:digest(admissions),
      tsSha256:digest(typeScript),kernelTestExecuted:false};
  });
  results.push(data);
}
await step('negative_source_grammar',async()=>{
  for(const [label,source,code] of [
    ['axiom','axiom admit : False\n','SOURCE-AXIOM-EXCLUDED'],
    ['partial','partial def fn(n: Nat): Nat := n\n','PARTIAL-EXCLUDED'],
    ['obsolete-verify','verify rule := by { omega }\n','VERIFY-REMOVED'],
    ['unsupported-extension','syntax "bad" : term\n','V7-COMMAND-NOT-YET-SUPPORTED']
  ]){
    const parsed=B.psPscv0ParseSource(true,source);
    const tag=parsed&&typeof parsed==='object'?
      Object.getOwnPropertySymbols(parsed).map(s=>parsed[s]).find(v=>typeof v==='string'):undefined;
    assert.equal(tag,'error',label+' should be refused by v7 grammar');
    assert.match(String(parsed.error),new RegExp(code),label+' wrong refusal');
  }
});
const summary={
 schema:name,status:'compiler-development-only',
 cachedBootstrapSource:sourceReport.source,
 cachedBootstrapJsSha256:sourceReport.bridgeJsSha256,
 retainedCompilerSha256:sourceReport.builderJsSha256,
 soleLanguageReferenceSha256:V7_REFERENCE_SHA,
 authoritativeCompilerModuleSourceSha256:candidateSourceSha256,
 selectedCompilerModuleNodes:selectedAst.normalizedNodes,
 typescript:meta.version,fixtures:results,
 stages,elapsedMs:Math.round(performance.now()-timeStart),
 fullCompilerRegenerated:false,fullSelfhostFixedPoint:false,
 independentlyKernelAdmitted:false,kernelOrKernelProofTestsExecuted:false,
 fullV7Conformance:false,
 cachePolicy:'exact 20-module source raw SHA-256, abort if changed'
};
await writeFile(path.join(target,'compiler-only-report.json'),JSON.stringify(summary,null,2)+'\n');
console.log('PSCV0_COMPILER_FAST: PASS '+JSON.stringify(summary));
