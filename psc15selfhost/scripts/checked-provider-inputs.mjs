import { createHash } from 'node:crypto';
import { realpath } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { readObservedFileBytes } from './observed-file-bytes.mjs';
import { selectedCheckedKernelOptions } from './checked-kernel-provider.mjs';
import { checkedKernelIdentity } from './checked-kernel-identity.mjs';

const root = fileURLToPath(new URL('../', import.meta.url));
const captures = new WeakMap();
const hash = bytes => createHash('sha256').update(bytes).digest('hex');
const fail = code => { throw new Error('PSC_PROVIDER_INPUTS_' + code); };
const defaults = Object.freeze({ maxFiles: 64, maxFileBytes: 128 * 1024 * 1024, maxTotalBytes: 160 * 1024 * 1024 });
const profiles = Object.freeze({
  'lean434-wasm': ['packages/pskernel-lean-wasm/index.mjs', 'packages/pskernel-lean-wasm/host/prebuilt.mjs',
    ...['package.json', 'PREBUILT_WASM_MANIFEST.json', 'LEAN_SOURCE_PIN.json', 'EMSCRIPTEN_PIN.json', 'LEAN_LICENSE',
      'KERNEL_SOURCE_MANIFEST.json', 'PROOFSCRIPT_SOURCE_MANIFEST.json', 'wasm/pskernel-lean.cjs', 'wasm/pskernel-lean.wasm']
      .map(name => 'packages/pskernel-lean-wasm/' + name)],
  'pskernel-core.old3': ['scripts/checked-owned-kernel.mjs', 'scripts/checked-owned-kernel-worker.mjs',
    'packages/pskernel-core.old3/package.json', 'packages/pskernel-core.old3/dist/foundation.js',
    'packages/pskernel-core.old3/manifests/BUILD.json'],
  'pskernel-core': ['scripts/checked-kernel-core.mjs'],
  lean434: ['packages/pskernel-lean/index.mjs', 'packages/pskernel-lean/host/node-provider.mjs',
    'packages/pskernel-lean/host/prebuilt.mjs', 'packages/pskernel-lean/package.json'],
});
async function readFiles(paths, limits) {
  if (paths.length > limits.maxFiles) fail('RESOURCE_EXHAUSTED');
  const files = []; let total = 0;
  for (const item of paths) {
    const bytes = await readObservedFileBytes(item.absolute, Math.min(limits.maxFileBytes, limits.maxTotalBytes - total));
    total += bytes.length; files.push({ path: item.path, bytes });
  }
  return files;
}

/** Explicit reviewed runtime-file profiles. Existing provider checks remain
 * authoritative; this capture adds byte observations without promoting trust.
 */
export async function captureCheckedProviderInputs(selector, options = {}, resourceLimits = {}) {
  const selected = selectedCheckedKernelOptions(selector, options);
  const allowedOptions = selector === 'lean434' ? ['nativeBinaryPath'] : selector === 'pskernel-core' ? ['coreBinaryPath'] : [];
  if (Object.keys(options).some(key => !allowedOptions.includes(key))) fail('OPTIONS');
  if (Object.keys(resourceLimits).some(key => !Object.hasOwn(defaults, key))) fail('BUDGET');
  const limits = { ...defaults, ...resourceLimits };
  if (Object.values(limits).some(value => !Number.isSafeInteger(value) || value < 0)) fail('BUDGET');
  const paths = profiles[selector].map(name => ({ path: name, absolute: path.join(root, name) }));
  const binary = selected.nativeBinaryPath ?? selected.coreBinaryPath;
  let invocationOptions = selected;
  if (binary) {
    const absolute = await realpath(binary);
    paths.push({ path: 'selected-native-provider', absolute });
    invocationOptions = Object.freeze(selector === 'lean434' ? { nativeBinaryPath: absolute } : { coreBinaryPath: absolute });
  }
  paths.sort((a, b) => a.path < b.path ? -1 : a.path > b.path ? 1 : 0);
  const files = await readFiles(paths, limits);
  if (selector === 'lean434-wasm') {
    const manifest = JSON.parse(files.find(item => item.path.endsWith('/PREBUILT_WASM_MANIFEST.json')).bytes);
    for (const [key, expected] of [['launcher', 'wasm/pskernel-lean.cjs'], ['wasm', 'wasm/pskernel-lean.wasm']]) {
      const record = manifest.artifacts?.[key], actual = files.find(item => item.path === 'packages/pskernel-lean-wasm/' + expected);
      if (record?.path !== expected || record.bytes !== actual.bytes.length || record.sha256 !== hash(actual.bytes)) fail('WASM_PIN');
    }
  }
  if (selector === 'pskernel-core.old3' && hash(files.find(item => item.path.endsWith('/foundation.js')).bytes) !==
      checkedKernelIdentity(selector).generatedKernelSha256) fail('OWNED_PIN');
  const details = Object.freeze({ contract: 'psc-checked-provider-inputs/1', selector,
    platform: process.platform, arch: process.arch,
    provider: checkedKernelIdentity(selector), coverage: 'selected-runtime-files-and-explicit-profile-assets',
    nativePath: binary ? 'selected-native-provider' : null, fullInputClosureEstablished: false,
    excluded: Object.freeze(['host runtime and OS libraries', 'ambient environment',
      'unlisted dynamic inputs', 'source-binary correspondence and authenticated release provenance']),
    files: Object.freeze(files.map(item => Object.freeze({ path: item.path, byteLength: item.bytes.length, sha256: hash(item.bytes) }))) });
  const handle = Object.freeze({ invocationOptions, details });
  captures.set(handle, { paths, limits, files });
  return handle;
}

export async function verifyCheckedProviderInputs(handle) {
  const captured = captures.get(handle);
  if (!captured) fail('UNKNOWN_CAPTURE');
  const current = await readFiles(captured.paths, captured.limits);
  if (current.some((item, index) => hash(item.bytes) !== handle.details.files[index].sha256)) fail('CHANGED');
  return Object.freeze({ details: handle.details,
    files: Object.freeze(captured.files.map(item => Object.freeze({ path: item.path, bytes: Buffer.from(item.bytes) }))) });
}
