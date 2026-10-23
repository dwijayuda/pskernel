import assert from 'node:assert/strict';
import fs from 'node:fs';import path from 'node:path';import {pathToFileURL} from 'node:url';
import {sha,buildTarget,verifyArtifact} from '../host-tools/generated-target-tools.mjs';
import {decodeWasmHex,loadWasmArtifact,loadWasmApi} from '../host-tools/generated-wasm-transport.mjs';
const directory=path.resolve('dist/direct-selfhost-preflight');
const current=(await import(pathToFileURL(path.join(directory,'runtime-current.mjs')).href)).api;
const legacy=(await import(pathToFileURL(path.join(directory,'runtime-legacy.mjs')).href)).api;
const strings=['','ASCII','雪😀','a\u0301','\ufeff\0','"\\\t','\ud800','\udfff','x'.repeat(31)+'a','x'.repeat(31)+'b'];
let comparisons=0,maxViews=0;
for(const text of strings){
 const size=legacy.size(text);
 for(const warm of [false,true]){
  current.clear();legacy.clear();
  if(warm){current.get(text,0n);legacy.get(text,0n);}
  const before=current.retained();assert.equal(current.size(text),size);assert.equal(current.retained(),before);
  for(let raw=-2;raw<=Number(size)+2;raw++){
   const position=BigInt(raw);
   assert.equal(current.get(text,position),legacy.get(text,position));
   assert.equal(current.next(text,position),legacy.next(text,position));
   assert.equal(current.ending(text,position),legacy.ending(text,position));comparisons+=3;
   for(let stop=-2;stop<=Number(size)+2;stop++){
    const retained=current.retained();
    assert.equal(current.extract(text,position,BigInt(stop)),legacy.extract(text,position,BigInt(stop)));
    assert.equal(current.retained(),retained);comparisons++;
   }
  }
  maxViews=Math.max(maxViews,current.retained());assert.ok(maxViews<=2);
 }
}
for(let round=0;round<3;round++)for(const text of strings){
 current.get(text,0n);assert.ok(current.retained()<=2);
}
current.clear();current.size('x'.repeat(100000));assert.equal(current.retained(),0);
const graph=JSON.parse(fs.readFileSync(path.join(directory,'fixture-ir.json'),'utf8'));
const declarations=graph[4],publicNames=declarations.map(d=>d[0]);
const publicTypes=declarations.map(d=>({name:d[0],parameters:d[2].map(p=>p[1]),result:d[3]}));
const source=fs.readFileSync(path.join(directory,'fixture.wasm.hex'),'utf8');
const artifact=buildTarget({target:'wasm-core',source,directory:path.join(directory,'wasm-artifact'),
 publicNames,publicTypes,consumer:'console.log(JSON.stringify({ready:true}));'});
verifyArtifact(artifact.file,artifact.sha256);
const api=loadWasmArtifact(artifact.file);
assert.equal(api.answer,42n);assert.equal(api.huge,-9007199254740993123456789n);assert.equal(api.text,'λ🙂');
const values=[0n,1n,255n,4294967296n,(1n<<2000n)+7n];
for(const value of values){assert.equal(api.increment(value),value+1n);assert.equal(api.negate(value),-value);assert.equal(api.negate(-value),value);}
for(const text of ['','ASCII','雪😀','\ufeff\0','λ🙂'.repeat(1000)])assert.equal(api.echo(text),text);
assert.equal(api.invert(false),true);assert.equal(api.invert(true),false);
assert.throws(()=>api.echo('\ud800'),/INVALID_UNICODE_SCALAR/);
for(const bad of ['','psc1-wasm-hex/1:0','psc1-wasm-hex/1:zz','not-a-backend:0061736d01000000'])assert.throws(()=>decodeWasmHex(bad));
const importModule=Buffer.from([0,97,115,109,1,0,0,0,1,4,1,96,0,0,2,16,1,4,104,111,115,116,7,99,111,109,112,105,108,101,0,0]);
assert.throws(()=>loadWasmApi(importModule,[],[]),/NATIVE_DELEGATION_FORBIDDEN/);
const receipt={schema:'psc1-direct-selfhost-preflight/1',testedCommit:process.env.GITHUB_SHA,
 runtime:{comparisons,maxViews,legacySourceSha256:sha(fs.readFileSync(path.join(directory,'runtime-legacy.mjs'))),currentSourceSha256:sha(fs.readFileSync(path.join(directory,'runtime-current.mjs')))},
 wasm:{sourceSha256:sha(source),binarySha256:sha(decodeWasmHex(source)),artifactSha256:artifact.sha256,
 scalarExports:publicNames,checks:['strict source/target IR','owned bytes validated by pinned wasm-tools and actual Node engine','no native/compiler imports','arbitrary Nat/Int GC roundtrip','Unicode scalar copy ownership','malformed binary transport refusals']},
 selfHostQualification:false};
fs.writeFileSync(path.join(directory,'receipt.json'),JSON.stringify(receipt,null,2)+'\n');
console.log('PSC1_DIRECT_SELFHOST_PREFLIGHT: '+JSON.stringify(receipt));
