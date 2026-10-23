import assert from 'node:assert/strict';import fs from 'node:fs';import path from 'node:path';import {pathToFileURL} from 'node:url';
import {sha} from '../host-tools/generated-target-tools.mjs';
const root=path.resolve('dist/js-statement-tests'),current=await import(pathToFileURL(path.join(root,'current.mjs'))),legacy=await import(pathToFileURL(path.join(root,'legacy.mjs')));
assert.deepEqual(Object.keys(current).sort(),Object.keys(legacy).sort());
const expected=JSON.parse(fs.readFileSync(path.join(root,'native-values.json')));
function observe(m,n){return [m.helperLoop(n),m.nonTail(n),m.runCaptureValue(n),m.runCaptureFunction(n),
 m.shadowHelper(n),m.tailAlias(n),m.escapingAlias(n),m.matchHelper(n),m.stateCollision(n,99n),
 m.letCollision(n,99n),m.matchCollision(n,99n),m.pureCount(n,0n)];}
let comparisons=0;
for(let n=0;n<expected.length;n++){
 const a=observe(current,BigInt(n)),b=observe(legacy,BigInt(n));
 assert.deepEqual(a,b);assert.deepEqual(a,expected[n].map(BigInt));comparisons+=a.length;
 assert.equal(current.evenLoop(BigInt(n)),n%2===0);assert.equal(current.oddLoop(BigInt(n)),n%2!==0);
}
// Actual Node execution must keep both tail and non-tail paths off native stack.
for(const m of [current,legacy]){
 assert.equal(m.helperLoop(100000n),0n);assert.equal(m.tailAlias(100000n),0n);
 assert.equal(m.evenLoop(100001n),false);assert.equal(m.nonTail(30000n),30000n);
 assert.equal(m.runCaptureValue(1000n),1n);assert.equal(m.runCaptureFunction(1000n),1000n);
}
const text=fs.readFileSync(path.join(root,'current.mjs'),'utf8'),old=fs.readFileSync(path.join(root,'legacy.mjs'),'utf8');
assert.ok(text.includes('function* __ps$impl$helperLoop'));
assert.ok(text.includes('const [n] = __ps$tail$state'));
const wrappers=s=>(s.match(/yield\* \(function\*/g)||[]).length;
assert.ok(wrappers(text)<wrappers(old),'statement path did not remove per-let generator wrappers');
const receipt={schema:'psc1-js-generator-statements-regression/1',testedCommit:process.env.GITHUB_SHA,
 comparisons,nativeReferenceRows:expected.length,legacySourceSha256:sha(old),sourceSha256:sha(text),
 generatorLetWrappers:{legacy:wrappers(old),current:wrappers(text)},
 checks:['strict original/target IR','native reference plus retained emitter','value/function captures and shadowing','tail/non-tail/mutual stack safety','alias/freshness/fuel refusals','legacy pure source identity'],selfHostQualification:false};
fs.writeFileSync(path.join(root,'receipt.json'),JSON.stringify(receipt,null,2)+'\n');
console.log('PSC1_JS_STATEMENT_REGRESSION: '+JSON.stringify(receipt));

// Differential view-loop execution includes invalid/interior byte offsets and
// cold/evicted cache states; valid full equality also has native Lean evidence.
const nativeStrings=JSON.parse(fs.readFileSync(path.join(root,'native-strings.json')));
let stringComparisons=0;
for(const [left,right,wanted] of nativeStrings){
 assert.equal(current.viewEqual(10000n,left,right,0n,0n),wanted);
 assert.equal(legacy.viewEqual(10000n,left,right,0n,0n),wanted);
 for(const fuel of [0n,1n,2n,8n]){
  for(const lp of [0n,1n,2n,4n,9n,99n]){
   for(const rp of [0n,1n,3n,5n,99n]){
    assert.equal(current.viewEqual(fuel,left,right,lp,rp),legacy.viewEqual(fuel,left,right,lp,rp));
    stringComparisons++;
   }
  }
 }
}
for(const [value] of nativeStrings){
 for(const fuel of [0n,1n,3n,20n]){
  for(const pos of [0n,1n,2n,3n,4n,99n]){
   assert.equal(current.viewChecksum(fuel,value,pos,0n),legacy.viewChecksum(fuel,value,pos,0n));
   assert.equal(current.viewFresh(fuel,value,pos,0n,99n),legacy.viewFresh(fuel,value,pos,0n,99n));
   assert.equal(current.movingSource(fuel,value,pos),legacy.movingSource(fuel,value,pos));
   assert.equal(current.shadowSource(fuel,value,pos),legacy.shadowSource(fuel,value,pos));
   stringComparisons+=4;
  }
 }
}
const debug=String.raw`
let __testLookups=0; const __testOriginalUtf8=__ps$utf8;
__ps$utf8=(text)=>{__testLookups++;return __testOriginalUtf8(text);};
export function __testReset(){__testLookups=0;__ps$lastUtf8=undefined;__ps$previousUtf8=undefined;}
export function __testState(){return {lookups:__testLookups,views:[__ps$lastUtf8,__ps$previousUtf8].filter(Boolean).length};}
`;
for(const [name,source] of [['debug-current',text],['debug-legacy',old]])
 fs.writeFileSync(path.join(root,name+'.mjs'),source+debug);
const debugCurrent=await import(pathToFileURL(path.join(root,'debug-current.mjs')));
const debugLegacy=await import(pathToFileURL(path.join(root,'debug-legacy.mjs')));
const large='abcλ🙂'.repeat(2000),equalCopy=Array.from(large).join('');
const events={};
for(const [name,module] of [['current',debugCurrent],['legacy',debugLegacy]]){
 module.__testReset();assert.equal(module.viewEqual(100000n,large,equalCopy,0n,0n),true);
 events[name]=module.__testState();
 assert.ok(events[name].views<=2);
 module.__testReset();
 for(let i=0;i<100;i++)module.viewSizeOnly(3n,'size-only-'+i,0n);
 assert.deepEqual(module.__testState(),{lookups:0,views:0});
 for(const s of ['cold λ','other 🙂','third 𝄞','cold λ']){
  assert.equal(module.viewChecksum(100n,s,0n,0n),current.viewChecksum(100n,s,0n,0n));
  assert.ok(module.__testState().views<=2);
 }
}
assert.equal(events.current.lookups,2);
assert.ok(events.legacy.lookups>10000);
assert.ok(text.includes('__ps$viewToken$0'));
const viewReceipt={schema:'psc1-js-lazy-utf8-loop-regression/1',testedCommit:process.env.GITHUB_SHA,
 sourceSha256:sha(text),legacySourceSha256:sha(old),stringComparisons,nativeStringPairs:nativeStrings.length,
 cacheKeyLookups:events,checks:['unchanged source String equality','native equality/reference emitter',
 'alias-aware invariant recursive arguments','cold and evicted caches; at most two views',
 'interior/out-of-range/fuel offsets','size-only non-admission','freshness and changing/shadowed source fallback'],
 selfHostQualification:false};
fs.writeFileSync(path.join(root,'view-receipt.json'),JSON.stringify(viewReceipt,null,2)+'\n');
console.log('PSC1_JS_VIEW_REGRESSION: '+JSON.stringify(viewReceipt));

// Real driver transitions, including unregistered foreign functions, must retain
// exact-once callee/operand order, native trap escape and tail/non-tail results.
let dispatchComparisons=0;
for(const module of [current,legacy]){
 for(const n of [0n,1n,7n,123n]){
  for(const name of ['orderedTail','orderedNonTail']){
   let trace=[];
   const make=x=>{trace.push('callee:'+x);return (a,b)=>{trace.push('apply:'+a+':'+b);return a*10n+b;};};
   const operand=x=>{trace.push('arg:'+x);return x;};
   const expected=(n+1n)*10n+n+2n+(name==='orderedNonTail'?1n:0n);
   assert.equal(module[name](make,operand,n),expected);
   assert.deepEqual(trace,['callee:'+n,'arg:'+(n+1n),'arg:'+(n+2n),'apply:'+(n+1n)+':'+(n+2n)]);
   dispatchComparisons++;
   trace=[];
   const throwing=x=>{trace.push('arg:'+x);if(x===n+1n)throw Error('operand-trap');return x;};
   assert.throws(()=>module[name](make,throwing,n),/operand-trap/);
   assert.deepEqual(trace,['callee:'+n,'arg:'+(n+1n)]);
   trace=[];
   const failedMake=x=>{trace.push('callee:'+x);throw Error('callee-trap');};
   assert.throws(()=>module[name](failedMake,operand,n),/callee-trap/);
   assert.deepEqual(trace,['callee:'+n]);
   trace=[];
   const failedApply=x=>{trace.push('callee:'+x);return(a,b)=>{trace.push('apply');throw Error('apply-trap');};};
   assert.throws(()=>module[name](failedApply,operand,n),/apply-trap/);
   assert.deepEqual(trace,['callee:'+n,'arg:'+(n+1n),'arg:'+(n+2n),'apply']);
   dispatchComparisons+=3;
  }
 }
}
const delegated=s=>(s.match(/yield\* __ps\$(?:invoke|tailInvoke)\(/g)||[]).length;
assert.equal(delegated(text),0,'compiler still delegates calls through generator helpers');
assert.ok(delegated(old)>0);
assert.ok(text.includes('(yield { fn: '));
const dispatchReceipt={schema:'psc1-js-direct-driver-dispatch/1',testedCommit:process.env.GITHUB_SHA,
 sourceSha256:sha(text),legacySourceSha256:sha(old),dispatchComparisons,
 delegatedCallSites:{current:delegated(text),legacy:delegated(old)},
 checks:['original and target strict IR','retained emitter and native arithmetic references',
 'callee and operands exactly once left-to-right','unregistered function return value',
 'tail and non-tail foreign trap escape','deep mutual/non-tail/capture regressions retained'],
 scope:'typed-IR backend regression; not independent source-ABI admission or self-host qualification',
 selfHostQualification:false};
fs.writeFileSync(path.join(root,'dispatch-receipt.json'),JSON.stringify(dispatchReceipt,null,2)+'\n');
console.log('PSC1_JS_DIRECT_DISPATCH: '+JSON.stringify(dispatchReceipt));
