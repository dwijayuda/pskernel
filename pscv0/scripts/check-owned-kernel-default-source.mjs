import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { defaultCheckedKernel, checkedKernelSelectors, checkedKernelDescriptor } from './checked-kernel-provider.mjs';
import { bootstrapPackageViolation } from './bootstrap-closure-contract.mjs';

assert.equal(defaultCheckedKernel, 'lean434-wasm');
assert.deepEqual(checkedKernelSelectors, ['lean434-wasm', 'lean434', 'pskernel-core.old3', 'pskernel-core']);
assert.equal(checkedKernelDescriptor().package, '@proofscript/pskernel-lean-wasm');
assert.equal(checkedKernelDescriptor().execution, 'wasm-node');
for (const name of ['pskernel-core','pskernel-core.old2','pskernel-core.old3','pskernel-lean','pskernel-lean-wasm','pskernel-core.old']) {
  assert(bootstrapPackageViolation(name));
}
for (const file of ['checked-owned-kernel.mjs', 'checked-owned-kernel-worker.mjs']) {
  const source = readFileSync(new URL(file, import.meta.url), 'utf8');
  assert(!/pskernel-lean|lean434|runCheckedSeedSession|\.\.\/.*test\//u.test(source),
    'owned runtime must remain self-contained when explicitly selected');
}
console.log('PSC2_CHECKED_DEFAULT_SOURCE: PASS (Lean WASM default; native Lean and owned kernel remain explicit alternatives outside compiler bootstrap closure)');
