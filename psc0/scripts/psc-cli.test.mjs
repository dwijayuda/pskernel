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
  const temporary = await mkdtemp(path.join(tmpdir(), 'psc cli spaces-'));
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
    ...['project-init.mjs', 'command-extensions.mjs', 'command-wasm-profile.mjs',
      'command-extension-worker.mjs', 'checked-artifact-publication.mjs'].map(file =>
      copyFile(path.join(root, 'scripts', file), path.join(installed, 'scripts', file))),
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
  assert.equal(call.nativeBinaryPath, path.join(context.installed, 'runtime/kernel',
    process.platform + '-' + process.arch, 'psc_kernel_core_provider' +
    (process.platform === 'win32' ? '.exe' : '')));
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
    defaultExtensions: [], configuredExtensions: [], loadedExtensions: [], executionSupported: true,
    protocol: 'psc-command/1',
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

test('unknown verification configuration and invalid extension requests fail closed', async t => {
  for (const proofscript of [
    { profile: 'checked', verification: { pscv: true } },
    { profile: 'contracts' },
    { extensions: ['third-party-proofscript-extension'] },
    { extensions: false },
  ]) {
    const context = await fixture(t, proofscript);
    const run = context.invoke(['check', 'src/Main.ps']);
    assert.notEqual(run.status, 0);
    assert.match(run.stderr, /PSC_(?:(?:PROJECT_CONFIGURATION|PROJECT_PROFILE)_UNSUPPORTED|EXTENSION_CONFIGURATION)/u);
    await notCalled(context);
  }
});

test('public CLI refuses alternate code, unimplemented commands, and environment overrides', async t => {
  const context = await fixture(t);
  for (const args of [
    ['check', 'src/Main.ps', '--compiler', '/tmp/untrusted.mjs'],
    ['check', 'src/Main.ps', '--kernel', 'lean434'],
    ['check', 'src/Main.ps', '--profile', 'pscv'],
    ['build'], ['dev', 'src/Main.ps'], ['dev', 'src/Main.ps', '--watch'],
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

test('version reports the actual host and both packaged platforms', async t => {
  const context = await fixture(t);
  const run = context.invoke(['version', '--json']);
  assert.equal(run.status, 0, run.stderr);
  const version = JSON.parse(run.stdout);
  assert.deepEqual(version.platform, { os: process.platform, arch: process.arch });
  assert.deepEqual(version.supportedPlatforms, [
    { os: 'linux', arch: 'x64' }, { os: 'win32', arch: 'x64' },
  ]);
  assert.deepEqual(Object.keys(version.kernel.artifacts), ['linux-x64', 'win32-x64']);
  await notCalled(context);
});

test('init routes through the installed release and creates no compiler activity', async t => {
  const context = await fixture(t);
  const run = context.invoke(['init', 'new project', '--json']);
  assert.equal(run.status, 0, run.stderr);
  const result = JSON.parse(run.stdout);
  assert.equal(result.projectRoot, path.join(context.project, 'new project'));
  const metadata = JSON.parse(await readFile(path.join(result.projectRoot, 'package.json'), 'utf8'));
  const release = JSON.parse(await readFile(path.join(context.installed, 'release.json'), 'utf8'));
  assert.equal(metadata.devDependencies.proofscript, release.version);
  assert.equal(metadata.proofscript.entry, 'src/Main.ps');
  assert.equal(metadata.proofscript.out, 'src/Main.ts');
  assert.match(await readFile(path.join(result.projectRoot, 'src/Main.ps'), 'utf8'), /Nat/u);
  assert.equal(run.stderr, 'PSC_EXTENSIONS: []\n');
  await notCalled(context);
});

test('project defaults resolve from the selected root and explicit entry gets its own adjacent output', async t => {
  const context = await fixture(t, {
    profile: 'checked', entry: 'src/Main.ps', out: 'dist/Bundle.ts', extensions: [],
  });
  let run = context.invoke(['build', '--json'], { cwd: path.join(context.project, 'src') });
  assert.equal(run.status, 0, run.stderr);
  let call = JSON.parse(await readFile(context.marker, 'utf8'));
  assert.equal(call.entryPath, path.join(context.project, 'src/Main.ps'));
  assert.equal(call.outputPath, path.join(context.project, 'dist/Bundle.ts'));
  run = context.invoke(['build', 'src/Main.ps']);
  assert.equal(run.status, 0, run.stderr);
  call = JSON.parse(await readFile(context.marker, 'utf8'));
  assert.equal(call.outputPath, path.join(context.project, 'src/Main.ts'));
  run = context.invoke(['check', '--json']);
  assert.equal(run.status, 0, run.stderr);
  call = JSON.parse(await readFile(context.marker, 'utf8'));
  assert.equal(call.checkOnly, true);
  assert.equal(Object.hasOwn(call, 'outputPath'), false);
});

test('project path settings cannot escape or silently select unsupported source/output kinds', async t => {
  for (const config of [
    { entry: '../Outside.ps' }, { entry: '/outside/Main.ps' },
    { entry: 'C:/outside/Main.ps' }, { entry: 'D:Outside.ps' }, { entry: 'src/Main.ts' },
    { entry: 'src/Main.ps', out: '../Outside.ts' }, { entry: 'src/Main.ps', out: 'D:Other.ts' },
    { entry: 'src/Main.ps', out: 'dist/Main.wasm' },
    { entry: 'src\\Main.ps' },
  ]) {
    const context = await fixture(t, { profile: 'checked', ...config });
    const run = context.invoke(['build']);
    assert.notEqual(run.status, 0);
    assert.match(run.stderr, /PSC_PROJECT_PATH/u);
    await notCalled(context);
  }
});

test('enabled command packages are not executed or resolved by ordinary check and build', async t => {
  const context = await fixture(t, { profile: 'checked', extensions: [
    { package: 'psdev', enable: ['command:dev'] },
  ] });
  const run = context.invoke(['check', 'src/Main.ps', '--json']);
  assert.equal(run.status, 0, run.stderr);
  assert.equal(run.stderr, 'PSC_EXTENSIONS: []\n');
  assert.deepEqual(JSON.parse(run.stdout).extensions, []);
});

test('dev requires explicit activation and refuses watch before requesting a build', async t => {
  const context = await fixture(t);
  let run = context.invoke(['dev', 'src/Main.ps', '--once']);
  assert.notEqual(run.status, 0);
  assert.match(run.stderr, /PSC_DEV_EXTENSION_REQUIRED/u);
  await notCalled(context);
  run = context.invoke(['dev', 'src/Main.ps', '--watch']);
  assert.notEqual(run.status, 0);
  assert.match(run.stderr, /PSC_DEV_WATCH_UNSUPPORTED/u);
  await notCalled(context);
  run = context.invoke(['dev', 'src/Main.ps', '--once', '--out', 'src/Main.js']);
  assert.notEqual(run.status, 0);
  assert.match(run.stderr, /PSC_DEV_OUTPUT_KIND/u);
  await notCalled(context);
});

test('examples lists shipped source locations without invoking compiler or npm code', async t => {
  const context = await fixture(t);
  const run = context.invoke(['examples', '--json']);
  assert.equal(run.status, 0, run.stderr);
  const { examples } = JSON.parse(run.stdout);
  assert.deepEqual(examples.map(item => item.name), ['checked-nat', 'existing-typescript', 'rejected-source']);
  for (const example of examples) {
    assert.equal(example.path, path.join(context.installed, 'examples/platform', example.name));
  }
  await notCalled(context);
});
