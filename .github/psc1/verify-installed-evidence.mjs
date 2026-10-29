// Read-only final checkpoint: completed CI and exact tested implementation bytes.
import fs from 'node:fs';
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
const receipt=JSON.parse(fs.readFileSync('docs/PSC1_SELFHOSTED_INSTALLED_QUALIFICATION_2026-10-29.json'));
assert.equal(receipt.schema,'psc1-selfhosted-installed-qualification/1');
assert.equal(receipt.status,'qualified-finite-linux-installed-preview');
const changed=spawnSync('git',['-C','..','diff','--name-only',receipt.implementationCommit,'HEAD'],{encoding:'utf8'});
assert.equal(changed.status,0);
const allowed=new Set(['psc1/AI_WORK_STATE.md','psc1/docs/PSC1_DEVELOPMENT_ROADMAP.md',
 'psc1/docs/architecture/selfhosted-installed-toolchain.md','psc1/docs/architecture/installed-modular-toolchain.md',
 'psc1/docs/PSC1_SELFHOSTED_INSTALLED_QUALIFICATION_2026-10-29.json',
 '.github/psc1/verify-installed-evidence.mjs','.github/workflows/diagnostic-psc1-installed-evidence.yml']);
for(const file of changed.stdout.trim().split('\n').filter(Boolean))
 assert.ok(allowed.has(file),'PSC1_INSTALLED_UNTESTED_IMPLEMENTATION:'+file);
const repository='dwijayuda/pskernel';assert.equal(process.env.GITHUB_REPOSITORY,repository);
async function get(route,json=true){
 const response=await fetch('https://api.github.com/repos/'+repository+route,{headers:{
  Authorization:'Bearer '+process.env.GH_TOKEN,Accept:'application/vnd.github+json',
  'X-GitHub-Api-Version':'2022-11-28'},signal:AbortSignal.timeout(120000)});
 assert.equal(response.status,200,route);
 const text=await response.text();assert.ok(Buffer.byteLength(text)<=33554432);
 return json?JSON.parse(text):text;
}
const checked=[];
for(const input of receipt.requiredRuns){
 const run=await get('/actions/runs/'+input.id);
 assert.equal(run.head_sha,input.commit);assert.equal(run.conclusion,'success');
 const jobs=await get('/actions/runs/'+input.id+'/jobs?per_page=100');
 assert.ok(jobs.total_count<=100);
 assert.ok(jobs.jobs.every(job=>['success','skipped'].includes(job.conclusion)));
 checked.push({id:run.id,commit:run.head_sha,conclusion:run.conclusion,
  jobs:jobs.jobs.map(job=>({id:job.id,name:job.name,conclusion:job.conclusion}))});
}
const artifacts=[];
for(const pin of receipt.artifacts){
 const actual=await get('/actions/artifacts/'+pin.id);
 assert.equal(actual.expired,false);assert.equal(actual.workflow_run.id,pin.run);
 assert.equal(actual.workflow_run.head_sha,pin.commit);
 assert.equal(actual.digest,pin.digest);assert.equal(actual.size_in_bytes,pin.bytes);
 artifacts.push(pin);
}
const jobs=await get('/actions/runs/'+receipt.delivery.run+'/jobs?per_page=100');
const job=jobs.jobs.find(job=>job.name==='delivery');assert.equal(job?.conclusion,'success');
const log=await get('/actions/jobs/'+job.id+'/logs',false);
const marker='PSC1_SELFHOSTED_NPM_DELIVERY ';
const lines=log.split('\n').filter(line=>line.includes(marker+'{'));assert.equal(lines.length,1);
const actual=JSON.parse(lines[0].slice(lines[0].indexOf(marker)+marker.length));
assert.deepEqual(actual,receipt.delivery,'PSC1_INSTALLED_RECEIPT_TRANSCRIPTION');
assert.equal(actual.testedCommit,receipt.implementationCommit);
assert.equal(actual.package.sha256,receipt.package.sha256);
assert.equal(actual.freshExtractedZip.npmExecHelpInitCheckBuild,true);
assert.equal(actual.freshExtractedZip.rootOnlyOfflineInstall,true);
const result={schema:'psc1-selfhosted-installed-final-evidence/1',status:'passed',
 testedFinalHead:process.env.GITHUB_SHA,implementationCommit:receipt.implementationCommit,
 compilerSourceCommit:receipt.compilerQualification.sourceCommit,
 sourceClosureDigest:receipt.compilerQualification.sourceClosureDigest,
 packageSha256:receipt.package.sha256,zipSha256:actual.zipSha256,checked,artifacts,
 exactTestedImplementationPreserved:true,scope:receipt.scope,remaining:receipt.remaining};
fs.mkdirSync('dist/installed-final-evidence',{recursive:true});
fs.writeFileSync('dist/installed-final-evidence/final.json',JSON.stringify(result,null,2)+'\n');
console.log('PSC1_SELFHOSTED_INSTALLED_FINAL_EVIDENCE '+JSON.stringify(result));
