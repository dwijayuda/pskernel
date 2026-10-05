import assert from 'node:assert/strict';
import {test} from 'node:test';
import {k,list,expression,drive} from './checker-values.mjs';
import {runtimeName} from './fixture-values.mjs';
import {definition} from './unit-values.mjs';
import {N,Z,S,U,B,C,app,pi,lam,nat,numeral,member,identityRec,sortRec,polymorphicFold,joint} from './nat-values.mjs';
const accepted=entries=>{const r=joint(entries);assert.equal(r.status,'admitted',r.error??r.status);return r;};
const rejected=entries=>{const r=joint(entries);assert.equal(r.status,'rejected',r.error??r.status);assert.equal(r.result.environment,undefined);return r;};
const proofType=pi('P',U(Z),pi('p',B(0),B(1)));
test('admits a checked unary recursive family and both constructor uses',()=>accepted([nat(),definition('Zero',[],C('OwnedNat'),numeral(0)),definition('Many',[],C('OwnedNat'),numeral(4))]));
test('derived recursor instantiates a declared universe under dependent term binders',()=>{
 const fold=polymorphicFold(5);accepted([nat(),definition('Fold',['u'],fold.type,fold.value)]);
});
for(const n of [0,1,2,5,12])test('generated recursor typing and both iota rules at depth '+n,()=>{
 const r=accepted([nat(),definition('Identity',[],C('OwnedNat'),identityRec(n)),definition('SortUse',[],sortRec(n),proofType)]);
 const reduced=drive(k.psKernelConversionStep,k.psKernelConversionStart(r.result.environment,expression(identityRec(n)),expression(numeral(n))),1000000);
 assert.equal(reduced.status,'equal');
});
for(const [label,override]of [
 ['anonymous family',{name:['anonymous']}],['anonymous zero',{zeroName:['anonymous']}],['anonymous successor',{succName:['anonymous']}],
 ['family collision',{zeroName:N('OwnedNat')}],['constructor collision',{succName:member('OwnedNat','zero')}],['recursor collision',{succName:member('OwnedNat','rec')}],
 ['Prop family',{familyType:U(Z)}],['higher family universe',{familyType:U(S(S(Z)))}],
 ['unknown result',{zeroType:C('Unknown')}],['wrong zero type',{zeroType:U(Z)}],
 ['nonrecursive successor',{succType:pi('p',U(Z),C('OwnedNat'))}],
 ['negative recursive field',{succType:pi('f',pi('n',C('OwnedNat'),C('OwnedNat')),C('OwnedNat'))}],
 ['binary recursive constructor',{succType:pi('a',C('OwnedNat'),pi('b',C('OwnedNat'),C('OwnedNat')))}],
 ['unbound constructor result',{succType:pi('n',C('OwnedNat'),B(2))}],
 ['extra family universe',{zeroType:C('OwnedNat',[Z])}],
])test('Nat fragment rejects '+label,()=>rejected([nat('OwnedNat',override)]));
test('duplicate complete family does not return its partial environment',()=>rejected([nat(),nat()]));
test('wrong constructor argument is checked even through recursor reduction',()=>rejected([nat(),definition('Bad',[],C('OwnedNat'),app(C(member('OwnedNat','succ')),U(Z)))]));
test('wrong recursor minor and missing universe are rejected',()=>{
 const wrong=sortRec(0);wrong[1][1][2]=U(S(Z));
 rejected([nat(),definition('Bad',[],U(S(Z)),wrong)]);
 rejected([nat(),definition('Bad',[],U(S(Z)),C(member('OwnedNat','rec')))]);
});
test('neutral major does not compute to a constructor',()=>{
 const r=accepted([nat()]);
 const input=sortRec(0);input[2]=B(0);
 const result=drive(k.psKernelConversionStep,k.psKernelConversionStart(r.result.environment,expression(input),expression(U(Z))),1000000);
 assert.equal(result.status,'different');
});
test('fresh admission cannot reuse another batch Nat',()=>{accepted([nat()]);rejected([definition('Bad',[],C('OwnedNat'),numeral(0))]);});
test('forged recursor metadata is never accepted as an external definition',()=>{
 const r=accepted([nat()]);
 const fake=k.PsKernelDefinition.natRecursor(runtimeName(k,N('Forged')),list([]),expression(U(S(Z))),runtimeName(k,member('OwnedNat','zero')),runtimeName(k,member('OwnedNat','succ')));
 const result=drive(k.psKernelJointStep,k.psKernelJointStart(list([k.PsKernelJointEntry.definition(fake)])),1000000);
 assert.equal(result.status,'rejected');assert.equal(result.error,'unsupported');
});
test('one budget covers constructor checks, derived recursor and recursive reduction',()=>{
 const entries=[nat(),definition('Use',[],sortRec(3),proofType)],r=accepted(entries);
 assert.equal(joint(entries,r.steps-1).status,'outOfFuel');assert.equal(joint(entries,r.steps).status,'admitted');
});
