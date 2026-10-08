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

for (const transport of ['native','wasm']) {
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
