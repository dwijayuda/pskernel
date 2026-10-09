import { chmod, lstat, mkdir, mkdtemp, readFile, rename, rm, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';
import { assertReleaseManifest, releaseRuntimePaths } from './release-manifest.mjs';
import { readBootstrapClosure } from './sh1-source-snapshot.mjs';

const root = fileURLToPath(new URL('../', import.meta.url));
const sha256 = bytes => createHash('sha256').update(bytes).digest('hex');

// Copy maintained sources verbatim. This is the public host's explicit import
// closure; it is not a second implementation or a copy of the repository CLI.
export const releaseHostFiles = Object.freeze([
  'bin/psc.mjs',
  'scripts/release-manifest.mjs',
  'scripts/checked-build.mjs',
  'scripts/checked-artifact-publication.mjs',
  'scripts/checked-prepared-session.mjs',
  'scripts/checked-source-snapshot.mjs',
  'scripts/checked-kernel-provider.mjs',
  'scripts/checked-kernel-identity.mjs',
  'scripts/checked-kernel-core.mjs',
  'scripts/kernel-contract.mjs',
  'scripts/proofscript-source.mjs',
  'scripts/source-grammar-profile.mjs',
  'scripts/selfhost-source-workspace.mjs',
  'scripts/bootstrap-manifest.mjs',
  'scripts/workspace-layout.mjs',
  'scripts/sh1-source-snapshot.mjs',
  'scripts/typescript-cli.mjs',
]);

async function absent(file) {
  try { await lstat(file); }
  catch (error) { if (error.code === 'ENOENT') return; throw error; }
  throw new Error('PSC_RELEASE_OUTPUT_EXISTS: ' + file);
}

function assertLinuxX64Elf(bytes) {
  if (bytes.length < 64 || bytes[0] !== 0x7f || bytes.subarray(1, 4).toString() !== 'ELF' ||
      bytes[4] !== 2 || bytes[5] !== 1 || bytes.readUInt16LE(18) !== 62) {
    throw new Error('PSC_RELEASE_KERNEL_PLATFORM: expected Linux x64 ELF');
  }
}

export async function assembleRelease({
  workspaceRoot = root, compilerPath, nativeBinaryPath, outputPath,
} = {}) {
  if (!compilerPath || !nativeBinaryPath || !outputPath) {
    throw new Error('PSC_RELEASE_INPUTS: require compiler, native provider, and output paths');
  }
  workspaceRoot = path.resolve(workspaceRoot);
  const output = path.resolve(outputPath);
  await absent(output);
  const release = assertReleaseManifest(JSON.parse(await readFile(
    path.join(workspaceRoot, 'release/release.json'), 'utf8')));
  const metadata = JSON.parse(await readFile(path.join(workspaceRoot, 'release/package.json'), 'utf8'));
  if (metadata.name !== 'proofscript' || metadata.version !== release.version ||
      metadata.bin?.psc !== './bin/psc.mjs' || metadata.type !== 'module' ||
      metadata.dependencies?.typescript !== release.typescriptVersion ||
      Object.keys(metadata.dependencies).length !== 1 || Object.hasOwn(metadata, 'scripts') ||
      Object.hasOwn(metadata, 'workspaces')) {
    throw new Error('PSC_RELEASE_PACKAGE_PROFILE');
  }
  const closure = await readBootstrapClosure(workspaceRoot);
  if (closure.sha256 !== release.compiler.sourceClosureSha256) {
    throw new Error('PSC_RELEASE_SOURCE_CLOSURE_MISMATCH');
  }
  // Authenticate the bytes before any runtime artifact is loaded or copied.
  // In particular, this assembler never executes an input compiler or provider.
  const [compiler, provider] = await Promise.all([readFile(compilerPath), readFile(nativeBinaryPath)]);
  if (sha256(compiler) !== release.compiler.sha256) throw new Error('PSC_RELEASE_COMPILER_PIN');
  if (sha256(provider) !== release.kernel.sha256) throw new Error('PSC_RELEASE_KERNEL_PIN');
  assertLinuxX64Elf(provider);
  const sources = await Promise.all(releaseHostFiles.map(async file => [
    file, await readFile(path.join(workspaceRoot, file)),
  ]));
  const [readme, leanLicense] = await Promise.all([
    readFile(path.join(workspaceRoot, 'release/README.md')),
    readFile(path.join(workspaceRoot, 'packages/pskernel-lean-wasm/LEAN_LICENSE')),
  ]);
  await mkdir(path.dirname(output), { recursive: true });
  const staging = await mkdtemp(path.join(path.dirname(output), '.proofscript-release-'));
  try {
    async function put(file, bytes) {
      await mkdir(path.dirname(file), { recursive: true });
      await writeFile(file, bytes, { flag: 'wx' });
    }
    for (const [file, bytes] of sources) await put(path.join(staging, file), bytes);
    await put(path.join(staging, 'package.json'), JSON.stringify(metadata, null, 2) + '\n');
    await put(path.join(staging, 'release.json'), JSON.stringify(release, null, 2) + '\n');
    await put(path.join(staging, 'README.md'), readme);
    await put(path.join(staging, 'LEAN_LICENSE'), leanLicense);
    const runtime = releaseRuntimePaths(staging);
    await put(runtime.compilerPath, compiler);
    await put(runtime.nativeBinaryPath, provider);
    await chmod(path.join(staging, 'bin/psc.mjs'), 0o755);
    await chmod(runtime.nativeBinaryPath, 0o755);
    await absent(output);
    await rename(staging, output);
  } finally {
    await rm(staging, { recursive: true, force: true });
  }
  return Object.freeze({
    kind: 'proofscript-release-assembly', outputPath: output, version: release.version,
    compilerSha256: release.compiler.sha256, kernelSha256: release.kernel.sha256,
    sourceClosureSha256: closure.sha256, moduleCount: closure.moduleCount,
    hostFiles: releaseHostFiles, extensions: [],
    runtimeExecuted: false, runtimeQualificationRequired: true,
  });
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const options = {};
  const args = process.argv.slice(2);
  while (args.length) {
    const flag = args.shift();
    const key = { '--compiler': 'compilerPath', '--kernel': 'nativeBinaryPath', '--out': 'outputPath' }[flag];
    const value = args.shift();
    if (!key || !value || value.startsWith('--') || options[key] !== undefined) {
      throw new Error('usage: assemble-release.mjs --compiler index.js --kernel provider --out new-directory');
    }
    options[key] = path.resolve(value);
  }
  console.log(JSON.stringify(await assembleRelease(options), null, 2));
}
