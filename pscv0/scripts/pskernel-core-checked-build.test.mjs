import assert from 'node:assert/strict';
import test from 'node:test';
import { mkdtemp, readFile, writeFile, rm } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { buildChecked, defaultCheckedSeed } from './checked-build.mjs';
import { checkAdmissionsWithDual } from './checked-kernel-dual.mjs';
import { runCheckedSeedSession } from './checked-seed-session.mjs';

// CI uses the unchanged default authority. Local diagnostics may explicitly
// select the freshly built native Lean reference when WASM is not materialized.
const reference = process.env.PSC_M4_REFERENCE ?? 'lean434-wasm';
assert(['lean434', 'lean434-wasm'].includes(reference));
const seedPath = process.env.PSC2_CHECKED_SEED_BIN ?? defaultCheckedSeed;
assert(existsSync(seedPath), 'Build psc2_lean_checked_seed before the M4 integration gate');

test('dual-checked compiler output executes and its receipt binds the checked admissions', { timeout: 60000 }, async () => {
  const dir = await mkdtemp(path.join(tmpdir(), 'm4-checked-build-'));
  try {
    await writeFile(path.join(dir, 'package.json'), '{"type":"module"}');
    const entryPath = path.join(dir, 'Main.lean'), outputPath = path.join(dir, 'out.js');
    await writeFile(entryPath, 'inductive M4Flag where\n  | off\n  | on\ndef flag : M4Flag := M4Flag.on\ndef answer : Nat := 42\n');
    const receipt = await buildChecked({ entryPath, outputPath, seedPath, kernel: reference, dualCheck: 'pskernel-core' });
    const module = await import(pathToFileURL(outputPath).href);
    assert.equal(module.answer, 42n);
    assert.deepEqual(module.flag, module.M4Flag.on);
    assert.equal(receipt.dualCheck.decision, 'accepted');
    assert.equal(receipt.dualCheck.primary.selector, reference);
    assert.equal(receipt.dualCheck.secondary.selector, 'pskernel-core');
    assert.equal(receipt.dualCheck.canonicalAdmissionsSha256, receipt.canonicalAdmissionsSha256);
    assert.deepEqual(JSON.parse(await readFile(path.join(dir, 'out.checked.json'), 'utf8')), receipt);
  } finally { await rm(dir, { recursive: true, force: true }); }
});

test('ProofScript source can explicitly select native core', { timeout: 30000 }, async () => {
  const dir = await mkdtemp(path.join(tmpdir(), 'm4-core-ps-'));
  try {
    const entryPath = path.join(dir, 'Main.ps');
    await writeFile(entryPath, 'const answer: Nat := { 42 }\n');
    const receipt = await buildChecked({ entryPath, checkOnly: true, seedPath, kernel: 'pskernel-core' });
    assert.equal(receipt.provider.provider, 'pskernel-core-native');
  } finally { await rm(dir, { recursive: true, force: true }); }
});

test('dual rejection stops the actual compiler session before emission', { timeout: 30000 }, async () => {
  let rejected = false;
  await assert.rejects(runCheckedSeedSession({
    binaryPath: seedPath, sourceKind: 'lean', source: 'def M4InvalidBody : Nat := 42\n', emit: true,
    timeoutMs: 10000,
    checkAdmissions: async admissions => {
      const payload = JSON.parse(admissions);
      payload.admissions.at(-1).declaration.v = { k: 'sort', l: { k: 'z' } };
      const checked = await checkAdmissionsWithDual(JSON.stringify(payload), reference, 'pskernel-core', { timeoutMs: 10000 });
      rejected = checked.parity.decision.startsWith('rejected:');
      return checked.result;
    },
  }), /KERNEL_REJECTED/);
  assert(rejected);
});
