import assert from 'node:assert/strict';
import fs from 'node:fs';
import {validateReleaseContract,deriveReadiness} from './practical-core-readiness.mjs';
const contract=JSON.parse(fs.readFileSync(new URL('../docs/PSC1_PRACTICAL_CORE_V1_CONTRACT.json',import.meta.url)));
const commit='a'.repeat(40),clone=value=>structuredClone(value);
validateReleaseContract(contract);
assert.equal(deriveReadiness(contract,{commit}).releaseReady,false);
assert.equal(deriveReadiness(contract,{commit}).counts.blocked,37);
for(const mutate of [
 c=>c.families.pop(),c=>c.targets.pop(),c=>c.grammars.pop(),c=>c.policy.negativeTests=false,
 c=>c.families[0].acceptance.push(c.families[0].acceptance[0]),
 c=>c.families[0].dependsOn.push('local-inference'),
 c=>c.workQueue[0].dependsOn.push('feature-freeze'),c=>c.authority.expressionV2Required=true
]){
 const changed=clone(contract);mutate(changed);assert.throws(()=>validateReleaseContract(changed));
}
const full={schema:'psc1-seven-backend-qualification/1',testedCommit:'b'.repeat(40),
 qualification:'passed-scoped-execution',assurance:{checked:true,explicitOrdinary:true,verifiedRequest:'refused'}};
assert.throws(()=>deriveReadiness(contract,{commit,fullQualification:full}),/stale/);
const spec=contract.suites['compiler-m'];
const caseContract=JSON.parse(fs.readFileSync(new URL('../'+spec.contract,import.meta.url)));
const suites={'compiler-m':{caseContract,implemented:true,receipt:{
 schema:'psc1-language-backend-execution/1',contract:caseContract.id,testedCommit:commit,
 checkerCommit:contract.authority.commit,passed:true,failures:[],targets:['js'],records:[]}}};
assert.throws(()=>deriveReadiness(contract,{commit,suites}),/missing grammar/);
suites['compiler-m'].receipt.testedCommit='b'.repeat(40);
assert.throws(()=>deriveReadiness(contract,{commit,suites}),/stale/);
console.log('PSC1_RELEASE_READINESS_CONTRACT: PASS missing, stale, partial, duplicate and weakened policies refuse');
