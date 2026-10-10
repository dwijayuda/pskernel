import assert from 'node:assert/strict';
import { test } from 'node:test';
import { execFileSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import {typedWitnessGoals,reviewTypedResolution} from '../src/typed-resolution-review.mjs';
const root=path.resolve(fileURLToPath(new URL('../../../../',import.meta.url)));
const show=p=>execFileSync('git',['-C',root,'show','HEAD:'+p],
 {encoding:'utf8',maxBuffer:2*1024*1024,timeout:15000});
const input=()=>({
  normativeReference:show('pscv0/PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md'),
  source:show('PSCVL/TypedInstanceWitness.lean'),
  transcript:typedWitnessGoals.map((g,i)=>
    'PSCVL/TypedInstanceWitness.lean:'+String(20+i*3)+':0: information: selected'+i).join('\n'),
});
test('exact bounded witnesses have no PSCV authority',()=>{
  const r=reviewTypedResolution(input());
  assert.equal(r.goalsObserved,7);
  assert.equal(r.requiredSurfaceRows,230);
  assert.equal(r.distinctStandardIds,194);
  assert.equal(r.unresolvedStandardSnapshotIds,191);
  assert.equal(r.standardEnvironmentFrozen,false);
  assert.equal(r.verifiedExecutableAuthorized,false);
  assert.equal(r.pscvVerified,false);
  assert.match(r.identitySha256,/^[0-9a-f]{64}$/u);
});
test('forged transcript, proof authority, or source drift are refused',()=>{
  const x=input();
  for(const alt of [
    {...x,source:x.source.replace('#synth HAdd Nat Nat Nat','#synth HAdd Int Int Int')},
    {...x,source:x.source.replace('example : BEq Nat := inferInstance','')},
    {...x,normativeReference:x.normativeReference+'\n'},
    {...x,transcript:x.transcript.replace(' information:',' warning:')},
    {...x,transcript:x.transcript+'\nfile:1:0: information: extra'},
    {...x,transcript:x.transcript+'\nerror: unacceptable'},
    {...x,transcript:x.transcript.replace('selected0','sorryAx')},
  ])assert.throws(()=>reviewTypedResolution(alt),
    /PSC_PSCV_(TYPED_WITNESS|REQUIRED_SURFACE)_/u);
});
test('selected-term text affects review identity, not authority',()=>{
  const a=input(),b=input();
  b.transcript=b.transcript.replace('selected3','different4');
  const left=reviewTypedResolution(a),right=reviewTypedResolution(b);
  assert.notEqual(left.identitySha256,right.identitySha256);
  assert.equal(right.mappedToClosedStandard,false);
  assert.equal(right.certifiedExecutableAvailable,false);
});
