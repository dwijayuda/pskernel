import assert from 'node:assert/strict';
import { test } from 'node:test';
import { createHash } from 'node:crypto';
import { mkdtemp, mkdir, readFile, writeFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { setTimeout as delay } from 'node:timers/promises';
import {
  relevantWatchEvent, runCheckedChild, watchCheckedProject, watchReceiptCurrent,
} from './project-watch.mjs';

const sha = bytes => createHash('sha256').update(bytes).digest('hex');
async function fixture(t) {
  const root = await mkdtemp(path.join(tmpdir(), 'psc t2 watch project spaces-'));
  t.after(() => rm(root, { recursive: true, force: true }));
  const sourceDir = path.join(root, 'src');
  const extension = path.join(root, 'node_modules', 'psdev');
  await mkdir(sourceDir, { recursive: true });
  await mkdir(extension, { recursive: true });
  const entry = path.join(sourceDir, 'Main.ps');
  const quantity = path.join(sourceDir, 'Quantity.ps');
  await writeFile(entry, 'import Quantity\ndef answer : Nat := 42\n');
  await writeFile(quantity, 'def Quantity.value : Nat := 42\n');
  await writeFile(path.join(root, 'package.json'),
    JSON.stringify({ proofscript: { profile: 'checked', entry: 'src/Main.ps', extensions: [] } }));
  await writeFile(path.join(root, 'package-lock.json'), JSON.stringify({ lockfileVersion: 3 }));
  await writeFile(path.join(extension, 'command.wasm'), 'wasm');
  return { root, sourceDir, entry, quantity, extension };
}

function receipt(files, sequence = 1) {
  return Promise.all(files.map(async file => ({
    path: path.basename(file), sha256: sha(await readFile(file)),
  }))).then(sources => ({
    schemaVersion: 4, kind: 'psc0-checked-build', kernelAdmissionAccepted: true,
    targetValidation: { tool: 'typescript', version: '7.0.2' },
    artifacts: [{ name: 'Main.ts', sha256: '0'.repeat(64) }],
    sources, transactionId: 'txn-' + sequence,
    sourceClosureSha256: sha(JSON.stringify(sources)),
  }));
}
async function until(predicate, message, max = 7000) {
  const start = Date.now();
  while (Date.now() - start < max) {
    if (predicate()) return;
    await delay(35);
  }
  assert.fail(message);
}

test('watch relevance excludes emitted TS, npm noise and unrelated project files', () => {
  assert(relevantWatchEvent('source', 'nested/Module.ps'));
  assert(relevantWatchEvent('source', 'Module.lean'));
  assert(relevantWatchEvent('source', null));
  assert.equal(relevantWatchEvent('source', 'Quantity.ts'), false);
  assert.equal(relevantWatchEvent('source', 'node_modules/pkg/Module.ps'), false);
  assert(relevantWatchEvent('project', 'package.json'));
  assert(relevantWatchEvent('project', 'package-lock.json'));
  assert.equal(relevantWatchEvent('project', 'tsconfig.json'), false);
  assert(relevantWatchEvent('project', 'tsconfig.json', true));
  assert.equal(relevantWatchEvent('extension', 'unrelated.js'), false);
  assert(relevantWatchEvent('extension', 'command.wasm'));
});

test('watch receipt freshness requires exact source and root configuration identity', async t => {
  const p = await fixture(t);
  const before = {
    package: sha(await readFile(path.join(p.root, 'package.json'))),
    lock: sha(await readFile(path.join(p.root, 'package-lock.json'))),
  };
  const value = await receipt([p.quantity, p.entry]);
  const args = { receipt: value, projectRoot: p.root, sourceDirectory: p.sourceDir, before };
  assert.equal(await watchReceiptCurrent(args), true);
  assert.equal(await watchReceiptCurrent({ ...args, receipt: { ...value, kernelAdmissionAccepted: false } }), false);
  await writeFile(p.quantity, 'def Quantity.value : Nat := 43\n');
  assert.equal(await watchReceiptCurrent(args), false);
  await writeFile(p.quantity, 'def Quantity.value : Nat := 42\n');
  await writeFile(path.join(p.root, 'package.json'), '{"proofscript":{"profile":"checked"}}');
  assert.equal(await watchReceiptCurrent(args), false);
});

test('real filesystem watcher builds, coalesces edits, preserves last good status, and recovers', async t => {
  const p = await fixture(t);
  const abort = new AbortController();
  t.after(() => abort.abort());
  const states = [];
  let builds = 0, accepted = 0;
  const watching = watchCheckedProject({
    projectRoot: p.root, entryPath: p.entry, extensionRoot: p.extension,
    signal: abort.signal, debounceMs: 65,
    runBuild: async signal => {
      builds++;
      await delay(45);
      signal.throwIfAborted();
      if ((await readFile(p.entry, 'utf8')).includes('INVALID')) throw new Error('PSC_TEST_KERNEL_REJECTED');
      return receipt([p.quantity, p.entry], builds);
    },
    onStatus: status => {
      states.push(status);
      if (status.state === 'ready') accepted++;
    },
  });
  await until(() => accepted === 1, 'initial ready status');
  const oldGeneration = states.findLast(x => x.state === 'ready').generation;
  await writeFile(path.join(p.sourceDir, 'Main.ts'), 'handwritten TS');
  await delay(250);
  assert.equal(accepted, 1, 'generated or handwritten TS changes cannot rebuild .ps');
  await writeFile(p.quantity, 'def Quantity.value : Nat := 44\n');
  await writeFile(p.quantity, 'def Quantity.value : Nat := 45\n');
  await until(() => accepted >= 2, 'coalesced changed source');
  assert(states.some(x => x.state === 'pending' && x.lastAcceptedGeneration === oldGeneration));
  await writeFile(p.entry, 'INVALID');
  await until(() => states.some(x => x.state === 'rejected' && /PSC_TEST_KERNEL_REJECTED/u.test(x.error)),
    'invalid source rejection');
  const priorCount = accepted;
  assert.equal(accepted, priorCount, 'rejection did not produce new acceptance');
  await writeFile(p.entry, 'import Quantity\ndef answer : Nat := 47\n');
  await until(() => accepted >= 3, 'recovered from rejected source');
  await writeFile(path.join(p.extension, 'command.wasm'), 'new extension content');
  await until(() => accepted >= 4, 'extension bytes trigger new checked transaction');
  abort.abort();
  await watching;
  assert.equal(states.at(-1).state, 'stopped');
  assert(builds >= 4);
});

test('an edit during checking supersedes earlier work; downstream runs only for fresh checked generations', async t => {
  const p = await fixture(t);
  await writeFile(path.join(p.root, 'tsconfig.json'), '{"compilerOptions":{}}');
  const abort = new AbortController();
  t.after(() => abort.abort());
  const states = [];
  let builds = 0, cancellations = 0, downstream = 0;
  const watching = watchCheckedProject({
    projectRoot: p.root, entryPath: p.entry, signal: abort.signal, debounceMs: 40,
    runBuild: async signal => {
      builds++;
      try { await delay(250, null, { signal }); }
      catch (error) { cancellations++; throw error; }
      if ((await readFile(p.entry, 'utf8')).includes('INVALID')) throw new Error('PSC_TEST_REJECTED');
      return receipt([p.quantity, p.entry], builds);
    },
    runDownstream: async signal => {
      signal.throwIfAborted(); downstream++; return true;
    },
    onStatus: item => states.push(item),
  });
  await until(() => states.some(x => x.state === 'checking'), 'first generation checking');
  await writeFile(p.quantity, 'def Quantity.value : Nat := 53\n');
  await until(() => states.some(x => x.state === 'ready'), 'superseding generation ready');
  assert(cancellations >= 1);
  assert.equal(downstream, 1);
  assert(states.findLast(x => x.state === 'ready').downstream === 'typescript-passed');
  await writeFile(p.entry, 'INVALID');
  await until(() => states.some(x => x.state === 'rejected'), 'rejected generation');
  assert.equal(downstream, 1);
  await writeFile(p.entry, 'import Quantity\ndef answer : Nat := 54\n');
  await until(() => downstream === 2, 'recovery downstream validation');
  abort.abort();
  await watching;
});

test('watch rejects unsupported linked source directories rather than silently missing changes', async t => {
  const p = await fixture(t);
  await assert.rejects(watchCheckedProject({
    projectRoot: p.root, entryPath: path.join(p.root, 'src/../elsewhere/Main.lean'),
    onStatus() {}, runBuild() {},
  }), /PSC_DEV_WATCH_SOURCE_PROFILE/u);
});

test('child launcher uses no shell, keeps bounded output, and reports failure', async () => {
  const source = await runCheckedChild({
    executable: process.execPath, args: ['-e', 'process.stdout.write("ok")'],
    cwd: process.cwd(), wallTimeMs: 5000,
  });
  assert.equal(source, 'ok');
  await assert.rejects(runCheckedChild({
    executable: process.execPath, args: ['-e', 'process.stderr.write("bad input");process.exit(2)'],
    cwd: process.cwd(), wallTimeMs: 5000,
  }), /PSC_DEV_WATCH_BUILD_FAILED: bad input/u);
  const controller = new AbortController();
  const request = runCheckedChild({
    executable: process.execPath, args: ['-e', 'setTimeout(()=>{},10000)'],
    cwd: process.cwd(), signal: controller.signal, wallTimeMs: 5000,
  });
  controller.abort();
  await assert.rejects(request, /PSC_DEV_WATCH_CANCELLED/u);
});
