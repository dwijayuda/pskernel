import test from 'node:test';import assert from 'node:assert/strict';import fs from 'node:fs';import {gunzipSync} from 'node:zlib';import {createHash} from 'node:crypto';
import {checkOwnedAdmissions} from './checked-owned-kernel.mjs';import {definition} from '../packages/pskernel-core/test/unit-values.mjs';
import {enumeration,eliminate,resultWitness,wireBatch,wireEntry,N,Z,S,U,B,C,app,pi,lam,member,literal} from '../packages/pskernel-core/test/enum-values.mjs';
const check=async entries=>(await checkOwnedAdmissions(wireBatch(entries)));
const preserved=gunzipSync(fs.readFileSync(new URL('../docs/continuity/owned-record-fields-2026-10-03/preserved75-admissions.json.gz',import.meta.url)));
assert.equal(createHash('sha256').update(preserved).digest('hex'),'20715347d21c3151b02207cb0b17e4827fa098c1c97861c6438df79b2863a722');
const original=JSON.parse(preserved),token=original.admissions[14],batch=admissions=>JSON.stringify({format:original.format,version:original.version,admissions});
test('exact preserved PsTokenKind admits in isolation, not as a full-prefix claim',async()=>{
 assert.equal(token.declaration.ts[0].n.v,'PsTokenKind');assert.equal(token.declaration.ts[0].cs.length,6);const r=(await checkOwnedAdmissions(batch([token])));
 assert.equal(r.accepted,true,r.errorKind);assert.equal(r.admissionCount,1);assert.equal(r.profile,'owned-uniform-algebraic/11');
});
test('owned enum checks dependent computed-result witnesses through the production boundary',async()=>{
 const e=enumeration('E',3);for(let i=0;i<3;i++){const w=resultWitness(eliminate(e,i),i+1);assert.equal((await check([e,definition('Good',[],w.type,w.value)])).accepted,true);const bad=resultWitness(eliminate(e,i),i+2);assert.equal((await check([e,definition('Bad',[],bad.type,bad.value)])).accepted,false);}
});
for(const [label,mutate]of [
 ['duplicate constructor',d=>{d.ts[0].cs[5].n=d.ts[0].cs[0].n;}],['wrong result',d=>{d.ts[0].cs[5].t.n={k:'s',p:{k:'a'},v:'Nat'};}],
 ['forged family metadata',d=>{d.ts[0].checked=true;}],['forged constructor metadata',d=>{d.ts[0].cs[0].index=0;}],
 ['parameters',d=>{d.np=1;}],['mutual family',d=>{d.ts.push(d.ts[0]);}],['universe parameters',d=>{d.lp=[{k:'s',p:{k:'a'},v:'u'}];}],
 ['higher sort',d=>{d.ts[0].t.l={k:'s',o:d.ts[0].t.l};}],['Prop sort',d=>{d.ts[0].t.l={k:'z'};}],['no constructors',d=>{d.ts[0].cs=[];}],
 ['unknown constructor field',d=>{d.ts[0].cs[0].t={k:'forall',n:{k:'a'},bi:'default',t:{k:'const',n:{k:'s',p:{k:'a'},v:'MissingFieldType'},ls:[]},b:d.ts[0].cs[0].t};}]
])test('owned enumeration boundary rejects '+label,async()=>{const changed=structuredClone(token);mutate(changed.declaration);const r=(await checkOwnedAdmissions(batch([changed])));assert.equal(r.accepted,false);assert.equal(r.environment,undefined);});
test('owned enum budget is exact and rejected sessions expose no retained authority',async()=>{
 const input=batch([token]),done=(await checkOwnedAdmissions(input));assert.equal(done.accepted,true);
 const short=(await checkOwnedAdmissions(input,{maxSteps:done.steps-1}));assert.equal(short.accepted,false);assert.equal(short.errorKind,'outOfFuel');assert.equal((await checkOwnedAdmissions(input,{maxSteps:done.steps})).accepted,true);
 const term=C(['str',N('PsTokenKind'),'identifier']);assert.equal((await check([definition('Bad',[],C('PsTokenKind'),term)])).accepted,false);
});

test('old payload-bearing PsTokenKind rejection fixture now takes the checked sum route',async()=>{
 const changed=structuredClone(token);changed.declaration.ts[0].cs[0].t={k:'forall',n:{k:'a'},bi:'default',t:{k:'const',n:{k:'s',p:{k:'a'},v:'Nat'},ls:[]},b:changed.declaration.ts[0].cs[0].t};
 const result=await checkOwnedAdmissions(batch([changed]));assert.equal(result.accepted,true,JSON.stringify(result));
});
