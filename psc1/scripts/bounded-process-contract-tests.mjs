// Real process-tree regression: child exit, ignored TERM, inherited pipes and output overflow.
import assert from 'node:assert/strict';
import fs from 'node:fs';import os from 'node:os';import path from 'node:path';
import {boundedRun} from '../host-tools/generated-target-tools.mjs';
const root=fs.mkdtempSync(path.join(os.tmpdir(),'psc1-process-tree-'));
try{
 const simple=boundedRun('python3',['-c','print("bounded")'],{logDirectory:path.join(root,'simple'),timeoutMs:2000});
 assert.equal(simple.status,0);assert.equal(simple.stdout.trim(),'bounded');
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
 const overflow=boundedRun('python3',['-c','import sys;sys.stdout.write("x"*40000000)'],{logDirectory:path.join(root,'overflow'),timeoutMs:5000});
 assert.equal(overflow.error.code,'ENOBUFS');assert.equal(Buffer.byteLength(overflow.stdout),32*1024*1024);
 console.log('PSC1_PROCESS_TREE_CONTRACT: descendants killed; deadline and 32 MiB output enforced');
}finally{fs.rmSync(root,{recursive:true,force:true});}
