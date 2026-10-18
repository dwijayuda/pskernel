import assert from 'node:assert/strict';
import { checkCanonicalAdmissions, createKernel, kernelStatus, KernelNotReadyError } from '../index.mjs';

const status = kernelStatus();
assert.equal(status.leanVersion, '4.35.0');
assert.equal(status.languageProfile, 'pscv0-v7.2');
assert.equal(status.target, 'wasm-gc-core');
assert.equal(status.checkerReady, false);
assert.equal(status.admissionSupported, false);

for (const source of [
  '{"format":"proofscript-checked-admissions","version":2,"admissions":[]}',
  '{"format":"proofscript-checked-admissions","version":2,"admissions":[{"kind":"axiom"}]}',
  '{malformed json',
  '',
]) {
  await assert.rejects(() => checkCanonicalAdmissions(source), error =>
    error instanceof KernelNotReadyError && error.code === 'PSC0-WASM-GC-KERNEL-NOT-READY');
}
await assert.rejects(() => createKernel(), error => error instanceof KernelNotReadyError);
await assert.rejects(() => checkCanonicalAdmissions(null), TypeError);
console.log('PSC0_WASM_GC_ADMISSION_FAIL_CLOSED: PASS (no misleading accepted or kernel-rejected result)');
