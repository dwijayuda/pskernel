// Diagnostic replay of the exact qualified G1 and failed G2 request. No native
// compiler or checker is built/called; a response here is never adopted.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { compilerSourceClosureDigest } from '../host-tools/compiler-host-protocol.mjs';
assert.equal(process.version,'v22.23.3');
const root=process.cwd(), inputRoot=path.resolve(process.argv[2]), directory=path.resolve(process.argv[3]);
fs.mkdirSync(directory,{recursive:true});
const sha=bytes=>crypto.createHash('sha256').update(bytes).digest('hex');
function find(directory,name) {
  return fs.readdirSync(directory,{withFileTypes:true}).flatMap(entry=>{
    const file=path.join(directory,entry.name);
    return entry.isDirectory()?find(file,name):entry.isFile()&&entry.name===name?[file]:[];
  });
}
const modules=find(inputRoot,'G1.mjs'), requests=find(inputRoot,'G1-bootstrap.request.json');
assert.equal(modules.length,1);assert.equal(requests.length,1);
const service=modules[0],serviceHash=sha(fs.readFileSync(service));
assert.equal(serviceHash,'7a1efe8d3e03e5c507d00e034651b81fa7d4062c5a459e9a356c9753aaaa531d');
const wire=JSON.parse(fs.readFileSync(requests[0],'utf8'));
assert.equal(wire.length,7);assert.equal(wire[0],'psc1-compiler-service/1');
assert.equal(wire[3],'lean');assert.equal(wire[4],'ordinary-checked');
assert.equal(wire[5],'Ps.BackendJs.CompilerService');assert.equal(wire[6].length,83);
assert.equal(compilerSourceClosureDigest(wire[6].map(([module,text])=>({module,kind:'lean',text}))),
  'e4b2904530be5ed81f7b678c345e0d634aa29ae4153a6b9122e822c16f44a3fb');
wire[1]='G2-self';
const request=JSON.stringify(wire),requestHash=sha(request);
assert.equal(requestHash,'1353995b84b1e33f3c0942a758e94a41c68dcb8f8b5fbc74d8f19fc6db73b331');
const input=path.join(directory,'request.json'),output=path.join(directory,'candidate.json');
fs.writeFileSync(input,request);
const runner=path.join(root,'scripts/generated-compiler-runner.mjs');
const args=['--prof','--logfile='+path.join(directory,'v8.log'),runner,service,serviceHash,input,output];
const start=performance.now();
const run=spawnSync(process.execPath,args,{cwd:root,encoding:'utf8',timeout:240000,
  maxBuffer:32*1024*1024});
fs.writeFileSync(path.join(directory,'process.stdout.txt'),run.stdout||'');
fs.writeFileSync(path.join(directory,'process.stderr.txt'),run.stderr||'');
assert.equal(sha(fs.readFileSync(service)),serviceHash);
assert.equal(sha(fs.readFileSync(input)),requestHash);
const receipt={schema:'psc1-qualified-g1-cpu-profile/1',commit:process.env.GITHUB_SHA,
  qualifiedG1Run:39543944316,qualifiedArtifact:12320558486,failedRequestRun:39545154962,
  serviceSha256:serviceHash,requestSha256:requestHash,node:process.version,
  nodeSha256:sha(fs.readFileSync(process.execPath)),runnerSha256:sha(fs.readFileSync(runner)),
  args,status:run.status,signal:run.signal,error:run.error?.message||null,
  elapsedMs:Math.round(performance.now()-start),timeoutMs:240000,
  nativeCompilerDelegation:false,admission:'not-run',publication:'not-run',
  G2Qualification:false,scope:'CPU sampled exact failed self-compilation; no stack/heap/process-limit increase'};
const logs=fs.readdirSync(directory).filter(name=>name.endsWith('.log'));
receipt.v8Logs=logs.map(name=>({path:name,bytes:fs.statSync(path.join(directory,name)).size}));
for (const [index,name] of logs.entries()) {
  const processed=spawnSync(process.execPath,['--prof-process',path.join(directory,name)],
    {encoding:'utf8',timeout:240000,maxBuffer:32*1024*1024});
  fs.writeFileSync(path.join(directory,'profile-'+index+'.txt'),processed.stdout||'');
  fs.writeFileSync(path.join(directory,'profile-'+index+'.stderr.txt'),processed.stderr||'');
  console.log('PSC1_G2_CPU_PROFILE_SUMMARY: '+(processed.stdout||'').split('\n').slice(0,100).join('\n'));
}
fs.writeFileSync(path.join(directory,'receipt.json'),JSON.stringify(receipt,null,2)+'\n');
console.log('PSC1_G2_CPU_PROFILE: '+JSON.stringify(receipt));
console.log('PSC1_G2_STDERR_TAIL: '+(run.stderr||'').slice(-6000));
assert.ok(logs.length>0,'must retain actual V8 sample data');
// A green collection step is diagnostic completion, never G2 qualification.
