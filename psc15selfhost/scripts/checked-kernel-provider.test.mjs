import assert from 'node:assert/strict';
import { test } from 'node:test';
import {
  checkAdmissionsWithKernel,
  checkedKernelDescriptor,
  defaultCheckedKernel,
} from './checked-kernel-provider.mjs';
import { kernelContractV1 } from './kernel-contract.mjs';

const emptyAdmissions = JSON.stringify({
  admissions: [],
  format: 'proofscript-checked-admissions',
  version: 2,
});

test('Lean WASM is the checked-profile default and remains host-side', () => {
  assert.equal(defaultCheckedKernel, 'lean434-wasm');
  assert.equal(checkedKernelDescriptor().package, '@proofscript/pskernel-lean-wasm');
  assert.equal(checkedKernelDescriptor().execution, 'wasm-node');
  assert.equal(checkedKernelDescriptor().kernelContract, kernelContractV1.id);
  assert.equal(
    checkedKernelDescriptor().kernelContractSha256,
    kernelContractV1.sha256,
  );
});

test('real bundled default WASM provider accepts canonical empty module', async () => {
  const checked = await checkAdmissionsWithKernel(emptyAdmissions);
  assert.equal(checked.descriptor.selector, 'lean434-wasm');
  assert.equal(checked.result.accepted, true);
  assert.equal(checked.result.profile, 'lean4.34-core');
});

test('native Lean provider remains an explicit alternative', () => {
  const descriptor = checkedKernelDescriptor('lean434');
  assert.equal(descriptor.selector, 'lean434');
  assert.equal(descriptor.package, '@proofscript/pskernel-lean');
  assert.equal(descriptor.execution, 'native');
});

test('unknown kernel selector fails closed', async () => {
  await assert.rejects(
    checkAdmissionsWithKernel(emptyAdmissions, 'automatic-fallback'),
    /KERNEL_UNSUPPORTED/,
  );
});
