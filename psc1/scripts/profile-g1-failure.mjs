// Sample one retained failed normal G1 request. Diagnostic results never publish.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
assert.equal(process.version,'v22.23.3');
const root=path.resolve('dist/generated-compiler');
const sha=bytes=>crypto.createHash('sha256').update(bytes).digest('hex');
function failures(directory){
 if(!fs.existsSync(directory))return [];
 return fs.readdirSync(directory,{withFileTypes:true}).flatMap(entry=>{
  const file=path.join(directory,entry.name);
  if(entry.isDirectory())return failures(file);
  if(!entry.isFile()||entry.name!=='failure.json')return [];
  const value=JSON.parse(fs.readFileSync(file,'utf8'));
  return value.failure?.startsWith('PSC1_SERVICE_PROCESS_FAILED:generated-compiler:')
   ? [{directory,value}]:[];
 });
}
const found=failures(path.join(root,'publication'));
if(!found.length){
 console.log('PSC1_G1_FAILURE_PROFILE: no failed generated-process request; no replay');
 process.exit(0);
}
const failure=found[0],service=path.join(root,'G1.mjs');
const serviceBytes=fs.readFileSync(service),requestBytes=fs.readFileSync(path.join(failure.directory,'request.json'));
assert.equal(sha(serviceBytes),failure.value.request.serviceSha256);
assert.equal(sha(requestBytes),failure.value.request.requestSha256);
const directory=path.join(root,'failure-cpu-profile');
fs.mkdirSync(directory,{recursive:true});
const input=path.join(directory,'request.json'),output=path.join(directory,'diagnostic-candidate.json');
fs.writeFileSync(input,requestBytes,{flag:'wx'});
const runner=path.resolve('scripts/generated-compiler-runner.mjs');
const args=['--prof','--logfile='+path.join(directory,'v8.log'),runner,service,sha(serviceBytes),input,output];
const start=performance.now();
const result=spawnSync(process.execPath,args,{encoding:'utf8',timeout:240000,maxBuffer:32*1024*1024});
fs.writeFileSync(path.join(directory,'stdout.txt'),result.stdout||'');
fs.writeFileSync(path.join(directory,'stderr.txt'),result.stderr||'');
assert.equal(sha(fs.readFileSync(service)),sha(serviceBytes));
assert.equal(sha(fs.readFileSync(input)),sha(requestBytes));
assert.equal(sha(fs.readFileSync(path.join(failure.directory,'request.json'))),sha(requestBytes));
const logs=fs.readdirSync(directory).filter(name=>name.endsWith('.log'));
const receipt={schema:'psc1-normal-g1-failure-cpu-profile/1',
 testedCommit:process.env.GITHUB_SHA,branchHeadCommit:process.env.PSC1_BRANCH_HEAD,
 requestId:failure.value.request.requestId,serviceSha256:sha(serviceBytes),requestSha256:sha(requestBytes),
 runnerSha256:sha(fs.readFileSync(runner)),nodeSha256:sha(fs.readFileSync(process.execPath)),
 status:result.status,signal:result.signal,error:result.error?.message||null,
 elapsedMs:Math.round(performance.now()-start),timeoutMs:240000,
 originalFailure:failure.value.failure,logs:logs.map(name=>({name,bytes:fs.statSync(path.join(directory,name)).size})),
 nativeCompilerDelegation:false,admission:'not-run',publication:'not-run',G2Qualification:false,
 scope:'Exact failed small normal G1 case; diagnostic response is never adopted; original gate remains failed.'};
for(const [index,name] of logs.entries()){
 const processed=spawnSync(process.execPath,['--prof-process',path.join(directory,name)],
  {encoding:'utf8',timeout:60000,maxBuffer:32*1024*1024});
 fs.writeFileSync(path.join(directory,'profile-'+index+'.txt'),processed.stdout||'');
 fs.writeFileSync(path.join(directory,'profile-'+index+'.stderr.txt'),processed.stderr||'');
 console.log('PSC1_G1_CPU_PROFILE_SUMMARY: '+(processed.stdout||'').split('\n').slice(0,110).join('\n'));
}
fs.writeFileSync(path.join(directory,'receipt.json'),JSON.stringify(receipt,null,2)+'\n');
console.log('PSC1_G1_FAILURE_PROFILE: '+JSON.stringify(receipt));
assert.ok(logs.length,'retain actual sampled V8 data');
