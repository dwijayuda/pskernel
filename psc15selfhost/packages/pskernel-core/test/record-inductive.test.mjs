import test from 'node:test';
import assert from 'node:assert/strict';
import {k,list,expression,drive,tag,decodeExpr,normal,convert} from './checker-values.mjs';
import {runtimeName} from './fixture-values.mjs';
import {unit,definition} from './unit-values.mjs';
import {N,Z,S,U,B,C,app,pi,lam,record,member,literal,value,firstFieldRec,bootstrap,joint} from './record-values.mjs';

for(const count of [1,2,3,8,16])test('closed record admits '+count+' fields and an exactly applied constructor',()=>{
 const entries=[record('R',Array(count).fill(C('Nat'))),definition('Use',[],C('R'),value('R',Array.from({length:count},(_,i)=>literal(i))))];
 assert.equal(bootstrap(entries).status,'admitted');
});
test('records can contain previously admitted records without recursive authority',()=>{
 const pos=value('Pos',[literal(0),literal(1),literal(2)]);
 assert.equal(bootstrap([record('Pos',Array(3).fill(C('Nat'))),record('Span',[C('Pos'),C('Pos')]),definition('Use',[],C('Span'),value('Span',[pos,pos]))]).status,'admitted');
});
test('closed function fields and definitionally equal field types remain checked',()=>{
 const fn=pi('n',C('Nat'),C('Nat'));
 const entries=[definition('Alias',[],U(S(Z)),C('Nat')),record('R',[C('Alias'),fn]),definition('Use',[],C('R'),value('R',[literal(42),lam('n',C('Nat'),B(0))]))];
 assert.equal(bootstrap(entries).status,'admitted');
});
for(const count of [1,2,3,8])test('derived record recursor has a checked dependent type with '+count+' fields',()=>{
 const result=bootstrap([record('R',Array(count).fill(C('Nat'))),definition('Use',[],C('Nat'),firstFieldRec('R',count))]);
 assert.equal(result.status,'admitted');
});
test('derived record metadata preserves forward field order',()=>{
 const admitted=bootstrap([record('Inner',[C('Nat')]),record('Outer',[C('Nat'),C('Inner')])]);
 assert.equal(admitted.status,'admitted');
 const rec=admitted.result.environment.head,family=admitted.result.environment.tail.tail.head;
 assert.equal(tag(rec),'recordRecursor');assert.equal(tag(family),'recordFamily');
 assert.deepEqual(decodeExpr(rec.fields.head),C('Nat'));assert.deepEqual(decodeExpr(rec.fields.tail.head),C('Inner'));
 assert.deepEqual(rec.fields,family.fields);
});
for(const [label,entries,error] of [
 ['anonymous family',[record(['anonymous'])],'invalidName'],
 ['anonymous constructor',[record('R',[C('Nat')],{ctorName:['anonymous']})],'invalidName'],
 ['universe parameters',[record('R',[C('Nat')],{parameters:[N('u')]})],'unsupported'],
 ['Prop family',[record('R',[C('Nat')],{level:Z})],'unsupported'],
 ['higher universe family',[record('R',[C('Nat')],{level:S(S(Z))})],'unsupported'],
 ['zero fields through record route',[record('R',[])],'unsupported'],
 ['unknown field type',[record('R',[C('Missing')])],'unknownConstant'],
 ['field term used as a type',[record('R',[literal(0)])],'typeMismatch'],
 ['field universe too high',[record('R',[U(S(Z))])],'typeMismatch'],
 ['free bound field',[record('R',[B(0)])],'invalidScope'],
 ['dependent second field',[record('R',[U(Z),B(0)])],'invalidScope'],
 ['recursive field',[record('R',[C('R')])],'unknownConstant'],
 ['negative recursive field',[record('R',[pi('bad',C('R'),C('Nat'))])],'unknownConstant'],
 ['wrong constructor result',[record('R',[C('Nat')],{ctorType:pi('x',C('Nat'),C('Nat'))})],'typeMismatch'],
 ['applied constructor result',[record('R',[C('Nat')],{ctorType:pi('x',C('Nat'),app(C('R'),B(0)))})],'typeMismatch'],
 ['extra result universe',[record('R',[C('Nat')],{ctorType:pi('x',C('Nat'),C('R',[Z]))})],'invalidUniverse'],
 ['constructor equals family',[record('R',[C('Nat')],{ctorName:N('R')})],'duplicateName'],
 ['constructor equals recursor',[record('R',[C('Nat')],{ctorName:member('R','rec')})],'duplicateName'],
 ['duplicate record family',[record('R'),record('R')],'duplicateName'],
 ['existing constructor',[unit(member('R','mk')),record('R')],'duplicateName'],
 ['existing recursor',[unit(member('R','rec')),record('R')],'duplicateName'],
 ['forward reference',[definition('Use',[],C('R'),value('R',[literal(0)])),record('R')],'unknownConstant']
])test('record admission rejects '+label,()=>{
 const result=bootstrap(entries);assert.equal(result.status,'rejected',JSON.stringify({label,status:result.status,error:result.error}));assert.equal(result.error,error);assert.equal(result.result.environment,undefined);
});
for(const [label,args] of [['missing',[]],['extra',[literal(0),literal(1)]],['wrong field type',[U(Z)]]])test('record constructor rejects '+label+' arguments',()=>{
 const result=bootstrap([record('R'),definition('Bad',[],C('R'),value('R',args))]);assert.equal(result.status,'rejected');assert.equal(result.result.environment,undefined);
});
test('record recursor rejects wrong major, minor and universe arity',()=>{
 const good=firstFieldRec('R',2);
 const badMajor=structuredClone(good);badMajor[2]=literal(0);
 const badMinor=structuredClone(good);badMinor[1][2]=lam('x',C('Nat'),lam('y',U(Z),literal(0)));
 for(const term of [badMajor,badMinor,app(C(member('R','rec'),[]),lam('m',C('R'),C('Nat')))]){
  const result=bootstrap([record('R',Array(2).fill(C('Nat'))),definition('Bad',[],C('Nat'),term)]);assert.equal(result.status,'rejected');assert.equal(result.result.environment,undefined);
 }
});
test('raw record metadata cannot be admitted through the definition path',()=>{
 const name=runtimeName(k,N('Forged')),ctor=runtimeName(k,member('Forged','mk')),fields=list([expression(C('Nat'))]);
 for(const entry of [k.PsKernelDefinition.recordFamily(name,ctor,fields),k.PsKernelDefinition.recordRecursor(name,list([]),expression(U(Z)),ctor,fields)]){
  const result=drive(k.psKernelJointStep,k.psKernelJointStart(list([k.PsKernelJointEntry.definition(entry)])));
  assert.equal(result.status,'rejected');assert.equal(result.error,'unsupported');assert.equal(result.result.environment,undefined);
 }
});
test('record typing and metadata derivation consume the same exact budget',()=>{
 const entries=[record('R',Array(3).fill(C('Nat')))];const done=bootstrap(entries);assert.equal(done.status,'admitted');
 assert.equal(bootstrap(entries,done.steps-1).status,'outOfFuel');assert.equal(bootstrap(entries,done.steps).status,'admitted');
 for(const budget of [0,1,32,128,512]){const result=bootstrap(entries,budget);assert.equal(result.status,'outOfFuel');assert.equal(result.result?.environment,undefined);}
});
test('record rejection and previous success expose no fresh-session authority',()=>{
 assert.equal(bootstrap([record('R')]).status,'admitted');
 assert.equal(bootstrap([definition('Use',[],C('R'),value('R',[literal(0)]))]).error,'unknownConstant');
 const rejected=bootstrap([record('R'),definition('Bad',[],C('R'),literal(0))]);assert.equal(rejected.status,'rejected');assert.equal(rejected.result.environment,undefined);
});
test('record iota now executes the source-owned record rule',()=>{
 const admitted=bootstrap([record('R')]);assert.equal(admitted.status,'admitted');
 const result=convert(firstFieldRec('R',1),literal(0),admitted.result.environment);assert.equal(result.status,'equal');
});
