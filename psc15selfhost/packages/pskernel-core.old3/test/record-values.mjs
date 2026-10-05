// Fixture construction only. Admission authority stays in generated source.
import {k,list,expression,drive} from './checker-values.mjs';
import {runtimeName,runtimeLevel} from './fixture-values.mjs';
import {N,Z,S,U,B,C,app,pi,lam,ownedEntry as previousEntry} from './nat-values.mjs';
export {N,Z,S,U,B,C,app,pi,lam};
export const member=(n,part)=>['str',Array.isArray(n)?n:N(n),part];
export const record=(name='OwnedRecord',fields=[C('Nat')],overrides={})=>({kind:'record',name:Array.isArray(name)?name:N(name),parameters:[],level:S(Z),
 ctorName:member(name,'mk'),ctorType:fields.reduceRight((body,type,i)=>pi('field'+i,type,body),C(name)),...overrides});
export const ownedEntry=e=>e.kind==='record'
 ?k.PsKernelJointEntry.recordInductive(k.PsKernelUnitDeclaration.declaration(runtimeName(k,e.name),list(e.parameters.map(x=>runtimeName(k,x))),runtimeLevel(k,e.level),runtimeName(k,e.ctorName),expression(e.ctorType)))
 :previousEntry(e);
export const joint=(entries,budget=1000000)=>drive(k.psKernelJointStep,k.psKernelJointStart(list(entries.map(ownedEntry))),budget);
export const bootstrap=(entries,budget=1000000)=>drive(k.psKernelBootstrapStep,k.psKernelBootstrapStart(list(entries.map(ownedEntry))),budget);
export const literal=n=>['nat',String(n)];
export const value=(name,args)=>app(C(member(name,'mk')),...args);
export const firstFieldRec=(name,count,major=value(name,Array.from({length:count},(_,i)=>literal(i))))=>
 app(C(member(name,'rec'),[S(Z)]),lam('major',C(name),C('Nat')),
  Array.from({length:count},()=>C('Nat')).reduceRight((body,type,i)=>lam('field'+i,type,body),B(count-1)),major);
