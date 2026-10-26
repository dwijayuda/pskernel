// Package qualified generated engines with the preserved native core.
// Linux CI only. No registry publication; qualification provenance is per engine.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';import {pathToFileURL} from 'node:url';
import {sha,verifyArtifact} from '../host-tools/generated-target-tools.mjs';
import {compilerSourceClosureDigest} from '../host-tools/compiler-host-protocol.mjs';
import {corpus,observedExpressions,expectedObservations,refusals} from './generated-target-corpus.mjs';
const [nativeTarball,...qfiles]=process.argv.slice(2);
assert.equal(qfiles.length,4);
const root=process.cwd(),out=path.resolve('dist/npm-generated');fs.mkdirSync(out,{recursive:true});
const work=fs.mkdtempSync(path.join(out,'run-')),stage=path.join(work,'package');
const run=(exe,args,options={})=>{const r=spawnSync(exe,args,{encoding:'utf8',timeout:240000,maxBuffer:32*1024*1024,...options});if(r.error||r.status!==0)throw Error('PSC1_GENERATED_PACKAGE_PROCESS: '+exe+' '+args.join(' ')+'\n'+(r.error||'')+r.stdout+r.stderr);return r.stdout;};
const write=(p,b)=>{fs.mkdirSync(path.dirname(p),{recursive:true});fs.writeFileSync(p,b);};
const copy=(a,b)=>{fs.mkdirSync(path.dirname(b),{recursive:true});fs.cpSync(a,b,{recursive:true,dereference:false});};
run('tar',['xzf',path.resolve(nativeTarball),'-C',work]);
const meta=JSON.parse(fs.readFileSync(path.join(stage,'package.json')));
assert.equal(meta.name,'proofscript');assert.equal(meta.version,'0.1.0-psc1.3');assert.equal(meta.proofscript.sourceKind,'native-lean');
const nativeDistribution=JSON.parse(fs.readFileSync(path.join(stage,'NATIVE_DISTRIBUTION.json')));
assert.equal(nativeDistribution.publicationStatus,'unpublished');
assert.equal(nativeDistribution.nativeSha256,sha(fs.readFileSync(path.join(stage,'native/bin/psc1'))));
const checkerCommit='eb6cafb7290e8bd5f2937522d8d804f58f02bafc';
assert.equal(nativeDistribution.compilerIdentity.leanCommit,checkerCommit);
const pins={
  "js": {
    "commit": "0cabb7edef8fbce76d966487fcf37ac030dc2e3b",
    "closure": "07eedac1888aad3d4192664cea8d21a515d23985f3befd6cb365d0194fee53af",
    "manifest": "e5f958b82f9d7b3ed9bf3c7d81abf568b8cad7772a2f0666b9834200e3426141",
    "executable": "b1325b31ddabb01a46db04f0790b6fcf248e3643d6a7d6ad8fbdb809f7723635"
  },
  "ts": {
    "commit": "0cabb7edef8fbce76d966487fcf37ac030dc2e3b",
    "closure": "07eedac1888aad3d4192664cea8d21a515d23985f3befd6cb365d0194fee53af",
    "manifest": "2484bb3543a52645fc1fc56e9c754b6f54547337c6fedfe2df19ac739a97c269",
    "executable": "136445a23a4968abee73f6c898b4bfc8607c20544627320af98acfe73310504a"
  },
  "rust": {
    "commit": "2d27f1428e6a53a6de5006f950fc94f2d471b214",
    "closure": "07eedac1888aad3d4192664cea8d21a515d23985f3befd6cb365d0194fee53af",
    "manifest": "33a22e78a1e119870553b30ad4475ac54f1d3469cb8ed9ca49d5ff77e131802a",
    "executable": "07f58b1f083da6f0757fdffd4866ae16535d193065cf95d9c56443b5548636d6"
  },
  "wasm-core": {
    "commit": "0cabb7edef8fbce76d966487fcf37ac030dc2e3b",
    "closure": "07eedac1888aad3d4192664cea8d21a515d23985f3befd6cb365d0194fee53af",
    "manifest": "332be1a1d4324241264ba996842b6d4d1b8e6cce524562441a4f63fdd16be3c9",
    "executable": "6c0af1dc0023fc0e97b1ad50f2fe6028e0506ca69661e3def1bcb03796e7ab9d"
  }
};
const filePin=relative=>({path:relative,sha256:sha(fs.readFileSync(path.join(stage,relative)))});
const engines={};
for(const qfile of qfiles){
 const q=JSON.parse(fs.readFileSync(qfile)),dir=path.dirname(qfile),engine=q.target;
 assert.ok(Object.hasOwn(pins,engine)&&!engines[engine]);
 assert.equal(q.schema,'psc1-generated-target-qualification/1');assert.equal(q.testedCommit,pins[engine].commit);
 assert.equal(q.serviceKind,'unified');assert.equal(q.status,'passed');assert.equal(q.correctnessQualification,'qualified');
 assert.equal(q.mode,'--self-host');assert.equal(q.sourceClosureDigest,pins[engine].closure);
 assert.equal(q.fixedPoint,'passed-G1-G2-G3-exact-source-admission-IR-executable-and-four-target-observations');
 assert.equal(q.generations.length,3);assert.equal(q.cases.length,120);assert.equal(q.envelopeRefusals.length,27);
 assert.deepEqual(q.outputTargets,['js','ts','rust','wasm-core']);
 assert.equal(q.nativeDelegationBoundary,'one-seed; native compiler executables removed; generated source semantics only');
 const wire=JSON.parse(fs.readFileSync(path.join(dir,'G1-bootstrap.request.json')));
 assert.equal(wire[0],'psc1-unified-compiler-service/2');assert.equal(wire[1],engine);
 const sources=wire[2][6].map(([module,text])=>({module,text,kind:'lean'}));
 assert.equal(compilerSourceClosureDigest(sources),q.sourceClosureDigest);
 assert.equal(sources.length,q.sourceModules);assert.equal(q.sourceInventory.length,sources.length);
 q.sourceInventory.forEach((r,i)=>{assert.equal(r.module,sources[i].module);assert.equal(r.sha256,sha(sources[i].text));assert.equal(r.bytes,Buffer.byteLength(sources[i].text));});
 for(const [i,g]of q.generations.entries()){
  assert.equal(g.generation,i+1);assert.equal(g.logicalAdmission,'accepted');assert.equal(g.checkerCommit,checkerCommit);
  for(const field of ['sourceClosureDigest','sourceSha256','admissionsSha256','originalIrSha256','specializedIrSha256'])
   assert.equal(g[field],q.bootstrap[field]);
  assert.deepEqual(g.observations,q.generations[0].observations);
  const m=verifyArtifact(path.join(dir,'G'+(i+1)+'-service/artifact.json'),g.artifactSha256);
  assert.equal(sha(fs.readFileSync(path.join(m.directory,m.executable))),pins[engine].executable);
  assert.equal(m.serviceKind,'unified');assert.equal(m.service,true);
 }
 const g=q.generations[2];assert.equal(g.artifactSha256,pins[engine].manifest);
 const manifest=path.join(dir,'G3-service/artifact.json'),m=verifyArtifact(manifest,pins[engine].manifest);
 const prefix='selfhost/'+engine;copy(manifest,path.join(stage,prefix,'artifact.json'));
 for(const row of m.files)copy(path.join(m.directory,row.path),path.join(stage,prefix,row.path));
 const adapter=(engine==='ts'||engine==='js')
  ? "import {psCompilerServiceCandidate} from './module.js';\n"
  : engine==='wasm-core'
  ? "import {loadWasmArtifact} from '../../host-tools/generated-wasm-transport.mjs';\nimport {fileURLToPath} from 'node:url';\nconst {psCompilerServiceCandidate}=loadWasmArtifact(fileURLToPath(new URL('./artifact.json',import.meta.url)));\n"
  : "import {runGeneratedRustCompiler} from '../../host-tools/generated-rust-transport.mjs';\nimport {fileURLToPath} from 'node:url';\n";
 if(engine==='rust')fs.chmodSync(path.join(stage,prefix,m.executable),0o755);
 const adapterRequestExpression="JSON.stringify(['psc1-unified-compiler-service/2','js',JSON.parse(request)])";
 const invocation=engine==='rust'
  ? "runGeneratedRustCompiler({executable:fileURLToPath(new URL('./"+m.executable+"',import.meta.url)),executableSha256:'"+pins[engine].executable+"',request:"+adapterRequestExpression+"})"
  : "psCompilerServiceCandidate("+adapterRequestExpression+")";
 write(path.join(stage,prefix,'adapter.mjs'),adapter+
  "export function psCompilerJsServiceCandidate(request){return "+invocation+";}\n");
 write(path.join(stage,prefix,'qualification.json'),fs.readFileSync(qfile));
 engines[engine]={sourceClosureDigest:q.sourceClosureDigest,qualifiedCommit:q.testedCommit,
  qualification:q.correctnessQualification,fixedPoint:q.fixedPoint,performanceQualification:q.performanceQualification,
  executableSha256:pins[engine].executable,adapter:filePin(prefix+'/adapter.mjs'),
  dependencies:['artifact.json',...m.files.map(r=>r.path),'qualification.json'].map(p=>filePin(prefix+'/'+p))};
}
for(const file of ['host-tools/contracts/compiler-closure.mjs','host-tools/process/resource-profiles.mjs','host-tools/process/bounded-process.py','host-tools/execution/generated-service-runner.mjs',
 'scripts/compiler-closure-contract.mjs','scripts/generated-compiler-runner.mjs','scripts/selfhost-qualification-profiles.mjs','scripts/bounded-process.py',
 'host-tools/generated-rust-transport.mjs','host-tools/generated-rust-guard.mjs','host-tools/generated-compiler-session.mjs','host-tools/compiler-host-protocol.mjs','host-tools/generated-wasm-transport.mjs','host-tools/generated-target-profiles.mjs'])
 copy(path.join(root,file),path.join(stage,file));
for(const file of ['npm-cli/generated.mjs','npm-cli/generated-entry.mjs'])copy(path.join(root,file),path.join(stage,file));
copy(path.join(root,'.lake/build/bin/psc1_independent_checker'),path.join(stage,'native/bin/psc1_independent_checker'));
fs.chmodSync(path.join(stage,'native/bin/psc1_independent_checker'),0o755);
const distribution={schema:'psc1-installed-generated-engines/1',packageBuildCommit:process.env.GITHUB_SHA,
 nativeCoreSourceCommit:nativeDistribution.sourceCommit,checkerCommit,engines,
 checker:filePin('native/bin/psc1_independent_checker'),runner:filePin('host-tools/execution/generated-service-runner.mjs'),
 session:filePin('host-tools/generated-compiler-session.mjs'),
 hostDependencies:['host-tools/contracts/compiler-closure.mjs','host-tools/process/resource-profiles.mjs','host-tools/process/bounded-process.py','host-tools/execution/generated-service-runner.mjs','host-tools/generated-rust-transport.mjs','host-tools/generated-rust-guard.mjs','host-tools/compiler-host-protocol.mjs','scripts/compiler-closure-contract.mjs','host-tools/generated-wasm-transport.mjs'].map(filePin),
 nativeLibraries:nativeDistribution.bundledNativeLibraries.map(r=>filePin('native/lib/'+r.name)),
 generatedPublicationTargets:['js'],nativeOutputTargets:nativeDistribution.builtInTargets,
 unavailableGeneratedEngines:{},sharedSourceClosureDigest:"07eedac1888aad3d4192664cea8d21a515d23985f3befd6cb365d0194fee53af",allFourEngineSelfHostQualified:true,
 allFourEngineReleaseQualified:false,publication:'unpublished'};
write(path.join(stage,'SELFHOST_DISTRIBUTION.json'),JSON.stringify(distribution,null,2)+'\n');
meta.bin={psc:'./npm-cli/generated-entry.mjs',psc1:'./npm-cli/generated-entry.mjs'};
fs.chmodSync(path.join(stage,'npm-cli/generated-entry.mjs'),0o755);
meta.files.push('selfhost/','scripts/','SELFHOST_DISTRIBUTION.json');
meta.proofscript.generatedEngines=Object.keys(engines);meta.proofscript.generatedPublicationTargets=['js'];
meta.proofscript.allFourEngineReleaseQualified=false;meta.proofscript.allFourEngineSelfHostQualified=true;meta.proofscript.sharedSourceClosureDigest="07eedac1888aad3d4192664cea8d21a515d23985f3befd6cb365d0194fee53af";
write(path.join(stage,'package.json'),JSON.stringify(meta,null,2)+'\n');
fs.appendFileSync(path.join(stage,'README.md'),'\nQualified generated JS/TS/Rust/Wasm engines: psc generated --identity.\n'+
 'Compile one source file: psc generated build Main.ps --engine ts --out dist/generated.\n'+
 'For modules use --project project.json with entryModule and ordered sources [{module,kind,text}].\n'+
 'The result lives at dist/generated/current/target.mjs after official independent Lean4.35 admission and JS syntax/API checks.\n'+
 'This explicit generated path currently publishes JS; psc build retains all five native core targets and matching optional Python/PHP providers.\n'+
 'Generated execution requires Node22.23.3. Engine qualifications retain their recorded source identities. All four engines use the frozen shared source root.\n');
const tarballs=path.join(work,'tarballs');fs.mkdirSync(tarballs);
const packed=JSON.parse(run('npm',['pack',stage,'--pack-destination',tarballs,'--ignore-scripts','--json']));
const tarball=path.join(tarballs,packed[0].filename),consumer=path.join(work,'consumer'),cache=path.join(work,'cache');
write(path.join(consumer,'package.json'),JSON.stringify({name:'psc1-generated-installed-canary',private:true,type:'module'}));
run('npm',['install','--prefix',consumer,'--cache',cache,'--offline','--ignore-scripts','--no-audit','--no-fund',tarball]);
const installed=path.join(consumer,'node_modules/proofscript'),cli=path.join(installed,'npm-cli/generated-entry.mjs');
const command=args=>run(process.execPath,[cli,...args],{cwd:consumer});
assert.equal(JSON.parse(command(['--identity'])).leanCommit,checkerCommit);
assert.deepEqual(JSON.parse(command(['generated','--identity'])),distribution);
assert.deepEqual(JSON.parse(run(path.join(consumer,'node_modules/.bin/psc'),['generated','--identity'],{cwd:consumer})),distribution);
// Generated compilation must keep working with the native compiler unavailable.
fs.renameSync(path.join(installed,'native/bin/psc1'),path.join(installed,'native/bin/psc1.disabled'));
const cases=[];
for(const engine of Object.keys(engines)){
 for(const item of corpus){
  const project=path.join(consumer,engine+'-'+item.id+'.json'),store=path.join(consumer,engine+'-'+item.id);
  write(project,JSON.stringify({entryModule:item.entry,assurance:item.assurance,sources:item.sources.map(s=>({...s,kind:item.grammar}))}));
  const result=JSON.parse(command(['generated','build','--project',project,'--engine',engine,'--out',store]));
  assert.equal(result.logicalAdmission,'accepted');assert.equal(result.checkerCommit,checkerCommit);
  assert.equal(result.engineSourceClosureDigest,engines[engine].sourceClosureDigest);
  const observe=path.join(consumer,'observe.mjs');write(observe,"import * as m from "+JSON.stringify(pathToFileURL(result.artifact).href)+";\n"+item.consumer+"\nconsole.log(JSON.stringify("+observedExpressions[item.id]+"));\n");
  assert.deepEqual(JSON.parse(run(process.execPath,[observe])),expectedObservations[item.id]);
  cases.push({engine,id:item.id,grammar:item.grammar,passed:true,compilerExecutionMs:result.compilerExecutionMs,manifestSha256:result.manifestSha256});
 }
 // A refused program must leave an existing accepted generation unchanged.
 const prior=path.join(consumer,engine+'-'+corpus[0].id),pointer=fs.readlinkSync(path.join(prior,'current'));
 for(const item of refusals){
  const file=path.join(consumer,'bad.json');write(file,JSON.stringify({entryModule:'Entry',assurance:item.assurance,sources:[{module:'Entry',kind:item.grammar,text:item.source}]}));
  const r=spawnSync(process.execPath,[cli,'generated','build','--project',file,'--engine',engine,'--out',prior],{encoding:'utf8',timeout:240000});
  assert.notEqual(r.status,0);assert.equal(fs.readlinkSync(path.join(prior,'current')),pointer);
 }
 const asset=path.join(installed,engines[engine].dependencies.find(r=>r.path.endsWith('/artifact.json')).path),bytes=fs.readFileSync(asset);
 fs.appendFileSync(asset,' ');const r=spawnSync(process.execPath,[cli,'generated','build','--project',path.join(consumer,engine+'-'+corpus[0].id+'.json'),'--engine',engine,'--out',prior],{encoding:'utf8',timeout:240000});
 assert.notEqual(r.status,0);assert.match(r.stderr,/IDENTITY_CHANGED/);assert.equal(fs.readlinkSync(path.join(prior,'current')),pointer);fs.writeFileSync(asset,bytes);
}
// Real application source modules exercise both grammars through installed engines.
// Imported transport and invalid UTF8 must refuse without changing a generation.
const shared=distribution.hostDependencies.find(r=>r.path.endsWith('generated-wasm-transport.mjs'));
const sharedFile=path.join(installed,shared.path),sharedBytes=fs.readFileSync(sharedFile);
{
 const prior=path.join(consumer,'wasm-core-'+corpus[0].id),pointer=fs.readlinkSync(path.join(prior,'current'));
 fs.appendFileSync(sharedFile,' ');
 const bad=spawnSync(process.execPath,[cli,'generated','build','--project',path.join(consumer,'wasm-core-'+corpus[0].id+'.json'),'--engine','wasm-core','--out',prior],{encoding:'utf8',timeout:240000});
 assert.notEqual(bad.status,0);assert.match(bad.stderr,/IDENTITY_CHANGED/);assert.equal(fs.readlinkSync(path.join(prior,'current')),pointer);
 fs.writeFileSync(sharedFile,sharedBytes);
 const invalid=path.join(consumer,'Invalid.ps');write(invalid,Buffer.from([0xff]));
 const failed=spawnSync(process.execPath,[cli,'generated','build',invalid,'--engine','ts','--out',prior],{encoding:'utf8',timeout:240000});
 assert.notEqual(failed.status,0);assert.equal(fs.readlinkSync(path.join(prior,'current')),pointer);
}
const applicationCases=[];
const canonicalPs=new Map();
{
 // Standard library .ps is derived by the existing owned translator, exactly as
 // normal native package resolution and compiler source census already do.
 const ordered=[],seen=new Set();
 function visit(module){
  if(seen.has(module))return;
  const file=path.join(root,'stdlib',...module.split('.'))+'.lean',text=fs.readFileSync(file,'utf8');
  for(const m of text.matchAll(/^import\s+(.+)$/gm))for(const dep of m[1].trim().split(/\s+/))visit(dep);
  seen.add(module);ordered.push({module,file});
 }
 visit('ProofScript.System.IO');
 const report=path.join(work,'stdlib-ps-census.json');
 run(path.join(root,'.lake/build/bin/psc1_source_census_probe'),['--grammar','ps','--out',report,'--modules',...ordered.flatMap(x=>[x.module,x.file])]);
 const q=JSON.parse(fs.readFileSync(report));
 for(const r of q.records){assert.equal(r.translation,'accepted');assert.equal(r.parse,'accepted');assert.equal(r.elaboration,'accepted');assert.equal(typeof r.inputSource,'string');canonicalPs.set(r.module,r.inputSource);}
}

function applicationSources(grammar,entryModule,entryText){
 const ordered=[],seen=new Set(),active=new Set();
 function visit(module,text){
  if(seen.has(module))return;assert.ok(!active.has(module),'application import cycle');active.add(module);
  const file=module.startsWith('ProofScript.')?path.join(root,'stdlib',...module.split('.'))+'.'+grammar
   :path.join(root,'test/applications',...module.split('.'))+'.'+grammar;
  const source=text===undefined?(grammar==='ps'&&module.startsWith('ProofScript.')?canonicalPs.get(module):fs.readFileSync(file,'utf8')):text;assert.equal(typeof source,'string');
  for(const m of source.matchAll(/^import\s+(.+)$/gm))for(const name of m[1].trim().split(/\s+/))visit(name);
  active.delete(module);seen.add(module);ordered.push({module,kind:grammar,text:source});
 }
 visit(entryModule,entryText);return ordered;
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
  for(const engine of Object.keys(engines)){
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
 for(const engine of Object.keys(engines)){
  const result=JSON.parse(command(['generated','build',filename,'--engine',engine,'--out',path.join(consumer,engine+'-single-'+grammar)]));
  const observe=path.join(consumer,'single-observe.mjs');write(observe,"import * as m from "+JSON.stringify(pathToFileURL(result.artifact).href)+";\nif(m.answer!==42n)throw Error('single file');\n");
  run(process.execPath,[observe]);applicationCases.push({engine,grammar,app:'single-file',observations:1,compilerExecutionMs:result.compilerExecutionMs,passed:true});
 }
}
fs.renameSync(path.join(installed,'native/bin/psc1.disabled'),path.join(installed,'native/bin/psc1'));
assert.equal(JSON.parse(command(['--identity'])).leanCommit,checkerCommit);
const receipt={schema:'psc1-generated-package-qualification/1',status:'passed',testedCommit:process.env.GITHUB_SHA,
 nativeInputTarballSha256:sha(fs.readFileSync(nativeTarball)),distribution,cases,applicationCases,negativeCases:Object.keys(engines).length*(refusals.length+1)+2,
 nativeCompilerUnavailableDuringGeneratedCases:true,offlineInstall:true,tarball:path.relative(root,tarball),
 tarballSha256:sha(fs.readFileSync(tarball)),bytes:fs.statSync(tarball).size,
 scope:'All four JS/TS/Rust/Wasm engines qualified on the same frozen source and integrated for independently admitted JS publication. Other generated publication targets, clean full-generation replay and final release remain separate.'};
write(path.join(out,'qualification.json'),JSON.stringify(receipt,null,2)+'\n');
for(const p of [stage,consumer,cache])fs.rmSync(p,{recursive:true,force:true});
console.log('PSC1_GENERATED_PACKAGE_QUALIFICATION: '+JSON.stringify(receipt));
