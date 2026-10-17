// Independent aggregate interface, encoding and allocation-lifetime checks.
import assert from 'node:assert/strict';
import { readFile, writeFile } from 'node:fs/promises';
import { spawnSync } from 'node:child_process';
import path from 'node:path';
const directory = path.resolve(process.argv[2]);
const stem = path.join(directory, 'aggregate');
function run(tool, args) {
  const result = spawnSync(tool, args, {encoding:'utf8', maxBuffer:16*1024*1024});
  assert.equal(result.status, 0, tool + ' ' + args.join(' ') + '\n' + result.stderr);
  return result.stdout.trim();
}
const declared = run('wasm-tools', ['component','wit',stem+'.wit']);
const extracted = run('wasm-tools', ['component','wit',stem+'.wasm']);
await writeFile(stem+'.extracted.wit', extracted+'\n');
// Package/world labels are not stored in a component; interface members and
// their complete type graph remain exact. Normalize only those outer labels.
const normalize = s => s.replace(/^package [^;]+;/m,'').replace(/world [\w-]+ \{/,'world application {').replace(/\/\/[^\n]*/g,'').replaceAll('%','').replace(/\s/g,'');
assert.equal(normalize(extracted), normalize(declared), 'complete extracted aggregate world');
for (const kind of ['', '.core']) {
  run('wasm-tools', ['validate',stem+kind+'.wasm']);
  run('wasm-tools', ['parse',stem+kind+'.wat','-o',stem+kind+'.roundtrip.wasm']);
  run('wasm-tools', ['validate',stem+kind+'.roundtrip.wasm']);
  {
    for (const suffix of ['', '.roundtrip']) run('wasm-tools', ['strip','--delete','^(name|component-name)$',stem+kind+suffix+'.wasm','-o',stem+kind+suffix+'.stripped.wasm']);
    assert.deepEqual(await readFile(stem+kind+'.stripped.wasm'), await readFile(stem+kind+'.roundtrip.stripped.wasm'));
  }
  if (!kind) {
    assert.equal(normalize(run('wasm-tools',['component','wit',stem+'.roundtrip.wasm'])), normalize(declared));
  }
}
const bytes = await readFile(stem+'.core.wasm');
const fresh = async () => (await WebAssembly.instantiate(bytes, {})).instance.exports;
const api = await fresh();
// i64 scalar results retain their width, including post-return. Variant
// payload slots join u8/u64 to i64, then narrow for the selected u8 case.
const wide = (1n << 64n) - 1n;
assert.equal(BigInt.asUintN(64, api.echoWide(wide)), wide);
api.__ps_abi_post_return_i64(wide);
let unsignedResult = api.echoUnsignedBox(255, wide);
let unsignedView = new DataView(api.memory.buffer);
assert.equal(unsignedView.getUint8(unsignedResult), 255);
assert.equal(unsignedView.getBigUint64(unsignedResult + 8, true), wide);
api.__ps_abi_post_return(unsignedResult);
for (const [tag, value] of [[0,255n],[1,wide]]) {
  unsignedResult = api.echoUnsignedChoice(tag, value);
  unsignedView = new DataView(api.memory.buffer);
  assert.equal(unsignedView.getUint8(unsignedResult), tag);
  assert.equal(tag === 0 ? BigInt(unsignedView.getUint8(unsignedResult+8))
    : unsignedView.getBigUint64(unsignedResult+8,true), value);
  api.__ps_abi_post_return(unsignedResult);
}
assert.equal(BigInt.asUintN(64,api.wideResult(0,0)),wide);
api.__ps_abi_post_return_i64(wide);
assert.equal(api.__ps_abi_usage(),16);
// Float ABI slots preserve signed zero and canonicalize NaNs. Mixed variants
// exercise i32/f32 and i64/f32/f64 joins as bit transport, never numeric casts.
for (const [name, post] of [["echoFloat32","__ps_abi_post_return_f32"],
                            ["echoFloat64","__ps_abi_post_return_f64"],
                            ["echoFloatBox","__ps_abi_post_return_f64"]]) {
  for (const value of [-0, 1.25, Infinity, -Infinity, NaN]) {
    assert(Object.is(api[name](value), value), name);
    api[post](value);
  }
}
let pointer = api.echoFloatPair(-0, NaN);
let view = new DataView(api.memory.buffer);
assert.equal(view.getUint32(pointer, true), 0x80000000);
assert.equal(view.getBigUint64(pointer+8, true), 0x7ff8000000000000n);
api.__ps_abi_post_return(pointer);
for (const [tag, bits] of [[0, 0xffffffff], [1, 0x80000000], [1, 0xff800001]]) {
  pointer = api.echoFloatNarrowChoice(tag, bits);
  view = new DataView(api.memory.buffer);
  assert.equal(view.getUint8(pointer), tag);
  assert.equal(view.getUint32(pointer+4,true), tag === 1 && bits === 0xff800001 ? 0x7fc00000 : bits);
  api.__ps_abi_post_return(pointer);
}
for (const [tag, bits, expected] of [
  [0, 0xffffffffffffffffn, 0xffffffffffffffffn],
  [1, 0x80000000n, 0x80000000n], [1, 0xff800001n, 0x7fc00000n],
  [2, 0x8000000000000000n, 0x8000000000000000n],
  [2, 0xfff0000000000001n, 0x7ff8000000000000n]]) {
  pointer = api.echoFloatWideChoice(tag, bits);
  view = new DataView(api.memory.buffer);
  assert.equal(view.getUint8(pointer), tag);
  assert.equal(tag === 1 ? BigInt(view.getUint32(pointer+8,true)) : view.getBigUint64(pointer+8,true), expected);
  api.__ps_abi_post_return(pointer);
}
pointer = api.__ps_abi_realloc(0,0,4,68);
view = new DataView(api.memory.buffer);
for (let i=0;i<17;i++) view.setFloat32(pointer+4*i, i === 16 ? -0 : i, true);
assert(Object.is(api.manyFloats(pointer), -0));
api.__ps_abi_post_return_f32(-0);
pointer = api.__ps_abi_realloc(0,0,4,8);
view = new DataView(api.memory.buffer);
view.setUint32(pointer, 0x80000000, true);
view.setUint32(pointer+4, 0xff800001, true);
const arrayResult = api.echoFloatArray(pointer,2);
view = new DataView(api.memory.buffer);
const arrayData = view.getUint32(arrayResult,true);
assert.equal(view.getUint32(arrayResult+4,true),2);
assert.equal(view.getUint32(arrayData,true),0x80000000);
assert.equal(view.getUint32(arrayData+4,true),0x7fc00000);
api.__ps_abi_post_return(arrayResult);
assert.equal(api.__ps_abi_usage(),16);

const encoder = new TextEncoder(), decoder = new TextDecoder('utf8', {fatal:true});
const text = 'é🙂'.repeat(16384), encoded = encoder.encode(text);
let stablePages;
for (let i=0;i<64;i++) {
  assert.equal(api.__ps_abi_usage(),16);
  const input = api.__ps_abi_realloc(0,0,1,encoded.length) >>> 0;
  new Uint8Array(api.memory.buffer).set(encoded,input);
  const result = api.echoText(input,encoded.length) >>> 0;
  const view = new DataView(api.memory.buffer);
  const pointer = view.getUint32(result,true), length = view.getUint32(result+4,true);
  assert.equal(decoder.decode(new Uint8Array(api.memory.buffer,pointer,length)),text);
  assert(api.__ps_abi_usage()>16, 'output remains live before post-return');
  const pages = api.memory.buffer.byteLength;
  if (stablePages !== undefined) assert.equal(pages,stablePages,'arena reaches a stable high-water mark');
  stablePages = pages;
  api.__ps_abi_post_return(result);
  assert.equal(api.__ps_abi_usage(),16);
}
for (const invalid of [[0xc0,0x80],[0xed,0xa0,0x80],[0xf4,0x90,0x80,0x80],[0xe2,0x82]]) {
  const instance = await fresh();
  const pointer = instance.__ps_abi_realloc(0,0,1,invalid.length);
  new Uint8Array(instance.memory.buffer).set(invalid,pointer);
  assert.throws(()=>instance.echoText(pointer,invalid.length),WebAssembly.RuntimeError);
}
const refused = [
  ['misaligned list', x => x.echoNatural(17,1)],
  ['out-of-range buffer', x => x.echoText(x.memory.buffer.byteLength,1)],
  ['overflowed list', x => x.echoArray(16,0x40000000)],
  ['natural resource bound', x => x.echoNatural(16,134217728)],
  ['invalid bool before narrowing', x => x.echoInteger(256,0,0)],
  ['invalid Unicode scalar', x => x.echoChar(0xd800)],
  ['invalid variant tag', x => x.echoChoice(256,0,0)],
  ['post-return without call', x => x.__ps_abi_post_return(0)],
  ['entry before post-return', x => { x.echoText(0,0); x.echoText(0,0); }]
];
for (const [name, call] of refused) {
  const instance = await fresh();
  assert.throws(()=>call(instance),WebAssembly.RuntimeError,name);
}
console.log(JSON.stringify({profile:'pscv0-component-c4b-memory32/1', repeatedCalls:64,
  utf8Refusals:4, boundaryRefusals:refused.length, highWaterBytes:stablePages, postReturn:true, completeWorldEqual:true}))
