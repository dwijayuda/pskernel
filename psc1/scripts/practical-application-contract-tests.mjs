import assert from 'node:assert/strict';
import fs from 'node:fs';
import crypto from 'node:crypto';
import {deriveReadiness} from './practical-core-readiness.mjs';
import {checkPracticalApplications} from './check-practical-applications.mjs';
const c=JSON.parse(fs.readFileSync(new URL('../docs/PSC1_APPLICATION_EXECUTION_CONTRACT.json',import.meta.url)));
const h='a'.repeat(64),commit='b'.repeat(40),sha=s=>crypto.createHash('sha256').update(s).digest('hex');
const receipt={schema:'psc1-practical-application-execution/1',contract:c.id,testedCommit:commit,
 checkerCommit:c.checkerCommit,targets:c.targets,passed:true,failures:[],
 records:c.grammars.flatMap(syntax=>c.targets.map(target=>({
  syntax,target,passed:true,runtime:'executed',hostEffects:true,admission:'independent-official-Lean',checkerCommit:c.checkerCommit,
  strictIr:'required-by-production-publication',moduleSha256:{Args:h,Program:h,Transform:h},hostCargoLockSha256:h,
  ...Object.fromEntries(['sourceSha256','librarySha256','artifactSha256','manifestSha256','kernelAdmissionSha256','sourceClosureSha256','oracleSha256'].map(k=>[k,h])),
  cases:c.cases.map(x=>({id:x.id,passed:true,exitCode:x.exitCode,stdoutSha256:sha(x.stdout),stderrSha256:h,outputSha256:sha(x.output??'previous'),preservedPrevious:x.output===undefined}))
 })))};
checkPracticalApplications(c,receipt,{commit});
for(const change of [
 x=>x.testedCommit='c'.repeat(40),x=>x.records.pop(),x=>x.records.push(x.records[0]),
 x=>x.records[0].cases.pop(),x=>x.records[0].cases.push(x.records[0].cases[0]),
 x=>x.records[0].cases[0].exitCode=99,x=>x.records[0].cases[0].stdoutSha256=h,
 x=>x.records[0].cases.find(c=>c.id==='unicode-records').outputSha256=h,
 x=>x.records[0].cases.find(c=>c.id==='malformed-json').outputSha256=h,
 x=>x.records[0].runtime='skipped',x=>x.records[0].sourceClosureSha256=null,
 x=>x.records[0].cases.find(c=>c.id==='malformed-json').preservedPrevious=false
]){
 const bad=structuredClone(receipt);change(bad);
 assert.throws(()=>checkPracticalApplications(c,bad,{commit}));
}
const subset={...receipt,targets:['js'],records:receipt.records.filter(r=>r.target==='js')};
checkPracticalApplications(c,subset,{commit,targets:['js']});
assert.throws(()=>checkPracticalApplications(c,subset,{commit}));
console.log('PSC1_APPLICATION_CONTRACT: PASS stale, missing, duplicate, skipped, wrong exit/console and lost output refuse');

const release=JSON.parse(fs.readFileSync(new URL('../docs/PSC1_PRACTICAL_CORE_V1_CONTRACT.json',import.meta.url)));
const full={schema:'psc1-seven-backend-qualification/1',testedCommit:commit,qualification:'passed-scoped-execution',
 assurance:{checked:true,explicitOrdinary:true,verifiedRequest:'refused'}};
const report=deriveReadiness(release,{commit,practicalApplications:receipt,applicationContract:c,fullQualification:full});
assert.deepEqual(report.applications.filter(a=>a.status==='qualified').map(a=>a.id),['cli','json-files']);
assert.equal(report.releaseReady,false);assert.ok(report.applications.filter(a=>a.id==='compiler-like'||a.id==='multi-module-library').every(a=>a.status==='blocked'));
assert.equal(deriveReadiness(release,{commit,practicalApplications:subset,applicationContract:c}).applications[0].status,'tested');
assert.throws(()=>deriveReadiness(release,{commit,practicalApplications:subset,applicationContract:c,fullQualification:full}),/full application matrix/);

const weakenedContract=structuredClone(c);weakenedContract.cases.pop();
assert.throws(()=>checkPracticalApplications(weakenedContract,receipt,{commit}),/frozen application case identities/);
