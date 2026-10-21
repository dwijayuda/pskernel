import assert from 'node:assert/strict';
import fs from 'node:fs';
import {checkTypedIoExecution as check} from './check-typed-io-execution.mjs';
const contract=JSON.parse(fs.readFileSync(new URL('../docs/PSC1_TYPED_IO_EXECUTION_CONTRACT.json',import.meta.url)));
const commit='a'.repeat(40),head='b'.repeat(40),checkerCommit='eb6cafb7290e8bd5f2937522d8d804f58f02bafc';
const digest='c'.repeat(64),clone=structuredClone;
const records=contract.grammars.flatMap(syntax=>contract.targets.map(target=>({
 syntax,target,...contract.mappings[target],passed:true,hostEffects:true,checks:contract.checks,
 admission:'independent-official-Lean',checkerCommit,strictIr:'required-by-production-publication',runtime:'executed',
 ...Object.fromEntries(['sourceSha256','librarySha256','applicationModuleSha256','artifactSha256',
 'manifestSha256','sourceClosureSha256','kernelAdmissionSha256'].map(k=>[k,digest]))
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
 r=>r.records[0].kernelAdmissionSha256='',r=>r.records[0].provider='python',
 r=>r.records[0].runtime='skipped',r=>r.completeApplications=true,
 r=>r.policies.rust.testedCommit=head,r=>r.policies.php.checks=[],
 r=>r.policies.node.checks=[...r.policies.node.checks,r.policies.node.checks[0]]
]){
 const bad=clone(receipt);mutate(bad);assert.throws(()=>check(contract,bad,{commit,head,checkerCommit}));
}
console.log('PSC1_TYPED_IO_EXECUTION_CONTRACT: PASS exact commit, matrix, policy, host effects and admission identity refusals');
