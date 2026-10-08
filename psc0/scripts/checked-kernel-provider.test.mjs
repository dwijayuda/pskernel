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

test('native PSKernel Core is selected by default; Lean WASM is an explicit alternative', () => {
  assert.equal(defaultCheckedKernel, 'pskernel-core');
  assert.equal(checkedKernelDescriptor().package, '@proofscript/pskernel-core');
  assert.equal(checkedKernelDescriptor().execution, 'lean-native');
  assert.equal(checkedKernelDescriptor('lean434-wasm').execution, 'wasm-node');
});
test('native PSKernel Core accepts canonical empty module', async () => {
  const checked = await checkAdmissionsWithKernel(emptyAdmissions, 'pskernel-core');
  assert.equal(checked.descriptor.selector, 'pskernel-core');
  assert.equal(checked.result.accepted, true);
  assert.equal(checked.result.provider, 'pskernel-core-native');
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
