/*
 * PSC0 v7.2 Wasm-GC kernel development entry.
 * NO checker implementation is currently bundled. Never treat a GC transport
 * self-test or the official native Lean compiler's checked emission as an
 * independent Lean kernel implementation.
 */
import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { resolve } from 'node:path';
import { createHash } from 'node:crypto';

export const leanKernelProviderProtocol = 'pskernel-lean-wasm-gc/0';
export const leanKernelProviderVersion = '4.35.0';
export const leanKernelProviderCommit = 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc';
export const leanKernelLanguageProfile = 'pscv0-v7.2';

export class KernelNotReadyError extends Error {
  constructor() {
    super('PSC0-WASM-GC-KERNEL-NOT-READY: no qualified Lean 4.35.0 GC-native proof checker is bundled');
    this.name = 'KernelNotReadyError';
    this.code = 'PSC0-WASM-GC-KERNEL-NOT-READY';
  }
}

export function kernelStatus() {
  return Object.freeze({
    protocol: leanKernelProviderProtocol,
    leanVersion: leanKernelProviderVersion,
    leanCommit: leanKernelProviderCommit,
    languageProfile: leanKernelLanguageProfile,
    target: 'wasm-gc-core',
    checkerReady: false,
    admissionSupported: false,
    assurance: 'unavailable',
  });
}

// Unavailable is NOT a kernel rejection. Callers must not report "invalid proof".
export async function createKernel() {
  throw new KernelNotReadyError();
}

export async function checkCanonicalAdmissions(source) {
  if (typeof source !== 'string') throw new TypeError('canonical admissions must be a string');
  throw new KernelNotReadyError();
}

// DEVELOPMENT-ONLY test of PSC0's Wasm-GC backend, not part of proof admission.
// Does not initialize or return a kernel provider.
export async function loadGcProbe({ binaryPath } = {}) {
  const file = binaryPath === undefined
    ? fileURLToPath(new URL('./wasm/gc-probe.core.wasm', import.meta.url))
    : resolve(binaryPath);
  const bytes = await readFile(file);
  if (binaryPath === undefined) {
    const manifest = JSON.parse(await readFile(
      fileURLToPath(new URL('./PREBUILT_GC_PROBE_MANIFEST.json', import.meta.url)), 'utf8'));
    if (manifest.isProofKernel !== false || manifest.acceptsCanonicalAdmissions !== false ||
        manifest.leanCommit !== leanKernelProviderCommit) {
      throw new Error('PSC0-WASM-GC-PROBE: wrong package or kernel identity');
    }
    const expected = manifest.assets['gc-probe.core.wasm'];
    if (!expected || expected.bytes !== bytes.length ||
        expected.sha256 !== createHash('sha256').update(bytes).digest('hex')) {
      throw new Error('PSC0-WASM-GC-PROBE: prebuilt digest/size mismatch');
    }
  }
  const module = await WebAssembly.compile(bytes);
  if (WebAssembly.Module.imports(module).length !== 0 ||
      WebAssembly.Module.exports(module).some(entry => entry.kind === 'memory')) {
    throw new Error('PSC0-WASM-GC-PROBE: expected a standalone module without linear memory or imports');
  }
  const instance = await WebAssembly.instantiate(module);
  const functions = WebAssembly.Module.exports(module)
    .filter(entry => entry.kind === 'function' && entry.name.includes('pskernelWasmGcProbe'));
  if (functions.length !== 1 || typeof instance.exports[functions[0].name] !== 'function') {
    throw new Error('PSC0-WASM-GC-PROBE: missing or ambiguous probe export');
  }
  return Object.freeze({ probe: instance.exports[functions[0].name], module });
}
