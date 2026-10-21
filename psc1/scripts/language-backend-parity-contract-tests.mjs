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
assert.equal(check(contract,rows).obligations,126);
assert.throws(()=>check(contract,rows.slice(1)),/missing grammar/);
assert.throws(()=>check(contract,[...rows,rows[0]]),/duplicate/);
for(const mutation of [{id:'unknown'},{syntax:'unknown'},{target:'unknown'},{passed:false},
 {flags:[true]},{admission:'metadata-only'},{strictIr:'skipped'},{runtime:'skipped'},
 {sourceSha256:''},{artifactSha256:''},{refusals:{}}]){
 assert.throws(()=>check(contract,[{...rows[0],...mutation},...rows.slice(1)]));
}
assert.throws(()=>check({...contract,targets:[...contract.targets,'js']},rows));
console.log('PSC1_PARITY_CONTRACT_TESTS: missing/duplicate/unknown/skipped/identity/refusal receipts refuse');

const collection=JSON.parse(fs.readFileSync('docs/PSC1_STDLIB_COLLECTION_CASE_CONTRACT.json','utf8'));
const collectionRows=collection.cases.flatMap(c=>collection.grammars.flatMap(s=>collection.targets.map(t=>({
 ...rows[0],id:c.id,syntax:s,target:t,independentReferenceSha256:digest,
 referenceComparison:'native-standard-operations',
 refusals:Object.fromEntries(collection.requiredRefusals.map(id=>[id,digest]))
}))));
assert.equal(check(collection,collectionRows).obligations,42);
assert.throws(()=>check(collection,[{...collectionRows[0],independentReferenceSha256:null},...collectionRows.slice(1)]),/independent standard reference/);
assert.throws(()=>check(collection,[{...collectionRows[0],referenceComparison:'same-helper'},...collectionRows.slice(1)]));

const jsonContract=JSON.parse(fs.readFileSync('docs/PSC1_JSON_APPLICATION_CASE_CONTRACT.json','utf8'));
const jsonRows=jsonContract.cases.flatMap(c=>jsonContract.grammars.flatMap(s=>jsonContract.targets.map(t=>({
 ...rows[0],id:c.id,syntax:s,target:t,
 applicationModuleSha256:Object.fromEntries(jsonContract.requiredModules.map(m=>[m+'.'+s,digest])),
 librarySha256:Object.fromEntries(jsonContract.oracleLibraries.map(key=>[key,digest])),
 refusals:Object.fromEntries(jsonContract.requiredRefusals.map(id=>[id,digest]))
}))));
assert.equal(check(jsonContract,jsonRows).obligations,98);
assert.throws(()=>check(jsonContract,[{...jsonRows[0],applicationModuleSha256:{}},...jsonRows.slice(1)]));
assert.throws(()=>check(jsonContract,[{...jsonRows[0],librarySha256:{}},...jsonRows.slice(1)]));
