import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import crypto from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import {checkPracticalApplications} from './check-practical-applications.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const evidence=path.join(root,'dist/scoped-correctness',process.env.PSC1_APPLICATION_EVIDENCE||'practical-applications');
const contract=JSON.parse(fs.readFileSync(path.join(root,'docs/PSC1_APPLICATION_EXECUTION_CONTRACT.json'),'utf8'));
const targets=(process.env.PSC1_APPLICATION_TARGETS||contract.targets.join(',')).split(',');
assert.ok(targets.length&&targets.every(t=>contract.targets.includes(t)));assert.equal(new Set(targets).size,targets.length);
const native=process.env.PSC1_NATIVE||path.join(root,'.lake/build/bin/psc1');
const work=fs.mkdtempSync(path.join(os.tmpdir(),'psc1-practical-applications-'));
const env={...process.env,PSC1_HOST_TOOLS:path.join(root,'host-tools/artifacts.mjs')};
const records=[],failures=[],read=p=>fs.readFileSync(path.join(root,p),'utf8');
const hash=p=>crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');
const sha=value=>crypto.createHash('sha256').update(value).digest('hex');
function write(p,s){fs.mkdirSync(path.dirname(p),{recursive:true});fs.writeFileSync(p,s);}
function invoke(cmd,args,options={}){
 const r=spawnSync('timeout',['--kill-after=5s','180s',cmd,...args],{cwd:root,env,encoding:'utf8',
  timeout:190000,maxBuffer:32*1024*1024,...options});
 assert.equal(r.error,undefined);assert.equal(r.signal,null);return r;
}
function run(cmd,args,options={}){const r=invoke(cmd,args,options);assert.equal(r.status,0,cmd+' '+args.join(' ')+'\n'+r.stdout+r.stderr);return r.stdout;}
const valid='[{"text":"A","count":2},{"text":"\\uD83D\\uDE00","count":-4}]';
const referenceFile=path.join(root,'test/PracticalApplicationReference.lean');
const oracleLog=run('lake',['env','lean','--run',referenceFile],{input:valid});
const oracleLines=oracleLog.split('\n').filter(l=>l.startsWith('PSC1_PRACTICAL_APPLICATION_REFERENCE: '));
assert.equal(oracleLines.length,1);
const oracle=JSON.parse(oracleLines[0].slice('PSC1_PRACTICAL_APPLICATION_REFERENCE: '.length));
assert.equal(oracle.leanVersion,'4.35.0');assert.equal(oracle.leanCommit,contract.checkerCommit);
assert.equal(oracle.output,'[{"count":2,"text":"processed:A"},{"count":-4,"text":"processed:😀"}]');
write(path.join(evidence,'native-reference.log'),oracleLog);
write(path.join(evidence,'native-reference.lean'),read('test/PracticalApplicationReference.lean'));
write(path.join(work,'package.json'),'{"type":"module"}\n');
const cases=[
 {id:'help',args:['--help'],code:0,stdout:'usage: transform INPUT OUTPUT\n'},
 {id:'invalid-command',args:['bad'],code:2,stdout:'usage: transform INPUT OUTPUT\n'},
 {id:'invalid-arity',args:['transform','input.json'],code:2,stdout:'usage: transform INPUT OUTPUT\n'},
 {id:'invalid-help-arity',args:['--help','extra'],code:2,stdout:'usage: transform INPUT OUTPUT\n'},
 {id:'unicode-records',input:valid,output:oracle.output,code:0,stdout:'ok\n'},
 {id:'argv-unicode-quote',inputName:'in \"Ω😀.json',args:['transform','in \"Ω😀.json','output.json'],input:valid,output:oracle.output,code:0,stdout:'ok\n'},
 {id:'bounded-output',input:JSON.stringify([{text:'a'.repeat(480),count:0}]),code:2,stdout:'error:tooLarge\n'},
 {id:'empty-records',input:'[]',output:'[]',code:0,stdout:'ok\n'},
 {id:'array-trailing-comma',input:'[{"text":"A","count":1}, ]',code:2,stdout:'invalid-json\n'},
 {id:'object-trailing-comma',input:'[{"text":"A","count":1, }]',code:2,stdout:'invalid-json\n'},
 {id:'malformed-json',input:'{',code:2,stdout:'invalid-json\n'},
 {id:'isolated-surrogate',input:'[{"text":"\\uD800","count":1}]',code:2,stdout:'invalid-unicode\n'},
 {id:'duplicate-key',input:'[{"text":"A","text":"B","count":1}]',code:2,stdout:'invalid-json\n'},
 {id:'wrong-shape',input:'[{"text":false,"count":1}]',code:2,stdout:'invalid-json\n'},
 {id:'missing-input',missing:true,code:2,stdout:'error:notFound\n'},
 {id:'path-denied',args:['transform','../input.json','output.json'],code:2,stdout:'error:pathDenied\n'},
 {id:'read-permission',input:valid,readMode:0,code:2,stdout:'error:ioFailure\n'},
 {id:'invalid-utf8',input:Buffer.from([0xff]),code:2,stdout:'error:invalidUtf8\n'},
 {id:'bounded-file',input:' '.repeat(513),code:2,stdout:'error:tooLarge\n'},
 {id:'write-permission',input:valid,writeMode:0o500,code:2,stdout:'error:ioFailure\n'},
 {id:'denied-capability',denied:true,code:78,stdout:''}
];
try{
 for(const syntax of contract.grammars)for(const target of targets){
  const label=syntax+'-'+target,folder=path.join(work,label),sourceRoot=path.join(folder,'source');
  const source=path.join(sourceRoot,'Run.'+syntax);
  const output=path.join(folder,'module.'+{js:'js',ts:'ts',rust:'rs','wasm-core':'wasm','wasm-component':'wasm',python:'py',php:'php'}[target]);
  try{
   for(const name of ['Args','Transform','Program'])write(path.join(sourceRoot,'PracticalCli',name+'.'+syntax),read('test/applications/PracticalCli/'+name+'.'+syntax));
   write(source,read('test/applications/PracticalCli/Run.'+syntax));
   write(path.join(sourceRoot,'ProofScript/System/IO.'+syntax),read('stdlib/ProofScript/System/IO.'+syntax));
   run(native,['build',source,'--target',target,'--assurance','ordinary','--abi','io-dispatcher','--out',output]);
   const manifest=JSON.parse(fs.readFileSync(output+'.bundle.json','utf8'));
   assert.equal(manifest.logicalCheckerCommit,contract.checkerCommit);assert.equal(manifest.behaviorallyVerified,false);
   assert.equal(manifest.publicAbi,target.startsWith('wasm-')?'wasm-io-dispatcher':'io-dispatcher');
   let module=output,hostCargoLockSha256=null,command;
   if(target==='ts'){
    assert.ok(process.env.PSC1_TSC);const consumer=path.join(folder,'typescript');
    run(process.execPath,[process.env.PSC1_TSC,'--ignoreConfig','--strict','--target','ES2022','--module','ESNext','--moduleResolution','Bundler','--outDir',consumer,fs.realpathSync(output)]);
    write(path.join(consumer,'package.json'),'{"type":"module"}\n');module=path.join(consumer,'module.js');
   }
   if(target==='rust'){
    const crate=path.join(folder,'consumer');fs.cpSync(fs.realpathSync(output.replace(/\.rs$/,'.cargo')),crate,{recursive:true,dereference:true});
    fs.appendFileSync(path.join(crate,'Cargo.toml'),'\n[dependencies.psc1-typed-io]\npath = '+JSON.stringify(path.join(root,'host-tools/typed-io-rust'))+'\n');
    write(path.join(crate,'src/bin/practical-application.rs'),read('scripts/practical-application-rust.rs'));
    run('python3',[path.join(root,'scripts/merge-rust-io-lock.py'),path.join(crate,'Cargo.lock'),path.join(root,'host-tools/typed-io-rust/Cargo.lock')]);
    hostCargoLockSha256=hash(path.join(crate,'Cargo.lock'));
    write(path.join(evidence,'consumers',label,'Cargo.lock'),fs.readFileSync(path.join(crate,'Cargo.lock'),'utf8'));
    run('cargo',['build','--locked','--manifest-path',path.join(crate,'Cargo.toml'),'--bin','practical-application'],
     {env:{...env,CARGO_TARGET_DIR:path.join(folder,'cargo-target')}});
    command=[path.join(folder,'cargo-target/debug/practical-application')];
   }
   const observations=[];
   for(const test of cases){
    const caseRoot=path.join(folder,test.id);fs.mkdirSync(caseRoot,{recursive:true});
    const input=path.join(caseRoot,test.inputName||'input.json'),destination=path.join(caseRoot,'output.json');
    if(!test.missing)fs.writeFileSync(input,test.input??valid);
    fs.writeFileSync(destination,'previous');
    if(test.readMode!==undefined)fs.chmodSync(input,test.readMode);
    if(test.writeMode!==undefined)fs.chmodSync(caseRoot,test.writeMode);
    const config=path.join(folder,test.id+'.json');
    write(config,JSON.stringify({abi:target==='rust'?'psc1-rust-linux-string-io/1':'psc1-node-linux-string-io/1',
     capabilities:test.denied?[]:['readUtf8','writeUtf8','writeLine'],required:['readUtf8','writeUtf8','writeLine'],
     root:caseRoot,maxFileBytes:512,maxLineBytes:128,inputFd:0,outputFd:1}));
    const argv=test.args||['transform','input.json','output.json'];
    let cmd;
    if(target==='rust')cmd=[...command,config,...argv];
    else if(target==='python'||target==='wasm-component')cmd=[
     target==='python'?(process.env.PSC1_PYTHON||'python3'):(process.env.PSC1_WASMTIME_PY||'python3'),'-I',
     path.join(root,'scripts/practical-application-python.py'),target,test.denied?'/missing-guest':module,config,...argv];
    else if(target==='php')cmd=[process.env.PSC1_PHP||'php','-d','ffi.enable=1',path.join(root,'scripts/practical-application-php.php'),
     test.denied?'/missing-guest':module,config,...argv];
    else cmd=[process.execPath,path.join(root,'scripts/practical-application-node.mjs'),target,test.denied?'/missing-guest':module,config,...argv];
    let result;
    try{result=invoke(cmd[0],cmd.slice(1));}
    finally{fs.chmodSync(caseRoot,0o700);if(fs.existsSync(input))fs.chmodSync(input,0o600);}
    assert.equal(result.status,test.code,label+'/'+test.id+'\n'+result.stdout+result.stderr);
    assert.equal(result.stdout,test.stdout,label+'/'+test.id);
    assert.equal(fs.readFileSync(destination,'utf8'),test.output??'previous',label+'/'+test.id+' previous output');
    assert.deepEqual(fs.readdirSync(caseRoot).filter(n=>n.startsWith('.psc1-')),[],'atomic temporary leak');
    observations.push({id:test.id,passed:true,exitCode:result.status,stdoutSha256:sha(result.stdout),stderrSha256:sha(result.stderr),
     outputSha256:hash(destination),preservedPrevious:test.output===undefined});
   }
   const pointer=fs.realpathSync(output+'.bundle.json'),manifestSha256=hash(output+'.bundle.json');
   const rejected=invoke(native,['build',source,'--target',target,'--abi','io-dispatcher','--assurance','verified','--out',output]);
   assert.notEqual(rejected.status,0);assert.match(rejected.stdout+rejected.stderr,/PSC1_VERIFIED_EXECUTION_UNAVAILABLE/);
   assert.equal(fs.realpathSync(output+'.bundle.json'),pointer);assert.equal(hash(output+'.bundle.json'),manifestSha256);
   const moduleSha256=Object.fromEntries(['Args','Transform','Program'].map(n=>[n,hash(path.join(sourceRoot,'PracticalCli',n+'.'+syntax))]));
   records.push({syntax,target,passed:true,runtime:'executed',hostEffects:true,admission:'independent-official-Lean',
    checkerCommit:manifest.logicalCheckerCommit,strictIr:'required-by-production-publication',
    sourceSha256:hash(source),moduleSha256,librarySha256:hash(path.join(sourceRoot,'ProofScript/System/IO.'+syntax)),
    artifactSha256:hash(output),manifestSha256,kernelAdmissionSha256:manifest.kernelAdmissionSha256,
    sourceClosureSha256:manifest.sourceClosureSha256,oracleSha256:hash(referenceFile),hostCargoLockSha256,cases:observations});
   fs.cpSync(path.dirname(pointer),path.join(evidence,'bundles',label),{recursive:true});
   console.log('PSC1_PRACTICAL_APPLICATION_RECORD: '+JSON.stringify(records.at(-1)));
   console.log('PSC1_PRACTICAL_APPLICATION_PASS: '+label+' '+observations.length+' actual CLI/file cases');
  }catch(error){failures.push({label,error:error.stack||String(error)});console.error('PSC1_PRACTICAL_APPLICATION_FAIL: '+label+'\n'+error.stack);}
 }
}finally{
 const receipt={schema:'psc1-practical-application-execution/1',contract:contract.id,testedCommit:process.env.GITHUB_SHA||null,
  branchHeadCommit:process.env.PSC1_HEAD_SHA||null,checkerCommit:contract.checkerCommit,targets,records,failures,passed:failures.length===0};
 write(path.join(evidence,'results.json'),JSON.stringify(receipt,null,2)+'\n');
 console.log('PSC1_PRACTICAL_APPLICATIONS: '+JSON.stringify(receipt));
 if(!failures.length)checkPracticalApplications(contract,receipt,{commit:receipt.testedCommit,targets});
 fs.rmSync(work,{recursive:true,force:true});
}
assert.deepEqual(failures,[]);
