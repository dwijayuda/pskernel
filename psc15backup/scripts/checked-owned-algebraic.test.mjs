import test from 'node:test';import assert from 'node:assert/strict';import fs from 'node:fs';import {createHash} from 'node:crypto';
import {checkOwnedAdmissions} from './checked-owned-kernel.mjs';
import {family,value,eliminate,resultWitness,wireBatch,N,Z,S,U,B,C,app,pi,lam,member,literal,d,T} from '../packages/pskernel-core.old3/test/algebraic-values.mjs';
const fixture=fs.readFileSync(new URL('./fixtures/owned-algebraic-list.json',import.meta.url),'utf8');
test('exact preserved PsKernelList declaration is admitted through the owned production boundary',async()=>{
 assert.equal(createHash('sha256').update(fixture).digest('hex'),'1a1dc0ac346acaa79411efb6b91f029e6b1444aa8a39456ff6b993720c548d48');const r=await checkOwnedAdmissions(fixture);assert.equal(r.accepted,true);assert.equal(r.admissionCount,1);
});
test('parameterized recursive production recursor computes checked result-type witnesses',async()=>{
 const e=family('Seq',1,[[],[B(0),app(C('Seq'),B(0))]]),ty=app(C('Seq'),C('Nat')),nil=value(e,0,[C('Nat')]),major=value(e,1,[C('Nat')],[literal(7),nil]);
 const step=lam('h',C('Nat'),lam('t',ty,lam('ih',C('Nat'),app(C(member('Nat','succ')),B(0))))),term=eliminate(e,[C('Nat')],lam('s',ty,C('Nat')),[literal(0),step],major);
 for(const [n,accepted]of [[1,true],[2,false]]){const w=resultWitness(term,n),r=await checkOwnedAdmissions(wireBatch([e,d('Witness',w.type,w.value)]));assert.equal(r.accepted,accepted);}
});
const altered=[['fractional parameter count',x=>x.declaration.np=1.5],['negative parameter count',x=>x.declaration.np=-1],['string parameter count',x=>x.declaration.np='1'],['huge parameter count',x=>x.declaration.np=Number.MAX_SAFE_INTEGER+1],['forged family metadata',x=>x.declaration.ts[0].approved=true],['forged constructor metadata',x=>x.declaration.ts[0].cs[0].rule=[]],['universe parameters',x=>x.declaration.lp=[{k:'s',p:{k:'a'},v:'u'}]],['mutual families',x=>x.declaration.ts.push(x.declaration.ts[0])]];
for(const [label,change]of altered)test('algebraic wire rejects '+label,async()=>{const input=JSON.parse(wireBatch([family('O',1,[[],[B(0)]]) ]));change(input.admissions[0]);const r=await checkOwnedAdmissions(JSON.stringify(input));assert.equal(r.accepted,false);assert.equal(r.environment,undefined);});
for(const [label,e]of [['negative-self',family('Bad',1,[[pi('x',app(C('Bad'),B(0)),C('Nat'))]])],['loose-bound-field',family('Bad',1,[[B(1)]])],['nonuniform-self',family('Bad',1,[[app(C('Bad'),C('Nat'))]])]])test('production source checker rejects '+label,async()=>{const r=await checkOwnedAdmissions(wireBatch([e]));assert.equal(r.accepted,false);assert.equal(r.environment,undefined);});
test('algebraic production exhaustion and session isolation never retain authority',async()=>{
 const r=await checkOwnedAdmissions(fixture);assert.equal(r.accepted,true);const short=await checkOwnedAdmissions(fixture,{maxSteps:r.steps-1});assert.equal(short.accepted,false);assert.equal(short.errorKind,'outOfFuel');assert.equal((await checkOwnedAdmissions(fixture,{maxSteps:r.steps})).accepted,true);
 const type=app(C('PsKernelList'),C('Nat')),term=app(C(member('PsKernelList','nil')),C('Nat'));assert.equal((await checkOwnedAdmissions(wireBatch([d('Leak',type,term)]))).accepted,false);
});
