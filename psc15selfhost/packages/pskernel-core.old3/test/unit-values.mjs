import { k, list, expression, drive } from './checker-values.mjs';
import { runtimeName, runtimeLevel } from './fixture-values.mjs';
export const N=s=>['str',['anonymous'],s], Z=['zero'], S=l=>['succ',l], P=n=>['param',Array.isArray(n)?n:N(n)];
export const U=l=>['sort',l], B=i=>['b',String(i)], C=(n,ls=[])=>['const',Array.isArray(n)?n:N(n),ls];
export const app=(f,...args)=>args.reduce((fn,arg)=>['app',fn,arg],f);
export const pi=(n,t,b)=>['pi',N(n),t,b,'explicit'], lam=(n,t,b)=>['lam',N(n),t,b,'explicit'];
export const ctorName=n=>['str',Array.isArray(n)?n:N(n),'unit'], recName=n=>['str',Array.isArray(n)?n:N(n),'rec'];
export const unit=(n='OwnedUnit',parameters=[],level=S(Z),overrides={})=>({kind:'unit',name:Array.isArray(n)?n:N(n),parameters:parameters.map(p=>Array.isArray(p)?p:N(p)),level,
  ctorName:ctorName(n),ctorType:C(n,parameters.map(P)),...overrides});
export const definition=(name,parameters,type,value)=>({kind:'definition',name:N(name),parameters:parameters.map(p=>Array.isArray(p)?p:N(p)),type,value});
export const ownedEntry=e=>e.kind==='unit'
 ?k.PsKernelJointEntry.unitInductive(k.PsKernelUnitDeclaration.declaration(runtimeName(k,e.name),list(e.parameters.map(x=>runtimeName(k,x))),runtimeLevel(k,e.level),runtimeName(k,e.ctorName),expression(e.ctorType)))
 :k.PsKernelJointEntry.definition(k.PsKernelDefinition.polymorphic(runtimeName(k,e.name),list(e.parameters.map(x=>runtimeName(k,x))),expression(e.type),expression(e.value)));
export const joint=(entries,budget=200000)=>drive(k.psKernelJointStep,k.psKernelJointStart(list(entries.map(ownedEntry))),budget);
export const eliminate=(familyLevel=S(Z),parameters=[])=>{
 const levels=parameters.length?[familyLevel]:[],f=C('OwnedUnit',levels);
 return app(C(recName('OwnedUnit'),[S(S(Z)),...levels]),lam('major',f,U(S(Z))),U(Z),C(ctorName('OwnedUnit'),levels));
};
