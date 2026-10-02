import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { defaultCheckedKernel, checkedKernelSelectors } from './checked-kernel-provider.mjs';
import { bootstrapPackageViolation } from './bootstrap-closure-contract.mjs';

assert.equal(defaultCheckedKernel, 'pskernel-core');
assert.deepEqual(checkedKernelSelectors, ['pskernel-core', 'lean434-wasm', 'lean434']);
assert.equal(bootstrapPackageViolation('pskernel-core'), undefined);
for (const name of ['pskernel-lean', 'pskernel-lean-wasm', 'pskernel-core.old']) assert(bootstrapPackageViolation(name));
for (const file of ['checked-owned-kernel.mjs', 'checked-owned-kernel-worker.mjs']) {
  const source = readFileSync(new URL(file, import.meta.url), 'utf8');
  assert(!/pskernel-lean|lean434|runCheckedSeedSession|\.\.\/.*test\//u.test(source), 'owned runtime must not import a reference checker or test semantics');
}
const worker = readFileSync(new URL('checked-owned-kernel-worker.mjs', import.meta.url), 'utf8');
for (const required of ['k.psKernelAdmissionStart', 'k.psKernelAdmissionStep', 'generatedKernelSha256', "errorKind: 'outOfFuel'"]) {
  assert(worker.includes(required), `missing owned checking boundary: ${required}`);
}
console.log('PSC2_OWNED_DEFAULT_SOURCE: PASS (owned generated transitions, bounded execution, explicit references outside closure)');
