import {test} from 'node:test';
import assert from 'node:assert/strict';
import {execFileSync} from 'node:child_process';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {buildArithmeticBatch,reviewArithmeticBatch} from '../src/arithmetic-surface-batch.mjs';
const root=path.resolve(fileURLToPath(new URL('../../../../',import.meta.url)));
const reference=()=>execFileSync('git',['-C',root,'show',
  'HEAD:pscv0/PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md'],{
  encoding:'utf8',maxBuffer:2*1024*1024,timeout:15000,
});
const fixture=()=>{
 const normativeReference=reference();
 const plan=buildArithmeticBatch(normativeReference);
 const sample=plan.goals.map(x=>x.goalKind==='generic'?'instHAdd':'instAddNat').join('\n')+'\n';
 return {normativeReference,generatedSource:plan.generatedSource,transcript:sample};
};
test('normative 42-row, 84-query arithmetic scope is total and deterministic',()=>{
 const normativeReference=reference();
 const a=buildArithmeticBatch(normativeReference),b=buildArithmeticBatch(normativeReference);
 assert.equal(a.sourceRowCount,42);
 assert.equal(a.typedQueryCount,84);
 assert.equal(a.identitySha256,b.identitySha256);
 assert.equal(a.generatedSource,b.generatedSource);
 assert.equal(a.sourceRows.filter(x=>x.surfaceId.startsWith('Nat:')).length,3);
 assert.equal(a.sourceRows.filter(x=>x.surfaceId.startsWith('Float32:')).length,3);
 assert.equal(a.sourceRows.filter(x=>x.surfaceId.startsWith('UInt64:')).length,3);
 assert(a.goals.some(x=>x.leanGoal==='HAdd Nat Nat Nat'));
 assert(a.goals.some(x=>x.leanGoal==='Add Nat'));
 assert(a.goals.some(x=>x.leanGoal==='HMul Float32 Float32 Float32'));
 assert(a.generatedSource.includes('example : Mul Float32 := inferInstance'));
 assert.equal(a.declarationMappingApproved,false);
 assert.equal(a.verifiedExecutableAuthorized,false);
});
test('review retains exact source and output boundaries, never certifies mapping',()=>{
 const r=reviewArithmeticBatch(fixture());
 assert.equal(r.observedArithmeticRows,42);
 assert.equal(r.observedGoals,84);
 assert.equal(r.typesExamined,14);
 assert.equal(r.requiredSurfaceRows,230);
 assert.equal(r.requiredSnapshotIDs,194);
 assert.equal(r.unresolvedNormativeIDs,191);
 assert.equal(r.approvedStandardRegistryFrozen,false);
 assert.equal(r.verifiedExecutableAuthorized,false);
 assert.equal(r.pscvVerified,false);
 assert(r.observations.every(x=>!x.semanticMappingApproved));
 assert.match(r.identitySha256,/^[0-9a-f]{64}$/u);
});
test('tampered generated Lean goals, normative source, selection outputs rejected',()=>{
 const f=fixture();
 for(const g of [
  {...f,normativeReference:f.normativeReference+'\n'},
  {...f,generatedSource:f.generatedSource.replace('HAdd Nat Nat Nat','HAdd Int Int Int')},
  {...f,generatedSource:f.generatedSource+'\ninstance : Add Nat := inferInstance\n'},
  {...f,transcript:f.transcript+'\ninstHAdd'},
  {...f,transcript:f.transcript.replace('instHAdd','sorryAx')},
  {...f,transcript:f.transcript.replace('instAddNat','error: fake')},
  {...f,transcript:''},
 ])assert.throws(()=>reviewArithmeticBatch(g),
 /PSC_PSCV_(ARITHMETIC_BATCH|REQUIRED_SURFACE)_/u);
});
test('candidate output hash changes without conferring proof authority',()=>{
 const f=fixture(),other={...f,transcript:f.transcript.replace('instAddNat','instAddInt')};
 const a=reviewArithmeticBatch(f),b=reviewArithmeticBatch(other);
 assert.notEqual(a.identitySha256,b.identitySha256);
 assert.equal(b.exactGenericToConcreteDependencyProved,false);
 assert.equal(b.verifiedExecutableAuthorized,false);
});
