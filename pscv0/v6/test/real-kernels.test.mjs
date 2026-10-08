import test from 'node:test';
import assert from 'node:assert/strict';
import { checkWithLeanKernel } from '@proofscript/pscv-kernel';

const ENABLED = process.env.PSCV_REAL_KERNELS === '1';
const EMPTY = '{"admissions":[],"format":"proofscript-checked-admissions","version":2}\n';
const MALFORMED = '{"admissions":[{"kind":"unsupported","declaration":{}}],"format":"proofscript-checked-admissions","version":2}\n';
const WRONG_THEOREM = JSON.stringify({
  admissions: [{
    kind:'constant',
    declaration:{
      k:'theorem',lp:[],
      n:{k:'s',p:{k:'a'},v:'FalseWitness'},
      t:{k:'sort',l:{k:'z'}},
      v:{k:'sort',l:{k:'z'}},
    },
  }],
  format:'proofscript-checked-admissions',
  version:2,
}) + '\n';


const name = value => ({k:'s',p:{k:'a'},v:value});
const bvar = i => ({k:'b',i});
const sortProp = {k:'sort',l:{k:'z'}};
const theoremType = {
  k:'forall',n:name('P'),t:sortProp,bi:'default',
  b:{k:'forall',n:name('h'),t:bvar(0),bi:'default',b:bvar(1)},
};
function encodedTheorem(bodyVariableIndex) {
  return JSON.stringify({
    admissions:[{
      kind:'constant',declaration:{
        k:'theorem',lp:[],n:name('PSCV.IdentityProof'),
        t:theoremType,
        v:{k:'lam',n:name('P'),t:sortProp,bi:'default',
          b:{k:'lam',n:name('h'),t:bvar(0),bi:'default',b:bvar(bodyVariableIndex)}},
      },
    }],
    format:'proofscript-checked-admissions',version:2,
  }) + '\n';
}
const VALID_THEOREM = encodedTheorem(0);
const FALSE_PROOF_TERM = encodedTheorem(1);

for (const transport of ['native','wasm']) {

  test('pinned provider checks an actual closed logical identity theorem: ' + transport,
    {skip: !ENABLED}, async () => {
      const result = await checkWithLeanKernel(VALID_THEOREM,{transport});
      assert.equal(result.status,'kernel-admissions-accepted');
      assert.equal(result.admissions.declarationCount,1);
      assert.equal(result.pscvCertified,false);
    });

  test('pinned provider rejects a bogus proof body for the same proposition: ' + transport,
    {skip: !ENABLED}, async () => {
      const result = await checkWithLeanKernel(FALSE_PROOF_TERM,{transport});
      assert.equal(result.status,'kernel-admissions-rejected');
      assert.ok(result.rejectionKind.length > 0);
    });
  test('pinned provider accepts valid empty declaration batch: ' + transport,
    {skip: !ENABLED}, async () => {
      const result = await checkWithLeanKernel(EMPTY,{transport});
      assert.equal(result.status,'kernel-admissions-accepted');
      assert.equal(result.provider.profile,'lean4.34-core');
      assert.equal(result.pscvCertified,false);
      assert.equal(result.sourceFidelityEstablished,false);
    });

  test('pinned provider rejects an invalid theorem even when its JSON shape is valid: ' + transport,
    {skip: !ENABLED}, async () => {
      const result = await checkWithLeanKernel(WRONG_THEOREM,{transport});
      assert.equal(result.status,'kernel-admissions-rejected');
      assert.ok(result.rejectionKind.length > 0);
      assert.equal(result.pscvCertified,false);
    });

  test('pinned provider rejects unsupported declaration: ' + transport,
    {skip: !ENABLED}, async () => {
      const result = await checkWithLeanKernel(MALFORMED,{transport});
      assert.equal(result.status,'kernel-admissions-rejected');
      assert.ok(result.rejectionKind.length > 0);
      assert.equal(result.pscvCertified,false);
    });
}
