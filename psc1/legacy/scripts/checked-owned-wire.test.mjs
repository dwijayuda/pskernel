import test from 'node:test';import assert from 'node:assert/strict';
import {checkOwnedAdmissions} from './checked-owned-kernel.mjs';
const name=(...parts)=>parts.reduce((p,v)=>({k:'s',p,v}),{k:'a'}),nat={k:'const',n:name('Nat'),ls:[]};
const definition=(n,v='0')=>({kind:'constant',declaration:{k:'definition',n,lp:[],t:nat,v:{k:'nat',v},s:'safe',h:{k:'regular',h:'1'}}});
const batch=xs=>JSON.stringify({format:'proofscript-checked-admissions',version:2,admissions:xs});
test('wire sharing keeps structural names distinct, including cache-like names',async()=>{
 const xs=[definition(name('A.B'),'1'),definition(name('A','B'),'2'),definition(name('__proto__'),'3'),definition(name('s:1'),'4'),definition({k:'n',p:{k:'a'},v:'1'},'5'),definition(name('1'),'6')];
 const r=await checkOwnedAdmissions(batch(xs));assert.equal(r.accepted,true);assert.equal(r.admissionCount,6);
});
test('a cached name cannot bypass validation of a later malformed occurrence',async()=>{
 const n=name('Same'),first=definition(n),second=definition({...n,metadata:{accepted:true}});const r=await checkOwnedAdmissions(batch([first,second]));assert.equal(r.accepted,false);assert.equal(r.errorKind,'invalid-wire-shape');
});
test('cached numeric and string values remain strictly validated',async()=>{
 for(const second of [definition(name('Bad'),'-0'),definition(name('Bad'),'01'),definition(name('\ud800'))]){const r=await checkOwnedAdmissions(batch([definition(name('Valid')),second]));assert.equal(r.accepted,false);assert(['invalid-natural','invalid-text'].includes(r.errorKind));}
});
test('only bounded reductions of the default heap budget are configurable',async()=>{
 for(const maxMemoryMb of [0,15,513,NaN,Infinity,'32',16.5])await assert.rejects(checkOwnedAdmissions(batch([]),{maxMemoryMb}),/Invalid owned kernel resource limit/);
});
test('large decoding respects the default heap and explicit heap exhaustion rejects',async()=>{
 const input=batch(Array.from({length:5000},(_,i)=>definition(name('x'.repeat(256)+i))));
 const normal=await checkOwnedAdmissions(input,{maxSteps:0,timeoutMs:120000});assert.equal(normal.accepted,false);assert.equal(normal.errorKind,'outOfFuel');
 const exhausted=await checkOwnedAdmissions(input,{maxSteps:0,maxMemoryMb:16,timeoutMs:120000});assert.equal(exhausted.accepted,false);assert.equal(exhausted.errorKind,'memory-limit');assert.equal(exhausted.environment,undefined);
 assert.equal((await checkOwnedAdmissions(batch([]))).accepted,true);
});
