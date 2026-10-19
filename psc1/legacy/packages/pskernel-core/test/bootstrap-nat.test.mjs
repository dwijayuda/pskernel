import assert from 'node:assert/strict';import {test} from 'node:test';
import {definition,unit} from './unit-values.mjs';
import {N,Z,S,U,B,C,pi,bootstrap,nat,numeral,identityRec,sortRec} from './nat-values.mjs';
const proofType=pi('P',U(Z),pi('p',B(0),B(1)));
for(const n of [0,1,4,9])test('bootstrap owns and checks Nat before dependent definitions '+n,()=>{
 const r=bootstrap([definition('Value',[],C('Nat'),identityRec(n,'Nat')),definition('TypeUse',[],sortRec(n,'Nat'),proofType)]);
 assert.equal(r.status,'admitted',r.error??r.status);
});
test('empty bootstrap still pays for checked Nat admission',()=>{
 const r=bootstrap([]);assert.equal(r.status,'admitted');assert(r.steps>50);
 assert.equal(bootstrap([],r.steps-1).status,'outOfFuel');assert.equal(bootstrap([],r.steps).status,'admitted');
});
test('caller cannot redeclare or replace standard Nat',()=>{
 for(const entries of [[nat('Nat')],[definition('Nat',[],U(S(Z)),U(Z))]]){
  const r=bootstrap(entries);assert.equal(r.status,'rejected');assert.equal(r.error,'duplicateName');assert.equal(r.result.environment,undefined);
 }
});
test('bootstrap does not import other batches or an implicit reference prelude',()=>{
 assert.equal(bootstrap([unit()]).status,'admitted');
 for(const name of ['OwnedUnit','String','Bool']){
  const r=bootstrap([definition('Use',[],U(S(Z)),C(name))]);
  if(name==='String'){assert.equal(r.status,'admitted');}else{assert.equal(r.status,'rejected');assert.equal(r.error,'unknownConstant');}
 }
});
test('wrongly typed Nat use fails after valid Nat initialization',()=>{
 const r=bootstrap([definition('Bad',[],U(Z),numeral(0,'Nat'))]);assert.equal(r.status,'rejected');assert.equal(r.error,'typeMismatch');assert.equal(r.result.environment,undefined);
});
