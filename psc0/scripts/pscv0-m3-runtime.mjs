// VM-only runner for separately kernel-checked native M3 runtime fixtures.
// No compiler algorithm or acceptance policy is implemented here.
import assert from 'node:assert/strict';
import {readFile, writeFile, mkdir} from 'node:fs/promises';
import {fileURLToPath, pathToFileURL} from 'node:url';
import {spawnSync} from 'node:child_process';
import path from 'node:path';

const [mode, directoryArg, stem, exportsArg, moduleArg] = process.argv.slice(2);
assert(directoryArg && stem && exportsArg,
  'expected mode, fixture directory, output stem and comma-separated export names');
assert.match(stem, /^[a-z][a-z0-9_-]*$/);
const names = exportsArg.split(',');
assert(names.length > 0 && new Set(names).size === names.length, 'unique requested exports');
for (const name of names) assert.match(name, /^[a-z][a-z0-9_]*$/);
const directory = path.resolve(directoryArg);
const expected = JSON.parse(await readFile(path.join(directory, 'expected.json'), 'utf8'));
assert.deepEqual(expected.map(row => row.flag), [false, true]);
for (const row of expected) {
  assert.deepEqual(Object.keys(row).sort(), ['flag', ...names].sort(), 'exact oracle outputs');
  for (const name of names) {
    assert.equal(typeof row[name], 'string', 'UInt64 oracle must be exact decimal text');
    assert.match(row[name], /^(0|[1-9][0-9]*)$/);
    assert(BigInt(row[name]) <= 0xffffffffffffffffn, 'UInt64 oracle out of range');
  }
}
const run = (command, args) => {
  const result = spawnSync(command, args, {encoding:'utf8', timeout:120000, maxBuffer:4*1024*1024});
  assert.equal(result.status, 0, command + ': ' + (result.error ?? '') + '\n' + result.stderr);
  return result.stdout.trim();
};

if (mode === 'ecma') {
  const file = moduleArg ? path.resolve(moduleArg) : path.join(directory, stem + '.js');
  const generated = await import(pathToFileURL(file).href);
  for (const row of expected) for (const name of names)
    assert.equal(generated[name](row.flag), BigInt(row[name]), name + '(' + row.flag + ')');
  console.log('PSCV0_M3_RUNTIME_ECMA: PASS ' + file);
} else if (mode === 'rust') {
  // Reuse the existing dependency lock and selected runtime-check target.
  // Cargo owns one harness path even when a fixture directory is nested.
  const output = fileURLToPath(new URL('../dist/pscv0-native/', import.meta.url));
  await mkdir(output, {recursive:true});
  const generatedPath = path.relative(output, path.join(directory, stem + '.rs'));
  const assertions = expected.flatMap(row => names.map(name =>
    '    assert_eq!(generated::' + name + '(' + row.flag + '), ' + row[name] + 'u64);'));
  await writeFile(path.join(output, 'rust-checks.rs'),
    '#[path = ' + JSON.stringify(generatedPath) + ']\nmod generated;\nfn main() {\n' +
    assertions.join('\n') + '\n    println!("PSCV0_M3_RUNTIME_RUST: PASS ' + stem + '");\n}\n');
  console.log('PSCV0_M3_RUNTIME_RUST_READY: ' + stem);
} else if (mode === 'wasm') {
  const core = path.join(directory, stem + '.core.wasm');
  const component = path.join(directory, stem + '.wasm');
  run('wasm-tools', ['validate', core]);
  run('wasm-tools', ['validate', component]);
  const {instance} = await WebAssembly.instantiate(await readFile(core), {});
  assert.deepEqual(Object.keys(instance.exports).sort(), [...names].sort());
  const wit = await readFile(path.join(directory, stem + '.wit'), 'utf8');
  const exports = [...wit.matchAll(/export\s+%?([\w-]+):\s*func\([^)]*:\s*bool\)\s*->\s*u64\s*;/g)].map(m => m[1]);
  assert.deepEqual(exports.sort(), [...names].sort(), 'exact Bool-to-UInt64 component ABI');
  for (const row of expected) for (const name of names) {
    assert.equal(BigInt.asUintN(64, instance.exports[name](Number(row.flag))), BigInt(row[name]),
      'GC core ' + name + '(' + row.flag + ')');
    const value = run('wasmtime', ['run', '--invoke', name + '(' + row.flag + ')', component]);
    assert.equal(BigInt(value), BigInt(row[name]), 'component ' + name + '(' + row.flag + ')');
  }
  console.log('PSCV0_M3_RUNTIME_WASM: PASS ' + stem + ' V8 GC core and Wasmtime components against checked equations');
} else {
  throw new Error('expected ecma, rust or wasm');
}

