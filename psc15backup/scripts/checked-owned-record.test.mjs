import assert from 'node:assert/strict';
import {test} from 'node:test';
import {readFileSync} from 'node:fs';
import {checkOwnedAdmissions} from './checked-owned-kernel.mjs';
const prefix=JSON.parse(readFileSync(new URL('./fixtures/owned-bootstrap-record-prefix.json',import.meta.url)));
const wire=admissions=>JSON.stringify({format:'proofscript-checked-admissions',version:2,admissions});

test('preserved record prefix admits PsSourcePos and PsSourceSpan without prelude substitution',async()=>{
 const result=await checkOwnedAdmissions(wire(prefix.slice(0,3)));
 assert.equal(result.accepted,true,JSON.stringify(result));assert.equal(result.admissionCount,3);
 assert.equal(result.profile,'owned-uniform-algebraic/11');
 const next=await checkOwnedAdmissions(wire(prefix));
 assert.equal(next.accepted,false);assert.equal(next.admissionIndex,3);assert.equal(next.errorKind,'unknownConstant');
 assert.equal(next.environment,undefined);
});
for(const [label,change]of [
 ['extra family metadata',d=>{d.ts[0].fields=[];}],
 ['extra constructor metadata',d=>{d.ts[0].cs[0].numFields=3;}],
 ['universe parameters',d=>{d.lp=[{k:'s',p:{k:'a'},v:'u'}];}],
 ['term parameters',d=>{d.np=1;}],
 ['missing constructor field',d=>{d.ts[0].cs[0].t.b.b.b={k:'b',i:0};}],
 ['recursive field',d=>{d.ts[0].cs[0].t.t={k:'const',n:d.ts[0].n,ls:[]};}],
 ['dependent field',d=>{d.ts[0].cs[0].t.b.t={k:'b',i:0};}],
 ['field universe mismatch',d=>{d.ts[0].cs[0].t.t={k:'sort',l:{k:'s',o:{k:'z'}}};}]
])test('owned record boundary rejects '+label,async()=>{
 const entry=structuredClone(prefix[1]);change(entry.declaration);
 const result=await checkOwnedAdmissions(wire([entry]));
 assert.equal(result.accepted,false,JSON.stringify(result));assert.equal(result.admissionIndex,0);assert.equal(result.environment,undefined);
});
test('record bootstrap prefix uses an exact shared limit and exposes no partial environment',async()=>{
 const input=wire(prefix.slice(0,3)),accepted=await checkOwnedAdmissions(input);assert.equal(accepted.accepted,true);
 const exhausted=await checkOwnedAdmissions(input,{maxSteps:accepted.steps-1});
 assert.equal(exhausted.accepted,false);assert.equal(exhausted.errorKind,'outOfFuel');assert.equal(exhausted.environment,undefined);
 assert.equal((await checkOwnedAdmissions(input,{maxSteps:accepted.steps})).accepted,true);
});
