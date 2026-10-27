// Packaging only: no parser/elaborator/IR transform/kernel implementation.
// One qualified root implementation; existing source packages expose honest APIs.
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import {sha256} from './kernel435-qualified-artifact.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
process.chdir(root);
const out=path.join(root,'dist/npm-packages'),args=process.argv.slice(2),mode=args[0]??'build';
const selected=args.includes('--package')?args[args.indexOf('--package')+1]:null;
assert.ok(['build','clean'].includes(mode));
if(selected)assert.ok(/^[a-z][a-z0-9-]*$/.test(selected));
const json=x=>JSON.stringify(x,null,2)+'\n';
const read=p=>JSON.parse(fs.readFileSync(p,'utf8'));
const put=(p,b)=>{fs.mkdirSync(path.dirname(p),{recursive:true});fs.writeFileSync(p,b);};
function run(exe,args,options={}){
 const r=spawnSync(exe,args,{cwd:root,encoding:'utf8',timeout:240000,maxBuffer:33554432,...options});
 assert.equal(r.error,undefined,String(r.error));assert.equal(r.status,0,r.stdout+r.stderr);return r.stdout;
}
function inventory(directory,prefix=''){
 return fs.readdirSync(path.join(directory,prefix)).sort().flatMap(name=>{
  const relative=prefix?prefix+'/'+name:name,p=path.join(directory,relative),stat=fs.lstatSync(p);
  assert.ok(!stat.isSymbolicLink(),'symlink in package input:'+p);
  return stat.isDirectory()?inventory(directory,relative):[{path:relative,bytes:stat.size,sha256:sha256(fs.readFileSync(p))}];
 });
}
const dirs=fs.readdirSync('packages').sort().filter(d=>fs.existsSync(path.join('packages',d,'package.json')));
if(selected)assert.ok(dirs.includes(selected),'existing named package required');
function clean(dir){
 const target=path.resolve('packages',dir,'dist');
 assert.equal(target,path.join(root,'packages',dir,'dist'));
 if(fs.existsSync(target)){assert.ok(!fs.lstatSync(target).isSymbolicLink());fs.rmSync(target,{recursive:true});}
}
if(mode==='clean'){for(const dir of selected?[selected]:dirs)clean(dir);process.exit(0);}
if(!fs.existsSync(path.join(out,'qualified-bundles.json')))await import('./npm-package-inventory.mjs');
const input=read('scripts/npm-packages-input.json'),audit=read(path.join(out,'inventory.json'));
for(const [directory,pin]of [['qualified-input',input.root],['qualified-bundles',input.full]])
 assert.equal(sha256(fs.readFileSync(path.join(out,directory,'input.zip'))),pin.zipSha256,'qualified archive unchanged');
const frozen=path.join(out,'frozen/package'),original=read(path.join(frozen,'UNIVERSAL_DISTRIBUTION.json'));
for(const pin of audit.frozenFiles){
 const b=fs.readFileSync(path.join(frozen,pin.path));assert.equal(b.length,pin.bytes);assert.equal(sha256(b),pin.sha256);
}
const extras=read(path.join(out,'qualified-bundles.json'));
const tarIndex=new Map();
function indexTars(dir){for(const n of fs.readdirSync(dir)){const p=path.join(dir,n);if(fs.statSync(p).isDirectory())indexTars(p);else if(n.endsWith('.tgz'))tarIndex.set(n,p);}}
indexTars(path.join(out,'qualified-bundles'));
const hydrated=path.join(out,'hydrated');fs.mkdirSync(hydrated,{recursive:true});
function originalPackage(name){
 const found=extras.find(e=>e.meta.name===name);assert.ok(found,'qualified existing bundle:'+name);
 const tar=tarIndex.get(found.tarball);assert.equal(sha256(fs.readFileSync(tar)),found.sha256);
 const target=path.join(hydrated,name.replaceAll('/','-').replaceAll('@',''));
 if(!fs.existsSync(target)){fs.mkdirSync(target);unpack(tar,target);}
 return path.join(target,'package');
}
function unpack(tar,target){
 const names=run('tar',['tzf',tar]).split('\n').filter(Boolean);
 assert.ok(names.every(n=>n.startsWith('package/')&&!n.split('/').includes('..')));
 fs.mkdirSync(target,{recursive:true});run('tar',['xzf',tar,'-C',target]);
 for(const pin of inventory(path.join(target,'package')))assert.ok(pin.bytes>=0);
}
const packed=path.join(out,'tarballs');fs.mkdirSync(packed,{recursive:true});
function pack(dir){
 const rows=JSON.parse(run('npm',['pack',dir,'--ignore-scripts','--json','--pack-destination',packed]));
 assert.equal(rows.length,1);const tarball=rows[0].filename,bytes=fs.readFileSync(path.join(packed,tarball));
 return{tarball,bytes:bytes.length,sha256:sha256(bytes)};
}
// Payload hydration never overwrites canonical source files or metadata.
function hydrate(dir,source){
 for(const pin of inventory(source)){
  if(['package.json','README.md','LICENSE','NOTICE'].includes(pin.path))continue;
  const target=path.join(dir,pin.path),bytes=fs.readFileSync(path.join(source,pin.path));
  if(fs.existsSync(target))assert.equal(sha256(fs.readFileSync(target)),pin.sha256,'canonical/prebuilt conflict:'+target);
  else put(target,bytes);
  fs.chmodSync(target,fs.statSync(path.join(source,pin.path)).mode & 0o777);
 }
}
function sourceFiles(dir){
 const source=path.join(dir,'src');
 if(!fs.existsSync(source))return[];
 return inventory(source).filter(p=>/\.(lean|ps)$/.test(p.path)).map(p=>{
  const text=fs.readFileSync(path.join(source,p.path),'utf8');
  return{...p,path:'src/'+p.path,module:p.path.replace(/\.(lean|ps)$/,'').replaceAll('/','.'),
   kind:p.path.endsWith('.ps')?'ps':'lean',
   imports:[...text.matchAll(/^import\s+(.+)$/gm)].flatMap(m=>m[1].trim().split(/\s+/))};
 });
}
const readSourcesCode=[
 "import fs from 'node:fs';import crypto from 'node:crypto';",
 "const data=JSON.parse(fs.readFileSync(new URL('./source-manifest.json',import.meta.url),'utf8'));",
 "export const sourcePackage=Object.freeze({...data,files:Object.freeze(data.files.map(f=>Object.freeze({...f,imports:Object.freeze(f.imports)})))});",
 "export function readSources({kind='lean'}={}){",
 "if(!['lean','ps'].includes(kind))throw Error('PSC1_PACKAGE_SOURCE_KIND');",
 "const files=sourcePackage.files.filter(f=>f.kind===kind),result=[],seen=new Set(),active=new Set();",
 "const visit=file=>{if(seen.has(file.module))return;if(active.has(file.module))throw Error('PSC1_PACKAGE_SOURCE_CYCLE');active.add(file.module);",
 "for(const name of file.imports){const dep=files.find(f=>f.module===name);if(dep)visit(dep);}",
 "const bytes=fs.readFileSync(new URL('../'+file.path,import.meta.url));if(bytes.length!==file.bytes||crypto.createHash('sha256').update(bytes).digest('hex')!==file.sha256)throw Error('PSC1_PACKAGE_SOURCE_IDENTITY');",
 "result.push(Object.freeze({module:file.module,kind,text:new TextDecoder('utf-8',{fatal:true}).decode(bytes)}));active.delete(file.module);seen.add(file.module);};",
 "files.forEach(visit);if(result.length===0)throw Error('PSC1_PACKAGE_NO_SOURCE_VARIANT');return Object.freeze(result);}"
].join('\n')+'\n';
const sourceTypes=[
 "export interface SourceRecord{readonly module:string;readonly kind:'lean'|'ps';readonly text:string;}",
 "export interface SourceFile{readonly path:string;readonly module:string;readonly kind:'lean'|'ps';readonly bytes:number;readonly sha256:string;readonly imports:readonly string[];}",
 "export const sourcePackage:Readonly<{schema:'psc1-source-package/1';name:string;version:string;kind:string;files:readonly SourceFile[];internalRuntimeApi:false;admissionAuthority:false;}>;",
 "export function readSources(options?:{kind?:'lean'|'ps'}):readonly SourceRecord[];"
].join('\n')+'\n';
const records=[],built=new Map(),packedRoots=new Map();
function build(dir){
 if(built.has(dir))return built.get(dir);
 const packageRoot=path.join(root,'packages',dir),meta=read(path.join(packageRoot,'package.json'));
 if(dir==='stdlib')fs.cpSync(path.join(root,'stdlib/ProofScript'),path.join(packageRoot,'src/ProofScript'),{recursive:true});
 const stamp=sha256(json({input,meta,source:sourceFiles(packageRoot),builder:sha256(fs.readFileSync(fileURLToPath(import.meta.url))),
  rootMetadata:dir==='proofscript'?dirs.map(name=>['package.json','README.md','LICENSE','NOTICE'].map(file=>{const p=path.join(root,'packages',name,file);return fs.existsSync(p)?sha256(fs.readFileSync(p)):null;})):null}));
 const marker=path.join(out,'build-cache',dir+'.json');
 if(fs.existsSync(marker)){
  const old=read(marker);
  if(old.input===stamp&&old.files.every(p=>fs.existsSync(path.join(packageRoot,p.path))&&sha256(fs.readFileSync(path.join(packageRoot,p.path)))===p.sha256)&&
    fs.existsSync(path.join(packed,old.tarball))&&sha256(fs.readFileSync(path.join(packed,old.tarball)))===old.sha256){
   const unpacked=path.join(out,'packed',dir);if(!fs.existsSync(path.join(unpacked,'package')))unpack(path.join(packed,old.tarball),unpacked);
   packedRoots.set(dir,path.join(unpacked,'package'));built.set(dir,old);records.push({...old,cache:'verified-unchanged'});return old;
  }
 }
 if(dir!=='proofscript'&&!dir.startsWith('pskernel-lean'))build('proofscript');
 if(dir==='proofscript'){build('pskernel-lean-wasm');build('pskernel-lean');}
 clean(dir);fs.mkdirSync(path.join(packageRoot,'dist'));
 if(dir==='backend-python'||dir==='backend-php')hydrate(packageRoot,originalPackage(meta.name));
 if(dir.startsWith('pskernel-lean'))fs.cpSync(originalPackage(meta.name),path.join(packageRoot,'dist/implementation'),{recursive:true});
 if(dir==='stdlib'){
  // Preserve the existing canonical standard library; copy, never translate.
  fs.cpSync(path.join(root,'stdlib/ProofScript'),path.join(packageRoot,'src/ProofScript'),{recursive:true});
 }
 const sources=sourceFiles(packageRoot);
 put(path.join(packageRoot,'dist/source-manifest.json'),json({schema:'psc1-source-package/1',
  name:meta.name,version:meta.version,kind:meta.proofscript?.packageKind??'independent-kernel',
  files:sources,internalRuntimeApi:false,admissionAuthority:false}));
 put(path.join(packageRoot,'dist/sources.js'),readSourcesCode);
 put(path.join(packageRoot,'dist/sources.d.ts'),sourceTypes);
 if(dir==='proofscript'){
  const impl=path.join(packageRoot,'dist/implementation');
  fs.cpSync(frozen,impl,{recursive:true,filter:p=>p!==path.join(frozen,'node_modules')});
  // Update distribution metadata before sealing it; execution code stays exact.
  put(path.join(impl,'package.json'),json({...audit.rootMetadata,version:meta.version,
   dependencies:meta.dependencies,peerDependencies:meta.peerDependencies}));
  const metadataChanges=new Set(['package.json','DEPENDENCY_LOCK.json','npm-shrinkwrap.json']);
  for(const file of ['DEPENDENCY_LOCK.json','npm-shrinkwrap.json']){
   const target=path.join(impl,file);if(!fs.existsSync(target))continue;
   const lock=read(target);lock.version=meta.version;
   if(lock.packages?.[''])Object.assign(lock.packages[''],{version:meta.version,dependencies:meta.dependencies,peerDependencies:meta.peerDependencies});
   if(lock.packages?.['node_modules/@proofscript/pskernel-lean-wasm'])lock.packages['node_modules/@proofscript/pskernel-lean-wasm'].version=meta.dependencies['@proofscript/pskernel-lean-wasm'];
   put(target,json(lock));
  }
  const d=read(path.join(impl,'UNIVERSAL_DISTRIBUTION.json'));d.version=meta.version;
  d.hostFiles=d.hostFiles.map(pin=>{
   const bytes=fs.readFileSync(path.join(impl,pin.path));
   if(!metadataChanges.has(pin.path)){assert.equal(bytes.length,pin.bytes);assert.equal(sha256(bytes),pin.sha256);return pin;}
   return{...pin,bytes:bytes.length,sha256:sha256(bytes)};
  });
  const kernel=packedRoots.get('pskernel-lean-wasm');
  assert.ok(kernel);const kernelMeta=read(path.join(kernel,'package.json'));
  function repinMetadata(descriptor,dir){
   const targetRoot=path.join(root,'packages',dir),published=read(path.join(targetRoot,'package.json'));
   return{...descriptor,version:published.version,files:descriptor.files.map(pin=>{
    if(!['package.json','README.md','LICENSE','NOTICE'].includes(pin.path))return pin;
    const bytes=fs.readFileSync(path.join(targetRoot,pin.path));
    return{...pin,bytes:bytes.length,sha256:sha256(bytes)};
   })};
  }
  for(const [provider,dir]of [['wasm','pskernel-lean-wasm'],['native','pskernel-lean']])
   d.kernels[provider]={...d.kernels[provider],version:read(path.join(packedRoots.get(dir),'package.json')).version,entry:'dist/index.js',files:inventory(packedRoots.get(dir))};
  for(const target of ['python','php'])d.dispatchPackages[target]=repinMetadata(d.dispatchPackages[target],'backend-'+target);
  put(path.join(impl,'UNIVERSAL_DISTRIBUTION.json'),json(d));
  const originalPin=fs.readFileSync(path.join(impl,'DISTRIBUTION_PIN.mjs'),'utf8');
  put(path.join(impl,'DISTRIBUTION_PIN.mjs'),originalPin.replace(/expectedDistributionSha256\s*=\s*['"][a-f0-9]{64}['"]/,
    "expectedDistributionSha256 = "+JSON.stringify(sha256(json(d)))));

  const bundled=path.join(packageRoot,'node_modules/@proofscript/pskernel-lean-wasm');
  if(fs.existsSync(bundled)){inventory(bundled);fs.rmSync(bundled,{recursive:true});}
  fs.cpSync(kernel,bundled,{recursive:true});
  put(path.join(packageRoot,'dist/index.js'),"export * from './implementation/npm-cli/compiler-api.mjs';\n");
  put(path.join(packageRoot,'dist/index.d.ts'),fs.readFileSync(path.join(impl,'npm-cli/universal.d.ts')));
  put(path.join(packageRoot,'dist/psc.mjs'),"#!/usr/bin/env node\nimport './implementation/npm-cli/proofscript-cli.mjs';\n");
  fs.chmodSync(path.join(packageRoot,'dist/psc.mjs'),0o755);
 }else if(dir.startsWith('pskernel-lean')){
  put(path.join(packageRoot,'dist/index.js'),"export * from './implementation/index.mjs';\n");
  put(path.join(packageRoot,'dist/index.d.ts'),fs.readFileSync(path.join(packageRoot,'dist/implementation/index.d.ts')));
 }else{
  const adapter="export * from 'proofscript';\n",types="export * from 'proofscript';\n";
  put(path.join(packageRoot,'dist/compiler.js'),adapter);
  put(path.join(packageRoot,'dist/compiler.d.ts'),types);
  let entry="export {sourcePackage,readSources} from './sources.js';\n",declarations="export * from './sources.js';\n";
  if(['compiler','cli','bootstrap'].includes(dir)){entry+=adapter;declarations+=types;}
  if(dir.startsWith('backend-')&&dir!=='backend-common'){
   const target=dir==='backend-wasm'?'wasm-core':dir.slice('backend-'.length);
   entry+="import {compile as checked} from 'proofscript';\nexport function compile(options){if(options.target!==undefined&&options.target!=="+
    JSON.stringify(target)+")throw Error('PSC1_PACKAGE_TARGET');return checked({...options,target:"+JSON.stringify(target)+"});}\n";
   declarations+="import type {CompileOptions,CheckedCompilation} from 'proofscript';\nexport function compile(options:Omit<CompileOptions,'target'>):CheckedCompilation;\n";
  }
  put(path.join(packageRoot,'dist/index.js'),entry);
  put(path.join(packageRoot,'dist/index.d.ts'),declarations);
 }
 for(const name of ['LICENSE','NOTICE'])if(!fs.existsSync(path.join(packageRoot,name)))put(path.join(packageRoot,name),fs.readFileSync(path.join(root,name)));
 const r={directory:dir,name:meta.name,version:meta.version,input:stamp,...pack(packageRoot),
  kind:meta.proofscript?.packageKind??'independent-kernel',files:[]};
 const unpacked=path.join(out,'packed',dir);if(fs.existsSync(unpacked))fs.rmSync(unpacked,{recursive:true});
 unpack(path.join(packed,r.tarball),unpacked);packedRoots.set(dir,path.join(unpacked,'package'));
 // Track emitted content; build stamps are not part of the published API or compiler pins.
 r.files=inventory(path.join(packageRoot,'dist')).map(p=>({...p,path:'dist/'+p.path}));
 put(marker,json(r));built.set(dir,r);records.push(r);return r;
}
for(const dir of selected?[selected]:dirs)build(dir);

const sourceRows=dirs.map(dir=>({directory:dir,name:read(path.join('packages',dir,'package.json')).name,files:sourceFiles(path.join('packages',dir))}));
const sourceOwner=new Map(sourceRows.flatMap(row=>row.files.map(file=>[file.module,row.name])));
put(path.join(out,'source-dependencies.json'),json(sourceRows.map(row=>({
 directory:row.directory,name:row.name,sourceModules:row.files.map(f=>f.module),
 sourceDependencies:[...new Set(row.files.flatMap(f=>f.imports).map(name=>sourceOwner.get(name)).filter(name=>name&&name!==row.name))].sort(),
 externalOrInternalWorkspaceImports:[...new Set(row.files.flatMap(f=>f.imports).filter(name=>!sourceOwner.has(name)))].sort(),
 runtimeDependencies:read(path.join('packages',row.directory,'package.json')).dependencies??{},
 scope:'source import inventory only; runtime adapters reuse proofscript and do not execute internal source imports'
}))));

put(path.join(out,'package-builds.json'),json({schema:'psc1-existing-package-builds/1',
 testedCommit:process.env.GITHUB_SHA,version:input.version,implementationOwner:'proofscript',
 independentCompilerModularity:'deferred',packages:records,
 unnamedSourceOnlyDirectories:fs.readdirSync('packages').filter(d=>fs.statSync(path.join('packages',d)).isDirectory()&&!dirs.includes(d))}));
console.log('PSC1_PACKAGE_BUILDS '+json(records.map(({files,...r})=>r)));
