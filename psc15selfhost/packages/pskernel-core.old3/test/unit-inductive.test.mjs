import test from 'node:test';
import assert from 'node:assert/strict';
import { k, list, expression, drive, decodeExpr } from './checker-values.mjs';
import { runtimeName } from './fixture-values.mjs';
import { N, Z, S, P, U, B, C, app, pi, lam, ctorName, recName, unit, definition, joint, eliminate } from './unit-values.mjs';

test('fresh mixed admission accepts the empty bundle',()=>assert.equal(joint([]).status,'admitted'));
for(const [label,params,level]of [['Prop',[],Z],['Type',[],S(Z)],['polymorphic',['u'],P('u')],['extra unused level',['u','v'],P('u')]]){
 test('unit inductive admits '+label,()=>{
  const result=joint([unit('OwnedUnit',params,level)]);assert.equal(result.status,'admitted',JSON.stringify(result));
 });
}
test('the generated constructor checks against its admitted family',()=>{
 const entries=[unit('OwnedUnit',['u'],P('u')),definition('value',['v'],C('OwnedUnit',[P('v')]),C(ctorName('OwnedUnit'),[P('v')]))];
 assert.equal(joint(entries).status,'admitted');
});
test('the derived recursor checks and reduces to its minor premise',()=>{
 const result=joint([unit(),definition('Use',[],U(S(Z)),eliminate())]);assert.equal(result.status,'admitted',JSON.stringify(result));
 const reduced=drive(k.psKernelReduceStep,k.psKernelNormalStart(result.result.environment,expression(C('Use'))));
 assert.equal(reduced.status,'done');assert.deepEqual(decodeExpr(reduced.result.value),U(Z));
});
test('polymorphic recursor instantiation preserves family universe arguments',()=>{
 const result=joint([unit('OwnedUnit',['u'],P('u')),definition('Use',['v'],U(S(Z)),eliminate(P('v'),['v']))]);
 assert.equal(result.status,'admitted',JSON.stringify(result));
});
test('motive universe name is fresh even when the first numeric candidate is declared',()=>{
 const collision=['num',N('OwnedUnit'),'0'];
 const result=joint([unit('OwnedUnit',[collision],P(collision))]);assert.equal(result.status,'admitted',JSON.stringify(result));
 const rec=result.result.environment.head;
 assert.notDeepEqual(rec.parameters.head,runtimeName(k,collision));
});
for(const [label,entries,error]of [
 ['anonymous family',[unit(['anonymous'])],'invalidName'],
 ['anonymous constructor',[unit('OwnedUnit',[],S(Z),{ctorName:['anonymous']})],'invalidName'],
 ['duplicate level',[unit('OwnedUnit',['u','u'],P('u'))],'invalidUniverse'],
 ['anonymous level',[unit('OwnedUnit',[['anonymous']],Z)],'invalidUniverse'],
 ['undeclared family level',[unit('OwnedUnit',[],P('missing'))],'invalidUniverse'],
 ['wrong result family',[unit('Other'),unit('OwnedUnit',[],S(Z),{ctorType:C('Other')})],'typeMismatch'],
 ['unknown result family',[unit('OwnedUnit',[],S(Z),{ctorType:C('Unknown')})],'unknownConstant'],
 ['constructor with a field',[unit('OwnedUnit',[],S(Z),{ctorType:pi('x',C('OwnedUnit'),C('OwnedUnit'))})],'typeMismatch'],
 ['undeclared constructor universe',[unit('OwnedUnit',['u'],P('u'),{ctorType:C('OwnedUnit',[P('missing')])})],'invalidUniverse'],
 ['missing constructor universe',[unit('OwnedUnit',['u'],P('u'),{ctorType:C('OwnedUnit')})],'invalidUniverse'],
 ['extra constructor universe',[unit('OwnedUnit',[],S(Z),{ctorType:C('OwnedUnit',[Z])})],'invalidUniverse'],
 ['constructor equals family',[unit('OwnedUnit',[],S(Z),{ctorName:N('OwnedUnit')})],'duplicateName'],
 ['constructor equals recursor',[unit('OwnedUnit',[],S(Z),{ctorName:recName('OwnedUnit')})],'duplicateName'],
 ['duplicate family',[unit(),unit()],'duplicateName'],
 ['forward family reference',[definition('Before',[],C('OwnedUnit'),C(ctorName('OwnedUnit'))),unit()],'unknownConstant'],
])test('unit admission rejects '+label,()=>{
 const result=joint(entries);assert.equal(result.status,'rejected',JSON.stringify(result));assert.equal(result.error,error);assert.equal(result.result.environment,undefined);
});
test('universe-distinct constructor result is rejected even with the same family name',()=>{
 const result=joint([unit('OwnedUnit',['u'],P('u'),{ctorType:C('OwnedUnit',[S(P('u'))])})]);
 assert.equal(result.status,'rejected');assert.equal(result.result.environment,undefined);
});
test('motive, minor and major types are checked before iota can authorize a definition',()=>{
 const f=C('OwnedUnit'),head=C(recName('OwnedUnit'),[S(S(Z))]),motive=lam('major',f,U(S(Z)));
 for(const value of [app(head,motive,U(S(Z)),C(ctorName('OwnedUnit'))),app(head,motive,U(Z),U(Z))]){
  const result=joint([unit(),definition('Bad',[],U(S(Z)),value)]);assert.equal(result.status,'rejected');assert.equal(result.result.environment,undefined);
 }
});
test('wrong recursor universe arity rejects rather than reducing to acceptance',()=>{
 for(const levels of [[],[S(S(Z)),Z]]){
  const value=app(C(recName('OwnedUnit'),levels),lam('major',C('OwnedUnit'),U(S(Z))),U(Z),C(ctorName('OwnedUnit')));
  const result=joint([unit(),definition('Bad',[],U(S(Z)),value)]);assert.equal(result.error,'invalidUniverse');
 }
});
test('neutral majors remain neutral in the supported reduction fragment',()=>{
 const admitted=joint([unit()]);const term=app(C(recName('OwnedUnit'),[S(S(Z))]),lam('major',C('OwnedUnit'),U(S(Z))),U(Z),B(0));
 const result=drive(k.psKernelReduceStep,k.psKernelNormalStart(admitted.result.environment,expression(term)));
 assert.equal(result.status,'done');assert.deepEqual(decodeExpr(result.result.value),term);
});
test('raw constants and forged recursors remain inadmissible as definitions',()=>{
 const raw=[k.PsKernelDefinition.constant(runtimeName(k,N('Bad')),list([]),expression(U(Z))),
  k.PsKernelDefinition.unitRecursor(runtimeName(k,N('Bad')),list([]),expression(U(Z)),runtimeName(k,N('Invented')))];
 for(const entry of raw){
  const result=drive(k.psKernelJointStep,k.psKernelJointStart(list([k.PsKernelJointEntry.definition(entry)])));
  assert.equal(result.status,'rejected');assert.equal(result.error,'unsupported');assert.equal(result.result.environment,undefined);
 }
});
test('one budget includes name validation, typing, derived admission and iota',()=>{
 const entries=[unit(),definition('Use',[],U(S(Z)),eliminate())];const result=joint(entries);assert.equal(result.status,'admitted');
 assert.equal(joint(entries,result.steps-1).status,'outOfFuel');assert.equal(joint(entries,result.steps).status,'admitted');
 for(const fuel of [0,1,4,32,128])assert.equal(joint(entries,fuel).status,'outOfFuel');
});
test('successful unit admission never leaks into a fresh bundle',()=>{
 assert.equal(joint([unit()]).status,'admitted');
 assert.equal(joint([definition('Bad',[],C('OwnedUnit'),C(ctorName('OwnedUnit')))]).error,'unknownConstant');
});
