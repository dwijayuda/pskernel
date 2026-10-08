import assert from 'node:assert/strict';
import { test } from 'node:test';
import {
  checkAdmissionsWithKernel,
  checkedKernelDescriptor,
  defaultCheckedKernel,
} from './checked-kernel-provider.mjs';

const emptyAdmissions = JSON.stringify({
  admissions: [],
  format: 'proofscript-checked-admissions',
  version: 2,
});

test('Lean WASM is the checked-profile default and remains host-side', () => {
  assert.equal(defaultCheckedKernel, 'lean434-wasm');
  assert.equal(checkedKernelDescriptor().package, '@proofscript/pskernel-lean-wasm');
  assert.equal(checkedKernelDescriptor().execution, 'wasm-node');
});

test('real bundled WASM provider accepts canonical empty module', async () => {
  const checked = await checkAdmissionsWithKernel(emptyAdmissions, 'lean434-wasm');
  assert.equal(checked.descriptor.selector, 'lean434-wasm');
  assert.equal(checked.result.accepted, true);
  assert.equal(checked.result.profile, 'lean4.34-core');
});

test('real native Lean provider remains an explicit alternative', async () => {
  const checked = await checkAdmissionsWithKernel(emptyAdmissions, 'lean434');
  assert.equal(checked.descriptor.package, '@proofscript/pskernel-lean');
  assert.equal(checked.result.accepted, true);
  assert.equal(checked.result.profile, 'lean4.34-core');
});

test('unknown kernel selector fails closed', async () => {
  await assert.rejects(
    checkAdmissionsWithKernel(emptyAdmissions, 'automatic-fallback'),
    /KERNEL_UNSUPPORTED/,
  );
});
