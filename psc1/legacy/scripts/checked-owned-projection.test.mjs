import assert from 'node:assert/strict';
import {test} from 'node:test';
import {readFileSync} from 'node:fs';
import {checkOwnedAdmissions} from './checked-owned-kernel.mjs';
const prefix=JSON.parse(readFileSync(new URL('./fixtures/owned-bootstrap-record-prefix.json',import.meta.url)));
const N=v=>({k:'s',p:{k:'a'},v}),C=n=>({k:'const',n,ls:[]}),nat=v=>({k:'nat',v:String(v)}),app=(f,...args)=>args.reduce((f,a)=>({k:'app',f,a}),f);
const family=prefix[1].declaration.ts[0],major=app(C(family.cs[0].n),nat(7),nat(11),nat(13));
const projection=i=>({k:'proj',n:family.n,i,e:structuredClone(major)});
const definition=v=>({kind:'constant',declaration:{k:'definition',n:N('Projected'),lp:[],t:C(N('Nat')),v,h:{k:'regular',h:'1'},s:'safe'}});
const wire=admissions=>JSON.stringify({format:'proofscript-checked-admissions',version:2,admissions});
for(const i of [0,1,2])test('exact preserved PsSourcePos metadata checks wire projection '+i,async()=>{
 const result=await checkOwnedAdmissions(wire([...prefix.slice(0,3),definition(projection(i))]));assert.equal(result.accepted,true,JSON.stringify(result));assert.equal(result.profile,'owned-uniform-algebraic/11');
});
for(const [label,change]of [
 ['out-of-bounds',p=>{p.i=3;}],['huge-index',p=>{p.i='9007199254740993';}],['negative-index',p=>{p.i=-1;}],['noncanonical-index',p=>{p.i='01';}],
 ['unsafe-number',p=>{p.i=9007199254740992;}],['extra-metadata',p=>{p.fields=[];}],['missing-field',p=>{delete p.e;}],
 ['wrong-family',p=>{p.n=prefix[2].declaration.ts[0].n;}],['unknown-family',p=>{p.n=N('Missing');}],['non-record-family',p=>{p.n=N('Nat');p.e=nat(0);}],
 ['wrong-major',p=>{p.e=nat(0);}],['unbound-major',p=>{p.e={k:'b',i:0};}],['discarded-bad-field',p=>{p.e.a={k:'sort',l:{k:'z'}};}]
])test('projection boundary rejects '+label,async()=>{
 const p=projection(0);change(p);const result=await checkOwnedAdmissions(wire([...prefix.slice(0,3),definition(p)]));assert.equal(result.accepted,false,JSON.stringify(result));assert.equal(result.environment,undefined);
});
test('wire projection exhaustion is exact and prior acceptance does not grant authority',async()=>{
 const input=wire([...prefix.slice(0,3),definition(projection(1))]),done=await checkOwnedAdmissions(input);assert.equal(done.accepted,true);
 const exhausted=await checkOwnedAdmissions(input,{maxSteps:done.steps-1});assert.equal(exhausted.errorKind,'outOfFuel');assert.equal(exhausted.environment,undefined);
 assert.equal((await checkOwnedAdmissions(input,{maxSteps:done.steps})).accepted,true);
 assert.equal((await checkOwnedAdmissions(wire([definition(projection(1))]))).accepted,false);
});
