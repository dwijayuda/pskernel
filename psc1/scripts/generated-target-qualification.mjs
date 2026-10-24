// Manual Linux qualification. One native seed; generated semantic work thereafter.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {readOwnedCompilerSources} from '../host-tools/compiler-source-inputs.mjs';
import {createCompilerHostSession,compilerSourceClosureDigest} from '../host-tools/compiler-host-protocol.mjs';
import {sha,buildTarget,observeArtifact,verifyArtifact,runTool,boundedRun} from '../host-tools/generated-target-tools.mjs';
import {validateClosureCounts} from './compiler-closure-contract.mjs';
import {corpus,refusals,expectedObservations,observedExpressions,rustObservations,pythonObservations,phpObservations} from './generated-target-corpus.mjs';
import {compilerService,unifiedOutputTargets} from '../host-tools/generated-target-profiles.mjs';
import {qualificationProfile,compilerRequestLimit,PERFORMANCE_PROFILE} from './selfhost-qualification-profiles.mjs';
const [target,mode='--self-host',profileName=PERFORMANCE_PROFILE,serviceKind='single']=process.argv.slice(2);
const definition=compilerService(target,serviceKind);const unified=serviceKind==='unified';assert.ok(['--g1-only','--self-host'].includes(mode));
const profile=qualificationProfile(profileName);
assert.equal(process.version,'v22.23.3');assert.ok(process.env.GITHUB_SHA);
const root=process.cwd(),directory=path.resolve('dist/generated-'+(unified?'unified-':'')+target+'-compiler');
fs.mkdirSync(directory,{recursive:true});
const seed=path.resolve('.lake/build/bin/'+(unified?'psc1_unified_service_seed':'psc1_target_service_seed'));
const checker=path.resolve('.lake/build/bin/psc1_independent_checker');
const runner=path.resolve('scripts/generated-target-runner.mjs');
const inventoryFiles=['scripts/generated-target-qualification.mjs','scripts/generated-target-runner.mjs',
 'scripts/selfhost-qualification-profiles.mjs','scripts/generated-target-corpus.mjs','host-tools/generated-target-tools.mjs',
 'host-tools/compiler-host-protocol.mjs','host-tools/compiler-source-inputs.mjs','host-tools/generated-target-profiles.mjs','host-tools/generated-wasm-transport.mjs','host-tools/generated-python-transport.py','host-tools/generated-php-transport.php','scripts/bounded-process.py','scripts/compiler-closure-contract.mjs'];
const tools=[checker,process.execPath,...inventoryFiles.map(p=>path.resolve(p))].map(file=>({file,sha256:sha(fs.readFileSync(file))}));
if(target==='python'||target==='php'){
 const python=target==='python';
 const binary=runTool(python?'python3':'php',python?['-I','-c','import sys; print(sys.executable)']:['-r','echo PHP_BINARY;']).stdout.trim();
 const file=fs.realpathSync(binary);
 tools.push({file,sha256:sha(fs.readFileSync(file)),role:target+'-interpreter'});
 const version=runTool(python?'python3':'php',python?['--version']:['-r','echo PHP_VERSION;']).stdout.trim();
 assert.equal(version,definition.runtimeVersion,'PSC1_QUALIFICATION_RUNTIME_VERSION');
}
const seedHash=sha(fs.readFileSync(seed));let seedCalls=0;
const events=[],report={schema:'psc1-generated-target-qualification/1',target,mode,serviceKind,outputTargets:unified?unifiedOutputTargets:[target],
 profile,correctnessQualification:'not-qualified',performanceQualification:'not-qualified',
 testedCommit:process.env.GITHUB_SHA,branchHead:process.env.PSC1_BRANCH_HEAD,
 nativeSeedSha256:seedHash,tools,events,status:'running',generations:[],attempts:[],
 fixedPoint:'not-run',productionPublication:'not-run',formalPreservation:'not-provided'};
const checkpoint=()=>fs.writeFileSync(path.join(directory,'qualification.json'),JSON.stringify(report,null,2)+'\n');
const pinned=()=>{
 tools.forEach(t=>assert.equal(sha(fs.readFileSync(t.file)),t.sha256,'PSC1_QUALIFICATION_TOOL_CHANGED'));
 for(const row of report.sourceInventory||[]){
  const bytes=fs.readFileSync(row.path);assert.equal(bytes.length,row.bytes);
  assert.equal(sha(bytes),row.sha256,'PSC1_COMPILER_SOURCE_CHANGED');
 }
};
const entry=definition.entry;
const exportName=definition.exportName;
function request(id,grammar,assurance,entry,sources,outputTarget=target) {
 const captured=sources.map(s=>({module:s.module,kind:grammar,text:s.text}));
 const digest=compilerSourceClosureDigest(captured);
 const inner=JSON.stringify(['psc1-compiler-service/1',id,digest,grammar,assurance,entry,sources.map(s=>[s.module,s.text])]);
 return {id,grammar,assurance,entry,sources:captured,digest,outputTarget,
  text:unified?JSON.stringify(['psc1-unified-compiler-service/1',outputTarget,inner]):inner,inner};
}
function candidateFile(file) {
 const b=fs.readFileSync(file);assert.ok(b.length>0&&b.length<=128*1024*1024);
 return {value:JSON.parse(b),sha256:sha(b)};
}
function checkCandidate(c,r) {
 const v=c.value;
 console.log('PSC1_TARGET_CANDIDATE: '+JSON.stringify({target,id:r.id,status:v.status,phase:v.phase,code:v.code,module:v.module,declaration:v.declaration,line:v.line,column:v.column}));
 assert.equal(v.status,'candidate',JSON.stringify(v));
 assert.deepEqual(Object.keys(v).sort(),['admission','admissionRequest','assurance','candidateOnly','grammar','logicalDeclarations','originalIr','origins','partialNames','protocol','publicNames','requestId','runtimeRequirements','source','sourceClosureDigest','sourceDeclarations','specializedIr','status','target'].sort());
 for(const [k,value] of Object.entries({protocol:'psc1-compiler-service/1',requestId:r.id,
  sourceClosureDigest:r.digest,grammar:r.grammar,assurance:r.assurance,target:r.outputTarget,candidateOnly:true,admission:'not-run'})) assert.equal(v[k],value,k);
 assert.equal(typeof v.source,'string');assert.ok(v.source.length>0);
 assert.ok(Array.isArray(v.publicNames)&&new Set(v.publicNames).size===v.publicNames.length);
 assert.equal(v.origins.length,r.sources.length);let sourceCount=0;
 v.origins.forEach((row,i)=>{
  assert.equal(row.length,4);assert.equal(row[0],r.sources[i].module);assert.equal(row[1],Buffer.byteLength(r.sources[i].text));
  row[3].forEach((origin,j)=>{assert.equal(origin.length,5);assert.equal(origin[0],j);assert.equal(typeof origin[1],'string');
   origin[4].forEach((member,k)=>{assert.equal(member.length,2);assert.equal(member[0],k);assert.equal(typeof member[1],'string');sourceCount++;});
  });
 });
 validateClosureCounts({assurance:r.assurance,sourceCoreDeclarations:v.sourceDeclarations,coreDeclarations:v.logicalDeclarations,partialNames:v.partialNames},sourceCount,r.assurance);
 for(const graph of [v.originalIr,v.specializedIr]){assert.equal(graph.length,5);assert.equal(graph[0],'psc1-ir/1');assert.ok(graph.slice(1).every(Array.isArray));}
 if(r.id==='G1-bootstrap'||r.id.endsWith('-self')){
  const declarations=v.specializedIr[4],stats={request:r.id,declarations:declarations.length,
   genericDeclarations:declarations.filter(d=>d[1].length>0).length,
   genericCurried:declarations.filter(d=>d[1].length>0&&d[3][0]==='function').length};
  (report.targetPlans||=[]).push(stats);checkpoint();
  console.log('PSC1_TARGET_PLAN_PROFILE: '+JSON.stringify(stats));
 }
 pinned();
 const session=createCompilerHostSession({requestId:r.id,target:r.outputTarget,sources:r.sources,
  canonicalAdmissions:v.admissionRequest.admissions,checkerExecutable:checker});
 const receipt=session.admit(JSON.stringify(v.admissionRequest));assert.equal(receipt.accepted,true);
 pinned();
 return {sourceClosureDigest:r.digest,sourceSha256:sha(v.source),admissionsSha256:receipt.admissionsDigest,
  originalIrSha256:sha(JSON.stringify(v.originalIr)),specializedIrSha256:sha(JSON.stringify(v.specializedIr)),
  checkerCommit:receipt.checkerCommit,logicalAdmission:'accepted',publicNames:v.publicNames};
}
function generated(artifact,r,label) {
 pinned();verifyArtifact(artifact.file,artifact.sha256);
 const input=path.join(directory,label+'.request.json'),output=path.join(directory,label+'.candidate.json');
 fs.writeFileSync(input,r.text);
 report.activeRequest={id:r.id,requestSha256:sha(r.text),producer:artifact.sha256};checkpoint();
 const limits=compilerRequestLimit(profileName,r.id);
 console.log('PSC1_TARGET_REQUEST_STARTED: '+JSON.stringify({target,id:r.id,serviceSha256:artifact.sha256,requestSha256:sha(r.text),...limits,at:new Date().toISOString()}));
 const began=Date.now(),result=boundedRun(process.execPath,[runner,artifact.file,artifact.sha256,input,output,profileName],
  {logDirectory:path.join(directory,label+'-process'),...limits});
 const event={role:'generated-compiler',target,id:r.id,serviceSha256:artifact.sha256,
  requestSha256:sha(r.text),...limits,maxRssKiB:result.maxRssKiB,peakTreeRssKiB:result.peakTreeRssKiB,sampledCpuSeconds:result.sampledCpuSeconds,memoryMeasurement:result.memoryMeasurement,elapsedMs:Date.now()-began,status:result.status,signal:result.signal,error:result.error?.message||null};
 events.push(event);checkpoint();
 console.log('PSC1_TARGET_REQUEST_EXECUTION: '+JSON.stringify(event));
 fs.writeFileSync(path.join(directory,label+'.stdout.txt'),result.stdout||'');
 fs.writeFileSync(path.join(directory,label+'.stderr.txt'),result.stderr||'');
 pinned();verifyArtifact(artifact.file,artifact.sha256);assert.equal(sha(fs.readFileSync(input)),sha(r.text));
 assert.ok(!result.error&&result.status===0,'PSC1_GENERATED_TARGET_FAILED:'+JSON.stringify(event)+'\n'+(result.stderr||'').slice(-6000));
 const c=candidateFile(output),execution=JSON.parse(result.stdout.trim());
 assert.equal(execution.protocol,'psc1-generated-target-run/1');
 assert.equal(execution.target,target);assert.equal(execution.serviceSha256,artifact.sha256);
 assert.equal(execution.requestSha256,sha(r.text));assert.equal(execution.responseSha256,c.sha256);
 event.serviceMaxRssKiB=execution.maxRssKiB;
 console.log('PSC1_TARGET_GENERATED_WORKLOAD: '+JSON.stringify(event));
 report.activeRequest=null;checkpoint();
 return c;
}
function exercise(artifact,generation,outputTarget) {
 const target=outputTarget,observations=[];
 const prefix='G'+generation+(unified?'-'+target:'');
 for(const item of corpus) {
  const label=prefix+'-'+item.id,r=request(label,item.grammar,item.assurance,item.entry,item.sources,target);
  const c=generated(artifact,r,label),identity=checkCandidate(c,r);
  const consumer=target==='python'?'print(json.dumps('+pythonObservations[item.id]+',ensure_ascii=False))\n':target==='php'?'echo json_encode('+phpObservations[item.id]+',JSON_THROW_ON_ERROR);\n':target!=='rust'?item.consumer+'\nconsole.log(JSON.stringify('+observedExpressions[item.id]+'));\n':rustObservations[item.id];
  const built=buildTarget({target,source:c.value.source,directory:path.join(directory,label),consumer,publicNames:c.value.publicNames,publicTypes:target==='wasm-core'?c.value.specializedIr[4].filter(d=>c.value.publicNames.includes(d[0])).map(d=>({name:d[0],parameters:d[2].map(p=>p[1]),result:d[3]})):[]});
  const observation=observeArtifact(built);assert.deepEqual(observation.observation,expectedObservations[item.id]);
  observations.push({id:item.id,...identity,observation:observation.observation});
  (report.cases||=[]).push({generation,...observations.at(-1),execution:observation.event});checkpoint();
 }
 for(const item of refusals) {
  const label=prefix+'-'+item.id,r=request(label,item.grammar,item.assurance,'Entry',[{module:'Entry',text:item.source}],target);
  const c=generated(artifact,r,label);assert.equal(c.value.status,'refused');assert.equal(c.value.phase,item.phase);
  assert.equal(c.value.admission,'not-run');assert.equal(c.value.source,undefined);
  observations.push({id:item.id,refused:true,phase:item.phase,code:c.value.code});
  (report.cases||=[]).push({generation,...observations.at(-1)});checkpoint();
 }
 assert.equal(observations.length,10);
 return observations;
}
function exerciseAll(artifact,generation) {
 const rows=(unified?unifiedOutputTargets:[target]).map(outputTarget=>({target:outputTarget,observations:exercise(artifact,generation,outputTarget)}));
 if(unified) {
  for(const [index,input] of ['malformed','null','{}',
    JSON.stringify(['wrong','js','{}']),
    ...['python','php','wasm-component','unknown'].map(t=>JSON.stringify(['psc1-unified-compiler-service/1',t,'{}'])),
    JSON.stringify(['psc1-unified-compiler-service/1','js','{}','extra'])].entries()) {
   const label='G'+generation+'-envelope-'+index;
   const c=generated(artifact,{id:label,text:input},label);
   assert.equal(c.value.status,'refused');assert.equal(c.value.phase,'wire');
   assert.equal(c.value.admission,'not-run');assert.equal(c.value.candidateOnly,true);
   assert.equal(c.value.source,undefined);
   (report.envelopeRefusals||=[]).push({generation,index,code:c.value.code});
  }
 }
 return unified?rows:rows[0].observations;
}
try {
 // Exact portable source ownership, taken from registered roots; no host/compiler executable import.
 const ordered=readOwnedCompilerSources(entry);
 const sources=ordered.map(({module,text})=>({module,text}));
 const sourceInventory=ordered.map(s=>({module:s.module,path:s.path,bytes:Buffer.byteLength(s.text),sha256:sha(s.text)}));
 if(unified)assert.ok(sourceInventory.every(s=>!/^Ps\.Backend(Python|Php)\./.test(s.module)),'PSC1_OPTIONAL_EMITTER_IN_DEFAULT_CLOSURE');
 report.sourceInventory=sourceInventory;report.sourceModules=sources.length;
 const bootstrap=request('G1-bootstrap','lean','ordinary-checked',entry,sources);
 report.sourceClosureDigest=bootstrap.digest;checkpoint();
 const input=path.join(directory,'G1-bootstrap.request.json'),output=path.join(directory,'G1-bootstrap.candidate.json');
 fs.writeFileSync(input,bootstrap.text);if(unified)fs.writeFileSync(input+'.inner',bootstrap.inner);assert.equal(seedCalls,0);
 assert.equal(sha(fs.readFileSync(seed)),seedHash);seedCalls++;
 const seedRun=runTool(seed,[target,unified?input+'.inner':input,output],{logDirectory:directory});events.push({role:'stage0-seed',...seedRun.event});
 assert.equal(sha(fs.readFileSync(seed)),seedHash);assert.equal(sha(fs.readFileSync(input)),sha(bootstrap.text));
 const initial=candidateFile(output),baseline=checkCandidate(initial,bootstrap);
 assert.deepEqual(initial.value.publicNames,[exportName]);
 report.bootstrap=baseline;checkpoint();
 let artifact=buildTarget({target,source:initial.value.source,directory:path.join(directory,'G1-service'),service:true,serviceKind,publicNames:[exportName],publicTypes:target==='wasm-core'?[{name:exportName,parameters:[['primitive','string']],result:['primitive','string']}]:[]});
 const rawExecutable=a=>sha(fs.readFileSync(path.join(path.dirname(a.file),a.manifest.executable)));
 const executableBaseline=rawExecutable(artifact);report.executableSha256=executableBaseline;
 report.serviceArtifact={file:artifact.file,sha256:artifact.sha256,sourceSha256:artifact.manifest.sourceSha256};checkpoint();
 // No native compiler frontend/emitter is available after this sole seed call.
 const disabled=path.resolve('.lake/build/disabled-'+target+'-native-tools');fs.mkdirSync(disabled,{recursive:true});
 for(const n of fs.readdirSync('.lake/build/bin')){
  if(n==='psc1_independent_checker')continue;
  const from=path.resolve('.lake/build/bin',n);if(fs.statSync(from).isFile())fs.renameSync(from,path.join(disabled,n));
 }
 assert.equal(fs.existsSync(seed),false);report.nativeDelegationBoundary='one-seed; native compiler executables removed; generated source semantics only';
 const observations=exerciseAll(artifact,1);
 report.generations.push({generation:1,...baseline,artifactSha256:artifact.sha256,observations});checkpoint();
 for(const generation of (mode==='--self-host'?[2,3]:[])){
  const r=request('G'+generation+'-self','lean','ordinary-checked',entry,sources);
  const attempt={generation,producer:artifact.sha256,startedAt:new Date().toISOString(),status:'running'};report.attempts.push(attempt);checkpoint();
  const c=generated(artifact,r,'G'+generation+'-self'),identity=checkCandidate(c,r);
  for(const k of ['sourceClosureDigest','sourceSha256','admissionsSha256','originalIrSha256','specializedIrSha256'])assert.equal(identity[k],baseline[k],'PSC1_FIXED_POINT_MISMATCH:'+k);
  assert.deepEqual(c.value.publicNames,[exportName]);
  const next=buildTarget({target,source:c.value.source,directory:path.join(directory,'G'+generation+'-service'),service:true,serviceKind,publicNames:[exportName],publicTypes:target==='wasm-core'?[{name:exportName,parameters:[['primitive','string']],result:['primitive','string']}]:[]});
  if(unified)assert.equal(rawExecutable(next),executableBaseline,'PSC1_EXECUTABLE_FIXED_POINT_MISMATCH');
  const actual=exerciseAll(next,generation);assert.deepEqual(actual,observations,'PSC1_GENERATION_CORPUS_CHANGED');
  report.generations.push({generation,...identity,artifactSha256:next.sha256,observations:actual});
  attempt.status='passed';attempt.completedAt=new Date().toISOString();artifact=next;checkpoint();
 }
 assert.equal(seedCalls,1);pinned();
 if(target==='rust')assert.ok(fs.existsSync('scripts/fixtures/selfhost-rust.Cargo.lock'),
  'PSC1_REPRODUCIBILITY_REQUIRES_REVIEWED_RUST_LOCK');
 report.fixedPoint=mode==='--self-host'?(unified?'passed-G1-G2-G3-exact-source-admission-IR-executable-and-four-target-observations':'passed-G1-G2-G3-exact-source-admission-IR-and-ten-case-observations'):'not-requested';
 report.correctnessQualification=mode==='--self-host'?'qualified':'G1-only';
 report.performanceQualification=mode==='--self-host'&&profileName===PERFORMANCE_PROFILE?'qualified-240s':'not-run-in-this-profile';
 report.status='passed';
} catch(error){
 report.status='failed';report.failure=error.message;
 for(const attempt of report.attempts)if(attempt.status==='running'){
  attempt.status='failed';attempt.failure=error.message;attempt.completedAt=new Date().toISOString();
 }
 throw error;
}
finally{
 report.completedAt=new Date().toISOString();
 fs.writeFileSync(path.join(directory,'qualification.json'),JSON.stringify(report,null,2)+'\n');
 console.log('PSC1_GENERATED_TARGET_QUALIFICATION: '+JSON.stringify({target,profile,correctnessQualification:report.correctnessQualification,performanceQualification:report.performanceQualification,status:report.status,sourceModules:report.sourceModules,
  sourceClosureDigest:report.sourceClosureDigest,generations:report.generations.map(g=>g.generation),fixedPoint:report.fixedPoint,failure:report.failure,attempts:report.attempts}));
}
