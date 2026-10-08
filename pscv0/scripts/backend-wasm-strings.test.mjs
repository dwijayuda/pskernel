import assert from 'node:assert/strict';
import { mkdtemp, readFile, rm } from 'node:fs/promises';
import { spawnSync } from 'node:child_process';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { performance } from 'node:perf_hooks';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const temp = await mkdtemp(path.join(tmpdir(), 'psc-wasm-strings-'));
try {
  const binary = path.join(root, '.lake/build/bin/psc1_wasm_string_runtime_fixture' +
    (process.platform === 'win32' ? '.exe' : ''));
  const wasm = path.join(temp, 'runtime.wasm');
  const generated = spawnSync(binary, [wasm], { cwd: root, encoding: 'utf8', timeout: 60000 });
  if (generated.error) throw generated.error;
  assert.equal(generated.status, 0, generated.stdout + generated.stderr);
  const { instance } = await WebAssembly.instantiate(await readFile(wasm), {});
  const e = instance.exports;
  const runtime = name => e['__ps_wasm_' + name];
  const zero = runtime('nat_zero'), bit0 = runtime('nat_mk_bit0'), bit1 = runtime('nat_bit1');
  function nat(value) {
    let result = zero();
    for (const bit of BigInt(value).toString(2)) result = bit === '1' ? bit1(result) : bit0(result);
    return result;
  }
  const number = value => runtime('nat_to_u32')(value) >>> 0;
  const sameNat = (a, b) => assert.equal(runtime('nat_cmp')(a, nat(b)), 0);
  function string(text) {
    const chars = Array.from(text), builder = e.__ps_selfhost_string_new(chars.length);
    chars.forEach((char, index) => e.__ps_selfhost_string_set(builder, index, char.codePointAt(0)));
    return e.__ps_selfhost_string_finish(builder);
  }
  const eq = (actual, expected) => assert.equal(runtime('string_eq')(actual, string(expected)), 1);
  const corpus = ['', 'ASCII\n', 'aéΩ中😀z', String.fromCodePoint(
    0, 0x7f, 0x80, 0x7ff, 0x800, 0xd7ff, 0xe000, 0xffff, 0x10000, 0x10ffff)];
  for (const text of corpus) {
    const value = string(text), chars = Array.from(text), starts = new Map();
    let offset = 0;
    chars.forEach((char, index) => {
      starts.set(offset, { char, index, width: Buffer.byteLength(char) });
      offset += Buffer.byteLength(char);
    });
    sameNat(runtime('string_length')(value), chars.length);
    sameNat(runtime('string_utf8_byte_size')(value), Buffer.byteLength(text));
    for (let pos = 0; pos <= offset + 2; pos++) {
      const entry = starts.get(pos);
      assert.equal(runtime('string_get')(value, nat(pos)), entry?.char.codePointAt(0) ?? 65);
      sameNat(runtime('string_next')(value, nat(pos)), pos + (entry?.width ?? 1));
      assert.equal(runtime('string_at_end')(value, nat(pos)), Number(pos >= offset));
      for (let end = 0; end <= offset + 2; end++) {
        const expected = pos >= end || !entry ? '' :
          chars.slice(entry.index, starts.get(end)?.index ?? chars.length).join('');
        eq(runtime('string_extract')(value, nat(pos), nat(end)), expected);
      }
    }
    for (const huge of [1n << 32n, (1n << 70n) + 1n]) {
      assert.equal(runtime('string_get')(value, nat(huge)), 65);
      sameNat(runtime('string_next')(value, nat(huge)), huge + 1n);
      assert.equal(runtime('string_at_end')(value, nat(huge)), 1);
      eq(runtime('string_extract')(value, nat(huge), nat(huge + 1n)), '');
      eq(runtime('string_extract')(value, nat(0), nat(huge)), text);
    }
    eq(runtime('string_append')(value, string('é😀')), text + 'é😀');
    eq(runtime('string_push')(value, 0x10ffff), text + String.fromCodePoint(0x10ffff));
    eq(value, text);
  }
  for (const cp of [0, 0x7f, 0x80, 0x7ff, 0x800, 0xd7ff, 0xe000, 0xffff, 0x10000, 0x10ffff])
    eq(runtime('string_singleton')(cp), String.fromCodePoint(cp));
  const builder = e.__ps_selfhost_string_new(2);
  e.__ps_selfhost_string_set(builder, 0, 65);
  e.__ps_selfhost_string_set(builder, 1, 0x1f600);
  const finished = e.__ps_selfhost_string_finish(builder);
  e.__ps_selfhost_string_set(builder, 0, 66);
  eq(finished, 'A😀');
  eq(e.__ps_selfhost_string_finish(builder), 'B😀');
  for (const cp of [0xd800, 0xdfff, 0x110000, -1]) {
    assert.throws(() => e.__ps_selfhost_string_set(builder, 0, cp), WebAssembly.RuntimeError);
    assert.throws(() => runtime('string_singleton')(cp), WebAssembly.RuntimeError);
  }
  assert.throws(() => runtime('string_size_add')(-1, 1), WebAssembly.RuntimeError);
  assert.equal(runtime('string_size_add')(0x7fffffff, 1) >>> 0, 0x80000000);
  // Bounded diagnostic, not a deployment performance threshold or theorem.
  const long = 'aé中😀'.repeat(10000), value = string(long);
  const start = performance.now();
  let pos = nat(0), count = 0, sum = 0;
  while (!runtime('string_at_end')(value, pos)) {
    sum += runtime('string_get')(value, pos);
    pos = runtime('string_next')(value, pos);
    count++;
  }
  assert.equal(count, Array.from(long).length);
  assert.equal(sum, Array.from(long).reduce((total, char) => total + char.codePointAt(0), 0));
  assert.equal(number(pos), Buffer.byteLength(long));
  console.log('PSC_WASM_UTF8_RUNTIME: PASS (' + count + ' scalars, ' +
    Math.round(performance.now() - start) + ' ms observed traversal)');
} finally {
  await rm(temp, { recursive: true, force: true });
}
