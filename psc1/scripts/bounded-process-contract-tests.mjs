// Real process-tree regression: child exit, ignored TERM, inherited pipes and output overflow.
import assert from 'node:assert/strict';
import fs from 'node:fs';import os from 'node:os';import path from 'node:path';
import {compilerRequestLimit,qualificationProfile,supervisorLimit} from './selfhost-qualification-profiles.mjs';
import {spawnSync} from 'node:child_process';
import {boundedRun} from '../host-tools/generated-target-tools.mjs';
assert.equal(qualificationProfile().name,'performance-240s');
for(const profile of ['performance-240s','correctness-1800s']) {
 for(const id of ['G1-bootstrap','G1-lean-modules','G2-ps-list-literal','G3-verified','G2-self','G3-self']) {
  const expected=profile==='correctness-1800s'&&['G2-self','G3-self'].includes(id)?1800000:240000;
  assert.equal(compilerRequestLimit(profile,id).timeoutMs,expected);
 }
}
assert.throws(()=>qualificationProfile('unbounded'),/UNKNOWN_QUALIFICATION/);
assert.throws(()=>supervisorLimit(240001),/TIMEOUT_OUTSIDE/);
assert.throws(()=>supervisorLimit(1800001,'g2g3-correctness-1800s'),/TIMEOUT_OUTSIDE/);
assert.throws(()=>supervisorLimit(240000,'unknown'),/UNKNOWN_TIMEOUT/);
const root=fs.mkdtempSync(path.join(os.tmpdir(),'psc1-process-tree-'));
try{
 const simple=boundedRun('python3',['-c','print("bounded")'],{logDirectory:path.join(root,'simple'),timeoutMs:2000});
 assert.equal(simple.status,0);assert.equal(simple.stdout.trim(),'bounded');
 const extended=boundedRun('python3',['-c','print("long-profile")'],{logDirectory:path.join(root,'extended'),...compilerRequestLimit('correctness-1800s','G2-self')});
 assert.equal(extended.status,0);assert.equal(extended.timeoutMs,1800000);
 assert.ok(extended.maxRssKiB>0&&extended.peakTreeRssKiB>0);
 for(const invalid of [{timeoutMs:240001},{timeoutMs:1800001,timeoutPolicy:'g2g3-correctness-1800s'},{timeoutMs:1,timeoutPolicy:'unknown'}]) {
  const rejected=spawnSync('python3',['scripts/bounded-process.py',JSON.stringify({command:['python3','-c','print("must-not-run")'],directory:path.join(root,'refused'),...invalid})],{encoding:'utf8'});
  assert.notEqual(rejected.status,0);
  assert.equal(fs.existsSync(path.join(root,'refused','tool.stdout.txt')),false);
 }
 const pidFile=path.join(root,'descendant.pid');
 const grandchild="import os,signal,time;open("+JSON.stringify(pidFile)+",'w').write(str(os.getpid()));signal.signal(signal.SIGTERM,signal.SIG_IGN);time.sleep(60)";
 const parent="import subprocess,signal,time;subprocess.Popen(['python3','-c',"+JSON.stringify(grandchild)+"]);signal.signal(signal.SIGTERM,signal.SIG_IGN);time.sleep(60)";
 const hung=boundedRun('python3',['-c',parent],{logDirectory:path.join(root,'hung'),timeoutMs:300});
 assert.equal(hung.error.code,'ETIMEDOUT');assert.ok(hung.elapsedMs<2000);
 const pid=Number(fs.readFileSync(pidFile,'utf8'));
 let state;try{state=fs.readFileSync('/proc/'+pid+'/stat','utf8').split(' ')[2];}catch(e){assert.equal(e.code,'ENOENT');}
 assert.ok(state===undefined||state==='Z','descendant must not execute after deadline');
 const exitingParent="import subprocess;subprocess.Popen(['python3','-c',"+JSON.stringify(grandchild)+"])";
 const inherited=boundedRun('python3',['-c',exitingParent],{logDirectory:path.join(root,'inherited'),timeoutMs:500});
 assert.equal(inherited.error.code,'ETIMEDOUT');assert.ok(inherited.elapsedMs<2000);
 const escapedParent="import subprocess,signal,time;subprocess.Popen(['python3','-c',"+JSON.stringify(grandchild)+"],start_new_session=True);signal.signal(signal.SIGTERM,signal.SIG_IGN);time.sleep(60)";
 const escaped=boundedRun('python3',['-c',escapedParent],{logDirectory:path.join(root,'new-session'),timeoutMs:500,timeoutPolicy:'g2g3-correctness-1800s'});
 assert.equal(escaped.error.code,'ETIMEDOUT');
 const escapedPid=Number(fs.readFileSync(pidFile,'utf8'));
 let escapedState;try{escapedState=fs.readFileSync('/proc/'+escapedPid+'/stat','utf8').split(' ')[2];}catch(e){assert.equal(e.code,'ENOENT');}
 assert.ok(escapedState===undefined||escapedState==='Z','nested session must not survive deadline');
 const overflow=boundedRun('python3',['-c','import sys;sys.stdout.write("x"*40000000)'],{logDirectory:path.join(root,'overflow'),timeoutMs:5000});
 assert.equal(overflow.error.code,'ENOBUFS');assert.equal(Buffer.byteLength(overflow.stdout),32*1024*1024);
 console.log('PSC1_PROCESS_TREE_CONTRACT: descendants killed; deadline and 32 MiB output enforced');
}finally{fs.rmSync(root,{recursive:true,force:true});}
