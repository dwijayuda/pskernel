// Two ordered bootstrap stages share one live, pure preparation prefix.
// Stage one generates the owned source bridge from predecessor-readable Lean;
// stage two uses that bridge to consume the selected real PSCV0 source module.
// No serialized preparation cache, native frontend fallback, or kernel rebuild.
import assert from 'node:assert/strict';
import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { execFileSync, spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { createRequire } from 'node:module';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { readAuthoringInputs, materializeAuthoring } from './pscv0-authoring.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const prefix=path.resolve(process.argv[2]);
const output=path.resolve(process.argv[3]||path.join(root,'dist/pscv0-bridge'));
const installed=path.join(prefix,...(process.platform==='win32'?['node_modules']:['lib','node_modules']),'proofscript');
const compilerFile=path.join(installed,'node_modules/@proofscript/compiler/dist/index.js');
const sha=b=>createHash('sha256').update(b).digest('hex');
const builderJsSha256=sha(await readFile(compilerFile));
assert.equal(builderJsSha256,'6cddc3c34c38f1524ef9a355c46b0eb17949c45c54fd59367ea370c1af861ab3');
const compiler=await import(pathToFileURL(compilerFile).href);
const tag=o=>o&&typeof o==='object'?Object.getOwnPropertySymbols(o).map(s=>o[s]).find(x=>typeof x==='string'):undefined;
function printable(o){
  if(typeof o==='bigint')return o.toString();
  if(!o||typeof o!=='object')return o;
  return Object.fromEntries([...Object.entries(o).map(([k,v])=>[k,printable(v)]),...(tag(o)?[['constructor',tag(o)]]:[])]);
}
function unwrap(result,phase){
  if(tag(result)!=='ok')throw Error('PSCV0_BRIDGE_'+phase+': '+JSON.stringify(printable(result),null,2));
  return result.value;
}
const git=args=>execFileSync('git',args,{cwd:path.dirname(root),encoding:'utf8',maxBuffer:8*1024*1024});
const sourceRevision=git(['rev-parse','HEAD']).trim();assert.equal(sourceRevision,process.env.GITHUB_SHA);
const base='b64a95e4537dade93462e0232b5da54d79f9cb25';
const compilerPackages=['foundation','syntax','core','environment','meta','elab','bridge','compiler-ir','erasure','compiler','backend-ts','bootstrap'];
const sourcePaths=compilerPackages.map(p=>'psc0/packages/'+p+'/src');
const old=git(['ls-tree','-r','--full-tree',base,'--',...sourcePaths]).trim().split('\n').filter(Boolean);
assert.equal(old.length,69,'baseline compiler inventory');
for(const row of old){
  const [object,file]=row.split('\t');
  assert.equal(git(['rev-parse','HEAD:'+file]).trim(),object.split(' ')[2],'frozen predecessor source changed: '+file);
}
for(const name of ['psc0/packages/pskernel-core','psc0/npm-runtime','psc0/selfhost-seed.json','psc0/psconfig.json','psc0/lean-toolchain','psc0/npm-cli']){
  assert.equal(git(['rev-parse','HEAD:'+name]).trim(),git(['rev-parse',base+':'+name]).trim(),'unrelated authority changed: '+name);
}
const inputs=await readAuthoringInputs();
const added=git(['diff','--name-only',base,'HEAD','--',...sourcePaths,'psc0/packages/syntax/src-ps']).trim().split('\n').filter(Boolean);
assert(added.length>0&&added.every(n=>n.startsWith('psc0/packages/syntax/src/Ps/Syntax/Pscv0/')||n==='psc0/'+inputs.selected.source),'unexpected portable-source scope');
const consumed=source=>source.split(/\r?\n/u).filter(s=>!/^\s*import\s+[A-Za-z_][A-Za-z_0-9.]*\s*$/u.test(s)).join('\n');
const order=[],seen=new Set(),active=new Set();
async function visit(module){
  if(active.has(module))throw Error('bridge import cycle: '+module);
  if(seen.has(module))return;
  const parts=module.split('.'),owner={Syntax:'syntax',Foundation:'foundation'}[parts[1]];
  assert(parts[0]==='Ps'&&owner,'bridge imports non-syntax compiler or kernel: '+module);
  const file=path.join(root,'packages',owner,'src',...parts)+'.lean';
  const raw=await readFile(file,'utf8');active.add(module);
  for(const line of raw.split(/\r?\n/u)){
    const m=line.match(/^\s*import\s+([A-Za-z_][A-Za-z_0-9.]*)\s*$/u);if(m)await visit(m[1]);
  }
  active.delete(module);seen.add(module);
  const source=consumed(raw);
  order.push({module,path:path.relative(root,file).split(path.sep).join('/'),sourceKind:'lean',rawSha256:sha(raw),consumedSha256:sha(source),source});
}
await visit('Ps.Syntax.Pscv0.Module');
assert.equal(order.length,20,'review changed closure size');
const forkIndex=order.findIndex(x=>x.module===inputs.selected.module);assert(forkIndex>0);
const req=createRequire(path.join(installed,'package.json'));
const tsMetaFile=req.resolve('typescript/package.json'),tsMeta=JSON.parse(await readFile(tsMetaFile,'utf8'));assert.equal(tsMeta.version,'7.0.2');
const bin=path.join(path.dirname(tsMetaFile),typeof tsMeta.bin==='string'?tsMeta.bin:tsMeta.bin.tsc);
await mkdir(output,{recursive:true});
const start=Date.now();
const progress={source:sourceRevision,preflight:[],prepared:[],phase:'preflight',sharedPrefixModules:forkIndex,stages:[]};
const checkpoint=()=>writeFile(path.join(output,'progress.json'),JSON.stringify(progress,null,2)+'\n');
const parsed=new Map();
async function prepareOne(state,module,stage){
  progress.phase=stage+' prepare '+module.module;await checkpoint();
  console.log('PSCV0_BRIDGE_PREPARING: '+stage+' '+module.module+' ['+module.sourceKind+']');const begin=Date.now();
  const key=module.module+':'+module.consumedSha256;
  let next;
  if(module.sourceKind==='pscv0'){
    assert(parsed.has(key),'authoritative PSCV0 source AST missing; old Lean parser fallback forbidden');
    next=unwrap(compiler.psCompilerPreparationStepParsedWithOrigins(state,parsed.get(key)),
      'PREPARE_V7_AST '+module.module).state;
  }else if(parsed.has(key)){
    next=unwrap(compiler.psCompilerPreparationStepParsedWithOrigins(state,parsed.get(key)),
      'PREPARE_RETAINED_LEAN_AST '+module.module).state;
  }else{
    assert.equal(module.sourceKind,'lean','unregistered module source kind');
    next=unwrap(compiler.psCompilerPreparationStep(state,module.source),'PREPARE '+module.module);
  }
  progress.prepared.push({stage,module:module.module,elapsedMs:Date.now()-begin});
  console.log('PSCV0_BRIDGE_PREPARED: '+module.module+' '+(Date.now()-begin)+'ms');await checkpoint();return next;
}
async function emitStage(state,modules,stage,directory,authoring){
  progress.phase=stage+' emit';await checkpoint();await mkdir(directory,{recursive:true});
  const prepared=unwrap(compiler.psCompilerPreparationFinish(state),'FINISH '+stage);
  const admissions=unwrap(compiler.psCompilerAdmissionsFromPrepared(prepared),'ADMISSIONS '+stage);
  const ts=unwrap(compiler.psCompilerTypeScriptFromPrepared(prepared),'EMIT '+stage);
  await writeFile(path.join(directory,'index.ts'),ts);
  await writeFile(path.join(directory,'bridge.admissions.json'),admissions);
  await writeFile(path.join(directory,'package.json'),'{"type":"module","private":true}\n');
  const result=spawnSync(process.execPath,[bin,'--ignoreConfig',path.join(directory,'index.ts'),'--target','ES2022','--module','ES2022','--moduleResolution','bundler','--strict','--declaration','--sourceMap','--skipLibCheck','--noEmitOnError','--pretty','false'],{encoding:'utf8',timeout:180000,maxBuffer:8*1024*1024});
  assert(!result.error&&result.status===0,String(result.error||result.stderr||result.stdout));
  const report={schema:'psc0-pscv0-portable-bridge-build/1',stage,source:sourceRevision,baseSource:base,
    referenceSha256:inputs.manifest.referenceSha256,builder:'retained self-hosted JavaScript PSC0 compiler',
    builderRuntimeSource:'2f42a52814f3785ff2d92bd826f6e7fb3eb9bc8a',builderJsSha256,
    existingCompilerSourceFilesUnchanged:old.length,newPortableSourceFiles:added,
    closure:modules.map(({source,...record})=>record),
    ...(authoring?{authoring:{manifestSha256:authoring.receipt.manifestSha256,modules:[authoring.receipt],selectedPsModules:1,noFallback:true,
      sharedPrefixModules:forkIndex,sharedPrefixPreparedOnce:true,
      directGeneratedSourceAstHandoff:true,compilerInput:'generated-v7-pscv0-syntax-module',
      readableLeanProjectionOnly:true,
      surfaceBootstrapJsSha256:authoring.receipt.surfaceSeed.jsSha256}}:{}),
    bridgeTypeScriptSha256:sha(ts),bridgeJsSha256:sha(await readFile(path.join(directory,'index.js'))),admissionsSha256:sha(admissions),
    typescript:'7.0.2',elapsedMs:Date.now()-start,kernelRegenerated:false,existingCompilerRebuilt:false,newInstalledFixedPoint:false,bridgeKernelAdmitted:false};
  await writeFile(path.join(directory,'build-report.json'),JSON.stringify(report,null,2)+'\n');
  progress.stages.push({stage,bridgeJsSha256:report.bridgeJsSha256});await checkpoint();
  console.log('PSCV0_PORTABLE_STAGE: PASS '+stage+' '+report.bridgeJsSha256);return report;
}
try{
  await checkpoint();
  for(const module of order.filter(x=>x.module.startsWith('Ps.Syntax.Pscv0.'))){
    parsed.set(module.module+':'+module.consumedSha256,unwrap(compiler.psCompilerParseSource(compiler.PsCompilerSourceKind.lean,module.source),'PREFLIGHT '+module.module));
    progress.preflight.push(module.module);console.log('PSCV0_BRIDGE_PREFLIGHT: PASS '+module.module);
  }
  let state=compiler.psCompilerPreparationStart(compiler.PsCompilerSourceKind.lean),shared;
  for(let index=0;index<order.length;index++){
    if(index===forkIndex)shared=Object.freeze(state);
    state=await prepareOne(state,order[index],'surface-bootstrap');
  }
  assert(shared,'shared pure preparation prefix missing');
  const bootstrap=path.join(output,'bootstrap');await emitStage(state,order,'surface-bootstrap',bootstrap);
  const authoring=await materializeAuthoring(bootstrap,output);
  // Check the actual generated source again, not merely native preflight files.
  execFileSync(process.execPath,[path.join(root,'scripts/pscv0-authoring-proof.mjs'),'4.34.0',path.join(output,'authoring')],{cwd:root,stdio:'inherit',timeout:180000});
  const candidate=order.map(module=>module.module!==inputs.selected.module?module:{...module,
    path:inputs.selected.source,sourceKind:'pscv0',rawSha256:authoring.receipt.sourceSha256,
    surfaceSeedJsSha256:authoring.receipt.surfaceSeed.jsSha256,loweredLeanSha256:sha(authoring.lowered),
    source:consumed(authoring.lowered),consumedSha256:sha(consumed(authoring.lowered))});
  const chosen=candidate[forkIndex];
  // Semantic source authority is the generated PSCV0 syntax tree. Passing it
  // directly to the existing elaboration step avoids a second lossy Lean-text
  // parse and does not bypass admission or any kernel/host obligation.
  // The Lean text above remains an independently checked projection.
  assert(authoring.parsedModule&&typeof authoring.parsedModule==='object',
    'generated PSCV0 parsed module must exist; no old Lean parser fallback');
  parsed.set(chosen.module+':'+chosen.consumedSha256,authoring.parsedModule);
  console.log('PSCV0_SOURCE_AST_HANDOFF: generated PSCV0 source AST, direct checked elaboration');
  state=shared;
  for(const module of candidate.slice(forkIndex))state=await prepareOne(state,module,'ps-authoring-candidate');
  await emitStage(state,candidate,'ps-authoring-candidate',output,authoring);
  assert.equal(progress.prepared.filter(r=>order.slice(0,forkIndex).some(m=>m.module===r.module)).length,forkIndex);
  progress.phase='complete';await checkpoint();
  console.log('PSCV0_PORTABLE_BRIDGE_BUILD: PASS one selected PS module; '+forkIndex+' prefix modules prepared once; no full compiler/kernel rebuild');
}catch(error){
  await writeFile(path.join(output,'failure.json'),JSON.stringify({source:progress.source,phase:progress.phase,message:error.message,elapsedMs:Date.now()-start},null,2)+'\n');throw error;
}
