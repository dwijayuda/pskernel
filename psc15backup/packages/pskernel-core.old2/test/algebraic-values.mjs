// Fixture construction only. No admission, positivity or reduction is implemented here.
import {k,list,expression,drive} from './checker-values.mjs';
import {runtimeName,runtimeNatural} from './fixture-values.mjs';
import {ownedEntry as previousEntry,wireEntry as previousWire,N,Z,S,U,B,C,app,pi,lam,member,literal,resultWitness} from './sum-values.mjs';
import {wireExpr,wireName} from './enum-values.mjs';
export {N,Z,S,U,B,C,app,pi,lam,member,literal,resultWitness};
export const T=U(S(Z));
export const d=(name,type,value)=>({name:N(name),parameters:[],type,value});
export function shift(x,by,depth=0){switch(x[0]){
 case'b':return B(BigInt(x[1])>=BigInt(depth)?BigInt(x[1])+BigInt(by):x[1]);
 case'app':return app(shift(x[1],by,depth),shift(x[2],by,depth));
 case'pi':case'lam':return [x[0],x[1],shift(x[2],by,depth),shift(x[3],by,depth+1),x[4]];
 case'let':return [x[0],x[1],shift(x[2],by,depth),shift(x[3],by,depth),shift(x[4],by,depth+1)];
 case'proj':return [x[0],x[1],x[2],shift(x[3],by,depth)];
 default:return x;
}}
export const params=(count,body)=>Array.from({length:count},(_,i)=>i).reduceRight((b,i)=>pi('A'+i,T,b),body);
export const family=(name,n,fields)=>({kind:'algebraic',name:N(name),parameterCount:n,type:params(n,T),constructors:fields.map((xs,i)=>({name:member(name,'c'+i),type:params(n,xs.reduceRight((body,type,j)=>pi('f'+j,shift(type,j),body),app(C(name),...Array.from({length:n},(_,j)=>B(xs.length+n-1-j)))))}))});
export const input=e=>k.PsKernelAlgDeclaration.declaration(runtimeName(k,e.name),runtimeNatural(k,String(e.parameterCount)),expression(e.type),list(e.constructors.map(c=>k.PsKernelAlgInputConstructor.constructor(runtimeName(k,c.name),expression(c.type)))));
export const ownedEntry=e=>e.kind==='algebraic'?k.PsKernelJointEntry.algebraic(input(e)):previousEntry(e);
export const bootstrap=(entries,budget=4000000)=>drive(k.psKernelBootstrapStep,k.psKernelBootstrapStart(list(entries.map(ownedEntry))),budget);
export const value=(e,i,parameters=[],fields=[])=>app(C(e.constructors[i].name),...parameters,...fields);
export const eliminate=(e,parameters,motive,minors,major,universe=S(Z))=>app(C(member(e.name,'rec'),[universe]),...parameters,motive,...minors,major);
export const wireEntry=e=>e.kind==='algebraic'?{kind:'inductive',declaration:{lp:[],np:e.parameterCount,ts:[{n:wireName(e.name),t:wireExpr(e.type),cs:e.constructors.map(c=>({n:wireName(c.name),t:wireExpr(c.type)}))}]}}:previousWire(e);
export const wireBatch=entries=>JSON.stringify({format:'proofscript-checked-admissions',version:2,admissions:entries.map(wireEntry)});
