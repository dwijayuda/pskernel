import assert from 'node:assert/strict';
import fs from 'node:fs';
import {checkTypedIoExecution as check} from './check-typed-io-execution.mjs';
import {deriveReadiness} from './practical-core-readiness.mjs';
const contract=JSON.parse(fs.readFileSync(new URL('../docs/PSC1_TYPED_IO_EXECUTION_CONTRACT.json',import.meta.url)));
const commit='a'.repeat(40),head='b'.repeat(40),checkerCommit='eb6cafb7290e8bd5f2937522d8d804f58f02bafc';
const digest='c'.repeat(64),clone=structuredClone;
const records=contract.grammars.flatMap(syntax=>contract.targets.map(target=>({
 syntax,target,...contract.mappings[target],passed:true,hostEffects:true,checks:contract.checks,
 admission:'independent-official-Lean',checkerCommit,strictIr:'required-by-production-publication',runtime:'executed',
 ...Object.fromEntries(['sourceSha256','librarySha256','applicationModuleSha256','artifactSha256',
 'manifestSha256','sourceClosureSha256','kernelAdmissionSha256','hostCargoLockSha256'].map(k=>[k,digest]))
})));
const policies=Object.fromEntries(Object.entries(contract.providers).map(([id,spec])=>[id,{
 schema:spec.schema,abi:spec.abi,platform:'linux',testedCommit:commit,branchHeadCommit:head,passed:true,checks:spec.requiredChecks
}]));
const receipt={schema:'psc1-typed-io-execution/1',contract:contract.id,testedCommit:commit,
 branchHeadCommit:head,checkerCommit,passed:true,failures:[],completeApplications:false,targets:contract.targets,records,policies};
assert.equal(check(contract,receipt,{commit,head,checkerCommit}).observations,14);
for(const mutate of [
 r=>r.testedCommit=head,r=>r.records.pop(),r=>r.records.push(r.records[0]),
 r=>r.records[0].checks=[],r=>r.records[0].hostEffects=false,
 r=>r.records[0].kernelAdmissionSha256='',r=>r.records[0].provider='python',r=>r.records[2].hostCargoLockSha256='',
 r=>r.records[0].runtime='skipped',r=>r.completeApplications=true,
 r=>r.policies.rust.testedCommit=head,r=>r.policies.php.checks=[],
 r=>r.policies.node.checks=[...r.policies.node.checks,r.policies.node.checks[0]]
]){
 const bad=clone(receipt);mutate(bad);assert.throws(()=>check(contract,bad,{commit,head,checkerCommit}));
}
console.log('PSC1_TYPED_IO_EXECUTION_CONTRACT: PASS exact commit, matrix, policy, host effects and admission identity refusals');

const releaseContract=JSON.parse(fs.readFileSync(new URL('../docs/PSC1_PRACTICAL_CORE_V1_CONTRACT.json',import.meta.url)));
const pending=deriveReadiness(releaseContract,{commit,ioExecutionImplemented:true});
assert.ok(pending.families.find(f=>f.id==='typed-io').cases.every(c=>c.status==='implemented'));
const tested=deriveReadiness(releaseContract,{commit,ioExecutionContract:contract,typedIoExecution:receipt});
assert.ok(tested.families.find(f=>f.id==='typed-io').cases.every(c=>c.status==='tested'));
const qualified=deriveReadiness(releaseContract,{commit,ioExecutionContract:contract,typedIoExecution:receipt,
 fullQualification:{schema:'psc1-seven-backend-qualification/1',testedCommit:commit,
  qualification:'passed-scoped-execution',assurance:{checked:true,explicitOrdinary:true,verifiedRequest:'refused'}}});
assert.equal(qualified.families.find(f=>f.id==='typed-io').qualified,true);
assert.equal(qualified.counts.qualified,3);
assert.equal(qualified.releaseReady,false);
assert.ok(qualified.applications.every(a=>a.status==='blocked'));

for(const name of ['short-circuit-skips-foreign-error','short-circuit-error-control-traps']){
 const bad=clone(receipt);bad.records[0].checks=bad.records[0].checks.filter(c=>c!==name);
 assert.throws(()=>check(contract,bad,{commit,head,checkerCommit}),/missing actual IO check/);
}
const orderContract=JSON.parse(fs.readFileSync(new URL('../docs/PSC1_ORDER_CASE_CONTRACT.json',import.meta.url)));
const orderRows=orderContract.cases.flatMap(c=>orderContract.grammars.flatMap(syntax=>orderContract.targets.map(target=>({
 id:c.id,syntax,target,passed:true,flags:[false,true],admission:'independent-official-Lean',
 strictIr:'required-by-production-publication',runtime:'executed',
 ...Object.fromEntries(['sourceSha256','entrySha256','artifactSha256','manifestSha256','oracleSha256'].map(k=>[k,digest])),
 librarySha256:Object.fromEntries(orderContract.oracleLibraries.map(k=>[k,digest])),
 refusals:Object.fromEntries(orderContract.requiredRefusals.map(k=>[k,digest]))
}))));
const orderSuite={'checked-order':{caseContract:orderContract,implemented:true,receipt:{
 schema:'psc1-language-backend-execution/1',contract:orderContract.id,testedCommit:commit,
 checkerCommit,passed:true,failures:[],targets:orderContract.targets,records:orderRows}}};
const full={schema:'psc1-seven-backend-qualification/1',testedCommit:commit,
 qualification:'passed-scoped-execution',assurance:{checked:true,explicitOrdinary:true,verifiedRequest:'refused'}};
const withoutIo=deriveReadiness(releaseContract,{commit,suites:orderSuite,fullQualification:full});
const operatorCases=r=>r.families.find(f=>f.id==='operators').cases;
assert.equal(operatorCases(withoutIo).find(c=>c.id==='numeric').status,'qualified');
assert.equal(operatorCases(withoutIo).find(c=>c.id==='short-circuit').status,'implemented',
 'divergence observation alone cannot qualify foreign-error skipping');
const withIo=deriveReadiness(releaseContract,{commit,suites:orderSuite,ioExecutionContract:contract,
 typedIoExecution:receipt,fullQualification:full});
assert.ok(operatorCases(withIo).every(c=>c.status==='qualified'));
assert.equal(withIo.releaseReady,false);
const withoutFull=deriveReadiness(releaseContract,{commit,suites:orderSuite,ioExecutionContract:contract,typedIoExecution:receipt});
assert.equal(operatorCases(withoutFull).find(c=>c.id==='short-circuit').status,'tested');
console.log('PSC1_SHORT_CIRCUIT_COMPOSITE: PASS divergence, seven foreign-error consumers and exact full qualification required together');
