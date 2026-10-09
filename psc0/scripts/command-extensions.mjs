import { open, lstat, realpath } from 'node:fs/promises';
import path from 'node:path';
import { createHash } from 'node:crypto';
import { Worker } from 'node:worker_threads';
import { assertCommandWasmProfile, commandWasmLimits } from './command-wasm-profile.mjs';

export const commandExtensionProtocol = 'psc-command/1';
const selections = new WeakMap();
const executions = new WeakMap();
const hash = bytes => createHash('sha256').update(bytes).digest('hex');
const fail = code => { throw new Error(code); };
const object = value => value !== null && typeof value === 'object' && !Array.isArray(value);
const exact = (value, keys) => object(value) && Object.keys(value).length === keys.length &&
  keys.every(key => Object.hasOwn(value, key));
function frozen(value) {
  if (value && typeof value === 'object') {
    for (const item of Object.values(value)) frozen(item);
    Object.freeze(value);
  }
  return value;
}
const validName = name => typeof name === 'string' && name.length <= 214 &&
  /^(?:@[a-z0-9][a-z0-9._-]*\/)?[a-z0-9][a-z0-9._-]*$/u.test(name);
const validVersion = value => typeof value === 'string' && value.length <= 100 &&
  /^(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)(?:-[0-9A-Za-z.-]+)?$/u.test(value);

export function validateCommandExtensionConfig(extensions) {
  if (extensions === undefined) return Object.freeze([]);
  if (!Array.isArray(extensions)) fail('PSC_EXTENSION_CONFIGURATION');
  if (extensions.length > 1) fail('PSC_DEV_EXTENSION_AMBIGUOUS');
  return frozen(extensions.map(entry => {
    if (!exact(entry, ['package', 'enable']) || !validName(entry.package) ||
        !Array.isArray(entry.enable) || entry.enable.length !== 1 ||
        entry.enable[0] !== 'command:dev') fail('PSC_EXTENSION_CONFIGURATION');
    return { package: entry.package, enable: ['command:dev'] };
  }));
}

// Bound allocations before parsing. Package files must be ordinary direct
// files; no linked packages, module symlinks or ancestor/global resolution.
async function readBounded(file, limit) {
  const before = await lstat(file);
  if (!before.isFile() || before.isSymbolicLink() || before.size > limit) fail('PSC_EXTENSION_FILE');
  const handle = await open(file, 'r');
  try {
    const actual = await handle.stat();
    if (!actual.isFile() || actual.size > limit ||
        actual.dev !== before.dev || actual.ino !== before.ino) fail('PSC_EXTENSION_FILE');
    const bytes = Buffer.alloc(limit + 1);
    let offset = 0;
    while (offset < bytes.length) {
      const result = await handle.read(bytes, offset, bytes.length - offset, offset);
      if (result.bytesRead === 0) break;
      offset += result.bytesRead;
    }
    if (offset > limit) fail('PSC_EXTENSION_FILE');
    return bytes.subarray(0, offset);
  } finally { await handle.close(); }
}
function json(bytes) {
  try { return JSON.parse(bytes.toString('utf8').replace(/^\uFEFF/u, '')); }
  catch { fail('PSC_EXTENSION_JSON'); }
}
async function capture(file, limit, inputs) {
  const bytes = await readBounded(file, limit);
  inputs.push({ file, limit, sha256: hash(bytes) });
  return bytes;
}
async function current(state) {
  for (const input of state.inputs) {
    try {
      if (hash(await readBounded(input.file, input.limit)) !== input.sha256) {
        fail('PSC_EXTENSION_INPUT_CHANGED');
      }
    } catch { fail('PSC_EXTENSION_INPUT_CHANGED'); }
  }
  // Recheck the package directory, including node_modules parent aliases.
  if (path.relative(state.packageRoot, await realpath(state.packageRoot)) !== '') {
    fail('PSC_EXTENSION_INPUT_CHANGED');
  }
}

export async function discoverCommandExtensions({ projectRoot, projectMetadata }) {
  const entries = validateCommandExtensionConfig(projectMetadata?.proofscript?.extensions);
  if (!entries.length) return Object.freeze([]);
  if (typeof projectRoot !== 'string' || !object(projectMetadata)) fail('PSC_EXTENSION_PROJECT');
  const root = await realpath(projectRoot);
  const inputs = [];
  const projectBytes = await capture(path.join(root, 'package.json'), 64 * 1024, inputs);
  const project = json(projectBytes);
  if (JSON.stringify(project) !== JSON.stringify(projectMetadata)) fail('PSC_EXTENSION_INPUT_CHANGED');
  let lockBytes;
  try { lockBytes = await capture(path.join(root, 'package-lock.json'), 2 * 1024 * 1024, inputs); }
  catch { fail('PSC_EXTENSION_LOCK_REQUIRED'); }
  const lock = json(lockBytes);
  if (!object(lock) || lock.lockfileVersion !== 3 || !object(lock.packages) ||
      !object(lock.packages[''])) fail('PSC_EXTENSION_LOCK_REQUIRED');
  const entry = entries[0];
  const groups = ['dependencies', 'devDependencies'].filter(group =>
    object(project[group]) && Object.hasOwn(project[group], entry.package));
  if (groups.length !== 1) fail('PSC_EXTENSION_DIRECT_DEPENDENCY');
  const group = groups[0];
  const spec = project[group][entry.package];
  const tarball = typeof spec === 'string' && spec.length <= 2048 &&
    /^file:[^\u0000\r\n]+\.tgz$/u.test(spec);
  if ((!validVersion(spec) && !tarball) || lock.packages[''][group]?.[entry.package] !== spec) {
    fail('PSC_EXTENSION_DEPENDENCY_PIN');
  }
  const locked = lock.packages['node_modules/' + entry.package];
  if (!object(locked) || locked.link === true || !validVersion(locked.version) ||
      typeof locked.resolved !== 'string' || locked.resolved.length > 2048 ||
      !(tarball ? locked.resolved.startsWith('file:') : locked.resolved.startsWith('https://')) ||
      typeof locked.integrity !== 'string' || !/^sha512-[A-Za-z0-9+/]{86}==$/u.test(locked.integrity) ||
      Buffer.from(locked.integrity.slice(7), 'base64').toString('base64') !== locked.integrity.slice(7)) {
    fail('PSC_EXTENSION_LOCK_REQUIRED');
  }
  const packageRoot = path.join(root, 'node_modules', ...entry.package.split('/'));
  if (path.relative(packageRoot, await realpath(packageRoot)) !== '') fail('PSC_EXTENSION_LINK_UNSUPPORTED');
  const packageBytes = await capture(path.join(packageRoot, 'package.json'), 32 * 1024, inputs);
  const metadata = json(packageBytes);
  if (!object(metadata) || metadata.name !== entry.package || metadata.version !== locked.version ||
      (!tarball && spec !== metadata.version)) fail('PSC_EXTENSION_PACKAGE_IDENTITY');
  const descriptorBytes = await capture(path.join(packageRoot, 'proofscript-extension.json'), 4096, inputs);
  const descriptor = json(descriptorBytes);
  if (!exact(descriptor, ['schemaVersion', 'protocol', 'operations', 'entry', 'sha256']) ||
      descriptor.schemaVersion !== 1 || descriptor.protocol !== commandExtensionProtocol ||
      !Array.isArray(descriptor.operations) || descriptor.operations.length !== 1 ||
      descriptor.operations[0] !== 'command:dev' || descriptor.entry !== 'command.wasm' ||
      typeof descriptor.sha256 !== 'string' || !/^[a-f0-9]{64}$/u.test(descriptor.sha256)) {
    fail('PSC_EXTENSION_DESCRIPTOR');
  }
  const bytes = await capture(path.join(packageRoot, descriptor.entry), commandWasmLimits.moduleBytes, inputs);
  const report = frozen({
    package: metadata.name, version: metadata.version, origin: 'project', packageRoot,
    entry: descriptor.entry, packageJsonSha256: hash(packageBytes), descriptorSha256: hash(descriptorBytes),
    moduleSha256: hash(bytes), projectPackageSha256: hash(projectBytes), lockfileSha256: hash(lockBytes),
    lockResolved: locked.resolved, lockIntegrity: locked.integrity, protocol: commandExtensionProtocol,
    operation: 'command:dev', grants: ['command:dev'], imports: [],
    engine: { name: 'v8-webassembly', node: process.versions.node, v8: process.versions.v8 },
    limits: commandWasmLimits, status: 'configured', instantiated: false,
  });
  const selection = Object.freeze({ report });
  selections.set(selection, { report, bytes: Uint8Array.from(bytes), expectedSha256: descriptor.sha256,
    inputs, packageRoot });
  return Object.freeze([selection]);
}

function runWorker(state, event, signal, onInstantiated) {
  return new Promise((resolve, reject) => {
    let worker, timer, settled = false, instantiated = false;
    const finish = (error, value) => {
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      signal?.removeEventListener('abort', abort);
      Promise.resolve(worker?.terminate()).then(() => error ? reject(error) : resolve(value), reject);
    };
    const abort = () => finish(new Error('PSC_EXTENSION_CANCELLED'));
    if (signal?.aborted) { abort(); return; }
    signal?.addEventListener('abort', abort, { once: true });
    timer = setTimeout(() => finish(new Error('PSC_EXTENSION_TIMEOUT')), commandWasmLimits.wallTimeMs);
    try {
      worker = new Worker(new URL('./command-extension-worker.mjs', import.meta.url), {
        workerData: { bytes: state.bytes, event }, execArgv: [], env: {}, stdin: false,
        stdout: true, stderr: true,
        resourceLimits: { maxOldGenerationSizeMb: 16, maxYoungGenerationSizeMb: 4,
          codeRangeSizeMb: 16, stackSizeMb: 2 },
      });
    } catch (error) { finish(error); return; }
    worker.stdout.on('data', () => finish(new Error('PSC_EXTENSION_UNEXPECTED_OUTPUT')));
    worker.stderr.on('data', () => finish(new Error('PSC_EXTENSION_UNEXPECTED_OUTPUT')));
    worker.on('error', () => finish(new Error('PSC_EXTENSION_WORKER_FAILED')));
    worker.on('exit', () => finish(new Error('PSC_EXTENSION_WORKER_EXIT')));
    worker.on('message', message => {
      if (settled) return;
      try {
        if (exact(message, ['stage']) && message.stage === 'instantiated' && !instantiated) {
          instantiated = true;
          onInstantiated();
        } else if (exact(message, ['stage', 'value']) && message.stage === 'completed' &&
            instantiated && (message.value === 0 || message.value === 1)) {
          finish(undefined, message.value);
        } else if (exact(message, ['stage', 'code']) && message.stage === 'failed' &&
            typeof message.code === 'string' && /^PSC_EXTENSION_[A-Z_]+$/u.test(message.code)) {
          finish(new Error(message.code));
        } else finish(new Error('PSC_EXTENSION_RESPONSE'));
      } catch (error) { finish(error); }
    });
  });
}

export async function executeCommandExtension(selection, { event = 0, onState, signal } = {}) {
  const state = selections.get(selection);
  if (!state) fail('PSC_EXTENSION_SELECTION_INVALID');
  if (event !== 0) fail('PSC_EXTENSION_EVENT');
  if (typeof onState !== 'function') fail('PSC_EXTENSION_DISCLOSURE_REQUIRED');
  let instantiated = false;
  let workerRequested = false;
  const emit = (status, extra = {}) => {
    const record = frozen({ ...state.report, status, instantiated, ...extra });
    const returned = onState(record);
    if (returned && typeof returned.then === 'function') fail('PSC_EXTENSION_DISCLOSURE_ASYNC');
    return record;
  };
  try {
    emit('attempted');
    signal?.throwIfAborted();
    await current(state);
    if (hash(state.bytes) !== state.expectedSha256) fail('PSC_EXTENSION_MODULE_HASH');
    assertCommandWasmProfile(state.bytes);
    // This full supervisor record precedes creation of any executing guest.
    emit('executing');
    workerRequested = true;
    const value = await runWorker(state, event, signal, () => {
      instantiated = true;
      emit('instantiated');
    });
    signal?.throwIfAborted();
    await current(state);
    const record = emit('completed', { requestBuild: value === 1 });
    const result = Object.freeze({ requestBuild: value === 1, record });
    executions.set(result, { state, records: Object.freeze([record]) });
    return result;
  } catch (error) {
    const code = /^PSC_[A-Z0-9_]+$/u.test(error?.message ?? '') ? error.message : 'PSC_EXTENSION_FAILED';
    // If a worker stopped before acknowledging instantiation, say unknown.
    emit('failed', { instantiated: instantiated ? true : workerRequested ? null : false, errorCode: code });
    throw error;
  }
}

export function completedCommandRecords(execution) {
  const owned = executions.get(execution);
  if (!owned || execution.requestBuild !== true || execution.record.status !== 'completed') {
    fail('PSC_EXTENSION_EXECUTION_INVALID');
  }
  return owned.records;
}

export async function assertCommandExtensionCurrent(execution) {
  completedCommandRecords(execution);
  await current(executions.get(execution).state);
}
