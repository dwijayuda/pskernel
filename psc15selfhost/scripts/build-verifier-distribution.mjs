import { createHash } from 'node:crypto';
import { mkdir, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { canonicalArtifact } from './artifact-evidence.mjs';
import { readOfflineCapsule } from './offline-capsule.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const digest = bytes => createHash('sha256').update(bytes).digest('hex');
const unavailableProviderImports = ['./checked-kernel-core.mjs', './checked-owned-kernel.mjs',
  '../packages/pskernel-lean-wasm/index.mjs', '../packages/pskernel-lean/index.mjs'].sort();
function relative(from, reference) {
  const resolved = path.posix.normalize(path.posix.join(path.posix.dirname(from), reference));
  if (resolved === '..' || resolved.startsWith('../') || path.posix.isAbsolute(resolved) || reference.includes('\\')) {
    throw new Error('PSC_VERIFIER_BUILD_SOURCE_ESCAPE');
  }
  return resolved;
}

/** Packages the actual reviewed static ESM/data closure for this explicit
 * checker profile. Dynamic kernel provider modules/assets are not supplied;
 * the shipped launcher rejects Core checker policy before any provider runs.
 * The scanner is a source inventory, not a general JavaScript security proof.
 */
export async function buildVerifierDistribution(destination) {
  const pending = ['scripts/offline-verifier-cli.mjs'], files = new Map(), dynamic = [];
  let total = 0;
  while (pending.length) {
    const name = pending.pop(); if (files.has(name)) continue;
    if (files.size >= 120) throw new Error('PSC_VERIFIER_BUILD_FILE_LIMIT');
    const bytes = await readOfflineCapsule(path.join(root, name), { maxCapsuleBytes: 16 * 1024 * 1024 });
    total += bytes.length; if (total > 30 * 1024 * 1024) throw new Error('PSC_VERIFIER_BUILD_BYTE_LIMIT');
    files.set(name, bytes);
    if (!name.endsWith('.mjs')) continue;
    const source = new TextDecoder('utf-8', { fatal: true }).decode(bytes);
    for (const match of source.matchAll(/(?:\bfrom\s*|\bimport\s*)['"]([^'"]+)['"]/gu)) {
      const reference = match[1];
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
    if (dynamicCount) dynamic.push({ owner: name, imports: dynamicImports, status: 'unshipped-and-policy-disabled' });
  }
  files.set('pscv-verify.mjs', await readOfflineCapsule(path.join(root, 'scripts/verifier-launcher.mjs'), { maxCapsuleBytes: 1024 * 1024 }));
  const readme = 'PSCV offline verifier: wasm-literal-offline/1\n\n' +
    'Requires a trusted Node.js 22+ runtime and trusted local filesystem/process execution.\n' +
    'No npm install, compiler, network service, or live registry is required.\n' +
    'Pin the manifest SHA-256 independently before use; also authenticate the launcher and runtime through your trusted distribution channel.\n' +
    'node pscv-verify.mjs --manifest-sha256 PINNED_HASH --capsule CAPSULE --policy LOCAL_POLICY\n' +
    'node pscv-verify.mjs --manifest-sha256 PINNED_HASH --diff-locks LEFT RIGHT\n\n' +
    'Supports V1 semantic locks, SAVEF graph integrity, configured Ed25519 provenance and closed i32 literal Wasm certificates.\n' +
    'Core proof providers and their binaries are not included; their checker policies fail closed.\n' +
    'Validation of a supported claim is not global compiler preservation or release acceptance.\n';
  files.set('README.txt', Buffer.from(readme));
  const manifest = canonicalArtifact({ contract: 'psc-verifier-distribution/1', profile: 'wasm-literal-offline/1',
    entry: 'pscv-verify.mjs', runtime: { implementation: 'node', minimumMajor: 22, included: false },
    checkerKinds: ['wasm-literal'], coreProvidersIncluded: false, fullCompilerIncluded: false,
    closureCoverage: 'computed-static-esm-and-literal-url-files/1', disabledDynamicImports: dynamic,
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
    profile: 'wasm-literal-offline/1', releaseAccepted: false };
}

if (process.argv[1] && pathToFileURL(path.resolve(process.argv[1])).href === import.meta.url) {
  const args = process.argv.slice(2);
  if (args.length !== 2 || args[0] !== '--out') throw new Error('Usage: build-verifier-distribution --out NEW_DIRECTORY');
  buildVerifierDistribution(args[1]).then(result => process.stdout.write(JSON.stringify(result) + '\n'))
    .catch(error => { process.stderr.write(error.message + '\n'); process.exitCode = 1; });
}
