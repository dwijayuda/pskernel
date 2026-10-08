import assert from 'node:assert/strict';
import test from 'node:test';
import { analyzeKernelClosure, kernelEntryRelative, kernelModuleRelative } from './joint-kernel-closure.mjs';

test('joint checker root resolves solely to portable kernel implementation modules', async () => {
  const result = await analyzeKernelClosure();
  assert.equal(result.entry, kernelEntryRelative);
  assert.equal(result.moduleCount, result.sourceFiles);
  assert.ok(result.moduleCount >= 79, 'expected full PSKernel Core source');
  assert.deepEqual(result.missing, []);
  assert.equal(result.proofModules, 0);
  assert.equal(result.metatheoryModules, 0);
  assert.ok(result.modules.every(p => p.startsWith('packages/pskernel-core/src/Ps/KernelCore/') &&
    p.endsWith('.lean')));
  assert.match(result.sourceSha256, /^[a-f0-9]{64}$/u);
});

test('joint closure import resolver refuses all proof, metatheory, host, and legacy imports', () => {
  for (const name of [
    'Ps.KernelCore', 'Ps.KernelCore..Checker', 'Ps.Host.KernelCoreProvider',
    'Ps.KernelCore.Proof..Bad', 'Ps.Foundation.List',
    'ProofScript.Core', '../metatheory', 'Ps.KernelCore.Foo/Bar',
  ]) assert.throws(() => kernelModuleRelative(name), /JOINT_IMPORT_OUTSIDE_IMPLEMENTATION/u);
});
