import test from 'node:test';
import assert from 'node:assert/strict';
import {k,expression,drive,tag,normal,convert,check,infer} from './checker-values.mjs';
import {definition,unit} from './unit-values.mjs';
import {N,Z,S,U,B,C,app,pi,lam,record,member,literal,value,firstFieldRec,bootstrap} from './record-values.mjs';
const P=(family,index,major)=>['proj',Array.isArray(family)?family:N(family),String(index),major];
const envFor=(entries)=>{const out=bootstrap(entries);assert.equal(out.status,'admitted',out.error);return out.result.environment;};
const equal=(a,b,env)=>assert.equal(convert(a,b,env,1000000).status,'equal');
const witness=(term,n)=>({type:pi('F',pi('n',C('Nat'),U(S(Z))),pi('h',app(B(0),literal(n)),app(B(1),term))),
 value:lam('F',pi('n',C('Nat'),U(S(Z))),lam('h',app(B(0),literal(n)),B(0)))});
for(const count of [1,2,3,8,16])test('projection typing and reduction checks every field of width '+count,()=>{
 const env=envFor([record('R',Array(count).fill(C('Nat')))]),args=Array.from({length:count},(_,i)=>literal(2*i+1)),major=value('R',args);
 for(let i=0;i<count;i++){const p=P('R',i,major);assert.equal(infer(p,env).status,'done');equal(p,args[i],env);const w=witness(p,2*i+1);assert.equal(check(w.value,w.type,env,1000000).status,'done');}
});
for(const count of [1,2,3,8])test('record iota applies every field in forward order: '+count,()=>{
 const env=envFor([record('R',Array(count).fill(C('Nat')))]),args=Array.from({length:count},(_,i)=>literal(i+1));
 for(let i=0;i<count;i++){const minor=Array(count).fill(C('Nat')).reduceRight((b,t,j)=>lam('f'+j,t,b),B(count-i-1));
  const term=app(C(member('R','rec'),[S(Z)]),lam('r',C('R'),C('Nat')),minor,value('R',args));
  assert.equal(check(term,C('Nat'),env).status,'done');equal(term,args[i],env);const w=witness(term,i+1);assert.equal(check(w.value,w.type,env,1000000).status,'done');}
});
test('wrong computed projection and iota equalities reject during dependent checking',()=>{
 const env=envFor([record('R',[C('Nat'),C('Nat')])]);
 for(const term of [P('R',1,value('R',[literal(3),literal(7)])),firstFieldRec('R',2,value('R',[literal(7),literal(3)]))]){
  const w=witness(term,3);assert.equal(check(w.value,w.type,env,1000000).status,'rejected');}
});
test('nested records, transparent aliases, and function-valued fields reduce',()=>{
 const fun=pi('n',C('Nat'),C('Nat')),env=envFor([record('R',[C('Nat')]),record('Outer',[C('R'),fun]),definition('Alias',[],C('R'),value('R',[literal(9)]))]);
 equal(P('R',0,C('Alias')),literal(9),env);
 const outer=value('Outer',[C('Alias'),lam('n',C('Nat'),B(0))]);equal(P('R',0,P('Outer',0,outer)),literal(9),env);
 const call=app(P('Outer',1,outer),literal(11));assert.equal(check(call,C('Nat'),env).status,'done');equal(call,literal(11),env);
});
test('binding traversal preserves projection scope under lambdas and lets',()=>{
 const env=envFor([record('R',[C('Nat')])]);
 const neutral=lam('r',C('R'),lam('n',C('Nat'),P('R',0,B(1))));assert.equal(check(neutral,pi('r',C('R'),pi('n',C('Nat'),C('Nat'))),env).status,'done');
 equal(app(neutral,value('R',[literal(7)]),literal(11)),literal(7),env);
 const captured=lam('x',C('Nat'),lam('y',C('Nat'),P('R',0,value('R',[B(1)]))));equal(app(captured,literal(7),literal(11)),literal(7),env);
 const letTerm=['let',N('r'),C('R'),value('R',[literal(13)]),P('R',0,B(0))];assert.equal(check(letTerm,C('Nat'),env).status,'done');equal(letTerm,literal(13),env);
});
test('neutral projection conversion compares family, index, and normalized scrutinee',()=>{
 const env=envFor([record('R',[C('Nat'),C('Nat')]),record('Other',[C('Nat'),C('Nat')])]);
 equal(P('R',0,B(0)),P('R',0,app(lam('r',C('R'),B(0)),B(0))),env);
 for(const p of [P('R',1,B(0)),P('Other',0,B(0)),P('R',0,B(1))])assert.equal(convert(P('R',0,B(0)),p,env).status,'different');
});
for(const index of [1,2,16,4294967296n,9007199254740993n,1n<<256n])test('out of bounds projection rejects even for neutral major: '+index,()=>{
 const env=envFor([record('R')]);const term=lam('r',C('R'),P('R',index,B(0)));
 assert.equal(check(term,pi('r',C('R'),C('Nat')),env).status,'rejected');assert.equal(normal(term,env).status,'rejected');
});
for(const [label,term]of [
 ['wrong-family',P('Other',0,value('R',[literal(1),literal(2)]))],
 ['non-record-family',P('Nat',0,literal(0))],['unknown-family',P('Missing',0,value('R',[literal(1),literal(2)]))],
 ['wrong-major',P('R',0,literal(0))],['missing-field',P('R',0,value('R',[literal(1)]))],
 ['extra-field',P('R',0,value('R',[literal(1),literal(2),literal(3)]))],
 ['discarded-bad-field',P('R',0,value('R',[literal(1),U(Z)]))],
 ['constructor-universe',P('R',0,app(C(member('R','mk'),[Z]),literal(1),literal(2)))],
 ['free-major',P('R',0,B(0))]
])test('projection admission rejects '+label,()=>{
 const result=bootstrap([record('R',[C('Nat'),C('Nat')]),record('Other',[C('Nat'),C('Nat')]),definition('Bad',[],C('Nat'),term)]);
 assert.equal(result.status,'rejected');assert.equal(result.result.environment,undefined);
});
test('record iota never discards an ill-typed constructor field during checking',()=>{
 const result=bootstrap([record('R',[C('Nat'),C('Nat')]),definition('Bad',[],C('Nat'),firstFieldRec('R',2,value('R',[literal(7),U(Z)])))]);
 assert.equal(result.status,'rejected');assert.equal(result.result.environment,undefined);
});
test('projection and iota use exact shared budgets for inference, conversion, and whole admission',()=>{
 const entries=[record('R',[C('Nat'),C('Nat')])],env=envFor(entries),term=P('R',1,value('R',[literal(3),literal(7)]));
 for(const [step,start]of [[k.psKernelTypeStep,()=>k.psKernelInferStart(env,expression(term))],[k.psKernelReduceStep,()=>k.psKernelNormalStart(env,expression(term))],[k.psKernelConversionStep,()=>k.psKernelConversionStart(env,expression(term),expression(literal(7)))]]){
  const done=drive(step,start(),1000000);assert.ok(['done','equal'].includes(done.status),done.status);assert.equal(drive(step,start(),done.steps-1).status,'outOfFuel');assert.equal(drive(step,start(),done.steps).status,done.status);}
 const w=witness(term,7),all=[...entries,definition('Use',[],w.type,w.value)],done=bootstrap(all);assert.equal(done.status,'admitted');
 assert.equal(bootstrap(all,done.steps-1).status,'outOfFuel');assert.equal(bootstrap(all,done.steps).status,'admitted');
});
