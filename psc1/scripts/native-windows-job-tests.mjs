// Test the real compiled Job Object guard with native process descendants.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import crypto from 'node:crypto';
import {spawn,spawnSync} from 'node:child_process';
import {pathToFileURL} from 'node:url';
import {setTimeout as pause} from 'node:timers/promises';
export async function testWindowsJob({packageRoot,selected,fixturesDirectory,env}){
  assert.equal(process.platform,'win32');
  const adapter=path.join(packageRoot,'dist/host-tools/generated-rust-windows-transport.mjs');
  const {runGeneratedRustWindowsCompiler:execute}=await import(pathToFileURL(adapter).href);
  const guard=path.join(packageRoot,...selected.guardPath.split('/'));
  const executable=path.join(fixturesDirectory,'native-windows-fixture.exe');
  const digest=file=>crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
  const base={guard,guardSha256:digest(guard),executable,executableSha256:digest(executable)};
  const dir=fs.mkdtempSync(path.join(os.tmpdir(),'psc1 windows lifecycle λ '));
  const gone=pid=>{const r=spawnSync(executable,['--probe',String(pid)],{env,encoding:'utf8',timeout:5000,windowsHide:true});assert.equal(r.error,undefined);return r.status===0;};
  async function requireGone(file){
    assert.ok(fs.existsSync(file),'fixture child did not start');const pid=Number(fs.readFileSync(file,'utf8'));assert.ok(pid>0);
    for(let i=0;i<100;i++){if(gone(pid))return;await pause(50);}
    assert.fail('Windows guard left a live descendant '+pid);
  }
  let child;
  try{
    assert.equal(execute({...base,request:'fast',timeoutMs:3000}),'{}');
    assert.throws(()=>execute({...base,request:'hang',timeoutMs:500}),/DEADLINE/);
    const deadlineMarker=path.join(dir,'deadline.pid');
    assert.throws(()=>execute({...base,request:'spawn\n'+deadlineMarker,timeoutMs:3000}),/DEADLINE/);
    await requireGone(deadlineMarker);
    const successMarker=path.join(dir,'success.pid');
    assert.equal(execute({...base,request:'spawn-success\n'+successMarker,timeoutMs:5000}),'{}');
    await requireGone(successMarker);
    const parentMarker=path.join(dir,'parent.pid'),worker=path.join(dir,'worker.mjs');
    fs.writeFileSync(worker,'import {runGeneratedRustWindowsCompiler as run} from '+JSON.stringify(pathToFileURL(adapter).href)+';\nrun('+JSON.stringify({...base,request:'spawn\n'+parentMarker,timeoutMs:60000})+');\n');
    child=spawn(process.execPath,[worker],{env,stdio:'ignore',windowsHide:true});
    for(let i=0;i<200&&!fs.existsSync(parentMarker);i++){assert.equal(child.exitCode,null,'parent worker exited early');await pause(50);}
    assert.ok(fs.existsSync(parentMarker),'parent exit fixture did not start');
    child.kill('SIGKILL');
    await requireGone(parentMarker);
    assert.throws(()=>execute({...base,request:'overflow',timeoutMs:10000}),/PROCESS|FAILED/);
    return {passed:true,cases:['windows-deadline-refusal','windows-deadline-descendant-cleanup','windows-success-descendant-cleanup','windows-parent-exit-cleanup','windows-output-bound-refusal']};
  }finally{
    if(child&&child.exitCode===null)child.kill('SIGKILL');
    fs.rmSync(dir,{recursive:true,force:true,maxRetries:20,retryDelay:100});
  }
}
