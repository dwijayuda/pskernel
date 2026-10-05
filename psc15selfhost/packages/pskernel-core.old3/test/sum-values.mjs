// Fixture construction only; judgments and reductions are generated from Lean source.
import {k,list,expression,drive} from './checker-values.mjs';
import {runtimeName,runtimeLevel} from './fixture-values.mjs';
import {ownedEntry as previousEntry,wireEntry as previousWire,N,Z,S,U,B,C,app,pi,lam,member,literal,resultWitness} from './enum-values.mjs';
export {N,Z,S,U,B,C,app,pi,lam,member,literal,resultWitness};
export const sum=(name='Sum',fields=[[],[C('Nat')]],overrides={})=>({kind:'sum',name:Array.isArray(name)?name:N(name),parameters:[],level:S(Z),constructors:fields.map((xs,i)=>({name:member(name,'c'+i),type:xs.reduceRight((b,t,j)=>pi('f'+j,t,b),C(name))})),...overrides});
export const ownedEntry=e=>e.kind==='sum'?k.PsKernelJointEntry.sumInductive(k.PsKernelEnumDeclaration.declaration(runtimeName(k,e.name),list(e.parameters.map(n=>runtimeName(k,n))),runtimeLevel(k,e.level),list(e.constructors.map(c=>k.PsKernelEnumConstructor.ctor(runtimeName(k,c.name),expression(c.type)))))):previousEntry(e);
export const bootstrap=(entries,budget=2000000)=>drive(k.psKernelBootstrapStep,k.psKernelBootstrapStart(list(entries.map(ownedEntry))),budget);
export const value=(e,which,args=[])=>app(C(e.constructors[which].name),...args);
export const eliminate=(e,which,args,minors,motive=lam('major',C(e.name),C('Nat')),universe=S(Z))=>app(C(member(e.name,'rec'),[universe]),motive,...minors,value(e,which,args));
export const wireEntry=e=>e.kind==='sum'?previousWire({...e,kind:'enum'}):previousWire(e);
export const wireBatch=entries=>JSON.stringify({format:'proofscript-checked-admissions',version:2,admissions:entries.map(wireEntry)});
