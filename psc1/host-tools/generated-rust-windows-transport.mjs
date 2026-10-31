// Windows native candidate transport, with a pinned Job Object supervisor.
// Trusted host configuration selects executables. Requests only contain data.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import crypto from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {requireSupportedRuntime} from './runtime-policy.mjs';
const MAX=128*1024*1024;
const sha=bytes=>crypto.createHash('sha256').update(bytes).digest('hex');
function read(file,limit){
  const stat=fs.lstatSync(file);
  assert.ok(stat.isFile()&&!stat.isSymbolicLink()&&stat.size>0&&stat.size<=limit,'PSC1_WINDOWS_RESOURCE_KIND');
  const bytes=fs.readFileSync(file);
  assert.equal(bytes.length,stat.size,'PSC1_WINDOWS_RESOURCE_CHANGED');
  return bytes;
}
export function runGeneratedRustWindowsCompiler({executable,executableSha256,guard,guardSha256,request,timeoutMs=240000}){
  requireSupportedRuntime();assert.equal(process.platform,'win32');assert.equal(process.arch,'x64');
  for(const file of [executable,guard])assert.ok(typeof file==='string'&&path.isAbsolute(file));
  for(const hash of [executableSha256,guardSha256])assert.match(hash,/^[a-f0-9]{64}$/);
  assert.equal(typeof request,'string');assert.ok(Buffer.byteLength(request)>0&&Buffer.byteLength(request)<=MAX);
  assert.ok(Number.isSafeInteger(timeoutMs)&&timeoutMs>0&&timeoutMs<=240000);
  const verify=()=>{
    assert.equal(sha(read(executable,MAX)),executableSha256,'PSC1_WINDOWS_COMPILER_IDENTITY');
    assert.equal(sha(read(guard,16*1024*1024)),guardSha256,'PSC1_WINDOWS_GUARD_IDENTITY');
  };
  verify();
  const temporaryRoot=fs.realpathSync(os.tmpdir());
  const directory=fs.mkdtempSync(path.join(temporaryRoot,'psc1-rust-request-'));
  const input=path.join(directory,'request.json'),output=path.join(directory,'response.json');
  fs.writeFileSync(input,request,{flag:'wx'});const requestSha256=sha(request);
  const env={...process.env};
  for(const key of Object.keys(env))if(key==='NODE_OPTIONS'||key.startsWith('RUST')||key.startsWith('CARGO')||key.startsWith('LD_')||key.startsWith('DYLD_'))delete env[key];
  try{
    // The helper owns a kill-on-close Windows Job Object and watches this exact
    // parent's handle/creation time. It enforces the original deadline itself.
    // The outer guard timeout is cleanup protection, not an execution extension.
    const result=spawnSync(guard,[String(process.pid),String(timeoutMs),executable,input,output],{
      cwd:directory,env,encoding:'utf8',timeout:timeoutMs+10000,
      maxBuffer:32*1024*1024,stdio:['ignore','pipe','pipe'],windowsHide:true,killSignal:'SIGKILL',shell:false,
    });
    verify();
    assert.equal(result.error,undefined,'PSC1_WINDOWS_COMPILER_PROCESS:'+String(result.error));
    assert.equal(result.status,0,'PSC1_WINDOWS_COMPILER_FAILED:'+(result.stderr||result.stdout));
    assert.equal(sha(read(input,MAX)),requestSha256,'PSC1_WINDOWS_REQUEST_CHANGED');
    return new TextDecoder('utf-8',{fatal:true,ignoreBOM:true}).decode(read(output,MAX));
  }finally{
    if(fs.existsSync(directory)){
      assert.equal(fs.realpathSync(directory),directory);
      assert.equal(path.dirname(directory),temporaryRoot);
      fs.rmSync(directory,{recursive:true,force:true,maxRetries:10,retryDelay:50});
    }
  }
}
