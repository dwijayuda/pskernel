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
const applicationCases=[],sourceRoot=process.cwd();const write=(p,b)=>{fs.mkdirSync(path.dirname(p),{recursive:true});fs.writeFileSync(p,b);};
const canonicalPs=new Map();
{
 // Standard library .ps is derived by the existing owned translator, exactly as
 // normal native package resolution and compiler source census already do.
 const ordered=[],seen=new Set();
 function visit(module){
  if(seen.has(module))return;
  const file=path.join(sourceRoot,'stdlib',...module.split('.'))+'.lean',text=fs.readFileSync(file,'utf8');
  for(const m of text.matchAll(/^import\s+(.+)$/gm))for(const dep of m[1].trim().split(/\s+/))visit(dep);
  seen.add(module);ordered.push({module,file});
 }
 visit('ProofScript.System.IO');
 for(const item of ordered){const translated=command(['translate',item.file,'--to','ps']);assert.equal(typeof translated,'string');assert.ok(translated.length);canonicalPs.set(item.module,translated);}

}

function applicationSources(grammar,entryModule,entryText){
 const ordered=[],seen=new Set(),active=new Set();
 function visit(module,text){
  if(seen.has(module))return;assert.ok(!active.has(module),'application import cycle');active.add(module);
  const file=module.startsWith('ProofScript.')?path.join(sourceRoot,'stdlib',...module.split('.'))+'.'+grammar
   :path.join(sourceRoot,'test/applications',...module.split('.'))+'.'+grammar;
  const source=text===undefined?(grammar==='ps'&&module.startsWith('ProofScript.')?canonicalPs.get(module):fs.readFileSync(file,'utf8')):text;assert.equal(typeof source,'string');
  for(const m of source.matchAll(/^import\s+(.+)$/gm))for(const name of m[1].trim().split(/\s+/))visit(name);
  active.delete(module);seen.add(module);ordered.push({module,kind:grammar,text:source});
 }
 visit(entryModule,entryText);return ordered;
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
for(const grammar of ['lean','ps']){
 const jsonEntry=grammar==='lean'
  ? 'import JsonRecords.Transform\ndef observe (source : String) : Nat := recordObservation [source]\n'
  : 'import JsonRecords.Transform\ndef observe(source : String) : Nat := recordObservation([source])\n';
 const cliEntry=grammar==='lean'
  ? 'import PracticalCli.Args\ndef observe (source : String) : Nat :=\n  match cliArguments source with\n  | Option.none => 2\n  | Option.some command =>\n      match command with\n      | CliCommand.help => 0\n      | CliCommand.transform _ _ => 1\n'
  : 'import PracticalCli.Args\ndef observe(source : String) : Nat :=\n match (cliArguments(source)) with { | Option.none => 2 | Option.some command => match (command) with { | CliCommand.help => 0 | CliCommand.transform input output => 1 } }\n';
 for(const [app,text,observations]of [
  ['json-records',jsonEntry,[['{"text":"A"}','65'],['{"text":"\\uD83D\\uDE00"}','128512'],['{"text":"\\uD800"}','1'],['{"text":false}','2'],['{"text":"A","text":"B"}','2']]],
  ['cli-arguments',cliEntry,[['["--help"]','0'],['["transform","in λ😀.json","out.json"]','1'],['["transform","input.json"]','2'],['["--help","extra"]','2'],['{','2']]]
 ]){
  const sources=applicationSources(grammar,'Entry',text),project=path.join(consumer,app+'-'+grammar+'.json');
  write(project,JSON.stringify({entryModule:'Entry',assurance:'ordinary-checked',sources}));
  const expected=observations.map(x=>x[1]);
  for(const engine of Object.keys(distribution.engines)){
   const store=path.join(consumer,engine+'-'+app+'-'+grammar);
   const result=JSON.parse(command(['generated','build','--project',project,'--engine',engine,'--out',store]));
   const observe=path.join(consumer,'application-observe.mjs');
   write(observe,"import * as m from "+JSON.stringify(pathToFileURL(result.artifact).href)+";\n"+
    'console.log(JSON.stringify('+JSON.stringify(observations.map(x=>x[0]))+'.map(x=>String(m.observe(x)))));\n');
   assert.deepEqual(JSON.parse(run(process.execPath,[observe])),expected);
   applicationCases.push({engine,grammar,app,modules:sources.length,observations:observations.length,
    sourceClosureDigest:result.sourceClosureDigest,compilerExecutionMs:result.compilerExecutionMs,manifestSha256:result.manifestSha256,passed:true});
  }
 }
 // Qualify the direct single-file user command as well as captured projects.
 const filename=path.join(consumer,'Single.'+grammar);write(filename,'def answer : Nat := 42\n');
 for(const engine of Object.keys(distribution.engines)){
  const result=JSON.parse(command(['generated','build',filename,'--engine',engine,'--out',path.join(consumer,engine+'-single-'+grammar)]));
  const observe=path.join(consumer,'single-observe.mjs');write(observe,"import * as m from "+JSON.stringify(pathToFileURL(result.artifact).href)+";\nif(m.answer!==42n)throw Error('single file');\n");
  run(process.execPath,[observe]);applicationCases.push({engine,grammar,app:'single-file',observations:1,compilerExecutionMs:result.compilerExecutionMs,passed:true});
 }
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


const policyDeclarations=[];
const selfFile=path.join(root,'SELFHOST_DISTRIBUTION.json'),packageFile=path.join(root,'package.json'),selfBytes=fs.readFileSync(selfFile),packageBytes=fs.readFileSync(packageFile);
const prior=path.join(consumer,'js-'+corpus[0].id),beforePointer=fs.readlinkSync(path.join(prior,'current')),project=path.join(consumer,'js-'+corpus[0].id+'.json');
for(const [id,file,original,change]of [
 ['missing-generated-default',selfFile,selfBytes,d=>{delete d.defaultKernel;}],
 ['conflicting-generated-default',selfFile,selfBytes,d=>{d.defaultKernel='native';}],
 ['missing-root-default',packageFile,packageBytes,d=>{delete d.proofscript.defaultKernel;}],
 ['conflicting-root-default',packageFile,packageBytes,d=>{d.proofscript.defaultKernel='native';}]
]){
 const data=JSON.parse(original);change(data);fs.writeFileSync(file,JSON.stringify(data));
 try{
  const refused=spawnSync(process.execPath,[cli,'generated','build','--project',project,'--engine','js','--out',prior],{cwd:consumer,encoding:'utf8',timeout:240000});
  assert.notEqual(refused.status,0,id);assert.match(refused.stderr,/DEFAULT_KERNEL_POLICY/,id);assert.equal(fs.readlinkSync(path.join(prior,'current')),beforePointer);
  const nativeOutput=path.join(consumer,'native-lean.js'),nativeCurrent=path.join(consumer,'.native-lean.js.psc1/current'),nativePrior=fs.readlinkSync(nativeCurrent);
  for(const args of [['check',path.join(consumer,'Native.lean')],['build',path.join(consumer,'Native.lean'),'--out',nativeOutput]]){
   const denied=spawnSync(process.execPath,[cli,...args],{cwd:consumer,encoding:'utf8',timeout:240000});assert.notEqual(denied.status,0,id+' native command');assert.match(denied.stderr,/DEFAULT_KERNEL_POLICY/);
  }
  assert.equal(fs.readlinkSync(nativeCurrent),nativePrior);
  policyDeclarations.push({id,refused:true,priorPreserved:true,nativeCheckerAvailable:true,commands:['generated-build','source-check','native-build']});
 }finally{fs.writeFileSync(file,original);}
}

const report={schema:'psc1-integrated-kernel-installed/1',sourceCommit:process.env.GITHUB_SHA,status:'passed',tarballSha256:sha256(fs.readFileSync(tar)),platform:process.platform+'-'+process.arch,kernelCases,sourceCases,cases,applicationCases,negatives,crossChecks,nativePublication,policyDeclarations,missingPolicyRefused:true,nativeCompilerUnavailableDuringGeneratedCases:true,defaultIndependentWasm:true,nativeCheckerUnavailableDuringDefaultGeneratedCases:true,wasmMemoryModel:'linear',compilerSourceClosureDigest:distribution.sharedSourceClosureDigest,finalCrossPlatformRelease:false,scope:'installed Linux integration; kernel packages carry their separate five-platform qualification'};
fs.mkdirSync('dist/kernel435-core-installed',{recursive:true});fs.writeFileSync('dist/kernel435-core-installed/qualification.json',JSON.stringify(report,null,2)+'\n');console.log('PSC1_KERNEL435_CORE_INSTALLED: '+JSON.stringify(report));
