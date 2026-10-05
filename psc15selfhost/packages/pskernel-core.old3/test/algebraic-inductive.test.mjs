import test from 'node:test';import assert from 'node:assert/strict';
import {k,list,expression,drive,check,convert,tag} from './checker-values.mjs';
import {family,bootstrap,value,eliminate,resultWitness,N,Z,S,U,B,C,app,pi,lam,member,literal,T,d} from './algebraic-values.mjs';
const accepted=entries=>{const r=bootstrap(entries);assert.equal(r.status,'admitted',JSON.stringify({error:r.error,steps:r.steps}));return r.result.environment;};
const witness=(term,n,env)=>{const w=resultWitness(term,n);assert.equal(check(w.value,w.type,env,4000000).status,'done');const bad=resultWitness(term,n+1);assert.equal(check(bad.value,bad.type,env,4000000).status,'rejected');};
test('uniform option validates the constructor, dependent eliminator and both branches',()=>{
 const e=family('O',1,[[],[B(0)]]),env=accepted([e]),ty=app(C('O'),C('Nat')),m=lam('o',ty,C('Nat')),minors=[literal(2),lam('a',C('Nat'),B(0))];
 for(const [i,args,n]of [[0,[],2],[1,[literal(7)],7]]){const v=value(e,i,[C('Nat')],args);assert.equal(check(v,ty,env).status,'done');witness(eliminate(e,[C('Nat')],m,minors,v),n,env);}
});
test('two different type parameters and forward field order remain distinct',()=>{
 const e=family('P',2,[[B(1),B(0)]]),env=accepted([e]),fn=pi('x',C('Nat'),C('Nat')),ty=app(C('P'),C('Nat'),fn),v=value(e,0,[C('Nat'),fn],[literal(7),lam('x',C('Nat'),B(0))]);
 const branch=lam('a',C('Nat'),lam('f',fn,app(B(0),B(1)))),term=eliminate(e,[C('Nat'),fn],lam('p',ty,C('Nat')),[branch],v);witness(term,7,env);
 assert.equal(check(value(e,0,[C('Nat'),fn],[lam('x',C('Nat'),B(0)),literal(7)]),ty,env).status,'rejected');
});
test('direct recursive list derives and computes its induction hypothesis',()=>{
 const e=family('L',1,[[],[B(0),app(C('L'),B(0))]]),env=accepted([e]),ty=app(C('L'),C('Nat')),nil=value(e,0,[C('Nat')]),cons=(h,t)=>value(e,1,[C('Nat')],[literal(h),t]);
 const minor=lam('head',C('Nat'),lam('tail',ty,lam('ih',C('Nat'),app(C(member('Nat','succ')),B(0)))));
 for(const [major,n]of [[nil,0],[cons(7,nil),1],[cons(7,cons(11,nil)),2]])witness(eliminate(e,[C('Nat')],lam('l',ty,C('Nat')),[literal(0),minor],major),n,env);
});
test('two recursive fields receive two hypotheses in forward order',()=>{
 const e=family('Tree',0,[[],[C('Tree'),C('Tree')]]),env=accepted([e]),leaf=value(e,0),node=(l,r)=>value(e,1,[],[l,r]);
 const minor=[['l',C('Tree')],['r',C('Tree')],['ihl',C('Nat')],['ihr',C('Nat')]].reduceRight((body,[name,type])=>lam(name,type,body),app(C(member('Nat','succ')),B(0)));
 witness(eliminate(e,[],lam('t',C('Tree'),C('Nat')),[literal(0),minor],node(leaf,node(leaf,leaf))),2,env);
});
const badConstructor=(e,type)=>({...e,constructors:[{...e.constructors[0],type},...e.constructors.slice(1)]});
const invalid=[
 ['anonymous family',e=>({...e,name:['anonymous']})],['empty family',e=>({...e,constructors:[]})],
 ['parameter count mismatch',e=>({...e,parameterCount:2})],['non-type parameter',e=>({...e,type:pi('a',C('Nat'),T)})],
 ['Prop family',e=>({...e,type:pi('a',T,U(Z))})],['higher family',e=>({...e,type:pi('a',T,U(S(S(Z))))})],
 ['extra index',e=>({...e,type:pi('a',T,pi('n',C('Nat'),T))})],['unbound family',e=>({...e,type:pi('a',B(0),T)})],
 ['unknown field',()=>family('O',1,[[C('Missing')]])],['field is term',()=>family('O',1,[[literal(0)]])],
 ['higher field',()=>family('O',1,[[T]])],['free field',()=>family('O',1,[[B(1)]])],
 ['negative parameter field',()=>family('O',1,[[pi('a',B(0),C('Nat'))]])],
 ['function-valued parameter field',()=>family('O',1,[[pi('n',C('Nat'),B(1))]])],
 ['negative recursive field',()=>family('O',1,[[pi('o',app(C('O'),B(0)),C('Nat'))]])],
 ['nonuniform recursion',()=>family('O',1,[[app(C('O'),C('Nat'))]])],
 ['self applied with missing parameter',()=>family('O',1,[[C('O')]])],
 ['wrong constructor result',e=>badConstructor(e,pi('a',T,C('Nat')))],
 ['constructor missing parameter',e=>badConstructor(e,app(C('O'),C('Nat')))],
 ['constructor parameter wrong domain',e=>badConstructor(e,pi('a',C('Nat'),app(C('O'),T)))],
 ['constructor specialized result',e=>badConstructor(e,pi('a',T,app(C('O'),C('Nat'))))],
 ['constructor universe application',e=>badConstructor(e,pi('a',T,app(C('O',[Z]),B(0))))],
 ['anonymous constructor',e=>({...e,constructors:[{...e.constructors[0],name:['anonymous']}]})],
 ['duplicate constructor',e=>({...e,constructors:[e.constructors[0],e.constructors[0]]})],
 ['constructor is family',e=>({...e,constructors:[{...e.constructors[0],name:N('O')}]})],
 ['constructor is recursor',e=>({...e,constructors:[{...e.constructors[0],name:member('O','rec')}]})],
 ['term-dependent field',e=>badConstructor(e,pi('a',T,pi('x',B(0),pi('bad',B(0),app(C('O'),B(2))))))]
];
for(const [label,change]of invalid)test('algebraic admission rejects '+label,()=>{const r=bootstrap([change(family('O',1,[[],[B(0)]]))]);assert.equal(r.status,'rejected',label);assert.equal(r.result.environment,undefined);});
for(const name of [N('O'),member('O','c0'),member('O','rec')])test('algebraic full-name freshness '+JSON.stringify(name),()=>{assert.equal(bootstrap([{...d('prior',C('Nat'),literal(0)),name},family('O',1,[[],[B(0)]])]).status,'rejected');});
test('validated covariant family parameters compose without granting nested-recursion support',()=>{
 const opt=family('O',1,[[],[B(0)]]),wrap=family('W',1,[[app(C('O'),B(0))]]),env=accepted([opt,wrap]);
 const ov=value(opt,1,[C('Nat')],[literal(7)]),wv=value(wrap,0,[C('Nat')],[ov]);assert.equal(check(wv,app(C('W'),C('Nat')),env).status,'done');
 const nested=family('L',1,[[],[app(C('O'),app(C('L'),B(0)))]]);const r=bootstrap([opt,nested]);assert.equal(r.status,'rejected');assert.equal(r.error,'unsupported');assert.equal(r.result.environment,undefined);
});
test('previous field variables cannot escape parameter-only templates',()=>{
 const f=d('F',pi('n',C('Nat'),T),lam('n',C('Nat'),C('Nat'))),e=family('O',1,[[]]);
 e.constructors[0].type=pi('a',T,pi('x',C('Nat'),pi('y',app(C('F'),B(0)),app(C('O'),B(2)))));
 assert.equal(bootstrap([f,e]).status,'rejected');
});
test('algebraic constructor and recursor arguments are all type checked',()=>{
 const e=family('O',1,[[],[B(0)]]),env=accepted([e]),ty=app(C('O'),C('Nat')),m=lam('o',ty,C('Nat')),v=value(e,1,[C('Nat')],[literal(7)]);
 const terms=[value(e,1,[C('Nat')],[]),value(e,1,[C('Nat')],[U(Z)]),value(e,1,[C('Nat')],[literal(7),literal(8)]),value(e,1,[],[literal(7)]),value(e,1,[U(Z)],[literal(7)]),eliminate(e,[C('Nat')],m,[literal(0),U(Z)],v),eliminate(e,[C('Nat')],m,[literal(0),lam('x',C('Nat'),B(0))],literal(1)),C(member('O','rec')),C(member('O','rec'),[Z,Z])];
 for(const term of terms)assert.equal(check(term,C('Nat'),env,4000000).status,'rejected',JSON.stringify(term));
 const discarded=value(e,1,[C('Nat')],[U(Z)]),term=eliminate(e,[C('Nat')],m,[literal(0),lam('x',C('Nat'),literal(2))],discarded);assert.equal(bootstrap([e,d('Bad',C('Nat'),term)]).status,'rejected');
});
test('algebraic reduction handles partial application, outer binders and functional results',()=>{
 const e=family('O',1,[[],[B(0)]]),env=accepted([e]),ty=app(C('O'),C('Nat')),fn=pi('n',C('Nat'),C('Nat')),v=value(e,1,[C('Nat')],[literal(7)]);
 const term=eliminate(e,[C('Nat')],lam('o',ty,fn),[lam('n',C('Nat'),B(0)),lam('x',C('Nat'),lam('n',C('Nat'),B(1)))],v);witness(app(term,literal(11)),7,env);
 const rec=app(C(member('O','rec'),[S(Z)]),C('Nat'),lam('o',ty,C('Nat')),literal(0),lam('x',C('Nat'),B(0)));assert.equal(check(rec,pi('o',ty,C('Nat')),env).status,'done');
 const capture=lam('outer',C('Nat'),eliminate(e,[C('Nat')],lam('o',ty,C('Nat')),[B(0),lam('x',C('Nat'),B(1))],v));witness(app(capture,literal(11)),11,env);
});
test('algebraic checks share exact fuel and never expose partial or forged metadata',()=>{
 const e=family('O',1,[[],[B(0)]]),ty=app(C('O'),C('Nat')),term=eliminate(e,[C('Nat')],lam('o',ty,C('Nat')),[literal(0),lam('x',C('Nat'),B(0))],value(e,1,[C('Nat')],[literal(7)])),w=resultWitness(term,7),entries=[e,d('Witness',w.type,w.value)],r=bootstrap(entries);assert.equal(r.status,'admitted');assert.equal(bootstrap(entries,r.steps-1).status,'outOfFuel');assert.equal(bootstrap(entries,r.steps).status,'admitted');
 const env=accepted([e]);for(let p=env;tag(p)!=='nil';p=p.tail){if(['algebraicFamily','algebraicRecursor'].includes(tag(p.head)))assert.equal(drive(k.psKernelJointStep,k.psKernelJointStart(list([k.PsKernelJointEntry.definition(p.head)]))).status,'rejected');}
 assert.equal(bootstrap([e,e]).status,'rejected');assert.equal(bootstrap([d('Leak',ty,value(e,0,[C('Nat')]))]).status,'rejected');
});
