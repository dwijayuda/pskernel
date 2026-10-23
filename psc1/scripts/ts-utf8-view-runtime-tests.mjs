import assert from 'node:assert/strict';
import fs from 'node:fs';import path from 'node:path';import {pathToFileURL} from 'node:url';
import {sha,runTool} from '../host-tools/generated-target-tools.mjs';
const dir=path.resolve('dist/ts-utf8-views');
fs.writeFileSync(path.join(dir,'package.json'),JSON.stringify({type:'module',private:true}));
fs.writeFileSync(path.join(dir,'tsconfig.json'),JSON.stringify({compilerOptions:{
 target:'ES2022',module:'NodeNext',moduleResolution:'NodeNext',strict:true,noEmitOnError:true,
 declaration:true,sourceMap:true,skipLibCheck:false,types:[],lib:['ES2022','DOM'],outDir:'build'},files:['current.ts','extract-only.ts']}));
const compiled=runTool(process.execPath,[path.resolve('..','node_modules/typescript/bin/tsc'),'--project',path.join(dir,'tsconfig.json')],{logDirectory:dir});
const {probe:p,equalCurrent:current,equalLegacy:legacy}=await import(pathToFileURL(path.join(dir,'build/current.js')).href);
const strings=['','A','ASCII','雪😀','a\u0301','\ufeff\0','"\\\t','\ud800','\udfff','x'.repeat(31)+'a','x'.repeat(31)+'b'];
let comparisons=0,maxViews=0;
function check(fuel,left,right,a,b){
 p.clear();const expected=legacy(fuel,left,right,a,b),state=p.state();
 p.clear();const actual=current(fuel,left,right,a,b);
 assert.equal(actual,expected);assert.deepEqual(p.state(),state);
 maxViews=Math.max(maxViews,p.state().filter(Boolean).length);assert.ok(maxViews<=2);comparisons++;
}
for(const left of strings)for(const original of strings){
 const right=(' '+original).slice(1);
 for(const fuel of [0n,1n,2n,5n,40n])for(const a of [-1n,0n,1n,2n,3n,50n])for(const b of [0n,1n,3n,50n])check(fuel,left,right,a,b);
}
for(const text of strings){
 p.clear();let token;
 for(const other of ['first','second',text,'third',text]){
  p.view(other);const known=p.known(text,token);token=known.token;
  const snapshot=p.state();const ordinary=p.view(text);assert.deepEqual(p.state(),snapshot);
  assert.equal(known,ordinary);
  for(let n=-2;n<Number(known.size)+3;n++){
   const pos=BigInt(n);assert.equal(p.getView(known,pos),p.get(text,pos));
   assert.equal(p.nextView(known,pos),p.next(text,pos));comparisons+=2;
  }
 }
}
p.clear();assert.equal(current(0n,'x'.repeat(100000),'y'.repeat(100000),0n,0n),false);
assert.deepEqual(p.state(),[null,null]);
function timing(fn,textA,textB){
 p.clear();const t=process.hrtime.bigint();const value=fn(BigInt(textA.length+2),textA,textB,0n,0n);
 return {elapsedNs:String(process.hrtime.bigint()-t),value};
}
const left=Buffer.from('x'.repeat(100000)).toString(),right=Buffer.from('x'.repeat(100000)).toString();
const old=timing(legacy,left,right),optimized=timing(current,left,right);
assert.equal(old.value,optimized.value);assert.equal(old.value,true);
const receipt={schema:'psc1-ts-utf8-view-tokens/1',testedCommit:process.env.GITHUB_SHA,
 comparisons,maxViews,checks:['unchanged fuel-zero laziness','all tested Unicode/raw positions','equal separately allocated strings',
 'identical two-view cache order','evicted token fallback','actual current and legacy emitted tail loops','strict native TypeScript 7'],
 sourceSha256:sha(fs.readFileSync(path.join(dir,'current.ts'))),compiler:compiled.event,
 syntheticOnly:{characters:left.length,legacy:old,optimized},qualification:false};
fs.writeFileSync(path.join(dir,'receipt.json'),JSON.stringify(receipt,null,2)+'\n');
console.log('PSC1_TS_UTF8_VIEW_RUNTIME: '+JSON.stringify(receipt));

function legacyExtract(text,start,stop){
 if(start>=stop)return "";
 let position=0n,started=false,out="";
 for(const char of text){
  const code=char.codePointAt(0)??0;
  const width=BigInt(code<=0x7f?1:code<=0x7ff?2:code<=0xffff?3:4);
  if(!started){if(position===start)started=true;else{position+=width;continue;}}
  if(position===stop)return out;out+=char;position+=width;
 }
 return out;
}
const {onlyExtract}=await import(pathToFileURL(path.join(dir,'build/extract-only.js')).href);
const samples=[...strings];let seed=0x51c1;
for(let i=0;i<48;i++){
 let text='';for(let j=0;j<4;j++){seed=(Math.imul(seed,1664525)+1013904223)>>>0;text+=String.fromCodePoint(seed%0x110000);}samples.push(text);
}
let extractionComparisons=0;
for(const text of samples){
 const size=BigInt(new TextEncoder().encode(text).length);
 p.clear();assert.equal(p.size(text),size);assert.deepEqual(p.state(),[null,null],'cold size does not admit an index');
 for(const warm of [false,true]){
  p.clear();if(warm)p.view(text);
  const state=p.state();assert.equal(p.size(text),size);assert.deepEqual(p.state(),state,'size preserves existing views');
  for(let start=-2;start<=Number(size)+2;start++)for(let stop=-2;stop<=Number(size)+2;stop++){
   const a=BigInt(start),b=BigInt(stop),expected=legacyExtract(text,a,b);
   assert.equal(p.extract(text,a,b),expected);assert.deepEqual(p.state(),state,'extraction never admits/promotes a view');
   assert.equal(onlyExtract(text,a,b),expected,'extract-only module selects its required runtime');
   extractionComparisons+=2;
  }
 }
}
p.clear();p.view('source 雪😀');const retained=p.state();
for(const text of ['run chunk','\\"','another chunk'])p.size(text);
assert.deepEqual(p.state(),retained,'size-only chunks cannot evict source cursor');
const source='x'.repeat(100000);
p.clear();p.view(source);
let legacyChecksum=0,newChecksum=0;
let before=process.hrtime.bigint();
for(let i=0;i<256;i++)legacyChecksum+=legacyExtract(source,BigInt(i*300),BigInt(i*300+30)).length;
const legacyNs=String(process.hrtime.bigint()-before);before=process.hrtime.bigint();
for(let i=0;i<256;i++)newChecksum+=p.extract(source,BigInt(i*300),BigInt(i*300+30)).length;
const cachedNs=String(process.hrtime.bigint()-before);assert.equal(newChecksum,legacyChecksum);
console.log('PSC1_TS_SIZE_EXTRACT_RUNTIME: '+JSON.stringify({schema:'psc1-ts-size-extract-runtime/1',testedCommit:process.env.GITHUB_SHA,
 extractionComparisons,maxViews:2,checks:['legacy extraction exact on cold/warm Unicode and all tested raw boundaries',
 'no index admission or promotion by extraction','size matches independent UTF8 encoding','cold size retains no views',
 'size-only chunks do not evict cursor','extract-only module runtime','all previous token/proof regressions'],
 syntheticOnly:{characters:source.length,spans:256,legacyNs,cachedNs,checksum:newChecksum},qualification:false}));
