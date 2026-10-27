// Real long-running installed CLI, genuine compiler/Lean kernel and immutable stores.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {spawn} from 'node:child_process';
import {fixture} from './cli-fixture.mjs';
const f = fixture({consumers:true}), cases = [], active = new Set();
const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));
async function until(predicate, message, limit = 240000) {
  const start = Date.now();
  while (!predicate()) {
    if (Date.now() - start > limit) throw Error('WATCH_TEST_TIMEOUT: ' + message);
    await sleep(20);
  }
}
function watch(args, cwd, runtime = f.runtime) {
  const flags = path.basename(runtime).startsWith('bun') ? ['--no-install','--no-macros','--no-env-file'] : [];
  const child = spawn(runtime, [...flags, f.cli, 'build', ...args, '--watch', '--diagnostics=json'],
    {cwd, env:f.env, stdio:['ignore','pipe','pipe']});
  const state = {child, receipts:[], events:[], diagnostics:[], stderr:'', exit:undefined};
  active.add(state);
  let stdout = '', stderr = '';
  child.stdout.on('data', chunk => {
    stdout += chunk;
    assert.ok(stdout.length < 32*1024*1024);
    for (;;) {
      const end = stdout.indexOf('\n'); if (end < 0) break;
      const line = stdout.slice(0,end); stdout = stdout.slice(end+1);
      if (line) state.receipts.push(JSON.parse(line));
    }
  });
  child.stderr.on('data', chunk => {
    state.stderr += chunk; stderr += chunk; assert.ok(state.stderr.length < 32*1024*1024);
    for (;;) {
      const end = stderr.indexOf('\n'); if (end < 0) break;
      const line = stderr.slice(0,end); stderr = stderr.slice(end+1); if (!line) continue;
      const event = JSON.parse(line);
      (event.schema === 'proofscript-watch-event/1' ? state.events : state.diagnostics).push(event);
    }
  });
  child.on('error', error => {state.error=String(error);});
  child.on('close', (code, signal) => {state.exit={code, signal}; active.delete(state);});
  return state;
}
async function receipt(state, after) {
  await until(() => state.receipts.length > after || state.exit, state.stderr);
  assert.equal(state.exit, undefined, state.stderr);
  return state.receipts[after];
}
async function failed(state, after) {
  await until(() => state.events.filter(e => e.event.startsWith('failed')).length > after || state.exit, state.stderr);
  assert.equal(state.exit, undefined, state.stderr);
}
async function stop(state, signal='SIGINT') {
  const start = Date.now(); state.child.kill(signal);
  await until(() => state.exit, 'watch must terminate promptly', 6000);
  assert.equal(state.exit.code, signal==='SIGINT'?130:143, state.stderr);
  return Date.now()-start;
}
try {
  for (const kind of ['ps','lean']) {
    const dir=path.join(f.directory,'project-'+kind);fs.mkdirSync(dir);
    const lib=path.join(dir,'Lib.'+kind), config=path.join(dir,'proofscript.json');
    const source=n=>'namespace Lib\ndef base : Nat := '+n+'\nend Lib\n';
    fs.writeFileSync(lib,source(40));
    fs.writeFileSync(path.join(dir,'Main.'+kind),'import Lib\ndef answer : Nat := Lib.base + 2\n');
    const data={schema:'proofscript-project/1',entryModule:'Main',files:[
      {module:'Lib',path:'Lib.'+kind},{module:'Main',path:'Main.'+kind}]};
    fs.writeFileSync(config,JSON.stringify(data));
    const out=path.join(dir,'out'), state=watch(['--out',out,'--publication-protocol','portable-file'],dir);
    assert.equal(f.observe(await receipt(state,0)),'42');
    fs.writeFileSync(lib,source(41)); assert.equal(f.observe(await receipt(state,1)),'43');
    let pointer=fs.readFileSync(path.join(out,'current.json')), failures=0;
    fs.writeFileSync(lib+'.tmp','namespace Lib\ndef base : Nat := true\nend Lib\n');
    fs.renameSync(lib+'.tmp',lib);await failed(state,failures++);
    assert.deepEqual(fs.readFileSync(path.join(out,'current.json')),pointer);
    fs.unlinkSync(lib);await failed(state,failures++);
    assert.deepEqual(fs.readFileSync(path.join(out,'current.json')),pointer);
    fs.writeFileSync(lib,source(42));assert.equal(f.observe(await receipt(state,2)),'44');
    data.files[0].path='Replacement.'+kind;
    fs.writeFileSync(config+'.tmp',JSON.stringify(data));fs.renameSync(config+'.tmp',config);
    await failed(state,failures++);
    fs.writeFileSync(path.join(dir,data.files[0].path),source(43));
    assert.equal(f.observe(await receipt(state,3)),'45');
    const count=state.receipts.length;
    fs.writeFileSync(lib,source(99));await sleep(1600);
    assert.equal(state.receipts.length,count,'old/unlisted source must not trigger a rebuild');
    pointer=fs.readFileSync(path.join(out,'current.json'));
    fs.writeFileSync(config,JSON.stringify({...data,out:'unauthorized'}));await failed(state,failures++);
    assert.deepEqual(fs.readFileSync(path.join(out,'current.json')),pointer);
    assert.equal(fs.existsSync(path.join(dir,'unauthorized')),false);
    fs.writeFileSync(config,JSON.stringify(data));assert.equal(f.observe(await receipt(state,4)),'45');
    const elapsed=await stop(state);
    cases.push({kind,dependencyEdit:true,atomicSave:true,illTypedAndMissingPreservedPointer:true,
      missingNewDependencyRecovered:true,configRecaptured:true,unlistedChangesIgnored:true,
      metadataAuthorityRefused:true,signalExit:130,stopMs:elapsed,receipts:state.receipts,diagnostics:state.diagnostics});
  }
  for(const kind of ['ps','lean'])for(const target of ['ts','rust','wasm-core']){
    const dir=path.join(f.directory,kind+'-'+target);fs.mkdirSync(dir);
    const file=path.join(dir,'Main.'+kind),out=path.join(dir,'out');fs.writeFileSync(file,'def answer : Nat := 42\n');
    const args=[file,'--target',target,'--out',out,'--publication-protocol','portable-file'];
    if(target==='rust') {
      assert.ok(process.env.PSC1_TEST_RUST_ROOT,'pinned installed Rust SDK required');
      args.push('--rust-toolchain-root',process.env.PSC1_TEST_RUST_ROOT);
    }
    const state=watch(args,dir),initial=await receipt(state,0);
    assert.equal(initial.logicalAdmission,'accepted');
    assert.ok(initial.artifact.endsWith(target==='ts'?'.ts':target==='rust'?'.rs':'.wasm'),initial.artifact);
    fs.writeFileSync(file,'def answer : Nat := 43\n');
    const edited=await receipt(state,1);assert.notEqual(edited.sourceClosureDigest,initial.sourceClosureDigest);
    assert.equal(edited.logicalAdmission,'accepted');
    if(target!=='rust')assert.equal(f.observe(edited),'43');
    await stop(state);
    cases.push({kind,target,initial,edited,realIndependentCheckAndTargetConsumer:true});
  }
  // Observe a real staged request, then edit before its checked build can publish.
  const dir=path.join(f.directory,'superseded');fs.mkdirSync(dir);
  const file=path.join(dir,'Main.ps'),out=path.join(dir,'out');
  fs.writeFileSync(file,Array.from({length:200},(_,i)=>'def value'+i+' : Nat := '+i).join('\n')+'\ndef answer : Nat := 42\n');
  const state=watch([file,'--out',out,'--publication-protocol','portable-file'],dir);
  let staged;
  await until(()=>{
    const gen=path.join(out,'generations');if(!fs.existsSync(gen))return false;
    for(const name of fs.readdirSync(gen)){
      const p=path.join(gen,name,'request.json');
      if(name.startsWith('.stage-')&&fs.existsSync(p)){staged=JSON.parse(fs.readFileSync(p));return true;}
    }return false;
  },'real source snapshot must reach generated compiler');
  assert.equal(fs.existsSync(path.join(out,'current.json')),false,'edit must precede first commit');
  const oldDigest=staged[2];
  fs.writeFileSync(file,'def answer : Nat := 43\n');
  const latest=await receipt(state,0);assert.equal(f.observe(latest),'43');
  assert.notEqual(latest.sourceClosureDigest,oldDigest);
  assert.ok(state.diagnostics.some(d=>/WATCH_SUPERSEDED/.test(d.message)),state.stderr);
  // Cancel a second real request while work is active; keep the committed pointer.
  const pointer=fs.readFileSync(path.join(out,'current.json'));
  const prior=state.events.filter(e=>e.event==='checking').length;
  const previousStages=new Set(fs.readdirSync(path.join(out,'generations')));
  fs.writeFileSync(file,'def answer : Nat := 44\n');
  await until(()=>state.events.filter(e=>e.event==='checking').length>prior,'active checking');
  await until(()=>fs.readdirSync(path.join(out,'generations')).some(name=>
    !previousStages.has(name)&&name.startsWith('.stage-')&&fs.existsSync(path.join(out,'generations',name,'request.json'))),
    'cancellation must interrupt a real staged compiler request');
  const elapsed=await stop(state,'SIGTERM');
  assert.deepEqual(fs.readFileSync(path.join(out,'current.json')),pointer);
  cases.push({supersededRealRequest:true,oldDigest,latest,activeSignalExit:143,stopMs:elapsed,
    priorGenerationPreserved:true,diagnostics:state.diagnostics});

  // Exercise real native descendants under both host runtimes. The independent
  // Rust guardian must survive outer CLI group cancellation long enough to reap.
  const rustRoot=path.join(f.directory,'node_modules/@proofscript/compiler-rust-linux-x64');
  const rustArtifact=JSON.parse(fs.readFileSync(path.join(rustRoot,'payload/artifact.json')));
  const binary=path.join(rustRoot,'payload',rustArtifact.executable);
  function rustProcesses(){
    const rows=[];
    for(const pid of fs.readdirSync('/proc').filter(n=>/^[0-9]+$/.test(n))){
      try{
        const cmd=fs.readFileSync('/proc/'+pid+'/cmdline','utf8');
        if(!cmd.includes(binary))continue;
        const stat=fs.readFileSync('/proc/'+pid+'/stat','utf8');
        const state=stat.slice(stat.lastIndexOf(')')+2).split(' ')[0];
        if(!['Z','X','x'].includes(state))rows.push({pid:Number(pid),exe:fs.readlinkSync('/proc/'+pid+'/exe')});
      }catch{}
    }return rows;
  }
  for(const runtime of new Set([f.runtime,process.env.PSC1_TEST_BUN_RUNTIME].filter(Boolean))){
    const dir=path.join(f.directory,'native-cancellation-'+path.basename(runtime));fs.mkdirSync(dir);
    const file=path.join(dir,'Main.ps'),out=path.join(dir,'out');
    fs.writeFileSync(file,Array.from({length:4000},(_,i)=>'def value'+i+' : Nat := '+i).join('\n')+'\ndef answer : Nat := 42\n');
    const state=watch([file,'--engine','rust','--out',out,'--publication-protocol','portable-file'],dir,runtime);
    let observed;
    await until(()=>{observed=rustProcesses();return observed.some(row=>row.exe===binary);},
      'real Rust compiler child must execute before cancellation');
    const elapsed=await stop(state,'SIGTERM');
    await until(()=>rustProcesses().length===0,'Rust guardian must reap native compiler descendants',6000);
    assert.equal(fs.existsSync(path.join(out,'current.json')),false);
    cases.push({runtime,nativeCancellation:true,observedChildren:observed,stopMs:elapsed,noNativeOrGuardSurvivors:true});
  }
  const result={schema:'psc1-installed-watch/1',status:'passed',testedCommit:process.env.GITHUB_SHA,
    runtime:f.runtime,cases,scope:'full checked rebuilds of explicit dependencies; no incremental semantic cache'};
  fs.writeFileSync('dist/cli/watch.json',JSON.stringify(result,null,2)+'\n');
  console.log('PSC1_INSTALLED_WATCH '+JSON.stringify(result));
} finally {
  for(const state of active)state.child.kill('SIGTERM');
  fs.rmSync(f.directory,{recursive:true,force:true});
}
