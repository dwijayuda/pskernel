// Import the shared fixtures before any expensive Lean compilation.
// "node --check" cannot detect unbound values hidden in top-level code.
import {test} from 'node:test';
import assert from 'node:assert/strict';
import {corpus} from './corpus.mjs';

test('shared canonical admissions corpus eagerly constructs and decodes',()=>{
  assert.equal(corpus.length,4);
  assert.equal(new Set(corpus.map(c=>c.id)).size,corpus.length);
  assert.ok(corpus.some(c=>c.accept));
  assert.ok(corpus.some(c=>!c.accept));
  for(const fixture of corpus){
    assert.equal(typeof fixture.id,'string');
    assert.equal(typeof fixture.input,'string');
    assert.equal(typeof fixture.accept,'boolean');
    assert.ok(fixture.input.length>0);
    if(fixture.id!=='malformed-json'){
      const payload=JSON.parse(fixture.input);
      assert.equal(payload.format,'proofscript-checked-admissions');
      assert.ok(Array.isArray(payload.admissions));
      if(fixture.id!=='wrong-version')assert.equal(payload.version,2);
    }else{
      assert.throws(()=>JSON.parse(fixture.input),SyntaxError);
    }
    if(!fixture.accept)assert.equal(typeof fixture.errorKind,'string');
  }
});
test('valid and invalid declaration fixtures are semantically distinct',()=>{
  const valid=JSON.parse(corpus.find(x=>x.id==='good-nat-definition').input);
  const invalid=JSON.parse(corpus.find(x=>x.id==='ill-typed-definition').input);
  assert.equal(valid.admissions[0].declaration.v.k,'nat');
  assert.equal(valid.admissions[0].declaration.v.v,'1');
  assert.equal(invalid.admissions[0].declaration.v.k,'sort');
});
