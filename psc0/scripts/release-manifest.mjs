import { readFile } from 'node:fs/promises';
import path from 'node:path';

function exactKeys(value, keys, label) {
  if (value === null || typeof value !== 'object' || Array.isArray(value) ||
      Object.keys(value).length !== keys.length ||
      keys.some(key => !Object.hasOwn(value, key))) {
    throw new Error('PSC_RELEASE_SCHEMA: ' + label);
  }
}

export function assertReleaseManifest(value) {
  exactKeys(value, ['schemaVersion', 'kind', 'version', 'platform', 'compiler',
    'kernel', 'typescriptVersion', 'defaultExtensions'], 'release');
  exactKeys(value.platform, ['os', 'arch'], 'platform');
  exactKeys(value.compiler, ['sourceRef', 'sourceClosureSha256', 'sha256'], 'compiler');
  exactKeys(value.kernel, ['selector', 'sourceRef', 'sha256'], 'kernel');
  if (value.schemaVersion !== 1 || value.kind !== 'proofscript-release' ||
      !/^[0-9]+\.[0-9]+\.[0-9]+(?:-[0-9A-Za-z.-]+)?$/u.test(value.version) ||
      value.platform.os !== 'linux' || value.platform.arch !== 'x64' ||
      value.kernel.selector !== 'pskernel-core' || value.typescriptVersion !== '7.0.2') {
    throw new Error('PSC_RELEASE_SCHEMA: unsupported release profile');
  }
  for (const item of [value.compiler, value.kernel]) {
    if (typeof item.sourceRef !== 'string' || !/^[0-9a-f]{40}$/u.test(item.sourceRef) ||
        typeof item.sha256 !== 'string' || !/^[0-9a-f]{64}$/u.test(item.sha256)) {
      throw new Error('PSC_RELEASE_SCHEMA: artifact identity');
    }
  }
  if (typeof value.compiler.sourceClosureSha256 !== 'string' ||
      !/^[0-9a-f]{64}$/u.test(value.compiler.sourceClosureSha256)) {
    throw new Error('PSC_RELEASE_SCHEMA: source closure');
  }
  if (!Array.isArray(value.defaultExtensions) || value.defaultExtensions.length !== 0) {
    throw new Error('PSC_RELEASE_EXTENSIONS_UNSUPPORTED');
  }
  for (const item of [value.platform, value.compiler, value.kernel, value.defaultExtensions]) {
    Object.freeze(item);
  }
  return Object.freeze(value);
}

export async function readReleaseManifest(root) {
  let source;
  try { source = await readFile(path.join(root, 'release.json'), 'utf8'); }
  catch (cause) {
    throw new Error('PSC_RELEASE_NOT_ASSEMBLED: use the assembled proofscript package', { cause });
  }
  if (Buffer.byteLength(source) > 16384) throw new Error('PSC_RELEASE_SCHEMA: size');
  let value;
  try { value = JSON.parse(source); }
  catch (cause) { throw new Error('PSC_RELEASE_SCHEMA: invalid JSON', { cause }); }
  return assertReleaseManifest(value);
}

// These are release-owned paths, never package/project-provided entrypoints.
export function releaseRuntimePaths(root) {
  return Object.freeze({
    compilerPath: path.join(root, 'runtime/compiler/index.js'),
    nativeBinaryPath: path.join(root, 'runtime/kernel/linux-x64/psc_kernel_core_provider'),
  });
}

export function assertReleasePlatform(release) {
  if (process.platform !== release.platform.os || process.arch !== release.platform.arch) {
    throw new Error('PSC_RELEASE_PLATFORM: this preview requires Linux x64');
  }
}
