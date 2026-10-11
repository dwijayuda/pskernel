// PSC0 Linux-only compiler-development source graph / incremental prefix cache.
// No independent kernel, checked-release, or Windows runtime tests are run.
// Every prefix is an IN-MEMORY, pure PSC0 preparation state and its identity
// includes all previous source kinds, source hashes and actual toolchain SHA.
// Foreign generated ADTs cross only the closed, validated PSCV0 v7 AST boundary.
import assert from 'node:assert/strict';
import { readFile, mkdir, writeFile } from 'node:fs/promises';
import { createRequire } from 'node:module';
import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { transferPscv0Ast, AST_ABI_VERSION, V7_REFERENCE_SHA } from './transport.mjs';
import { loadQualifiedCompilerCache,hash } from './qualified-cache.mjs';

const root=process.cwd(),cache=path.resolve(process.argv[2]||''),
  installed=path.resolve(process.argv[3]||'');
assert(process.argv[2]&&process.argv[3],
  'Pass the pinned cached bootstrap and retained compiler directories');
assert(process.platform==='linux',
  'This inner-loop CI currently executes Linux only; Windows is a static portability review');
const begin=performance.now();
const {B,C,report:cached,checkedModules,sourceValidationMs}=
  await loadQualifiedCompilerCache({root,cache,installed});
const cfgText=await readFile(path.join(root,'pscv0-fast-graph.json'),'utf8');
const cfg=JSON.parse(cfgText);
assert.equal(cfg.schema,'psc0-pscv0-fast-source-graph/1');
assert.equal(cfg.edition,'pscv0-v7');
assert.equal(cfg.languageReferenceSha256,V7_REFERENCE_SHA);
assert.equal(cfg.compilerOnly,true);
assert.equal(cfg.noIndependentKernelChecks,true);
assert.equal(cfg.noWindowsExecutions,true);
assert.equal(cfg.sourceCandidateManifest,'pscv0-fast-candidates.json');
assert(Array.isArray(cfg.roots)&&cfg.roots.length>=2&&cfg.roots.length<=12);
assert(Array.isArray(cfg.scenarios)&&cfg.scenarios.length>=4&&cfg.scenarios.length<=12);
assert(Number.isInteger(cfg.maxClosureModules)&&cfg.maxClosureModules<=20&&cfg.maxClosureModules>=4);
const manifest=JSON.parse(await readFile(path.join(root,cfg.sourceCandidateManifest),'utf8'));
assert.equal(manifest.schema,'psc0-compiler-source-candidates/1');
assert.equal(manifest.status,'candidate-only-not-selected-into-full-generated-bridge');
assert.equal(manifest.referenceSha256,V7_REFERENCE_SHA);
assert(Array.isArray(manifest.modules)&&manifest.modules.length>=2&&manifest.modules.length<=20);
const candidateByModule=new Map();
for(const m of manifest.modules){
  assert(/^Ps\.(?:Foundation|Syntax)\.[A-Za-z_][A-Za-z_0-9]*$/.test(m.module),
    'unapproved candidate module '+String(m.module));
  assert(!candidateByModule.has(m.module),'duplicate candidate '+m.module);
  const parts=m.module.split('.');
  const owner=parts[1].toLowerCase(),file=parts[2];
  assert.equal(m.baseline,'packages/'+owner+'/src/Ps/'+parts[1]+'/'+file+'.lean',
    'source manifest baseline path does not match module identity');
  assert.equal(m.source,'packages/'+owner+'/src-ps/Ps/'+parts[1]+'/'+file+'.ps',
    'source manifest v7 path does not match module identity');
  assert(Number.isInteger(m.expectedDeclarations)&&m.expectedDeclarations>=1&&m.expectedDeclarations<=200);
  candidateByModule.set(m.module,m);
}
function importsOf(source,label){
  const all=[];
  for(const line of source.split(/\r?\n/u)){
    if(!/^\s*import\b/u.test(line))continue;
    const m=line.match(/^\s*import\s+(Ps\.(?:Syntax|Foundation)\.[A-Za-z_][A-Za-z_0-9.]*)\s*$/u);
    assert(m,label+': unsupported/out-of-scope import line '+JSON.stringify(line));
    all.push(m[1]);
  }
  assert.equal(new Set(all).size,all.length,label+': duplicate import');
  return all;
}
const nodes=new Map(),ordered=[],visiting=new Set();
async function visit(module){
  if(nodes.has(module))return;
  assert(!visiting.has(module),'source graph import cycle involving '+module);
  assert(/^Ps\.(?:Syntax|Foundation)\.[A-Za-z_][A-Za-z_0-9.]*$/.test(module),
    'invalid requested source graph module '+String(module));
  const parts=module.split('.'),pkg=parts[1].toLowerCase();
  const baselinePath='packages/'+pkg+'/src/'+parts.join('/')+'.lean';
  const raw=await readFile(path.join(root,baselinePath),'utf8');
  assert(Buffer.byteLength(raw,'utf8')<=1048576,'source graph file exceeds source byte limit: '+module);
  visiting.add(module);
  const imports=importsOf(raw,module+' Lean baseline');
  for(const dep of imports)await visit(dep);
  visiting.delete(module);
  assert(ordered.length<cfg.maxClosureModules,'source graph exceeds explicit module bound');
  const node={module,imports,baselinePath,baseline:raw,baselineSha256:hash(raw)};
  if(candidateByModule.has(module)){
    const c=candidateByModule.get(module);
    node.v7Path=c.source;
    node.v7=await readFile(path.join(root,c.source),'utf8');
    assert.deepEqual(importsOf(node.v7,module+' v7 source'),imports,
      module+' authored v7 dependency set differs from baseline');
    node.v7Sha256=hash(node.v7);
    node.declarations=c.expectedDeclarations;
  }
  nodes.set(module,node);
  ordered.push(node);
}
for(const module of cfg.roots)await visit(module);
assert(ordered.length<=cfg.maxClosureModules&&ordered.length>=4,
  'unexpected compiler source graph size');
for(const module of candidateByModule.keys())
  assert(nodes.has(module),'v7 source candidate excluded from dependency closure: '+module);
assert(ordered.indexOf(nodes.get('Ps.Foundation.Source'))<ordered.indexOf(nodes.get('Ps.Syntax.Cursor')));
assert(ordered.indexOf(nodes.get('Ps.Foundation.Source'))<ordered.indexOf(nodes.get('Ps.Syntax.Token')));

const tag=o=>o&&typeof o==='object'?
  Object.getOwnPropertySymbols(o).map(s=>o[s]).find(v=>typeof v==='string'):undefined;
function ok(value,context){
  if(tag(value)!=='ok')throw Error(context+': '+String(value?.error??tag(value)));
  return value.value;
}
function declarationsCount(value,label){
  let n=0,v=value;
  while(tag(v)==='cons'){
    if(++n>512)throw Error(label+': declaration list budget exceeded');
    v=v.tail;
  }
  assert.equal(tag(v),'nil',label+': malformed source declaration list');
  return n;
}
const parseCache=new Map();
let parsedReuse=0,parsedBuild=0;
function sourceAst(node,useV7){
  const identity=useV7?'pscv0-v7:'+node.v7Sha256:'retained-lean:'+node.baselineSha256;
  const key=node.module+':'+identity;
  if(parseCache.has(key)){parsedReuse++;return parseCache.get(key);}
  const parsed=useV7?(()=>{
    assert(node.v7!==undefined,'missing authored v7 source: '+node.module);
    const syntax=ok(B.psPscv0ParseSource(true,node.v7),node.module+' PSCV0 source parse');
    assert.equal(B.psPscv0ReplayOriginal(syntax),node.v7,
      node.module+' source byte identity lost');
    const lowered=ok(B.psPscv0LowerModule(syntax),node.module+' v7 AST lower');
    const received=transferPscv0Ast(B,C,lowered,node.v7);
    assert.equal(received.receipt.schema,AST_ABI_VERSION);
    assert.equal(received.receipt.sourceSha256,node.v7Sha256);
    return {ast:received.module,nodes:received.receipt.normalizedNodes};
  })():{
    ast:ok(C.psCompilerParseSource(C.PsCompilerSourceKind.lean,node.baseline),
      node.module+' retained Lean parse'),
    nodes:null
  };
  if(node.declarations!==undefined&&useV7){
    assert.equal(declarationsCount(parsed.ast.declarations,node.module),node.declarations,
      node.module+' declarations count changed');
  }
  parsedBuild++;parseCache.set(key,parsed);return parsed;
}
const graphSeed=hash(JSON.stringify({
  schema:cfg.schema,source:cached.source,frontendJs:cached.bridgeJsSha256,
  retainedCompiler:cached.builderJsSha256,reference:V7_REFERENCE_SHA
}));
const stateCache=new Map([[graphSeed,C.psCompilerPreparationStart(C.PsCompilerSourceKind.lean)]]);
let preparedUnique=0,preparedReused=0;
function prepareScenario(scenario){
  const selected=new Set(scenario.v7Modules);
  let prev=graphSeed;
  for(const node of ordered){
    const v7=selected.has(node.module);
    const identity=v7?'pscv0-v7:'+node.v7Sha256:'retained-lean:'+node.baselineSha256;
    const prefix=hash(JSON.stringify([prev,node.module,identity]));
    if(stateCache.has(prefix)){
      preparedReused++;prev=prefix;continue;
    }
    const module=sourceAst(node,v7).ast;
    const state=stateCache.get(prev);
    assert(state,'prefix state missing; source dependency graph not valid');
    const step=ok(C.psCompilerPreparationStepParsedWithOrigins(state,module),
      scenario.name+' elaborate '+node.module);
    stateCache.set(prefix,step.state);
    preparedUnique++;prev=prefix;
  }
  const state=stateCache.get(prev);
  const prepared=ok(C.psCompilerPreparationFinish(state),
    scenario.name+' compiler preparation finish');
  const admissions=ok(C.psCompilerAdmissionsFromPrepared(prepared),
    scenario.name+' canonical compiler admissions');
  const ts=ok(C.psCompilerTypeScriptFromPrepared(prepared),
    scenario.name+' TypeScript 7 generation');
  return {admissions,typescript:ts};
}
function difference(a,b){
  if(a===b)return null;
  let n=0;while(n<a.length&&n<b.length&&a[n]===b[n])n++;
  return {index:n,left:a.slice(Math.max(0,n-120),n+200),
    right:b.slice(Math.max(0,n-120),n+200),leftLength:a.length,rightLength:b.length};
}
const scenarios=[],out=path.join(root,'dist/pscv0-compiler-fast');
await mkdir(out,{recursive:true});
let canonical;
for(const plan of cfg.scenarios){
  assert(/^[a-z0-9-]{3,64}$/.test(plan.name));
  assert(Array.isArray(plan.v7Modules));
  const selected=new Set(plan.v7Modules);
  assert(selected.size===plan.v7Modules.length,'duplicate source switch in scenario '+plan.name);
  for(const module of selected)assert(candidateByModule.has(module),
    'scenario contains unregistered v7 source '+module);
  const start=performance.now(),prepared=prepareScenario(plan);
  if(!canonical){
    assert.equal(selected.size,0,'baseline must be a source-unchanged reference');
    canonical=prepared;
  }
  const admissionsDifference=difference(canonical.admissions,prepared.admissions),
    targetDifference=difference(canonical.typescript,prepared.typescript);
  const row={name:plan.name,v7Modules:[...selected],
    admissionSha256:hash(prepared.admissions),
    typeScriptSha256:hash(prepared.typescript),
    canonicalAdmissionBytesEqual:admissionsDifference===null,
    typeScriptBytesEqual:targetDifference===null,
    admissionsDifference,targetDifference,elapsedMs:Math.round(performance.now()-start)};
  scenarios.push(row);
  console.log('PSCV0_FAST_GRAPH_SCENARIO: '+JSON.stringify(row));
  if(admissionsDifference||targetDifference){
    await writeFile(path.join(out,'incremental-source-graph.json'),
      JSON.stringify({schema:cfg.schema,status:'compiler-only-failure',scenarios},null,2)+'\n');
    throw Error(plan.name+': source-graph scenario changed canonical compiler product');
  }
}
assert(preparedUnique+preparedReused===ordered.length*scenarios.length,
  'missing source graph preparation coverage');
assert(preparedReused>0&&parsedBuild>0,
  'prefix reuse was not exercised; do not claim cache savings');
assert.equal(new Set(scenarios.map(x=>x.name)).size,scenarios.length,
  'duplicate scenario names');
assert(scenarios.some(x=>x.v7Modules.length===candidateByModule.size),
  'the combined v7 candidate scenario is missing');

const tsCompileStart=performance.now();
const last=canonical.typescript;
const dir=path.join(out,'graph-linux');
await mkdir(dir,{recursive:true});
await writeFile(path.join(dir,'index.ts'),last);
await writeFile(path.join(dir,'package.json'),'{"type":"module"}\n');
const req=createRequire(path.join(installed,'package.json'));
const tsMetaFile=req.resolve('typescript/package.json');
const meta=JSON.parse(await readFile(tsMetaFile,'utf8'));
assert.equal(meta.version,'7.0.2','only the qualified TypeScript 7 compiler is allowed');
const tsc=path.join(path.dirname(tsMetaFile),
  typeof meta.bin==='string'?meta.bin:meta.bin.tsc);
const emitted=spawnSync(process.execPath,[tsc,'--ignoreConfig',path.join(dir,'index.ts'),
  '--target','ES2022','--module','ES2022','--moduleResolution','bundler',
  '--strict','--skipLibCheck','--noEmitOnError','--pretty','false'],
  {encoding:'utf8',timeout:90000,maxBuffer:4*1024*1024});
assert(!emitted.error&&emitted.status===0,
  'graph compiler TS7 error: '+String(emitted.error||emitted.stderr||emitted.stdout));
const js=await import(pathToFileURL(path.join(dir,'index.js')).href);
const value=js.List.cons(5n,js.List.cons(8n,js.List.nil()));
assert.equal(js.psListLength(value),2n);
assert.equal(js.psListIsEmpty(value),false);
assert.equal(js.psListIsEmpty(js.List.nil()),true);
assert.equal(js.psListLength(js.psListReverse(value)),2n);
assert.equal(js.psTokenKindEq(js.PsTokenKind.identifier,js.PsTokenKind.identifier),true);
assert.equal(js.psTokenKindEq(js.PsTokenKind.identifier,js.PsTokenKind.natural),false);
const emptyCursor={remaining:js.List.nil(),
  position:{byteOffset:0n,line:1n,column:1n}};
assert.equal(js.psLexCursorDone(emptyCursor),true);
const tsRuntimeMs=Math.round(performance.now()-tsCompileStart);
const report={
  schema:'psc0-compiler-only-preparation-graph/1',
  status:'linux-compiler-development-only',
  onlyLanguageReferenceSha256:V7_REFERENCE_SHA,
  cachedFrontendSource:cached.source,
  cachedFrontendJsSha256:cached.bridgeJsSha256,
  retainedCompilerJsSha256:cached.builderJsSha256,
  graphManifestSha256:hash(cfgText),
  candidateManifestSha256:hash(await readFile(path.join(root,cfg.sourceCandidateManifest))),
  modules:ordered.map(node=>({name:node.module,imports:node.imports,
    baselineSourceSha256:node.baselineSha256,v7SourceSha256:node.v7Sha256||null})),
  scenarios,preparationStatesCreated:preparedUnique,
  preparationStatesReused:preparedReused,
  parsedSourceModulesCreated:parsedBuild,parsedSourceModulesReused:parsedReuse,
  cacheSourceValidationMs:sourceValidationMs,
  cachedSourceModuleCount:checkedModules,
  elapsedMs:Math.round(performance.now()-begin),
  linuxTypeScriptAndRuntimeMs:tsRuntimeMs,
  runtimeResults:{listLength:2,listEmpty:false,tokenKindEq:true,cursorDone:true},
  sourceGraphCycleRefused:true,
  kernelTestsExecuted:false,windowsTestsExecuted:false,
  windowsPortability:'static-pattern-review-only-not-verified',
  fullSelfhostCompilerFixedPoint:false,
  candidateSourcesPromoted:false
};
await writeFile(path.join(out,'incremental-source-graph.json'),
  JSON.stringify(report,null,2)+'\n');
console.log('PSCV0_INCREMENTAL_GRAPH: PASS '+JSON.stringify({
  moduleCount:report.modules.length,scenarios:report.scenarios.length,
  uniquePreparationStates:preparedUnique,reusedPreparationStates:preparedReused,
  parsedSourceModules:parsedBuild,elapsedMs:report.elapsedMs,
  linuxRuntime:true,independentKernelTests:false,windowsExecuted:false
}));
