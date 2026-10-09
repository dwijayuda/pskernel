import { readFile } from 'node:fs/promises';
import path from 'node:path';

const platforms = Object.freeze([
  Object.freeze({ os: 'linux', arch: 'x64' }),
  Object.freeze({ os: 'win32', arch: 'x64' }),
]);
const platformKeys = Object.freeze(platforms.map(item => item.os + '-' + item.arch));
const digest = value => typeof value === 'string' && /^[0-9a-f]{64}$/u.test(value);
const sourceRef = value => typeof value === 'string' && /^[0-9a-f]{40}$/u.test(value);

function exactKeys(value, keys, label) {
  if (value === null || typeof value !== 'object' || Array.isArray(value) ||
      Object.keys(value).length !== keys.length ||
      keys.some(key => !Object.hasOwn(value, key))) {
    throw new Error('PSC_RELEASE_SCHEMA: ' + label);
  }
}

export function assertReleaseManifest(value) {
  exactKeys(value, ['schemaVersion', 'kind', 'version', 'platforms', 'compiler',
    'kernel', 'typescriptVersion', 'defaultExtensions'], 'release');
  exactKeys(value.compiler, ['sourceRef', 'sourceClosureSha256', 'sha256'], 'compiler');
  exactKeys(value.kernel, ['selector', 'sourceRef', 'artifacts'], 'kernel');
  exactKeys(value.kernel.artifacts, platformKeys, 'kernel artifacts');
  if (value.schemaVersion !== 2 || value.kind !== 'proofscript-release' ||
      typeof value.version !== 'string' ||
      !/^[0-9]+\.[0-9]+\.[0-9]+(?:-[0-9A-Za-z.-]+)?$/u.test(value.version) ||
      value.kernel.selector !== 'pskernel-core' || value.typescriptVersion !== '7.0.2') {
    throw new Error('PSC_RELEASE_SCHEMA: unsupported release profile');
  }
  if (!Array.isArray(value.platforms) || value.platforms.length !== platforms.length) {
    throw new Error('PSC_RELEASE_SCHEMA: platforms');
  }
  for (let index = 0; index < platforms.length; index++) {
    const actual = value.platforms[index];
    const expected = platforms[index];
    exactKeys(actual, ['os', 'arch'], 'platform');
    if (actual.os !== expected.os || actual.arch !== expected.arch) {
      throw new Error('PSC_RELEASE_SCHEMA: unsupported platform');
    }
    Object.freeze(actual);
  }
  if (!sourceRef(value.compiler.sourceRef) || !digest(value.compiler.sha256) ||
      !sourceRef(value.kernel.sourceRef)) {
    throw new Error('PSC_RELEASE_SCHEMA: artifact identity');
  }
  if (!digest(value.compiler.sourceClosureSha256)) {
    throw new Error('PSC_RELEASE_SCHEMA: source closure');
  }
  for (const key of platformKeys) {
    const artifact = value.kernel.artifacts[key];
    exactKeys(artifact, ['sha256', 'dependencies'], 'kernel artifact');
    // Both qualified providers link their non-system runtimes statically.
    // A future native dependency requires an explicit new qualification/profile.
    if (!digest(artifact.sha256) || !Array.isArray(artifact.dependencies) ||
        artifact.dependencies.length !== 0) {
      throw new Error('PSC_RELEASE_SCHEMA: native artifact');
    }
    Object.freeze(artifact.dependencies);
    Object.freeze(artifact);
  }
  if (!Array.isArray(value.defaultExtensions) || value.defaultExtensions.length !== 0) {
    throw new Error('PSC_RELEASE_EXTENSIONS_UNSUPPORTED');
  }
  for (const item of [value.platforms, value.compiler, value.kernel.artifacts,
    value.kernel, value.defaultExtensions]) Object.freeze(item);
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

// Paths come from the release host, never a project or npm manifest entrypoint.
// Explicit platforms are used by the assembler; execution selects process.platform.
export function releaseRuntimePaths(root, os = process.platform, arch = process.arch) {
  const key = os + '-' + arch;
  if (!platformKeys.includes(key)) {
    throw new Error('PSC_RELEASE_PLATFORM: this preview supports Linux x64 and Windows x64');
  }
  return Object.freeze({
    compilerPath: path.join(root, 'runtime/compiler/index.js'),
    nativeBinaryPath: path.join(root, 'runtime/kernel', key,
      'psc_kernel_core_provider' + (os === 'win32' ? '.exe' : '')),
  });
}

export function assertReleasePlatform(release) {
  if (!release.platforms.some(item => item.os === process.platform && item.arch === process.arch)) {
    throw new Error('PSC_RELEASE_PLATFORM: this preview supports Linux x64 and Windows x64');
  }
}
