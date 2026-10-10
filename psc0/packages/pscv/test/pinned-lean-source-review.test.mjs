import {test} from 'node:test';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {gitBlobSha1,literalInstanceLineCandidates,reviewPinnedLeanSource}
 from '../src/pinned-lean-source-review.mjs';

test('Git source blob identity is content bound',()=>{
 const first='instance instAddNat : Add Nat where\n';
 const header='blob '+Buffer.byteLength(first)+String.fromCharCode(0);
 const expected=createHash('sha1').update(header).update(first).digest('hex');
 assert.equal(gitBlobSha1(first),expected);
 assert.notEqual(gitBlobSha1(first),gitBlobSha1(first+'\n'));
});
test('lexical locator only sees named instance declarations, not incidental mentions',()=>{
 const source=[
  'namespace Test',
  'instance instAddNat : Add Nat where',
  '   add := Nat.add',
  'theorem example := instAddNat',
  'instance otherNat : Mul Nat where',
  '  mul := Nat.mul',
  'match instDecidableEqNat i.val j.val with',
  'instance Int.instAdd : Add Int where',
 ].join('\n');
 assert.deepEqual(literalInstanceLineCandidates(source,'instAddNat'),[2]);
 assert.deepEqual(literalInstanceLineCandidates(source,'instDecidableEqNat'),[]);
 assert.deepEqual(literalInstanceLineCandidates(source,'Int.instAdd'),[8]);
 assert.deepEqual(literalInstanceLineCandidates(source,'instMulNat'),[]);
});
test('no source module claim accepted without exact qualified Lean observation',()=>{
 assert.throws(()=>reviewPinnedLeanSource({
  typedDeclarations:{identitySha256:'fake',observedDeclarationCount:11},
  upstreamCommit:'470d5ce1400764999581fd26d5d72b00d990b0f4',
  sourceFiles:[],
 }),/PSC_PSCV_SOURCE_BLOBS_PINNED_INPUTS/u);
});
