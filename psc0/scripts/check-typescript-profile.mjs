import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { existsSync, realpathSync, statSync } from 'node:fs';
import { mkdir, mkdtemp, readFile, writeFile } from 'node:fs/promises';
import { createRequire } from 'node:module';
import path from 'node:path';
import { performance } from 'node:perf_hooks';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { expectedTypeScriptVersion, resolveTypeScriptCli, typeScriptProfileArgs } from './typescript-cli.mjs';

const root = fileURLToPath(new URL('../', import.meta.url));
const options = {};
const args = process.argv.slice(2);
while (args.length) {
  const flag = args.shift();
  const key = { '--out': 'out', '--source': 'source', '--historical-tsc': 'historicalTsc' }[flag];
  const value = args.shift();
  if (!key || !value || value.startsWith('--') || Object.hasOwn(options, key)) {
    throw new Error('PSC0_TYPESCRIPT_PROFILE_ARGUMENT: ' + flag);
  }
  options[key] = value;
}
if (Boolean(options.source) !== Boolean(options.historicalTsc)) {
  throw new Error('PSC0_TYPESCRIPT_PROFILE_ARGUMENT: --source and --historical-tsc must be supplied together');
}
const directory = path.resolve(root, options.out ?? 'dist/typescript-profile');
await mkdir(directory, { recursive: true });
const reportPath = path.join(directory, 'report.json');
const report = {
  schemaVersion: 1,
  kind: 'psc0-typescript-profile-check',
  mode: options.source ? 'same-source-comparison' : 'installed-profile-contract',
  node: process.version,
  platform: process.platform,
  architecture: process.arch,
  startedAt: new Date().toISOString(),
  phases: [],
  passed: false,
};
const hash = value => createHash('sha256').update(value).digest('hex');
const errorRecord = error => ({ name: error.name, message: error.message, code: error.code ?? null });
async function saveReport() {
  await writeFile(reportPath, JSON.stringify(report, null, 2) + '\n');
}
async function phase(name, work) {
  const entry = { name, passed: false };
  report.phases.push(entry);
  try {
    const value = await work(entry);
    entry.passed = true;
    await saveReport();
    return { passed: true, value };
  } catch (error) {
    entry.error = errorRecord(error);
    await saveReport();
    return { passed: false };
  }
}
async function capture(label, command, commandArgs, { cwd = root, env = process.env, timeout = 120000 } = {}) {
  const started = performance.now();
  const result = spawnSync(command, commandArgs, {
    cwd, env, encoding: 'utf8', stdio: 'pipe', timeout, maxBuffer: 64 * 1024 * 1024, windowsHide: true,
  });
  const receipt = {
    command, args: commandArgs, cwd, timeoutMs: timeout, maxBufferBytes: 64 * 1024 * 1024,
    elapsedMs: performance.now() - started,
    status: result.status, signal: result.signal,
    error: result.error ? errorRecord(result.error) : null,
    diagnosticsComplete: !result.error && result.signal === null,
    stdout: path.join(directory, label + '.stdout.log'),
    stderr: path.join(directory, label + '.stderr.log'),
  };
  await writeFile(receipt.stdout, result.stdout ?? '');
  await writeFile(receipt.stderr, result.stderr ?? '');
  await writeFile(path.join(directory, label + '.command.json'), JSON.stringify(receipt, null, 2) + '\n');
  return receipt;
}
function requireSuccess(receipt) {
  assert.equal(receipt.error, null, 'compiler process must complete; retained command report has the error');
  assert.equal(receipt.status, 0, 'compiler must succeed; retained stdout/stderr contain complete available diagnostics');
}
const probeProgram = [
  "import assert from 'node:assert/strict';",
  "import { execFileSync } from 'node:child_process';",
  'import { expectedTypeScriptVersion, resolveTypeScriptCli, typeScriptProfileArgs } from ' +
    JSON.stringify(new URL('./typescript-cli.mjs', import.meta.url).href) + ';',
  'const version = expectedTypeScriptVersion();',
  'const cli = resolveTypeScriptCli();',
  "const actual = execFileSync(process.execPath, [cli, '--version'], { encoding: 'utf8', timeout: 10000 }).trim();",
  "assert.equal(actual, 'Version ' + version, 'PSC0_TYPESCRIPT_PROFILE_PIN');",
  "process.stdout.write(JSON.stringify({ cli, version, args: typeScriptProfileArgs(['input.ts'], version) }));",
].join('\n');
async function probe(label, env) {
  return capture(label, process.execPath, ['--input-type=module', '--eval', probeProgram], { env, timeout: 30000 });
}
async function packageForLauncher(cli) {
  let current = path.dirname(realpathSync(cli));
  for (;;) {
    const file = path.join(current, 'package.json');
    if (existsSync(file)) {
      const bytes = await readFile(file);
      return { directory: current, file, bytes, metadata: JSON.parse(bytes.toString('utf8')) };
    }
    const parent = path.dirname(current);
    if (parent === current) throw new Error('PSC0_TYPESCRIPT_PROFILE_PACKAGE: no owning package');
    current = parent;
  }
}
function compileArgs(input, version) {
  return typeScriptProfileArgs([
    input, '--target', 'ES2022', '--module', 'ES2022', '--moduleResolution', 'bundler',
    '--strict', '--declaration', '--sourceMap', '--noEmitOnError', '--skipLibCheck', '--pretty', 'false',
  ], version);
}
async function artifacts(outputDirectory) {
  const found = {};
  for (const name of ['index.ts', 'index.js', 'index.d.ts', 'index.js.map']) {
    const file = path.join(outputDirectory, name);
    if (existsSync(file)) {
      const bytes = await readFile(file);
      found[name] = { path: file, bytes: bytes.length, sha256: hash(bytes) };
    }
  }
  return found;
}
function requireArtifacts(found) {
  for (const name of ['index.ts', 'index.js', 'index.d.ts', 'index.js.map']) {
    assert(found[name]?.bytes > 0, 'missing or empty emitted artifact: ' + name);
  }
}

try {
  assert.equal(expectedTypeScriptVersion(), '7.0.2', 'this check runs in the current TS7 profile');
  if (options.source) {
    // Reuse the emitted compiler source. No PSC preparation or contract-fixture
    // rerun belongs in this comparison, and neither profile edits the input.
    const inputPath = path.resolve(root, options.source);
    const input = await readFile(inputPath);
    report.source = { path: inputPath, bytes: input.length, sha256: hash(input) };
    report.measurement = 'One sequential wall-clock observation per compiler, including its CLI launcher; no cross-version artifact equality';
    await saveReport();
    for (const profile of [
      { label: 'historical', version: '5.8.3', cli: options.historicalTsc },
      { label: 'current', version: '7.0.2', cli: process.env.PSC0_TSC },
    ]) {
      await phase('compile-' + profile.label, async entry => {
        const env = { ...process.env, PSC0_TYPESCRIPT_VERSION: profile.version };
        if (profile.cli !== undefined) env.PSC0_TSC = profile.cli;
        else delete env.PSC0_TSC;
        entry.version = profile.version;
        entry.versionCheck = await probe(profile.label + '-version', env);
        requireSuccess(entry.versionCheck);
        const selected = JSON.parse(await readFile(entry.versionCheck.stdout, 'utf8'));
        entry.cli = selected.cli;
        entry.outputDirectory = await mkdtemp(path.join(directory, profile.label + '-'));
        const copiedInput = path.join(entry.outputDirectory, 'index.ts');
        await writeFile(copiedInput, input);
        entry.sourceSha256 = hash(await readFile(copiedInput));
        assert.equal(entry.sourceSha256, report.source.sha256);
        entry.compile = await capture(profile.label + '-compile', process.execPath,
          [selected.cli, ...compileArgs(copiedInput, profile.version)],
          { cwd: entry.outputDirectory, env, timeout: 10 * 60 * 1000 });
        entry.artifacts = await artifacts(entry.outputDirectory);
        requireSuccess(entry.compile);
        requireArtifacts(entry.artifacts);
      });
    }
  } else {
    const installed = await phase('installed-current-profile', async entry => {
      const cli = resolveTypeScriptCli();
      entry.cli = cli;
      const owned = await packageForLauncher(cli);
      assert.equal(owned.metadata.name, 'typescript');
      assert.equal(owned.metadata.version, '7.0.2');
      assert.equal(typeof owned.metadata.bin?.tsc, 'string');
      assert.equal(realpathSync(path.resolve(owned.directory, owned.metadata.bin.tsc)), realpathSync(cli));
      const nativePackageName = '@typescript/typescript-' + process.platform + '-' + process.arch;
      assert.equal(owned.metadata.optionalDependencies?.[nativePackageName], '7.0.2');
      const nativeJson = createRequire(owned.file).resolve(nativePackageName + '/package.json');
      const nativeBytes = await readFile(nativeJson);
      const nativeMetadata = JSON.parse(nativeBytes.toString('utf8'));
      assert.equal(nativeMetadata.name, nativePackageName);
      assert.equal(nativeMetadata.version, '7.0.2');
      const nativeExecutable = path.join(path.dirname(nativeJson), 'lib', process.platform === 'win32' ? 'tsc.exe' : 'tsc');
      assert(statSync(nativeExecutable).isFile(), 'the selected native platform binary must actually be installed');
      entry.package = {
        path: owned.file, name: owned.metadata.name, version: owned.metadata.version,
        bin: owned.metadata.bin.tsc, sha256: hash(owned.bytes),
        launcherSha256: hash(await readFile(cli)),
      };
      entry.platformPackage = {
        path: nativeJson, name: nativeMetadata.name, version: nativeMetadata.version,
        sha256: hash(nativeBytes), executable: nativeExecutable,
        executableSha256: hash(await readFile(nativeExecutable)),
      };
      entry.versionCheck = await probe('current-version', { ...process.env, PSC0_TSC: cli, PSC0_TYPESCRIPT_VERSION: '7.0.2' });
      requireSuccess(entry.versionCheck);
      const selected = JSON.parse(await readFile(entry.versionCheck.stdout, 'utf8'));
      assert.deepEqual(selected.args, ['--ignoreConfig', 'input.ts']);
      assert.deepEqual(typeScriptProfileArgs(['input.ts'], '5.8.3'), ['input.ts']);
      return cli;
    });
    if (!installed.passed) throw new Error('PSC0_TYPESCRIPT_PROFILE_INSTALLATION_FAILED');
    const cli = installed.value;
    await phase('authoritative-profile-rejections', async entry => {
      const unrelated = path.join(directory, 'unowned-launcher.mjs');
      await writeFile(unrelated, 'throw new Error("unowned launcher must not run");\n');
      const cases = [
        { name: 'wrong-supported-pin', values: { PSC0_TYPESCRIPT_VERSION: '5.8.3' }, code: 'PSC0_TYPESCRIPT_PROFILE_PIN' },
        { name: 'unsupported-pin', values: { PSC0_TYPESCRIPT_VERSION: '7.0.1' }, code: 'PSC0_TYPESCRIPT_VERSION' },
        { name: 'empty-override', values: { PSC0_TSC: '' }, code: 'PSC0_TYPESCRIPT_CLI_OVERRIDE' },
        { name: 'relative-override', values: { PSC0_TSC: 'relative/tsc' }, code: 'PSC0_TYPESCRIPT_CLI_OVERRIDE' },
        { name: 'missing-override', values: { PSC0_TSC: path.join(directory, 'not-installed', 'tsc') }, code: 'PSC0_TYPESCRIPT_CLI_OVERRIDE' },
        { name: 'unowned-override', values: { PSC0_TSC: unrelated }, code: 'PSC0_TYPESCRIPT_CLI_OVERRIDE' },
      ];
      entry.cases = [];
      for (const item of cases) {
        const receipt = await probe(item.name, {
          ...process.env, PSC0_TSC: cli, PSC0_TYPESCRIPT_VERSION: '7.0.2', ...item.values,
        });
        const diagnostic = await readFile(receipt.stderr, 'utf8');
        const passed = receipt.error === null && typeof receipt.status === 'number' &&
          receipt.status !== 0 && diagnostic.includes(item.code);
        entry.cases.push({ name: item.name, expectedCode: item.code, passed, command: receipt });
      }
      assert(entry.cases.every(item => item.passed), 'every invalid explicit selection must fail without discovery fallback');
    });
    await phase('positional-source-with-unrelated-config', async entry => {
      const fixture = await mkdtemp(path.join(directory, 'positional-'));
      const configDirectory = path.join(fixture, 'unrelated-project');
      await mkdir(configDirectory);
      await writeFile(path.join(configDirectory, 'tsconfig.json'), JSON.stringify({
        compilerOptions: { noEmit: true, types: ['psc0-intentionally-missing-types'] },
        files: ['unrelated-missing-source.ts'],
      }));
      await writeFile(path.join(fixture, 'package.json'), '{"type":"module"}\n');
      const input = path.join(fixture, 'index.ts');
      await writeFile(input, 'export const answer: bigint = 42n;\n');
      entry.compile = await capture('positional-compile', process.execPath,
        [cli, ...compileArgs(input, '7.0.2')], { cwd: configDirectory });
      entry.artifacts = await artifacts(fixture);
      requireSuccess(entry.compile);
      requireArtifacts(entry.artifacts);
      const runtime = await import(pathToFileURL(path.join(fixture, 'index.js')).href);
      assert.equal(runtime.answer, 42n);
      entry.answer = '42';
    });
  }
  report.passed = report.phases.length > 0 && report.phases.every(entry => entry.passed);
  report.finishedAt = new Date().toISOString();
  await saveReport();
  if (!report.passed) throw new Error('PSC0_TYPESCRIPT_PROFILE_FAILED: see ' + reportPath);
  const timings = report.phases.filter(entry => entry.compile).map(entry => ({
    phase: entry.name, version: entry.version ?? '7.0.2', elapsedMs: entry.compile.elapsedMs,
  }));
  process.stdout.write('PSC0_TYPESCRIPT_PROFILE: PASS ' + JSON.stringify({
    mode: report.mode, report: reportPath, sourceSha256: report.source?.sha256, timings,
  }) + '\n');
} catch (error) {
  report.passed = false;
  report.error = errorRecord(error);
  report.finishedAt = new Date().toISOString();
  await saveReport();
  throw error;
}
