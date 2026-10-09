import assert from 'node:assert/strict';
import { test } from 'node:test';
import { access, mkdir, mkdtemp, readFile, readdir, rm, stat, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';
import { assembleRelease, releaseHostFiles } from './assemble-release.mjs';
import { readBootstrapClosure, bootstrapEntryRelative } from './sh1-source-snapshot.mjs';

const root = fileURLToPath(new URL('../', import.meta.url));
const sha256 = bytes => createHash('sha256').update(bytes).digest('hex');

async function fixture(t) {
  const temporary = await mkdtemp(path.join(tmpdir(), 'psc-assembly-'));
  t.after(() => rm(temporary, { recursive: true, force: true }));
  const workspaceRoot = path.join(temporary, 'source');
  const outputPath = path.join(temporary, 'assembled');
  async function source(file, content) {
    const target = path.join(workspaceRoot, file);
    await mkdir(path.dirname(target), { recursive: true });
    await writeFile(target, content);
  }
  // Synthetic pinned bytes test copying, identity checks, and non-execution.
  // They are never used as compiler/kernel qualification evidence.
  const compiler = Buffer.from('throw new Error("assembler must not execute compiler inputs");\n');
  const provider = Buffer.alloc(128);
  provider.write('\x7fELF', 0, 'binary');
  provider[4] = 2; provider[5] = 1; provider.writeUInt16LE(62, 18);
  const compilerPath = path.join(temporary, 'input-compiler.js');
  const nativeBinaryPath = path.join(temporary, 'input-provider');
  await Promise.all([writeFile(compilerPath, compiler), writeFile(nativeBinaryPath, provider)]);
  await source(bootstrapEntryRelative, '-- synthetic source closure\n');
  const closure = await readBootstrapClosure(workspaceRoot);
  const release = JSON.parse(await readFile(path.join(root, 'release/release.json'), 'utf8'));
  release.compiler.sha256 = sha256(compiler);
  release.compiler.sourceClosureSha256 = closure.sha256;
  release.kernel.sha256 = sha256(provider);
  await source('release/release.json', JSON.stringify(release));
  await source('release/package.json', await readFile(path.join(root, 'release/package.json')));
  await source('release/README.md', 'Synthetic test package; not a release.\n');
  await source('packages/pskernel-lean-wasm/LEAN_LICENSE', 'Synthetic fixture attribution.\n');
  for (const file of releaseHostFiles) await source(file, '// maintained fixture: ' + file + '\n');
  await source('scripts/unlisted-test.mjs', 'throw new Error("must not be packaged");\n');
  await source('legacy/should-not-leak.txt', 'must not be packaged\n');
  return { workspaceRoot, outputPath, compilerPath, nativeBinaryPath, source, release, compiler, provider };
}

test('assembler copies exact pinned bytes and maintained host files without executing inputs', async t => {
  const context = await fixture(t);
  const result = await assembleRelease(context);
  assert.equal(result.runtimeExecuted, false);
  assert.equal(result.runtimeQualificationRequired, true);
  assert.deepEqual(await readFile(path.join(context.outputPath, 'runtime/compiler/index.js')), context.compiler);
  assert.deepEqual(await readFile(path.join(context.outputPath, 'runtime/kernel/linux-x64/psc_kernel_core_provider')), context.provider);
  for (const file of releaseHostFiles) {
    assert.deepEqual(await readFile(path.join(context.outputPath, file)),
      await readFile(path.join(context.workspaceRoot, file)));
  }
  await assert.rejects(access(path.join(context.outputPath, 'legacy')), { code: 'ENOENT' });
  await assert.rejects(access(path.join(context.outputPath, 'scripts/unlisted-test.mjs')), { code: 'ENOENT' });
  const metadata = JSON.parse(await readFile(path.join(context.outputPath, 'package.json'), 'utf8'));
  assert.equal(metadata.bin.psc, './bin/psc.mjs');
  assert.equal(metadata.dependencies.typescript, '7.0.2');
  assert.equal(Object.hasOwn(metadata, 'scripts'), false);
  if (process.platform !== 'win32') {
    assert.equal((await stat(path.join(context.outputPath, 'bin/psc.mjs'))).mode & 0o111, 0o111);
    assert.equal((await stat(path.join(context.outputPath, 'runtime/kernel/linux-x64/psc_kernel_core_provider'))).mode & 0o111, 0o111);
  }
});

test('assembler rejects compiler/provider tampering and source-closure drift before publication', async t => {
  for (const [kind, expected] of [
    ['compiler', /PSC_RELEASE_COMPILER_PIN/u],
    ['provider', /PSC_RELEASE_KERNEL_PIN/u],
    ['source', /PSC_RELEASE_SOURCE_CLOSURE_MISMATCH/u],
  ]) {
    const context = await fixture(t);
    if (kind === 'compiler') await writeFile(context.compilerPath, 'different compiler');
    if (kind === 'provider') await writeFile(context.nativeBinaryPath, 'different provider');
    if (kind === 'source') await context.source(bootstrapEntryRelative, '-- changed source\n');
    await assert.rejects(assembleRelease(context), expected);
    await assert.rejects(access(context.outputPath), { code: 'ENOENT' });
  }
});

test('assembler refuses unavailable artifacts, missing host modules, and existing destinations', async t => {
  const context = await fixture(t);
  await rm(path.join(context.workspaceRoot, 'scripts/checked-build.mjs'));
  await assert.rejects(assembleRelease(context), { code: 'ENOENT' });
  await assert.rejects(access(context.outputPath), { code: 'ENOENT' });
  await assert.rejects(assembleRelease({ ...context, compilerPath: undefined }), /PSC_RELEASE_INPUTS/u);
  await mkdir(context.outputPath);
  await writeFile(path.join(context.outputPath, 'keep.txt'), 'existing output');
  await assert.rejects(assembleRelease(context), /PSC_RELEASE_OUTPUT_EXISTS/u);
  assert.equal(await readFile(path.join(context.outputPath, 'keep.txt'), 'utf8'), 'existing output');
  const siblings = await readdir(path.dirname(context.outputPath));
  assert.equal(siblings.some(name => name.startsWith('.proofscript-release-')), false);
});

test('assembler refuses default execution requests and package lifecycle hooks', async t => {
  const context = await fixture(t);
  context.release.defaultExtensions = ['psdev'];
  await context.source('release/release.json', JSON.stringify(context.release));
  await assert.rejects(assembleRelease(context), /PSC_RELEASE_EXTENSIONS_UNSUPPORTED/u);
  context.release.defaultExtensions = [];
  await context.source('release/release.json', JSON.stringify(context.release));
  const metadata = JSON.parse(await readFile(path.join(root, 'release/package.json'), 'utf8'));
  metadata.scripts = { postinstall: 'node bootstrap.mjs' };
  await context.source('release/package.json', JSON.stringify(metadata));
  await assert.rejects(assembleRelease(context), /PSC_RELEASE_PACKAGE_PROFILE/u);
  await assert.rejects(access(context.outputPath), { code: 'ENOENT' });
});

test('release compiler pin still describes the exact maintained self-host source closure', async () => {
  const release = JSON.parse(await readFile(path.join(root, 'release/release.json'), 'utf8'));
  const closure = await readBootstrapClosure(root);
  assert.equal(closure.sha256, release.compiler.sourceClosureSha256);
});
