import { spawn } from 'node:child_process';
import path from 'node:path';
import { performance } from 'node:perf_hooks';

export const processLimits = Object.freeze({ inputBytes: 16 * 1024 * 1024,
  stdoutBytes: 16 * 1024 * 1024, stderrBytes: 1024 * 1024, wallTimeMs: 60000, terminationGraceMs: 2000 });

/** Host process execution only. Process exit success is untrusted data, never
 * a kernel decision. CPU, memory and descendants require a sandbox adapter.
 */
export async function runBoundedProcess({ binary, args = [], cwd, env = {}, input = Buffer.alloc(0),
  limits = {}, signal }) {
  const budget = { ...processLimits, ...limits };
  if (!path.isAbsolute(binary) || !path.isAbsolute(cwd) || !Array.isArray(args) || args.some(arg => typeof arg !== 'string') ||
      Object.values(budget).some(value => !Number.isSafeInteger(value) || value < 0) || budget.wallTimeMs > 2147483647 ||
      budget.terminationGraceMs > 2147483647 || !(input instanceof Uint8Array) ||
      Object.values(env).some(value => typeof value !== 'string')) throw new Error('PSC_PROCESS_CONFIGURATION');
  const start = performance.now();
  const observation = () => ({ hostObserved: true, wallTimeMs: Math.ceil(performance.now() - start),
    cpuTime: null, peakMemory: null, hostStack: null });
  const outcome = (kind, details) => ({ kind, ...details, authority: 'none', observation: observation() });
  if (input.byteLength > budget.inputBytes) return outcome('resourceExhausted',
    { resource: 'inputBytes', configured: budget.inputBytes, observed: input.byteLength });
  if (signal?.aborted) return outcome('resourceExhausted', { resource: 'cancelled' });
  return new Promise(resolve => {
    let child, settled = false, timer, terminationTimer, failure;
    const stdout = [], stderr = [];
    let outBytes = 0, errBytes = 0;
    function finish(result) {
      if (settled) return;
      settled = true; clearTimeout(timer); clearTimeout(terminationTimer);
      signal?.removeEventListener('abort', abort);
      resolve(outcome(result.kind, result));
    }
    function terminate(reason) {
      if (failure || settled) return;
      failure = reason;
      child?.kill('SIGKILL');
      terminationTimer = setTimeout(() => finish({ kind: 'infrastructureUnavailable',
        code: 'process-termination-unconfirmed', cause: reason }), budget.terminationGraceMs);
    }
    function abort() { terminate({ kind: 'resourceExhausted', resource: 'cancelled' }); }
    try { child = spawn(binary, args, { cwd, env: { ...env }, shell: false, windowsHide: true, stdio: ['pipe', 'pipe', 'pipe'] }); }
    catch (error) { finish({ kind: 'infrastructureUnavailable', code: error.code ?? 'spawn-failed' }); return; }
    child.once('error', error => finish({ kind: 'infrastructureUnavailable', code: error.code ?? 'spawn-failed' }));
    child.stdout.on('data', chunk => {
      if (settled || failure) return;
      outBytes += chunk.length;
      if (outBytes > budget.stdoutBytes) terminate({ kind: 'resourceExhausted', resource: 'stdoutBytes',
        configured: budget.stdoutBytes, observed: outBytes });
      else stdout.push(chunk);
    });
    child.stderr.on('data', chunk => {
      if (settled || failure) return;
      errBytes += chunk.length;
      if (errBytes > budget.stderrBytes) terminate({ kind: 'resourceExhausted', resource: 'stderrBytes',
        configured: budget.stderrBytes, observed: errBytes });
      else stderr.push(chunk);
    });
    child.stdin.on('error', error => {
      // EPIPE commonly precedes a normal nonzero exit; the close event owns its
      // classification. Other IO failures are infrastructure failures.
      if (error.code !== 'EPIPE') terminate({ kind: 'infrastructureUnavailable', code: error.code ?? 'stdin-failed' });
    });
    child.once('close', (code, exitSignal) => {
      if (failure) { finish(failure); return; }
      const data = { stdout: Buffer.concat(stdout), stderr: Buffer.concat(stderr), code, signal: exitSignal };
      finish(code === 0 ? { kind: 'accepted', value: data } : { kind: 'internalError', code: 'process-exit', process: data });
    });
    timer = setTimeout(() => terminate({ kind: 'resourceExhausted', resource: 'wallTime',
      configured: budget.wallTimeMs, observed: Math.ceil(performance.now() - start) }), budget.wallTimeMs);
    signal?.addEventListener('abort', abort, { once: true });
    if (signal?.aborted) abort();
    child.stdin.end(Buffer.from(input));
  });
}
