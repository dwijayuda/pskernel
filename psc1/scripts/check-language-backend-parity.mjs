// Finite versioned case contract; data receipts never grant compiler authority.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
export function checkLanguageBackendParity(contract,records,{targets=contract.targets}={}){
 assert.equal(contract.schema,'psc1-language-backend-case-contract/1');
 assert.ok(contract.id&&Array.isArray(contract.cases)&&contract.cases.length);
 for(const values of [contract.grammars,contract.targets,contract.cases.map(c=>c.id),targets]){
  assert.ok(Array.isArray(values)&&values.length);assert.equal(new Set(values).size,values.length);
 }
 assert.ok(targets.every(t=>contract.targets.includes(t)));
 assert.deepEqual(contract.flags,[false,true]);
 const required=new Set(contract.cases.flatMap(c=>contract.grammars.flatMap(s=>targets.map(t=>[c.id,s,t].join('/')))));
 const seen=new Set();
 for(const row of records){
  const key=[row.id,row.syntax,row.target].join('/');
  assert.ok(required.has(key),'unknown obligation:'+key);
  assert.ok(!seen.has(key),'duplicate obligation:'+key);seen.add(key);
  assert.equal(row.passed,true,'failed/skipped obligation:'+key);
  assert.deepEqual(row.flags,contract.flags,'missing observations:'+key);
  assert.equal(row.admission,'independent-official-Lean');
  assert.equal(row.strictIr,'required-by-production-publication');
  assert.equal(row.runtime,'executed');
  for(const field of ['sourceSha256','entrySha256','artifactSha256','manifestSha256','oracleSha256'])
   assert.match(row[field]||'',/^[a-f0-9]{64}$/,'missing identity:'+field+':'+key);
  if(contract.requiredModules){
   assert.deepEqual(Object.keys(row.applicationModuleSha256||{}).sort(),contract.requiredModules.map(m=>m+'.'+row.syntax).sort());
   for(const digest of Object.values(row.applicationModuleSha256))assert.match(digest,/^[a-f0-9]{64}$/);
  }
  if(contract.applicationBoundaryChecks)assert.deepEqual(row.applicationBoundaryChecks,contract.applicationBoundaryChecks);
  if(contract.independentStandardReference){
   assert.match(row.independentReferenceSha256||'',/^[a-f0-9]{64}$/,'missing independent standard reference');
   assert.equal(row.referenceComparison,'native-standard-operations');
  }
  for(const key of (contract.oracleLibraries||['result','effect']))
   assert.match(row.librarySha256?.[key]||'',/^[a-f0-9]{64}$/,'missing oracle library:'+key);
  assert.deepEqual(Object.keys(row.refusals||{}).sort(),[...contract.requiredRefusals].sort());
  for(const digest of Object.values(row.refusals))assert.match(digest,/^[a-f0-9]{64}$/);
 }
 assert.equal(seen.size,required.size,'missing grammar/target obligations');
 return {contract:contract.id,obligations:seen.size,targets,completeFamily:false};
}
if(process.argv[1]&&import.meta.url===pathToFileURL(path.resolve(process.argv[1])).href){
 const [contractFile,receiptFile]=process.argv.slice(2);
 const contract=JSON.parse(fs.readFileSync(contractFile,'utf8'));
 const receipt=JSON.parse(fs.readFileSync(receiptFile,'utf8'));
 assert.equal(receipt.schema,'psc1-language-backend-execution/1');
 assert.equal(receipt.contract,contract.id);assert.equal(receipt.passed,true);
 assert.deepEqual(receipt.failures,[]);
 // CLI qualification is complete across the declared contract, not a caller's
 // reduced selection. The minimum-Python execution is checked in its own scope.
 console.log(JSON.stringify(checkLanguageBackendParity(contract,receipt.records)));
}
