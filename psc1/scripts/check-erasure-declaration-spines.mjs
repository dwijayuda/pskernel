import fs from 'node:fs';import assert from 'node:assert/strict';
const source=fs.readFileSync('packages/erasure/src/Ps/Erasure/Basic.lean','utf8');
const names=['psErasureIndexPrepend','psErasureDeclarationNameIndex','psErasureDeclarationEntryIndex'];
for(const name of names){
 const start=source.search(new RegExp('\\bdef\\s+'+name+'\\b'));assert.ok(start>=0,name);
 const declaration=source.slice(start);
 const end=declaration.indexOf('\ndef ',1),body=declaration.slice(declaration.indexOf(':='),end<0?undefined:end);
 assert.ok(body.includes('psErasureFoldRight'),name+': right-fold worker missing');
 assert.equal(new RegExp('\\b'+name+'\\b').test(body),false,name+': recursive spine reconstruction');
}
const worker=source.slice(source.indexOf('def psErasureFoldReverseWorker'),source.indexOf('def psErasureFoldRight'));
assert.ok(worker.includes('psErasureFoldReverseWorker step rest (step value state)'));
console.log('PSC1_ERASURE_DECLARATION_SPINES: 3 public APIs use the shared fully applied reverse fold');
