import assert from 'node:assert/strict';
import { test } from 'node:test';
import { readFileSync } from 'node:fs';
import { checkAdmissionsWithKernel } from './checked-kernel-provider.mjs';
import { checkOwnedAdmissions } from './checked-owned-kernel.mjs';

const N=v=>({k:'s',p:{k:'a'},v}), nested=(n,v)=>({k:'s',p:N(n),v});
const Z={k:'z'}, S=o=>({k:'s',o}), P=n=>({k:'p',n:N(n)}), U=l=>({k:'sort',l});
const C=(n,ls=[])=>({k:'const',n:typeof n==='string'?N(n):n,ls});
const app=(f,...args)=>args.reduce((f,a)=>({k:'app',f,a}),f);
const binder=(k,n,t,b)=>({k,n:N(n),t,b,bi:'default'});
const wire=admissions=>JSON.stringify({format:'proofscript-checked-admissions',version:2,admissions});
const def=(n,t,v)=>({kind:'constant',declaration:{k:'definition',n:N(n),lp:[],t,v,s:'safe',h:{k:'regular',h:'1'}}});
const unit=()=>({kind:'inductive',declaration:{lp:[N('u')],np:0,ts:[{n:N('Unit'),t:U(P('u')),cs:[{n:nested('Unit','unit'),t:C('Unit',[P('u')])}]}]}});
const family=()=>C('Unit',[S(Z)]), ctor=()=>C(nested('Unit','unit'),[S(Z)]);
const iota=()=>app(C(nested('Unit','rec'),[S(S(Z)),S(Z)]),binder('lam','major',family(),U(S(Z))),U(Z),ctor());

test('explicit owned kernel admits a polymorphic unit, constructor use and generated iota', async()=>{
  const entries=[unit(),def('Value',family(),ctor()),def('Reduce',U(S(Z)),iota())];
  const {result,descriptor}=await checkAdmissionsWithKernel(wire(entries),'pskernel-core.old3');
  assert.equal(descriptor.selector,'pskernel-core.old3');
  assert.equal(result.profile,'owned-uniform-algebraic/11');
  assert.equal(result.accepted,true,JSON.stringify(result));
  assert.equal(result.admissionCount,3);
});
for(const [label,change] of [
  ['term parameters',d=>{d.np=1;}],
  ['mutual families',d=>{d.ts.push(structuredClone(d.ts[0]));}],
  ['no constructor',d=>{d.ts[0].cs=[];}],
  ['multiple constructors',d=>{d.ts[0].cs.push(structuredClone(d.ts[0].cs[0]));}],
  ['indexed family',d=>{d.ts[0].t=binder('forall','A',U(S(Z)),U(S(Z)));}],
  ['forged reduction metadata',d=>{d.ts[0].recursor={accepted:true};}],
  ['unknown constructor result',d=>{d.ts[0].cs[0].t=C('Unknown');}],
  ['wrong constructor universe',d=>{d.ts[0].cs[0].t.ls=[S(P('u'))];}],
  ['duplicate level parameters',d=>{d.lp.push(N('u'));}],
])test('unit production boundary rejects '+label,async()=>{
  const entry=unit();change(entry.declaration);
  const {result,descriptor}=await checkAdmissionsWithKernel(wire([entry]),'pskernel-core.old3');
  assert.equal(descriptor.selector,'pskernel-core.old3');assert.equal(result.accepted,false,JSON.stringify(result));
  assert.equal(result.admissionIndex,0);assert.equal(result.environment,undefined);
});
test('unit exhaustion and later rejection expose no partial environment',async()=>{
  const accepted=await checkOwnedAdmissions(wire([unit()]));assert.equal(accepted.accepted,true);
  const short=await checkOwnedAdmissions(wire([unit()]),{maxSteps:accepted.steps-1});
  assert.equal(short.errorKind,'outOfFuel');assert.equal(short.accepted,false);
  assert.equal((await checkOwnedAdmissions(wire([unit()]),{maxSteps:accepted.steps})).accepted,true);
  const bad=await checkOwnedAdmissions(wire([unit(),def('Bad',U(Z),U(Z))]));
  assert.equal(bad.accepted,false);assert.equal(bad.admissionIndex,1);assert.equal(bad.environment,undefined);
  const fresh=await checkOwnedAdmissions(wire([def('Use',family(),ctor())]));
  assert.equal(fresh.accepted,false);assert.equal(fresh.errorKind,'unknownConstant');
});
test('actual preserved unit and PsSourcePos bootstrap prefix passes owned record admission',async()=>{
  const admissions=JSON.parse(readFileSync(new URL('./fixtures/owned-bootstrap-prefix.json',import.meta.url)));
  const first=await checkOwnedAdmissions(wire(admissions.slice(0,1)));
  assert.equal(first.accepted,true,JSON.stringify(first));assert.equal(first.admissionCount,1);
  const next=await checkOwnedAdmissions(wire(admissions));
  assert.equal(next.accepted,true,JSON.stringify(next));assert.equal(next.admissionCount,2);
});
