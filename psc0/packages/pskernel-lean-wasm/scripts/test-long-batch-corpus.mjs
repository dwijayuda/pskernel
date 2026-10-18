import {test} from 'node:test';
import assert from 'node:assert/strict';
import {count,makeLongBatchCorpus} from './long-batch-corpus.mjs';

test('1205-declaration test is a genuine dependent definition chain',()=>{
  const [valid,invalid]=makeLongBatchCorpus();
  assert.equal(valid.admissionCount,1205);
  const accepted=JSON.parse(valid.input);
  assert.equal(accepted.version,2);
  assert.equal(accepted.admissions.length,count);
  assert.equal(accepted.admissions[0].declaration.v.k,'nat');
  for(let i=1;i<count;i++){
    const decl=accepted.admissions[i].declaration;
    assert.equal(decl.v.k,'const');
    assert.deepEqual(decl.v.n,accepted.admissions[i-1].declaration.n);
  }
  const rejected=JSON.parse(invalid.input);
  assert.equal(rejected.admissions.length,count);
  for(let i=0;i<count-1;i++)
    assert.deepEqual(rejected.admissions[i],accepted.admissions[i]);
  assert.equal(rejected.admissions[count-1].declaration.v.k,'sort');
  assert.equal(invalid.declarationIndex,count-1);
  assert.equal(invalid.errorReason,'declaration-type-mismatch');
});
