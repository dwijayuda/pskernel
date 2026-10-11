// Generate only the portable syntax bridge. The explicit candidate source map
// selects real .ps implementation modules through the qualified surface seed.
// There is no adjacent-.lean fallback when a selected .ps file fails.
import assert from 'node:assert/strict';
import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { execFileSync, spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { createRequire } from 'node:module';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { materializeAuthoring } from './pscv0-authoring.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const prefix=path.resolve(process.argv[2]);
const output=path.resolve(process.argv[3]||path.join(root,'dist/pscv0-bridge'));
const installed=path.join(prefix,...(process.platform==='win32'?['node_modules']:['lib','node_modules']),'proofscript');
const compilerFile=path.join(installed,'node_modules/@proofscript/compiler/dist/index.js');
const compiler=await import(pathToFileURL(compilerFile).href);
const sha=b=>createHash('sha256').update(b).digest('hex');
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
const authoring=await materializeAuthoring(process.env.PSCV0_SURFACE_SEED,output);
const added=git(['diff','--name-only',base,'HEAD','--',...sourcePaths,'psc0/packages/syntax/src-ps']).trim().split('\n').filter(Boolean);
assert(added.length>0&&added.every(n=>n.startsWith('psc0/packages/syntax/src/Ps/Syntax/Pscv0/')||n==='psc0/'+authoring.selected.source),'unexpected portable-source scope');
const order=[],seen=new Set(),active=new Set();
async function visit(module){
  if(active.has(module))throw Error('bridge import cycle: '+module);
  if(seen.has(module))return;
  const parts=module.split('.'),owner={Syntax:'syntax',Foundation:'foundation'}[parts[1]];
  assert(parts[0]==='Ps'&&owner,'bridge imports non-syntax compiler or kernel: '+module);
  const selected=module===authoring.selected.module;
  const file=selected?path.join(root,authoring.selected.source):path.join(root,'packages',owner,'src',...parts)+'.lean';
  const raw=selected?authoring.source:await readFile(file,'utf8');
  const source=selected?authoring.lowered:raw;
  active.add(module);
  for(const line of source.split(/\r?\n/u)){
    const m=line.match(/^\s*import\s+([A-Za-z_][A-Za-z_0-9.]*)\s*$/u);
    if(m)await visit(m[1]);
  }
  active.delete(module);seen.add(module);
  const consumed=source.split(/\r?\n/u).filter(s=>!/^\s*import\s+[A-Za-z_][A-Za-z_0-9.]*\s*$/u.test(s)).join('\n');
  order.push({module,path:path.relative(root,file).split(path.sep).join('/'),sourceKind:selected?'pscv0':'lean',
    rawSha256:sha(raw),...(selected?{surfaceSeedJsSha256:authoring.manifest.surfaceSeed.jsSha256,loweredLeanSha256:sha(source)}:{}),
    consumedSha256:sha(consumed),source:consumed});
}
await visit('Ps.Syntax.Pscv0.Module');
assert.equal(order.filter(x=>x.sourceKind==='pscv0').length,1,'candidate module not actually consumed');
await mkdir(output,{recursive:true});
const progress={source:git(['rev-parse','HEAD']).trim(),preflight:[],prepared:[],phase:'preflight',closure:order.map(({source,...r})=>r)};
async function checkpoint(){await writeFile(path.join(output,'progress.json'),JSON.stringify(progress,null,2)+'\n');}
const parsedNew=new Map();
const start=Date.now();
try{
  await checkpoint();
  for(const module of order.filter(x=>x.sourceKind==='pscv0'||x.module.startsWith('Ps.Syntax.Pscv0.'))){
    const begin=Date.now();
    parsedNew.set(module.module,unwrap(compiler.psCompilerParseSource(compiler.PsCompilerSourceKind.lean,module.source),'PREFLIGHT '+module.module));
    progress.preflight.push({module:module.module,elapsedMs:Date.now()-begin});
    console.log('PSCV0_BRIDGE_PREFLIGHT: PASS '+module.module);await checkpoint();
  }
  let state=compiler.psCompilerPreparationStart(compiler.PsCompilerSourceKind.lean);
  for(const module of order){
    progress.phase='prepare '+module.module;await checkpoint();
    console.log('PSCV0_BRIDGE_PREPARING: '+module.module+' ['+module.sourceKind+']');const begin=Date.now();
    if(parsedNew.has(module.module)){
      const result=unwrap(compiler.psCompilerPreparationStepParsedWithOrigins(state,parsedNew.get(module.module)),'PREPARE_WITH_ORIGINS '+module.module);
      state=result.state;
    }else state=unwrap(compiler.psCompilerPreparationStep(state,module.source),'PREPARE '+module.module);
    progress.prepared.push({module:module.module,elapsedMs:Date.now()-begin});
    console.log('PSCV0_BRIDGE_PREPARED: '+module.module+' '+(Date.now()-begin)+'ms');await checkpoint();
  }
  progress.phase='finish';await checkpoint();
  const prepared=unwrap(compiler.psCompilerPreparationFinish(state),'FINISH');
  const admissions=unwrap(compiler.psCompilerAdmissionsFromPrepared(prepared),'ADMISSIONS');
  progress.phase='emit';await checkpoint();
  const ts=unwrap(compiler.psCompilerTypeScriptFromPrepared(prepared),'EMIT');
  await writeFile(path.join(output,'index.ts'),ts);
  await writeFile(path.join(output,'bridge.admissions.json'),admissions);
  await writeFile(path.join(output,'package.json'),'{"type":"module","private":true}\n');
  const req=createRequire(path.join(installed,'package.json'));
  const tsMetaFile=req.resolve('typescript/package.json'),tsMeta=JSON.parse(await readFile(tsMetaFile,'utf8'));
  assert.equal(tsMeta.version,'7.0.2');
  const bin=path.join(path.dirname(tsMetaFile),typeof tsMeta.bin==='string'?tsMeta.bin:tsMeta.bin.tsc);
  const result=spawnSync(process.execPath,[bin,'--ignoreConfig',path.join(output,'index.ts'),'--target','ES2022','--module','ES2022','--moduleResolution','bundler','--strict','--declaration','--sourceMap','--skipLibCheck','--noEmitOnError','--pretty','false'],{encoding:'utf8',timeout:180000,maxBuffer:8*1024*1024});
  assert(!result.error&&result.status===0,String(result.error||result.stderr||result.stdout));
  const report={schema:'psc0-pscv0-portable-bridge-build/1',source:progress.source,baseSource:base,
    referenceSha256:authoring.manifest.referenceSha256,builder:'retained self-hosted JavaScript PSC0 compiler',
    builderRuntimeSource:'2f42a52814f3785ff2d92bd826f6e7fb3eb9bc8a',builderJsSha256:sha(await readFile(compilerFile)),
    existingCompilerSourceFilesUnchanged:old.length,newPortableSourceFiles:added,closure:progress.closure,
    authoring:{manifestSha256:authoring.receipt.manifestSha256,modules:[authoring.receipt],selectedPsModules:1,noFallback:true},
    bridgeTypeScriptSha256:sha(ts),bridgeJsSha256:sha(await readFile(path.join(output,'index.js'))),admissionsSha256:sha(admissions),
    typescript:'7.0.2',elapsedMs:Date.now()-start,kernelRegenerated:false,existingCompilerRebuilt:false,newInstalledFixedPoint:false,bridgeKernelAdmitted:false};
  await writeFile(path.join(output,'build-report.json'),JSON.stringify(report,null,2)+'\n');
  progress.phase='complete';await checkpoint();
  console.log('PSCV0_PORTABLE_BRIDGE_BUILD: PASS '+JSON.stringify({...report,authoring:{selectedPsModules:1},closureModules:order.length,closure:undefined}));
}catch(error){
  await writeFile(path.join(output,'failure.json'),JSON.stringify({source:progress.source,phase:progress.phase,message:error.message,elapsedMs:Date.now()-start},null,2)+'\n');throw error;
}
