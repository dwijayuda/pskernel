// Focused execution checks for the separately kernel-checked M3 deriving fixture.
// Compiler implementation remains native Lean; this file only drives target VMs.
import assert from 'node:assert/strict';
import {readFile, writeFile, mkdir} from 'node:fs/promises';
import {pathToFileURL} from 'node:url';
import {spawnSync} from 'node:child_process';
import path from 'node:path';

const [mode, directoryArg, moduleArg] = process.argv.slice(2);
assert(directoryArg, 'expected mode and fixture directory');
const directory = path.resolve(directoryArg);
const expected = JSON.parse(await readFile(path.join(directory, 'expected.json'), 'utf8'));
const names = ['m3hashnat', 'm3hashbool', 'm3reprnat', 'm3reprbool', 'm3eqnat', 'm3eqbool', 'm3eqatom', 'm3decidenat', 'm3decidebool', 'm3decideatom', 'm3decideproof', 'm3normoutput', 'm3lateroutput', 'm3flipoutput', 'm3suboutput', 'm3infixoutput', 'm3matrixoutput', 'm3nestedoutput', 'm3nestedarrayoutput', 'm3partialoutput', 'm3partialcountoutput', 'm3nestedoptionoutput', 'm3nestedprodoutput', 'm3partialcaptureoutput'];
assert.deepEqual(expected.map(row => row.flag), [false, true]);
const run = (command, args) => {
  const result = spawnSync(command, args, {encoding:'utf8', timeout:120000, maxBuffer:4*1024*1024});
  assert.equal(result.status, 0, `${command}: ${result.error ?? ''}\n${result.stderr}`);
  return result.stdout.trim();
};

if (mode === 'ecma') {
  const file = moduleArg ? path.resolve(moduleArg) : path.join(directory, 'hashing.js');
  const generated = await import(pathToFileURL(file).href);
  for (const row of expected) for (const name of names)
    assert.equal(generated[name](row.flag), BigInt(row[name]), `${name}(${row.flag})`);
  console.log(`PSCV0_M3_RECURSIVE_HASH_ECMA: PASS ${file}`);
} else if (mode === 'rust') {
  // Reuse the existing pinned dependency lock and selected runtime-check target.
  const output = path.resolve(directory, '..', 'pscv0-native');
  await mkdir(output, {recursive:true});
  const generatedPath = path.relative(output, path.join(directory, 'hashing.rs'));
  const assertions = expected.flatMap(row => names.map(name =>
    `    assert_eq!(generated::${name}(${row.flag}), ${row[name]}u64);`));
  await writeFile(path.join(output, 'rust-checks.rs'),
    `#[path = ${JSON.stringify(generatedPath)}]\nmod generated;\nfn main() {\n${assertions.join('\n')}\n    println!("PSCV0_M3_RECURSIVE_HASH_RUST: PASS");\n}\n`);
} else if (mode === 'wasm') {
  const core = path.join(directory, 'hashing.core.wasm');
  const component = path.join(directory, 'hashing.wasm');
  run('wasm-tools', ['validate', core]);
  run('wasm-tools', ['validate', component]);
  const {instance} = await WebAssembly.instantiate(await readFile(core), {});
  assert.deepEqual(Object.keys(instance.exports).sort(), [...names].sort());
  const wit = await readFile(path.join(directory, 'hashing.wit'), 'utf8');
  const exports = [...wit.matchAll(/export\s+%?([\w-]+):\s*func\([^)]*:\s*bool\)\s*->\s*u64\s*;/g)].map(m => m[1]);
  assert.deepEqual(exports.sort(), [...names].sort(), 'exact Bool-to-UInt64 component ABI');
  for (const row of expected) for (const name of names) {
    assert.equal(BigInt.asUintN(64, instance.exports[name](Number(row.flag))), BigInt(row[name]),
      `GC core ${name}(${row.flag})`);
    const value = run('wasmtime', ['run', '--invoke', `${name}(${row.flag})`, component]);
    assert.equal(BigInt(value), BigInt(row[name]), `component ${name}(${row.flag})`);
  }
  console.log('PSCV0_M3_RECURSIVE_HASH_WASM: PASS V8 GC core and Wasmtime components against pinned Lean oracle');
} else {
  throw new Error('expected ecma, rust or wasm');
}

