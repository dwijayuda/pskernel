import assert from 'node:assert/strict';
import { test } from 'node:test';
import { checkAdmissionsWithKernel } from './checked-kernel-provider.mjs';
import { checkOwnedAdmissions } from './checked-owned-kernel.mjs';

const N=v=>({k:'s',p:{k:'a'},v}), child=(n,v)=>({k:'s',p:N(n),v});
const Z={k:'z'}, S=o=>({k:'s',o}), U=l=>({k:'sort',l});
const C=(n,ls=[])=>({k:'const',n:typeof n==='string'?N(n):n,ls});
const B=i=>({k:'b',i}), app=(f,...xs)=>xs.reduce((f,a)=>({k:'app',f,a}),f);
const binder=(k,n,t,b)=>({k,n:N(n),t,b,bi:'default'});
const lam=(n,t,b)=>binder('lam',n,t,b), pi=(n,t,b)=>binder('forall',n,t,b);
const wire=admissions=>JSON.stringify({format:'proofscript-checked-admissions',version:2,admissions});
const def=(n,t,v)=>({kind:'constant',declaration:{k:'definition',n:N(n),lp:[],t,v,s:'safe',h:{k:'regular',h:'1'}}});
const numeral=(name,n)=>n===0?C(child(name,'zero')):app(C(child(name,'succ')),numeral(name,n-1));
const nat=name=>({kind:'inductive',declaration:{lp:[],np:0,ts:[{n:N(name),t:U(S(Z)),cs:[
  {n:child(name,'zero'),t:C(name)},
  {n:child(name,'succ'),t:pi('n',C(name),C(name))},
]}]}});
const fold=(name,n)=>app(C(child(name,'rec'),[S(Z)]),lam('major',C(name),C(name)),numeral(name,0),
  lam('n',C(name),lam('ih',C(name),app(C(child(name,'succ')),B(0)))),numeral(name,n));

test('explicit owned kernel checks its Nat prelude and derived recursor before user declarations',async()=>{
  const {result,descriptor}=await checkAdmissionsWithKernel(wire([
    def('First',C('Nat'),numeral('Nat',1)),def('Fold',C('Nat'),fold('Nat',4)),
  ]),'pskernel-core.old3');
  assert.equal(descriptor.selector,'pskernel-core.old3');
  assert.equal(result.profile,'owned-uniform-algebraic/11');
  assert.equal(result.accepted,true,JSON.stringify(result));
  assert.equal(result.admissionCount,2);
});
test('explicit owned kernel derives a fresh Nat-like family and checks constructor iota',async()=>{
  const result=await checkOwnedAdmissions(wire([nat('Counter'),def('Fold',C('Counter'),fold('Counter',3))]));
  assert.equal(result.accepted,true,JSON.stringify(result));assert.equal(result.admissionCount,2);
});
for(const [label,change] of [
  ['wrong constructor result',d=>{d.ts[0].cs[1].t=C('Nat');}],
  ['negative recursion',d=>{d.ts[0].cs[1].t=pi('f',pi('n',C('Counter'),C('Nat')),C('Counter'));}],
  ['higher sort',d=>{d.ts[0].t=U(S(S(Z)));}],
  ['duplicate constructors',d=>{d.ts[0].cs[1].n=d.ts[0].cs[0].n;}],
])test('Nat boundary rejects '+label+' without reference fallback',async()=>{
  const entry=nat('Counter');change(entry.declaration);
  const {result,descriptor}=await checkAdmissionsWithKernel(wire([entry]),'pskernel-core.old3');
  assert.equal(descriptor.selector,'pskernel-core.old3');assert.equal(result.accepted,false);
  assert.equal(result.admissionIndex,0);assert.equal(result.environment,undefined);
});
test('Nat initialization shares the total transition budget even for an empty module',async()=>{
  const full=await checkOwnedAdmissions(wire([]));assert.equal(full.accepted,true);assert(full.steps>2);
  const short=await checkOwnedAdmissions(wire([]),{maxSteps:full.steps-1});
  assert.equal(short.accepted,false);assert.equal(short.errorKind,'outOfFuel');assert.equal(short.admissionIndex,0);
  assert.equal((await checkOwnedAdmissions(wire([]),{maxSteps:full.steps})).accepted,true);
});
test('prelude cannot be redeclared and earlier user environments never leak',async()=>{
  const duplicate=await checkOwnedAdmissions(wire([nat('Nat')]));
  assert.equal(duplicate.accepted,false);assert.equal(duplicate.errorKind,'duplicateName');
  assert.equal((await checkOwnedAdmissions(wire([nat('Counter')]))).accepted,true);
  const fresh=await checkOwnedAdmissions(wire([def('Leak',C('Counter'),numeral('Counter',0))]));
  assert.equal(fresh.errorKind,'unknownConstant');
  const other=await checkOwnedAdmissions(wire([def('Other',U(S(Z)),C('String'))]));
  assert.equal(other.accepted,true);
  const unavailable=await checkOwnedAdmissions(wire([def('Other',U(S(Z)),C('Bool'))]));
  assert.equal(unavailable.errorKind,'unknownConstant');
});
test('later rejection retains the user admission index and exposes no partial environment',async()=>{
  const result=await checkOwnedAdmissions(wire([def('Good',C('Nat'),numeral('Nat',0)),def('Bad',U(Z),numeral('Nat',0))]));
  assert.equal(result.accepted,false);assert.equal(result.errorKind,'typeMismatch');
  assert.equal(result.admissionIndex,1);assert.equal(result.environment,undefined);
});

// The old 'wrong successor' input is a valid enum, not a malformed inductive.
// Preserve it and prove that its name does not confer Nat-like application/iota.
test('two nullary constructors named zero/succ form an enum without Nat authority',async()=>{
  const entry=nat('Counter');entry.declaration.ts[0].cs[1].t=C('Counter');
  const accepted=await checkOwnedAdmissions(wire([entry]));
  assert.equal(accepted.accepted,true,JSON.stringify(accepted));
  for(const bad of [def('BadSuccessor',C('Counter'),numeral('Counter',1)),def('BadFold',C('Counter'),fold('Counter',1))]){
    const {result,descriptor}=await checkAdmissionsWithKernel(wire([entry,bad]),'pskernel-core.old3');
    assert.equal(descriptor.selector,'pskernel-core.old3');assert.equal(result.accepted,false,JSON.stringify(result));
    assert.equal(result.admissionIndex,1);assert.equal(result.environment,undefined);
  }
});
