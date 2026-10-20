import test from 'node:test';
import assert from 'node:assert/strict';
import { realpathSync, readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
// Test tooling only: all compiler/library implementations are written in Lean.
import * as native from '@proofscript/pskernel-lean';
import * as wasm from '@proofscript/pskernel-lean-wasm';

test('both kernel npm specifiers resolve to the copied V6 workspace packages', () => {
  const expectedPin = '293d5d0c0c3f3dded4688b3ccd6a33939ac5102b';
  for (const name of ['pskernel-lean', 'pskernel-lean-wasm']) {
    const specifier = '@proofscript/' + name;
    const actual = realpathSync(fileURLToPath(import.meta.resolve(specifier)));
    const expected = realpathSync(fileURLToPath(new URL('../packages/' + name + '/index.mjs', import.meta.url)));
    assert.equal(actual, expected, 'Kernel provider import must resolve to local V6 copy');
    const packageRoot = new URL('../packages/' + name + '/', import.meta.url);
    const meta = JSON.parse(readFileSync(new URL('package.json', packageRoot), 'utf8'));
    assert.equal(meta.name, specifier);
    assert.equal(meta.version, '4.34.0');
    const pin = JSON.parse(readFileSync(new URL('LEAN_SOURCE_PIN.json', packageRoot), 'utf8'));
    assert.equal(pin.commit ?? pin.leanCommit, expectedPin);
  }
});

const format = 'proofscript-checked-admissions';
const EMPTY = JSON.stringify({admissions:[],format,version:2})+'\n';
const UNSUPPORTED = JSON.stringify({
  admissions:[{kind:'unrecognized',declaration:{}}],format,version:2,
})+'\n';
const name = x => ({k:'s',p:{k:'a'},v:x});
const bvar = i => ({k:'b',i});
const prop = {k:'sort',l:{k:'z'}};
function theorem(proofIndex) {
  return JSON.stringify({
    admissions:[{kind:'constant',declaration:{
      k:'theorem',lp:[],n:name('PscvOracle.Identity'),
      t:{k:'forall',n:name('P'),t:prop,bi:'default',
        b:{k:'forall',n:name('h'),t:bvar(0),bi:'default',b:bvar(1)}},
      v:{k:'lam',n:name('P'),t:prop,bi:'default',
        b:{k:'lam',n:name('h'),t:bvar(0),bi:'default',b:bvar(proofIndex)}},
    }}],format,version:2,
  })+'\n';
}
for (const [transport,checker] of [
  ['native',source => native.checkCanonicalAdmissions(source,{
    env:{},allowSourceCheckoutFallback:false,timeoutMs:30000})],
  ['wasm',source => wasm.checkCanonicalAdmissions(source,{timeoutMs:30000})]
]) {
  test('pinned independent Lean 4.34 provider '+transport+' accepts valid proof term',async()=>{
    const r=await checker(theorem(0));
    assert.equal(r.accepted,true);
    assert.equal(r.leanVersion,'4.34.0');
    assert.equal(r.protocol,'pskernel-lean/1');
  });
  test('pinned independent Lean 4.34 provider '+transport+' rejects incorrect proof term',async()=>{
    const r=await checker(theorem(1));
    assert.equal(r.accepted,false);
    assert.equal(typeof r.errorKind,'string');
  });
  test('pinned independent Lean 4.34 provider '+transport+' accepts empty module',async()=>{
    const r=await checker(EMPTY);
    assert.equal(r.accepted,true);
  });
  test('pinned independent Lean 4.34 provider '+transport+' rejects unsupported Core admission',async()=>{
    const r=await checker(UNSUPPORTED);
    assert.equal(r.accepted,false);
  });
}
