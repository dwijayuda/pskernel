import assert from 'node:assert/strict';import {test} from 'node:test';
import {k,list,nil,expression,drive,infer,check,normal,convert,decodeExpr} from './checker-values.mjs';
import {runtimeName} from './fixture-values.mjs';
import {N,Z,S,U,C,app,nat,joint,bootstrap,numeral,identityRec,member} from './nat-values.mjs';
import {unit,definition} from './unit-values.mjs';
const literal=n=>['nat',String(n)],environment=()=>{const r=bootstrap([]);assert.equal(r.status,'admitted');return r.result.environment;};
for(const n of [0,1,19,256,9007199254740993n,1n<<256n])test('natural literal infers Nat exactly after checked prelude '+n,()=>{
 const env=environment(),r=infer(literal(n),env);assert.equal(r.status,'done',r.error);assert.deepEqual(decodeExpr(r.result.type),C('Nat'));
 assert.equal(check(literal(n),C('Nat'),env).status,'done');
});
for(const n of [0,1,2,8,19])test('natural literal converts to its checked constructor form '+n,()=>{
 const env=environment(),r=normal(literal(n),env);assert.equal(r.status,'done',r.error);assert.deepEqual(decodeExpr(r.result.value),numeral(n,'Nat'));
 assert.equal(convert(literal(n),numeral(n,'Nat'),env).status,'equal');
 assert.equal(convert(literal(n),literal(n+1),env).status,'different');
});
for(const n of [0,1,4,9])test('derived Nat recursor reduces a literal major '+n,()=>{
 const env=environment(),term=identityRec(n,'Nat');term[2]=literal(n);
 assert.equal(check(term,C('Nat'),env).status,'done');
 assert.equal(convert(term,literal(n),env).status,'equal');
});
test('literal typing does not invent Nat or accept an ordinary opaque constant by spelling',()=>{
 assert.equal(infer(literal(0)).error,'unknownConstant');
 const fake=k.PsKernelDefinition.constant(runtimeName(k,N('Nat')),nil(),expression(U(S(Z))));
 assert.equal(infer(literal(0),list([fake])).error,'unsupported');
 const disguised=joint([unit('Nat',[],S(Z),{ctorName:member('Nat','zero'),ctorType:C('Nat')})]);
 assert.equal(disguised.status,'admitted',disguised.error);
 assert.equal(infer(literal(0),disguised.result.environment).error,'unsupported');
});
test('Nat-like families with different constructor names do not authorize standard literal semantics',()=>{
 const renamed=joint([nat('Nat',{zeroName:member('Nat','otherZero')})]);assert.equal(renamed.status,'admitted',renamed.error);
 assert.equal(infer(literal(0),renamed.result.environment).error,'unsupported');
});
test('external metadata cannot mint literal authority',()=>{
 const forged=k.PsKernelDefinition.natFamily(runtimeName(k,N('Nat')),runtimeName(k,member('Nat','zero')),runtimeName(k,member('Nat','succ')));
 const r=drive(k.psKernelAdmissionStep,k.psKernelAdmissionStart(list([forged])));
 assert.equal(r.status,'rejected');assert.equal(r.error,'unsupported');assert.equal(r.result.environment,undefined);
});
test('wrong natural types and literal functions reject; supported text retains String type',()=>{
 const env=environment();assert.equal(check(literal(0),U(Z),env).error,'typeMismatch');
 assert.equal(infer(app(literal(0),literal(0)),env).error,'functionExpected');
 assert.equal(infer(['text','no string semantics'],env).status,'done');
 assert.equal(check(['text','no string semantics'],C('Nat'),env).error,'typeMismatch');
});
test('literal expansion and authority validation consume the same bounded execution budget',()=>{
 const env=environment(),r=normal(literal(8),env);assert.equal(r.status,'done');
 assert.equal(normal(literal(8),env,r.steps-1).status,'outOfFuel');assert.equal(normal(literal(8),env,r.steps).status,'done');
 assert.equal(normal(literal(1n<<1000n),env,2000).status,'outOfFuel');
});
test('bootstrap admits literal definitions atomically and exposes no environment after rejection',()=>{
 assert.equal(bootstrap([definition('Value',[],C('Nat'),literal(42))]).status,'admitted');
 const r=bootstrap([definition('Good',[],C('Nat'),literal(42)),definition('Bad',[],U(Z),literal(0))]);
 assert.equal(r.status,'rejected');assert.equal(r.result.environment,undefined);
});
