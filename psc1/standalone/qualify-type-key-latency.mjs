// CI-only measured source optimization; ordinary host, worker and acceptance policy stay unchanged.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import crypto from 'node:crypto';
import { spawn } from 'node:child_process';
import { pathToFileURL } from 'node:url';
const sha=x=>crypto.createHash('sha256').update(x).digest('hex');
const json=x=>JSON.stringify(x,null,2)+'\n';
const MAX=128*1024*1024, LOG_MAX=32*1024*1024;
const P={
  toolchain:'04eb0bb66b4e3ac04850843af40546c3677f31782d73d39de4b6191927692cf2',
  source:'9d0f097e79eb2b1e14d10362c6db9b4bc2370c26627658017bf6b2681b46fabf',
  compiler:'858c188024f0a7da221e0c26053437b3fac3fc0ab1cc9d14092df19b39d1465d',
  candidate:'532081726b246297e30fd0a0975f95a6198510e295338a2bcfbe74ed602c4978',
  request:'4206adb1eb0f795cd09401136f45e638a1298cf8f6c801e30a639c0eccd6180a',
  admissions:'904cdaf4b2e57b2e1b4d3205928a14dd44676e74468e952c29e73847ec245de1',
  originalIr:'13fc0f2fbd65d421257e6df901a9a3afa1b74bf0472292de27549f6214a03b50',
  specializedIr:'a1a377f537848666837c74d0bffd4604718812d59a0d7bcb56586bf7936771c8',
  selectedSource:'feeaf5c7a44f54be247492ff30ee27df628fa6ea32be7a8506224064bcc025b2',
  lean:'eb6cafb7290e8bd5f2937522d8d804f58f02bafc',
};
const files=['admissions.json','build.json','candidate.json','compiler.mjs','original-ir.json','sources.json','specialized-ir.json'];
function read(file,limit=MAX){
  const s=fs.lstatSync(file);assert.ok(s.isFile()&&!s.isSymbolicLink()&&s.size<=limit,file);
  const b=fs.readFileSync(file);assert.equal(b.length,s.size);return b;
}
const decode=b=>new TextDecoder('utf-8',{fatal:true,ignoreBOM:true}).decode(b);
function relative(value){
  assert.ok(typeof value==='string'&&value&&!path.isAbsolute(value)&&!value.includes('\\')&&!value.includes('\0'));
  assert.ok(value.split('/').every(x=>x&&x!=='.'&&x!=='..'));return value;
}
function contained(base,value){
  let current=base;for(const part of relative(value).split('/')){current=path.join(current,part);assert.ok(!fs.lstatSync(current).isSymbolicLink());}return current;
}
function cleanEnv(){
  const env={...process.env};for(const key of Object.keys(env))if(/^(NODE_|BUN_|NPM_|npm_|RUST|CARGO|DYLD_|LD_|PYTHON|LEAN_|ELAN_|PSC1_)/.test(key)||['ENV','BASH_ENV','OPENSSL_CONF','OPENSSL_MODULES','GH_TOKEN','GITHUB_TOKEN'].includes(key))delete env[key];return env;
}
function pidIdentity(pid){try{const s=fs.readFileSync('/proc/'+pid+'/stat','utf8');return s.slice(s.lastIndexOf(')')+2).split(' ')[19];}catch{return null;}}
const opts={};for(let args=process.argv.slice(2);args.length;){const k=args.shift(),v=args.shift();assert.ok(['--toolchain','--baseline','--out'].includes(k)&&v&&!opts[k]);opts[k]=path.resolve(v);}assert.equal(Object.keys(opts).length,3);
const root=opts['--toolchain'],baseline=opts['--baseline'],out=opts['--out'];
assert.equal(process.platform,'linux');assert.ok(!fs.lstatSync(out,{throwIfNoEntry:false}),'output must be new');fs.mkdirSync(path.dirname(out),{recursive:true});fs.mkdirSync(out,{mode:0o700});
const save=(name,value)=>fs.writeFileSync(path.join(out,name),json(value),{flag:'wx',mode:0o600});
let phase='inputs';
async function hostBuild(label,project,destination,selected){
  const args=['--max-old-space-size=4096',path.join(root,'standalone/host.mjs'),'build',project,'--out',destination,'--profile','correctness-3600s',...(selected?['--compiler',selected]:[])];
  const started=Date.now(),child=spawn(path.join(root,'libexec/psc-runtime'),args,{cwd:out,env:cleanEnv(),stdio:['ignore','pipe','pipe']});
  const identity=child.pid?pidIdentity(child.pid):null;
  let failure=null,escalation;
  const chunks={stdout:[],stderr:[]},sizes={stdout:0,stderr:0};
  const signal=sig=>{if(!child.pid)return;const current=pidIdentity(child.pid);if(identity&&current&&identity!==current)return;try{child.kill(sig);}catch(e){if(e.code!=='ESRCH')throw e;}};
  const stop=reason=>{failure||=reason;signal('SIGTERM');escalation??=setTimeout(()=>signal('SIGKILL'),2500);};
  for(const key of ['stdout','stderr'])child[key].on('data',chunk=>{const take=Math.min(chunk.length,Math.max(0,LOG_MAX-sizes[key]));if(take)chunks[key].push(chunk.subarray(0,take));sizes[key]+=take;if(key==='stderr'&&take)process.stderr.write(chunk.subarray(0,take));if(take!==chunk.length)stop('host log limit');});
  const listeners=new Map();for(const sig of ['SIGINT','SIGTERM','SIGHUP']){const f=()=>stop('parent signal '+sig);listeners.set(sig,f);process.on(sig,f);}
  const timer=setTimeout(()=>stop('outer host deadline'),3900000);
  const heartbeat=setInterval(()=>console.log('PSC1_TYPE_KEY_BUILD_HEARTBEAT: '+JSON.stringify({label,elapsedMs:Date.now()-started})),60000);
  console.log('PSC1_TYPE_KEY_BUILD: '+JSON.stringify({label,phase:'started',selected:selected||'pinned bootstrap',workerTimeoutMs:3600000}));
  try{
    const result=await new Promise(resolve=>{child.once('error',e=>{failure='spawn: '+e.message;resolve({code:null});});child.once('close',(code,signal)=>resolve({code,signal}));});
    const stdout=Buffer.concat(chunks.stdout),stderr=Buffer.concat(chunks.stderr);
    fs.writeFileSync(path.join(out,label+'-stdout.log'),stdout,{flag:'wx'});fs.writeFileSync(path.join(out,label+'-stderr.log'),stderr,{flag:'wx'});
    assert.equal(failure,null,failure||'host failure');assert.equal(result.code,0,stderr.toString('utf8').slice(-8192));
    const receipt=JSON.parse(decode(stdout));assert.equal(receipt.checked,true);assert.equal(receipt.output,destination);
    console.log('PSC1_TYPE_KEY_BUILD: '+JSON.stringify({label,phase:'passed',processElapsedMs:Date.now()-started,execution:receipt.execution,identities:receipt.identities,checker:receipt.checker}));
    return receipt;
  }finally{clearTimeout(timer);clearInterval(heartbeat);if(escalation)clearTimeout(escalation);for(const[sig,f]of listeners)process.removeListener(sig,f);}
}
function manifestVerifier(directory){
  const bytes=read(path.join(directory,'files.json'),1024*1024),m=JSON.parse(decode(bytes));
  assert.equal(m.schema,'psc1-independent-files/1');assert.deepEqual(m.files.map(x=>x.path).sort(),files);
  return ()=>{assert.equal(sha(read(path.join(directory,'files.json'),1024*1024)),sha(bytes));for(const row of m.files){const b=read(contained(directory,row.path));assert.equal(b.length,row.bytes);assert.equal(sha(b),row.sha256);}};
}
function verifyBuild(directory,returned,expectedSources,sourceDigest,producer,checkerSha){
  const verify=manifestVerifier(directory);verify();const b=JSON.parse(decode(read(path.join(directory,'build.json'))));
  const {output,checked,...reported}=returned;assert.deepEqual(b,reported);
  assert.equal(b.schema,'psc1-independent-build/1');assert.equal(b.assurance,'ordinary-checked');assert.equal(b.grammar,'ps');assert.equal(b.target,'js');assert.equal(b.profile,'correctness-3600s');
  assert.equal(b.toolchainSha256,P.toolchain);assert.match(b.checker.admissionReceiptSha256,/^[a-f0-9]{64}$/);
  assert.equal(b.sourceModules,125);assert.deepEqual(b.publicNames,['psCompilerServiceCandidate']);assert.equal(b.identities.sourceClosureDigest,sourceDigest);assert.deepEqual(JSON.parse(decode(read(path.join(directory,'sources.json')))),expectedSources);
  for(const[key,file]of Object.entries({sourceSha256:'compiler.mjs',admissionsSha256:'admissions.json',originalIrSha256:'original-ir.json',specializedIrSha256:'specialized-ir.json'}))assert.equal(b.identities[key],sha(read(path.join(directory,file))));
  assert.equal(b.execution.compilerSha256,producer);assert.equal(b.producer.sha256,producer);assert.equal(b.execution.timeoutMs,3600000);assert.equal(b.execution.responseSha256,sha(read(path.join(directory,'candidate.json'))));
  assert.equal(b.checker.executed,true);assert.equal(b.checker.accepted,true);assert.equal(b.checker.sha256,checkerSha);assert.equal(b.checker.leanCommit,P.lean);assert.equal(b.checker.admissionsSha256,b.identities.admissionsSha256);
  assert.equal(b.authority.actualIndependentAdmission,true);assert.equal(b.authority.sourceAndIrChecks,'generated strict original and transformed IR validation');
  assert.equal(b.api.compilerSha256,b.identities.sourceSha256);assert.equal(b.api.operation,'inspect');assert.equal(b.api.timeoutMs,240000);
  return {receipt:b,verify};
}

try{
  const manifestFile=path.join(root,'toolchain.json'),manifestBytes=read(manifestFile,4*1024*1024);assert.equal(sha(manifestBytes),P.toolchain);const manifest=JSON.parse(decode(manifestBytes));
  const verifyToolchain=()=>{assert.equal(sha(read(manifestFile,4*1024*1024)),P.toolchain);for(const row of manifest.resources){const b=read(contained(root,row.path),512*1024*1024);assert.equal(b.length,row.bytes);assert.equal(sha(b),row.sha256);}};
  verifyToolchain();const verifyBaseline=manifestVerifier(baseline);verifyBaseline();
  for(const[file,pin]of Object.entries({'compiler.mjs':P.compiler,'candidate.json':P.candidate,'admissions.json':P.admissions,'original-ir.json':P.originalIr,'specialized-ir.json':P.specializedIr}))assert.equal(sha(read(path.join(baseline,file))),pin);
  const projectFile=path.join(root,'compiler/project.json'),projectBytes=read(projectFile,1024*1024),project=JSON.parse(decode(projectBytes));
  assert.equal(project.entryModule,'Ps.CompilerUnified.Service');assert.equal(project.sources.length,125);
  const captured=project.sources.map(row=>{assert.ok(row.path.endsWith('.ps'));const file=contained(path.dirname(projectFile),row.path),bytes=read(file,1024*1024);return {...row,file,bytes,sha256:sha(bytes),text:decode(bytes)};});
  const oldSources=captured.map(x=>({module:x.module,kind:'ps',text:x.text}));assert.equal(captured.reduce((n,x)=>n+x.bytes.length,0),2382708);assert.deepEqual(oldSources,JSON.parse(decode(read(path.join(baseline,'sources.json')))));
  const helpers=await import(pathToFileURL(path.join(root,'host-tools/compiler-host-protocol.mjs')).href);assert.equal(helpers.compilerSourceClosureDigest(oldSources),P.source);
  const verifyInputs=()=>{verifyToolchain();verifyBaseline();assert.equal(sha(read(projectFile,1024*1024)),sha(projectBytes));for(const row of captured)assert.equal(sha(read(row.file,1024*1024)),row.sha256);};
  phase='observe and patch the pinned canonical PS definition';
  const selected=captured.filter(x=>x.module==='Ps.CompilerIr.Specialize');assert.equal(selected.length,1);const source=selected[0];assert.equal(source.bytes.length,60198);assert.equal(source.sha256,P.selectedSource);
  const start=source.text.indexOf('def psIrSpecializeTypeKeyWithFuel('),end=source.text.indexOf('\ndef psIrSpecializeTypeKey(',start);assert.ok(start>=0&&end>start&&end-start<16384);
  const beforeDefinition=source.text.slice(start,end);console.log('PSC1_TYPE_KEY_SOURCE_BEFORE: '+JSON.stringify({module:source.module,path:source.path,bytes:source.bytes.length,sha256:source.sha256,definition:beforeDefinition}));
  const pattern=/let smaller : ([^\r\n]+) := \(psIrSpecializeTypeKeyWithFuel\(remaining\)\)\n(fun \(type : PsVerifiedIrType\) => )/g;
  const matches=[...beforeDefinition.matchAll(pattern)];assert.equal(matches.length,1,'exact qualified PS let/lambda anchor');
  const before=matches[0][0],letLine=before.slice(0,before.indexOf('\n')),after=matches[0][2]+letLine+'\n';
  const afterDefinition=beforeDefinition.replace(before,after),changedText=source.text.slice(0,start)+afterDefinition+source.text.slice(end);
  assert.notEqual(changedText,source.text);assert.equal(Buffer.byteLength(changedText),source.bytes.length);assert.equal(afterDefinition.replace(after,before),beforeDefinition);
  const changedSha=sha(changedText),workspace=path.join(out,'workspace');fs.mkdirSync(workspace,{mode:0o700});
  const newSources=captured.map(row=>({module:row.module,kind:'ps',text:row.module===source.module?changedText:row.text}));
  for(let i=0;i<captured.length;i++){const destination=path.join(workspace,relative(captured[i].path));fs.mkdirSync(path.dirname(destination),{recursive:true,mode:0o700});fs.writeFileSync(destination,newSources[i].text,{flag:'wx',mode:0o600});}
  const newProject=path.join(workspace,'project.json');fs.writeFileSync(newProject,projectBytes,{flag:'wx',mode:0o600});
  const changedDigest=helpers.compilerSourceClosureDigest(newSources);assert.notEqual(changedDigest,P.source);
  const verifyWorkspace=()=>{assert.equal(sha(read(newProject,1024*1024)),sha(projectBytes));for(let i=0;i<captured.length;i++)assert.equal(sha(read(contained(workspace,captured[i].path),1024*1024)),sha(newSources[i].text));};
  const change={schema:'psc1-type-key-source-change/1',module:source.module,canonicalOwner:'psc1/packages/compiler-ir/src/Ps/CompilerIr/Specialize.ps',projectPath:source.path,bytes:source.bytes.length,beforeSha256:source.sha256,afterSha256:changedSha,beforeDefinition,afterDefinition,beforeAnchor:before,afterAnchor:after,changedModules:1,oldSourceClosureDigest:P.source,newSourceClosureDigest:changedDigest,semantics:'same fuel, branches, keys and rejection conditions; prepare recursive closure only when a type is inspected'};
  save('source-change.json',change);fs.writeFileSync(path.join(out,'selected-source-before.ps'),source.bytes,{flag:'wx'});fs.writeFileSync(path.join(out,'selected-source-after.ps'),changedText,{flag:'wx'});
  console.log('PSC1_TYPE_KEY_SOURCE_AFTER: '+JSON.stringify(change));
  save('input.json',{schema:'psc1-type-key-qualification-input/1',observerCommit:process.env.GITHUB_SHA||null,toolchainSha256:P.toolchain,distributionArtifact:12788978661,baselineArtifact:12787934687,qualificationRun:40618697529,profileRun:40631714254,profileArtifact:12792955597,profileWorkerElapsedMs:1236092,profileLogSha256:'5eba285e8858c09f7182a1c23ba377604cebf5153f1f7105e69267a12dfca9f1',sourceModules:125,sourceBytes:2382708,sourceChange:change,machine:{platform:process.platform,arch:process.arch,release:os.release(),cpuModels:[...new Set(os.cpus().map(x=>x.model))],logicalCpus:os.cpus().length,totalMemoryBytes:os.totalmem()},ordinaryHostUnchanged:true,ordinaryRunnerUnchanged:true,workerTimeoutMs:3600000,oldSpaceMiB:4096});
  const verifyAll=()=>{verifyInputs();verifyWorkspace();};verifyAll();
  phase='old pinned seed to O1';const o1=path.join(out,'O1');const first=await hostBuild('O1',newProject,o1);verifyAll();const firstCheck=verifyBuild(o1,first,newSources,changedDigest,manifest.compiler.sha256,manifest.checker.sha256);
  phase='O1 to O2';const o2=path.join(out,'O2');const second=await hostBuild('O2',newProject,o2,o1);verifyAll();firstCheck.verify();const secondCheck=verifyBuild(o2,second,newSources,changedDigest,first.identities.sourceSha256,manifest.checker.sha256);
  assert.deepEqual(first.identities,second.identities);
  const fixedFiles=['compiler.mjs','candidate.json','admissions.json','original-ir.json','specialized-ir.json','sources.json'];for(const file of fixedFiles)assert.ok(read(path.join(o1,file)).equals(read(path.join(o2,file))),'fixed-point bytes: '+file);
  save('fixed-point.json',{schema:'psc1-type-key-fixed-point/1',status:'passed',generations:['O1','O2'],identities:second.identities,compared:fixedFiles,freshAdmissionEachGeneration:true,strictOriginalAndTransformedIr:true});
  function exactBaseline(directory,receipt){
    assert.equal(receipt.execution.requestSha256,P.request);assert.equal(receipt.execution.responseSha256,P.candidate);
    for(const file of fixedFiles)assert.ok(read(path.join(directory,file)).equals(read(path.join(baseline,file))),'immutable baseline bytes: '+file);
    assert.deepEqual(receipt.identities,{sourceClosureDigest:P.source,sourceSha256:P.compiler,admissionsSha256:P.admissions,originalIrSha256:P.originalIr,specializedIrSha256:P.specializedIr});
  }
  phase='matched unmodified compiler control';const controlDir=path.join(out,'control');const control=await hostBuild('control',projectFile,controlDir,baseline);verifyAll();firstCheck.verify();secondCheck.verify();const controlCheck=verifyBuild(controlDir,control,oldSources,P.source,P.compiler,manifest.checker.sha256);exactBaseline(controlDir,control);
  phase='O2 on the immutable qualified workload';const optimizedDir=path.join(out,'optimized-baseline');const optimized=await hostBuild('optimized-baseline',projectFile,optimizedDir,o2);verifyAll();firstCheck.verify();secondCheck.verify();controlCheck.verify();const optimizedCheck=verifyBuild(optimizedDir,optimized,oldSources,P.source,second.identities.sourceSha256,manifest.checker.sha256);exactBaseline(optimizedDir,optimized);optimizedCheck.verify();
  const oldMs=control.execution.elapsedMs,newMs=optimized.execution.elapsedMs;assert.ok(Number.isFinite(oldMs)&&oldMs>0&&Number.isFinite(newMs)&&newMs>0);
  const summary={schema:'psc1-type-key-latency-qualification/1',status:newMs<oldMs?'passed':'performance-not-improved',sourceChange:change,fixedPoint:{identities:second.identities,compared:fixedFiles},qualifiedCompiler:{directory:'O2',compilerSha256:second.identities.sourceSha256,filesManifestSha256:sha(read(path.join(o2,'files.json'))),sourceClosureDigest:changedDigest,selectedCanonicalSourceSha256:changedSha},comparison:{workloadSourceClosureDigest:P.source,requestSha256:P.request,completeCandidateSha256:P.candidate,completeCandidateBytesEqual:true,sameMachine:true,sameOrdinaryRuntimeFlags:true,controlCompilerSha256:P.compiler,optimizedCompilerSha256:second.identities.sourceSha256,controlElapsedMs:oldMs,optimizedElapsedMs:newMs,elapsedRatio:newMs/oldMs,savedMs:oldMs-newMs,observedReduction:(oldMs-newMs)/oldMs,controlPeakRssKiB:control.execution.peakRssKiB,optimizedPeakRssKiB:optimized.execution.peakRssKiB,interpretation:'one sequential matched pair on the same hosted runner; observed latency, not a statistical guarantee'},generations:{O1:{execution:first.execution,checker:first.checker},O2:{execution:second.execution,checker:second.checker}},benchmarks:{control:{execution:control.execution,checker:control.checker},optimized:{execution:optimized.execution,checker:optimized.checker}},freshIndependentAdmissionEveryBuild:true,strictOriginalAndTransformedIrEveryBuild:true,ordinaryHostUnchanged:true,ordinaryRunnerUnchanged:true};
  save('summary.json',summary);console.log('PSC1_TYPE_KEY_QUALIFICATION_RESULT: '+JSON.stringify(summary));assert.ok(newMs<oldMs,'correctness passed but the measured optimization did not improve rebuild latency');
}catch(error){const failure={schema:'psc1-type-key-qualification-failure/1',status:'failed',phase,message:error.message,stack:error.stack};fs.writeFileSync(path.join(out,'failure.json'),json(failure));console.error('PSC1_TYPE_KEY_QUALIFICATION_FAILED: '+JSON.stringify(failure));process.exitCode=1;}
