import assert from 'node:assert/strict';
import fs from 'node:fs';
import { checkLanguageBackendParity as check } from './check-language-backend-parity.mjs';
const contract=JSON.parse(fs.readFileSync('docs/PSC1_COMPILERM_CASE_CONTRACT.json','utf8'));
const digest='a'.repeat(64);
const rows=contract.cases.flatMap(c=>contract.grammars.flatMap(s=>contract.targets.map(t=>({
 id:c.id,syntax:s,target:t,passed:true,flags:[false,true],admission:'independent-official-Lean',
 strictIr:'required-by-production-publication',runtime:'executed',sourceSha256:digest,
 entrySha256:digest,artifactSha256:digest,manifestSha256:digest,oracleSha256:digest,
 librarySha256:Object.fromEntries(contract.oracleLibraries.map(key=>[key,digest])),
 refusals:Object.fromEntries(contract.requiredRefusals.map(id=>[id,digest]))
}))));
assert.equal(check(contract,rows).obligations,98);
assert.throws(()=>check(contract,rows.slice(1)),/missing grammar/);
assert.throws(()=>check(contract,[...rows,rows[0]]),/duplicate/);
for(const mutation of [{id:'unknown'},{syntax:'unknown'},{target:'unknown'},{passed:false},
 {flags:[true]},{admission:'metadata-only'},{strictIr:'skipped'},{runtime:'skipped'},
 {sourceSha256:''},{artifactSha256:''},{refusals:{}}]){
 assert.throws(()=>check(contract,[{...rows[0],...mutation},...rows.slice(1)]));
}
assert.throws(()=>check({...contract,targets:[...contract.targets,'js']},rows));
console.log('PSC1_PARITY_CONTRACT_TESTS: missing/duplicate/unknown/skipped/identity/refusal receipts refuse');
