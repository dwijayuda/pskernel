// Independent format/engine checks. Production emission never invokes these tools.
import assert from 'node:assert/strict';
import { readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
const directory = path.resolve(process.argv[2]);
function run(tool, args) {
  const result = spawnSync(tool, args, {encoding: 'utf8'});
  assert.equal(result.status, 0, tool + ' ' + args.join(' ') + '\n' + result.stderr);
  return result.stdout.trim();
}
function exportsOf(wit) {
  return [...wit.matchAll(/export\s+%?([\w-]+):\s*func\(([^)]*)\)(?:\s*->\s*(\w+))?;/g)]
    .map(m => [m[1], m[2].replaceAll('%', '').replace(/\s/g, ''), m[3] ?? ''])
    .sort((a, b) => a[0].localeCompare(b[0]));
}
for (const name of ['gc-probe', 'scalar']) {
  const stem = path.join(directory, name);
  const declared = run('wasm-tools', ['component', 'wit', stem + '.wit']);
  const extracted = run('wasm-tools', ['component', 'wit', stem + '.wasm']);
  assert.deepEqual(exportsOf(extracted), exportsOf(declared), 'extracted scalar world');
  assert(exportsOf(declared).length > 0);
  await writeFile(stem + '.extracted.wit', extracted + '\n');
  for (const kind of ['', '.core']) {
    const binary = stem + kind + '.wasm';
    run('wasm-tools', ['validate', binary]);
    run('wasm-tools', ['parse', stem + kind + '.wat', '-o', stem + kind + '.roundtrip.wasm']);
    run('wasm-tools', ['validate', stem + kind + '.roundtrip.wasm']);
    if (kind === '.core') {
      run('wasm-tools', ['strip', '--delete', '^name$', binary, '-o', stem + '.stripped.wasm']);
      run('wasm-tools', ['strip', '--delete', '^name$', stem + kind + '.roundtrip.wasm', '-o', stem + '.roundtrip.stripped.wasm']);
      assert.deepEqual(await readFile(stem + '.stripped.wasm'), await readFile(stem + '.roundtrip.stripped.wasm'),
        'direct binary and reassembled readable core WAT');
    } else {
      assert.deepEqual(exportsOf(run('wasm-tools', ['component', 'wit', stem + '.roundtrip.wasm'])),
        exportsOf(declared), 'reassembled component world');
    }
  }
  const bytes = await readFile(stem + '.core.wasm');
  const { instance } = await WebAssembly.instantiate(bytes, {});
  if (name === 'gc-probe') {
    assert.equal(instance.exports.readCaptured(42), 42);
    assert.equal(run('wasmtime', ['run', '--invoke', 'readCaptured', stem + '.core.wasm', '42']), '42');
    for (const suffix of ['.wasm', '.roundtrip.wasm'])
      assert.equal(run('wasmtime', ['run', '--invoke', 'read-captured(42)', stem + suffix]), '42');
  } else {
    for (const a of [0, 1]) {
      assert.equal(instance.exports.invert(a), 1 - a);
      for (const b of [0, 1]) {
        assert.equal(instance.exports.both(a, b), a & b);
        assert.equal(run('wasmtime', ['run', '--invoke', 'both', stem + '.core.wasm', String(a), String(b)]), String(a & b));
        for (const suffix of ['.wasm', '.roundtrip.wasm'])
          assert.equal(run('wasmtime', ['run', '--invoke', 'both(' + !!a + ', ' + !!b + ')', stem + suffix]), String(!!(a & b)));
      }
    }
  }
  console.log(await readFile(stem + '.wit', 'utf8'));
}
console.log(JSON.stringify({profile:'pscv0-wasm-c3/1', node:process.version, v8:process.versions.v8,
  wasmTools:run('wasm-tools',['--version']), wasmtime:run('wasmtime',['--version']),
  gcInsideComponent:true, scalarWorlds:2, coreBinaryWatEqual:true}));
