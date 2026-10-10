import assert from 'node:assert/strict';
import {test} from 'node:test';
import {execFileSync} from 'node:child_process';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {concreteGoals,inspectConcreteDictionaries} from '../src/concrete-dictionary-review.mjs';
const root=path.resolve(fileURLToPath(new URL('../../../../',import.meta.url)));
const git=p=>execFileSync('git',['-C',root,'show','HEAD:'+p],
  {encoding:'utf8',maxBuffer:2*1024*1024,timeout:15000});
const input=()=>({
  normativeReference:git('pscv0/PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md'),
  source:git('PSCVL/ConcreteDictionaryWitness.lean'),
  transcript:["instAddNat","instMulNat","instSubNat","Int.instAdd","instDecidableEqNat","instDecidableEqBool","instAppendString"].join('\n')+'\n',
});
test('concrete dictionaries remain unapproved diagnostic observations',()=>{
  const r=inspectConcreteDictionaries(input());
  assert.equal(r.count,7);
  assert.equal(r.normativeRows,230);
  assert.equal(r.requiredSnapshotIds,194);
  assert.equal(r.unresolvedStandardIds,191);
  assert.equal(r.exactGenericDependencyGraphQualified,false);
  assert.equal(r.instancePriorityAndScopeOrderQualified,false);
  assert.equal(r.verifiedExecutableAuthorized,false);
});
test('invalid input/source and fabricated authority are refused',()=>{
  const f=input();
  for(const alt of [
    {...f,source:f.source+'\ninstance : Add Nat := inferInstance\n'},
    {...f,source:f.source.replace('#synth Add Nat','#synth Add Bool')},
    {...f,source:f.source.replace('example : DecidableEq Bool := inferInstance','')},
    {...f,normativeReference:f.normativeReference+'\n'},
    {...f,transcript:f.transcript+'\nverifiedExecutableAuthorized:true'},
    {...f,transcript:f.transcript.replace('instAddNat','sorryAx')},
  ]) assert.throws(()=>inspectConcreteDictionaries(alt),
    /PSC_PSCV_(CONCRETE_DICT|REQUIRED_SURFACE)_/u);
});
test('changing the observed concrete selection changes the non-authoritative evidence identity',()=>{
 const one=input(),two=input();
 two.transcript=two.transcript.replace('Int.instAdd','Int.forgedAdd');
 const a=inspectConcreteDictionaries(one);
 assert.throws(()=>inspectConcreteDictionaries(two),/PSC_PSCV_CONCRETE_DICT_TRANSCRIPT/u);
 assert.equal(a.proofCertificateAvailable,false);
});
