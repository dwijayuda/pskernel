import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { access, mkdir, mkdtemp, readFile, rm, symlink, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { createRequire } from 'node:module';

// Run only in a fresh Actions job with Node, npm and the release tarball.
// No checkout, Lean toolchain, bootstrap seed or source compiler is required.
const [tarballArgument, outputArgument] = process.argv.slice(2);
assert(tarballArgument && outputArgument, 'usage: platform-release-smoke.mjs <tarball> <evidence-directory>');
const tarball = path.resolve(tarballArgument);
const evidence = path.resolve(outputArgument);
await mkdir(evidence, { recursive: true });
const temporary = await mkdtemp(path.join(tmpdir(), 'proofscript-installed-'));
const prefix = path.join(temporary, 'global');
const project = path.join(temporary, 'project');
const observations = [];
const digest = bytes => createHash('sha256').update(bytes).digest('hex');
let passed = false;
let failure;
let tarballSha256 = null;
let tarballBytes = null;
let releaseIdentity = null;
let providerRuntime = null;

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    encoding: 'utf8', timeout: 120000, maxBuffer: 8 * 1024 * 1024,
    cwd: project, ...options,
  });
  if (result.error) throw result.error;
  return result;
}
function success(result, label) {
  assert.equal(result.status, 0, label + ': ' + result.stdout + '\n' + result.stderr);
  observations.push(label);
  return result;
}
async function missing(file) {
  await assert.rejects(access(file), { code: 'ENOENT' });
}

try {
  const archive = await readFile(tarball);
  tarballSha256 = digest(archive);
  tarballBytes = archive.length;
  await mkdir(path.join(project, 'src'), { recursive: true });
  await writeFile(path.join(project, 'package.json'), JSON.stringify({
    name: 'proofscript-installed-fixture', private: true, type: 'module',
    proofscript: { profile: 'checked', extensions: [] },
  }, null, 2) + '\n');
  success(run('npm', ['install', '--global', '--prefix', prefix, '--ignore-scripts',
    '--no-audit', '--no-fund', tarball]), 'fresh global tarball install without lifecycle scripts');
  const installed = path.join(prefix, 'lib/node_modules/proofscript');
  const command = path.join(prefix, 'bin/psc');
  const release = JSON.parse(await readFile(path.join(installed, 'release.json'), 'utf8'));
  releaseIdentity = { version: release.version, compiler: release.compiler, kernel: release.kernel, typescriptVersion: release.typescriptVersion };
  const metadata = JSON.parse(await readFile(path.join(installed, 'package.json'), 'utf8'));
  assert.equal(metadata.name, 'proofscript');
  assert.equal(metadata.dependencies.typescript, '7.0.2');
  assert.equal(Object.hasOwn(metadata, 'scripts'), false);
  assert.equal(digest(await readFile(path.join(installed, 'runtime/compiler/index.js'))), release.compiler.sha256);
  const provider = path.join(installed, 'runtime/kernel/linux-x64/psc_kernel_core_provider');
  assert.equal(digest(await readFile(provider)), release.kernel.sha256);

  // The CLI gets only a dedicated Node symlink directory on PATH. No Lean/lake/npm/tsc fallback
  // can satisfy the package smoke. Build invokes absolute packaged tools.
  const nodeOnlyPath = path.join(temporary, 'node-only');
  await mkdir(nodeOnlyPath);
  await symlink(process.execPath, path.join(nodeOnlyPath, 'node'));
  const env = { ...process.env, PATH: nodeOnlyPath };
  for (const name of ['PSC0_TSC', 'PSC0_TYPESCRIPT_VERSION', 'PSC_KERNEL_CORE_PROVIDER_BIN',
    'PSC_LEAN_KERNEL_PROVIDER_BIN', 'PSC0_TEST_KERNEL_CORE_PROVIDER_BIN',
    'PSC0_PLATFORM_COMPILER', 'LEAN_PATH', 'LEAN_SRC_PATH', 'ELAN_HOME', 'NODE_PATH',
    'NODE_OPTIONS', 'LD_LIBRARY_PATH']) delete env[name];
  const invoke = args => run(command, args, { env });
  const version = success(invoke(['version', '--json']), 'installed executable and version');
  assert.equal(JSON.parse(version.stdout).version, release.version);
  assert.equal(version.stderr, 'PSC_EXTENSIONS: []\n');
  const extensions = success(invoke(['extensions', '--json']), 'supervisor extension disclosure');
  assert.deepEqual(JSON.parse(extensions.stdout), {
    defaultExtensions: [], loadedExtensions: [], executionSupported: false,
  });

  const source = path.join(project, 'src/Main.ps');
  await writeFile(source, 'def answer : Nat := 42\n');
  const check = JSON.parse(success(invoke(['check', 'src/Main.ps', '--json']),
    'packaged compiler and native Core admission').stdout);
  assert.equal(check.kernelAdmissionAccepted, true);
  assert.equal(check.kernel.binarySha256, release.kernel.sha256);
  assert.equal(check.runtimeIr.status, 'not-requested');
  await missing(path.join(project, 'src/Main.ts'));

  const built = success(invoke(['build', 'src/Main.ps', '--out', 'src/Main.ts', '--json']),
    'neighboring TypeScript publication from the installed package');
  assert.equal(built.stderr, 'PSC_EXTENSIONS: []\n');
  const receipt = JSON.parse(built.stdout);
  assert.equal(receipt.schemaVersion, 4);
  assert.equal(receipt.compiler.sha256, release.compiler.sha256);
  assert.equal(receipt.runtimeIr.runtimeIrTypingAccepted, true);
  assert.equal(receipt.runtimeIr.traversalComplete, true);
  assert.equal(receipt.runtimeIr.sameOriginalIrCheckedBeforeEmission, true);
  assert.equal(receipt.targetValidation.version, '7.0.2');
  for (const field of ['pscvVerified', 'strictSh1Qualified', 'semanticPreservationProved']) assert.equal(receipt[field], false);
  assert.deepEqual(receipt.extensions, []);
  assert.deepEqual(receipt.artifacts.map(item => item.name), ['Main.ts']);
  const savedReceipt = await readFile(path.join(project, 'src/Main.checked.json'));
  assert.deepEqual(JSON.parse(savedReceipt.toString('utf8')), receipt);
  const generated = await readFile(path.join(project, 'src/Main.ts'));
  assert.equal(digest(generated), receipt.artifacts[0].sha256);
  await missing(path.join(project, 'src/Main.js'));
  await missing(path.join(project, 'src/Main.d.ts'));
  await writeFile(path.join(project, 'src/consumer.ts'),
    "import { answer } from './Main.js';\n" +
    "const result: bigint = answer;\n" +
    "if (result !== 42n) throw new Error('wrong compiled result');\n" +
    "console.log('PSC_INSTALLED_CONSUMER: 42');\n");
  await writeFile(path.join(project, 'tsconfig.json'), JSON.stringify({
    compilerOptions: {
      target: 'ES2022', module: 'NodeNext', moduleResolution: 'NodeNext',
      strict: true, noEmitOnError: true, rootDir: 'src', outDir: 'dist',
    }, include: ['src/**/*.ts'],
  }, null, 2) + '\n');
  const require = createRequire(path.join(installed, 'package.json'));
  const tsPackage = require.resolve('typescript/package.json');
  const tsMetadata = JSON.parse(await readFile(tsPackage, 'utf8'));
  assert.equal(tsMetadata.version, release.typescriptVersion);
  const tsLauncher = path.resolve(path.dirname(tsPackage), tsMetadata.bin.tsc);
  success(run(process.execPath, [tsLauncher, '--project', 'tsconfig.json'], { env }),
    'existing TypeScript project typechecks generated neighbor');
  const consumer = success(run(process.execPath, ['dist/consumer.js'], { env }),
    'existing TypeScript project executes generated neighbor');
  assert.equal(consumer.stdout.trim(), 'PSC_INSTALLED_CONSUMER: 42');

  await writeFile(source, 'def answer : Nat := Type\n');
  const refused = invoke(['build', 'src/Main.ps', '--out', 'src/Main.ts', '--json']);
  assert.notEqual(refused.status, 0);
  assert.equal(refused.stdout, '');
  assert.match(refused.stderr, /PSC2_CHECKED_(?:PREPARE|EMIT)_FAILED|PSC2_KERNEL_REJECTED/u);
  assert.deepEqual(await readFile(path.join(project, 'src/Main.ts')), generated);
  assert.deepEqual(await readFile(path.join(project, 'src/Main.checked.json')), savedReceipt);
  observations.push('invalid source cannot replace the previous completed output');

  await writeFile(path.join(project, 'package.json'), JSON.stringify({
    name: 'proofscript-installed-fixture', type: 'module', proofscript: { profile: 'pscv' },
  }));
  const unsupported = invoke(['check', 'src/Main.ps', '--json']);
  assert.notEqual(unsupported.status, 0);
  assert.match(unsupported.stderr, /PSC_PROJECT_PROFILE_UNSUPPORTED/u);
  observations.push('requested PSCV is explicitly refused');

  const dependencies = success(run('/usr/bin/ldd', [provider], { env }), 'packaged provider linked-library inspection');
  assert(!/not found|\.elan|provider-source|\.lake/u.test(dependencies.stdout + dependencies.stderr),
    'packaged provider has no unprovided Lean/source/build-path shared library dependency');
  const interpreter = success(run('/usr/bin/readelf', ['-l', provider], { env }), 'packaged provider ELF interpreter inspection');
  const versions = success(run('/usr/bin/readelf', ['--version-info', provider], { env }), 'packaged provider ABI version inspection');
  providerRuntime = {
    linkedLibraries: dependencies.stdout.trim().split('\n').map(line => line.trim()),
    interpreter: /Requesting program interpreter: ([^\]]+)/u.exec(interpreter.stdout)?.[1] ?? null,
    requiredGlibcVersions: [...new Set(versions.stdout.match(/GLIBC_[0-9]+(?:\.[0-9]+)+/gu) ?? [])].sort(),
  };
  await writeFile(path.join(evidence, 'provider-ldd.txt'), dependencies.stdout + dependencies.stderr);
  await writeFile(path.join(evidence, 'provider-elf-program-headers.txt'), interpreter.stdout);
  await writeFile(path.join(evidence, 'provider-abi-versions.txt'), versions.stdout);
  await writeFile(path.join(evidence, 'installed-build-receipt.json'), savedReceipt);
  await writeFile(path.join(evidence, 'release.json'), JSON.stringify(release, null, 2) + '\n');
  passed = true;
} catch (error) {
  failure = { name: error.name, message: error.message };
  throw error;
} finally {
  const result = {
    schemaVersion: 1, kind: 'proofscript-installed-package-qualification',
    sourceRef: process.env.GITHUB_SHA, runId: process.env.GITHUB_RUN_ID,
    tarballSha256, tarballBytes, releaseIdentity, providerRuntime,
    nodeOnlyExecutionPath: true, nodeVersion: process.version,
    platform: process.platform, architecture: process.arch,
    runnerImage: process.env.ImageOS ?? null, runnerImageVersion: process.env.ImageVersion ?? null,
    observations, passed, ...(failure ? { failure } : {}),
    leanToolchainRequired: false, sourceCheckoutRequired: false,
    semanticPreservationProved: false, pscvVerified: false, strictSh1Qualified: false,
    selectedSeedChanged: false, npmPublished: false,
  };
  await writeFile(path.join(evidence, 'installed-package-qualification.json'), JSON.stringify(result, null, 2) + '\n');
  console.log('PSC0_INSTALLED_PACKAGE: ' + JSON.stringify(result));
  await rm(temporary, { recursive: true, force: true });
}
