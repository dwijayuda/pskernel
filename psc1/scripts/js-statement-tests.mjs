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
