import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import { runtimeFuel } from './fixture-values.mjs';
import {k,tag,nil,list,expression,definition,B,U,Pi,Lam,App,Let,C,def,identity,identityType,drive,infer,check,admit,normal,convert,decodeExpr} from './checker-values.mjs';
const cases=JSON.parse(fs.readFileSync(new URL('./checker-cases.json',import.meta.url),'utf8'));
for(const c of cases)test('checker: '+c.name,()=>{
  const prior=admit(c.prior);assert.equal(prior.status,'admitted',JSON.stringify(prior));
  const r=check(c.value,c.type,prior.result.environment);
  assert.equal(r.status,c.expected,JSON.stringify(r));
  if(c.error)assert.equal(r.error,c.error,JSON.stringify(r));
});
test('reducer: beta/zeta reductions preserve binder scope',()=>{
  const input=Lam('P',U(0),Lam('p',B(0),App(Lam('z',B(1),Lam('q',B(2),B(1))),B(0))));
  const expected=Lam('P',U(0),Lam('p',B(0),Lam('q',B(1),B(1))));
  const r=normal(input);assert.equal(r.status,'done');assert.deepEqual(decodeExpr(r.result.value),expected);
});
test('infer: binder lookup lifts dependent type by index plus one',()=>{
  const r=infer(Lam('A',U(1),Lam('x',B(0),B(0))));assert.equal(r.status,'done');
  assert.deepEqual(decodeExpr(r.result.type),identityType(1));
});
test('infer: impredicative Pi over a high universe remains Prop',()=>{
  const r=infer(Pi('Large',U(7),identityType(0)));assert.equal(r.status,'done');
  assert.equal(convert(decodeExpr(r.result.type),U(0)).status,'equal');
});
test('conversion: ignores binder names and binder visibility only',()=>{
  assert.equal(convert(identity(0),Lam('Different',U(0),Lam('other',B(0),B(0),'implicit'),'strictImplicit')).status,'equal');
  assert.equal(convert(identity(0),Lam('P',U(0),Lam('p',B(0),B(1)))).status,'different');
});
test('admission: complete sequential dependency replay from empty environment',()=>{
  const ds=[def('Alias',U(1),U(0)),def('Id',identityType(0),identity(0)),def('Use',identityType(0),C('Id'))];
  const r=admit(ds);assert.equal(r.status,'admitted');
  assert.equal(check(C('Use'),identityType(0),r.result.environment).status,'done');
});
for(const [name,ds,error] of [
 ['duplicate',[def('D',U(1),U(0)),def('D',U(1),U(0))],'duplicateName'],
 ['self-reference',[def('D',U(0),C('D'))],'unknownConstant'],
 ['forward-reference',[def('D',U(0),C('Later')),def('Later',U(1),U(0))],'unknownConstant'],
 ['cycle',[def('D',U(0),C('E')),def('E',U(0),C('D'))],'unknownConstant'],
 ['ill-typed-later-definition',[def('Good',identityType(0),identity(0)),def('Bad',U(0),U(0))],'typeMismatch'],
])test('admission rejects '+name+' without returning an environment',()=>{
 const r=admit(ds);assert.equal(r.status,'rejected');assert.equal(r.error,error);assert.equal(r.result.environment,undefined);
});
test('fresh admissions never inherit a previous accepted environment',()=>{
 assert.equal(admit([def('Earlier',identityType(0),identity(0))]).status,'admitted');
 assert.equal(admit([def('Use',identityType(0),C('Earlier'))]).error,'unknownConstant');
});
test('anonymous global names rejected',()=>{
 const d=k.PsKernelDefinition.definition(k.PsKernelName.anonymous,expression(U(1)),expression(U(0)));
 const r=drive(k.psKernelAdmissionStep,k.psKernelAdmissionStart(list([d])));assert.equal(r.error,'invalidName');
});
test('single budget includes nested typing, reduction, lookup, and conversion',()=>{
 const ds=[def('Id',identityType(1),identity(1)),def('Use',identityType(1),C('Id'))];
 const full=admit(ds);assert.equal(full.status,'admitted');
 assert.equal(admit(ds,full.steps-1).status,'outOfFuel');assert.equal(admit(ds,full.steps).status,'admitted');
 for(const budget of [0,1,2,8,16,32])assert.equal(admit(ds,budget).status,'outOfFuel');
});
test('generated recursive runners agree with iterative transition drivers',()=>{
 const t=identityType(0),v=identity(0),complete=check(v,t),ds=[def('Id',t,v)],admitted=admit(ds);
 const tests=[
  [k.psKernelTypeRun,k.psKernelCheckStart(nil(),expression(v),expression(t)),complete.steps,complete.result,k.PsKernelTypeResult.outOfFuel],
  [k.psKernelAdmissionRun,k.psKernelAdmissionStart(list(ds.map(definition))),admitted.steps,admitted.result,k.PsKernelAdmissionResult.outOfFuel]
 ];
 for(const [run,state,steps,result,exhausted]of tests){assert.deepEqual(run(runtimeFuel(k,steps),state),result);assert.deepEqual(run(runtimeFuel(k,steps-1),state),exhausted);}
});
test('malformed internal final states do not manufacture success',()=>{
 assert.equal(drive(k.psKernelTypeStep,k.PsKernelTypeState.state(nil(),nil(),nil())).error,'invalidState');
 assert.equal(drive(k.psKernelReduceStep,k.PsKernelReduceState.state(nil(),nil(),list([expression(U(0)),expression(U(1))]))).error,'invalidState');
});
test('unguarded internal divergent reducer consumes budget, never returns equality',()=>{
 const w=Lam('x',U(0),App(B(0),B(0))),omega=App(w,w);
 assert.equal(normal(omega,nil(),500).status,'outOfFuel');
 assert.equal(convert(omega,omega,nil(),500).status,'outOfFuel');
 assert.equal(check(omega,U(0)).status,'rejected');
});
test('deeply nested well-shaped terms are stopped by shared budget',()=>{
 let x=U(0);for(let i=0;i<350;i++)x=Pi('A',U(1),x);
 assert.equal(infer(x,nil(),1000).status,'outOfFuel');
});
