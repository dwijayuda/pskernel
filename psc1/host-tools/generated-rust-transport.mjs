// Synchronous adapter for an independently qualified, immutable Rust compiler.
import fs from 'node:fs';import path from 'node:path';import os from 'node:os';import crypto from 'node:crypto';
import assert from 'node:assert/strict';import {spawnSync} from 'node:child_process';import {fileURLToPath} from 'node:url';
import {linuxProcessIdentity} from './generated-rust-guard.mjs';
import {requireSupportedRuntime,runtimeArguments} from './runtime-policy.mjs';
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
const guard=fileURLToPath(new URL('./generated-rust-guard.mjs',import.meta.url)),MAX=128*1024*1024;
export function runGeneratedRustCompiler({executable,executableSha256,request,timeoutMs=240000}){
 requireSupportedRuntime();assert.equal(process.platform,'linux');
 assert.ok(path.isAbsolute(executable));assert.match(executableSha256,/^[a-f0-9]{64}$/);
 assert.equal(typeof request,'string');assert.ok(Buffer.byteLength(request)<=MAX);
 assert.ok(Number.isSafeInteger(timeoutMs)&&timeoutMs>0&&timeoutMs<=240000);
 const parentStart=linuxProcessIdentity(process.pid);assert.ok(parentStart,'PSC1_RUST_PARENT_IDENTITY');
 const directory=fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()),'psc1-rust-request-'));fs.chmodSync(directory,0o700);
 const input=path.join(directory,'request.json'),output=path.join(directory,'response.json');fs.writeFileSync(input,request);
 try{
  // The independent guard survives an outer caller kill long enough to reap the
  // whole compiler process group. The ordinary compiler budget stays240s.
  const child=spawnSync(process.execPath,runtimeArguments([guard,String(process.pid),parentStart,executable,executableSha256,input,output,String(timeoutMs)]),
   {encoding:'utf8',maxBuffer:1024*1024,stdio:['ignore','pipe','pipe']});
  assert.equal(child.error,undefined,child.error?.message);
  assert.equal(child.status,0,'PSC1_RUST_COMPILER_FAILED: '+(child.stderr||child.stdout));
  const event=JSON.parse(child.stdout);assert.equal(event.protocol,'psc1-rust-host-run/1');
  assert.equal(event.binarySha256,executableSha256);assert.equal(event.requestSha256,sha(request));
  const stat=fs.lstatSync(output);assert.ok(stat.isFile()&&!stat.isSymbolicLink()&&stat.size<=MAX);
  const bytes=fs.readFileSync(output);assert.equal(sha(bytes),event.responseSha256);
  return new TextDecoder('utf-8',{fatal:true,ignoreBOM:true}).decode(bytes);
 }finally{
  // The unique directory belongs to this request, never a generated path.
  if(fs.existsSync(directory)){assert.equal(fs.realpathSync(directory),directory);assert.equal(path.dirname(directory),fs.realpathSync(os.tmpdir()));fs.rmSync(directory,{recursive:true});}
 }
}
