import assert from 'node:assert/strict';import {test} from 'node:test';
import {checkAdmissionsWithKernel} from './checked-kernel-provider.mjs';
import {checkOwnedAdmissions} from './checked-owned-kernel.mjs';
const name=v=>({k:'s',p:{k:'a'},v}),nat={k:'const',n:name('Nat'),ls:[]};
const entry=v=>({kind:'constant',declaration:{k:'definition',n:name('Value'),lp:[],t:nat,v:{k:'nat',v},s:'safe',h:{k:'regular',h:'1'}}});
const wire=e=>JSON.stringify({format:'proofscript-checked-admissions',version:2,admissions:[e]});
for(const value of ['0','42','9007199254740993',(1n<<256n).toString()])test('explicit owned kernel accepts exact natural literal '+value,async()=>{
 const {result,descriptor}=await checkAdmissionsWithKernel(wire(entry(value)),'pskernel-core.old3');
 assert.equal(descriptor.selector,'pskernel-core.old3');assert.equal(result.profile,'owned-uniform-algebraic/11');
 assert.equal(result.accepted,true,JSON.stringify(result));assert.equal(result.admissionCount,1);
});
for(const value of ['-1','01','1.5','1e3',9007199254740992,'9'.repeat(5001)])test('literal wire rejects invalid natural '+String(value).slice(0,30),async()=>{
 const {result,descriptor}=await checkAdmissionsWithKernel(wire(entry(value)),'pskernel-core.old3');
 assert.equal(descriptor.selector,'pskernel-core.old3');assert.equal(result.accepted,false);assert.equal(result.errorKind,'invalid-natural');
});
test('literal checking shares its budget with prelude and exposes no partial environment',async()=>{
 const input=wire(entry('42')),full=await checkOwnedAdmissions(input);assert.equal(full.accepted,true);
 const short=await checkOwnedAdmissions(input,{maxSteps:full.steps-1});assert.equal(short.accepted,false);assert.equal(short.errorKind,'outOfFuel');
 assert.equal(short.environment,undefined);assert.equal((await checkOwnedAdmissions(input,{maxSteps:full.steps})).accepted,true);
});
test('literal support does not turn wrongly typed values or forged Nat metadata into acceptance',async()=>{
 const wrong=entry('0');wrong.declaration.t={k:'sort',l:{k:'z'}};
 assert.equal((await checkOwnedAdmissions(wire(wrong))).errorKind,'typeMismatch');
 const forged=entry('0');forged.declaration.k='natFamily';
 assert.equal((await checkOwnedAdmissions(wire(forged))).accepted,false);
});
