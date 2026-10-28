// CI-only observation of the immutable qualified full compiler workload.
// No compiler acceptance, IR policy or ordinary runner implementation is changed.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import crypto from 'node:crypto';
import { spawn } from 'node:child_process';
import { pathToFileURL } from 'node:url';
const sha=x=>crypto.createHash('sha256').update(x).digest('hex');
const json=x=>JSON.stringify(x,null,2)+'\n';
const MAX=128*1024*1024,LOG_MAX=32*1024*1024;
const PINS={
  toolchain:'04eb0bb66b4e3ac04850843af40546c3677f31782d73d39de4b6191927692cf2',
  source:'9d0f097e79eb2b1e14d10362c6db9b4bc2370c26627658017bf6b2681b46fabf',
  compiler:'858c188024f0a7da221e0c26053437b3fac3fc0ab1cc9d14092df19b39d1465d',
  admissions:'904cdaf4b2e57b2e1b4d3205928a14dd44676e74468e952c29e73847ec245de1',
  originalIr:'13fc0f2fbd65d421257e6df901a9a3afa1b74bf0472292de27549f6214a03b50',
  specializedIr:'a1a377f537848666837c74d0bffd4604718812d59a0d7bcb56586bf7936771c8',
  lean:'eb6cafb7290e8bd5f2937522d8d804f58f02bafc',
};
function read(file,limit=MAX){
  const stat=fs.lstatSync(file);
  assert.ok(stat.isFile()&&!stat.isSymbolicLink()&&stat.size<=limit,file);
  const bytes=fs.readFileSync(file);assert.equal(bytes.length,stat.size);return bytes;
}
function decoded(bytes){return new TextDecoder('utf-8',{fatal:true,ignoreBOM:true}).decode(bytes);}
function confined(root,relative){
  assert.ok(typeof relative==='string'&&relative&&!path.isAbsolute(relative));
  assert.ok(!relative.includes('\\')&&!relative.includes('\0'));
  let current=root;
  for(const part of relative.split('/')){
    assert.ok(part&&part!=='.'&&part!=='..');
    current=path.join(current,part);assert.ok(!fs.lstatSync(current).isSymbolicLink());
  }
  return current;
}
function cleanEnvironment(){
  const env={...process.env};
  for(const key of Object.keys(env))
    if(/^(NODE_|BUN_|NPM_|npm_|RUST|CARGO|DYLD_|LD_|PYTHON|LEAN_|ELAN_|PSC1_)/.test(key)||
      ['ENV','BASH_ENV','OPENSSL_CONF','OPENSSL_MODULES'].includes(key))delete env[key];
  return env;
}
const options={};
for(let args=process.argv.slice(2);args.length;){
  const key=args.shift(),value=args.shift();
  assert.ok(['--toolchain','--baseline','--out'].includes(key)&&value&&!options[key]);
  options[key]=path.resolve(value);
}
assert.equal(Object.keys(options).length,3);
const root=options['--toolchain'],baseline=options['--baseline'],out=options['--out'];
assert.ok(!fs.existsSync(out),'profile output must be new');
fs.mkdirSync(path.dirname(out),{recursive:true});fs.mkdirSync(out,{mode:0o700});
const save=(name,value)=>fs.writeFileSync(path.join(out,name),json(value),{flag:'wx',mode:0o600});
function memory(pid){
  try{
    const s=fs.readFileSync('/proc/'+pid+'/status','utf8');
    const n=field=>Number(new RegExp('^'+field+':\\s+(\\d+)\\s+kB$','m').exec(s)?.[1]||0);
    return{rssKiB:n('VmRSS'),highWaterKiB:n('VmHWM')};
  }catch{return{rssKiB:0,highWaterKiB:0};}
}
function processIdentity(pid){
  try{const s=fs.readFileSync('/proc/'+pid+'/stat','utf8');return s.slice(s.lastIndexOf(')')+2).split(' ')[19];}
  catch{return null;}
}
async function profiledWorker(label,job,runtime,runner){
  const jobFile=path.join(out,label+'-job.json');
  const jobBytes=Buffer.from(json(job));fs.writeFileSync(jobFile,jobBytes,{flag:'wx',mode:0o600});
  const profileFile=path.join(out,label+'.cpuprofile');
  const reads=[runner,jobFile,job.compiler,...(job.request?[job.request]:[])];
  const args=['--max-old-space-size=4096','--permission',
    ...reads.map(file=>'--allow-fs-read='+file),
    ...(job.output?['--allow-fs-write='+job.output]:[]),
    '--allow-fs-write='+profileFile,'--cpu-prof','--cpu-prof-interval=5000',
    '--cpu-prof-dir='+out,'--cpu-prof-name='+path.basename(profileFile),
    runner,'execute',jobFile,sha(jobBytes)];
  const started=Date.now();
  const child=spawn(runtime,args,{cwd:out,env:cleanEnvironment(),detached:true,stdio:['ignore','pipe','pipe']});
  const buffers={stdout:[],stderr:[]},sizes={stdout:0,stderr:0};
  let failure=null,peakRssKiB=0,nextHeartbeat=started+60000;
  let childIdentity=child.pid?processIdentity(child.pid):null;
  const kill=()=>{
    if(!child.pid)return;
    const current=processIdentity(child.pid);
    if(childIdentity&&current&&current!==childIdentity)return;
    try{process.kill(-child.pid,'SIGKILL');}catch(e){if(e.code!=='ESRCH')throw e;}
  };
  const stop=why=>{failure||=why;kill();};
  for(const key of ['stdout','stderr'])child[key].on('data',chunk=>{
    const take=Math.min(chunk.length,Math.max(0,LOG_MAX-sizes[key]));
    if(take)buffers[key].push(chunk.subarray(0,take));sizes[key]+=take;
    if(take!==chunk.length)stop('profile worker log limit');
  });
  const listeners=new Map();
  for(const signal of ['SIGINT','SIGTERM','SIGHUP']){
    const f=()=>stop('parent signal '+signal);listeners.set(signal,f);process.on(signal,f);
  }
  const timer=setInterval(()=>{
    if(!childIdentity&&child.pid)childIdentity=processIdentity(child.pid);
    const m=memory(child.pid);peakRssKiB=Math.max(peakRssKiB,m.rssKiB,m.highWaterKiB);
    if(Date.now()-started>=job.timeoutMs)stop('profile worker deadline');
    if(Date.now()>=nextHeartbeat){
      console.log('PSC1_REBUILD_PROFILE_HEARTBEAT: '+JSON.stringify({label,elapsedMs:Date.now()-started,peakRssKiB,observation:'worker resources, not semantic progress'}));
      nextHeartbeat=Date.now()+60000;
    }
  },100);
  try{
    const exit=await new Promise(resolve=>{
      child.once('error',e=>{failure='spawn: '+e.message;resolve({code:null,signal:null});});
      child.once('close',(code,signal)=>resolve({code,signal}));
    });
    const stdout=Buffer.concat(buffers.stdout),stderr=Buffer.concat(buffers.stderr);
    fs.writeFileSync(path.join(out,label+'-stdout.log'),stdout);
    fs.writeFileSync(path.join(out,label+'-stderr.log'),stderr);
    assert.equal(failure,null,failure||'worker failure');assert.equal(exit.code,0,stderr.toString('utf8').slice(-8192));
    assert.equal(sha(read(jobFile,1024*1024)),sha(jobBytes));
    const event=JSON.parse(stdout.toString('utf8').trim());
    assert.equal(event.protocol,'psc1-independent-worker/1');assert.equal(event.operation,job.operation);
    assert.equal(event.compilerSha256,PINS.compiler);
    const bytes=read(profileFile,512*1024*1024),profile=JSON.parse(decoded(bytes));
    assert.ok(Array.isArray(profile.nodes)&&profile.nodes.length>0&&Array.isArray(profile.samples));
    assert.ok(profile.samples.length>0,'CPU profile must contain samples');
    return{event,processElapsedMs:Date.now()-started,peakRssKiB:Math.max(peakRssKiB,event.maxRssKiB||0),
      profile,profileIdentity:{path:path.basename(profileFile),bytes:bytes.length,sha256:sha(bytes)}};
  }finally{
    clearInterval(timer);for(const[signal,f]of listeners)process.removeListener(signal,f);kill();
  }
}
function summarizeProfile(profile,compilerFile,compilerText){
  const byId=new Map(profile.nodes.map(node=>[node.id,node]));
  assert.equal(profile.samples.length,profile.timeDeltas.length);
  const compilerUrl=pathToFileURL(compilerFile).href,lines=compilerText.split('\n'),ownerAtLine=[];
  let owner='(module initialization)';
  for(let i=0;i<lines.length;i++){
    const m=/^(?:export\s+)?function\*?\s+([A-Za-z_$][\w$]*)\s*\(/.exec(lines[i]);
    if(m)owner=m[1];ownerAtLine[i]=owner;
  }
  const frames=new Map(),owners=new Map(),categories=new Map();let totalUs=0;
  function category(name){
    if(name==='(garbage collector)')return'sampled garbage collection';
    if(name==='(idle)')return'sampled idle';
    if(/^__ps\$(run|wrap|invoke|tailInvoke)$/.test(name))return'generator execution driver';
    if(/utf8|string(Get|Next|Extract|Utf8)/i.test(name))return'UTF-8 runtime helpers';
    if(/psJson/i.test(name))return'JSON codec names';
    if(/ps.*(Parser|Parse|Lexer|Lex|Token)/i.test(name))return'frontend names';
    if(/ps.*(Elab|Meta|Unif|DefEq)/i.test(name))return'elaboration/metaprogramming names';
    if(/ps.*(Js|Ts|Rust|Wasm)/i.test(name))return'backend names';
    if(/ps.*(Ir|Erasure|Specializ|WorkerFusion)/i.test(name))return'IR/erasure names';
    if(/ps.*(List|Text|String|Name)/i.test(name))return'foundation names';
    return'other';
  }
  function add(map,key,row,us){const old=map.get(key)||{...row,selfUs:0,samples:0};old.selfUs+=us;old.samples++;map.set(key,old);}
  for(let i=0;i<profile.samples.length;i++){
    const node=byId.get(profile.samples[i]);assert.ok(node);
    const us=profile.timeDeltas[i];assert.ok(Number.isFinite(us)&&us>=0);
    totalUs+=us;const f=node.callFrame,name=f.functionName||'(anonymous)';
    const owned=f.url===compilerUrl||f.url===compilerFile;
    const sourceOwner=owned?(ownerAtLine[f.lineNumber]||name):name;
    const normalizedOwner=sourceOwner.replace(/^__ps\$impl\$/,'');
    const key=JSON.stringify([name,f.url,f.lineNumber,f.columnNumber]);
    add(frames,key,{name,url:f.url,line:f.lineNumber+1,column:f.columnNumber+1,generatedOwner:owned?sourceOwner:null},us);
    add(owners,JSON.stringify([owned,normalizedOwner]),{name:normalizedOwner,generatedCompiler:owned},us);
    const cat=category(owned?normalizedOwner:name);add(categories,cat,{name:cat},us);
  }
  const ranked=map=>[...map.values()].sort((a,b)=>b.selfUs-a.selfUs).map(row=>({...row,selfMs:row.selfUs/1000,weightedShare:totalUs?row.selfUs/totalUs:0}));
  const allCategories=ranked(categories);
  return{samplingIntervalUs:5000,samples:profile.samples.length,nodes:profile.nodes.length,
    profileDurationMs:(profile.endTime-profile.startTime)/1000,weightedSampleMs:totalUs/1000,
    attribution:'timeDeltas weighted sampled self-time; categories are name heuristics, not stopwatch phase timings; generator trampoline stacks are not logical ProofScript caller stacks',
    gc:allCategories.find(row=>row.name==='sampled garbage collection')||{name:'sampled garbage collection',samples:0,selfUs:0,selfMs:0,weightedShare:0},
    categories:allCategories,topFrames:ranked(frames).slice(0,100),topGeneratedOwners:ranked(owners).filter(x=>x.generatedCompiler).slice(0,100)};
}
let phase='inputs';
try{
  assert.equal(process.platform,'linux');
  const manifestFile=path.join(root,'toolchain.json'),manifestBytes=read(manifestFile,4*1024*1024);
  assert.equal(sha(manifestBytes),PINS.toolchain);
  const manifest=JSON.parse(decoded(manifestBytes));
  const verifyResources=()=>{
    assert.equal(sha(read(manifestFile,4*1024*1024)),PINS.toolchain);
    for(const pin of manifest.resources){const b=read(confined(root,pin.path),512*1024*1024);assert.equal(b.length,pin.bytes);assert.equal(sha(b),pin.sha256);}
  };
  verifyResources();
  const runtime=path.join(root,'libexec/psc-runtime'),runner=path.join(root,'standalone/runner.mjs');
  const compiler=path.join(baseline,'compiler.mjs'),compilerBytes=read(compiler);
  assert.equal(sha(compilerBytes),PINS.compiler);
  const helpers=await import(pathToFileURL(path.join(root,'host-tools/compiler-host-protocol.mjs')).href);
  const projectFile=path.join(root,'compiler/project.json'),projectBytes=read(projectFile,1024*1024);
  const project=JSON.parse(decoded(projectBytes)),sourcePins=[];
  assert.equal(project.entryModule,'Ps.CompilerUnified.Service');assert.equal(project.sources.length,125);
  const sources=project.sources.map(row=>{
    assert.ok(row.path.endsWith('.ps'));const file=confined(path.dirname(projectFile),row.path),bytes=read(file);
    sourcePins.push({file,sha256:sha(bytes),bytes:bytes.length});return{module:row.module,kind:'ps',text:decoded(bytes)};
  });
  assert.equal(sourcePins.reduce((n,p)=>n+p.bytes,0),2382708);
  assert.deepEqual(sources,JSON.parse(decoded(read(path.join(baseline,'sources.json')))));
  const digest=helpers.compilerSourceClosureDigest(sources);assert.equal(digest,PINS.source);
  const id='psc1-independent-'+digest.slice(0,24);
  const request=JSON.stringify(['psc1-unified-compiler-service/2','js',['psc1-compiler-service/1',id,digest,'ps','ordinary-checked',project.entryModule,sources.map(x=>[x.module,x.text])]]);
  const requestFile=path.join(out,'request.json'),responseFile=path.join(out,'candidate.json');
  fs.writeFileSync(requestFile,request,{flag:'wx',mode:0o600});
  save('input.json',{schema:'psc1-rebuild-profile-input/1',qualificationRun:40618697529,distributionArtifact:12788978661,baselineArtifact:12787934687,
    sourceCommit:'5484a04df34de1bbcfa46a248b6a93ce510035d6',observerCommit:process.env.GITHUB_SHA||null,sourceModules:sources.length,sourceUtf8Bytes:2382708,
    toolchainSha256:PINS.toolchain,compilerSha256:PINS.compiler,sourceClosureDigest:digest,requestSha256:sha(request),projectSha256:sha(projectBytes),
    machine:{platform:process.platform,arch:process.arch,release:os.release(),cpuModels:[...new Set(os.cpus().map(x=>x.model))],logicalCpus:os.cpus().length,totalMemoryBytes:os.totalmem()},
    samplingIntervalUs:5000,timeoutMs:3600000,oldSpaceMiB:4096,ordinaryRunnerUnchanged:true,productionAcceptanceUnchanged:true});
  const verifyInputs=()=>{
    for(const pin of sourcePins)assert.equal(sha(read(pin.file)),pin.sha256);
    assert.equal(sha(read(projectFile,1024*1024)),sha(projectBytes));
    assert.equal(sha(read(compiler)),PINS.compiler);verifyResources();
  };
  const common={schema:'psc1-independent-worker-job/1',root,compiler,compilerSha256:PINS.compiler,exportName:'psCompilerServiceCandidate'};
  phase='permission/profile preflight';
  const preflight=await profiledWorker('preflight',{...common,operation:'inspect',publicNames:['psCompilerServiceCandidate'],timeoutMs:240000},runtime,runner);
  save('preflight.json',{status:'passed',event:preflight.event,profile:preflight.profileIdentity,samples:preflight.profile.samples.length});
  console.log('PSC1_REBUILD_PROFILE_PREFLIGHT: '+JSON.stringify({status:'passed',samples:preflight.profile.samples.length,profile:preflight.profileIdentity}));
  phase='full compilation';
  const full=await profiledWorker('compile',{...common,operation:'compile',request:requestFile,requestSha256:sha(request),output:responseFile,timeoutMs:3600000},runtime,runner);
  const candidateBytes=read(responseFile);assert.equal(full.event.requestSha256,sha(request));assert.equal(full.event.responseSha256,sha(candidateBytes));
  assert.ok(candidateBytes.equals(read(path.join(baseline,'candidate.json'))),'complete candidate bytes must equal qualified B2');
  const candidate=JSON.parse(decoded(candidateBytes));
  const identities={sourceClosureDigest:digest,compilerSha256:sha(candidate.source),admissionsSha256:sha(candidate.admissionRequest.admissions),originalIrSha256:sha(JSON.stringify(candidate.originalIr)),specializedIrSha256:sha(JSON.stringify(candidate.specializedIr))};
  assert.equal(identities.compilerSha256,PINS.compiler);assert.equal(identities.admissionsSha256,PINS.admissions);
  assert.equal(identities.originalIrSha256,PINS.originalIr);assert.equal(identities.specializedIrSha256,PINS.specializedIr);
  verifyInputs();
  phase='fresh independent admission';
  const checkerStart=Date.now();
  const accepted=helpers.createCompilerHostSession({requestId:id,target:'js',sources,canonicalAdmissions:candidate.admissionRequest.admissions,checkerExecutable:path.join(root,'kernel/checker')}).admit(JSON.stringify(candidate.admissionRequest));
  const checkerElapsedMs=Date.now()-checkerStart;
  assert.equal(accepted.accepted,true);assert.equal(accepted.checkerCommit,PINS.lean);assert.equal(accepted.admissionsDigest,PINS.admissions);
  verifyInputs();
  phase='profile summary';
  const profile=summarizeProfile(full.profile,compiler,decoded(compilerBytes));
  const summary={schema:'psc1-rebuild-profile/1',status:'passed',observerCommit:process.env.GITHUB_SHA||null,identities,completeCandidateBytesEqual:true,
    worker:full.event,processElapsedMs:full.processElapsedMs,sampledPeakRssKiB:full.peakRssKiB,profileIdentity:full.profileIdentity,
    checker:{executed:true,accepted:true,leanCommit:accepted.checkerCommit,sha256:manifest.checker.sha256,admissionsSha256:accepted.admissionsDigest,elapsedMs:checkerElapsedMs,receiptSha256:sha(JSON.stringify(accepted))},
    strictIr:'unchanged generated compiler pipeline; original/transformed IR and complete candidate bytes equal qualified B2',profile};
  save('summary.json',summary);save('checker-receipt.json',accepted);
  console.log('PSC1_REBUILD_PROFILE_RESULT: '+JSON.stringify({...summary,profile:{...profile,topFrames:profile.topFrames.slice(0,30),topGeneratedOwners:profile.topGeneratedOwners.slice(0,30)}}));
}catch(error){
  const failure={schema:'psc1-rebuild-profile-failure/1',status:'failed',phase,message:error.message,stack:error.stack};
  fs.writeFileSync(path.join(out,'failure.json'),json(failure));console.error('PSC1_REBUILD_PROFILE_FAILED: '+JSON.stringify(failure));process.exitCode=1;
}
