// Exact-commit CI inventory; no admission or publication authority.
import assert from 'node:assert/strict';
export function checkTypedIoExecution(contract,receipt,{commit,head,checkerCommit,targets=contract.targets}){
 assert.equal(contract.schema,'psc1-typed-io-execution-contract/1');
 assert.equal(receipt.schema,'psc1-typed-io-execution/1');assert.equal(receipt.contract,contract.id);
 assert.equal(receipt.testedCommit,commit,'stale IO execution');
 if(head)assert.equal(receipt.branchHeadCommit,head,'wrong IO branch head');
 assert.equal(receipt.checkerCommit,checkerCommit);assert.equal(receipt.passed,true);
 assert.deepEqual(receipt.failures,[]);assert.equal(receipt.completeApplications,false);
 assert.equal(new Set(targets).size,targets.length);assert.ok(targets.length&&targets.every(t=>contract.targets.includes(t)));
 assert.deepEqual(receipt.targets,targets);
 const expected=contract.grammars.flatMap(s=>targets.map(t=>s+'/'+t)).sort();
 assert.deepEqual(receipt.records.map(r=>r.syntax+'/'+r.target).sort(),expected,'complete unique actual IO matrix');
 const requiredProviders=new Set(targets.map(t=>contract.mappings[t].provider));
 assert.deepEqual(Object.keys(receipt.policies).sort(),[...requiredProviders].sort());
 for(const provider of requiredProviders){
  const policy=receipt.policies[provider],spec=contract.providers[provider];
  assert.equal(policy.schema,spec.schema);assert.equal(policy.testedCommit,commit,'stale IO policy');
  if(head)assert.equal(policy.branchHeadCommit,head);
  assert.equal(policy.passed,true);
  if(spec.abi)assert.equal(policy.abi,spec.abi);else assert.equal(policy.platform,'linux');
  assert.equal(new Set(policy.checks).size,policy.checks.length);
  for(const name of spec.requiredChecks)assert.ok(policy.checks.includes(name),'missing IO policy: '+provider+'/'+name);
 }
 for(const row of receipt.records){
  const mapping=contract.mappings[row.target];
  assert.equal(row.passed,true);assert.equal(row.hostEffects,true);
  assert.equal(row.provider,mapping.provider);assert.equal(row.abi,mapping.abi);
  assert.equal(row.admission,'independent-official-Lean');
  assert.equal(row.checkerCommit,checkerCommit);
  assert.equal(row.strictIr,'required-by-production-publication');assert.equal(row.runtime,'executed');
  assert.equal(new Set(row.checks).size,row.checks.length);
  for(const check of contract.checks)assert.ok(row.checks.includes(check),'missing actual IO check: '+check);
  for(const field of ['sourceSha256','librarySha256','applicationModuleSha256','artifactSha256',
   'manifestSha256','sourceClosureSha256','kernelAdmissionSha256'])
   assert.match(row[field]||'',/^[a-f0-9]{64}$/,field);
 }
 return {contract:contract.id,targets,observations:receipt.records.length,
  policies:[...requiredProviders],qualifiedSubset:contract.targets.every(t=>targets.includes(t))};
}
