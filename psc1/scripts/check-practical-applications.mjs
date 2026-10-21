// Evidence inventory only; this validator grants no execution/admission authority.
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
const sha=value=>crypto.createHash('sha256').update(value).digest('hex');
export function checkPracticalApplications(contract,receipt,{commit,targets=contract.targets}={}){
 assert.equal(contract.schema,'psc1-practical-application-contract/1');
 assert.deepEqual(contract.applications,['cli','json-files']);
 assert.deepEqual(contract.cases.map(c=>c.id),["help","invalid-command","invalid-arity","invalid-help-arity","unicode-records","argv-unicode-quote","bounded-output","empty-records","array-trailing-comma","object-trailing-comma","malformed-json","isolated-surrogate","duplicate-key","wrong-shape","missing-input","path-denied","read-permission","invalid-utf8","bounded-file","write-permission","denied-capability"],'frozen application case identities');
 assert.equal(receipt.schema,'psc1-practical-application-execution/1');
 assert.equal(receipt.contract,contract.id);assert.equal(receipt.testedCommit,commit,'stale applications');
 assert.equal(receipt.checkerCommit,contract.checkerCommit);
 assert.equal(receipt.passed,true);assert.deepEqual(receipt.failures,[]);
 assert.ok(targets.length&&targets.every(t=>contract.targets.includes(t)));assert.equal(new Set(targets).size,targets.length);
 assert.deepEqual(receipt.targets,targets);
 assert.deepEqual(receipt.records.map(r=>r.syntax+'/'+r.target).sort(),
  contract.grammars.flatMap(s=>targets.map(t=>s+'/'+t)).sort(),'complete unique application matrix');
 for(const row of receipt.records){
  assert.equal(row.passed,true);assert.equal(row.runtime,'executed');assert.equal(row.hostEffects,true);
  assert.equal(row.admission,'independent-official-Lean');assert.equal(row.checkerCommit,contract.checkerCommit);
  assert.equal(row.strictIr,'required-by-production-publication');
  for(const key of ['sourceSha256','librarySha256','artifactSha256','manifestSha256','kernelAdmissionSha256','sourceClosureSha256','oracleSha256'])
   assert.match(row[key]||'',/^[a-f0-9]{64}$/,'application '+key);
  assert.deepEqual(Object.keys(row.moduleSha256).sort(),['Args','Program','Transform']);
  for(const hash of Object.values(row.moduleSha256))assert.match(hash,/^[a-f0-9]{64}$/);
  if(row.target==='rust')assert.match(row.hostCargoLockSha256||'',/^[a-f0-9]{64}$/);
  assert.deepEqual(row.cases.map(c=>c.id).sort(),contract.cases.map(c=>c.id).sort(),'complete unique application cases');
  for(const expected of contract.cases){
   const actual=row.cases.find(c=>c.id===expected.id);
   assert.equal(actual.passed,true);assert.equal(actual.exitCode,expected.exitCode);
   assert.equal(actual.stdoutSha256,sha(expected.stdout));
   for(const key of ['stderrSha256','outputSha256'])assert.match(actual[key]||'',/^[a-f0-9]{64}$/);
   assert.equal(actual.outputSha256,sha(expected.output??'previous'),'exact application file result');
   assert.equal(actual.preservedPrevious,expected.output===undefined);
  }
 }
 return true;
}
