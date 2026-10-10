// One disposable process per checked build. No arbitrary guest or shell.
// Time limits interrupt CPU-bound compiler JS; V8 heap is not total RSS.
import { spawn } from 'node:child_process';
import { performance } from 'node:perf_hooks';
import { fileURLToPath } from 'node:url';
import { FRONTEND_PROTOCOL as protocol, MAX_FRAME_BYTES, receiveFrames, sendFrame } from './frontend-wire.mjs';
export const defaultFrontendLimits = Object.freeze({ timeoutMs: 300000, heapMb: 4096 });
export function frontendLimits(input = {}) {
  for (const key of Object.keys(input)) if (!Object.hasOwn(defaultFrontendLimits, key)) throw new Error('PSC_FRONTEND_UNKNOWN_LIMIT: ' + key);
  const limits = { ...defaultFrontendLimits, ...input };
  if (!Number.isSafeInteger(limits.timeoutMs) || limits.timeoutMs < 1 || limits.timeoutMs > 86400000 || !Number.isSafeInteger(limits.heapMb) || limits.heapMb < 128 || limits.heapMb > 32768) throw new Error('PSC_FRONTEND_INVALID_LIMIT');
  return Object.freeze(limits);
}
export function createFrontendTransport({ script, limits: options, onAdmissions, signal, maxFrameBytes = MAX_FRAME_BYTES, maxDiagnosticsBytes = 65536 }) {
  const limits = frontendLimits(options);
  if (!Number.isSafeInteger(maxFrameBytes) || maxFrameBytes < 1 || maxFrameBytes > MAX_FRAME_BYTES || !Number.isSafeInteger(maxDiagnosticsBytes) || maxDiagnosticsBytes < 1 || maxDiagnosticsBytes > 65536) throw new Error('PSC_FRONTEND_INVALID_WIRE_LIMIT');
  if (signal?.aborted) throw new Error('PSC_FRONTEND_CANCELLED');
  const environment = { ...process.env };
  // Never inherit Node preload hooks, search-path injection or caller heap flags.
  // The installation and this process are trusted; this is not an OS sandbox.
  for (const key of Object.keys(environment)) if (['NODE_OPTIONS', 'NODE_PATH', 'NODE_V8_COVERAGE'].includes(key.toUpperCase())) delete environment[key];
  const worker = spawn(process.execPath, ['--max-old-space-size=' + limits.heapMb, fileURLToPath(script)], { stdio: ['pipe', 'pipe', 'pipe'], env: environment, windowsHide: true, shell: false });
  let pending, failure, sequence = 0, elapsedMs = 0, diagnostics = 0;
  let finishClosed;
  const closed = new Promise(resolve => { finishClosed = resolve; });
  function fail(error) {
    if (failure) return;
    failure = error instanceof Error ? error : new Error(String(error));
    if (pending) { clearTimeout(pending.timer); pending.reject(failure); pending = undefined; }
    worker.stdin.destroy();
    worker.kill('SIGKILL');
  }
  function send(value) { if (!failure) sendFrame(worker.stdin, value, fail, maxFrameBytes); }
  worker.on('error', fail);
  worker.stdin.on('error', fail);
  worker.once('close', (code, sig) => {
    fail(new Error('PSC_FRONTEND_EXIT: ' + (sig || code)));
    process.removeListener('exit', onParentExit);
    signal?.removeEventListener('abort', onAbort);
    finishClosed();
  });
  worker.stderr.on('data', chunk => {
    diagnostics += chunk.length;
    if (diagnostics > maxDiagnosticsBytes) fail(new Error('PSC_FRONTEND_DIAGNOSTIC_LIMIT'));
  });
  worker.stderr.on('error', fail);
  const onParentExit = () => worker.kill('SIGKILL');
  const onAbort = () => fail(new Error('PSC_FRONTEND_CANCELLED'));
  process.once('exit', onParentExit);
  signal?.addEventListener('abort', onAbort, { once: true });
  if (signal?.aborted) onAbort();
  receiveFrames(worker.stdout, frame => {
    if (failure) return;
    const call = pending;
    if (!call || frame.protocol !== protocol || frame.id !== call.id) return fail(new Error('PSC_FRONTEND_RESPONSE_IDENTITY'));
    if (performance.now() - call.started + elapsedMs >= limits.timeoutMs) return fail(new Error('PSC_FRONTEND_TIME_LIMIT'));
    if (frame.kind === 'admissions') {
      if (call.op !== 'check' || call.sawAdmissions || typeof frame.value !== 'string' || Buffer.byteLength(frame.value) > 16 * 1024 * 1024 || typeof onAdmissions !== 'function') return fail(new Error('PSC_FRONTEND_ADMISSION_PROTOCOL'));
      call.sawAdmissions = true; call.awaitingKernel = true;
      Promise.resolve().then(() => onAdmissions(frame.value)).then(result => {
        if (failure || pending !== call) return;
        call.awaitingKernel = false;
        send({ protocol, id: call.id, op: 'kernel-result', data: result });
      }, fail);
      return;
    }
    if (call.awaitingKernel || !['result', 'error'].includes(frame.kind)) return fail(new Error('PSC_FRONTEND_RESPONSE_ORDER'));
    if (frame.kind === 'error') return fail(new Error('PSC_FRONTEND_DECLINED: ' + (typeof frame.message === 'string' ? frame.message.slice(0, 2000) : 'invalid error')));
    if (call.op === 'check' && !call.sawAdmissions) return fail(new Error('PSC_FRONTEND_UNCHECKED_RESULT'));
    elapsedMs += performance.now() - call.started;
    clearTimeout(call.timer); pending = undefined;
    call.resolve(frame.value);
  }, fail, maxFrameBytes);
  return Object.freeze({
    request(op, data = {}) {
      if (failure) return Promise.reject(failure);
      if (pending) return Promise.reject(new Error('PSC_FRONTEND_CONCURRENT_REQUEST'));
      if (++sequence > 4096) { fail(new Error('PSC_FRONTEND_REQUEST_LIMIT')); return Promise.reject(failure); }
      if (elapsedMs >= limits.timeoutMs) { fail(new Error('PSC_FRONTEND_TIME_LIMIT')); return Promise.reject(failure); }
      return new Promise((resolve, reject) => {
        const call = { id: sequence, op, resolve, reject, started: performance.now(), awaitingKernel: false, sawAdmissions: false };
        call.timer = setTimeout(() => fail(new Error('PSC_FRONTEND_TIME_LIMIT')), Math.max(1, limits.timeoutMs - elapsedMs));
        pending = call; send({ protocol, id: call.id, op, data });
      });
    },
    assertAlive() { if (failure) throw failure; },
    stats() { return Object.freeze({ protocol, childPid: worker.pid, requestCount: sequence, elapsedRequestMs: Math.ceil(elapsedMs), limits }); },
    async close() { fail(new Error('PSC_FRONTEND_CLOSED')); await closed; },
  });
}
