import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import crypto from 'node:crypto';
import {fileURLToPath} from 'node:url';
import {createPinnedKernelSession} from '../lsp/dist/kernel-session.mjs';

const toolsRoot = fileURLToPath(new URL('../', import.meta.url));
const compilerRoot = path.join(toolsRoot, 'lsp/compiler/package');
const sha = value => crypto.createHash('sha256').update(value).digest('hex');
const root = {k: 'a'};
const name = value => ({k: 's', p: root, v: value});
const nat = {k: 'const', n: name('Nat'), ls: []};
// Canonical valid and ill-typed definitions follow the actual kernel fixtures in
// psc1/scripts/kernel435-fixtures.mjs. Both go to the real official Wasm checker.
const admission = (label, value) => JSON.stringify({protocol: 'pskernel-lean/1',
  format: 'proofscript-checked-admissions', version: 2,
  admissions: [{kind: 'constant', declaration: {k: 'definition', h: {k: 'regular', h: '1'},
    lp: [], n: name(label), s: 'safe', t: nat, v: value}}]});

test('retained genuine kernel health still checks and rejects each new graph', {timeout: 60000}, async () => {
  const session = createPinnedKernelSession(compilerRoot);
  const firstSource = admission('Profile.First', {k: 'nat', v: '1'});
  const invalidSource = admission('Profile.Invalid', {k: 'sort', l: {k: 'z'}});
  const nextSource = admission('Profile.Next', {k: 'nat', v: '2'});
  const first = await session.checkCanonicalAdmissions(firstSource);
  assert.equal(first.result.accepted, true);
  assert.equal(first.reusedKernelHealth, false);
  assert.equal(first.admissionsSha256, sha(firstSource));
  const refused = await session.checkCanonicalAdmissions(invalidSource);
  assert.equal(refused.result.accepted, false, 'A healthy provider is not evidence that an ill-typed graph is accepted');
  assert.equal(refused.reusedKernelHealth, true);
  assert.equal(refused.admissionsSha256, sha(invalidSource));
  const next = await session.checkCanonicalAdmissions(nextSource);
  assert.equal(next.result.accepted, true);
  assert.equal(next.reusedKernelHealth, true);
  assert.equal(next.admissionsSha256, sha(nextSource));
  assert.notEqual(next.admissionsSha256, first.admissionsSha256);
  for (const checked of [first, refused, next]) {
    assert.equal(checked.result.protocol, 'pskernel-lean/1');
    assert.equal(checked.result.provider, 'lean4-cpp');
    assert.equal(checked.result.leanVersion, '4.35.0');
    assert.equal(checked.result.leanCommit, 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc');
  }
  const out = path.join(toolsRoot, 'dist'); await fs.mkdir(out, {recursive: true});
  await fs.writeFile(path.join(out, 'kernel-session-test-receipt.json'), JSON.stringify({
    schema: 'psc1-kernel-session-tests/1', testedCommit: process.env.GITHUB_SHA, compilerMocks: false,
    observations: [first, refused, next].map(checked => ({accepted: checked.result.accepted,
      admissionsSha256: checked.admissionsSha256, reusedKernelHealth: checked.reusedKernelHealth})),
  }, null, 2) + '\n');
});

test('a changed pinned resource closes a previously healthy kernel session', {timeout: 60000}, async () => {
  const temporary = await fs.mkdtemp(path.join(os.tmpdir(), 'psc1-kernel-pin-test-'));
  const copiedRoot = path.join(temporary, 'compiler');
  const providerPath = 'node_modules/@proofscript/pskernel-lean-wasm/dist/index.js';
  const originalBytes = await fs.readFile(path.join(compilerRoot, providerPath));
  try {
    // Only this disposable copy is changed. The installed/qualified input is read-only.
    await fs.cp(compilerRoot, copiedRoot, {recursive: true});
    const session = createPinnedKernelSession(copiedRoot);
    const source = admission('Profile.PinCheck', {k: 'nat', v: '7'});
    const checked = await session.checkCanonicalAdmissions(source);
    assert.equal(checked.result.accepted, true);
    await fs.appendFile(path.join(copiedRoot, providerPath), '\n// Intentional pin-integrity test in a disposable copy.\n');
    await assert.rejects(session.checkCanonicalAdmissions(source), /PSC1_LSP_KERNEL_RESOURCE_CHANGED/);
    await assert.rejects(session.checkCanonicalAdmissions(source), /PSC1_LSP_KERNEL_SESSION_CLOSED/);
    assert.equal(sha(await fs.readFile(path.join(compilerRoot, providerPath))), sha(originalBytes));
  } finally {
    await fs.rm(temporary, {recursive: true, force: true, maxRetries: 5, retryDelay: 100});
  }
});
