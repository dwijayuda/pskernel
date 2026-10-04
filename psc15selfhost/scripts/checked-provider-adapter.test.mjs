import assert from 'node:assert/strict';
import { test } from 'node:test';
import { mkdtemp, writeFile, chmod, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { checkCanonicalAdmissions } from '../packages/pskernel-lean/index.mjs';
import { leanCheckedIdentity } from './kernel-checked-session.mjs';
async function withStub(body, fn) {
  const dir = await mkdtemp(path.join(tmpdir(), 'psc2-provider-double-'));
  try {
    const binaryPath = path.join(dir, 'provider');
    await writeFile(binaryPath, `#!${process.execPath}\n${body}\n`); await chmod(binaryPath, 0o755);
    await fn(binaryPath);
  } finally { await rm(dir, { recursive: true, force: true }); }
}
test('transport double: mismatched profile rejected', { skip: process.platform === 'win32' }, () =>
  withStub(`console.log(${JSON.stringify(JSON.stringify({ ...leanCheckedIdentity, profile: 'wrong', accepted: true }))})`, binaryPath => {
    assert.throws(() => checkCanonicalAdmissions('{}', { binaryPath }), /profile mismatch/);
  }));
test('transport double: native provider hang times out', { skip: process.platform === 'win32' }, () =>
  withStub('setInterval(() => {}, 1000)', binaryPath => {
    assert.throws(() => checkCanonicalAdmissions('{}', { binaryPath, timeoutMs: 100 }), /ETIMEDOUT|timed out/);
  }));
test('invalid timeout cannot disable the bound', () => {
  assert.throws(() => checkCanonicalAdmissions('{}', { binaryPath: '/unused', timeoutMs: 0 }), /positive integer/);
});
