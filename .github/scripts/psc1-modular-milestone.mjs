// Verify evidence adoption without rebuilding or replacing the qualified compiler.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
const root=path.resolve('..'),repo=process.env.GITHUB_REPOSITORY;
const receipt=JSON.parse(fs.readFileSync('docs/PSC1_MODULAR_INSTALLED_QUALIFICATION_2026-10-28.json','utf8'));
const contract=JSON.parse(fs.readFileSync('EXECUTABLE_PACKAGE_CONTRACT.json','utf8'));
const git=(args)=>{const r=spawnSync('git',['-C',root,...args],{encoding:'utf8',maxBuffer:16*1024*1024});assert.equal(r.status,0,r.stderr);return r.stdout;};
assert.equal(receipt.status,'qualified-finite-linux-preview');
assert.equal(receipt.implementationCommit,'ca92bbdbc7c0f34e1da4076db7300033802eab3e');
assert.equal(contract.installedPreview.qualifiedCommit,receipt.implementationCommit);
assert.equal(contract.installedPreview.extendedQualification,receipt.status);
assert.equal(contract.installedPreview.fullModularSelfHosting,false);
assert.equal(contract.noNewModularCompilerQualification,true);
assert.equal(contract.noMerge,true);assert.equal(contract.noRegistryPublication,true);
const changes=git(['diff','--name-only','--no-renames',receipt.implementationCommit,'HEAD','--','psc1/']).trim().split('\n').filter(Boolean);
for(const file of changes)assert.ok(file==='psc1/AI_WORK_STATE.md'||file==='psc1/EXECUTABLE_PACKAGE_CONTRACT.json'||file.startsWith('psc1/docs/'),'unqualified production change: '+file);
const diagnostic='1ce58717ee9565d1e52fbff2566721d7c30c1654';
const adopted=git(['diff','--name-only',receipt.implementationCommit,diagnostic]).trim().split('\n').filter(Boolean);
assert.equal(adopted.length,12);
for(const file of adopted){
 assert.ok(file.startsWith('.github/scripts/')||file.startsWith('.github/workflows/diagnostic-'));
 assert.equal(fs.readFileSync(path.join(root,file),'utf8'),git(['show',diagnostic+':'+file]),'diagnostic adoption drift: '+file);
 if(file.endsWith('.mjs')){const r=spawnSync(process.execPath,['--check',path.join(root,file)],{encoding:'utf8'});assert.equal(r.status,0,r.stderr);}
}
const get=async suffix=>{const response=await fetch('https://api.github.com/repos/'+repo+suffix,{
 headers:{Authorization:'Bearer '+process.env.GH_TOKEN,Accept:'application/vnd.github+json'},redirect:'error'});
 assert.equal(response.status,200,'GitHub evidence unavailable: '+suffix);return response.json();};
const groups=[
 [receipt.qualification.run,receipt.implementationCommit,receipt.qualification.artifacts],
 [receipt.diagnostics.run,receipt.diagnostics.commit,receipt.diagnostics.artifacts],
 [receipt.applications.run,receipt.applications.commit,receipt.applications.artifacts],
 [receipt.delivery.artifacts[0].url.match(/runs\/(\d+)/)[1],receipt.delivery.testedCommit,receipt.delivery.artifacts],
 [receipt.retainedRegressions.source.run,receipt.implementationCommit,[]],
 [receipt.retainedRegressions.legacyCli.run,receipt.implementationCommit,[]]
];
for(const [id,commit,artifacts]of groups){
 const run=await get('/actions/runs/'+id);assert.equal(run.status,'completed');assert.equal(run.conclusion,'success');assert.equal(run.head_sha,commit);
 const jobs=await get('/actions/runs/'+id+'/jobs?per_page=100');
 assert.ok(jobs.jobs.every(j=>j.status==='completed'&&['success','skipped'].includes(j.conclusion)));
 if(artifacts.length){const actual=await get('/actions/runs/'+id+'/artifacts?per_page=100');
  for(const a of artifacts){const found=actual.artifacts.find(x=>x.id===a.id);assert.ok(found,'missing artifact '+a.id);assert.equal(found.expired,false);assert.equal(found.size_in_bytes,a.bytes);assert.equal(found.digest,'sha256:'+a.sha256);}
 }
 console.log('PSC1_M4_EVIDENCE '+JSON.stringify({run:id,commit,status:run.conclusion,jobs:jobs.jobs.length,artifacts:artifacts.length}));
}
assert.equal(receipt.applications.checkedBuilds,32);assert.equal(receipt.applications.behaviorCases,528);
for(const host of ['node','bun']){
 const app=receipt.applications.hosts[host];assert.equal(app.status,'passed');assert.equal(app.builds,16);assert.equal(app.behaviorCases,264);
 assert.equal(app.records.reduce((n,x)=>n+x.behaviorCases,0),264);
 const q=receipt.qualification.hosts[host];assert.equal(q.status,'passed');assert.equal(q.checkedBuilds,64);assert.equal(q.refusals,10);
 assert.equal(q.fullCompilerWasmAdmissionSha256,receipt.package.compilerAdmissionsSha256);
 assert.equal(q.globalRootOnlyCheckAndBuild,true);assert.equal(q.watchCases,9);
}
console.log('PSC1_MODULAR_MILESTONE '+JSON.stringify({status:'passed-evidence-checkpoint',head:process.env.GITHUB_SHA,implementationCommit:receipt.implementationCommit,productionChanges:0,adoptedFiles:adopted.length,fullModularSelfHosting:false}));

