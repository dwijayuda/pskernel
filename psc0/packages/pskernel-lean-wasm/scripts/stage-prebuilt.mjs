// Invoked only after native PSC0 + official Lean checking + GC runtime tests.
// The output is a compiler/GC probe; NOT a Lean proof kernel.
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {readFile, mkdir, copyFile, writeFile} from 'node:fs/promises';
import {resolve, dirname} from 'node:path';
import {fileURLToPath} from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const file = subpath => resolve(root, subpath);
const sha = bytes => createHash('sha256').update(bytes).digest('hex');
const pin = JSON.parse(await readFile(file('LEAN_SOURCE_PIN.json'), 'utf8'));
const provenance = JSON.parse(await readFile(file('dist/gc-probe.wasm.origins.json'), 'utf8'));
assert.equal(pin.leanCommit, 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc');
assert.equal(provenance.leanCommit, pin.leanCommit);
assert.equal(provenance.assurance, 'ordinary-checked');
assert.equal(provenance.kernel, 'official-lean4-cpp');
assert.equal(provenance.irValidation, 'accepted-complete');
const wat = await readFile(file('dist/gc-probe.core.wat'), 'utf8');
assert.match(wat, /\(struct\b|struct\.new/, 'GC structure must exist in real emitted binary');
assert.doesNotMatch(wat, /\(memory\b/, 'no linear memory');
const bytes = await readFile(file('dist/gc-probe.core.wasm'));
const module = await WebAssembly.compile(bytes);
assert.equal(WebAssembly.Module.imports(module).length, 0);
assert.ok(!WebAssembly.Module.exports(module).some(e => e.kind === 'memory'));
await mkdir(file('wasm'), {recursive:true});
const assets = [
  ['dist/gc-probe.core.wasm', 'wasm/gc-probe.core.wasm'],
  ['dist/gc-probe.core.wat', 'wasm/gc-probe.core.wat'],
  ['dist/gc-probe.wasm.origins.json', 'wasm/gc-probe.origins.json'],
];
const entries = {};
for (const [input, output] of assets) {
  await copyFile(file(input), file(output));
  const payload = await readFile(file(output));
  entries[output.slice(5)] = {path:output, bytes:payload.length, sha256:sha(payload)};
}
const source = await readFile(file('src/PsKernelLeanWasmGc/Probe.lean'));
const manifest = {
  schemaVersion:1,
  packageName:'@proofscript/pskernel-lean-wasm',
  status:'gc-backend-probe-only',
  isProofKernel:false,
  acceptsCanonicalAdmissions:false,
  sourceLanguage:'pscv0-v7.2',
  leanVersion:'4.35.0',
  leanCommit:pin.leanCommit,
  gcMemoryModel:'wasm-gc; no linear-memory import or export',
  sourceSha256:sha(source),
  compilerEvidence:'PSC0 checked Core through the official Lean kernel, ordinary-checked',
  assets:entries
};
await writeFile(file('PREBUILT_GC_PROBE_MANIFEST.json'), JSON.stringify(manifest,null,2)+'\n');
console.log('PSC0_WASM_GC_STAGE_PREBUILT: PASS '+JSON.stringify(entries));
