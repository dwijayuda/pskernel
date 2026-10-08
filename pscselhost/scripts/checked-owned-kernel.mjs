import { Worker } from 'node:worker_threads';
import { ownedCheckedIdentity } from './checked-kernel-identity.mjs';

// Host transport and resource limits only. All semantic transitions run the
// generated owned kernel in a disposable worker with a fresh environment.
export async function checkOwnedAdmissions(admissions, { timeoutMs = 60000, maxSteps = 2000000, maxMemoryMb = 512 } = {}) {
  if (typeof admissions !== 'string') throw new TypeError('Expected canonical admissions text');
  if (!Number.isSafeInteger(timeoutMs) || timeoutMs <= 0 || timeoutMs > 1200000 ||
      !Number.isSafeInteger(maxSteps) || maxSteps < 0 || maxSteps > 100000000 ||
      !Number.isSafeInteger(maxMemoryMb) || maxMemoryMb < 16 || maxMemoryMb > 512) {
    throw new TypeError('Invalid owned kernel resource limit');
  }
  const result = extra => Object.freeze({ ...ownedCheckedIdentity, ...extra });
  if (Buffer.byteLength(admissions, 'utf8') > 32 * 1024 * 1024) {
    return result({ accepted: false, errorKind: 'input-limit' });
  }
  return new Promise((resolve, reject) => {
    const worker = new Worker(new URL('./checked-owned-kernel-worker.mjs', import.meta.url), {
      workerData: { admissions, maxSteps }, resourceLimits: { maxOldGenerationSizeMb: maxMemoryMb },
    });
    let settled = false;
    const finish = (value, error) => {
      if (settled) return;
      settled = true; clearTimeout(timer); void worker.terminate().catch(() => {});
      if (error) reject(error); else resolve(result(value));
    };
    const timer = setTimeout(() => finish({ accepted: false, errorKind: 'timeout' }), timeoutMs);
    worker.once('message', value => {
      if (!value || typeof value.accepted !== 'boolean') finish(null, new Error('PSC2_OWNED_WORKER_RESULT'));
      else finish(value);
    });
    worker.on('error', error => {
      if (error?.code === 'ERR_WORKER_OUT_OF_MEMORY') finish({ accepted: false, errorKind: 'memory-limit' });
      else finish(null, error);
    });
    worker.once('exit', code => { if (!settled) finish(null, new Error(`PSC2_OWNED_WORKER_EXIT: ${code}`)); });
  });
}
