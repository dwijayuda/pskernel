import test from 'node:test';
import assert from 'node:assert/strict';
import { k, tag, list, expression, nil } from './binding-values.mjs';
import { runtimeName } from './fixture-values.mjs';
import { drive } from './checker-values.mjs';
const N=s=>['str',['anonymous'],s], Z=['zero'], S=l=>['succ',l], P=s=>['param',N(s)];
const U=l=>['sort',l], B=i=>['b',String(i)], C=(n,ls=[])=>['const',N(n),ls];
const pi=(n,t,b)=>['pi',N(n),t,b,'explicit'], lam=(n,t,b)=>['lam',N(n),t,b,'explicit'];
const idType=l=>pi('A',U(l),pi('a',B(0),B(1))), id=l=>lam('A',U(l),lam('a',B(0),B(0)));
const d=(name,params,type,value)=>k.PsKernelDefinition.polymorphic(runtimeName(k,N(name)),list(params.map(p=>runtimeName(k,Array.isArray(p)?p:N(p)))),expression(type),expression(value));
const poly=()=>d('Id',['u'],idType(P('u')),id(P('u')));
const alias=()=>d('Universe',['u'],U(S(P('u'))),U(P('u')));
const admit=(ds,budget=200000)=>drive(k.psKernelAdmissionStep,k.psKernelAdmissionStart(list(ds)),budget);
test('owned source admits symbolic universe-polymorphic identity',()=>assert.equal(admit([poly()]).status,'admitted'));
for(const [label,level]of [['Prop',Z],['Type',S(Z)],['higher',S(S(S(Z)))]])test('one polymorphic definition instantiates at '+label,()=>{
  const r=admit([poly(),d('Use',[],idType(level),C('Id',[level]))]);assert.equal(r.status,'admitted',JSON.stringify(r));
});
test('polymorphic definition reuses another at symbolic successor level',()=>{
  assert.equal(admit([poly(),d('Lifted',['v'],idType(S(P('v'))),C('Id',[S(P('v'))]))]).status,'admitted');
});
test('delta unfolding instantiates universes in the admitted value',()=>{
  const admitted=admit([alias()]);assert.equal(admitted.status,'admitted');
  const result=drive(k.psKernelReduceStep,k.psKernelNormalStart(admitted.result.environment,expression(C('Universe',[S(Z)]))));
  assert.equal(result.status,'done');assert.deepEqual(result.result.value,expression(U(S(Z))));
});
test('dependent binder domains reduce instantiated polymorphic definitions',()=>{
  const type=pi('A',C('Universe',[S(Z)]),pi('a',B(0),B(1)));
  assert.equal(admit([alias(),d('Use',[],type,id(S(Z)))]).status,'admitted');
});
for(const [label,definitions,error]of [
  ['undeclared parameter in type',()=>[d('Bad',[],U(S(P('u'))),U(P('u')))],'invalidUniverse'],
  ['undeclared parameter in value',()=>[d('Bad',['u'],U(S(P('u'))),U(P('v')))],'invalidUniverse'],
  ['duplicate parameter even when unused',()=>[d('Bad',['u','u'],U(S(Z)),U(Z))],'invalidUniverse'],
  ['anonymous parameter',()=>[d('Bad',[['anonymous']],U(S(Z)),U(Z))],'invalidUniverse'],
  ['missing universe argument',()=>[poly(),d('Bad',[],idType(Z),C('Id'))],'invalidUniverse'],
  ['extra universe argument',()=>[poly(),d('Bad',[],idType(Z),C('Id',[Z,Z]))],'invalidUniverse'],
  ['undeclared argument',()=>[poly(),d('Bad',[],idType(Z),C('Id',[P('missing')]))],'invalidUniverse'],
  ['wrong instantiated type',()=>[poly(),d('Bad',[],idType(S(Z)),C('Id',[Z]))],'typeMismatch'],
  ['self reference',()=>[d('Self',['u'],idType(P('u')),C('Self',[P('u')]))],'unknownConstant'],
  ['forward reference',()=>[d('Use',['u'],idType(P('u')),C('Id',[P('u')])),poly()],'unknownConstant'],
  ['duplicate declaration',()=>[poly(),poly()],'duplicateName'],
])test('polymorphic admission rejects '+label,()=>{
  const r=admit(definitions());assert.equal(r.status,'rejected');assert.equal(r.error,error);assert.equal(r.result.environment,undefined);
});
test('monomorphic definitions cannot acquire universe parameters at a use site',()=>{
  const mono=k.PsKernelDefinition.definition(runtimeName(k,N('Mono')),expression(U(S(Z))),expression(U(Z)));
  assert.equal(admit([mono,d('Bad',[],U(S(Z)),C('Mono',[Z]))]).error,'invalidUniverse');
});
test('undeclared universe in a discarded let still fails',()=>{
  const body=['let',N('unused'),U(P('missing')),U(Z),id(P('u'))];
  assert.equal(admit([d('Bad',['u'],idType(P('u')),body)]).error,'invalidUniverse');
});
test('one budget includes parameter validation, type/value instantiation and conversion',()=>{
  const ds=()=>[poly(),d('Use',[],idType(S(Z)),C('Id',[S(Z)]))];
  const full=admit(ds());assert.equal(full.status,'admitted');
  assert.equal(admit(ds(),full.steps-1).status,'outOfFuel');
  assert.equal(admit(ds(),full.steps).status,'admitted');
  for(const fuel of [0,1,2,16,64])assert.equal(admit(ds(),fuel).status,'outOfFuel');
});
test('a fresh environment never inherits earlier polymorphic declarations',()=>{
  assert.equal(admit([poly()]).status,'admitted');
  assert.equal(admit([d('Use',[],idType(Z),C('Id',[Z]))]).error,'unknownConstant');
});
