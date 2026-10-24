import assert from 'node:assert/strict';import fs from 'node:fs';
const entries=[
 ['packages/environment/src/Ps/Environment/Basic.lean','psEnvironmentFindInListWorker'],
 ['packages/erasure/src/Ps/Erasure/Inductive.lean','psFindConstructorDeclaration'],
 ['packages/erasure/src/Ps/Erasure/Inductive.lean','psFindRecursorDeclaration']
];
function unsafe(name,body){const unsafe=new RegExp('let\\s+\\w+(?:(?!:=)[\\s\\S])*:=\\s*'+name+'\\b[^;]*;\\s*fun\\b');return unsafe.test(body);}
const retained=fs.readFileSync('test/SharedLookupPrefixReference.lean','utf8');
for(const [path,name] of entries){
 const source=fs.readFileSync(path,'utf8'),at=source.indexOf('def '+name);
 assert.ok(at>=0,name);const next=source.indexOf('\ndef ',at+5);
 assert.equal(unsafe(name,source.slice(at,next<0?source.length:next)),false,'eager shared lookup '+name);
 assert.equal(unsafe(name,retained),true,'original shared lookup must be rejected '+name);
}
console.log('PSC1_SHARED_LOOKUP_PREFIX_GUARD: three measured lookup workers defer recursive prefix; retained originals rejected');
