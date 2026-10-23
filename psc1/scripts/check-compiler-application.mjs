import assert from 'node:assert/strict';
import crypto from 'node:crypto';
const sha=value=>crypto.createHash('sha256').update(value).digest('hex');
export function checkCompilerApplication(contract,receipt,{commit,targets=contract.targets}={}){
 assert.equal(contract.schema,'psc1-compiler-application-contract/1');
 assert.deepEqual(contract.applications,['compiler-like']);
 assert.deepEqual(contract.cases.map(c=>c.id),["single","whitespace","exact-large-number","empty","expected-plus","expected-number","expected-semicolon","unexpected-end","unicode-location","second-line-location","unexpected-token","100000-statements"],'frozen compiler application case identities');
 assert.deepEqual(contract.performance,{id:'100000-statements',statements:100000,inputBytes:500000,
  maxElapsedSeconds:120,maxRssKiB:1048576,measurement:'Linux /usr/bin/time per actual checked child process; no injected guest fuel.'});
 assert.equal(receipt.schema,'psc1-compiler-application-execution/1');assert.equal(receipt.contract,contract.id);
 assert.equal(receipt.testedCommit,commit,'stale compiler application');assert.equal(receipt.checkerCommit,contract.checkerCommit);
 assert.equal(receipt.passed,true);assert.deepEqual(receipt.failures,[]);
 assert.ok(targets.length&&targets.every(t=>contract.targets.includes(t)));assert.equal(new Set(targets).size,targets.length);
 assert.deepEqual(receipt.targets,targets);
 assert.deepEqual(receipt.records.map(r=>r.syntax+'/'+r.target).sort(),
  contract.grammars.flatMap(s=>targets.map(t=>s+'/'+t)).sort(),'complete unique compiler application matrix');
 for(const row of receipt.records){
  assert.equal(row.passed,true);assert.equal(row.runtime,'executed');assert.equal(row.hostEffects,true);
  assert.equal(row.admission,'independent-official-Lean');assert.equal(row.checkerCommit,contract.checkerCommit);
  assert.equal(row.strictIr,'required-by-production-publication');
  for(const key of ['sourceSha256','librarySha256','artifactSha256','manifestSha256','kernelAdmissionSha256','sourceClosureSha256','oracleSha256'])
   assert.match(row[key]||'',/^[a-f0-9]{64}$/,'compiler application '+key);
  assert.deepEqual(Object.keys(row.moduleSha256).sort(),[...contract.requiredModules].sort());
  for(const hash of Object.values(row.moduleSha256))assert.match(hash,/^[a-f0-9]{64}$/);
  if(row.target==='rust')assert.match(row.hostCargoLockSha256||'',/^[a-f0-9]{64}$/);
  assert.deepEqual(row.cases.map(c=>c.id).sort(),contract.cases.map(c=>c.id).sort(),'complete unique compiler application cases');
  for(const expected of contract.cases){
   const actual=row.cases.find(c=>c.id===expected.id);
   const input=expected.repeat?expected.repeat.repeat(expected.count):expected.input;
   assert.equal(actual.passed,true);assert.equal(actual.exitCode,expected.code);
   assert.equal(actual.stdoutSha256,sha(expected.stdout));assert.equal(actual.inputSha256,sha(input));
   assert.equal(actual.inputBytes,Buffer.byteLength(input));
   assert.equal(actual.outputSha256,sha(expected.output??'previous'));
   assert.match(actual.stderrSha256||'',/^[a-f0-9]{64}$/);
   if(expected.output===undefined)assert.equal(actual.preservedPrevious,true);
   if(expected.performance){
    assert.equal(actual.id,contract.performance.id);assert.equal(actual.inputBytes,500000);
    const m=actual.metrics;assert.ok(m,'actual process metrics required');
    assert.ok(Number.isFinite(m.elapsedSeconds)&&m.elapsedSeconds>=0&&m.elapsedSeconds<=120,'elapsed bound');
    assert.ok(Number.isInteger(m.maxRssKiB)&&m.maxRssKiB>0&&m.maxRssKiB<=1048576,'memory bound');
   }else assert.equal(actual.metrics,null);
  }
 }
 return true;
}
