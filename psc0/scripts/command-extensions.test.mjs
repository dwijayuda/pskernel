import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, mkdir, writeFile, readFile, rm, symlink } from 'node:fs/promises';
import path from 'node:path';
import os from 'node:os';
import { createHash } from 'node:crypto';
import {
  validateCommandExtensionConfig, discoverCommandExtensions, executeCommandExtension,
  completedCommandRecords, assertCommandExtensionCurrent,
} from './command-extensions.mjs';
import { assertCommandWasmProfile, commandWasmLimits } from './command-wasm-profile.mjs';

const digest = bytes => createHash('sha256').update(bytes).digest('hex');
const canonical = Buffer.from('AGFzbQEAAAABBgFgAX8BfwMCAQAHDQEJcHNjX2V2ZW50AAAKBwEFACAARQs=', 'base64');
const prefix = Array.from(canonical.subarray(0, 35));
const enable = name => ({ package: name, enable: ['command:dev'] });
const u32 = number => {
  const bytes = [];
  do { const part = number & 127; number >>>= 7; bytes.push(part | (number ? 128 : 0)); } while (number);
  return bytes;
};
function moduleBytes(instructions, locals = [0], modulePrefix = prefix) {
  const body = [...locals, ...instructions];
  const payload = [1, ...u32(body.length), ...body];
  return Buffer.from([...modulePrefix, 10, ...u32(payload.length), ...payload]);
}
async function fixture(t, { name = 'psdev', bytes = canonical, active = true, descriptor = {}, bom = false } = {}) {
  const root = await mkdtemp(path.join(os.tmpdir(), 'psc-command λ '));
  t.after(() => rm(root, { recursive: true, force: true }));
  const packageRoot = path.join(root, 'node_modules', ...name.split('/'));
  await mkdir(packageRoot, { recursive: true });
  const version = '0.1.0-preview.2';
  const spec = 'file:./command-demo.tgz';
  const project = { name: 'fixture', private: true, devDependencies: { [name]: spec },
    proofscript: { profile: 'checked', extensions: active ? [enable(name)] : [] } };
  const lock = { name: 'fixture', lockfileVersion: 3, packages: {
    '': { name: 'fixture', devDependencies: { [name]: spec } },
    ['node_modules/' + name]: { version, resolved: spec,
      integrity: 'sha512-' + Buffer.alloc(64, 1).toString('base64') },
  } };
  const metadata = { name, version, private: true, main: './must-not-run.mjs' };
  const description = { schemaVersion: 1, protocol: 'psc-command/1', operations: ['command:dev'],
    entry: 'command.wasm', sha256: digest(bytes), ...descriptor };
  const json = value => (bom ? '\uFEFF' : '') + JSON.stringify(value, null, 2) + '\n';
  await Promise.all([
    writeFile(path.join(root, 'package.json'), json(project)),
    writeFile(path.join(root, 'package-lock.json'), json(lock)),
    writeFile(path.join(packageRoot, 'package.json'), json(metadata)),
    writeFile(path.join(packageRoot, 'proofscript-extension.json'), json(description)),
    writeFile(path.join(packageRoot, 'command.wasm'), bytes),
    writeFile(path.join(packageRoot, 'must-not-run.mjs'),
      "import fs from 'node:fs'; fs.writeFileSync(new URL('./HOST_ENTRY_RAN', import.meta.url), 'bad'); throw new Error('HOST_ENTRY_RAN');\n"),
  ]);
  return { root, packageRoot, project, lock, metadata, description };
}
const discover = f => discoverCommandExtensions({ projectRoot: f.root, projectMetadata: f.project });
const run = selection => {
  const states = [];
  return { states, promise: executeCommandExtension(selection, { event: 0, onState: state => { states.push(state); } }) };
};
async function overwriteJson(file, value) { await writeFile(file, JSON.stringify(value, null, 2) + '\n'); }

test('packaged psdev and independently named demo carry the canonical no-import module', async () => {
  for (const directory of ['../packages/psdev/', '../examples/extensions/pshello/']) {
    const bytes = await readFile(new URL(directory + 'command.wasm', import.meta.url));
    const descriptor = JSON.parse(await readFile(new URL(directory + 'proofscript-extension.json', import.meta.url), 'utf8'));
    assert.deepEqual(bytes, canonical);
    assert.equal(digest(bytes), '63b9c0f41bfc46a06b148a92b370c73f950d1b89b544b290cc7e83e15998e279');
    assert.equal(descriptor.sha256, digest(bytes));
    assert.equal(assertCommandWasmProfile(bytes), true);
    assert.equal(WebAssembly.validate(bytes), true);
    assert.deepEqual(WebAssembly.Module.imports(new WebAssembly.Module(bytes)), []);
  }
});

test('configuration is explicit, bounded, independent of the publisher name, and unambiguous', () => {
  assert.deepEqual(validateCommandExtensionConfig(undefined), []);
  assert.deepEqual(validateCommandExtensionConfig([]), []);
  assert.deepEqual(validateCommandExtensionConfig([enable('@independent/ps-custom')]), [enable('@independent/ps-custom')]);
  for (const entries of [[enable('../escape')], [enable('Caps')], [{ ...enable('psdev'), trusted: true }],
    [{ package: 'psdev', enable: ['kernel:replace'] }], [{ package: 'psdev', enable: ['command:dev', 'command:build'] }]]) {
    assert.throws(() => validateCommandExtensionConfig(entries), /PSC_EXTENSION_CONFIGURATION/u);
  }
  assert.throws(() => validateCommandExtensionConfig([enable('psdev'), enable('@other/psdev')]),
    /PSC_DEV_EXTENSION_AMBIGUOUS/u);
});

test('installed but unactivated packages need no lockfile and never load', async t => {
  const f = await fixture(t, { active: false });
  await rm(path.join(f.root, 'package-lock.json'));
  assert.deepEqual(await discover(f), []);
  await assert.rejects(readFile(path.join(f.packageRoot, 'HOST_ENTRY_RAN')), { code: 'ENOENT' });
});

test('discovery reads only data; complete disclosure precedes the isolated call and binds the result', async t => {
  const f = await fixture(t, { bom: true });
  const [selection] = await discover(f);
  assert.equal(selection.report.status, 'configured');
  assert.equal(selection.report.instantiated, false);
  assert.equal(selection.report.moduleSha256, digest(canonical));
  const { states, promise } = run(selection);
  const execution = await promise;
  assert.deepEqual(states.map(state => state.status), ['attempted', 'executing', 'instantiated', 'completed']);
  assert.equal(states[1].instantiated, false);
  assert.equal(execution.requestBuild, true);
  assert.equal(execution.record.instantiated, true);
  assert.deepEqual(completedCommandRecords(execution), [execution.record]);
  assert.equal(Object.isFrozen(execution), true);
  assert.equal(Object.isFrozen(execution.record.grants), true);
  assert.equal(execution.record.engine.node, process.versions.node);
  assert.equal(execution.record.engine.v8, process.versions.v8);
  await assertCommandExtensionCurrent(execution);
  await assert.rejects(readFile(path.join(f.packageRoot, 'HOST_ENTRY_RAN')), { code: 'ENOENT' });
});

test('independently named exact registry dependency uses the identical boundary', async t => {
  const f = await fixture(t, { name: '@independent/ps-custom' });
  f.project.devDependencies['@independent/ps-custom'] = f.metadata.version;
  f.lock.packages[''].devDependencies['@independent/ps-custom'] = f.metadata.version;
  f.lock.packages['node_modules/@independent/ps-custom'].resolved =
    'https://registry.example.invalid/independent/ps-custom.tgz';
  await overwriteJson(path.join(f.root, 'package.json'), f.project);
  await overwriteJson(path.join(f.root, 'package-lock.json'), f.lock);
  const [selection] = await discover(f);
  const execution = await run(selection).promise;
  assert.equal(execution.record.package, '@independent/ps-custom');
  assert.equal(execution.record.requestBuild, true);
});

test('lockfile, direct dependency pin and installed identity are independently required', async t => {
  const f = await fixture(t);
  await rm(path.join(f.root, 'package-lock.json'));
  await assert.rejects(discover(f), /PSC_EXTENSION_LOCK_REQUIRED/u);
  await overwriteJson(path.join(f.root, 'package-lock.json'), f.lock);
  f.project.devDependencies.psdev = '^0.1.0';
  await overwriteJson(path.join(f.root, 'package.json'), f.project);
  await assert.rejects(discover(f), /PSC_EXTENSION_DEPENDENCY_PIN/u);
  f.project.devDependencies.psdev = 'file:./command-demo.tgz';
  await overwriteJson(path.join(f.root, 'package.json'), f.project);
  f.metadata.version = '9.0.0';
  await overwriteJson(path.join(f.packageRoot, 'package.json'), f.metadata);
  await assert.rejects(discover(f), /PSC_EXTENSION_PACKAGE_IDENTITY/u);
});

test('additional operations, authority fields and JS entry descriptors are refused', async t => {
  const f = await fixture(t);
  for (const changed of [{ ...f.description, trusted: true }, { ...f.description, entry: 'main.mjs' },
    { ...f.description, operations: ['command:dev', 'kernel:replace'] }]) {
    await overwriteJson(path.join(f.packageRoot, 'proofscript-extension.json'), changed);
    await assert.rejects(discover(f), /PSC_EXTENSION_DESCRIPTOR/u);
  }
});

test('linked lockfile packages and directory aliases do not enter the resolver', async t => {
  const f = await fixture(t);
  f.lock.packages['node_modules/psdev'].link = true;
  await overwriteJson(path.join(f.root, 'package-lock.json'), f.lock);
  await assert.rejects(discover(f), /PSC_EXTENSION_LOCK_REQUIRED/u);
  delete f.lock.packages['node_modules/psdev'].link;
  await overwriteJson(path.join(f.root, 'package-lock.json'), f.lock);
  const relocated = path.join(f.root, 'linked-package');
  await mkdir(relocated);
  await rm(f.packageRoot, { recursive: true });
  await symlink(relocated, f.packageRoot, process.platform === 'win32' ? 'junction' : 'dir');
  await assert.rejects(discover(f), /PSC_EXTENSION_LINK_UNSUPPORTED/u);
});

test('actual-byte tampering is disclosed before refusal and never reaches a worker', async t => {
  const f = await fixture(t);
  const changed = Buffer.from(canonical);
  changed[0] ^= 1;
  await writeFile(path.join(f.packageRoot, 'command.wasm'), changed);
  const [selection] = await discover(f);
  assert.equal(selection.report.moduleSha256, digest(changed));
  const { states, promise } = run(selection);
  await assert.rejects(promise, /PSC_EXTENSION_MODULE_HASH/u);
  assert.deepEqual(states.map(state => state.status), ['attempted', 'failed']);
  assert.equal(states[1].instantiated, false);
});

test('metadata or module replacement after discovery invalidates the captured operation', async t => {
  const f = await fixture(t);
  const [selection] = await discover(f);
  await writeFile(path.join(f.packageRoot, 'package.json'), JSON.stringify(f.metadata) + '\n');
  await assert.rejects(run(selection).promise, /PSC_EXTENSION_INPUT_CHANGED/u);
});

test('completed results are opaque; forged receipts and no-build proposals convey no authority', async t => {
  assert.throws(() => completedCommandRecords({ requestBuild: true, record: { status: 'completed' } }),
    /PSC_EXTENSION_EXECUTION_INVALID/u);
  await assert.rejects(executeCommandExtension({ report: {} }, { onState() {} }),
    /PSC_EXTENSION_SELECTION_INVALID/u);
  const f = await fixture(t, { bytes: moduleBytes([0x41, 0, 0x0b]) });
  const execution = await run((await discover(f))[0]).promise;
  assert.equal(execution.requestBuild, false);
  assert.throws(() => completedCommandRecords(execution), /PSC_EXTENSION_EXECUTION_INVALID/u);
});

test('a changed project policy after guest execution invalidates publication eligibility', async t => {
  const f = await fixture(t);
  const execution = await run((await discover(f))[0]).promise;
  f.project.proofscript.extensions = [];
  await overwriteJson(path.join(f.root, 'package.json'), f.project);
  await assert.rejects(assertCommandExtensionCurrent(execution), /PSC_EXTENSION_INPUT_CHANGED/u);
});

test('no disclosure callback and an asynchronous callback both fail before execution', async t => {
  const f = await fixture(t);
  const [selection] = await discover(f);
  await assert.rejects(executeCommandExtension(selection), /PSC_EXTENSION_DISCLOSURE_REQUIRED/u);
  await assert.rejects(executeCommandExtension(selection, { onState: async () => {} }),
    /PSC_EXTENSION_DISCLOSURE_ASYNC/u);
  await assert.rejects(executeCommandExtension(selection, { event: 1, onState() {} }),
    /PSC_EXTENSION_EVENT/u);
});

test('valid Wasm imports and linear memory are refused without granting host capabilities', async t => {
  const importedPrefix = [
    ...prefix.slice(0, 16), 2, 13, 1, 3, 101, 110, 118, 5, 116, 111, 117, 99, 104, 0, 0,
    ...prefix.slice(16, -1), 1,
  ];
  const imported = moduleBytes([0x20, 0, 0x10, 0, 0x0b], [0], importedPrefix);
  const memoryPrefix = [...prefix.slice(0, 20), 5, 4, 1, 1, 0, 1, ...prefix.slice(20)];
  const memory = moduleBytes([0x20, 0, 0x45, 0x0b], [0], memoryPrefix);
  for (const bytes of [imported, memory]) {
    assert.equal(WebAssembly.validate(bytes), true, 'adversarial fixture must be a valid Wasm module');
    const f = await fixture(t, { bytes });
    const { states, promise } = run((await discover(f))[0]);
    await assert.rejects(promise, /PSC_EXTENSION_WASM_SECTION/u);
    assert.equal(states.at(-1).instantiated, false);
    assert.deepEqual(states.at(-1).imports, []);
  }
});

test('recursion, excessive locals, nesting, byte size and trailing sections are refused before compile', () => {
  const recursive = moduleBytes([0x20, 0, 0x10, 0, 0x0b]);
  assert.equal(WebAssembly.validate(recursive), true);
  assert.throws(() => assertCommandWasmProfile(recursive), /PSC_EXTENSION_WASM_OPCODE/u);
  const locals = moduleBytes([0x41, 1, 0x0b], [1, ...u32(1_000_000), 0x7f]);
  assert.throws(() => assertCommandWasmProfile(locals), /PSC_EXTENSION_WASM_INTEGER/u);
  const nesting = moduleBytes([...Array.from({ length: 33 }, () => [2, 0x40]).flat(),
    ...Array(33).fill(0x0b), 0x41, 1, 0x0b]);
  assert.throws(() => assertCommandWasmProfile(nesting), /PSC_EXTENSION_WASM_CONTROL/u);
  assert.throws(() => assertCommandWasmProfile(Buffer.alloc(4097)), /PSC_EXTENSION_WASM_HEADER/u);
  assert.throws(() => assertCommandWasmProfile(Buffer.concat([canonical, Buffer.from([0, 0])])),
    /PSC_EXTENSION_WASM_SECTION/u);
});

test('traps and invalid integer responses fail with host-owned records, leaving the host usable', async t => {
  for (const [bytes, code] of [
    [moduleBytes([0x00, 0x0b]), 'PSC_EXTENSION_GUEST_FAILED'],
    [moduleBytes([0x41, 2, 0x0b]), 'PSC_EXTENSION_RESPONSE'],
    [moduleBytes([0x01, 0x0b]), 'PSC_EXTENSION_INVALID_WASM'],
  ]) {
    const f = await fixture(t, { bytes });
    const { states, promise } = run((await discover(f))[0]);
    await assert.rejects(promise, new RegExp(code, 'u'));
    assert.equal(states.at(-1).status, 'failed');
    assert.equal(states.at(-1).errorCode, code);
  }
  const normal = await fixture(t);
  assert.equal((await run((await discover(normal))[0]).promise).requestBuild, true);
});

test('an infinite Wasm loop is terminated by the parent wall budget and cannot publish', async t => {
  const f = await fixture(t, { bytes: moduleBytes([0x03, 0x40, 0x0c, 0, 0x0b, 0x41, 1, 0x0b]) });
  const start = Date.now();
  const { states, promise } = run((await discover(f))[0]);
  await assert.rejects(promise, /PSC_EXTENSION_TIMEOUT/u);
  assert.ok(Date.now() - start >= commandWasmLimits.wallTimeMs - 100);
  assert.equal(states.at(-1).instantiated, true);
  assert.equal(states.at(-1).status, 'failed');
});

test('cancellation stops an instantiated guest; disclosure callback failure also prevents success', async t => {
  const f = await fixture(t, { bytes: moduleBytes([0x03, 0x40, 0x0c, 0, 0x0b, 0x41, 1, 0x0b]) });
  const [selection] = await discover(f);
  const controller = new AbortController();
  const states = [];
  await assert.rejects(executeCommandExtension(selection, {
    signal: controller.signal,
    onState(state) { states.push(state); if (state.status === 'instantiated') controller.abort(); },
  }), /PSC_EXTENSION_CANCELLED/u);
  assert.equal(states.at(-1).status, 'failed');
  const normal = await fixture(t);
  await assert.rejects(executeCommandExtension((await discover(normal))[0], {
    onState(state) { if (state.status === 'executing') throw new Error('reporting unavailable'); },
  }), /reporting unavailable/u);
});
