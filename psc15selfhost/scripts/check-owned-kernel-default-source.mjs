import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { defaultCheckedKernel, checkedKernelSelectors, checkedKernelDescriptor } from './checked-kernel-provider.mjs';
import { bootstrapPackageViolation } from './bootstrap-closure-contract.mjs';

assert.equal(defaultCheckedKernel, 'lean434');
assert.deepEqual(checkedKernelSelectors, ['lean434', 'lean434-wasm', 'pskernel-core']);
assert.equal(checkedKernelDescriptor().package, '@proofscript/pskernel-lean');
assert.equal(checkedKernelDescriptor().execution, 'native');
for (const name of ['pskernel-core','pskernel-lean','pskernel-lean-wasm','pskernel-core.old']) {
  assert(bootstrapPackageViolation(name));
}
for (const file of ['checked-owned-kernel.mjs', 'checked-owned-kernel-worker.mjs']) {
  const source = readFileSync(new URL(file, import.meta.url), 'utf8');
  assert(!/pskernel-lean|lean434|runCheckedSeedSession|\.\.\/.*test\//u.test(source),
    'owned runtime must remain self-contained when explicitly selected');
}
console.log('PSC2_NATIVE_DEFAULT_SOURCE: PASS (native Lean host default; every kernel outside compiler bootstrap closure)');
