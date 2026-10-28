// Final evidence gate. Reads completed CI only; never grants compiler authority.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
const receipt=JSON.parse(fs.readFileSync(process.argv[2]));
assert.equal(receipt.schema,'psc1-portable-modular-qualification/1');
assert.equal(receipt.status,'qualified-finite-linux-modular-js-ts');
const repository='dwijayuda/pskernel',headers={Authorization:'Bearer '+process.env.GH_TOKEN,
 Accept:'application/vnd.github+json','X-GitHub-Api-Version':'2022-11-28'};
assert.equal(process.env.GITHUB_REPOSITORY,repository);
async function get(route,json=true){
 const response=await fetch('https://api.github.com/repos/'+repository+route,{headers,signal:AbortSignal.timeout(120000)});
 assert.equal(response.status,200);
 const text=await response.text();assert.ok(Buffer.byteLength(text)<=33554432);
 return json?JSON.parse(text):text;
}
const production=['psc1/packages','psc1/host','psc1/host-tools','psc1/npm-cli','psc1/lakefile.lean',
 'psc1/lean-toolchain','psc1/scripts/restore-portable-g1.mjs',
 'psc1/scripts/requests/modular-selfhost.json'];
const diff=spawnSync('git',['diff','--exit-code',receipt.testedImplementationCommit,'HEAD','--',...production],
 {encoding:'utf8',maxBuffer:33554432});
assert.equal(diff.status,0,'PSC1_M5_UNTESTED_PRODUCTION_CHANGE:'+diff.stdout+diff.stderr);
const qualifiedWorkflow=spawnSync('git',['show',receipt.testedImplementationCommit+':.github/workflows/psc1-modular-generations.yml'],{encoding:'utf8'});
assert.equal(qualifiedWorkflow.status,0);
assert.equal(fs.readFileSync('../.github/workflows/psc1-modular-generations.yml','utf8'),
 qualifiedWorkflow.stdout.replace("paths: ['psc1/scripts/requests/modular-selfhost.json']",
  "paths: ['.github/psc1/modular-selfhost-run.json']"),'PSC1_M5_QUALIFIED_EXECUTION_STEPS');
const oldCli=spawnSync('git',['show',receipt.sourceGate.head+':.github/workflows/psc1-cli.yml'],{encoding:'utf8'});
assert.equal(oldCli.status,0);
assert.equal(fs.readFileSync('../.github/workflows/psc1-cli.yml','utf8'),
 oldCli.stdout.replace('timeout-minutes: 60','timeout-minutes: 90'),'PSC1_M5_RETAINED_CLI_COMMANDS');
const prior=spawnSync('git',['show',receipt.testedImplementationCommit+':psc1/EXECUTABLE_PACKAGE_CONTRACT.json'],
 {encoding:'utf8'});assert.equal(prior.status,0);
const before=JSON.parse(prior.stdout),current=JSON.parse(fs.readFileSync('EXECUTABLE_PACKAGE_CONTRACT.json'));
assert.deepEqual(current.preservation,before.preservation);assert.deepEqual(current.artifact.bounds,before.artifact.bounds);
const evidence=[];
for(const item of receipt.requiredRuns){
 const run=await get('/actions/runs/'+item.id);
 assert.equal(run.head_sha,item.commit);assert.equal(run.conclusion,'success');
 const jobs=await get('/actions/runs/'+item.id+'/jobs?per_page=100');
 assert.ok(jobs.total_count<=100);
 assert.ok(jobs.jobs.every(job=>['success','skipped'].includes(job.conclusion)));
 evidence.push({id:run.id,head:run.head_sha,conclusion:run.conclusion,
  jobs:jobs.jobs.map(job=>({id:job.id,name:job.name,conclusion:job.conclusion}))});
}
const run=await get('/actions/runs/'+receipt.generationRun);
assert.equal(run.head_sha,receipt.testedImplementationCommit);assert.equal(run.conclusion,'success');
const jobs=await get('/actions/runs/'+receipt.generationRun+'/jobs?per_page=100');
fs.mkdirSync('dist/portable-evidence',{recursive:true});
for(const engine of ['js','ts']){
 const job=jobs.jobs.find(job=>job.name==='qualification ('+engine+')');
 assert.ok(job);assert.equal(job.conclusion,'success');
 const log=await get('/actions/jobs/'+job.id+'/logs',false);
 const marker='PSC1_PORTABLE_MODULAR_SELFHOST ';
 const rows=log.split('\n').filter(line=>line.includes(marker));assert.equal(rows.length,1);
 const actual=JSON.parse(rows[0].slice(rows[0].indexOf(marker)+marker.length));
 assert.deepEqual(actual,receipt.generations[engine].report,'PSC1_M5_RECEIPT_TRANSCRIPTION:'+engine);
 assert.equal(actual.status,'passed');assert.equal(actual.nativeFrontendCalls,0);
 assert.equal(actual.fixedPoint,'exact-G1-G2-G3-graph-files-and-npm-tarballs');
 assert.equal(actual.sourceClosureDigest,receipt.sourceClosureDigest);
 assert.equal(actual.sourceCommit,receipt.sourceCommit);
 assert.equal(actual.g1ManifestSha256,receipt.portableG1Seed.manifestSha256);
 assert.deepEqual(actual.generations.map(row=>row.generation),[2,3]);
 for(const generation of actual.generations){
  assert.equal(generation.status,'qualified-generated-modular-compiler');
  assert.equal(generation.independentAdmission.accepted,true);
  assert.equal(generation.independentAdmission.checkerCommit,receipt.preservation.leanCommit);
  assert.equal(generation.fullGraphByteIdentity,true);
  assert.equal(generation.originalAndTransformedIrIdentity,true);
  assert.equal(generation.renderedNativeReferenceIdentity,true);
  assert.equal(generation.manifestSha256,actual.g1ManifestSha256);
  assert.equal(generation.packages.length,15);
 }
 assert.deepEqual(actual.generations[0].packages,actual.generations[1].packages);
 fs.writeFileSync('dist/portable-evidence/'+engine+'.json',JSON.stringify(actual,null,2)+'\n');
}
assert.deepEqual(receipt.generations.js.report.generations[0].packages,
 receipt.generations.ts.report.generations[0].packages,'PSC1_M5_CROSS_ENGINE_NPM_FIXED_POINT');
assert.equal(current.portableGenerationQualification.status,receipt.status);
assert.equal(current.portableGenerationQualification.run,receipt.generationRun);
assert.equal(current.portableGenerationQualification.sourceClosureDigest,receipt.sourceClosureDigest);
assert.equal(current.portableGenerationQualification.newRootPromoted,false);
assert.equal(current.portableGenerationQualification.performanceQualified,false);
const summary={schema:'psc1-portable-modular-final-evidence/1',status:'passed',
 testedFinalHead:process.env.GITHUB_SHA,testedImplementationCommit:receipt.testedImplementationCommit,
 sourceCommit:receipt.sourceCommit,sourceClosureDigest:receipt.sourceClosureDigest,evidence,
 exactProductionBytesPreserved:true,scope:receipt.scope,notQualified:receipt.notQualified};
fs.writeFileSync('dist/portable-evidence/final.json',JSON.stringify(summary,null,2)+'\n');
console.log('PSC1_M5_FINAL_EVIDENCE '+JSON.stringify(summary));
