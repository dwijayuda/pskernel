// Cloud bootstrap: the retained self-hosted JS compiler compiles the portable
// syntax-only bridge closure. No native Lean fallback or kernel generation.
import assert from 'node:assert/strict';
import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { execFileSync, spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { createRequire } from 'node:module';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
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
// Pathspecs below are repository-root paths, independent of the invocation cwd.
const git=args=>execFileSync('git',args,{cwd:path.dirname(root),encoding:'utf8',maxBuffer:8*1024*1024});
const base='b64a95e4537dade93462e0232b5da54d79f9cb25';
const compilerPackages=['foundation','syntax','core','environment','meta','elab','bridge','compiler-ir','erasure','compiler','backend-ts','bootstrap'];
const sourcePaths=compilerPackages.map(p=>'psc0/packages/'+p+'/src');
const old=git(['ls-tree','-r','--full-tree',base,'--',...sourcePaths]).trim().split('\n').filter(Boolean);
assert.equal(old.length,69,'baseline compiler inventory');
for(const row of old){
  const [object,file]=row.split('\t');
  assert.equal(git(['rev-parse','HEAD:'+file]).trim(),object.split(' ')[2],'baseline compiler source changed: '+file);
}
for(const name of ['psc0/packages/pskernel-core','psc0/npm-runtime','psc0/selfhost-seed.json','psc0/psconfig.json','psc0/lean-toolchain','psc0/npm-cli']){
  assert.equal(git(['rev-parse','HEAD:'+name]).trim(),git(['rev-parse',base+':'+name]).trim(),'unrelated authority changed: '+name);
}
const added=git(['diff','--name-only',base,'HEAD','--',...sourcePaths]).trim().split('\n').filter(Boolean);
assert(added.length>0&&added.every(n=>n.startsWith('psc0/packages/syntax/src/Ps/Syntax/Pscv0/')),'unexpected portable-source scope');
const order=[],seen=new Set(),active=new Set();
async function visit(module){
  if(active.has(module))throw Error('bridge import cycle: '+module);
  if(seen.has(module))return;
  const parts=module.split('.');
  const owner={Syntax:'syntax',Foundation:'foundation'}[parts[1]];
  assert(parts[0]==='Ps'&&owner,'bridge imports non-syntax compiler or kernel: '+module);
  const file=path.join(root,'packages',owner,'src',...parts)+'.lean';
  const source=await readFile(file,'utf8');
  active.add(module);
  for(const line of source.split(/\r?\n/u)){
    const m=line.match(/^\s*import\s+([A-Za-z_][A-Za-z_0-9.]*)\s*$/u);
    if(m)await visit(m[1]);
  }
  active.delete(module);seen.add(module);
  const consumed=source.split(/\r?\n/u).filter(s=>!/^\s*import\s+[A-Za-z_][A-Za-z_0-9.]*\s*$/u.test(s)).join('\n');
  order.push({module,path:path.relative(root,file),rawSha256:sha(source),consumedSha256:sha(consumed),source:consumed});
}
await visit('Ps.Syntax.Pscv0.Module');
await mkdir(output,{recursive:true});
const start=Date.now();
console.log('PSCV0_BRIDGE_PREPARING: '+order.length+' syntax-only modules, '+order.reduce((n,x)=>n+Buffer.byteLength(x.source),0)+' bytes');
let inputs=compiler.List.nil();
for(let i=order.length-1;i>=0;i--)inputs=compiler.List.cons(order[i].source,inputs);
const prepared=unwrap(compiler.psCompilerPrepareSources(compiler.PsCompilerSourceKind.lean,inputs),'PREPARE');
const admissions=unwrap(compiler.psCompilerAdmissionsFromPrepared(prepared),'ADMISSIONS');
const ts=unwrap(compiler.psCompilerTypeScriptFromPrepared(prepared),'EMIT');
await writeFile(path.join(output,'index.ts'),ts);
await writeFile(path.join(output,'bridge.admissions.json'),admissions);
await writeFile(path.join(output,'package.json'),'{"type":"module","private":true}\n');
const req=createRequire(path.join(installed,'package.json'));
const tsMetaFile=req.resolve('typescript/package.json');
const tsMeta=JSON.parse(await readFile(tsMetaFile,'utf8'));
assert.equal(tsMeta.version,'7.0.2');
const bin=path.join(path.dirname(tsMetaFile),typeof tsMeta.bin==='string'?tsMeta.bin:tsMeta.bin.tsc);
const result=spawnSync(process.execPath,[bin,'--ignoreConfig',path.join(output,'index.ts'),'--target','ES2022','--module','ES2022','--moduleResolution','bundler','--strict','--declaration','--sourceMap','--skipLibCheck','--noEmitOnError','--pretty','false'],{encoding:'utf8',timeout:180000,maxBuffer:8*1024*1024});
assert(!result.error&&result.status===0,String(result.error||result.stderr||result.stdout));
const report={schema:'psc0-pscv0-portable-bridge-build/1',source:git(['rev-parse','HEAD']).trim(),baseSource:base,referenceSha256:'a419955383fd3e35d873f82c939ecf3a92dc65b162cc9d0d3cadf5b853a0f4b0',builder:'retained self-hosted JavaScript PSC0 compiler',builderRuntimeSource:'2f42a52814f3785ff2d92bd826f6e7fb3eb9bc8a',builderJsSha256:sha(await readFile(compilerFile)),existingCompilerSourceFilesUnchanged:old.length,newPortableSourceFiles:added,closure:order.map(({source,...r})=>r),bridgeTypeScriptSha256:sha(ts),bridgeJsSha256:sha(await readFile(path.join(output,'index.js'))),admissionsSha256:sha(admissions),typescript:'7.0.2',elapsedMs:Date.now()-start,kernelRegenerated:false,existingCompilerRebuilt:false,newInstalledFixedPoint:false,bridgeKernelAdmitted:false};
await writeFile(path.join(output,'build-report.json'),JSON.stringify(report,null,2)+'\n');
console.log('PSCV0_PORTABLE_BRIDGE_BUILD: PASS '+JSON.stringify({...report,closureModules:order.length,closure:undefined}));
