import test from 'node:test';
import assert from 'node:assert/strict';
import { k, tag, list, expression, drive, decodeExpr, U, B, Lam, Pi, App } from './checker-values.mjs';
import { runtimeName } from './fixture-values.mjs';
const N=s=>['str',['anonymous'],s], Z=['zero'], S=l=>['succ',l], P=s=>['param',N(s)];
const C=(n,ls=[])=>['const',Array.isArray(n)?n:N(n),ls];
const raw=(n,params,type)=>k.PsKernelDefinition.constant(runtimeName(k,Array.isArray(n)?n:N(n)),list(params.map(x=>runtimeName(k,N(x)))),expression(type));
const env=()=>list([raw('F',['u'],['sort',P('u')]),raw('Other',['u'],['sort',P('u')])]);
const reduce=(v,budget=200000)=>drive(k.psKernelReduceStep,k.psKernelNormalStart(env(),expression(v)),budget);
const convert=(a,b,budget=200000)=>drive(k.psKernelConversionStep,k.psKernelConversionStart(env(),expression(a),expression(b)),budget);

test('internal constants have types and no invented definition bodies',()=>{
 const d=raw('F',['u'],['sort',P('u')]);
 assert.equal(tag(k.psKernelDefinitionBody(d)),'opaque');
 const result=drive(k.psKernelTypeStep,k.psKernelInferStart(env(),expression(C('F',[S(Z)]))));
 assert.equal(result.status,'done');assert.deepEqual(decodeExpr(result.result.type),U(1));
});
test('opaque constants remain neutral under normalization',()=>{
 const result=reduce(C('F',[S(Z)]));assert.equal(result.status,'done');assert.deepEqual(decodeExpr(result.result.value),C('F',[S(Z)]));
});
test('direct opaque entries cannot be injected through fresh definition admission',()=>{
 const result=drive(k.psKernelAdmissionStep,k.psKernelAdmissionStart(list([raw('False',[],U(0))])));
 assert.equal(result.status,'rejected');assert.equal(result.error,'unsupported');assert.equal(result.result.environment,undefined);
});
test('constant names and normalized universe arguments control conversion',()=>{
 assert.equal(convert(C('F',[['max',Z,S(Z)]]),C('F',[S(Z)])).status,'equal');
 assert.equal(convert(C('F',[Z]),C('F',[S(Z)])).status,'different');
 assert.equal(convert(C('F',[Z]),C('Other',[Z])).status,'different');
});
for(const levels of [[],[Z,Z]])test('opaque constant arity remains checked: '+levels.length,()=>{
 const reduced=reduce(C('F',levels));assert.equal(reduced.status,'rejected');assert.equal(reduced.error,'invalidUniverse');
 const inferred=drive(k.psKernelTypeStep,k.psKernelInferStart(env(),expression(C('F',levels))));
 assert.equal(inferred.status,'rejected');assert.equal(inferred.error,'invalidUniverse');
});
test('unknown neutral constants are still rejected',()=>assert.equal(reduce(C('Unknown')).error,'unknownConstant'));
test('opaque constants participate in dependent application typing',()=>{
 const f=C('F',[S(Z)]),term=Lam('x',f,B(0)),type=Pi('x',f,f);
 const result=drive(k.psKernelTypeStep,k.psKernelCheckStart(env(),expression(term),expression(type)));
 assert.equal(result.status,'done');
});
test('constant equality does not compare printed dotted names',()=>{
 const structured=['str',N('A'),'B'], dotted=N('A.B');
 const context=list([raw(structured,[],U(1)),raw(dotted,[],U(1))]);
 const result=drive(k.psKernelConversionStep,k.psKernelConversionStart(context,expression(C(structured)),expression(C(dotted))));
 assert.equal(result.status,'different');
});
test('symbolic parameters in type inference still require declaration scope',()=>{
 const result=drive(k.psKernelTypeStep,k.psKernelInferStart(env(),expression(C('F',[P('u')]))));
 assert.equal(result.status,'rejected');assert.equal(result.error,'invalidUniverse');
});
test('nested opaque comparisons and instantiation share the exact outer budget',()=>{
 const a=Pi('x',C('F',[S(Z)]),C('Other',[S(Z)]));
 const result=convert(a,a);assert.equal(result.status,'equal');
 assert.equal(convert(a,a,result.steps-1).status,'outOfFuel');
 assert.equal(convert(a,a,result.steps).status,'equal');
});
