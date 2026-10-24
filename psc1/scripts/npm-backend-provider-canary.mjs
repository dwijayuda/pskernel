// Qualify actual offline installations. No registry publication or install scripts.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {pathToFileURL,fileURLToPath} from 'node:url';
const [runRoot,consumer,cli,pythonTarball,phpTarball]=process.argv.slice(2);
assert.ok(phpTarball,'usage: runRoot consumer cli python.tgz php.tgz');
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const contract=JSON.parse(fs.readFileSync(path.join(root,'BACKEND_PROVIDER_CONTRACT.json'),'utf8'));
const installed=path.join(consumer,'node_modules/proofscript');
const env={...process.env};
for(const key of ['PSC1_NATIVE','PSC1_HOST_TOOLS','PSC1_LIBRARY_RESOLVER','PSC1_TSC'])delete env[key];
function command(cmd,args,options={}){
 const r=spawnSync(cmd,args,{cwd:consumer,env,encoding:'utf8',timeout:180000,maxBuffer:32*1024*1024,...options});
 assert.equal(r.error,undefined,r.error?.message);assert.equal(r.status,0,r.stdout+r.stderr);return r.stdout;
}
const psc=args=>command(process.execPath,[cli,...args]);
function refused(args,pattern){
 const r=spawnSync(process.execPath,[cli,...args],{cwd:consumer,env,encoding:'utf8',timeout:120000});
 assert.equal(r.error,undefined);assert.notEqual(r.status,0,r.stdout+r.stderr);assert.match(r.stderr,pattern);
}
const meta=JSON.parse(fs.readFileSync(path.join(installed,'package.json'),'utf8'));
assert.deepEqual(meta.proofscript.builtInTargets,contract.coreTargets);
assert.deepEqual(meta.proofscript.optionalTargets,['python','php']);
for(const target of ['python','php']){
 const packageName=contract.optionalProviders[target].package;
 for(const field of ['dependencies','optionalDependencies','bundledDependencies']){
  assert.ok(!Object.hasOwn(meta[field]||{},packageName));if(Array.isArray(meta[field]))assert.ok(!meta[field].includes(packageName));
 }
 assert.equal(fs.existsSync(path.join(consumer,'node_modules',packageName)),false);
 for(const resource of contract.optionalProviders[target].resources)
  assert.equal(fs.existsSync(path.join(installed,'host-tools',resource)),false,'optional resource absent from core');
 assert.equal(fs.existsSync(path.join(installed,'native/bin/psc1_backend_'+target)),false);
}
const records=[],refusals=[];
for(const syntax of ['lean','ps']){
 const source=path.join(consumer,'Default.'+syntax);
 fs.writeFileSync(source,'def truth : Bool := true\n');
 for(const target of contract.coreTargets){
  const extension=target==='js'?'.js':target==='ts'?'.ts':target==='rust'?'.rs':'.wasm';
  const output=path.join(consumer,syntax+'-'+target+extension);
  psc(['build',source,'--target',target,...(target==='wasm-component'?['--export','truth']:[]),'--out',output]);
  const manifest=JSON.parse(fs.readFileSync(output+'.bundle.json','utf8'));
  assert.equal(manifest.target,target);assert.equal(manifest.logicalCheckerCommit,'eb6cafb7290e8bd5f2937522d8d804f58f02bafc');
  assert.equal(manifest.backendProvider,undefined);
  if(target==='js'){const m=await import(pathToFileURL(output).href);assert.equal(typeof m.truth==='function'?m.truth():m.truth,true);}
  if(target==='ts'){
   assert.ok(process.env.PSC1_TSC,'pinned independent TypeScript checker required');
   const emitted=path.join(consumer,'ts-consumer-'+syntax);
   command(process.execPath,[process.env.PSC1_TSC,'--strict','--target','es2022','--module','es2022','--outDir',emitted,output]);
   const m=await import(pathToFileURL(path.join(emitted,path.basename(output,'.ts')+'.js')).href);
   assert.equal(typeof m.truth==='function'?m.truth():m.truth,true);
  }
  if(target==='rust'){
   const harness=path.join(consumer,'rust-consumer-'+syntax);
   fs.cpSync(output.slice(0,-3)+'.cargo',harness,{recursive:true,dereference:true});
   fs.mkdirSync(path.join(harness,'tests'),{recursive:true});
   fs.writeFileSync(path.join(harness,'tests/truth.rs'),'#[test] fn truth(){assert!(psc1_generated::truth());}');
   command('cargo',['test','--locked','--manifest-path',path.join(harness,'Cargo.toml')],{env:{...env,CARGO_TARGET_DIR:path.join(runRoot,'rust-package-target')}});
  }
  if(target==='wasm-core'){const {instance}=await WebAssembly.instantiate(fs.readFileSync(output),{});assert.equal(instance.exports.truth(),1);}
  if(target==='wasm-component')assert.match(command('wasmtime',['run','--invoke','truth()',output]),/true/);
  records.push({syntax,target,installed:true,executed:true,admission:manifest.logicalCheckerCommit,validated:true});
 }
 for(const target of ['python','php']){
  const output=path.join(consumer,'absent-'+syntax+'-'+target+contract.optionalProviders[target].extension);
  fs.writeFileSync(output,'previous-output');
  refused(['build',source,'--target',target,'--out',output],/PSC1_BACKEND_PROVIDER_MISSING/);
  assert.equal(fs.readFileSync(output,'utf8'),'previous-output');
  refusals.push('absent-'+syntax+'-'+target);
 }
}
const providerRecords=[];
for(const [target,tarball]of [['python',pythonTarball],['php',phpTarball]]){
 command('npm',['install','--prefix',consumer,'--cache',path.join(runRoot,'empty-npm-cache'),
  '--offline','--ignore-scripts','--no-audit','--no-fund',tarball]);
 const spec=contract.optionalProviders[target],addon=path.join(consumer,'node_modules',spec.package);
 const metadataFile=path.join(addon,'package.json'),original=fs.readFileSync(metadataFile,'utf8'),addonMeta=JSON.parse(original);
 assert.equal(addonMeta.name,spec.package);
 assert.deepEqual(addonMeta.peerDependencies,{proofscript:meta.version});
 assert.equal(addonMeta.proofscript.backendProvider.target,target);
 if(target==='python'){
  assert.equal(fs.existsSync(path.join(consumer,'node_modules/@proofscript/backend-php')),false);
 }
 for(const syntax of ['lean','ps']){
  const source=path.join(consumer,'Addon.'+syntax),output=path.join(consumer,syntax+'-'+target+spec.extension);
  fs.writeFileSync(source,'def answer : Nat := 42\n');
  const args=['build',source,'--target',target,'--out',output];psc(args);
  const before=fs.readFileSync(output);
  const manifest=JSON.parse(fs.readFileSync(output+'.bundle.json','utf8'));
  assert.equal(manifest.logicalCheckerCommit,'eb6cafb7290e8bd5f2937522d8d804f58f02bafc');
  assert.equal(manifest.backendProvider.mode,'installed-package');
  assert.equal(manifest.backendProvider.packageName,spec.package);
  assert.equal(manifest.backendProvider.compilerSourceCommit,JSON.parse(fs.readFileSync(path.join(installed,'NATIVE_DISTRIBUTION.json'),'utf8')).sourceCommit);
  if(target==='python')command(process.env.PSC1_PYTHON||'python3',['-c','import runpy,sys; assert runpy.run_path(sys.argv[1])["answer"]==42',output]);
  else command('php',['-r','$api=require $argv[1]; if(gmp_cmp($api["answer"],42)!==0)exit(1);',output]);
  for(const [label,mutate]of [
   ['pin',x=>x.proofscript.backendProvider.leanCommit='0'.repeat(40)],
   ['source',x=>x.proofscript.backendProvider.compilerSourceCommit='0'.repeat(40)],
   ['target',x=>x.proofscript.backendProvider.target=target==='python'?'php':'python'],
   ['schema',x=>x.proofscript.backendProvider.kernel='untrusted-authority']
  ]){
   const changed=JSON.parse(original);mutate(changed);fs.writeFileSync(metadataFile,JSON.stringify(changed));
   try{refused(args,/PSC1_PROVIDER_PACKAGE_(IDENTITY|SCHEMA)/);assert.deepEqual(fs.readFileSync(output),before);}
   finally{fs.writeFileSync(metadataFile,original);}
   refusals.push(target+'-'+syntax+'-'+label);
  }
  if(syntax==='lean'){
   const binary=path.join(addon,addonMeta.proofscript.backendProvider.native.path),bytes=fs.readFileSync(binary);
   const changed=Buffer.from(bytes);changed[changed.length-1]^=1;fs.writeFileSync(binary,changed);
   try{refused(args,/PSC1_PROVIDER_BINARY_INTEGRITY/);assert.deepEqual(fs.readFileSync(output),before);}
   finally{fs.writeFileSync(binary,bytes);}
   refusals.push(target+'-binary-integrity');
   const resource=path.join(addon,addonMeta.proofscript.backendProvider.resources[0].path),saved=fs.readFileSync(resource);
   fs.appendFileSync(resource,'#tamper');
   try{refused(args,/PSC1_PROVIDER_BINARY_INTEGRITY/);assert.deepEqual(fs.readFileSync(output),before);}
   finally{fs.writeFileSync(resource,saved);}
   refusals.push(target+'-resource-integrity');
  }
  providerRecords.push({target,syntax,installed:true,executed:true,packageName:spec.package,
   binarySha256:manifest.backendProvider.binarySha256,requestSha256:manifest.backendProvider.requestSha256,
   admission:manifest.logicalCheckerCommit});
 }
}
const receipt={schema:'psc1-installed-backend-providers/1',testedCommit:process.env.GITHUB_SHA||null,
 passed:true,defaultTargets:contract.coreTargets,optionalTargets:['python','php'],
 explicitOfflineInstalls:true,optionalPackagesAbsentByDefault:true,optionalResourcesAbsentByDefault:true,
 records,providerRecords,refusals,preservedExistingOutput:true};
fs.writeFileSync(path.join(runRoot,'backend-provider-qualification.json'),JSON.stringify(receipt,null,2)+'\n');
console.log(JSON.stringify(receipt));
