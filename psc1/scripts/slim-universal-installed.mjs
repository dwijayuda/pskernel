// Linux installed-root qualification. No checkout, SDK, native compiler or fallback on PATH.
import fs from 'node:fs';import path from 'node:path';import os from 'node:os';import assert from 'node:assert/strict';import {spawnSync} from 'node:child_process';import {pathToFileURL} from 'node:url';
import {compilerSourceClosureDigest} from '../host-tools/compiler-host-protocol.mjs';
import {corpus,observedExpressions,expectedObservations,refusals} from './generated-target-corpus.mjs';import {fixtures} from './kernel435-fixtures.mjs';import {sha256} from './kernel435-qualified-artifact.mjs';
const out=path.resolve('dist/slim-universal'),assembly=JSON.parse(fs.readFileSync(path.join(out,'package-receipt.json'),'utf8')),tarballs=path.join(out,'tarballs'),tar=path.join(tarballs,assembly.tarball);
assert.equal(sha256(fs.readFileSync(tar)),assembly.sha256);
const temp=fs.mkdtempSync(path.join(os.tmpdir(),'psc1-slim-installed-')),consumer=path.join(temp,'consumer'),prefix=path.join(temp,'global');fs.mkdirSync(consumer);
fs.writeFileSync(path.join(consumer,'package.json'),'{"private":true,"type":"module"}');
const env={...process.env,PATH:path.dirname(process.execPath)};for(const k of Object.keys(env))if(k==='NODE_OPTIONS'||k.startsWith('PSC1_')||k==='LEAN_PATH'||k==='ELAN_TOOLCHAIN'||k==='LD_LIBRARY_PATH'||k==='DYLD_LIBRARY_PATH'||k==='PSC_LEAN_KERNEL_PROVIDER_BIN')delete env[k];
const npm=path.resolve(path.dirname(process.execPath),'../lib/node_modules/npm/bin/npm-cli.js');assert.ok(fs.existsSync(npm));
function call(exe,args,options={}){return spawnSync(exe,args,{cwd:consumer,env,encoding:'utf8',timeout:240000,maxBuffer:32*1024*1024,...options});}
function run(exe,args,options={}){const r=call(exe,args,options);assert.equal(r.error,undefined,String(r.error));assert.equal(r.status,0,r.stdout+r.stderr);return r.stdout;}
const install=(args,cache)=>run(process.execPath,[npm,'install','--cache',cache,'--offline','--registry','http://127.0.0.1:9','--ignore-scripts','--no-audit','--no-fund',...args]);
install(['--prefix',consumer,tar],path.join(temp,'local-cache'));install(['--global','--prefix',prefix,tar],path.join(temp,'global-cache'));
const root=path.join(consumer,'node_modules/proofscript'),globalRoot=path.join(prefix,'lib/node_modules/proofscript'),cli=path.join(consumer,'node_modules/.bin/psc'),globalCli=path.join(prefix,'bin/psc');
const command=args=>JSON.parse(run(cli,args));
const metadata=command(['--identity']);assert.equal(metadata.defaultKernel,'wasm');assert.equal(metadata.defaultEngine,'js');assert.equal(metadata.engines.js.installed,true);assert.equal(metadata.engines.ts.installed,true);assert.equal(metadata.engines.rust.installed,false);assert.equal(metadata.engines['wasm-core'].installed,false);
for(const base of [root,globalRoot]){
 const meta=JSON.parse(fs.readFileSync(path.join(base,'package.json'),'utf8'));assert.ok(!meta.os&&!meta.cpu&&!meta.libc);assert.equal(meta.dependencies['@proofscript/pskernel-lean-wasm'],'4.35.0');assert.deepEqual(Object.keys(meta.dependencies),['@proofscript/pskernel-lean-wasm']);assert.ok(!meta.scripts);
 for(const rel of ['native','selfhost/rust','selfhost/wasm-core','node_modules/@proofscript/compiler-wasm','node_modules/@proofscript/compiler-rust-linux-x64','node_modules/@proofscript/pskernel-lean'])assert.equal(fs.existsSync(path.join(base,rel)),false,'optional payload absent: '+rel);
}

function portableAudit(directory){
 for(const name of fs.readdirSync(directory)){const file=path.join(directory,name),stat=fs.lstatSync(file);assert.ok(!stat.isSymbolicLink(),'no symlinked packaged resources');if(stat.isDirectory())portableAudit(file);else{
  const bytes=fs.readFileSync(file),magic=bytes.subarray(0,4).toString('hex');assert.ok(!['7f454c46','cffaedfe','feedfacf','cefaedfe','feedface'].includes(magic),'native executable payload');assert.notEqual(bytes.subarray(0,2).toString(),'MZ','Windows executable payload');
  if(magic==='0061736d')assert.equal(file,path.join(root,'node_modules/@proofscript/pskernel-lean-wasm/wasm/pskernel-lean.wasm'),'only the mandatory kernel Wasm is in the default root');
 }}
}
portableAudit(root);

const main=path.join(consumer,'Main.lean');fs.writeFileSync(main,'def answer : Nat := 42\n');
for(const engine of ['rust','wasm-core']){
 const missing=call(cli,['build',main,'--engine',engine,'--out',path.join(consumer,'missing-'+engine)]);assert.notEqual(missing.status,0);assert.match(missing.stderr,/OPTIONAL_PACKAGE_MISSING/);
}
const cases=[],negativeCases=[],candidateCases=[],globalCases=[],byteCaptureCases=[];
function exercise(engine,bin=cli,scope='local'){
 for(const item of corpus){
  const project=path.join(consumer,scope+'-'+engine+'-'+item.id+'.json'),store=path.join(consumer,scope+'-'+engine+'-'+item.id);
  fs.writeFileSync(project,JSON.stringify({entryModule:item.entry,assurance:item.assurance,sources:item.sources.map(s=>({...s,kind:item.grammar}))}));
  const result=JSON.parse(run(bin,['build','--project',project,'--engine',engine,'--out',store]));assert.equal(result.logicalAdmission,'accepted');assert.deepEqual(result.kernelProviders,['wasm']);assert.equal(result.compilerSourceClosureDigest,metadata.compilerSourceClosureDigest);
  const observe=path.join(consumer,'observe.mjs');fs.writeFileSync(observe,'import * as m from '+JSON.stringify(pathToFileURL(result.artifact).href)+';\n'+item.consumer+'\nconsole.log(JSON.stringify('+observedExpressions[item.id]+'));\n');assert.deepEqual(JSON.parse(run(process.execPath,[observe])),expectedObservations[item.id]);
  cases.push({engine,scope,id:item.id,grammar:item.grammar,manifestSha256:result.manifestSha256,passed:true});
 }
 const prior=path.join(consumer,scope+'-'+engine+'-'+corpus[0].id),pointer=fs.readlinkSync(path.join(prior,'current'));
 for(const f of refusals){const p=path.join(consumer,'bad.json');fs.writeFileSync(p,JSON.stringify({entryModule:'Entry',assurance:f.assurance,sources:[{module:'Entry',kind:f.grammar,text:f.source}]}));const refused=call(bin,['build','--project',p,'--engine',engine,'--out',prior]);assert.notEqual(refused.status,0);assert.equal(fs.readlinkSync(path.join(prior,'current')),pointer);negativeCases.push({engine,id:f.id,priorPreserved:true});}
}
for(const engine of ['js','ts'])exercise(engine);
for(const bin of [cli,globalCli])for(const grammar of ['lean','ps']){
 const source=path.join(consumer,'Portable.'+grammar);fs.writeFileSync(source,'def answer : Nat := 42\n');
 const checked=JSON.parse(run(bin,['check',source]));assert.equal(checked.engine,'js');assert.equal(checked.logicalAdmission,'accepted');assert.equal(checked.source,undefined);
 const compiled=JSON.parse(run(bin,['compile',source,'--engine','ts']));assert.equal(compiled.engine,'ts');assert.equal(compiled.logicalAdmission,'accepted');assert.equal(compiled.publication,'not-requested');assert.ok(compiled.source.includes('42'));globalCases.push({scope:bin===cli?'local':'global',grammar,checkedStdout:true});
}


const bomFile=path.join(consumer,'Bom.lean'),bomText=String.fromCharCode(0xfeff)+'def answer : Nat := 42\n',bomStore=path.join(consumer,'bom-capture');fs.writeFileSync(bomFile,bomText);
const bomResult=call(cli,['build',bomFile,'--out',bomStore]),expectedBom=compilerSourceClosureDigest([{module:'Bom',kind:'lean',text:bomText}]);
if(bomResult.status===0)assert.equal(JSON.parse(bomResult.stdout).receipt.sourceClosureDigest,expectedBom);
else{const generations=path.join(bomStore,'generations'),attempt=fs.readdirSync(generations).find(n=>n.startsWith('failed-'));assert.ok(attempt,bomResult.stderr);const captured=JSON.parse(fs.readFileSync(path.join(generations,attempt,'request.json'),'utf8'));assert.equal(captured[2],expectedBom);assert.equal(captured[6][0][1],bomText);}
byteCaptureCases.push({id:'utf8-bom-preserved-in-captured-source',compilerAccepted:bomResult.status===0,sourceClosureDigest:expectedBom});
const invalidUtf8=path.join(consumer,'InvalidUtf8.lean');fs.writeFileSync(invalidUtf8,Buffer.from([0xc0,0xaf]));const badEncoding=call(cli,['compile',invalidUtf8]);assert.notEqual(badEncoding.status,0);negativeCases.push({id:'invalid-utf8-refused'});

const rootOnlyApi=path.join(consumer,'root-only-api.mjs');
fs.writeFileSync(rootOnlyApi,"import {compileCandidate,getCompilerMetadata} from 'proofscript';\n"+
 "const records=[];for(const engine of ['js','ts'])for(const target of ['js','ts','rust','wasm-core'])for(const kind of ['lean','ps']){const r=compileCandidate({engine,target,entryModule:'Entry',sources:[{module:'Entry',kind,text:'def answer : Nat := 42\\n'}]});if(r.publicationAuthority!==false||r.logicalAdmission!=='not-run'||r.candidate.status!=='candidate'||r.candidate.target!==target)throw Error('root candidate mapping');records.push({engine,target,grammar:kind,optionalPackagesAbsent:true,candidateOnly:true});}const m=getCompilerMetadata();if(m.engines.rust.installed||m.engines['wasm-core'].installed)throw Error('unexpected optional package');console.log(JSON.stringify(records));\n");
candidateCases.push(...JSON.parse(run(process.execPath,[rootOnlyApi])));
const safeStore=path.join(consumer,'local-js-'+corpus[0].id),safePointer=fs.readlinkSync(path.join(safeStore,'current'));
for(const field of ['out','serviceFile','checkerExecutable','engine']){
 const injected=path.join(consumer,'host-options.json'),selected=path.join(consumer,'source-selected-output-'+field);
 fs.writeFileSync(injected,JSON.stringify({entryModule:'Entry',sources:[{module:'Entry',kind:'lean',text:'def answer : Nat := 42\n'}],[field]:selected}));
 const denied=call(cli,['build','--project',injected,'--out',safeStore]);assert.notEqual(denied.status,0);assert.match(denied.stderr,/PROJECT_FIELDS/);assert.equal(fs.readlinkSync(path.join(safeStore,'current')),safePointer);assert.equal(fs.existsSync(selected),false);
 negativeCases.push({id:'project-cannot-select-'+field,priorPreserved:true});
}

const optional=assembly.input.packages,packagePaths=['rust','wasm-core','nativeKernel'].map(k=>path.join(tarballs,optional[k].tarball));
install(['--prefix',consumer,...packagePaths],path.join(temp,'optional-local-cache'));install(['--global','--prefix',prefix,...packagePaths],path.join(temp,'optional-global-cache'));
const installed=command(['--identity']);assert.equal(installed.engines.rust.installed,true);assert.equal(installed.engines['wasm-core'].installed,true);
for(const engine of ['rust','wasm-core'])exercise(engine);
for(const engine of ['js','ts','rust','wasm-core'])for(const grammar of ['lean','ps']){
 const source=path.join(consumer,'Global.'+grammar);fs.writeFileSync(source,'def answer : Nat := 42\n');
 const result=JSON.parse(run(globalCli,['generated','build',source,'--engine',engine,'--out',path.join(consumer,'global-'+engine+'-'+grammar)]));assert.deepEqual(result.kernelProviders,['wasm']);assert.equal(run(process.execPath,['--input-type=module','-e','const m=await import('+JSON.stringify(pathToFileURL(result.artifact).href)+');console.log(String(m.answer));']).trim(),'42');globalCases.push({scope:'global',engine,grammar,optionalDiscovery:true});
}
const kernelCases=[];
for(const f of fixtures){const input=path.join(consumer,'admissions.json');fs.writeFileSync(input,f.input);const result=call(cli,['kernel','check',input,'--provider','both']);assert.equal(result.error,undefined);assert.equal(result.status,f.accepted?0:1,result.stderr);const json=JSON.parse(result.stdout);assert.equal(json.accepted,f.accepted);assert.equal(json.agreement,true);kernelCases.push({id:f.id,accepted:f.accepted,agreement:true});}
const moduleFile=path.join(consumer,'api.mjs');
fs.writeFileSync(moduleFile,"import {compile,compileCandidate,createIndependentKernelToolchain} from 'proofscript';\n"+
 "const compiler=await createIndependentKernelToolchain();if(compiler.metadata.provider!=='wasm')throw Error('kernel default');\n"+
 "const records=[];for(const engine of ['js','ts','rust','wasm-core'])for(const target of ['js','ts','rust','wasm-core'])for(const kind of ['lean','ps']){const result=compileCandidate({engine,target,entryModule:'Entry',sources:[{module:'Entry',kind,text:'def answer : Nat := 42\\n'}]});if(result.publicationAuthority!==false||result.logicalAdmission!=='not-run'||result.candidate.status!=='candidate'||result.candidate.target!==target)throw Error('candidate scope');records.push({engine,target,grammar:kind,candidateOnly:true});}\n"+
 "const checked=compile({entryModule:'Entry',sources:[{module:'Entry',kind:'ps',text:'def answer : Nat := 42\\n'}],kernel:'both'});if(checked.logicalAdmission!=='accepted'||checked.kernelProviders.join(',')!=='wasm,native')throw Error('dual compile');console.log(JSON.stringify(records));\n");
candidateCases.push(...JSON.parse(run(process.execPath,[moduleFile])));
const store=path.join(consumer,'local-js-'+corpus[0].id),pointer=fs.readlinkSync(path.join(store,'current')),validProject=path.join(consumer,'local-js-'+corpus[0].id+'.json');
function refused(label,apply,restore){
 try{apply();const r=call(cli,['build','--project',validProject,'--engine','js','--out',store]);assert.notEqual(r.status,0,label);assert.equal(fs.readlinkSync(path.join(store,'current')),pointer);negativeCases.push({id:label,priorPreserved:true});}finally{restore();}
}
const wasmRoot=path.join(root,'node_modules/@proofscript/pskernel-lean-wasm'),wasm=path.join(wasmRoot,'wasm/pskernel-lean.wasm'),wasmBytes=fs.readFileSync(wasm);
refused('corrupt-default-kernel-with-native-installed',()=>{const b=Buffer.from(wasmBytes);b[b.length-1]^=1;fs.writeFileSync(wasm,b);},()=>fs.writeFileSync(wasm,wasmBytes));
refused('missing-default-kernel-with-native-installed',()=>fs.renameSync(wasmRoot,wasmRoot+'.disabled'),()=>fs.renameSync(wasmRoot+'.disabled',wasmRoot));
const manifest=path.join(root,'UNIVERSAL_DISTRIBUTION.json'),manifestBytes=fs.readFileSync(manifest);
refused('manifest-policy-corruption',()=>{const d=JSON.parse(manifestBytes);d.defaultKernel='native';fs.writeFileSync(manifest,JSON.stringify(d));},()=>fs.writeFileSync(manifest,manifestBytes));
const packageFile=path.join(root,'package.json'),packageBytes=fs.readFileSync(packageFile);
refused('missing-root-kernel-policy',()=>{const d=JSON.parse(packageBytes);delete d.proofscript.defaultKernel;fs.writeFileSync(packageFile,JSON.stringify(d));},()=>fs.writeFileSync(packageFile,packageBytes));
for(const phase of ['before-seal','after-seal','before-commit']){const result=call(cli,['build','--project',validProject,'--out',store],{env:{...env,PSC1_TEST_SERVICE_PUBLICATION_FAIL_AT:phase}});assert.notEqual(result.status,0);assert.equal(fs.readlinkSync(path.join(store,'current')),pointer);negativeCases.push({id:phase,priorPreserved:true});}
for(const [engine,key]of [['rust','compiler-rust-linux-x64'],['wasm-core','compiler-wasm']]){
 const dir=path.join(consumer,'node_modules/@proofscript',key),manifest=JSON.parse(fs.readFileSync(path.join(dir,'BUNDLE_MANIFEST.json'),'utf8')),resource=path.join(dir,manifest.files.find(p=>p.path.startsWith('payload/')&&!p.path.endsWith('.json')).path),original=fs.readFileSync(resource);
 try{const changed=Buffer.from(original);changed[changed.length-1]^=1;fs.writeFileSync(resource,changed);const result=call(cli,['build','--project',validProject,'--engine',engine,'--out',store]);assert.notEqual(result.status,0);assert.equal(fs.readlinkSync(path.join(store,'current')),pointer);negativeCases.push({engine,id:'optional-executor-corruption',priorPreserved:true});}finally{fs.writeFileSync(resource,original);}
 const meta=path.join(dir,'package.json'),bytes=fs.readFileSync(meta);
 try{const d=JSON.parse(bytes);d.version='0.0.0-wrong';fs.writeFileSync(meta,JSON.stringify(d));const result=call(cli,['check',main,'--engine',engine]);assert.notEqual(result.status,0);negativeCases.push({engine,id:'optional-executor-version-refusal'});}finally{fs.writeFileSync(meta,bytes);}
}
const receipt={schema:'psc1-slim-universal-installed/1',sourceCommit:process.env.GITHUB_SHA,status:'passed',tarballSha256:assembly.sha256,tarballBytes:assembly.bytes,sizeRatio:assembly.sizeRatio,compilerSourceClosureDigest:metadata.compilerSourceClosureDigest,defaultKernel:'wasm',defaultEngine:'js',cases,globalCases,candidateCases,kernelCases,negativeCases,byteCaptureCases,rootOnlyWithoutOptionalPayloads:true,noCompilerSdkOnExecutionPath:true,offlineEmptyCache:true,installScriptsDisabled:true,optionalBundlesInstalledExplicitly:true,allFourQualifiedPayloadsPreserved:true,linuxPublicationQualified:true,otherPlatformPublicationPolicy:'explicit-runtime-guard; other OS execution not qualified',actualPlatform:'linux-x64',fullCrossPlatformRelease:false,scope:'universal package format and checked compile API, real Linux local/global JS publication; no macOS/Windows release execution claim'};
fs.writeFileSync(path.join(out,'installed-qualification.json'),JSON.stringify(receipt,null,2)+'\n');console.log('PSC1_SLIM_UNIVERSAL_INSTALLED: '+JSON.stringify(receipt));
