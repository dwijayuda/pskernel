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
assert.equal(serviceHash,'5d30b5552896fbe4f90eadc7cc71564a61bec7f586a6ef4f38deedfeb8456f6f');
const wire=JSON.parse(fs.readFileSync(requests[0],'utf8'));
assert.equal(wire.length,7);assert.equal(wire[0],'psc1-compiler-service/1');
assert.equal(wire[3],'lean');assert.equal(wire[4],'ordinary-checked');
assert.equal(wire[5],'Ps.BackendJs.CompilerService');assert.equal(wire[6].length,84);
assert.equal(compilerSourceClosureDigest(wire[6].map(([module,text])=>({module,kind:'lean',text}))),
  'feef9c744743a4a1c34c46424491826c13823ff3ef537473fb26ce4b2fe97443');
wire[1]='G2-self';
const request=JSON.stringify(wire),requestHash=sha(request);
assert.equal(requestHash,'4c61b3c17d8ef2591eb473f69afca9a6748c6d1b7d8bd999de9d3e8e841e345f');
const bootstrapFiles=find(inputRoot,'G1-bootstrap.candidate.json');
assert.equal(bootstrapFiles.length,1);
const bootstrap=JSON.parse(fs.readFileSync(bootstrapFiles[0],'utf8'));
assert.equal(sha(bootstrap.source),serviceHash);
assert.equal(sha(JSON.stringify(bootstrap.originalIr)),'ac8baeda7e847bb77edff590e6951730f7113740552f48b3a777ed12dabf1e23');
assert.equal(sha(JSON.stringify(bootstrap.specializedIr)),'71e18f6dce4476b44cd1e9c5e6e13801409425a6673ed2a0751b0c67a143ce14');
for (const lane of ['originalIr','specializedIr']) {
  for (const name of ['psJsonStringCharsAccWithFuel','psJsonStringToChars']) {
    const declaration=bootstrap[lane][4].find(row=>row[0]===name);
    assert.ok(declaration);
    console.log('PSC1_WORKER_IR_CONTEXT: '+JSON.stringify({lane,name,declaration}));
  }
}
const sourceLines=fs.readFileSync(service,'utf8').split('\n');
for (const line of sourceLines.filter(line=>line.includes('psJsonStringCharsAccWithFuel$worker') ||
    line.startsWith('function psJsonStringCharsAccWithFuel(') ||
    line.includes('__ps$impl$psJsonStringCharsAccWithFuel') ||
    line.startsWith('function __ps$run') || line.startsWith('function __ps$wrap')))
  console.log('PSC1_WORKER_JS_CONTEXT: '+line.slice(0,16000));
if(process.argv[4]==='--inspect-only') {
  console.log('PSC1_WORKER_CONTEXT_INSPECTED: exact qualified graph/code; no compiler execution');
  process.exit(0);
}
const input=path.join(directory,'request.json'),output=path.join(directory,'candidate.json');
fs.writeFileSync(input,request);
const runner=path.join(root,'host-tools/execution/generated-service-runner.mjs');
const args=['--prof','--logfile='+path.join(directory,'v8.log'),runner,service,serviceHash,input,output];
const start=performance.now();
const run=spawnSync(process.execPath,args,{cwd:root,encoding:'utf8',timeout:240000,
  maxBuffer:32*1024*1024});
fs.writeFileSync(path.join(directory,'process.stdout.txt'),run.stdout||'');
fs.writeFileSync(path.join(directory,'process.stderr.txt'),run.stderr||'');
assert.equal(sha(fs.readFileSync(service)),serviceHash);
assert.equal(sha(fs.readFileSync(input)),requestHash);
const receipt={schema:'psc1-qualified-g1-cpu-profile/1',commit:process.env.GITHUB_SHA,
  qualifiedG1Run:39557245225,qualifiedArtifact:12326192682,failedRequestRun:39551686967,
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
