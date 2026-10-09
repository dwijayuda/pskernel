import assert from 'node:assert/strict';
import { test } from 'node:test';
import { copyFile, mkdir, mkdtemp, readFile, rm, writeFile, access } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

const root = fileURLToPath(new URL('../', import.meta.url));
const overrides = ['PSC0_TSC', 'PSC0_TYPESCRIPT_VERSION', 'PSC_KERNEL_CORE_PROVIDER_BIN',
  'PSC_LEAN_KERNEL_PROVIDER_BIN'];

// This fixture tests public CLI policy and path plumbing without executing a
// compiler/provider. The cloud package smoke test checks the real runtimes.
async function fixture(t, proofscript = { profile: 'checked', extensions: [] }) {
  const temporary = await mkdtemp(path.join(tmpdir(), 'psc-cli-'));
  t.after(() => rm(temporary, { recursive: true, force: true }));
  const installed = path.join(temporary, 'installed');
  const project = path.join(temporary, 'project');
  await Promise.all([
    mkdir(path.join(installed, 'bin'), { recursive: true }),
    mkdir(path.join(installed, 'scripts'), { recursive: true }),
    mkdir(path.join(installed, 'node_modules/typescript'), { recursive: true }),
    mkdir(path.join(project, 'src'), { recursive: true }),
  ]);
  await Promise.all([
    copyFile(path.join(root, 'bin/psc.mjs'), path.join(installed, 'bin/psc.mjs')),
    copyFile(path.join(root, 'scripts/release-manifest.mjs'), path.join(installed, 'scripts/release-manifest.mjs')),
    copyFile(path.join(root, 'release/release.json'), path.join(installed, 'release.json')),
    writeFile(path.join(installed, 'node_modules/typescript/package.json'), JSON.stringify({ name: 'typescript', version: '7.0.2' })),
    writeFile(path.join(project, 'package.json'), JSON.stringify({ name: 'fixture', proofscript })),
    writeFile(path.join(project, 'src/Main.ps'), '-- CLI-only source fixture\n'),
    writeFile(path.join(project, 'src/Main.lean'), '-- CLI-only source fixture\n'),
  ]);
  await writeFile(path.join(installed, 'scripts/checked-build.mjs'), `
import { writeFile } from 'node:fs/promises';
export async function buildChecked(options) {
  await writeFile(new URL('../called.json', import.meta.url), JSON.stringify({
    ...options, callerCwd: process.cwd(), hasAbortSignal: options.signal instanceof AbortSignal,
  }));
  return { schemaVersion: 4, kind: 'psc-checked-fixture', extensions: [], semanticPreservationProved: false };
}
`);
  const env = { ...process.env };
  for (const key of overrides) delete env[key];
  const invoke = (args, options = {}) => spawnSync(process.execPath,
    [path.join(installed, 'bin/psc.mjs'), ...args],
    { cwd: project, encoding: 'utf8', timeout: 15000, env, ...options });
  return { temporary, installed, project, invoke, marker: path.join(installed, 'called.json') };
}

async function notCalled(context) {
  await assert.rejects(access(context.marker), { code: 'ENOENT' });
}

test('public build preserves caller cwd and pins installed runtimes', async t => {
  const context = await fixture(t);
  const run = context.invoke(['build', 'src/Main.ps', '--out', 'dist/Main.js', '--json']);
  assert.equal(run.status, 0, run.stderr);
  assert.equal(JSON.parse(run.stdout).semanticPreservationProved, false);
  assert.equal(run.stderr, 'PSC_EXTENSIONS: []\n');
  const call = JSON.parse(await readFile(context.marker, 'utf8'));
  const release = JSON.parse(await readFile(path.join(context.installed, 'release.json'), 'utf8'));
  assert.equal(call.callerCwd, context.project);
  assert.equal(call.entryPath, path.join(context.project, 'src/Main.ps'));
  assert.equal(call.outputPath, path.join(context.project, 'dist/Main.js'));
  assert.equal(call.compilerPath, path.join(context.installed, 'runtime/compiler/index.js'));
  assert.equal(call.nativeBinaryPath, path.join(context.installed, 'runtime/kernel/linux-x64/psc_kernel_core_provider'));
  assert.equal(call.compilerSha256, release.compiler.sha256);
  assert.equal(call.kernel, 'pskernel-core');
  assert.equal(call.profile, 'checked');
  assert.equal(call.checkOnly, false);
  assert.equal(call.hasAbortSignal, true);
});

test('check needs no output and help/version/extensions do not run the compiler', async t => {
  const context = await fixture(t);
  for (const args of [['--help'], ['--version'], ['extensions', '--json']]) {
    const run = context.invoke(args);
    assert.equal(run.status, 0, run.stderr);
    assert.equal(run.stderr, 'PSC_EXTENSIONS: []\n');
    await notCalled(context);
  }
  const extensions = context.invoke(['extensions', '--json']);
  assert.deepEqual(JSON.parse(extensions.stdout), {
    defaultExtensions: [], loadedExtensions: [], executionSupported: false,
  });
  const run = context.invoke(['check', 'src/Main.lean', '--json']);
  assert.equal(run.status, 0, run.stderr);
  const call = JSON.parse(await readFile(context.marker, 'utf8'));
  assert.equal(call.checkOnly, true);
  assert.equal(Object.hasOwn(call, 'outputPath'), false);
});

test('nested source package cannot weaken caller PSCV policy', async t => {
  const context = await fixture(t, { profile: 'pscv', extensions: [] });
  await writeFile(path.join(context.project, 'src/package.json'), JSON.stringify({
    proofscript: { profile: 'checked', extensions: [] },
  }));
  const run = context.invoke(['check', 'src/Main.ps']);
  assert.notEqual(run.status, 0);
  assert.match(run.stderr, /PSC_PROJECT_PROFILE_UNSUPPORTED/u);
  await notCalled(context);
});

test('unknown verification configuration and requested extensions fail closed', async t => {
  for (const proofscript of [
    { profile: 'checked', verification: { pscv: true } },
    { profile: 'contracts' },
    { extensions: ['third-party-proofscript-extension'] },
    { extensions: false },
  ]) {
    const context = await fixture(t, proofscript);
    const run = context.invoke(['check', 'src/Main.ps']);
    assert.notEqual(run.status, 0);
    assert.match(run.stderr, /PSC_(?:PROJECT_CONFIGURATION|PROJECT_PROFILE|EXTENSIONS)_UNSUPPORTED/u);
    await notCalled(context);
  }
});

test('public CLI refuses alternate code, unimplemented commands, and environment overrides', async t => {
  const context = await fixture(t);
  for (const args of [
    ['check', 'src/Main.ps', '--compiler', '/tmp/untrusted.mjs'],
    ['check', 'src/Main.ps', '--kernel', 'lean434'],
    ['check', 'src/Main.ps', '--profile', 'pscv'],
    ['build', 'src/Main.ps'],
    ['watch'], ['lsp'],
  ]) {
    const run = context.invoke(args);
    assert.notEqual(run.status, 0);
    await notCalled(context);
  }
  const run = context.invoke(['check', 'src/Main.ps'], {
    env: { ...process.env, PSC0_TSC: '/tmp/untrusted-tsc' },
  });
  assert.notEqual(run.status, 0);
  assert.match(run.stderr, /PSC_RELEASE_OVERRIDE_UNSUPPORTED/u);
  await notCalled(context);
});

test('entry outside caller project is rejected even if it has its own checked policy', async t => {
  const context = await fixture(t);
  const outside = path.join(context.temporary, 'outside');
  await mkdir(outside);
  await writeFile(path.join(outside, 'package.json'), JSON.stringify({ proofscript: { profile: 'checked' } }));
  await writeFile(path.join(outside, 'Main.ps'), '-- outside fixture\n');
  const run = context.invoke(['check', path.join(outside, 'Main.ps')]);
  assert.notEqual(run.status, 0);
  assert.match(run.stderr, /PSC_ENTRY_OUTSIDE_PROJECT/u);
  await notCalled(context);
});

test('unavailable release defaults cannot activate code or falsify the empty disclosure', async t => {
  const context = await fixture(t);
  const file = path.join(context.installed, 'release.json');
  const release = JSON.parse(await readFile(file, 'utf8'));
  release.defaultExtensions = [{ name: 'evil', entry: './evil.mjs' }];
  await writeFile(file, JSON.stringify(release));
  const run = context.invoke(['--version']);
  assert.notEqual(run.status, 0);
  assert.match(run.stderr, /^PSC_EXTENSIONS: \[\]\n/u);
  assert.match(run.stderr, /PSC_RELEASE_EXTENSIONS_UNSUPPORTED/u);
  await notCalled(context);
});

test('public build rejects missing or wrong installed TypeScript before invoking the host', async t => {
  const context = await fixture(t);
  const metadata = path.join(context.installed, 'node_modules/typescript/package.json');
  await writeFile(metadata, JSON.stringify({ name: 'typescript', version: '5.8.3' }));
  let run = context.invoke(['build', 'src/Main.ps', '--out', 'dist/Main.js']);
  assert.notEqual(run.status, 0);
  assert.match(run.stderr, /PSC_RELEASE_TYPESCRIPT_PIN/u);
  await notCalled(context);
  await rm(path.dirname(metadata), { recursive: true });
  run = context.invoke(['build', 'src/Main.ps', '--out', 'dist/Main.js']);
  assert.notEqual(run.status, 0);
  assert.match(run.stderr, /PSC_RELEASE_TYPESCRIPT_MISSING/u);
  await notCalled(context);
});
