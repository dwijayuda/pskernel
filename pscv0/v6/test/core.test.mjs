import test from 'node:test';
import assert from 'node:assert/strict';
import { createCompilerCore } from '@proofscript/pscv-core';
import { inspectAdmissionsEnvelope, checkWithLeanKernel, supportedKernelTransports } from '@proofscript/pscv-kernel';

const EMPTY = '{"admissions":[],"format":"proofscript-checked-admissions","version":2}\n';

test('source inspection is explicitly not parsing or checking', () => {
  const core = createCompilerCore();
  const first = core.inspectSource({source:'function f(x: Nat): Nat := x'});
  assert.match(first.sourceSha256,/^[a-f0-9]{64}$/u);
  assert.equal(first.parsed, false);
  assert.equal(first.kernelChecked, false);
  assert.equal(first.pscvCertified, false);
  assert.equal(core.describe().implementationComplete, false);
  assert.throws(() => core.build(), /PSCV_CORE_BUILD_NOT_IMPLEMENTED/u);
  assert.throws(() => core.verify(), /PSCV_CORE_VERIFICATION_NOT_IMPLEMENTED/u);
  assert.throws(() => core.inspectSource({source:'',path:'src/Main.lean'}), /PSCV_SOURCE_ARTIFACT_INVALID/u);
});

test('profile identity is explicit; unknown profiles are rejected', () => {
  assert.equal(createCompilerCore({profile:'pscv-v1'}).describe().profile,'pscv-v1');
  assert.throws(() => createCompilerCore({profile:'lean-raw'}), /PSCV_CORE_PROFILE_UNSUPPORTED/u);
});

test('canonical admission envelope is only an input shape, not a proof', () => {
  const x = inspectAdmissionsEnvelope(EMPTY);
  assert.equal(x.contract, 'proofscript-checked-admissions/2');
  assert.equal(x.declarationCount, 0);
  assert.match(x.sha256,/^[a-f0-9]{64}$/u);
  assert.deepEqual(supportedKernelTransports(), ['native','wasm']);
  assert.throws(() => inspectAdmissionsEnvelope('{}'), /PSCV_ADMISSIONS_ENVELOPE_INVALID/u);
  assert.throws(() => inspectAdmissionsEnvelope('{"version":1,"format":"proofscript-checked-admissions","admissions":[]}'), /PSCV_ADMISSIONS_ENVELOPE_INVALID/u);
  assert.throws(() => inspectAdmissionsEnvelope('{"format":"proofscript-checked-admissions","version":2,"admissions":[],"accepted":true}'), /PSCV_ADMISSIONS_ENVELOPE_INVALID/u);
  assert.throws(() => inspectAdmissionsEnvelope('\uFEFF'+EMPTY), /PSCV_ADMISSIONS_INPUT_INVALID/u);
});

test('invalid admission envelopes are rejected before any optional kernel package is loaded', async () => {
  await assert.rejects(() => checkWithLeanKernel('bad'), /PSCV_ADMISSIONS_INVALID_JSON/u);
  await assert.rejects(() => checkWithLeanKernel(EMPTY,{transport:'other'}), /PSCV_KERNEL_TRANSPORT_UNSUPPORTED/u);
});
