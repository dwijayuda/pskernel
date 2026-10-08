import assert from 'node:assert/strict';
import { test } from 'node:test';

import {
  assertCanonicalAdmissionsEnvelope,
  assertKernelContractDecision,
  kernelContractV1,
  kernelContractV1Canonical,
  kernelContractV1Sha256,
} from './kernel-contract.mjs';

test('KernelContract-v1 identity is frozen and stable', () => {
  assert.equal(kernelContractV1.id, 'proofscript-kernel-contract/1');
  assert.equal(kernelContractV1.admissionsFormat, 'proofscript-checked-admissions');
  assert.equal(kernelContractV1.admissionsVersion, 2);
  assert.equal(kernelContractV1.decision, 'accepted-boolean');
  assert.equal(kernelContractV1.failClosed, true);
  assert.equal(kernelContractV1.sha256, kernelContractV1Sha256);
  assert.match(kernelContractV1Sha256, /^[0-9a-f]{64}$/u);
  assert.equal(Object.isFrozen(kernelContractV1), true);
  assert.equal(
    kernelContractV1Canonical,
    'proofscript-kernel-contract/1\n' +
      'admissions=proofscript-checked-admissions/2\n' +
      'decision=accepted-boolean\n' +
      'failClosed=true\n',
  );
});

test('KernelContract-v1 accepts its canonical admissions envelope', () => {
  const text = JSON.stringify({
    admissions: [],
    format: 'proofscript-checked-admissions',
    version: 2,
  });
  assert.equal(assertCanonicalAdmissionsEnvelope(text).admissions.length, 0);
});

for (const [label, text, pattern] of [
  ['malformed JSON', '{', /ADMISSIONS_JSON/u],
  ['wrong format', JSON.stringify({ admissions: [], format: 'wrong', version: 2 }), /ADMISSIONS_FORMAT/u],
  ['wrong version', JSON.stringify({ admissions: [], format: 'proofscript-checked-admissions', version: 1 }), /ADMISSIONS_VERSION/u],
  ['missing admissions', JSON.stringify({ format: 'proofscript-checked-admissions', version: 2 }), /ADMISSIONS_ARRAY/u],
]) {
  test(`KernelContract-v1 rejects ${label}`, () => {
    assert.throws(() => assertCanonicalAdmissionsEnvelope(text), pattern);
  });
}

test('KernelContract-v1 accepts explicit acceptance and explicit rejection', () => {
  assert.equal(assertKernelContractDecision({ accepted: true }).accepted, true);
  const rejected = assertKernelContractDecision({
    accepted: false,
    errorKind: 'kernel-rejection',
  });
  assert.equal(rejected.accepted, false);
});

test('KernelContract-v1 rejects malformed decisions', () => {
  assert.throws(
    () => assertKernelContractDecision({ accepted: 'true' }),
    /RESULT_ACCEPTED/u,
  );
  assert.throws(
    () => assertKernelContractDecision({ accepted: false }),
    /RESULT_REJECTION/u,
  );
});
