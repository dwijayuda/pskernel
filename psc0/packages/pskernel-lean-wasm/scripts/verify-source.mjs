import assert from 'node:assert/strict';
import { readFile, readdir, stat } from 'node:fs/promises';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const readJson = async name => JSON.parse(await readFile(resolve(root, name), 'utf8'));
const pkg = await readJson('package.json');
const parentRoot = resolve(root, '../..');
const distribution = await readFile(resolve(parentRoot, 'scripts/npm-distribution.mjs'), 'utf8');
const metaPackage = JSON.parse(await readFile(resolve(parentRoot, 'packages/proofscript/package.json'), 'utf8'));
assert.ok(!/const optionalNames=\[[^\n]*'pskernel-lean-wasm'/.test(distribution),
  'unqualified Wasm-GC kernel cannot enter npm distribution');
assert.ok(!metaPackage.proofscript.optionalPackages.includes('@proofscript/pskernel-lean-wasm'),
  'meta package cannot advertise unfinished GC kernel');
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
const manifest=JSON.parse(await readFile(resolve(root,'../../pskernel-lean-wasm-gc-project.json'),'utf8'));
assert.equal(manifest.entry,'PsKernelLeanWasmGc.SourceClosure');
assert.equal(manifest.modules.length,4);
const actualModules=new Set(manifest.modules.map(m=>m.name));
for(const required of ['Ps.Foundation.Name','Ps.Core.Level','Ps.Core.Expr','PsKernelLeanWasmGc.SourceClosure']){
  assert.ok(actualModules.has(required),'missing actual PSC0 source module '+required);
}
const closureSource=await readFile(resolve(root,'src/PsKernelLeanWasmGc/SourceClosure.lean'),'utf8');
assert.match(closureSource,/import Ps.Core.Expr/);
assert.match(closureSource,/def pskernelWasmGcSourceCoreProbe/);
const obsolete = [
  'source', 'kernel', 'patches', 'provider-test', 'provider',
  'host', 'EMSCRIPTEN_PIN.json', 'PREBUILT_WASM_MANIFEST.json',
  'KERNEL_SOURCE_MANIFEST.json', 'PROOFSCRIPT_SOURCE_MANIFEST.json', 'LEAN_LICENSE',
  'BUILDING.md'
];
const present = await readdir(root);
for (const name of obsolete) assert.ok(!present.includes(name), 'obsolete PSC2 asset: ' + name);
if (present.includes('wasm')) {
  const builtFiles=await readdir(resolve(root,'wasm'));
  for(const oldName of ['pskernel-lean.cjs','pskernel-lean.wasm']){
    assert.ok(!builtFiles.includes(oldName),'obsolete Emscripten Wasm: '+oldName);
  }
}
console.log('PSC0_WASM_GC_SOURCE: PASS (Lean 4.35.0 / v7.2; no legacy sources; NOT a checker)');
