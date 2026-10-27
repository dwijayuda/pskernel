// Editor-owned lifetime and integrity boundary around the unchanged public Wasm
// provider. A retained handle caches health metadata, never a Lean environment:
// the public provider still starts a fresh --check process for each graph.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {pathToFileURL} from 'node:url';
import pins from './kernel-pins.mjs';

const sha256 = value => crypto.createHash('sha256').update(value).digest('hex');
const COMPILER_TARBALL_SHA256 = '9a66dcd0f92aaa60f600674fb91b31bc0d67b211d1e9e004146baa8e96502fcc';
const LEAN_COMMIT = 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc';
const PROVIDER_ENTRY = 'node_modules/@proofscript/pskernel-lean-wasm/dist/index.js';
const validIdentity = result => result?.protocol === 'pskernel-lean/1' &&
  result.provider === 'lean4-cpp' && result.leanVersion === '4.35.0' &&
  result.leanCommit === LEAN_COMMIT && result.profile === 'lean4.35-core';
const addTime = (timings, key, start) => { timings[key] = (timings[key] || 0) + Math.round(performance.now() - start); };

export function createPinnedKernelSession(compilerRoot) {
  if (pins.schema !== 'psc1-editor-kernel-pins/1' ||
      pins.compilerTarballSha256 !== COMPILER_TARBALL_SHA256 ||
      pins.compilerVersion !== '0.1.0-psc1.12' || pins.leanCommit !== LEAN_COMMIT ||
      pins.providerEntry !== PROVIDER_ENTRY || !Array.isArray(pins.files) ||
      !pins.files.length || pins.files.length > 4096)
    throw Error('PSC1_LSP_KERNEL_PIN_IDENTITY');
  const root = path.resolve(compilerRoot), seen = new Set();
  const files = pins.files.map(row => {
    if (!row || typeof row.path !== 'string' || !/^[A-Za-z0-9_@.+/\-]+$/.test(row.path) ||
        row.path.split('/').some(part => !part || part === '.' || part === '..') ||
        seen.has(row.path) || !/^[a-f0-9]{64}$/.test(row.sha256) ||
        !Number.isSafeInteger(row.bytes) || row.bytes < 1 || row.bytes > 128 * 1024 * 1024)
      throw Error('PSC1_LSP_KERNEL_PIN_IDENTITY');
    seen.add(row.path);
    const file = path.resolve(root, row.path), relative = path.relative(root, file);
    if (!relative || relative === '..' || relative.startsWith('..' + path.sep) || path.isAbsolute(relative))
      throw Error('PSC1_LSP_KERNEL_PIN_IDENTITY');
    return Object.freeze({file, relative: row.path, bytes: row.bytes, sha256: row.sha256});
  });
  for (const required of ['package.json', 'dist/index.js', 'dist/implementation/DISTRIBUTION_PIN.mjs',
      'dist/implementation/UNIVERSAL_DISTRIBUTION.json', PROVIDER_ENTRY])
    if (!seen.has(required)) throw Error('PSC1_LSP_KERNEL_PIN_IDENTITY');

  let handle, closed = false;
  function verify(timings = {}) {
    if (closed) throw Error('PSC1_LSP_KERNEL_SESSION_CLOSED');
    const started = performance.now();
    try {
      const rootStat = fs.lstatSync(root);
      if (!rootStat.isDirectory() || rootStat.isSymbolicLink()) throw Error('package root');
      for (const pin of files) {
        for (let cursor = pin.file; cursor !== root; cursor = path.dirname(cursor))
          if (fs.lstatSync(cursor).isSymbolicLink()) throw Error(pin.relative);
        const stat = fs.lstatSync(pin.file);
        if (!stat.isFile() || stat.size !== pin.bytes || sha256(fs.readFileSync(pin.file)) !== pin.sha256)
          throw Error(pin.relative);
      }
    } catch (error) {
      closed = true;
      handle = undefined;
      throw Error('PSC1_LSP_KERNEL_RESOURCE_CHANGED: ' + String(error?.message || error));
    } finally { addTime(timings, 'kernelVerifyMs', started); }
  }

  async function checkCanonicalAdmissions(source, timings = {}) {
    if (closed) throw Error('PSC1_LSP_KERNEL_SESSION_CLOSED');
    if (typeof source !== 'string' || Buffer.byteLength(source) > 128 * 1024 * 1024) {
      closed = true;
      throw Error('PSC1_LSP_KERNEL_INPUT_LIMIT');
    }
    const reusedKernelHealth = Boolean(handle);
    try {
      // These pins come from the qualified archive, not a mutable provider
      // manifest. The provider additionally verifies its own prebuilt manifest.
      verify(timings);
      if (!handle) {
        const started = performance.now();
        try {
          const provider = await import(pathToFileURL(path.join(root, PROVIDER_ENTRY)).href);
          if (typeof provider.createKernel !== 'function') throw Error('PSC1_LSP_KERNEL_EXPORT');
          // Keep launcherPath absent: the public provider resolves its own
          // bundled launcher and keeps its prebuilt-manifest check enabled.
          const created = await provider.createKernel({nodePath: process.execPath,
            timeoutMs: 120000, maxBuffer: 32 * 1024 * 1024});
          if (!validIdentity(created?.metadata) || created.metadata.status !== 'ok' ||
              typeof created.checkCanonicalAdmissions !== 'function')
            throw Error('PSC1_LSP_KERNEL_IDENTITY');
          handle = created;
        } finally {
          addTime(timings, 'kernelInitMs', started);
          verify(timings);
        }
      }
      let result;
      const started = performance.now();
      try { result = await handle.checkCanonicalAdmissions(source); }
      finally {
        addTime(timings, 'kernelCheckMs', started);
        verify(timings);
      }
      if (!validIdentity(result) || typeof result.accepted !== 'boolean')
        throw Error('PSC1_LSP_KERNEL_IDENTITY');
      // The result is the real provider response. The editor adds only a digest
      // of the exact submitted bytes and whether health metadata was reused.
      return Object.freeze({result, admissionsSha256: sha256(source), reusedKernelHealth});
    } catch (error) {
      closed = true;
      handle = undefined;
      throw error;
    }
  }
  return Object.freeze({verify, checkCanonicalAdmissions});
}
