import test from 'node:test';import assert from 'node:assert/strict';
import {k,list,expression,drive,check,convert,tag} from './checker-values.mjs';import {definition} from './unit-values.mjs';import {record,value as recordValue} from './record-values.mjs';import {enumeration} from './enum-values.mjs';
import {sum,bootstrap,value,eliminate,resultWitness,N,Z,S,U,B,C,app,pi,lam,member,literal} from './sum-values.mjs';
const admitted=entries=>{const r=bootstrap(entries);assert.equal(r.status,'admitted',r.error);return r.result.environment;};
for(const widths of [[0,1],[1,0],[1,2,0],[0,3,1,2],[4,0,2]])test('closed sum checks payloads, all branch reductions and dependent witnesses '+widths,()=>{
 const fields=widths.map(n=>Array.from({length:n},()=>C('Nat'))),e=sum('Choice',fields),env=admitted([e]);
 const minors=fields.map((ts,i)=>ts.reduceRight((b,t,j)=>lam('f'+j,t,b),ts.length?B(0):literal(30+i)));
 for(let i=0;i<widths.length;i++){const args=fields[i].map((_,j)=>literal(10+j)),expect=widths[i]?9+widths[i]:30+i,term=eliminate(e,i,args,minors);
  assert.equal(check(value(e,i,args),C(e.name),env).status,'done');assert.equal(check(term,C('Nat'),env,2000000).status,'done');assert.equal(convert(term,literal(expect),env,2000000).status,'equal');
  for(const [n,status]of [[expect,'done'],[expect+1,'rejected']]){const w=resultWitness(term,n);assert.equal(check(w.value,w.type,env,2000000).status,status);}}
});
test('sum returns the first field without reversing payload order',()=>{
 const e=sum('S',[[C('Nat'),C('Nat')],[]]),env=admitted([e]),term=eliminate(e,0,[literal(7),literal(11)],[lam('a',C('Nat'),lam('b',C('Nat'),B(1))),literal(0)]);
 const w=resultWitness(term,7);assert.equal(check(w.value,w.type,env).status,'done');
});
test('sum supports closed function payloads and previously checked record and enum types',()=>{
 const rec=record('Pair',[C('Nat'),C('Nat')]),en=enumeration('Tag',2),e=sum('S',[[C('Pair')],[pi('n',C('Nat'),C('Nat'))],[C('Tag')]]),env=admitted([rec,en,e]);
 const minors=[lam('p',C('Pair'),['proj',N('Pair'),'1',B(0)]),lam('f',pi('n',C('Nat'),C('Nat')),app(B(0),literal(9))),lam('t',C('Tag'),literal(5))];
 const majors=[[recordValue('Pair',[literal(7),literal(11)])],[lam('n',C('Nat'),B(0))],[C(member('Tag','c1'))]];
 for(const [i,n]of [[0,11],[1,9],[2,5]]){const t=eliminate(e,i,majors[i],minors),w=resultWitness(t,n);assert.equal(check(w.value,w.type,env,2000000).status,'done');}
});
test('sum aliases, let substitution and outer lambda capture preserve binding',()=>{
 const e=sum('S',[[C('Nat')],[]]),alias=definition('Alias',[],C('S'),value(e,0,[literal(7)])),env=admitted([e,alias]);
 const fn=app(C(member('S','rec'),[S(Z)]),lam('s',C('S'),C('Nat')),lam('n',C('Nat'),B(0)),literal(2));
 for(const major of [C('Alias'),['let',N('s'),C('S'),C('Alias'),B(0)]])assert.equal(convert(app(fn,major),literal(7),env).status,'equal');
 const capture=lam('outside',C('Nat'),eliminate(e,0,[literal(11)],[lam('payload',C('Nat'),B(1)),B(0)]));assert.equal(convert(app(capture,literal(7)),literal(7),env).status,'equal');
});
test('sum recursor allows neutral/partial applications and functional result overapplication',()=>{
 const e=sum('S',[[C('Nat')],[]]),env=admitted([e]);
 const fn=app(C(member('S','rec'),[S(Z)]),lam('s',C('S'),C('Nat')),lam('n',C('Nat'),B(0)),literal(2));assert.equal(check(fn,pi('s',C('S'),C('Nat')),env).status,'done');
 assert.equal(check(lam('s',C('S'),app(fn,B(0))),pi('s',C('S'),C('Nat')),env).status,'done');
 const motive=lam('s',C('S'),pi('x',C('Nat'),C('Nat'))),minors=[lam('payload',C('Nat'),lam('x',C('Nat'),B(1))),lam('x',C('Nat'),B(0))];
 assert.equal(convert(app(eliminate(e,0,[literal(7)],minors,motive),literal(11)),literal(7),env).status,'equal');
});
test('sum supports Prop-valued elimination under an explicit assumed proposition',()=>{
 const e=sum('S',[[C('Nat')],[]]),env=admitted([e]);const term=eliminate(e,0,[literal(7)],[lam('n',C('Nat'),B(1)),B(0)],lam('s',C('S'),B(2)),Z);
 assert.equal(check(lam('P',U(Z),lam('h',B(0),term)),pi('P',U(Z),pi('h',B(0),B(1))),env).status,'done');
});
const mutation=(e,index,type)=>({...e,constructors:e.constructors.map((c,i)=>i===index?{...c,type}:c)});
const cases=[['anonymous family',e=>({...e,name:['anonymous']})],['no constructors',()=>sum('S',[])],['one constructor',()=>sum('S',[[C('Nat')]])],['universe parameters',e=>({...e,parameters:[N('u')]})],['Prop family',e=>({...e,level:Z})],['higher family',e=>({...e,level:S(S(Z))})],
 ['unknown field',e=>mutation(e,0,pi('x',C('Missing'),C('S')))],['field term not type',e=>mutation(e,0,pi('x',literal(0),C('S')))],['field universe too high',e=>mutation(e,0,pi('x',U(S(Z)),C('S')))],['free field',e=>mutation(e,0,pi('x',B(0),C('S')))],
 ['dependent field',e=>mutation(e,0,pi('x',C('Nat'),pi('y',B(0),C('S'))))],['recursive first field',e=>mutation(e,0,pi('x',C('S'),C('S')))],['negative recursive field',e=>mutation(e,0,pi('x',pi('s',C('S'),C('Nat')),C('S')))],
 ['wrong result',e=>mutation(e,0,pi('n',C('Nat'),C('Nat')))],['applied result',e=>mutation(e,0,pi('n',C('Nat'),app(C('S'),B(0))))],['result universe',e=>mutation(e,0,pi('n',C('Nat'),C('S',[Z])))],['free result',e=>mutation(e,0,pi('n',C('Nat'),B(0)))],
 ['anonymous constructor',e=>({...e,constructors:[{...e.constructors[0],name:['anonymous']},e.constructors[1]]})],['duplicate constructor',e=>({...e,constructors:[e.constructors[0],e.constructors[0]]})],
 ['constructor equals family',e=>({...e,constructors:[{...e.constructors[0],name:N('S')},e.constructors[1]]})],['constructor equals recursor',e=>({...e,constructors:[{...e.constructors[0],name:member('S','rec')},e.constructors[1]]})]];
for(const [label,change]of cases)test('sum admission rejects '+label,()=>{const r=bootstrap([change(sum('S',[[C('Nat')],[]]))]);assert.equal(r.status,'rejected',label);assert.equal(r.result.environment,undefined);});
for(const name of [N('S'),member('S','c0'),member('S','rec')])test('sum rejects prior name collision '+JSON.stringify(name),()=>{const prior={...definition('unused',[],C('Nat'),literal(0)),name};const r=bootstrap([prior,sum('S',[[C('Nat')],[]])]);assert.equal(r.status,'rejected');assert.equal(r.result.environment,undefined);});
test('sum rejects wrong major, branch, arity and recursor universe arguments',()=>{
 const e=sum('S',[[C('Nat'),C('Nat')],[]]),env=admitted([e,enumeration('Other',2)]),fn=C(member('S','rec'),[S(Z)]),m=lam('s',C('S'),C('Nat')),branch=lam('a',C('Nat'),lam('b',C('Nat'),B(0)));
 for(const t of [app(fn,m,branch,literal(0),C(member('Other','c0'))),app(fn,m,U(Z),literal(0),value(e,1)),app(fn,m,branch,literal(0),value(e,0,[literal(1)])),app(fn,m,branch,literal(0),value(e,0,[literal(1),U(Z)])),app(fn,m,branch,literal(0),value(e,0,[literal(1),literal(2),literal(3)])),app(eliminate(e,1,[],[branch,literal(0)]),literal(3)),C(member('S','rec')),C(member('S','rec'),[Z,Z])])assert.equal(check(t,C('Nat'),env,2000000).status,'rejected',JSON.stringify(t));
});
test('sum cannot discard an ill-typed constructor field to pass whole admission',()=>{
 const e=sum('S',[[C('Nat'),C('Nat')],[]]),term=eliminate(e,0,[literal(7),U(Z)],[lam('a',C('Nat'),lam('b',C('Nat'),B(1))),literal(0)]),r=bootstrap([e,definition('Bad',[],C('Nat'),term)]);assert.equal(r.status,'rejected');assert.equal(r.result.environment,undefined);
});
test('sum and Nat selection happens before checking and never retries rejected Nat',()=>{
 const e=sum('Counter',[[],[C('Counter')]]),done=bootstrap([e]);assert.equal(done.status,'admitted');assert.equal(tag(done.result.environment.head),'natRecursor');
 const malformed=mutation(e,0,C('Nat'));assert.equal(bootstrap([malformed]).status,'rejected');
 const plain=sum('Plain',[[],[C('Nat')]]),env=admitted([plain]);assert.equal(tag(env.head),'sumRecursor');
 assert.equal(bootstrap([sum('Bad',[[C('Nat')],[C('Bad')]])]).status,'rejected');
});
test('sum field validation, branch construction and iota share the exact outer budget',()=>{
 const e=sum('S',[[C('Nat'),C('Nat')],[]]),term=eliminate(e,0,[literal(7),literal(11)],[lam('a',C('Nat'),lam('b',C('Nat'),B(0))),literal(0)]),w=resultWitness(term,11),entries=[e,definition('Witness',[],w.type,w.value)],done=bootstrap(entries);assert.equal(done.status,'admitted');
 assert.equal(bootstrap(entries,done.steps-1).status,'outOfFuel');assert.equal(bootstrap(entries,done.steps).status,'admitted');
 const env=admitted([e]),state=k.psKernelNormalStart(env,expression(term)),r=drive(k.psKernelReduceStep,state,2000000);assert.equal(r.status,'done');assert.equal(drive(k.psKernelReduceStep,state,r.steps-1).status,'outOfFuel');
});
test('sum admission refuses caller-supplied reduction metadata and has fresh atomic sessions',()=>{
 const e=sum('S',[[C('Nat')],[]]),env=admitted([e]);assert.equal(tag(env.head),'sumRecursor');
 const forged=drive(k.psKernelJointStep,k.psKernelJointStart(list([k.PsKernelJointEntry.definition(env.head)])),2000000);assert.equal(forged.status,'rejected');assert.equal(forged.result.environment,undefined);
 assert.equal(bootstrap([e,{...e}]).status,'rejected');assert.equal(bootstrap([definition('Leak',[],C('S'),value(e,1))]).status,'rejected');
});
test('sum compares full family and constructor names rather than printed aliases',()=>{
 const a=N('Nested.S'),b=['str',N('Nested'),'S'],first=sum(a,[[C('Nat')],[]]),second=sum(b,[[C('Nat')],[]]),env=admitted([first,second]);assert.equal(check(value(first,1),C(second.name),env).status,'rejected');
});
