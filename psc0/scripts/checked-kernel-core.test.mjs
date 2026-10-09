import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { existsSync, mkdtempSync, readFileSync, realpathSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { test } from 'node:test';
import { assertCoreProviderResponse, checkCoreAdmissions } from './checked-kernel-core.mjs';
import { coreCheckedIdentity } from './checked-kernel-identity.mjs';
import { checkAdmissionsWithKernel, checkedKernelDescriptor } from './checked-kernel-provider.mjs';

const emptyAdmissions = JSON.stringify({
  format: 'proofscript-checked-admissions', version: 2, admissions: [],
});
const response = extra => ({ ...coreCheckedIdentity, ...extra });
const digest = bytes => createHash('sha256').update(bytes).digest('hex');
const posix = process.platform !== 'win32';
const qualifiedPlatform = process.platform === 'linux' && process.arch === 'x64';

// These executables exercise the unchanged transport only. The protected
// selector must reject their bytes even when they forge all identity fields.
function executable(t, body) {
  const directory = mkdtempSync(path.join(tmpdir(), 'psc0-core-transport-'));
  t.after(() => rmSync(directory, { recursive: true, force: true }));
  const binaryPath = path.join(directory, 'provider.mjs');
  writeFileSync(binaryPath, '#!' + process.execPath + '\n' + body + '\n', { mode: 0o700 });
  return { binaryPath, directory };
}

test('native identity rejects a generated-owned or Lean 4.35 response', () => {
  assert.throws(() => assertCoreProviderResponse(response({
    accepted: true, provider: 'psc-generated-owned',
  })), /PSC_KERNEL_CORE_IDENTITY/);
  assert.throws(() => assertCoreProviderResponse(response({
    accepted: true, leanVersion: '4.35.0-rc4',
  })), /PSC_KERNEL_CORE_IDENTITY/);
});

test('a decision must be explicit and cannot contradict its success flag', () => {
  for (const accepted of [undefined, null, 'true', 1]) {
    assert.throws(() => assertCoreProviderResponse(response({ accepted })), /RESULT_ACCEPTED/);
  }
  assert.throws(() => assertCoreProviderResponse(response({
    accepted: true, errorKind: 'kernel-rejection',
  })), /CONTRADICTORY_RESPONSE/);
  assert.throws(() => assertCoreProviderResponse(response({
    accepted: false, errorKind: 'unknown', message: 'failure',
  })), /INVALID_FAILURE/);
  const rejected = response({
    accepted: false, errorKind: 'kernel-rejection', declarationIndex: 0, message: 'type mismatch',
  });
  assert.equal(assertCoreProviderResponse(rejected).accepted, false);
});

test('prototype names and legacy aliases cannot select a provider', async () => {
  for (const selector of ['constructor', '__proto__', 'toString', 'psc-generated-owned', 'automatic-fallback']) {
    assert.throws(() => checkedKernelDescriptor(selector), /KERNEL_UNSUPPORTED/);
    await assert.rejects(checkAdmissionsWithKernel(emptyAdmissions, selector), /KERNEL_UNSUPPORTED/);
  }
});

test('malformed canonical envelopes fail before opening a provider', async () => {
  for (const source of ['not-json', '[]', '{"format":"proofscript-checked-admissions","version":1,"admissions":[]}']) {
    await assert.rejects(checkAdmissionsWithKernel(source), /KERNEL_CONTRACT_ADMISSIONS/);
  }
  await assert.rejects(checkAdmissionsWithKernel(emptyAdmissions, 'pskernel-core', {
    nativeBinaryPath: 'project/provider',
  }), /PSC0_KERNEL_CORE_PATH/);
});

test('transport sends the exact checked bytes and fixed command', { skip: !posix }, t => {
  const { binaryPath } = executable(t,
    "import { readFileSync } from 'node:fs';\n" +
    'if (JSON.stringify(process.argv.slice(2)) !== \'["--check"]\' || readFileSync(0, \'utf8\') !== ' +
    JSON.stringify(emptyAdmissions) + ') process.exit(7);\n' +
    'process.stdout.write(' + JSON.stringify(JSON.stringify(response({ accepted: true }))) + ');');
  assert.equal(checkCoreAdmissions(emptyAdmissions, { binaryPath }).accepted, true);
});

test('transport does not treat exit zero or parseable output as acceptance', { skip: !posix }, t => {
  const malformed = executable(t, 'process.stdout.write("not-json");');
  assert.throws(() => checkCoreAdmissions(emptyAdmissions, { binaryPath: malformed.binaryPath }), /INVALID_JSON/);
  const failed = executable(t,
    'process.stdout.write(' + JSON.stringify(JSON.stringify(response({ accepted: true }))) + ');\nprocess.exit(7);');
  assert.throws(() => checkCoreAdmissions(emptyAdmissions, { binaryPath: failed.binaryPath }), /PROCESS_FAILED/);
  const rejected = executable(t, 'process.stdout.write(' + JSON.stringify(JSON.stringify(response({
    accepted: false, errorKind: 'kernel-rejection', message: 'type mismatch',
  }))) + ');');
  assert.equal(checkCoreAdmissions(emptyAdmissions, { binaryPath: rejected.binaryPath }).accepted, false);
});

test('transport enforces the fixed timeout budget and terminates a stalled process', { skip: !posix }, t => {
  const { binaryPath } = executable(t, 'setInterval(() => {}, 1000);');
  assert.throws(() => checkCoreAdmissions(emptyAdmissions, { binaryPath, timeoutMs: 100 }), /PROCESS_FAILED/);
  for (const timeoutMs of [0, -1, 60001, Infinity]) {
    assert.throws(() => checkCoreAdmissions(emptyAdmissions, { binaryPath, timeoutMs }), /TIMEOUT_BUDGET/);
  }
});

test('the protected selector rejects a forged executable before it can run', { skip: !qualifiedPlatform }, async t => {
  const { directory, binaryPath } = executable(t, '');
  const marker = path.join(directory, 'executed');
  writeFileSync(binaryPath,
    '#!' + process.execPath + '\n' +
    "import { writeFileSync } from 'node:fs';\n" +
    'writeFileSync(' + JSON.stringify(marker) + ', "ran");\n' +
    'process.stdout.write(' + JSON.stringify(JSON.stringify(response({ accepted: true }))) + ');\n',
    { mode: 0o700 });
  await assert.rejects(checkAdmissionsWithKernel(emptyAdmissions, 'pskernel-core', {
    nativeBinaryPath: binaryPath,
    expectedBinarySha256: digest(readFileSync(binaryPath)),
  }), /PSC0_KERNEL_CORE_ARTIFACT_MISMATCH/);
  assert.equal(existsSync(marker), false);
});

test('the protected route uses its explicit path despite a provider environment override', { skip: !qualifiedPlatform }, async t => {
  const { binaryPath, directory } = executable(t, 'process.exit(0);');
  const previous = process.env.PSC_KERNEL_CORE_PROVIDER_BIN;
  process.env.PSC_KERNEL_CORE_PROVIDER_BIN = binaryPath;
  t.after(() => {
    if (previous === undefined) delete process.env.PSC_KERNEL_CORE_PROVIDER_BIN;
    else process.env.PSC_KERNEL_CORE_PROVIDER_BIN = previous;
  });
  await assert.rejects(checkAdmissionsWithKernel(emptyAdmissions, 'pskernel-core', {
    nativeBinaryPath: path.join(directory, 'missing'),
  }), /PSC0_KERNEL_CORE_ARTIFACT_UNAVAILABLE/);
});

const nativeBinaryPath = process.env.PSC0_TEST_KERNEL_CORE_PROVIDER_BIN;
test('the exact native artifact binds decisions to its executable and input bytes', {
  skip: !nativeBinaryPath && 'Set PSC0_TEST_KERNEL_CORE_PROVIDER_BIN to the separate pinned PR84 build',
}, async () => {
  const checked = await checkAdmissionsWithKernel(emptyAdmissions, 'pskernel-core', { nativeBinaryPath });
  assert.equal(checked.result.accepted, true);
  for (const [field, value] of Object.entries(coreCheckedIdentity)) assert.equal(checked.result[field], value);
  assert.equal(checked.descriptor.sourceCommit, '963030dc2d154008fccc82e7c8ed29331f138799');
  assert.equal(checked.descriptor.sourceTree, '38c8c55bd2b214753e56c58c15c4901c32c01b86');
  assert.equal(checked.descriptor.binarySha256, '88f2d20ea733742d48724ecbdc903271e18bcfcccc8682be596a676aef68e3ec');
  assert.equal(checked.descriptor.binarySha256, digest(readFileSync(nativeBinaryPath)));
  assert.equal(checked.descriptor.binaryPath, realpathSync(nativeBinaryPath));
  assert.equal(checked.descriptor.canonicalAdmissionsSha256, digest(Buffer.from(emptyAdmissions, 'utf8')));
  assert.ok(Object.isFrozen(checked));
  assert.ok(Object.isFrozen(checked.result));
  assert.ok(Object.isFrozen(checked.descriptor));
  assert.ok(Object.isFrozen(checked.descriptor.resourcePolicy));

  const invalid = JSON.stringify({
    format: 'proofscript-checked-admissions', version: 2,
    admissions: [{ kind: 'constant', declaration: {
      k: 'definition', n: { k: 's', p: { k: 'a' }, v: 'PlatformInvalid' }, lp: [],
      t: { k: 'sort', l: { k: 'z' } }, v: { k: 'sort', l: { k: 'z' } },
      s: 'safe', h: { k: 'regular', h: '0' },
    } }],
  });
  const rejected = await checkAdmissionsWithKernel(invalid, 'pskernel-core', { nativeBinaryPath });
  assert.equal(rejected.result.accepted, false);
  assert.equal(rejected.result.errorKind, 'kernel-rejection');
  assert.equal(rejected.descriptor.canonicalAdmissionsSha256, digest(Buffer.from(invalid, 'utf8')));
  assert.equal((await checkAdmissionsWithKernel(emptyAdmissions, 'pskernel-core', { nativeBinaryPath })).result.accepted, true);
});
