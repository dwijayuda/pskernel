import assert from 'node:assert/strict';
import { defaultCheckedKernel, checkedKernelSelectors, checkedKernelDescriptor } from './checked-kernel-provider.mjs';
import { bootstrapPackageViolation } from './bootstrap-closure-contract.mjs';
import { coreCheckedIdentity } from './checked-kernel-identity.mjs';

assert.equal(defaultCheckedKernel, 'pskernel-core');
assert.deepEqual(checkedKernelSelectors, ['pskernel-core', 'lean434-wasm', 'lean434']);
assert.equal(checkedKernelDescriptor().package, '@proofscript/pskernel-core');
assert.equal(checkedKernelDescriptor().execution, 'lean-native');
assert.equal(coreCheckedIdentity.provider, 'pskernel-core-native');
assert.equal(checkedKernelDescriptor('lean434-wasm').execution, 'wasm-node');
for (const name of ['pskernel-core', 'pskernel-lean', 'pskernel-lean-wasm', 'pskernel']) {
  assert(bootstrapPackageViolation(name), 'kernel must remain outside portable self-host closure: ' + name);
}
console.log('PSC0_NATIVE_CORE_DEFAULT: PASS (explicit kernel choice, no fallback, compiler closure unchanged)');
