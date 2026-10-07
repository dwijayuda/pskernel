import { createHash } from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { mkdir, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { canonicalArtifact } from './artifact-evidence.mjs';
import { readOfflineCapsule } from './offline-capsule.mjs';
import { verifyWasmPrebuiltManifest } from '../packages/pskernel-lean-wasm/host/prebuilt.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const digest = bytes => createHash('sha256').update(bytes).digest('hex');
const unavailableProviderImports = ['./checked-kernel-core.mjs', './checked-owned-kernel.mjs',
  '../packages/pskernel-lean-wasm/index.mjs', '../packages/pskernel-lean/index.mjs'].sort();
const leanWasmImport = '../packages/pskernel-lean-wasm/index.mjs';
const leanWasmRoot = 'packages/pskernel-lean-wasm/';
const leanWasmFiles = ['PREBUILT_WASM_MANIFEST.json', 'LEAN_SOURCE_PIN.json', 'EMSCRIPTEN_PIN.json',
  'LEAN_LICENSE', 'KERNEL_SOURCE_MANIFEST.json', 'PROOFSCRIPT_SOURCE_MANIFEST.json',
  'wasm/pskernel-lean.cjs', 'wasm/pskernel-lean.wasm'];
function relative(from, reference) {
  const resolved = path.posix.normalize(path.posix.join(path.posix.dirname(from), reference));
  if (resolved === '..' || resolved.startsWith('../') || path.posix.isAbsolute(resolved) || reference.includes('\\')) {
    throw new Error('PSC_VERIFIER_BUILD_SOURCE_ESCAPE');
  }
  return resolved;
}

// Ask Node's actual ESM parser for static dependencies without linking or
// evaluating source. Regex matching mistook the IR tag string 'import' for a
// declaration. Dynamic-provider/data inventories remain separately restricted.
export function staticModuleDependencies(source) {
  const program = "import { SourceTextModule } from 'node:vm'; let source = ''; " +
    "process.stdin.setEncoding('utf8'); process.stdin.on('data', part => { source += part; }); " +
    "process.stdin.on('end', () => { const module = new SourceTextModule(source); " +
    "process.stdout.write(JSON.stringify(module.dependencySpecifiers)); });";
  const result = spawnSync(process.execPath, ['--experimental-vm-modules', '--input-type=module', '--eval', program],
    { input: source, encoding: 'utf8', maxBuffer: 1024 * 1024, timeout: 10000, windowsHide: true });
  if (result.error || result.status !== 0) throw new Error('PSC_VERIFIER_BUILD_PARSE_FAILED: ' +
    (result.error?.message ?? result.stderr));
  return JSON.parse(result.stdout);
}

/** Packages the actual reviewed static ESM/data closure for this explicit
 * checker profile. Only the explicit Lean Wasm profile supplies that provider;
 * all other dynamic providers remain unshipped and policy-disabled.
 * The scanner is a source inventory, not a general JavaScript security proof.
 */
export async function buildVerifierDistribution(destination, { profile = 'wasm-literal-offline/1' } = {}) {
  if (!['wasm-literal-offline/1', 'lean434-wasm-offline/1'].includes(profile)) throw new Error('PSC_VERIFIER_BUILD_PROFILE');
  const withLean = profile === 'lean434-wasm-offline/1';
  const providerManifest = withLean ? verifyWasmPrebuiltManifest() : null;
  const pending = ['scripts/offline-verifier-cli.mjs', ...(withLean ? leanWasmFiles.map(name => leanWasmRoot + name) : [])];
  const files = new Map(), dynamic = [], includedDynamic = [];
  let total = 0;
  while (pending.length) {
    const name = pending.pop(); if (files.has(name)) continue;
    if (files.size >= 120) throw new Error('PSC_VERIFIER_BUILD_FILE_LIMIT');
    const bytes = await readOfflineCapsule(path.join(root, name), { maxCapsuleBytes: 16 * 1024 * 1024 });
    total += bytes.length; if (total > 30 * 1024 * 1024) throw new Error('PSC_VERIFIER_BUILD_BYTE_LIMIT');
    files.set(name, bytes);
    if (!name.endsWith('.mjs')) continue;
    const source = new TextDecoder('utf-8', { fatal: true }).decode(bytes);
    for (const reference of staticModuleDependencies(source)) {
      if (reference.startsWith('node:')) continue;
      if (!reference.startsWith('.') || !reference.endsWith('.mjs')) throw new Error('PSC_VERIFIER_BUILD_EXTERNAL_DEPENDENCY: ' + reference);
      pending.push(relative(name, reference));
    }
    for (const match of source.matchAll(/new URL\(\s*['"]([^'"]+)['"]\s*,\s*import\.meta\.url\s*\)/gu)) pending.push(relative(name, match[1]));
    const dynamicImports = [...source.matchAll(/\bimport\s*\(\s*['"]([^'"]+)['"]\s*\)/gu)].map(match => match[1]).sort();
    const dynamicCount = [...source.matchAll(/\bimport\s*\(/gu)].length;
    if (dynamicCount !== dynamicImports.length || (dynamicCount &&
        (name !== 'scripts/checked-kernel-provider.mjs' || JSON.stringify(dynamicImports) !== JSON.stringify(unavailableProviderImports)))) {
      throw new Error('PSC_VERIFIER_BUILD_DYNAMIC_DEPENDENCY: ' + name);
    }
    if (dynamicCount) {
      dynamic.push({ owner: name, imports: dynamicImports.filter(reference => !withLean || reference !== leanWasmImport),
        status: 'unshipped-and-policy-disabled' });
      if (withLean) {
        includedDynamic.push({ owner: name, imports: [leanWasmImport], status: 'included-and-selector-restricted' });
        pending.push(relative(name, leanWasmImport));
      }
    }
  }
  if (withLean) {
    // Recheck the exact copied snapshots, not only the files read by the existing
    // provider verifier. Runtime/provider identities and prebuilt pins stay intact.
    const copied = JSON.parse(files.get(leanWasmRoot + 'PREBUILT_WASM_MANIFEST.json'));
    if (JSON.stringify(copied) !== JSON.stringify(providerManifest)) throw new Error('PSC_VERIFIER_BUILD_PROVIDER_MANIFEST_CHANGED');
    for (const record of Object.values(copied.artifacts)) {
      const bytes = files.get(leanWasmRoot + record.path);
      if (!bytes || bytes.length !== record.bytes || digest(bytes) !== record.sha256) throw new Error('PSC_VERIFIER_BUILD_PROVIDER_BYTES');
    }
  }
  files.set('pscv-verify.mjs', await readOfflineCapsule(path.join(root, 'scripts/verifier-launcher.mjs'), { maxCapsuleBytes: 1024 * 1024 }));
  const readme = 'PSCV offline verifier: ' + profile + '\n\n' +
    'Requires a trusted Node.js 22+ runtime and trusted local filesystem/process execution.\n' +
    'No npm install, compiler, network service, or live registry is required.\n' +
    'Pin the manifest SHA-256 independently before use; also authenticate the launcher and runtime through your trusted distribution channel.\n' +
    'node pscv-verify.mjs --manifest-sha256 PINNED_HASH --capsule CAPSULE --policy LOCAL_POLICY\n' +
    'node pscv-verify.mjs --manifest-sha256 PINNED_HASH --build-archive ARCHIVE --policy LOCAL_POLICY\n' +
    'node pscv-verify.mjs --manifest-sha256 PINNED_HASH --diff-locks LEFT RIGHT\n\n' +
    'Supports V1 semantic locks, SAVEF graph integrity, configured Ed25519 provenance and closed i32 literal Wasm certificates.\n' +
    'Build archive mode verifies observed byte closure and pass integrity, not kernel acceptance, complete tool inputs or preservation.\n' +
    (withLean ? 'Core proof replay includes the pinned Lean 4.34.0 Wasm provider only. Explicit providers=[lean434-wasm] is required; the existing security policy still rejects paranoid-v1.\n' :
      'Core proof providers and their binaries are not included; their checker policies fail closed.\n') +
    'Validation of a supported claim is not global compiler preservation or release acceptance.\n';
  files.set('README.txt', Buffer.from(readme));
  const manifest = canonicalArtifact({ contract: 'psc-verifier-distribution/1', profile,
    entry: 'pscv-verify.mjs', runtime: { implementation: 'node', minimumMajor: 22, included: false },
    checkerKinds: withLean ? ['core-proof', 'wasm-literal'] : ['wasm-literal'], coreProvidersIncluded: withLean,
    providerSelectors: withLean ? ['lean434-wasm'] : [], fullCompilerIncluded: false,
    providerAssets: withLean ? { selector: 'lean434-wasm', prebuiltManifest: copiedProviderIdentity(files),
      security: 'existing-provider-policy-no-paranoid-promotion', sourceBinaryCorrespondence: 'not-established-by-packaging' } : null,
    closureCoverage: 'computed-static-esm-and-literal-url-files-plus-explicit-profile-assets/1',
    disabledDynamicImports: dynamic, includedDynamicImports: includedDynamic,
    files: [...files].sort(([a], [b]) => a < b ? -1 : a > b ? 1 : 0).map(([name, bytes]) =>
      ({ path: name, byteLength: bytes.length, sha256: digest(bytes) })),
    assurance: 'implementation-fixture-checked-global-assurance-pending', releaseAccepted: false },
    'verifier-distribution', 'psc-verifier-distribution/1');
  const output = path.resolve(destination);
  await mkdir(path.dirname(output), { recursive: true });
  // Never overwrite an existing distribution. Manifest is published last.
  await mkdir(output);
  for (const [name, bytes] of files) {
    await mkdir(path.dirname(path.join(output, name)), { recursive: true });
    await writeFile(path.join(output, name), bytes, { flag: 'wx' });
  }
  await writeFile(path.join(output, 'manifest.json'), manifest.bytes, { flag: 'wx' });
  return { directory: output, manifestId: manifest.identity, manifestSha256: digest(manifest.bytes),
    files: files.size, bytes: [...files.values()].reduce((sum, bytes) => sum + bytes.length, 0),
    profile, releaseAccepted: false };
}

function copiedProviderIdentity(files) {
  const name = leanWasmRoot + 'PREBUILT_WASM_MANIFEST.json', bytes = files.get(name);
  return { path: name, byteLength: bytes.length, sha256: digest(bytes) };
}

if (process.argv[1] && pathToFileURL(path.resolve(process.argv[1])).href === import.meta.url) {
  const args = process.argv.slice(2);
  if (![2, 4].includes(args.length) || args[0] !== '--out' || (args.length === 4 && args[2] !== '--profile')) {
    throw new Error('Usage: build-verifier-distribution --out NEW_DIRECTORY [--profile wasm-literal-offline/1|lean434-wasm-offline/1]');
  }
  buildVerifierDistribution(args[1], { profile: args[3] }).then(result => process.stdout.write(JSON.stringify(result) + '\n'))
    .catch(error => { process.stderr.write(error.message + '\n'); process.exitCode = 1; });
}
