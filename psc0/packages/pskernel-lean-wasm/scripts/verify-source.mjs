import assert from 'node:assert/strict';
import { readFile, readdir, stat } from 'node:fs/promises';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const readJson = async name => JSON.parse(await readFile(resolve(root, name), 'utf8'));
const pkg = await readJson('package.json');
const pin = await readJson('LEAN_SOURCE_PIN.json');
assert.equal(pkg.name, '@proofscript/pskernel-lean-wasm');
assert.equal(pkg.private, true, 'unqualified checker must not be published');
assert.equal(pkg.proofscript.kernelReady, false);
assert.equal(pin.toolchain, 'leanprover/lean4:v4.35.0');
assert.equal(pin.leanCommit, 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc');
assert.equal(pin.languageProfile, 'pscv0-v7.2');
assert.equal(pin.target, 'psc0-wasm-gc-core');
assert.equal(pin.kernelReady, false);
const source = await readFile(resolve(root, 'src/PsKernelLeanWasmGc/Probe.lean'), 'utf8');
assert.match(source, /structure PsKernelGcPair/);
assert.match(source, /def pskernelWasmGcProbe/);
const obsolete = [
  'source', 'kernel', 'patches', 'provider-test', 'provider',
  'host', 'wasm', 'EMSCRIPTEN_PIN.json', 'PREBUILT_WASM_MANIFEST.json',
  'KERNEL_SOURCE_MANIFEST.json', 'PROOFSCRIPT_SOURCE_MANIFEST.json', 'LEAN_LICENSE',
  'BUILDING.md'
];
const present = await readdir(root);
for (const name of obsolete) assert.ok(!present.includes(name), 'obsolete PSC2 asset: ' + name);
console.log('PSC0_WASM_GC_SOURCE: PASS (Lean 4.35.0 / v7.2; no legacy sources; NOT a checker)');
