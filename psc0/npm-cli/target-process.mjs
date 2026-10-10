// Launch the selected native target directly: no shell, JS launcher, PATH
// lookup or inherited preload options. Resource control, not a hostile OS sandbox.
import { spawn } from 'node:child_process';
import path from 'node:path';
export function targetEnvironment(source = process.env) {
  const allowed = new Map([['systemroot', 'SystemRoot'], ['windir', 'WINDIR'], ['temp', 'TEMP'], ['tmp', 'TMP'], ['tmpdir', 'TMPDIR']]);
  const result = { LANG: 'C.UTF-8', LC_ALL: 'C.UTF-8' };
  for (const [key, value] of Object.entries(source).sort(([a], [b]) => a < b ? -1 : a > b ? 1 : 0)) {
    const name = allowed.get(key.toLowerCase());
    if (name && !Object.hasOwn(result, name) && typeof value === 'string') result[name] = value;
  }
  return Object.freeze(result);
}
export async function runTargetProcess(executable, args, { cwd, signal, timeoutMs = 180000, maxBytes = 1024 * 1024, environment = targetEnvironment() } = {}) {
  if (!path.isAbsolute(executable) || /\.(cmd|bat)$/iu.test(executable) || !Array.isArray(args) || args.some(a => typeof a !== 'string')) throw new Error('PSC_TARGET_PROCESS_ARGUMENTS');
  if (!Number.isSafeInteger(timeoutMs) || timeoutMs < 1 || timeoutMs > 180000 || !Number.isSafeInteger(maxBytes) || maxBytes < 1 || maxBytes > 16 * 1024 * 1024) throw new Error('PSC_TARGET_PROCESS_BUDGET');
  signal?.throwIfAborted();
  return new Promise((resolve, reject) => {
    const child = spawn(executable, args, { cwd, env: environment, shell: false, windowsHide: true, stdio: ['ignore', 'pipe', 'pipe'] });
    let failure, bytes = 0;
    const stdout = [], stderr = [];
    function fail(error) {
      failure ??= error;
      child.kill('SIGKILL');
    }
    const timer = setTimeout(() => fail(new Error('PSC_TARGET_TIME_LIMIT')), timeoutMs);
    const abort = () => fail(new Error('PSC_TARGET_ABORTED'));
    signal?.addEventListener('abort', abort, { once: true });
    if (signal?.aborted) abort();
    const accept = chunks => data => {
      bytes += data.length;
      if (bytes > maxBytes) fail(new Error('PSC_TARGET_DIAGNOSTIC_LIMIT'));
      else if (!failure) chunks.push(data);
    };
    child.stdout.on('data', accept(stdout));
    child.stderr.on('data', accept(stderr));
    child.once('error', error => { failure ??= new Error('PSC_TARGET_PROCESS_FAILED: ' + error.code); });
    child.once('close', (code, terminatingSignal) => {
      clearTimeout(timer);
      signal?.removeEventListener('abort', abort);
      if (!failure && (code !== 0 || terminatingSignal)) failure = new Error('PSC_TSC_FAILED: ' + Buffer.concat(stderr.length ? stderr : stdout).toString('utf8').slice(0, 4000));
      if (failure) reject(failure);
      else resolve(Object.freeze({ stdout: Buffer.concat(stdout).toString('utf8'), stderr: Buffer.concat(stderr).toString('utf8'), childPid: child.pid, closed: true }));
    });
  });
}
