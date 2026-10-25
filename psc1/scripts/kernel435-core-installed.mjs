// Genuine installed native/generated compilation and two independent kernel providers.
import fs from 'node:fs';import path from 'node:path';import os from 'node:os';import assert from 'node:assert/strict';import {spawnSync} from 'node:child_process';import {pathToFileURL} from 'node:url';import {sha256} from './kernel435-qualified-artifact.mjs';import {corpus,observedExpressions,expectedObservations,refusals} from './generated-target-corpus.mjs';import {fixtures} from './kernel435-fixtures.mjs';
const tar=path.resolve(process.argv[2]),tmp=fs.mkdtempSync(path.join(os.tmpdir(),'psc1-integrated-kernels-')),consumer=path.join(tmp,'consumer'),cache=path.join(tmp,'cache');fs.mkdirSync(consumer);
fs.writeFileSync(path.join(consumer,'package.json'),'{"private":true,"type":"module"}');
const run=(exe,args,opts={})=>{const r=spawnSync(exe,args,{cwd:consumer,encoding:'utf8',timeout:240000,maxBuffer:32*1024*1024,...opts});assert.equal(r.error,undefined,String(r.error));assert.equal(r.status,0,(r.stdout||'')+(r.stderr||''));return r.stdout;};
run('npm',['install','--prefix',consumer,'--cache',cache,'--offline','--ignore-scripts','--no-audit','--no-fund',tar]);
const root=path.join(consumer,'node_modules/proofscript'),cli=path.join(root,'npm-cli/generated-entry.mjs'),command=args=>run(process.execPath,[cli,...args]),distribution=JSON.parse(fs.readFileSync(path.join(root,'SELFHOST_DISTRIBUTION.json'),'utf8'));
assert.equal(distribution.sharedSourceClosureDigest,'07eedac1888aad3d4192664cea8d21a515d23985f3befd6cb365d0194fee53af');assert.equal(distribution.allFourEngineSelfHostQualified,true);assert.equal(distribution.allFourEngineReleaseQualified,false);assert.equal(distribution.defaultKernel,'wasm');
assert.equal(fs.existsSync(path.join(root,'native/bin/psc1_independent_checker')),false,'no redundant large checker');
const identity=JSON.parse(command(['kernel','--identity']));assert.equal(identity.leanVersion,'4.35.0');assert.equal(identity.wasmMemoryModel,'linear');
const kernelCases=[];for(const f of fixtures){
 const file=path.join(consumer,'input.json');fs.writeFileSync(file,f.input);const r=spawnSync(process.execPath,[cli,'kernel','check',file,'--provider','both'],{cwd:consumer,encoding:'utf8',timeout:240000,maxBuffer:32*1024*1024});assert.equal(r.error,undefined);assert.equal(r.status,f.accepted?0:1,r.stderr);const value=JSON.parse(r.stdout);assert.equal(value.accepted,f.accepted);assert.equal(value.agreement,true);assert.equal(value.admissionsSha256,sha256(f.input));kernelCases.push({id:f.id,accepted:value.accepted,agreement:true});
}
const sourceCases=[];
for(const kind of ['lean','ps']){
 const file=path.join(consumer,'Main.'+kind);fs.writeFileSync(file,'def answer : Nat := 42\n');
 const result=JSON.parse(command(['kernel','check-source',file,'--provider','both']));assert.equal(result.accepted,true);assert.equal(result.agreement,true);assert.equal(result.provider,'both');sourceCases.push({kind,admissionsSha256:result.admissionsSha256});
 fs.writeFileSync(file,'def wrong : Nat := true\n');const bad=spawnSync(process.execPath,[cli,'kernel','check-source',file,'--provider','both'],{cwd:consumer,encoding:'utf8',timeout:240000});assert.notEqual(bad.status,0);
}
// Use the real qualified G3 engines with the native compiler unavailable.
const native=path.join(root,'native/bin/psc1'),nativeKernel=path.join(root,distribution.checker.path);fs.renameSync(native,native+'.disabled');fs.renameSync(nativeKernel,nativeKernel+'.disabled');const cases=[],negatives=[];
try{
 for(const engine of Object.keys(distribution.engines)){
  for(const item of corpus){
   const project=path.join(consumer,engine+'-'+item.id+'.json'),store=path.join(consumer,engine+'-'+item.id);fs.writeFileSync(project,JSON.stringify({entryModule:item.entry,assurance:item.assurance,sources:item.sources.map(s=>({...s,kind:item.grammar}))}));
   const result=JSON.parse(command(['generated','build','--project',project,'--engine',engine,'--out',store]));assert.equal(result.logicalAdmission,'accepted');assert.deepEqual(result.kernelProviders,['wasm']);
   const generation=fs.realpathSync(path.join(store,'current')),manifest=JSON.parse(fs.readFileSync(path.join(generation,'manifest.json'),'utf8'));assert.equal(typeof manifest.request.checkerScriptSha256,'string');assert.equal(manifest.request.checkerScriptSha256,distribution.kernelCheckers.wasm.script.sha256);
   const observe=path.join(consumer,'observe.mjs');fs.writeFileSync(observe,'import * as m from '+JSON.stringify(pathToFileURL(result.artifact).href)+';\n'+item.consumer+'\nconsole.log(JSON.stringify('+observedExpressions[item.id]+'));\n');assert.deepEqual(JSON.parse(run(process.execPath,[observe])),expectedObservations[item.id]);
   cases.push({engine,id:item.id,grammar:item.grammar,passed:true,compilerExecutionMs:result.compilerExecutionMs,manifestSha256:result.manifestSha256,admissionsSha256:sha256(fs.readFileSync(path.join(generation,'admissions.json')))});
  }
  const prior=path.join(consumer,engine+'-'+corpus[0].id),pointer=fs.readlinkSync(path.join(prior,'current'));
  for(const f of refusals){const project=path.join(consumer,'bad.json');fs.writeFileSync(project,JSON.stringify({entryModule:'Entry',assurance:f.assurance,sources:[{module:'Entry',kind:f.grammar,text:f.source}]}));const r=spawnSync(process.execPath,[cli,'generated','build','--project',project,'--engine',engine,'--out',prior],{cwd:consumer,encoding:'utf8',timeout:240000});assert.notEqual(r.status,0);assert.equal(fs.readlinkSync(path.join(prior,'current')),pointer);negatives.push({engine,id:f.id,priorPreserved:true});}
  const wasm=path.join(root,'node_modules/@proofscript/pskernel-lean-wasm/wasm/pskernel-lean.wasm'),b=fs.readFileSync(wasm),changed=Buffer.from(b);changed[changed.length-1]^=1;fs.writeFileSync(wasm,changed);
  try{const r=spawnSync(process.execPath,[cli,'generated','build','--project',path.join(consumer,engine+'-'+corpus[0].id+'.json'),'--engine',engine,'--out',prior],{cwd:consumer,encoding:'utf8',timeout:240000});assert.notEqual(r.status,0);assert.equal(fs.readlinkSync(path.join(prior,'current')),pointer);negatives.push({engine,id:'Wasm-kernel-tamper',priorPreserved:true});}finally{fs.writeFileSync(wasm,b);}
 }
}finally{fs.renameSync(native+'.disabled',native);fs.renameSync(nativeKernel+'.disabled',nativeKernel);}
const crossChecks=[];
for(const engine of Object.keys(distribution.engines)){
 for(const item of corpus.slice(0,2)){
  const project=path.join(consumer,engine+'-'+item.id+'.json'),store=path.join(consumer,engine+'-both-'+item.id);
  const result=JSON.parse(command(['generated','build','--project',project,'--engine',engine,'--kernel','both','--out',store]));
  assert.deepEqual(result.kernelProviders,['wasm','native']);assert.equal(result.additionalAdmissions.length,1);assert.equal(result.additionalAdmissions[0].name,'native');assert.equal(result.additionalAdmissions[0].accepted,true);
  crossChecks.push({engine,grammar:item.grammar,passed:true,primary:'wasm',additional:'native'});
 }
}
const nativePublication=[];
for(const kind of ['lean','ps']){
 const source=path.join(consumer,'Native.'+kind),output=path.join(consumer,'native-'+kind+'.js');fs.writeFileSync(source,'def answer : Nat := 42\n');
 command(['build',source,'--out',output]);const manifest=JSON.parse(fs.readFileSync(output+'.bundle.json','utf8'));assert.equal(manifest.independentKernel.provider,'wasm');assert.equal(manifest.independentKernel.accepted,true);assert.equal(manifest.independentKernel.admissionsSha256,manifest.kernelAdmissionSha256);
 assert.equal(run(process.execPath,['--input-type=module','-e','const m=await import('+JSON.stringify(pathToFileURL(output).href)+');console.log(String(m.answer))']).trim(),'42');
 const current=path.join(path.dirname(output),'.'+path.basename(output)+'.psc1/current'),before=fs.readlinkSync(current),wasm=path.join(root,'node_modules/@proofscript/pskernel-lean-wasm/wasm/pskernel-lean.wasm'),bytes=fs.readFileSync(wasm),changed=Buffer.from(bytes);changed[changed.length-1]^=1;fs.writeFileSync(wasm,changed);fs.writeFileSync(source,'def answer : Nat := 43\n');
 try{const r=spawnSync(process.execPath,[cli,'build',source,'--out',output],{cwd:consumer,encoding:'utf8',timeout:240000});assert.notEqual(r.status,0);assert.equal(fs.readlinkSync(current),before);}finally{fs.writeFileSync(wasm,bytes);}
 nativePublication.push({kind,defaultKernel:'wasm',actualResult:'42',corruptWasmPreservesPrior:true,admissionsSha256:manifest.kernelAdmissionSha256});
}
const policy=path.join(root,'KERNEL_DISTRIBUTION.json'),policyBytes=fs.readFileSync(policy);fs.renameSync(policy,policy+'.disabled');
try{const missing=spawnSync(process.execPath,[cli,'check',path.join(consumer,'Native.lean')],{cwd:consumer,encoding:'utf8',timeout:240000});assert.notEqual(missing.status,0,'missing Wasm policy must not fall back to native');}finally{fs.renameSync(policy+'.disabled',policy);}

const report={schema:'psc1-integrated-kernel-installed/1',sourceCommit:process.env.GITHUB_SHA,status:'passed',tarballSha256:sha256(fs.readFileSync(tar)),platform:process.platform+'-'+process.arch,kernelCases,sourceCases,cases,negatives,crossChecks,nativePublication,missingPolicyRefused:true,nativeCompilerUnavailableDuringGeneratedCases:true,defaultIndependentWasm:true,nativeCheckerUnavailableDuringDefaultGeneratedCases:true,wasmMemoryModel:'linear',compilerSourceClosureDigest:distribution.sharedSourceClosureDigest,finalCrossPlatformRelease:false,scope:'installed Linux integration; kernel packages carry their separate five-platform qualification'};
fs.mkdirSync('dist/kernel435-core-installed',{recursive:true});fs.writeFileSync('dist/kernel435-core-installed/qualification.json',JSON.stringify(report,null,2)+'\n');console.log('PSC1_KERNEL435_CORE_INSTALLED: '+JSON.stringify(report));
