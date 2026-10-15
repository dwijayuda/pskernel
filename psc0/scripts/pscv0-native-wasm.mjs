// Independent format/engine checks. Production emission never invokes these tools.
import { observations, panicObservations } from './pscv0-native-observations.mjs';
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
// The pinned CLI accepts bare WAVE function names; these fixture exports use
// descriptive check-* names. C4b uses an embedding harness for arbitrary names
// and repeated-call/post-return lifecycle checks.
function componentCall(name, args = []) {
  return name + '(' + args.map(x => typeof x === 'bigint' ? x.toString() : JSON.stringify(x)).join(', ') + ')';
}
function exportsOf(wit) {
  return [...wit.matchAll(/export\s+%?([\w-]+):\s*func\(([^)]*)\)(?:\s*->\s*(\w+))?;/g)]
    .map(m => [m[1], m[2].replaceAll('%', '').replace(/\s/g, ''), m[3] ?? ''])
    .sort((a, b) => a[0].localeCompare(b[0]));
}
for (const name of ['gc-probe', 'scalar', 'natural-probe', 'observations', 'signed']) {
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
    {
      run('wasm-tools', ['strip', '--delete', '^(name|component-name)$', binary, '-o', stem + '.stripped.wasm']);
      run('wasm-tools', ['strip', '--delete', '^(name|component-name)$', stem + kind + '.roundtrip.wasm', '-o', stem + '.roundtrip.stripped.wasm']);
      assert.deepEqual(await readFile(stem + '.stripped.wasm'), await readFile(stem + '.roundtrip.stripped.wasm'),
        'direct binary and reassembled readable WAT');
    }
    if (!kind) {
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
      assert.equal(run('wasmtime', ['run', '--invoke', componentCall('read-captured', [42]), stem + suffix]), '42');
  } else if (name === 'natural-probe' || name === 'observations') {
    for (const [foreign] of exportsOf(declared)) {
      const internal = foreign.replace(/-([a-z])/g, (_, c) => c.toUpperCase());
      if (name === 'observations' && panicObservations.some(({wasm}) => wasm === internal)) {
        assert.throws(() => instance.exports[internal](), WebAssembly.RuntimeError,
          'outOfBounds must trap under V8 Wasm GC');
        for (const args of [
          ['run', '--invoke', internal, stem + '.core.wasm'],
          ['run', '--invoke', componentCall(foreign), stem + '.wasm']]) {
          const trapped = spawnSync('wasmtime', args, {encoding: 'utf8'});
          assert.notEqual(trapped.status, 0, 'outOfBounds returned under Wasmtime');
          assert.match(trapped.stderr, /trap|unreachable/i,
            'outOfBounds failure was not a Wasm trap');
        }
        continue;
      }
      assert.equal(instance.exports[internal](), 1, internal);
      // The embedding harness runs the full table once per instance in both
      // core/component forms, avoiding hundreds of engine startups.
      if (name === 'natural-probe') {
        assert.equal(run('wasmtime', ['run', '--invoke', internal, stem + '.core.wasm']), '1', internal);
        for (const suffix of ['.wasm', '.roundtrip.wasm'])
          assert.equal(run('wasmtime', ['run', '--invoke', componentCall(foreign), stem + suffix]), 'true', foreign);
      }
    }
  } else if (name === 'signed') {
    // Signed i8/i16/i32/i64 use the same source-level definitions and
    // canonical WIT s8/s16/s32/s64 types. Assert both V8 GC core and
    // Wasmtime component values, including min/-1 and division-by-zero.
    const cases = [
    {core:"signedEightAdd", foreign:"signed-eight-add", args:[127,1], expected:-128},
    {core:"signedEightDiv", foreign:"signed-eight-div", args:[-128,-1], expected:-128},
    {core:"signedEightDiv", foreign:"signed-eight-div", args:[-128,0], expected:0},
    {core:"signedEightMod", foreign:"signed-eight-mod", args:[-5,2], expected:-1},
    {core:"signedEightMod", foreign:"signed-eight-mod", args:[-128,0], expected:-128},
    {core:"signedSixteenSub", foreign:"signed-sixteen-sub", args:[-32768,1], expected:32767},
    {core:"signedSixteenMul", foreign:"signed-sixteen-mul", args:[32767,2], expected:-2},
    {core:"signedThirtyTwoDiv", foreign:"signed-thirty-two-div", args:[-2147483648,-1], expected:-2147483648},
    {core:"signedThirtyTwoMod", foreign:"signed-thirty-two-mod", args:[-2147483648,0], expected:-2147483648},
    {core:"signedSixtyFourAdd", foreign:"signed-sixty-four-add", args:[9223372036854775807n,1n], expected:-9223372036854775808n},
    {core:"signedSixtyFourDiv", foreign:"signed-sixty-four-div", args:[-9223372036854775808n,-1n], expected:-9223372036854775808n},
    ];
    for (const test of cases) {
      assert.equal(instance.exports[test.core](...test.args), test.expected,
        test.core + ' V8 signed GC result');
      for (const suffix of ['.wasm', '.roundtrip.wasm']) {
        assert.equal(run('wasmtime', ['run', '--invoke',
          componentCall(test.foreign, test.args), stem + suffix]),
          String(test.expected), test.foreign + ' canonical signed result');
      }
    }
  } else {
    for (const bits of [0n, 0x8000000000000000n, 1n, 0x7ff0000000000000n, 0xfff0000000000001n]) {
      const expected = bits === 0xfff0000000000001n ? 0x7ff8000000000000n : bits;
      assert.equal(BigInt.asUintN(64, instance.exports.scalarBits64(instance.exports.scalarMake64(bits))), expected);
    }
    for (const bits of [0, 0x80000000, 1, 0x7f800000, 0xff800001]) {
      const expected = bits === 0xff800001 ? 0x7fc00000 : bits;
      assert.equal(instance.exports.scalarBits32(instance.exports.scalarMake32(bits)) >>> 0, expected);
    }
    for (const a of [0, 1]) {
      assert.equal(instance.exports.invert(a), 1 - a);
      for (const b of [0, 1]) {
        assert.equal(instance.exports.both(a, b), a & b);
        assert.equal(run('wasmtime', ['run', '--invoke', 'both', stem + '.core.wasm', String(a), String(b)]), String(a & b));
        for (const suffix of ['.wasm', '.roundtrip.wasm'])
          assert.equal(run('wasmtime', ['run', '--invoke', componentCall('both', [!!a, !!b]), stem + suffix]), String(!!(a & b)));
      }
    }
  }
  console.log(await readFile(stem + '.wit', 'utf8'));
}
console.log(JSON.stringify({profile:'pscv0-wasm-c4-gc/1', node:process.version, v8:process.versions.v8,
  wasmTools:run('wasm-tools',['--version']), wasmtime:run('wasmtime',['--version']),
  gcInsideComponent:true, scalarWorlds:5, sharedObservations:observations.length, naturalLimbChecks:10, coreBinaryWatEqual:true}));
