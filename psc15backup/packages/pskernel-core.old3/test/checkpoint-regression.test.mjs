// Regression tests for defects found when reproducing the previous tarball.
import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';import os from 'node:os';import path from 'node:path';
import {root,sha256,checkedTool,sourceClosure,verifySource,readSources,maskNonCode} from '../scripts/source.mjs';
import {natural,expr,definitions} from '../scripts/ground-oracle.mjs';
import {k,naturalValue} from './binding-values.mjs';
import {runtimeLevel} from './fixture-values.mjs';
import {Z,P,S,M,I,decodeLevel} from './universe-values.mjs';

test('both oracle compatibility helpers are exported and verify the same exact closure',()=>{
 assert.deepEqual(verifySource(),readSources().manifest);assert.equal(sourceClosure(),readSources().flat);
});
test('pinned-tool helper rejects a missing executable or missing digest',()=>{
 assert.throws(()=>checkedTool(undefined,'0'.repeat(64),'TOOL'),/PIN_REQUIRED/);
 assert.throws(()=>checkedTool('/no/tool',undefined,'TOOL'),/PIN_REQUIRED/);
 assert.throws(()=>checkedTool('/no/tool','not-a-digest','TOOL'),/PIN_REQUIRED/);
});
test('pinned-tool helper verifies bytes and executable permissions without launching anything',()=>{
 const tmp=fs.mkdtempSync(path.join(os.tmpdir(),'pskernel-pin-'));
 try{const file=path.join(tmp,'tool');const bytes='#!/bin/sh\nexit 0\n';fs.writeFileSync(file,bytes,{mode:0o700});
 assert.equal(checkedTool(file,sha256(bytes),'TOOL'),fs.realpathSync(file));
 assert.throws(()=>checkedTool(file,'0'.repeat(64),'TOOL'),/DIGEST_MISMATCH/);
 fs.appendFileSync(file,'# changed\n');assert.throws(()=>checkedTool(file,sha256(bytes),'TOOL'),/DIGEST_MISMATCH/);
 fs.chmodSync(file,0o600);assert.throws(()=>checkedTool(file,sha256(fs.readFileSync(file)),'TOOL'));
 }finally{fs.rmSync(tmp,{recursive:true,force:true});}
});
test('oracle scripts use the actual named provider digest in TOOLCHAIN',()=>{
 const pin=JSON.parse(fs.readFileSync(path.join(root,'manifests/TOOLCHAIN.json')));
 assert.match(pin.leanProviderSha256,/^[a-f0-9]{64}$/);
 for(const file of ['semantic-oracle.mjs','level-differential.mjs','ground-oracle.mjs','checker-differential.mjs']){
 const source=fs.readFileSync(path.join(root,'scripts',file),'utf8');
 assert.ok(source.includes('leanProviderSha256'),file);assert.ok(!source.includes('oracleProviderSha256'),file);
 }
});
test('semantic source does not depend on opaque host Bool/ite computations',()=>{
 for(const file of ['Natural.lean','Universe.lean']){
 const code=maskNonCode(fs.readFileSync(path.join(root,'src/Ps/Kernel',file),'utf8'));
 assert.doesNotMatch(code,/\b(?:Bool|if|ite)\b/);assert.match(code,/PsKernelFlag\./);
 }
});
for(const [label,base] of [['zero',Z],['param',P('u')],['max',M(P('u'),P('v'))],['imax',I(P('u'),P('v'))]]){
 test(`offset stripping retains current recursive child, not outer scrutinee: ${label}`,()=>{
 const value=S(S(base));const out=k.psKernelLevelOffset(runtimeLevel(k,value));
 assert.deepEqual(decodeLevel(out.base),base);assert.equal(naturalValue(out.count),2n);
 });
}
test('offset source handles all non-successor constructors explicitly',()=>{
 const source=maskNonCode(fs.readFileSync(path.join(root,'src/Ps/Kernel/Universe.lean'),'utf8'));
 const body=source.slice(source.indexOf('def psKernelLevelOffset'),source.indexOf('def psKernelLevelNeverZero'));
 assert.doesNotMatch(body,/\|\s*_\s*=>/);
 for(const name of ['zero','param','max','imax'])assert.ok(body.includes('| PsKernelLevel.'+name));
});
test('owned raw natural serialization preserves exact large values and rejects negatives',()=>{
 assert.notDeepEqual(natural('9007199254740993'),natural('9007199254740992'));
 assert.throws(()=>natural(-1),/NEGATIVE_NATURAL/);
 assert.equal(expr(['b','9007199254740993']).k,'app');
 assert.equal(definitions([]).k,'app');
});
test('no public entry point is added by the internal checker milestone',async()=>{
 const api=await import('@proofscript/pskernel-core.old3');assert.deepEqual(Object.keys(api),['kernelInfo']);
 const capabilities=JSON.parse(fs.readFileSync(path.join(root,'manifests/CAPABILITIES.json')));
 assert.equal(capabilities.authoritative,false);assert.equal(capabilities.selfHosted,false);
 assert.equal(capabilities.releaseGates['term-checking'].status,'partial');
 assert.equal(capabilities.releaseGates['conversion'].status,'partial');
});
