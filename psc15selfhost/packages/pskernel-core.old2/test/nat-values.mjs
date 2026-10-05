import {k,list,expression,drive} from './checker-values.mjs';
import {runtimeName} from './fixture-values.mjs';
import {N,Z,S,U,B,C,app,pi,lam,ownedEntry as previousEntry} from './unit-values.mjs';
export {N,Z,S,U,B,C,app,pi,lam};
export const member=(n,part)=>['str',N(n),part];
export const nat=(name='OwnedNat',overrides={})=>({kind:'nat',name:N(name),familyType:U(S(Z)),
 zeroName:member(name,'zero'),zeroType:C(name),succName:member(name,'succ'),succType:pi('n',C(name),C(name)),...overrides});
export const numeral=(n,name='OwnedNat')=>{let out=C(member(name,'zero'));for(let i=0;i<n;i++)out=app(C(member(name,'succ')),out);return out;};
export const ownedEntry=e=>e.kind==='nat'
 ?k.PsKernelJointEntry.natInductive(k.PsKernelNatDeclaration.declaration(runtimeName(k,e.name),expression(e.familyType),runtimeName(k,e.zeroName),expression(e.zeroType),runtimeName(k,e.succName),expression(e.succType)))
 :previousEntry(e);
export const joint=(entries,budget=1000000)=>drive(k.psKernelJointStep,k.psKernelJointStart(list(entries.map(ownedEntry))),budget);
export const bootstrap=(entries,budget=1000000)=>drive(k.psKernelBootstrapStep,k.psKernelBootstrapStart(list(entries.map(ownedEntry))),budget);
export const identityRec=(n,name='OwnedNat')=>{const f=C(name);return app(C(member(name,'rec'),[S(Z)]),lam('n',f,f),C(member(name,'zero')),
 lam('n',f,lam('ih',f,app(C(member(name,'succ')),B(0)))),numeral(n,name));};
export const sortRec=(n,name='OwnedNat')=>{const f=C(name);return app(C(member(name,'rec'),[S(S(Z))]),lam('n',f,U(S(Z))),U(Z),lam('n',f,lam('ih',U(S(Z)),B(0))),numeral(n,name));};
export const polymorphicFold=(n,name='OwnedNat')=>{
 const u=['param',N('u')],f=C(name);
 return {type:pi('A',U(u),pi('a',B(0),B(1))),value:lam('A',U(u),lam('a',B(0),
  app(C(member(name,'rec'),[u]),lam('n',f,B(2)),B(0),lam('n',f,lam('ih',B(2),B(0))),numeral(n,name))))};
};
