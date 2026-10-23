import assert from 'node:assert/strict';
import fs from 'node:fs';import path from 'node:path';import {pathToFileURL} from 'node:url';
import {sha,runTool} from '../host-tools/generated-target-tools.mjs';
const dir=path.resolve('dist/ts-utf8-views');
fs.writeFileSync(path.join(dir,'package.json'),JSON.stringify({type:'module',private:true}));
fs.writeFileSync(path.join(dir,'tsconfig.json'),JSON.stringify({compilerOptions:{
 target:'ES2022',module:'NodeNext',moduleResolution:'NodeNext',strict:true,noEmitOnError:true,
 declaration:true,sourceMap:true,skipLibCheck:false,types:[],lib:['ES2022','DOM'],outDir:'build'},files:['current.ts']}));
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
