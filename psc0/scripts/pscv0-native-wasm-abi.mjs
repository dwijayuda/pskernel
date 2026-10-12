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
const normalize = s => s.replace(/\/\/[^\n]*/g,'').replaceAll('%','').replace(/\s/g,'');
assert.equal(normalize(extracted), normalize(declared), 'complete extracted aggregate world');
for (const kind of ['', '.core']) {
  run('wasm-tools', ['validate',stem+kind+'.wasm']);
  run('wasm-tools', ['parse',stem+kind+'.wat','-o',stem+kind+'.roundtrip.wasm']);
  run('wasm-tools', ['validate',stem+kind+'.roundtrip.wasm']);
  if (kind) {
    for (const suffix of ['', '.roundtrip']) run('wasm-tools', ['strip','--delete','^name$',stem+kind+suffix+'.wasm','-o',stem+kind+suffix+'.stripped.wasm']);
    assert.deepEqual(await readFile(stem+kind+'.stripped.wasm'), await readFile(stem+kind+'.roundtrip.stripped.wasm'));
  } else {
    assert.equal(normalize(run('wasm-tools',['component','wit',stem+'.roundtrip.wasm'])), normalize(declared));
  }
}
const bytes = await readFile(stem+'.core.wasm');
const fresh = async () => (await WebAssembly.instantiate(bytes, {})).instance.exports;
const api = await fresh();
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
console.log(JSON.stringify({profile:'pscv0-component-aggregate-candidate/1', repeatedCalls:64,
  utf8Refusals:4, highWaterBytes:stablePages, postReturn:true, completeWorldEqual:true}));
