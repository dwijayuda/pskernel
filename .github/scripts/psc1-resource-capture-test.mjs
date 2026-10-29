// Integrity regressions for setup-only deduplication and the Linux executable optimization.
import fs from'node:fs';import path from'node:path';import os from'node:os';import assert from'node:assert/strict';import{spawnSync}from'node:child_process';import{pathToFileURL}from'node:url';
import{captureResourceSetup,resourceDigest}from'../../psc1/host-tools/resource-capture.mjs';
const dir=fs.mkdtempSync(path.join(os.tmpdir(),'psc1-resource-capture-'));
try{
 const file=path.join(dir,'mutable');fs.writeFileSync(file,'first');const first=resourceDigest(file);
 const captured=captureResourceSetup(()=>{const a=resourceDigest(file);fs.writeFileSync(file,'other');const b=resourceDigest(file);assert.equal(a,b);return b;});
 assert.equal(captured.value,first);assert.notEqual(resourceDigest(file),first);
 assert.equal(captured.metrics.duplicateReadsAvoided,1);
 assert.throws(()=>captureResourceSetup(()=>{throw Error('reset');}),/reset/);
 fs.writeFileSync(file,'third');assert.notEqual(resourceDigest(file),captured.value);
 const clone=path.join(dir,'node-copy');fs.copyFileSync(process.execPath,clone);fs.chmodSync(clone,0o755);
 const module=pathToFileURL(path.resolve('host-tools/running-executable.mjs')).href;
 const digestModule=pathToFileURL(path.resolve('host-tools/resource-capture.mjs')).href;
 const body="import fs from'node:fs';import assert from'node:assert/strict';import{runningExecutableIdentity}from"+JSON.stringify(module)+";import{resourceDigest}from"+JSON.stringify(digestModule)+";const before=resourceDigest(process.execPath),hit=runningExecutableIdentity(process.execPath);if(hit){assert.equal(hit.sha256,before);assert.throws(()=>fs.openSync(process.execPath,fs.constants.O_WRONLY),{code:'ETXTBSY'});}const bytes=fs.readFileSync(process.execPath);bytes[bytes.length-1]^=1;const replacement=process.execPath+'.replacement';fs.writeFileSync(replacement,bytes,{mode:0o755});fs.renameSync(replacement,process.execPath);assert.equal(runningExecutableIdentity(process.execPath),undefined);assert.notEqual(resourceDigest(process.execPath),before);console.log(JSON.stringify({cacheAvailable:!!hit,replacementDetected:true,filesystem:fs.statfsSync(process.execPath).type}));";
 const result=spawnSync(clone,['--input-type=module','-e',body],{encoding:'utf8',timeout:120000,maxBuffer:1048576});assert.equal(result.error,undefined);assert.equal(result.status,0,result.stdout+result.stderr);
 console.log('PSC1_RESOURCE_CAPTURE_TEST '+JSON.stringify({status:'passed',freshOutsideSetup:true,exceptionClearsCapture:true,runningExecutable:JSON.parse(result.stdout)}));
}finally{fs.rmSync(dir,{recursive:true,force:true});}
