// CPU sample of the actual modular compiler/self-source request. No adoption.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {verify} from '../../psc1/host-tools/executable/verify.mjs';
import {sha256,json,put} from '../../psc1/host-tools/executable/tools.mjs';
import {readOwnedCompilerSources} from '../../psc1/host-tools/compiler-source-inputs.mjs';
const engine=process.argv[2];assert.ok(['js','ts'].includes(engine));
const base=path.resolve('dist/portable-modules'),input=JSON.parse(fs.readFileSync(path.join(base,'input.json')));
assert.deepEqual(readOwnedCompilerSources('Ps.CompilerUnified.Service'),input.sourceRows.map(({module,path,text})=>({module,path,text})));
const directory=path.join(base,'cpu-profile-'+engine);fs.mkdirSync(directory);
const manifestFile=path.join(base,input.g1.manifest),root=path.join(base,input.g1.root);
verify(root,fs.readFileSync(manifestFile),input.g1.manifestSha256);
const config=path.join(directory,'request-config.json');
put(config,json({engine:{root,manifestFile,manifestSha256:input.g1.manifestSha256,variant:engine},
 requestFile:path.join(base,input.requestFile),directory:path.join(directory,'candidate')}));
const flags=['--max-old-space-size=4096','--stack-size=8192'];
const args=['--prof','--logfile='+path.join(directory,'v8.log')];
const command=['/usr/bin/prlimit','--stack=8388608','--',process.execPath,...flags,...args,
 path.resolve('host-tools/executable/generation-runner.mjs'),config];
const execute=spawnSync('python3',[path.resolve('host-tools/process/bounded-process.py'),JSON.stringify({
 command,directory:path.join(directory,'process'),timeoutMs:240000,timeoutPolicy:'standard-240s',maxBuffer:33554432})],
 {encoding:'utf8',timeout:245000,maxBuffer:33554432});
assert.equal(execute.error,undefined);assert.equal(execute.status,0,execute.stderr);
const execution=JSON.parse(execute.stdout);
const logs=fs.readdirSync(directory).filter(name=>name.endsWith('.log'));
assert.ok(logs.length>0);
for(const [index,name]of logs.entries()){
 const result=spawnSync(process.execPath,[...flags,'--prof-process',path.join(directory,name)],
  {encoding:'utf8',timeout:240000,maxBuffer:33554432});
 fs.writeFileSync(path.join(directory,'profile-'+index+'.txt'),result.stdout||'');
 fs.writeFileSync(path.join(directory,'profile-'+index+'.stderr.txt'),result.stderr||'');
 assert.equal(result.error,undefined);assert.equal(result.status,0,result.stderr);
 console.log('PSC1_MODULAR_CPU_SUMMARY '+engine+'\n'+result.stdout.split('\n').slice(0,180).join('\n'));
}
const receipt={schema:'psc1-modular-self-source-cpu-profile/1',status:'diagnostic-collected',
 testedCommit:process.env.GITHUB_SHA,sourceCommit:input.sourceCommit,sourceClosureDigest:input.reference.sourceClosureDigest,
 engine,g1ManifestSha256:input.g1.manifestSha256,requestSha256:sha256(fs.readFileSync(path.join(base,input.requestFile))),
 execution,logs:logs.map(name=>({path:name,bytes:fs.statSync(path.join(directory,name)).size})),
 limits:'canonical 240s wall clock,4096MiB heap,8MiB stack; no introduced CPU cap',
 G2Qualification:false,admission:'not-run',publication:'not-run',nativeFrontendCalls:0};
fs.writeFileSync(path.join(directory,'receipt.json'),json(receipt));
console.log('PSC1_MODULAR_CPU_PROFILE '+JSON.stringify(receipt));
