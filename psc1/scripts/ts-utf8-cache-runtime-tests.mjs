// Exact retained/current emitted runtime comparisons. No compiler qualification claim.
import assert from 'node:assert/strict';
import fs from 'node:fs';import path from 'node:path';import {pathToFileURL} from 'node:url';
import {sha,runTool} from '../host-tools/generated-target-tools.mjs';
const directory=path.resolve('dist/ts-utf8-cache');
fs.writeFileSync(path.join(directory,'package.json'),JSON.stringify({type:'module',private:true}));
fs.writeFileSync(path.join(directory,'tsconfig.json'),JSON.stringify({
 compilerOptions:{target:'ES2022',module:'NodeNext',moduleResolution:'NodeNext',strict:true,
  noEmitOnError:true,declaration:true,sourceMap:true,skipLibCheck:false,types:[],lib:['ES2022','DOM'],outDir:'build'},
 files:['current.ts','legacy.ts']}));
const compiler=path.resolve('..','node_modules/typescript/bin/tsc');
const compiled=runTool(process.execPath,[compiler,'--project',path.join(directory,'tsconfig.json')],{logDirectory:directory});
const current=(await import(pathToFileURL(path.join(directory,'build/current.js')).href)).probe;
const legacy=(await import(pathToFileURL(path.join(directory,'build/legacy.js')).href)).probe;
const scalars=[0,7,31,32,65,127,128,2047,2048,55295,55296,56319,56320,57343,57344,65535,65536,1114111];
const strings=['','ASCII','a\r\nb','a\u0301','雪😀','\ufeff\0','"\\\t'];
for(const cp of scalars)strings.push(String.fromCodePoint(cp));
let comparisons=0,maxViews=0;
function checkState(){
 assert.deepEqual(current.state(),legacy.state(),'same view data and unchanged insertion/eviction order');
 assert.deepEqual(current.keys(),legacy.keys(),'exactly the original two retained values');
 assert.equal(current.count(),legacy.count());assert.ok(current.count()<=2);
 maxViews=Math.max(maxViews,current.count());
}
for(let round=0;round<3;round++){
 for(const original of strings){
  // Include separately allocated equal values as well as distinct Unicode values.
  const text=round===1?(' '+original).slice(1):original;
  const view=current.view(text),oldView=legacy.view(text);
  assert.deepEqual(view,oldView);
  assert.equal(view.size,BigInt(new TextEncoder().encode(text).length));checkState();
  for(let position=-3;position<=Number(view.size)+3;position++){
   const p=BigInt(position);
   assert.equal(current.get(text,p),legacy.get(text,p));checkState();
   assert.equal(current.next(text,p),legacy.next(text,p));checkState();
   comparisons+=2;
  }
 }
}
for(const text of ['one','two','one','three','two','four','one']){
 assert.deepEqual(current.view(text),legacy.view(text));checkState();
}
function measure(probe){
 probe.clear();
 const left=Buffer.from('x'.repeat(100000)+'a').toString('utf8');
 const right=Buffer.from('x'.repeat(100000)+'b').toString('utf8');
 probe.get(left,0n);probe.get(right,0n);assert.equal(probe.count(),2);
 const started=process.hrtime.bigint();let checksum=0;
 for(let i=0;i<4000;i++)checksum+=probe.get(i%2===0?left:right,BigInt(i)).charCodeAt(0);
 return {elapsedNs:String(process.hrtime.bigint()-started),checksum,views:probe.count(),characters:left.length,queries:4000};
}
const oldTiming=measure(legacy),newTiming=measure(current);
assert.equal(oldTiming.checksum,newTiming.checksum);assert.equal(newTiming.views,2);
const receipt={schema:'psc1-ts-utf8-two-view-index/1',testedCommit:process.env.GITHUB_SHA,
 comparisons,maxViews,checks:['UTF8 width classes and surrogate strings','invalid/interior/out-of-range raw offsets',
  'separately allocated equal strings','same two retained views','unchanged insertion and eviction order','strict native TypeScript 7'],
 sourceSha256:sha(fs.readFileSync(path.join(directory,'current.ts'))),
 legacySha256:sha(fs.readFileSync(path.join(directory,'legacy.ts'))),compiler:compiled.event,
 syntheticPrefixOnly:{legacy:oldTiming,indexed:newTiming},
 scope:'runtime differential evidence; actual generated compiler G1/G2/G3 qualification required separately'};
fs.writeFileSync(path.join(directory,'receipt.json'),JSON.stringify(receipt,null,2)+'\n');
console.log('PSC1_TS_UTF8_CACHE_RUNTIME: '+JSON.stringify(receipt));
