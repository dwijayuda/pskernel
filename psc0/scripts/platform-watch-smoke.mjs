import assert from 'node:assert/strict';
import { spawn, spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { access, copyFile, mkdir, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { setTimeout as delay } from 'node:timers/promises';
import path from 'node:path';

// Installed-tarball smoke. No repository checkout, native build, compiler
// bootstrap, npm scripts, or external extension JavaScript entrypoints.
const [productTarball, psdevTarball, evidenceDirectory] = process.argv.slice(2).map(path.resolve);
assert(productTarball?.endsWith('.tgz') && psdevTarball?.endsWith('.tgz') &&
  evidenceDirectory, 'PSC_WATCH_SMOKE_ARGUMENTS');
assert(process.env.PSC0_SMOKE_NPM_CLI, 'PSC_WATCH_SMOKE_PINNED_NPM');

const digest = bytes => createHash('sha256').update(bytes).digest('hex');
const temp = await mkdtemp(path.join(tmpdir(), 'psc watch consumer spaces-'));
const project = path.join(temp, 'library project');
const observations = [];
const npmEnv = { ...process.env };
const runtimeEnv = { ...npmEnv, PATH: path.dirname(process.execPath) };
for (const name of [
  'PSC0_TSC', 'PSC0_TYPESCRIPT_VERSION', 'PSC_KERNEL_CORE_PROVIDER_BIN',
  'PSC_LEAN_KERNEL_PROVIDER_BIN', 'PSC0_TEST_KERNEL_CORE_PROVIDER_BIN',
  'LEAN_PATH', 'LEAN_SRC_PATH', 'ELAN_HOME', 'NODE_PATH', 'NODE_OPTIONS',
  'LD_LIBRARY_PATH', 'LD_PRELOAD', 'DYLD_LIBRARY_PATH', 'DYLD_INSERT_LIBRARIES',
]) delete runtimeEnv[name];
let watcher;
try {
  await mkdir(path.join(project, 'src'), { recursive: true });
  await mkdir(evidenceDirectory, { recursive: true });
  // Unpack only through npm; this fixture copies documented example data.
  const staging = path.join(temp, 'product staging');
  await mkdir(staging);
  const install = spawnSync(process.execPath,
    [process.env.PSC0_SMOKE_NPM_CLI, 'install', '--ignore-scripts', '--no-audit',
      '--no-fund', '--prefix', staging, productTarball], {
      encoding: 'utf8', timeout: 120000, maxBuffer: 5 * 1024 * 1024, env: npmEnv,
    });
  assert.equal(install.status, 0, install.stderr || install.stdout);
  const example = path.join(staging, 'node_modules/proofscript/examples/platform/checked-library');
  const files = ['README.md', 'package.json', 'tsconfig.json',
    'src/Quantity.ps', 'src/Main.ps', 'src/consumer.ts'];
  for (const file of files) {
    await mkdir(path.dirname(path.join(project, file)), { recursive: true });
    await copyFile(path.join(example, file), path.join(project, file));
  }
  const pkgFile = path.join(project, 'package.json');
  const pkg = JSON.parse(await readFile(pkgFile, 'utf8'));
  delete pkg.devDependencies.proofscript;
  delete pkg.devDependencies.psdev;
  pkg.proofscript.extensions = [{ package: 'psdev', enable: ['command:dev'] }];
  await writeFile(pkgFile, JSON.stringify(pkg, null, 2) + '\n');
  const installed = spawnSync(process.execPath,
    [process.env.PSC0_SMOKE_NPM_CLI, 'install', '--ignore-scripts', '--no-audit',
      '--no-fund', '--save-dev', '--save-exact', '--package-lock=true',
      productTarball, psdevTarball], {
      cwd: project, env: npmEnv, encoding: 'utf8', timeout: 120000,
      maxBuffer: 5 * 1024 * 1024,
    });
  assert.equal(installed.status, 0, installed.stderr || installed.stdout);
  const cli = path.join(project, 'node_modules/proofscript/bin/psc.mjs');
  await access(cli);
  const statuses = [];
  let stdout = '', stderr = '', closed;
  watcher = spawn(process.execPath, [cli, 'dev', '--watch', '--tsc', '--json'], {
    cwd: project, env: runtimeEnv, stdio: ['ignore', 'pipe', 'pipe'], windowsHide: true,
  });
  const stopped = new Promise(resolve => watcher.once('close', (code, signal) => {
    closed = { code, signal }; resolve();
  }));
  watcher.stdout.on('data', chunk => {
    stdout += chunk.toString('utf8');
    assert(Buffer.byteLength(stdout) < 1024 * 1024, 'PSC_WATCH_SMOKE_STDOUT_LIMIT');
    for (;;) {
      const pos = stdout.indexOf('\n');
      if (pos < 0) break;
      const row = stdout.slice(0, pos).trim(); stdout = stdout.slice(pos + 1);
      if (row) statuses.push(JSON.parse(row));
    }
  });
  watcher.stderr.on('data', chunk => {
    stderr += chunk.toString('utf8');
    assert(Buffer.byteLength(stderr) < 3 * 1024 * 1024, 'PSC_WATCH_SMOKE_STDERR_LIMIT');
  });
  async function waitFor(predicate, stage, timeout = 90000) {
    const start = Date.now();
    while (Date.now() - start < timeout) {
      const found = statuses.find(predicate);
      if (found) return found;
      assert(!closed, 'PSC_WATCH_SMOKE_EXIT_' + stage + ': ' + JSON.stringify(closed) + ' ' + stderr.slice(-1500));
      await delay(100);
    }
    assert.fail('PSC_WATCH_SMOKE_TIMEOUT_' + stage + ': ' + stderr.slice(-1500));
  }
  async function snapshotArtifacts() {
    const receiptFile = path.join(project, 'src/generated/library.checked.json');
    const receipt = JSON.parse(await readFile(receiptFile, 'utf8'));
    const values = new Map([['src/generated/library.checked.json', await readFile(receiptFile)]]);
    for (const artifact of receipt.artifacts) {
      const bytes = await readFile(path.join(project, artifact.name));
      assert.equal(digest(bytes), artifact.sha256);
      values.set(artifact.name, bytes);
    }
    return { receipt, values };
  }
  const ready1 = await waitFor(x => x.state === 'ready', 'INITIAL');
  assert.equal(ready1.downstream, 'typescript-passed');
  let accepted = await snapshotArtifacts();
  assert.equal(ready1.transactionId, accepted.receipt.transactionId);
  assert.equal(accepted.receipt.extensions[0].package, 'psdev');
  const initialConsumer = spawnSync(process.execPath, ['dist/consumer.js'], {
    cwd: project, env: runtimeEnv, encoding: 'utf8', timeout: 15000,
  });
  assert.equal(initialConsumer.status, 0, initialConsumer.stderr);
  assert.equal(initialConsumer.stdout.trim(), 'ProofScript library answer: 42');
  observations.push('initial checked generation and downstream TypeScript consumer');

  const source = path.join(project, 'src/Quantity.ps');
  const original = await readFile(source, 'utf8');
  const changed = original.replace('Quantity.mk(value)', 'Quantity.mk(Nat.succ(value))');
  assert.notEqual(changed, original);
  await writeFile(source, changed);
  const ready2 = await waitFor(x => x.state === 'ready' && x.generation > ready1.generation,
    'IMPORTED_EDIT');
  assert.notEqual(ready2.transactionId, ready1.transactionId);
  accepted = await snapshotArtifacts();
  const changedConsumer = spawnSync(process.execPath, [
    '--input-type=module', '--eval',
    "import { makeQuantity } from './dist/Quantity.js';" +
    "import { readQuantity } from './dist/Main.js';" +
    "if (readQuantity(makeQuantity(42n)) !== 43n) throw Error('bad watch value');",
  ], { cwd: project, env: runtimeEnv, encoding: 'utf8', timeout: 15000 });
  assert.equal(changedConsumer.status, 0, changedConsumer.stderr);
  observations.push('imported source change causes a distinct fully checked generation');

  const mainFile = path.join(project, 'src/Main.ps');
  const valid = await readFile(mainFile, 'utf8');
  const invalid = valid.replace('def readQuantity(value : Quantity) : Nat',
    'def readQuantity(value : Quantity) : Quantity');
  assert.notEqual(invalid, valid);
  await writeFile(mainFile, invalid);
  await waitFor(x => x.state === 'rejected' && x.generation > ready2.generation, 'INVALID_SOURCE');
  for (const [file, bytes] of accepted.values) {
    assert.deepEqual(await readFile(path.join(project, file)), bytes);
  }
  observations.push('invalid source retains all last-successful artifacts and receipt');

  await writeFile(mainFile, valid);
  const ready3 = await waitFor(x => x.state === 'ready' && x.generation > ready2.generation,
    'RECOVERY');
  assert.notEqual(ready3.transactionId, ready2.transactionId);
  accepted = await snapshotArtifacts();
  observations.push('valid recovery produces a new checked generation');

  const moduleFile = path.join(project, 'node_modules/psdev/command.wasm');
  await writeFile(moduleFile, Buffer.from('tampered command module'));
  await waitFor(x => x.state === 'rejected' && x.generation > ready3.generation,
    'TAMPERED_EXTENSION');
  for (const [file, bytes] of accepted.values) {
    assert.deepEqual(await readFile(path.join(project, file)), bytes);
  }
  observations.push('tampered extension is refused with previous outputs unchanged');

  assert(statuses.some(x => x.state === 'pending' && x.lastAcceptedGeneration));
  assert(statuses.every(x => x.kind === 'psc-dev-watch/1'));
  assert.match(stderr, /PSC_EXTENSIONS:/u);
  await writeFile(path.join(evidenceDirectory, 'watch-statuses.json'),
    JSON.stringify({ observations, statuses, extensionDisclosureObserved: true,
      productSha256: digest(await readFile(productTarball)),
      psdevSha256: digest(await readFile(psdevTarball)) }, null, 2) + '\n');
  console.log('PSC_WATCH_INSTALLED: PASS ' + JSON.stringify({ count: observations.length,
    statuses: statuses.length, platform: process.platform, node: process.versions.node }));
  watcher.kill('SIGTERM');
  await Promise.race([stopped, delay(7000).then(() => watcher.kill('SIGKILL'))]);
} finally {
  if (watcher && watcher.exitCode === null) {
    watcher.kill('SIGTERM');
    await delay(300);
    if (watcher.exitCode === null) watcher.kill('SIGKILL');
  }
  await rm(temp, { recursive: true, force: true });
}
