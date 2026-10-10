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
  'scripts/project-init.mjs',
  'scripts/project-watch.mjs',
  'scripts/command-extensions.mjs',
  'scripts/command-extension-worker.mjs',
  'scripts/command-wasm-profile.mjs',
  'scripts/checked-build.mjs',
  'scripts/checked-project.mjs',
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

// Shipped source examples are data, never loaded as compiler or extension code.
export const releaseExampleFiles = Object.freeze([
  "examples/platform/README.md",
  "examples/platform/checked-nat/package.json",
  "examples/platform/checked-nat/src/Main.ps",
  "examples/platform/existing-typescript/package.json",
  "examples/platform/existing-typescript/tsconfig.json",
  "examples/platform/existing-typescript/src/Main.ps",
  "examples/platform/existing-typescript/src/consumer.ts",
  "examples/platform/rejected-source/Main.ps",
  "examples/platform/rejected-source/README.md",
  "examples/platform/checked-nat/README.md",
  "examples/platform/existing-typescript/README.md",
  "examples/platform/checked-library/README.md",
  "examples/platform/checked-library/package.json",
  "examples/platform/checked-library/tsconfig.json",
  "examples/platform/checked-library/src/Quantity.ps",
  "examples/platform/checked-library/src/Main.ps",
  "examples/platform/checked-library/src/consumer.ts"
]);

async function absent(file) {
  try { await lstat(file); }
  catch (error) { if (error.code === 'ENOENT') return; throw error; }
  throw new Error('PSC_RELEASE_OUTPUT_EXISTS: ' + file);
}

function assertNativeImage(bytes, key) {
  if (key === 'linux-x64') {
    if (bytes.length < 64 || bytes[0] !== 0x7f || bytes.subarray(1, 4).toString() !== 'ELF' ||
        bytes[4] !== 2 || bytes[5] !== 1 || bytes.readUInt16LE(18) !== 62) {
      throw new Error('PSC_RELEASE_KERNEL_PLATFORM: expected Linux x64 ELF');
    }
    return;
  }
  const pe = bytes.length >= 64 ? bytes.readUInt32LE(0x3c) : 0;
  if (bytes.length < 64 || bytes.subarray(0, 2).toString() !== 'MZ' ||
      pe < 64 || pe + 26 > bytes.length ||
      bytes.subarray(pe, pe + 4).toString('binary') !== 'PE\0\0' ||
      bytes.readUInt16LE(pe + 4) !== 0x8664 ||
      bytes.readUInt16LE(pe + 24) !== 0x20b ||
      !(bytes.readUInt16LE(pe + 22) & 0x0002) ||
      Boolean(bytes.readUInt16LE(pe + 22) & 0x2000)) {
    throw new Error('PSC_RELEASE_KERNEL_PLATFORM: expected Windows x64 PE executable');
  }
}

export async function assembleRelease({
  workspaceRoot = root, compilerPath, nativeBinaryPaths, outputPath,
} = {}) {
  const keys = ['linux-x64', 'win32-x64'];
  if (!compilerPath || !outputPath || !nativeBinaryPaths ||
      Object.keys(nativeBinaryPaths).length !== keys.length ||
      keys.some(key => typeof nativeBinaryPaths[key] !== 'string' || !nativeBinaryPaths[key])) {
    throw new Error('PSC_RELEASE_INPUTS: require compiler, both native providers, and output paths');
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
      Object.hasOwn(metadata, 'workspaces') ||
      JSON.stringify(metadata.os) !== JSON.stringify(['linux', 'win32']) ||
      JSON.stringify(metadata.cpu) !== JSON.stringify(['x64']) ||
      metadata.engines?.node !== '>=22.23.3 <23 || >=26.7.0 <27') {
    throw new Error('PSC_RELEASE_PACKAGE_PROFILE');
  }
  const closure = await readBootstrapClosure(workspaceRoot);
  if (closure.sha256 !== release.compiler.sourceClosureSha256) {
    throw new Error('PSC_RELEASE_SOURCE_CLOSURE_MISMATCH');
  }
  // Authenticate every byte before copying or executing an input. Both platforms
  // are assembled together; this process does not execute either native image.
  const compiler = await readFile(compilerPath);
  if (sha256(compiler) !== release.compiler.sha256) throw new Error('PSC_RELEASE_COMPILER_PIN');
  const native = await Promise.all(keys.map(async key => {
    const expected = release.kernel.artifacts[key];
    const binary = await readFile(nativeBinaryPaths[key]);
    if (sha256(binary) !== expected.sha256) throw new Error('PSC_RELEASE_KERNEL_PIN: ' + key);
    assertNativeImage(binary, key);
    return { key, binary };
  }));
  const sources = await Promise.all([...releaseHostFiles, ...releaseExampleFiles].map(async file => [
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
    await put(path.join(staging, 'runtime/compiler/index.js'), compiler);
    for (const artifact of native) {
      const os = artifact.key === 'win32-x64' ? 'win32' : 'linux';
      const runtime = releaseRuntimePaths(staging, os, 'x64');
      await put(runtime.nativeBinaryPath, artifact.binary);
      await chmod(runtime.nativeBinaryPath, 0o755);
    }
    await chmod(path.join(staging, 'bin/psc.mjs'), 0o755);
    await absent(output);
    await rename(staging, output);
  } finally {
    await rm(staging, { recursive: true, force: true });
  }
  return Object.freeze({
    kind: 'proofscript-release-assembly', outputPath: output, version: release.version,
    compilerSha256: release.compiler.sha256, kernelArtifacts: release.kernel.artifacts,
    sourceClosureSha256: closure.sha256, moduleCount: closure.moduleCount,
    hostFiles: releaseHostFiles, exampleFiles: releaseExampleFiles, extensions: [],
    runtimeExecuted: false, runtimeQualificationRequired: true,
  });
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const options = { nativeBinaryPaths: {} };
  const args = process.argv.slice(2);
  while (args.length) {
    const flag = args.shift();
    const key = { '--compiler': 'compilerPath', '--kernel-linux': 'linux-x64',
      '--kernel-windows': 'win32-x64', '--out': 'outputPath' }[flag];
    const value = args.shift();
    const target = key?.endsWith('-x64') ? options.nativeBinaryPaths : options;
    if (!key || !value || value.startsWith('--') || target[key] !== undefined) {
      throw new Error('usage: assemble-release.mjs --compiler index.js --kernel-linux provider --kernel-windows provider.exe --out new-directory');
    }
    target[key] = path.resolve(value);
  }
  console.log(JSON.stringify(await assembleRelease(options), null, 2));
}
