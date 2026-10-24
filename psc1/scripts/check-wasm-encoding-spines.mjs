import assert from 'node:assert/strict';import fs from 'node:fs';
const source=fs.readFileSync('packages/backend-wasm/src/Ps/BackendWasm/BinaryBytes.lean','utf8');
for(const name of ['psListFlatMapExcept','psWasmEncodeByteChunks','psWasmEncodeUtf8Chars']){
 const line=source.indexOf('def '+name+'\n');
 const start=line>=0?line:source.indexOf('def '+name+' '),next=source.indexOf('\ndef ',start+5);
 assert.ok(start>=0,name);
 const body=source.slice(start,next<0?source.length:next);
 assert.ok(body.includes(name+'Acc'),name+' must use fully applied accumulator');
 assert.equal((body.match(new RegExp(name+'\\b','g'))||[]).length,1,name+' recursive spine regressed');
}
console.log('PSC1_WASM_ENCODING_SPINE_GUARD: three public encoder APIs delegate to applied accumulators');
