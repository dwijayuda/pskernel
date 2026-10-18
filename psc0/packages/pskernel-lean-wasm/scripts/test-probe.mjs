import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { loadGcProbe } from '../index.mjs';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const wat = await readFile(resolve(root, 'dist/gc-probe.core.wat'), 'utf8');
assert.match(wat, /\(struct\b|struct\.new/, 'must emit Wasm-GC structure types/operations');
assert.doesNotMatch(wat, /\(memory\b/, 'no linear-memory definition');
assert.doesNotMatch(wat, /\(import\s+[^\n]*memory\b/, 'no imported linear memory');
const {probe, module} = await loadGcProbe();
assert.equal(WebAssembly.Module.imports(module).length, 0);
assert.equal(WebAssembly.Module.exports(module).some(e => e.kind === 'memory'), false);
assert.equal(probe(0,0), 0);
assert.equal(probe(0,1), 0);
assert.equal(probe(1,0), 0);
assert.equal(probe(1,1), 1);
console.log('PSC0_WASM_GC_NATIVE_BACKEND: PASS (actual GC module, no linear memory, observable semantics)');
