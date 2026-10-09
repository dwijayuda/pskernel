// This adapter is trusted release code. The guest is only captured Wasm bytes;
// no npm JavaScript module or WASI implementation is loaded into this worker.
import { parentPort, workerData } from 'node:worker_threads';
import { assertCommandWasmProfile } from './command-wasm-profile.mjs';

try {
  assertCommandWasmProfile(workerData.bytes);
  const module = new WebAssembly.Module(workerData.bytes);
  const exports = WebAssembly.Module.exports(module);
  if (WebAssembly.Module.imports(module).length !== 0 || exports.length !== 1 ||
      exports[0].name !== 'psc_event' || exports[0].kind !== 'function') {
    throw new Error('PSC_EXTENSION_WASM_ABI');
  }
  const instance = new WebAssembly.Instance(module, Object.create(null));
  parentPort.postMessage({ stage: 'instantiated' });
  const value = instance.exports.psc_event(workerData.event);
  if (value !== 0 && value !== 1) throw new Error('PSC_EXTENSION_RESPONSE');
  parentPort.postMessage({ stage: 'completed', value });
} catch (error) {
  const code = /^PSC_EXTENSION_[A-Z_]+$/u.test(error?.message ?? '') ? error.message
    : error instanceof WebAssembly.CompileError ? 'PSC_EXTENSION_INVALID_WASM'
    : 'PSC_EXTENSION_GUEST_FAILED';
  // Never forward guest-controlled names, stack traces or arbitrary output.
  parentPort.postMessage({ stage: 'failed', code });
} finally {
  parentPort.close();
}
