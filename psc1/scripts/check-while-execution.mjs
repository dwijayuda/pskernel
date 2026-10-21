// Exact-commit execution inventory; no admission, termination or publication authority.
import assert from 'node:assert/strict';
const grammars=['lean','ps'];
const allTargets=['js','ts','rust','wasm-core','wasm-component','python','php'];
export const whileChecks=['whilefalsecheck','whilecountcheck','whileearlycheck','whilecapturecheck',
 'whilesequentialcheck','whileforcheck','whileselfcheck','whileexceptcheck'];
const fields=['whileCaptureFalse','whileCaptureTrue','whileCountFalse','whileCountTrue',
 'whileEarlyFalse','whileEarlyTrue','whileExceptFalseTag','whileExceptFalseValue',
 'whileExceptTrueTag','whileExceptTrueValue','whileFalseFalse','whileFalseTrue',
 'whileForFalse','whileForTrue','whileSelfFalse','whileSelfTrue','whileSequentialFalse','whileSequentialTrue'];
const refusalNames=['default-refuses-unrestricted-while','verified-refuses-unrestricted-while',
 'total-owner','nested-while-body','nested-for-body','function-valued-result','generic-result','CompilerM-body'];
function matrix(rows,targets,label){
 assert.ok(Array.isArray(rows),label);
 assert.deepEqual(rows.map(r=>r.syntax+'/'+r.target).sort(),
  grammars.flatMap(s=>targets.map(t=>s+'/'+t)).sort(),'complete unique '+label);
}
function identity(row,checkerCommit){
 assert.equal(row.passed,true);assert.equal(row.checkerCommit,checkerCommit);
 assert.equal(row.admission,'independent-official-Lean');
 assert.equal(row.strictIr,'required-by-production-publication');
 for(const key of ['sourceSha256','sourceClosureSha256','kernelAdmissionSha256','artifactSha256','manifestSha256'])
  assert.match(row[key]||'',/^[a-f0-9]{64}$/,key);
}
export function checkWhileExecution(data,{commit,head,checkerCommit,targets=allTargets}){
 assert.equal(data.schema,'psc1-ordinary-while-conformance/1');
 assert.equal(data.commit,commit,'stale while execution');
 if(head)assert.equal(data.branchHeadCommit,head,'wrong while branch');
 assert.equal(checkerCommit,'eb6cafb7290e8bd5f2937522d8d804f58f02bafc');
 assert.deepEqual(data.nativeLean,{version:'4.35.0',commit:checkerCommit});
 assert.match(data.oracleSha256||'',/^[a-f0-9]{64}$/);
 assert.deepEqual(data.failures,[]);assert.equal(data.assurance,'ordinary-checked');
 assert.equal(data.behaviorallyVerified,false);
 assert.equal(new Set(targets).size,targets.length);
 assert.ok(targets.length&&targets.every(t=>allTargets.includes(t)));
 assert.equal(data.targetCount,targets.length);assert.deepEqual(data.sourceSyntaxes,grammars);
 assert.deepEqual(data.loopChecks,whileChecks);assert.deepEqual([...data.oracleFields].sort(),fields);
 assert.equal(data.longLoopIterations,100000);
 matrix(data.records,targets,'finite while observations');
 for(const row of data.records){
  identity(row,checkerCommit);assert.equal(row.assurance,'ordinary-checked');
  assert.equal(row.behaviorallyVerified,false);
  const names=row.target==='wasm-component'?['semantic']:[...whileChecks,'semantic'];
  assert.deepEqual(row.checks,names.map(n=>[n,true,true]));
  assert.deepEqual([...row.publicNames].sort(),[...names].sort());
  assert.ok(row.partialDeclarations.length>0);
  assert.ok(row.publicNames.every(n=>!n.includes('_psc1WhileBody')));
 }
 for(const [label,rows,observation]of [
  ['divergence',data.divergence,'unusedNonvalueCallEvaluated'],
  ['pattern strictness',data.patternStrictness,'unusedPatternRhsEvaluated']
 ]){
  matrix(rows,targets,label);
  for(const row of rows){
   identity(row,checkerCommit);assert.equal(row.exitCode,124);
   assert.equal(row.externalTimeoutMs,2000);assert.equal(row.earlyReturnPreflight,true);
   assert.equal(row[observation],true);assert.deepEqual(row.publicNames,['spin']);
  }
 }
 assert.deepEqual(data.rejections.map(r=>r.syntax+'/'+r.name).sort(),
  grammars.flatMap(s=>refusalNames.map(n=>s+'/'+n)).sort(),'complete unique refusals');
 for(const row of data.rejections){
  assert.equal(row.passed,true);assert.equal(typeof row.diagnostic,'string');
  const expected=row.name==='default-refuses-unrestricted-while'?/PSC1_PREPARATION_FAILED/:
   row.name==='verified-refuses-unrestricted-while'?/PSC1_VERIFIED_EXECUTION_UNAVAILABLE/:
   row.name==='total-owner'?/unrestricted while requires an explicit partial declaration/:
   /selected while requires Id or Except/;
  assert.match(row.diagnostic,expected);
 }
 return {scope:'selected ordinary Id/Except controllers and selected nesting',
  consumers:data.records.length,externalDeadlines:data.divergence.length,
  patternStrictnessDeadlines:data.patternStrictness.length,refusals:data.rejections.length,
  completeTargets:allTargets.every(t=>targets.includes(t))};
}
