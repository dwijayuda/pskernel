// Project-specific GC runtime exercise: the only exported entry is a
// checked scalar Bool, while its transitive code uses GC Nat internally.
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {spawnSync} from 'node:child_process';
import path from 'node:path';

const coreStem = path.resolve(process.argv[2]);
const componentStem = path.resolve(process.argv[3]);
const core = await readFile(coreStem + '.core.wasm');
const {instance} = await WebAssembly.instantiate(core, {});
assert.deepEqual(Object.keys(instance.exports), ['wasmProjectCheck']);
assert.equal(instance.exports.wasmProjectCheck(), 1,
  'four-module Wasm GC private-helper execution');
const wit = await readFile(componentStem + '.wit', 'utf8');
const matches = [...wit.matchAll(/export\s+%?([\w-]+):\s*func\(\)\s*->\s*bool;/g)];
assert.equal(matches.length, 1, 'exactly one Boolean entry in extracted WIT');
const exported = matches[0][1];
const run = spawnSync('wasmtime', ['run','--invoke', exported+'()',componentStem+'.wasm'],
  {encoding:'utf8', maxBuffer:1024*1024});
assert.equal(run.status,0,run.stderr);
assert.equal(run.stdout.trim(),'true','component public Bool result from checked link');
console.log('PSCV0_NATIVE_PROJECT_WASM: PASS 4-module checked GC execution under V8 and Wasmtime; one entry-only Bool export');
