import { watch } from 'node:fs';
import { readFile, realpath, lstat } from 'node:fs/promises';
import { spawn } from 'node:child_process';
import { createHash } from 'node:crypto';
import path from 'node:path';

const digest = bytes => createHash('sha256').update(bytes).digest('hex');
const fail = code => { throw new Error(code); };
const inside = (root, file) => {
  const relative = path.relative(root, file);
  return relative !== '..' && !relative.startsWith('..' + path.sep) && !path.isAbsolute(relative);
};

// Events only trigger a new request. The checked compiler and publisher, not
// fs.watch, decide which source/extension bytes are admitted and published.
export function relevantWatchEvent(kind, filename, downstream = false) {
  if (filename === null || filename === undefined) return true; // unknown rename
  const name = String(filename).replace(/\\/gu, '/');
  if (kind === 'source') {
    if (name.split('/').some(part => part === '.git' || part === 'node_modules')) return false;
    return /\.(?:ps|lean)$/u.test(name);
  }
  if (kind === 'project') {
    return ['package.json', 'package-lock.json', ...(downstream ? ['tsconfig.json'] : [])].includes(name);
  }
  return ['package.json', 'proofscript-extension.json', 'command.wasm'].includes(name);
}

async function fingerprint(file) {
  try { return digest(await readFile(file)); }
  catch (error) { if (error?.code === 'ENOENT') return null; throw error; }
}
async function identity(projectRoot, downstream) {
  return {
    package: await fingerprint(path.join(projectRoot, 'package.json')),
    lock: await fingerprint(path.join(projectRoot, 'package-lock.json')),
    ...(downstream ? { tsconfig: await fingerprint(path.join(projectRoot, 'tsconfig.json')) } : {}),
  };
}
const equal = (a, b) => JSON.stringify(a) === JSON.stringify(b);

// This is freshness checking, not a replacement for the build's beforeCommit
// check. A successful child receipt is not evidence for a later saved edit.
export async function watchReceiptCurrent({ receipt, projectRoot, sourceDirectory, before, downstream = false }) {
  if (receipt?.kind !== 'psc0-checked-build' || receipt.kernelAdmissionAccepted !== true ||
      !receipt.targetValidation || !Array.isArray(receipt.artifacts) || receipt.artifacts.length === 0 ||
      !Array.isArray(receipt.sources) || receipt.sources.length === 0) return false;
  if (!equal(before, await identity(projectRoot, downstream))) return false;
  for (const item of receipt.sources) {
    if (typeof item?.path !== 'string' || !/^[a-f0-9]{64}$/u.test(item.sha256)) return false;
    const candidate = path.resolve(sourceDirectory, item.path);
    if (!inside(sourceDirectory, candidate)) return false;
    if (await fingerprint(candidate) !== item.sha256) return false;
  }
  return true;
}

// Only the supervisor supplies the executable/script paths. This launcher
// never invokes a shell or loads an npm extension's JavaScript entrypoint.
export async function runCheckedChild({ executable, args, cwd, signal, onStderr, wallTimeMs = 180000 }) {
  if (!Array.isArray(args) || args.some(item => typeof item !== 'string') ||
      typeof executable !== 'string' || typeof cwd !== 'string' ||
      !Number.isSafeInteger(wallTimeMs) || wallTimeMs < 1000 || wallTimeMs > 300000) {
    fail('PSC_DEV_WATCH_CHILD_ARGS');
  }
  signal?.throwIfAborted();
  return new Promise((resolve, reject) => {
    let child, timer, killer, output = '', errors = '', settled = false;
    const finish = (error, result) => {
      if (settled) return;
      settled = true;
      clearTimeout(timer); clearTimeout(killer);
      signal?.removeEventListener('abort', abort);
      if (error) reject(error); else resolve(result);
    };
    const terminate = () => {
      try { child?.kill('SIGTERM'); } catch {}
      if (!killer) killer = setTimeout(() => { try { child?.kill('SIGKILL'); } catch {} }, 15000);
    };
    const abort = () => terminate();
    if (signal?.aborted) { finish(new Error('PSC_DEV_WATCH_CANCELLED')); return; }
    signal?.addEventListener('abort', abort, { once: true });
    try {
      child = spawn(executable, args, { cwd, stdio: ['ignore', 'pipe', 'pipe'], windowsHide: true });
    } catch (error) { finish(error); return; }
    timer = setTimeout(terminate, wallTimeMs);
    child.stdout.on('data', data => {
      output += data.toString('utf8');
      if (Buffer.byteLength(output) > 8 * 1024 * 1024) terminate();
    });
    child.stderr.on('data', data => {
      errors += data.toString('utf8');
      if (Buffer.byteLength(errors) > 8 * 1024 * 1024) terminate();
      else onStderr?.(data.toString('utf8'));
    });
    child.on('error', error => finish(error));
    child.on('close', code => {
      if (signal?.aborted) return finish(new Error('PSC_DEV_WATCH_CANCELLED'));
      if (Buffer.byteLength(output) > 8 * 1024 * 1024 ||
          Buffer.byteLength(errors) > 8 * 1024 * 1024) {
        return finish(new Error('PSC_DEV_WATCH_OUTPUT_LIMIT'));
      }
      if (code !== 0) {
        const explanation = errors.trim().split(/\r?\n/u).slice(-4).join(' ').slice(-2000);
        return finish(new Error('PSC_DEV_WATCH_BUILD_FAILED: ' + explanation));
      }
      finish(undefined, output);
    });
  });
}

/**
 * T2 development scheduler. The only privileged operation is the supervisor-
 * supplied runBuild callback, which calls the same installed psc dev --once
 * authority path. This module never publishes output or accepts proof terms.
 */
export async function watchCheckedProject({
  projectRoot, entryPath, extensionRoot, configuredEntry, configuredExtension,
  signal, runBuild, runDownstream, onStatus, debounceMs = 160,
}) {
  if (typeof runBuild !== 'function' || typeof onStatus !== 'function' ||
      !Number.isSafeInteger(debounceMs) || debounceMs < 0 || debounceMs > 2000) {
    fail('PSC_DEV_WATCH_CONFIGURATION');
  }
  const root = path.resolve(projectRoot);
  const sourceDirectory = path.dirname(path.resolve(entryPath));
  if (!inside(root, sourceDirectory) || !path.resolve(entryPath).endsWith('.ps')) {
    fail('PSC_DEV_WATCH_SOURCE_PROFILE');
  }
  if (signal?.aborted) fail('PSC_DEV_WATCH_CANCELLED');
  const downstream = typeof runDownstream === 'function';
  const watchers = [];
  let generation = 0, timer, periodic, current, running = false, stopped = false;
  let lastAccepted, lastIdentity, stopError;
  let finish, rejectFinish;
  const completed = new Promise((resolve, reject) => { finish = resolve; rejectFinish = reject; });
  const update = (state, extra = {}) => {
    onStatus(Object.freeze({ kind: 'psc-dev-watch/1', generation, state,
      ...(lastAccepted ? { lastAcceptedGeneration: lastAccepted } : {}), ...extra }));
  };
  function stop(error) {
    if (stopped) return;
    stopped = true; stopError = error;
    clearTimeout(timer); clearInterval(periodic);
    signal?.removeEventListener('abort', onAbort);
    for (const watcher of watchers) watcher.close();
    current?.abort(new Error('PSC_DEV_WATCH_STOPPED'));
    if (!running) conclude();
  }
  function conclude() {
    update('stopped', stopError ? { error: stopError.message } : {});
    if (stopError) rejectFinish(stopError); else finish();
  }
  const onAbort = () => stop();
  signal?.addEventListener('abort', onAbort, { once: true });

  function request(reason) {
    if (stopped) return;
    generation++;
    update('pending', { reason });
    current?.abort(new Error('PSC_DEV_WATCH_SUPERSEDED'));
    clearTimeout(timer);
    timer = setTimeout(() => { timer = undefined; void build(); }, debounceMs);
  }
  async function build() {
    if (stopped || running) return;
    running = true;
    const selected = generation;
    const controller = new AbortController();
    current = controller;
    try {
      const before = await identity(root, downstream);
      if (stopped || selected !== generation) return;
      if (before.package === null) fail('PSC_DEV_WATCH_PROJECT_REMOVED');
      // Keep the initially selected source root and extension watcher honest.
      // Changing either requires an explicit watcher restart rather than
      // silently continuing to watch a stale source directory/package.
      let config;
      try { config = JSON.parse(await readFile(path.join(root, 'package.json'), 'utf8')).proofscript; }
      catch { fail('PSC_DEV_WATCH_PROJECT_CONFIGURATION'); }
      if ((configuredEntry !== undefined && config?.entry !== configuredEntry) ||
          (configuredExtension !== undefined &&
           config?.extensions?.[0]?.package !== configuredExtension)) {
        fail('PSC_DEV_WATCH_RESTART_REQUIRED');
      }
      update('checking');
      const receipt = await runBuild(controller.signal);
      if (stopped || selected !== generation) return;
      if (!await watchReceiptCurrent({
        receipt, projectRoot: root, sourceDirectory, before, downstream,
      })) { request('source-changed-after-build'); return; }
      update('checked', { transactionId: receipt.transactionId,
        sourceClosureSha256: receipt.sourceClosureSha256 });
      if (downstream) {
        const result = await runDownstream(controller.signal);
        if (stopped || selected !== generation) return;
        if (result !== undefined && result !== true) fail('PSC_DEV_WATCH_DOWNSTREAM_RESULT');
        if (!await watchReceiptCurrent({
          receipt, projectRoot: root, sourceDirectory, before, downstream,
        })) { request('source-changed-during-downstream'); return; }
      }
      if (stopped || selected !== generation) return;
      lastAccepted = selected; lastIdentity = { receipt, before };
      update('ready', { transactionId: receipt.transactionId,
        sourceClosureSha256: receipt.sourceClosureSha256,
        downstream: downstream ? 'typescript-passed' : 'not-requested' });
    } catch (error) {
      if (!stopped && selected === generation) {
        update('rejected', { error: String(error?.message ?? error).slice(0,2000),
          downstream: 'not-current' });
      }
    } finally {
      running = false;
      if (current === controller) current = undefined;
      if (stopped) conclude();
      else if (selected !== generation) {
        clearTimeout(timer);
        timer = setTimeout(() => { timer = undefined; void build(); }, debounceMs);
      }
    }
  }
  try {
    const rootInfo = await lstat(root);
    const sourceInfo = await lstat(sourceDirectory);
    if (!rootInfo.isDirectory() || rootInfo.isSymbolicLink() ||
        !sourceInfo.isDirectory() || sourceInfo.isSymbolicLink() ||
        !inside(await realpath(root), await realpath(sourceDirectory))) {
      fail('PSC_DEV_WATCH_DIRECTORY_LINK');
    }
    function attach(directory, kind, recursive) {
      const watcher = watch(directory, { recursive }, (event, filename) => {
        if (relevantWatchEvent(kind, filename, downstream)) request('filesystem-' + kind);
      });
      watcher.on('error', error => stop(new Error('PSC_DEV_WATCH_FILESYSTEM: ' + error.message)));
      watchers.push(watcher);
    }
    attach(sourceDirectory, 'source', true);
    attach(root, 'project', false);
    if (extensionRoot) {
      const extensionInfo = await lstat(extensionRoot);
      if (!extensionInfo.isDirectory() || extensionInfo.isSymbolicLink() ||
          !inside(await realpath(root), await realpath(extensionRoot))) {
        fail('PSC_DEV_WATCH_EXTENSION_ROOT');
      }
      attach(extensionRoot, 'extension', false);
    }
    // A periodic freshness check reduces reliance on a platform's watcher
    // delivery for already accepted inputs. Unseen new imports still require
    // an event; this is not a guarantee of instantaneous filesystem knowledge.
    periodic = setInterval(() => {
      if (running || stopped || !lastIdentity || generation !== lastAccepted) return;
      void watchReceiptCurrent({
        receipt: lastIdentity.receipt, projectRoot: root, sourceDirectory,
        before: lastIdentity.before, downstream,
      }).then(fresh => { if (!fresh && !stopped && !running &&
          generation === lastAccepted) request('periodic-freshness'); },
        error => stop(new Error('PSC_DEV_WATCH_FRESHNESS: ' + error.message)));
    }, 1500);
    request('initial');
    return await completed;
  } catch (error) {
    stop(error);
    return await completed;
  }
}
