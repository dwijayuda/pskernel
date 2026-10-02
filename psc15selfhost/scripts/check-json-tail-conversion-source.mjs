import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
for (const file of ['packages/bridge/src/Ps/Bridge/Json.lean',
  'packages/pskernel-lean-wasm/source/proofscript/bridge/Ps/Bridge/Json.lean']) {
  const source = await readFile(new URL(`../${file}`, import.meta.url), 'utf8');
  const worker = source.slice(source.indexOf('def psJsonStringCharsAccWithFuel'), source.indexOf('def psJsonStringToChars'));
  const markers = ['psJsonReverseChars charsRev',
    'smaller value (psJsonStringNext value position)\n            (List.cons (psJsonStringGet value position) charsRev)',
    'psJsonStringCharsAccWithFuel fuel value position List.nil'];
  const validate = text => { for (const marker of markers) assert(text.includes(marker), `${file}: missing tail-conversion guard`); };
  validate(worker);
  for (const marker of markers) assert.throws(() => validate(worker.replaceAll(marker, 'removed')));
  const count = source.slice(source.indexOf('def psJsonCharListLengthAcc'), source.indexOf('def psJsonParse\n'));
  for (const marker of ['psJsonCharListLengthAcc rest', 'smaller (Nat.succ count)', 'psJsonCharListLengthAcc chars 0']) {
    assert(count.includes(marker), `${file}: missing tail-count guard`);
  }
  assert(!count.includes('Nat.succ (psJsonCharListLength rest)'), `${file}: input-sized stack recursion`);
}
console.log('PSC2_JSON_TAIL_CONVERSION_SOURCE: PASS (bounded tail accumulation and ordered portable output)');
