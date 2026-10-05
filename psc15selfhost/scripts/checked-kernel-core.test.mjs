import assert from 'node:assert/strict';
import test from 'node:test';
import { chmod, mkdtemp, writeFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { checkCoreAdmissions, assertCoreProviderResponse } from './checked-kernel-core.mjs';
import { coreCheckedIdentity } from './checked-kernel-identity.mjs';
import { providerCorpus, envelope } from './pskernel-core-provider-corpus.mjs';

test('core response identity is exact and contradictory success is rejected', () => {
  const valid = { ...coreCheckedIdentity, accepted: true };
  assert.equal(assertCoreProviderResponse(valid), valid);
  for (const field of Object.keys(coreCheckedIdentity)) {
    assert.throws(() => assertCoreProviderResponse({ ...valid, [field]: 'wrong' }), /IDENTITY/);
  }
  assert.throws(() => assertCoreProviderResponse({ ...valid, accepted: 'true' }), /RESULT_ACCEPTED/);
  assert.throws(() => assertCoreProviderResponse({ ...valid, errorKind: 'resource-exhausted' }), /CONTRADICTORY/);
  assert.throws(() => assertCoreProviderResponse({ ...valid, accepted: false, errorKind: 'unknown', message: '' }), /INVALID_FAILURE/);
});

test('native core rejects malformed and unsupported wire forms without partial admission', () => {
  const definition = structuredClone(providerCorpus.find(f => f.id === 'large-natural').admissions[0]);
  const failures = [
    ['{', 'malformed-request'],
    [JSON.stringify({ format: 'proofscript-checked-admissions', version: 1, admissions: [] }), 'protocol-version'],
    [envelope([{ kind: 'axiom', declaration: {} }]), 'malformed-request'],
    [envelope([{ kind: 'inductive', declaration: { lp: [], np: 0, ts: [] } }]), 'malformed-request'],
    [envelope([{ ...definition, declaration: { ...definition.declaration, s: 'unsafe' } }]), 'malformed-request'],
    [envelope([{ ...definition, declaration: { ...definition.declaration, h: { k: 'regular', h: '4294967296' } } }]), 'malformed-request'],
    [envelope([{ ...definition, declaration: { ...definition.declaration, h: { k: 'regular', h: '01' } } }]), 'malformed-request'],
  ];
  for (const [source, kind] of failures) {
    const result = checkCoreAdmissions(source, { timeoutMs: 10000 });
    assert.equal(result.accepted, false);
    assert.equal(result.errorKind, kind);
  }
  assert.equal(checkCoreAdmissions(envelope([definition])).accepted, true);
});

async function withStub(body, fn) {
  const dir = await mkdtemp(path.join(tmpdir(), 'm4-provider-transport-'));
  try {
    const binaryPath = path.join(dir, 'provider');
    await writeFile(binaryPath, `#!${process.execPath}\n${body}\n`);
    await chmod(binaryPath, 0o755);
    await fn(binaryPath);
  } finally { await rm(dir, { recursive: true, force: true }); }
}

for (const [label, source, pattern] of [
  ['timeout', 'setInterval(() => {}, 1000)', /PROCESS_FAILED: ETIMEDOUT/],
  ['crash', 'process.exit(4)', /PROCESS_FAILED: 4/],
  ['invalid JSON', 'console.log("not json")', /RESPONSE_INVALID_JSON/],
  ['wrong provider', `console.log(${JSON.stringify(JSON.stringify({ ...coreCheckedIdentity, provider: 'lean4-cpp', accepted: true }))})`, /IDENTITY: provider/],
]) test(`core transport fails closed on ${label}`, { skip: process.platform === 'win32' }, () =>
  withStub(source, binaryPath => {
    assert.throws(() => checkCoreAdmissions(envelope([]), { binaryPath, timeoutMs: label === 'timeout' ? 200 : 5000 }), pattern);
  }));
