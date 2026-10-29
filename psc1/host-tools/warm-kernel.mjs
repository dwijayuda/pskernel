// Private host capability. Source/project/wire data cannot select a worker or checker.
import { Worker } from 'node:worker_threads';
import path from 'node:path';
import fs from 'node:fs';
import crypto from 'node:crypto';
import { loadDistribution, resolveKernel } from './installed-engine-resolver.mjs';
let current,
  starting,
  sequence = 0;
const hash = (b) => crypto.createHash('sha256').update(b).digest('hex');
const fail = (code) => {
  throw Error('PSC1_WARM_KERNEL_' + code);
};
async function startWarmKernel() {
  if (process.platform !== 'linux' || process.versions.bun) return;
  if (current && !current.dead) return;
  const selected = resolveKernel('wasm', loadDistribution());
  const launcher = selected.pins.filter((p) => p.path.endsWith('/wasm/pskernel-lean.cjs')),
    wasm = selected.pins.filter((p) => p.path.endsWith('/wasm/pskernel-lean.wasm'));
  if (launcher.length !== 1 || wasm.length !== 1) fail('PIN');
  const verify = () => {
    for (const pin of selected.pins) {
      const stat = fs.lstatSync(pin.path);
      if (!stat.isFile() || stat.isSymbolicLink() || hash(fs.readFileSync(pin.path)) !== pin.sha256)
        fail('RESOURCE_CHANGED');
    }
  };
  verify();
  const worker = new Worker(new URL('./warm-kernel-worker.mjs', import.meta.url), {
    workerData: { launcher: launcher[0], wasm: wasm[0] },
    resourceLimits: { maxOldGenerationSizeMb: 4096, stackSizeMb: 8 },
  });
  const handle = { worker, dead: false };
  worker.on('error', () => {
    handle.dead = true;
  });
  worker.on('exit', () => {
    handle.dead = true;
  });
  try {
    await new Promise((resolve, reject) => {
      const timeout = setTimeout(() => reject(Error('PSC1_WARM_KERNEL_START_TIMEOUT')), 120000);
      const complete = (error, packet) => {
        clearTimeout(timeout);
        worker.off('error', onError);
        worker.off('exit', onExit);
        if (error) reject(error);
        else resolve(packet);
      };
      const onError = (error) => complete(error),
        onExit = () => complete(Error('PSC1_WARM_KERNEL_EARLY_EXIT'));
      worker.once('error', onError);
      worker.once('exit', onExit);
      worker.once('message', (packet) => {
        if (
          packet?.status !== 'ready' ||
          packet.launcherSha256 !== launcher[0].sha256 ||
          packet.wasmSha256 !== wasm[0].sha256
        )
          complete(Error('PSC1_WARM_KERNEL_START_IDENTITY'));
        else complete(undefined, packet);
      });
    });
    verify();
    current = handle;
    worker.unref();
  } catch (error) {
    handle.dead = true;
    await worker.terminate();
    throw error;
  }
}
export async function prepareWarmKernel() {
  if (current && !current.dead) return;
  if (!starting) starting = startWarmKernel();
  const pending = starting;
  try {
    await pending;
  } finally {
    if (starting === pending) starting = undefined;
  }
}
export function warmKernel() {
  if (!current || current.dead) return;
  const handle = current;
  return (source) => {
    if (
      current !== handle ||
      handle.dead ||
      typeof source !== 'string' ||
      Buffer.byteLength(source) > 134217728
    )
      fail('REQUEST');
    const control = new SharedArrayBuffer(8),
      state = new Int32Array(control),
      output = new SharedArrayBuffer(33554432),
      id = ++sequence;
    handle.worker.postMessage({ id, source, control, output });
    const deadline = performance.now() + 120000;
    while (Atomics.load(state, 0) === 0) {
      const left = deadline - performance.now();
      if (left <= 0) {
        handle.dead = true;
        handle.worker.terminate();
        fail('TIMEOUT');
      }
      Atomics.wait(state, 0, 0, left);
    }
    const length = Atomics.load(state, 1);
    if (length <= 0 || length > 33554432) fail('RESPONSE_LIMIT');
    const text = Buffer.from(new Uint8Array(output, 0, length)).toString('utf8');
    if (Atomics.load(state, 0) !== 1) fail('EXECUTION:' + text.slice(0, 8192));
    let packet;
    try {
      packet = JSON.parse(text);
    } catch {
      fail('JSON');
    }
    if (packet.id !== id || packet.admissionsSha256 !== hash(source)) fail('RESPONSE_IDENTITY');
    return packet.result;
  };
}
export async function closeWarmKernel() {
  const handle = current;
  current = undefined;
  if (handle) {
    handle.dead = true;
    await handle.worker.terminate();
  }
}
