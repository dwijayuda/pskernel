// Execute exact pinned official Emscripten code. VM isolates request state; it is not a sandbox.
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import crypto from 'node:crypto';
import { createRequire } from 'node:module';
import { parentPort, workerData } from 'node:worker_threads';
const digest = (b) => crypto.createHash('sha256').update(b).digest('hex');
function read(pin) {
  const stat = fs.lstatSync(pin.path);
  if (!stat.isFile() || stat.isSymbolicLink() || stat.size <= 0 || stat.size > 33554432)
    throw Error('PSC1_WARM_KERNEL_RESOURCE');
  const bytes = fs.readFileSync(pin.path);
  if (digest(bytes) !== pin.sha256) throw Error('PSC1_WARM_KERNEL_IDENTITY');
  return bytes;
}
const launcher = read(workerData.launcher),
  binary = read(workerData.wasm),
  compiled = new WebAssembly.Module(binary);
const script = new vm.Script(launcher.toString('utf8'), { filename: workerData.launcher.path });
async function execute(source) {
  const input = Buffer.from(source),
    out = [],
    err = [];
  let cursor = 0;
  const append = (target, byte) => {
    if (byte !== null) {
      if (target.length >= 33554432) throw Error('PSC1_WARM_KERNEL_OUTPUT_LIMIT');
      target.push(byte);
    }
  };
  const processView = Object.assign(Object.create(process), {
    argv: [process.execPath, workerData.launcher.path, '--check'],
    env: { ...process.env },
  });
  Object.defineProperty(processView, 'exitCode', { value: 0, writable: true, configurable: true });
  const Module = {
    arguments: ['--check'],
    stdin: () => (cursor < input.length ? input[cursor++] : null),
    stdout: (c) => append(out, c),
    stderr: (c) => append(err, c),
    instantiateWasm(imports, done) {
      const instance = new WebAssembly.Instance(compiled, imports);
      done(instance);
      return instance.exports;
    },
  };
  const context = vm.createContext({
    Module,
    require: createRequire(workerData.launcher.path),
    module: { exports: {} },
    __filename: workerData.launcher.path,
    __dirname: path.dirname(workerData.launcher.path),
    process: processView,
    console,
    Buffer,
    TextDecoder,
    TextEncoder,
    performance,
    setTimeout,
    clearTimeout,
  });
  await script.runInContext(context);
  if (processView.exitCode !== 0)
    throw Error('PSC1_WARM_KERNEL_PROCESS:' + Buffer.from(err).toString('utf8').slice(0, 8192));
  return JSON.parse(Buffer.from(out).toString('utf8'));
}
let busy = false;
parentPort.on('message', async (packet) => {
  const state = new Int32Array(packet.control),
    destination = new Uint8Array(packet.output);
  try {
    if (
      busy ||
      !Number.isSafeInteger(packet.id) ||
      typeof packet.source !== 'string' ||
      Buffer.byteLength(packet.source) > 134217728 ||
      destination.byteLength !== 33554432
    )
      throw Error('PSC1_WARM_KERNEL_REQUEST');
    busy = true;
    const result = await execute(packet.source);
    const encoded = Buffer.from(
      JSON.stringify({ id: packet.id, admissionsSha256: digest(packet.source), result }),
    );
    if (encoded.length > destination.byteLength) throw Error('PSC1_WARM_KERNEL_RESPONSE_LIMIT');
    destination.set(encoded);
    Atomics.store(state, 1, encoded.length);
    Atomics.store(state, 0, 1);
  } catch (error) {
    const encoded = Buffer.from(String(error?.message || error).slice(0, 8192));
    destination.set(encoded);
    Atomics.store(state, 1, encoded.length);
    Atomics.store(state, 0, 2);
  } finally {
    busy = false;
    Atomics.notify(state, 0);
  }
});
parentPort.postMessage({
  status: 'ready',
  launcherSha256: digest(launcher),
  wasmSha256: digest(binary),
});
