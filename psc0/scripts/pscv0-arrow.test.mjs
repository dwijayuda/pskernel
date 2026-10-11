// Regression family for anonymous arrows in declaration parameter/result
// types. This does not claim arbitrary dependent binder or term coverage.
import assert from 'node:assert/strict';
import { test } from 'node:test';
import { pathToFileURL, fileURLToPath } from 'node:url';
import path from 'node:path';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const B=await import(pathToFileURL(path.join(root,'dist/pscv0-bridge/index.js')).href);
const tag=o=>o&&typeof o==='object'?Object.getOwnPropertySymbols(o).map(k=>o[k]).find(v=>typeof v==='string'):undefined;
const ok=r=>{assert.equal(tag(r),'ok',String(r?.error));return r.value;};
const cases=[
  'function apply(f: Nat -> Nat, x: Nat): Nat := f(x)\n',
  'function apply(f: Nat -> Nat -> Nat, x: Nat, y: Nat): Nat := f(x, y)\n',
  'function apply {alpha: Type} {beta: Type}(f: alpha -> beta, x: alpha): beta := f(x)\n',
  'function keep(f: Nat -> Nat): Nat -> Nat := f\n',
];
for(const source of cases)test('anonymous Pi stays a readable arrow in '+source.trim(),()=>{
  const native=ok(B.psPscv0TranslateReadable(true,false,source));
  assert(!native.includes('(_ :'),'printer expanded an anonymous Pi into a named binder');
  const returned=ok(B.psPscv0TranslateReadable(false,true,native));
  assert.equal(ok(B.psPscv0LowerToLean(true,returned)),ok(B.psPscv0LowerToLean(true,source)));
});
