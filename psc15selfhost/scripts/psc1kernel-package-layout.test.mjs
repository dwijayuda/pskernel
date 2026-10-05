import assert from 'node:assert/strict';
import fs from 'node:fs';
import test from 'node:test';
import { packageForModule } from './workspace-layout.mjs';
import { bootstrapPackageViolation } from './bootstrap-closure-contract.mjs';
import { checkedKernelDescriptor, defaultCheckedKernel } from './checked-kernel-provider.mjs';

const root = new URL('../', import.meta.url);
const json = file => JSON.parse(fs.readFileSync(new URL(file, root), 'utf8'));

test('canonical and archived package identities resolve to different sources', () => {
  const core = json('packages/pskernel-core/package.json');
  const archived = json('packages/pskernel-core.old3/package.json');
  assert.equal(core.name, '@proofscript/pskernel-core');
  assert.equal(archived.name, '@proofscript/pskernel-core.old3');
  assert.equal(packageForModule('Ps.KernelCore.Checker.Knot'), 'pskernel-core');
  assert.equal(packageForModule('Ps.Kernel.TypeCheck'), 'pskernel-core.old3');
  assert(fs.existsSync(new URL('packages/pskernel-core/src/Ps/KernelCore/Checker/Knot.lean', root)));
  assert(fs.existsSync(new URL('packages/pskernel-core.old3/src/Ps/Kernel/TypeCheck.lean', root)));
  assert(!fs.existsSync(new URL('packages/pskernel-selfhost', root)));
  for (const manifest of [core, archived]) {
    assert.equal(manifest.private, true);
    assert.equal(manifest.proofscript.authoritative, false);
    assert.equal(manifest.proofscript.bootstrap, false);
  }
});

test('package rename cannot silently promote or substitute a checking provider', () => {
  assert.equal(defaultCheckedKernel, 'lean434-wasm');
  assert.equal(checkedKernelDescriptor().package, '@proofscript/pskernel-lean-wasm');
  assert.equal(checkedKernelDescriptor('pskernel-core.old3').package, '@proofscript/pskernel-core.old3');
  assert.equal(checkedKernelDescriptor('pskernel-core').authority, 'explicit-candidate');
  assert.equal(checkedKernelDescriptor('pskernel-core').package, '@proofscript/pskernel-core');
  assert(bootstrapPackageViolation('pskernel-core'));
  assert(bootstrapPackageViolation('pskernel-core.old3'));
});
