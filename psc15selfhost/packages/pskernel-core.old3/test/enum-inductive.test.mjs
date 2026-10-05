import test from 'node:test';import assert from 'node:assert/strict';
import {k,list,expression,drive,infer,check,convert,tag} from './checker-values.mjs';
import {definition} from './unit-values.mjs';import {record,value as recordValue} from './record-values.mjs';
import {enumeration,bootstrap,joint,eliminate,resultWitness,N,Z,S,U,B,C,app,pi,lam,member,literal} from './enum-values.mjs';
const admitted=entries=>{const r=bootstrap(entries);assert.equal(r.status,'admitted',r.error);return r.result.environment;};
for(const count of [2,3,6,10])test('enum derives checked dependent recursor and reduces every branch: '+count,()=>{
 const e=enumeration('E',count),env=admitted([e]);
 for(let i=0;i<count;i++){assert.equal(check(C(e.constructors[i].name),C('E'),env).status,'done');const term=eliminate(e,i),w=resultWitness(term,i+1);
  assert.equal(check(term,C('Nat'),env).status,'done');assert.equal(convert(term,literal(i+1),env,1000000).status,'equal');assert.equal(check(w.value,w.type,env,1000000).status,'done');
  const bad=resultWitness(term,i+2);assert.equal(check(bad.value,bad.type,env,1000000).status,'rejected');}
});
test('enum supports partial eliminator application and neutral major',()=>{
 const e=enumeration('E',3),env=admitted([e]),m=lam('e',C('E'),C('Nat')),minors=e.constructors.map((_,i)=>literal(i));
 const partial=app(C(member('E','rec'),[S(Z)]),m,...minors);assert.equal(check(partial,pi('e',C('E'),C('Nat')),env).status,'done');
 const neutral=lam('e',C('E'),app(partial,B(0)));assert.equal(check(neutral,pi('e',C('E'),C('Nat')),env).status,'done');
 assert.equal(convert(app(neutral,C(e.constructors[2].name)),literal(2),env).status,'equal');
});
test('enum supports Prop-valued dependent elimination without axioms',()=>{
 const e=enumeration('E',2),env=admitted([e]),term=eliminate(e,1,[B(0),B(0)],lam('major',C('E'),B(2)),Z);
 const v=lam('P',U(Z),lam('h',B(0),term)),t=pi('P',U(Z),pi('h',B(0),B(1)));assert.equal(check(v,t,env).status,'done');
});
test('enum reductions compose with aliases, lets, lambda substitution and records',()=>{
 const e=enumeration('E',3),alias=definition('Alias',[],C('E'),C(e.constructors[1].name)),env=admitted([e,alias,record('Holder',[C('E')])]);
 const fn=app(C(member('E','rec'),[S(Z)]),lam('x',C('E'),C('Nat')),literal(3),literal(7),literal(11));
 for(const major of [C('Alias'),['let',N('x'),C('E'),C('Alias'),B(0)],['proj',N('Holder'),'0',recordValue('Holder',[C('Alias')])]]){
  const term=app(fn,major);assert.equal(check(term,C('Nat'),env).status,'done');assert.equal(convert(term,literal(7),env).status,'equal');}
 const captured=lam('n',C('Nat'),lam('m',C('Nat'),eliminate(e,0,[B(1),B(0),literal(0)])));
 assert.equal(convert(app(captured,literal(7),literal(11)),literal(7),env).status,'equal');
});
const mutations=[
 ['anonymous-family',e=>({...e,name:['anonymous']})],['no-constructors',()=>enumeration('E',0)],['one-constructor',()=>enumeration('E',1)],
 ['universe-parameters',e=>({...e,parameters:[N('u')]})],['Prop-family',e=>({...e,level:Z})],['higher-family',e=>({...e,level:S(S(Z))})],
 ['anonymous-constructor',e=>({...e,constructors:[{...e.constructors[0],name:['anonymous']},e.constructors[1]]})],
 ['duplicate-constructor',e=>({...e,constructors:[e.constructors[0],e.constructors[0]]})],
 ['constructor-is-family',e=>({...e,constructors:[{...e.constructors[0],name:e.name},e.constructors[1]]})],
 ['constructor-is-recursor',e=>({...e,constructors:[{...e.constructors[0],name:member('E','rec')},e.constructors[1]]})],
 ['wrong-result',e=>({...e,constructors:[{...e.constructors[0],type:C('Nat')},e.constructors[1]]})],
 ['result-universe',e=>({...e,constructors:[{...e.constructors[0],type:C('E',[Z])},e.constructors[1]]})],
 ['result-application',e=>({...e,constructors:[{...e.constructors[0],type:app(C('E'),literal(0))},e.constructors[1]]})],
 ['constructor-field',e=>({...e,constructors:[{...e.constructors[0],type:pi('n',C('Nat'),C('E'))},e.constructors[1]]})],
 ['recursive-field',e=>({...e,constructors:[{...e.constructors[0],type:pi('r',C('E'),C('E'))},e.constructors[1]]})],
 ['negative-recursion',e=>({...e,constructors:[{...e.constructors[0],type:pi('f',pi('e',C('E'),C('Nat')),C('E'))},e.constructors[1]]})],
 ['free-result',e=>({...e,constructors:[{...e.constructors[0],type:B(0)},e.constructors[1]]})]
];
for(const [label,mutate]of mutations)test('enum admission rejects '+label,()=>{const out=bootstrap([mutate(enumeration('E',2))]);assert.equal(out.status,'rejected');assert.equal(out.result.environment,undefined);});
for(const name of [N('E'),member('E','c0'),member('E','rec')])test('enum rejects existing name '+JSON.stringify(name),()=>{
 const prior={...definition('unused',[],C('Nat'),literal(0)),name},out=bootstrap([prior,enumeration('E',2)]);assert.equal(out.status,'rejected');assert.equal(out.result.environment,undefined);
});
test('enum recursor rejects wrong major, branches, overapplication and universe arity',()=>{
 const e=enumeration('E',2),env=admitted([e,enumeration('Other',2)]),fn=C(member('E','rec'),[S(Z)]),m=lam('e',C('E'),C('Nat'));
 for(const term of [app(fn,m,literal(1),U(Z),C(e.constructors[0].name)),app(fn,m,literal(1),literal(2),C(member('Other','c0'))),app(eliminate(e,0),literal(1)),C(member('E','rec')),C(member('E','rec'),[Z,Z])])assert.equal(check(term,C('Nat'),env).status,'rejected');
});
test('enum declarations check full names, not dotted display aliases',()=>{
 const a=N('Name.Child'),b=['str',N('Name'),'Child'],first=enumeration(a,2),second=enumeration(b,2),env=admitted([first,second]);
 assert.equal(check(C(first.constructors[0].name),C(second.name),env).status,'rejected');
});
test('enum checking and recursor reduction share exact outer fuel',()=>{
 const e=enumeration('E',6),w=resultWitness(eliminate(e,4),5),entries=[e,definition('Witness',[],w.type,w.value)],done=bootstrap(entries);assert.equal(done.status,'admitted');
 const short=bootstrap(entries,done.steps-1);assert.equal(short.status,'outOfFuel');assert.equal(short.result?.environment,undefined);assert.equal(bootstrap(entries,done.steps).status,'admitted');
 const env=admitted([e]),term=expression(eliminate(e,4)),finish=drive(k.psKernelReduceStep,k.psKernelNormalStart(env,term),1000000);assert.equal(finish.status,'done');
 assert.equal(drive(k.psKernelReduceStep,k.psKernelNormalStart(env,term),finish.steps-1).status,'outOfFuel');
});
test('raw enum recursor metadata cannot enter through definition admission',()=>{
 const env=admitted([enumeration('E',2)]),entry=env.head;assert.equal(tag(entry),'enumRecursor');
 const out=drive(k.psKernelJointStep,k.psKernelJointStart(list([k.PsKernelJointEntry.definition(entry)])),1000000);assert.equal(out.status,'rejected');assert.equal(out.result.environment,undefined);
});
test('enum batches are atomic and fresh sessions do not inherit authority',()=>{
 const e=enumeration('E',6),bad=structuredClone(e);bad.constructors[5].name=bad.constructors[0].name;
 assert.equal(bootstrap([e]).status,'admitted');assert.equal(bootstrap([bad]).status,'rejected');assert.equal(bootstrap([definition('Bad',[],C('E'),C(e.constructors[0].name))]).status,'rejected');
});
