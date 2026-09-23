import { ConstructorInfo, InductiveInfo, RecursorInfo, RecursorRule } from '../../core/declaration.js';
import { ensureClosed } from '../../core/checks.js';
import { Environment, KernelError } from '../../core/environment.js';
import { BinderInfo, Expr, app, appView, constant, consumeTypeAnnotations, exprEq, exprToString, forallE, fvar, inferImplicit, instantiateExprLevels, lam, mkAppN, sort } from '../../core/expr.js';
import { abstractFVar, instantiate1 } from '../../core/instantiate.js';
import { Level, isNotZero, levelEqStructural, levelEquivalent, levelLe, levelParam, levelZero, normalizesToZero } from '../../core/level.js';
import { LocalContext, LocalDecl } from '../../core/local-context.js';
import { Name, anonymous, nameAppendAfter, nameAppendIndexAfter, nameEq, nameFromDotted, nameIsPrefixOf, nameKey, nameReplacePrefix, nameToString, strName } from '../../core/name.js';
import { TypeChecker } from '../type-checker.js';
import { isPrimitiveName } from '../primitive-names.js';

export interface ConstructorDecl { readonly name:Name; readonly type:Expr }
export interface InductiveTypeDecl { readonly name:Name; readonly type:Expr; readonly ctors:readonly ConstructorDecl[] }
export interface InductiveDecl { readonly levelParams:readonly Name[]; readonly numParams:number; readonly types:readonly InductiveTypeDecl[]; readonly isUnsafe?:boolean; readonly numNested?:number }
interface OpenVar { readonly id:string; readonly expr:Expr; readonly decl:Extract<LocalDecl,{kind:'local'}> }
interface Stats { readonly levels:readonly Level[]; readonly resultLevel:Level; readonly nindices:readonly number[]; readonly params:readonly OpenVar[]; readonly names:readonly Name[]; readonly isUnsafe:boolean; readonly lparams:readonly Name[] }
interface RecBuild { readonly motive:OpenVar; readonly indices:readonly OpenVar[]; readonly major:OpenVar; readonly minors:OpenVar[] }
interface RuleBuild { readonly rule:RecursorRule; readonly expectedType:Expr }

function addLocal(lctx:LocalContext,name:Name,type:Expr,bi:BinderInfo='default'):OpenVar{const id=lctx.fresh(nameToString(name));lctx.addLocal(id,name,consumeTypeAnnotations(type),bi);const d=lctx.get(id);if(!d||d.kind!=='local')throw new Error('local context invariant');return {id,expr:fvar(id),decl:d};}
function tc(env:Environment,lctx:LocalContext,isUnsafe=false,lparams?:readonly Name[]){return new TypeChecker(env,lctx,undefined,undefined,isUnsafe?'unsafe':'safe',lparams);}
function stc(env:Environment,lctx:LocalContext,stats:Stats){return tc(env,lctx,stats.isUnsafe,stats.lparams);}
function recName(n:Name):Name{return strName(n,'rec');}
function hasConst(e:Expr,names:readonly Name[]):boolean{
 const todo:Expr[]=[e];
 while(todo.length){
   const x=todo.pop()!;
   switch(x.kind){
     case'const':if(names.some(n=>nameEq(n,x.name)))return true;break;
     case'app':todo.push(x.arg,x.fn);break;
     case'lam':case'forall':todo.push(x.body,x.type);break;
     case'let':todo.push(x.body,x.value,x.type);break;
     case'mdata':case'proj':todo.push(x.expr);break;
     default:break;
   }
 }
 return false;
}
function containsFVar(e:Expr,id:string):boolean{
 const todo:Expr[]=[e];
 while(todo.length){
   const x=todo.pop()!;
   switch(x.kind){
     case'fvar':if(x.id===id)return true;break;
     case'app':todo.push(x.arg,x.fn);break;
     case'lam':case'forall':todo.push(x.body,x.type);break;
     case'let':todo.push(x.body,x.value,x.type);break;
     case'mdata':case'proj':todo.push(x.expr);break;
     default:break;
   }
 }
 return false;
}
function arity(e:Expr):number{let n=0,x=e;while(x.kind==='forall'){n++;x=x.body;}return n;}
function uniqueNames(xs:readonly Name[]):boolean{return xs.every((x,i)=>xs.findIndex(y=>nameEq(x,y))===i);}
function mkBinder(kind:'forall'|'lam',v:OpenVar,body:Expr):Expr{const b=abstractFVar(body,v.id);return kind==='forall'?forallE(v.decl.userName,v.decl.type,b,v.decl.binderInfo):lam(v.decl.userName,v.decl.type,b,v.decl.binderInfo);}
function closeMany(kind:'forall'|'lam',vs:readonly OpenVar[],body:Expr):Expr{let r=body;for(let i=vs.length-1;i>=0;i--)r=mkBinder(kind,vs[i]!,r);return r;}
const reservedNestedName=nameFromDotted('_nested');
function isReservedNestedName(n:Name):boolean{return nameIsPrefixOf(reservedNestedName,n);}
function usesReservedNestedAux(e:Expr):boolean{
 const todo:Expr[]=[e];
 while(todo.length){
   const x=todo.pop()!;
   switch(x.kind){
     case'const':if(isReservedNestedName(x.name))return true;break;
     case'proj':if(isReservedNestedName(x.typeName))return true;todo.push(x.expr);break;
     case'app':todo.push(x.arg,x.fn);break;
     case'lam':case'forall':todo.push(x.body,x.type);break;
     case'let':todo.push(x.body,x.value,x.type);break;
     case'mdata':todo.push(x.expr);break;
     default:break;
   }
 }
 return false;
}
export function checkNoReservedNestedAux(d:InductiveDecl):void{
 for(const it of d.types){
   if(usesReservedNestedAux(it.type))throw new KernelError(`invalid declaration '${nameToString(it.name)}', it uses the reserved prefix '_nested'`);
   for(const ctor of it.ctors)if(usesReservedNestedAux(ctor.type))throw new KernelError(`invalid declaration '${nameToString(ctor.name)}', it uses the reserved prefix '_nested'`);
 }
}

/** Final Lean 4.34 syntactic uniform-occurrence check.
 * This intentionally runs before WHNF/nested preprocessing because reduction can erase
 * a malformed recursive occurrence before positivity checking sees it. */
export function checkUniformInductiveOccurrences(d:InductiveDecl):void{
 if(!Number.isSafeInteger(d.numParams)||d.numParams<0)throw new KernelError('invalid inductive datatype, number of parameters is invalid');
 const names=d.types.map(x=>x.name),levels=d.levelParams.map(levelParam);
 const isDeclared=(n:Name)=>names.some(x=>nameEq(x,n));
 const levelsMatch=(xs:readonly Level[])=>xs.length===levels.length&&xs.every((x,i)=>levelEqStructural(x,levels[i]!));
 const todo:{e:Expr;offset:number}[]=[];
 for(let ti=d.types.length-1;ti>=0;ti--)for(let ci=d.types[ti]!.ctors.length-1;ci>=0;ci--)todo.push({e:d.types[ti]!.ctors[ci]!.type,offset:0});
 while(todo.length){
   const {e,offset}=todo.pop()!,av=appView(e);
   if(av.fn.kind==='const'&&isDeclared(av.fn.name)&&av.args.length<=d.numParams){
     let ok=av.args.length===d.numParams&&offset>=d.numParams&&levelsMatch(av.fn.levels);
     for(let i=0;ok&&i<d.numParams;i++){const a=av.args[i]!;ok=a.kind==='bvar'&&a.index===offset-1-i;}
     if(!ok)throw new KernelError(`invalid occurrence of datatype '${nameToString(av.fn.name)}' being declared: it must be applied to the parameters and universe levels of the mutual declaration`);
     continue;
   }
   switch(e.kind){
     case'app':todo.push({e:e.arg,offset},{e:e.fn,offset});break;
     case'lam':case'forall':todo.push({e:e.body,offset:offset+1},{e:e.type,offset});break;
     case'let':todo.push({e:e.body,offset:offset+1},{e:e.value,offset},{e:e.type,offset});break;
     case'mdata':case'proj':todo.push({e:e.expr,offset});break;
     default:break;
   }
 }
}
function validIndApp(work:Environment,stats:Stats,lctx:LocalContext,t:Expr):{idx:number;indices:readonly Expr[]}|null{
 const w=stc(work,lctx,stats).whnf(t),v=appView(w);if(v.fn.kind!=='const')return null;const idx=stats.names.findIndex(n=>nameEq(n,v.fn.kind==='const'?v.fn.name:n));if(idx<0)return null;const ni=stats.nindices[idx]!;if(v.args.length!==stats.params.length+ni)return null;
 for(let i=0;i<stats.params.length;i++)if(!stc(work,lctx,stats).isDefEq(v.args[i]!,stats.params[i]!.expr))return null;
 for(let i=stats.params.length;i<v.args.length;i++)if(hasConst(v.args[i]!,stats.names))return null;
 return {idx,indices:v.args.slice(stats.params.length)};
}
function checkPositivity(work:Environment,stats:Stats,lctx:LocalContext,t:Expr,ctor:Name,argNo:number):void{
 let c=lctx,w=stc(work,c,stats).whnf(t);
 while(hasConst(w,stats.names)){
   if(w.kind!=='forall'){
     if(!validIndApp(work,stats,c,w))throw new KernelError(`arg #${argNo} of '${nameToString(ctor)}' has a non-valid occurrence of the datatypes being declared`);
     return;
   }
   if(hasConst(w.type,stats.names))throw new KernelError(`arg #${argNo} of '${nameToString(ctor)}' has a non-positive occurrence`);
   const next=c.clone(),v=addLocal(next,w.name,w.type,w.binderInfo);
   c=next;w=stc(work,c,stats).whnf(instantiate1(w.body,v.expr));
 }
}
function openHeader(env:Environment,type:Expr,numParams:number,shared:readonly OpenVar[]|null,d:InductiveDecl):{lctx:LocalContext;params:OpenVar[];indices:OpenVar[];result:Expr}{
 const lctx=new LocalContext();const params:OpenVar[]=[];const indices:OpenVar[]=[];let t=tc(env,lctx,!!d.isUnsafe,d.levelParams).whnf(type);let i=0;
 while(t.kind==='forall'){
   if(i<numParams){if(shared){const p=shared[i];if(!p)throw new KernelError('number of parameters mismatch');if(!tc(env,lctx,!!d.isUnsafe,d.levelParams).isDefEq(t.type,p.decl.type))throw new KernelError('parameters of mutually inductive datatypes must match');lctx.addLocal(p.id,p.decl.userName,p.decl.type,p.decl.binderInfo);params.push(p);t=tc(env,lctx,!!d.isUnsafe,d.levelParams).whnf(instantiate1(t.body,p.expr));}else{const p=addLocal(lctx,t.name,t.type,t.binderInfo);params.push(p);t=tc(env,lctx,!!d.isUnsafe,d.levelParams).whnf(instantiate1(t.body,p.expr));}i++;}
   else{const x=addLocal(lctx,t.name,t.type,t.binderInfo);indices.push(x);t=tc(env,lctx,!!d.isUnsafe,d.levelParams).whnf(instantiate1(t.body,x.expr));}
 }
 if(i!==numParams)throw new KernelError('number of parameters mismatch in inductive datatype declaration');return {lctx,params,indices,result:t};
}
function computeStats(env:Environment,d:InductiveDecl):Stats{
 if(d.types.length===0)throw new KernelError('empty inductive declaration');if(!uniqueNames(d.levelParams))throw new KernelError('duplicate universe parameter');
 let shared:OpenVar[]|null=null,resultLevel:Level|null=null;const nindices:number[]=[];
 for(const it of d.types){ensureClosed(it.type,`inductive type ${nameToString(it.name)}`);tc(env,new LocalContext(),!!d.isUnsafe,d.levelParams).check(it.type);const h=openHeader(env,it.type,d.numParams,shared,d);const s=tc(env,h.lctx,!!d.isUnsafe,d.levelParams).ensureSort(h.result,h.result).level;if(!shared)shared=h.params;if(resultLevel===null)resultLevel=s;else if(!levelEquivalent(resultLevel,s))throw new KernelError('mutually inductive types must live in the same universe');nindices.push(h.indices.length);}
 return {levels:d.levelParams.map(levelParam),resultLevel:resultLevel!,nindices,params:shared!,names:d.types.map(x=>x.name),isUnsafe:!!d.isUnsafe,lparams:d.levelParams};
}
function isRecursive(d:InductiveDecl,stats:Stats):boolean{return d.types.some(t=>t.ctors.some(c=>{let x=c.type;while(x.kind==='forall'){if(hasConst(x.type,stats.names))return true;x=x.body;}return false;}));}
function isReflexive(d:InductiveDecl,stats:Stats):boolean{return d.types.some(t=>t.ctors.some(c=>{let x=c.type;while(x.kind==='forall'){if(x.type.kind==='forall'&&hasConst(x.type,stats.names))return true;x=x.body;}return false;}));}
function declareTypes(work:Environment,d:InductiveDecl,stats:Stats):void{
 const all=stats.names,rec=isRecursive(d,stats),refl=isReflexive(d,stats);
 d.types.forEach((it,i)=>{if(work.has(it.name))throw new KernelError(`already declared '${nameToString(it.name)}'`);const info:InductiveInfo={kind:'inductive',name:it.name,levelParams:d.levelParams,type:it.type,numParams:d.numParams,numIndices:stats.nindices[i]!,all,ctors:it.ctors.map(c=>c.name),numNested:d.numNested??0,isRec:rec,isReflexive:refl,...(d.isUnsafe===undefined?{}:{isUnsafe:d.isUnsafe})};work.add(info);});
}
function checkConstructors(work:Environment,d:InductiveDecl,stats:Stats):void{
 const seen=new Set<string>();d.types.forEach((it,itIdx)=>it.ctors.forEach(ctor=>{
   const k=nameKey(ctor.name);if(seen.has(k))throw new KernelError(`duplicate constructor '${nameToString(ctor.name)}'`);seen.add(k);ensureClosed(ctor.type,`constructor ${nameToString(ctor.name)}`);tc(work,new LocalContext(),stats.isUnsafe,stats.lparams).check(ctor.type);
   const lctx=new LocalContext();for(const p of stats.params)lctx.addLocal(p.id,p.decl.userName,p.decl.type,p.decl.binderInfo);let t=stc(work,lctx,stats).whnf(ctor.type);let i=0;
   while(t.kind==='forall'){
     if(i<stats.params.length){const p=stats.params[i]!;if(!stc(work,lctx,stats).isDefEq(t.type,p.decl.type))throw new KernelError(`arg #${i+1} of '${nameToString(ctor.name)}' does not match parameters`);t=stc(work,lctx,stats).whnf(instantiate1(t.body,p.expr));i++;continue;}
     const s=stc(work,lctx,stats).ensureSort(stc(work,lctx,stats).infer(t.type,false),t.type).level;if(!normalizesToZero(stats.resultLevel)&&!levelLe(s,stats.resultLevel))throw new KernelError(`universe level of constructor field is too large in '${nameToString(ctor.name)}'`);
     if(!d.isUnsafe)checkPositivity(work,stats,lctx,t.type,ctor.name,i+1);const v=addLocal(lctx,t.name,t.type,t.binderInfo);t=stc(work,lctx,stats).whnf(instantiate1(t.body,v.expr));i++;
   }
   const appInfo=validIndApp(work,stats,lctx,t);if(!appInfo||appInfo.idx!==itIdx)throw new KernelError(`invalid return type for '${nameToString(ctor.name)}'`);
 }));
}
function declareConstructors(work:Environment,d:InductiveDecl):void{d.types.forEach(it=>it.ctors.forEach((ctor,cidx)=>{if(work.has(ctor.name))throw new KernelError(`already declared '${nameToString(ctor.name)}'`);const a=arity(ctor.type);if(a<d.numParams)throw new KernelError('constructor arity smaller than numParams');const info:ConstructorInfo={kind:'constructor',name:ctor.name,levelParams:d.levelParams,type:ctor.type,induct:it.name,cidx,numParams:d.numParams,numFields:a-d.numParams,...(d.isUnsafe===undefined?{}:{isUnsafe:d.isUnsafe})};work.add(info);}));}
function isLargeEliminator(work:Environment,d:InductiveDecl,stats:Stats):boolean{
 if(isNotZero(stats.resultLevel))return true;if(d.types.length!==1)return false;const cs=d.types[0]!.ctors;if(cs.length===0)return true;if(cs.length!==1)return false;
 const lctx=new LocalContext();for(const p of stats.params)lctx.addLocal(p.id,p.decl.userName,p.decl.type,p.decl.binderInfo);let t=cs[0]!.type,i=0;const must:OpenVar[]=[];
 while(t.kind==='forall'){if(i<stats.params.length){const p=stats.params[i]!;t=instantiate1(t.body,p.expr);i++;continue;}const v=addLocal(lctx,t.name,t.type,t.binderInfo);const lev=stc(work,lctx,stats).ensureSort(stc(work,lctx,stats).infer(t.type),t.type).level;if(!normalizesToZero(lev))must.push(v);t=instantiate1(t.body,v.expr);i++;}
 const args=appView(t).args;return must.every(v=>args.some(a=>a.kind==='fvar'&&a.id===v.id));
}
function freshElimLevel(d:InductiveDecl):{level:Level;name:Name|null}{if(!isLargeEliminatorPlaceholder)throw new Error('unreachable');return {level:levelZero,name:null};}
const isLargeEliminatorPlaceholder=true; // keeps fresh-level selection pure below
function chooseElimLevel(work:Environment,d:InductiveDecl,stats:Stats):{level:Level;name:Name|null}{if(!isLargeEliminator(work,d,stats))return {level:levelZero,name:null};let n=nameFromDotted('u');let i=1;while(d.levelParams.some(x=>nameEq(x,n))){n=nameAppendIndexAfter(nameFromDotted('u'),i++);}return {level:levelParam(n),name:n};}
function isKTarget(d:InductiveDecl,stats:Stats):boolean{if(!normalizesToZero(stats.resultLevel)||d.types.length!==1||d.types[0]!.ctors.length!==1)return false;let t=d.types[0]!.ctors[0]!.type,i=0;while(t.kind==='forall'){if(i>=stats.params.length)return false;t=t.body;i++;}return true;}
function openIndices(work:Environment,type:Expr,stats:Stats,lctx:LocalContext):OpenVar[]{let t=stc(work,lctx,stats).whnf(type),i=0;const xs:OpenVar[]=[];while(t.kind==='forall'){if(i<stats.params.length){t=stc(work,lctx,stats).whnf(instantiate1(t.body,stats.params[i]!.expr));i++;}else{const x=addLocal(lctx,t.name,t.type,t.binderInfo);xs.push(x);t=stc(work,lctx,stats).whnf(instantiate1(t.body,x.expr));}}return xs;}
function recArgInfo(work:Environment,stats:Stats,base:LocalContext,arg:OpenVar):{target:number;indices:readonly Expr[];xs:readonly OpenVar[];applied:Expr}|null{
 const c=base.clone();let ty=stc(work,c,stats).whnf(arg.decl.type);const xs:OpenVar[]=[];let applied=arg.expr;while(ty.kind==='forall'){const x=addLocal(c,ty.name,ty.type,ty.binderInfo);xs.push(x);applied=app(applied,x.expr);ty=stc(work,c,stats).whnf(instantiate1(ty.body,x.expr));}const v=validIndApp(work,stats,c,ty);return v?{target:v.idx,indices:v.indices,xs,applied}:null;
}
function openCtorFields(work:Environment,stats:Stats,ctor:ConstructorDecl,base:LocalContext):{lctx:LocalContext;fields:OpenVar[];result:Expr}{const c=base.clone();let t=stc(work,c,stats).whnf(ctor.type),i=0;while(i<stats.params.length){if(t.kind!=='forall')throw new KernelError('constructor parameter mismatch');t=stc(work,c,stats).whnf(instantiate1(t.body,stats.params[i]!.expr));i++;}const fields:OpenVar[]=[];while(t.kind==='forall'){const x=addLocal(c,t.name,t.type,t.binderInfo);fields.push(x);t=stc(work,c,stats).whnf(instantiate1(t.body,x.expr));}return {lctx:c,fields,result:t};}
function generateRecursors(work:Environment,d:InductiveDecl,stats:Stats):{infos:RecursorInfo[];expectedRules:Map<string,readonly RuleBuild[]>}{
 const {level:elimLevel,name:elimName}=chooseElimLevel(work,d,stats);const recLevels=elimName?[elimLevel,...stats.levels]:stats.levels;const recLParams=elimName?[elimName,...d.levelParams]:d.levelParams;const base=new LocalContext();for(const p of stats.params)base.addLocal(p.id,p.decl.userName,p.decl.type,p.decl.binderInfo);
 const builds:RecBuild[]=[];const motiveVars:OpenVar[]=[];
 d.types.forEach((it,idx)=>{const c=base.clone();for(const m of motiveVars)c.addLocal(m.id,m.decl.userName,m.decl.type,m.decl.binderInfo);const indices=openIndices(work,it.type,stats,c);const majorTy=mkAppN(constant(it.name,stats.levels),[...stats.params.map(p=>p.expr),...indices.map(x=>x.expr)]);const major=addLocal(c,nameFromDotted('t'),majorTy);const motiveTy=closeMany('forall',[...indices,major],sort(elimLevel));const motive=addLocal(base,d.types.length>1?nameAppendIndexAfter(nameFromDotted('motive'),idx+1):nameFromDotted('motive'),motiveTy);motiveVars.push(motive);builds.push({motive,indices,major,minors:[]});});
 // Put all motives in a context shared by minor construction.
 const minorBase=base.clone();for(const m of motiveVars)minorBase.addLocal(m.id,m.decl.userName,m.decl.type,m.decl.binderInfo);const allMinors:OpenVar[]=[];
 d.types.forEach((it,didx)=>it.ctors.forEach(ctor=>{const opened=openCtorFields(work,stats,ctor,minorBase);const target=validIndApp(work,stats,opened.lctx,opened.result);if(!target)throw new KernelError('internal: constructor result lost validity');const intro=mkAppN(constant(ctor.name,stats.levels),[...stats.params.map(p=>p.expr),...opened.fields.map(f=>f.expr)]);let result=app(mkAppN(motiveVars[target.idx]!.expr,target.indices),intro);const ihVars:OpenVar[]=[];
   for(const field of opened.fields){const ri=recArgInfo(work,stats,opened.lctx,field);if(!ri)continue;let ih=app(mkAppN(motiveVars[ri.target]!.expr,ri.indices),ri.applied);if(ri.xs.length)ih=closeMany('forall',ri.xs,ih);const v=addLocal(opened.lctx,nameAppendAfter(field.decl.userName,'_ih'),ih);ihVars.push(v);}
   const mty=closeMany('forall',[...opened.fields,...ihVars],result);const minorName=nameReplacePrefix(ctor.name,it.name,anonymous)??ctor.name;const mv=addLocal(minorBase,minorName,mty);allMinors.push(mv);builds[didx]!.minors.push(mv);
 }));
 // Recursor types and rules use one shared binder order: params, motives, all minors, per-target indices, major.
 const infos:RecursorInfo[]=[];const expectedRules=new Map<string,readonly RuleBuild[]>();const k=isKTarget(d,stats);
 d.types.forEach((it,didx)=>{
   const c=minorBase.clone();for(const m of allMinors)c.addLocal(m.id,m.decl.userName,m.decl.type,m.decl.binderInfo);const indices=openIndices(work,it.type,stats,c);const majorTy=mkAppN(constant(it.name,stats.levels),[...stats.params.map(p=>p.expr),...indices.map(x=>x.expr)]);const major=addLocal(c,nameFromDotted('t'),majorTy);const out=app(mkAppN(motiveVars[didx]!.expr,indices.map(x=>x.expr)),major.expr);const type=inferImplicit(closeMany('forall',[...stats.params,...motiveVars,...allMinors,...indices,major],out),true);
   const rbs:RuleBuild[]=[];
   it.ctors.forEach((ctor,ctorIdx)=>{const opened=openCtorFields(work,stats,ctor,c);const target=validIndApp(work,stats,opened.lctx,opened.result);if(!target)throw new KernelError('internal target failure');const intro=mkAppN(constant(ctor.name,stats.levels),[...stats.params.map(p=>p.expr),...opened.fields.map(f=>f.expr)]);const ihVals:Expr[]=[];
     for(const field of opened.fields){const ri=recArgInfo(work,stats,opened.lctx,field);if(!ri)continue;let rec=mkAppN(constant(recName(d.types[ri.target]!.name),recLevels),[...stats.params.map(p=>p.expr),...motiveVars.map(m=>m.expr),...allMinors.map(m=>m.expr),...ri.indices,ri.applied]);if(ri.xs.length)rec=closeMany('lam',ri.xs,rec);ihVals.push(rec);}
     const minorIndex=d.types.slice(0,didx).reduce((n,x)=>n+x.ctors.length,0)+ctorIdx;let body=mkAppN(allMinors[minorIndex]!.expr,[...opened.fields.map(f=>f.expr),...ihVals]);const rhs=closeMany('lam',[...stats.params,...motiveVars,...allMinors,...opened.fields],body);const expectedResult=app(mkAppN(motiveVars[target.idx]!.expr,target.indices),intro);const expectedType=closeMany('forall',[...stats.params,...motiveVars,...allMinors,...opened.fields],expectedResult);rbs.push({rule:{ctor:ctor.name,nFields:opened.fields.length,rhs},expectedType});
   });
   const info:RecursorInfo={kind:'recursor',name:recName(it.name),levelParams:recLParams,type,all:stats.names,numParams:stats.params.length,numIndices:stats.nindices[didx]!,numMotives:motiveVars.length,numMinors:allMinors.length,rules:rbs.map(x=>x.rule),k,...(d.isUnsafe===undefined?{}:{isUnsafe:d.isUnsafe})};infos.push(info);expectedRules.set(nameKey(info.name),rbs);
 });
 return {infos,expectedRules};
}
/** Lean 4.34 PR #14808 defense-in-depth: validate the installed recursor through
 * the real reducer, independently of the synthesis-side expected-rule calculation. */
export function validateInstalledRecursorsByReduction(work:Environment,d:InductiveDecl):void{
 const ctorLevels=d.levelParams.map(levelParam);
 for(const it of d.types){
   const ri=work.get(recName(it.name));if(ri.kind!=='recursor')throw new KernelError(`missing generated recursor '${nameToString(recName(it.name))}'`);
   const base=new LocalContext(),baseTc=tc(work,base,!!d.isUnsafe,ri.levelParams);
   baseTc.ensureSort(baseTc.check(ri.type),ri.type);
   let rt=baseTc.whnf(ri.type);const pre:OpenVar[]=[];
   const preCount=ri.numParams+ri.numMotives+ri.numMinors;
   for(let i=0;i<preCount;i++){
     rt=baseTc.whnf(rt);if(rt.kind!=='forall')throw new KernelError(`generated recursor '${nameToString(ri.name)}' has malformed binder metadata`);
     const v=addLocal(base,rt.name,rt.type,rt.binderInfo);pre.push(v);rt=baseTc.whnf(instantiate1(rt.body,v.expr));
   }
   const params=pre.slice(0,ri.numParams).map(x=>x.expr);
   const recPre=mkAppN(constant(ri.name,ri.levelParams.map(levelParam)),pre.map(x=>x.expr));
   for(const ctor of it.ctors){
     const lctx=base.clone(),checker=tc(work,lctx,!!d.isUnsafe,ri.levelParams);let ct=ctor.type;
     for(let i=0;i<ri.numParams;i++){
       ct=checker.whnf(ct);if(ct.kind!=='forall')throw new KernelError(`constructor '${nameToString(ctor.name)}' has fewer parameters than its recursor`);
       ct=checker.whnf(instantiate1(ct.body,params[i]!));
     }
     const fields:OpenVar[]=[];
     while((ct=checker.whnf(ct)).kind==='forall'){
       const v=addLocal(lctx,ct.name,ct.type,ct.binderInfo);fields.push(v);ct=instantiate1(ct.body,v.expr);
     }
     ct=checker.whnf(ct);const result=appView(ct);
     if(result.fn.kind!=='const'||!nameEq(result.fn.name,it.name)||result.args.length!==ri.numParams+ri.numIndices)
       throw new KernelError(`constructor '${nameToString(ctor.name)}' result does not match generated recursor metadata`);
     for(let i=0;i<ri.numParams;i++)if(!checker.isDefEq(result.args[i]!,params[i]!))
       throw new KernelError(`constructor '${nameToString(ctor.name)}' parameter does not match generated recursor metadata`);
     const indices=result.args.slice(ri.numParams),intro=mkAppN(constant(ctor.name,ctorLevels),[...params,...fields.map(x=>x.expr)]);
     const lhs=mkAppN(recPre,[...indices,intro]),expected=checker.check(lhs),reduct=checker.whnf(lhs),actual=checker.check(reduct);
     if(!checker.isDefEq(actual,expected))
       throw new KernelError(`generated recursor computation rule for '${nameToString(ctor.name)}' is not type-preserving`);
   }
 }
}
function commit(from:Environment,to:Environment,originalKeys:Set<string>):void{for(const i of from.entries())if(!originalKeys.has(nameKey(i.name)))to.add(i);}

interface InternalInductiveAdmissionOptions { readonly allowPrimitiveNames?: boolean; readonly allowReservedNestedAux?: boolean }

/** Internal admission entry used only after a dedicated recognizer/preprocessor has justified a bypass. */
export function addOrdinaryInductiveInternal(env:Environment,d:InductiveDecl,options:InternalInductiveAdmissionOptions={}):void{
 if(!options.allowReservedNestedAux)checkNoReservedNestedAux(d);
 checkUniformInductiveOccurrences(d);
 if(!options.allowPrimitiveNames){
   for(const it of d.types){if(isPrimitiveName(it.name))throw new KernelError(`primitive '${nameToString(it.name)}' must go through primitive recognition`);for(const c of it.ctors)if(isPrimitiveName(c.name))throw new KernelError(`primitive '${nameToString(c.name)}' must go through primitive recognition`);}
 }
 if(d.numNested&&d.numNested!==0)throw new KernelError('nested inductive declaration must go through nested-inductive preprocessing');if(!uniqueNames(d.types.map(x=>x.name)))throw new KernelError('duplicate inductive type name');
 const stage=<T>(label:string,f:()=>T):T=>{try{return f();}catch(e){const msg=e instanceof Error?e.message:String(e);throw new KernelError(`inductive ${label}: ${msg}`);}};
 const original=new Set(env.entries().map(x=>nameKey(x.name)));const work=env.clone();const stats=stage('header checking',()=>computeStats(work,d));stage('type declaration',()=>declareTypes(work,d,stats));stage('constructor checking',()=>checkConstructors(work,d,stats));stage('constructor declaration',()=>declareConstructors(work,d));
 const {infos,expectedRules}=stage('recursor synthesis',()=>generateRecursors(work,d,stats));for(const i of infos){if(work.has(i.name))throw new KernelError(`already declared '${nameToString(i.name)}'`);work.add(i);}
 // Defensive 4.34-style preservation checks: first verify synthesis-side rule types,
 // then independently exercise each installed rule through the real recursor reducer (PR #14808).
 stage('recursor validation',()=>{
   for(const i of infos){const checker=new TypeChecker(work,new LocalContext(),undefined,undefined,d.isUnsafe?'unsafe':'safe',i.levelParams);stage(`recursor type ${nameToString(i.name)}`,()=>checker.ensureSort(checker.check(i.type),i.type));for(const rb of expectedRules.get(nameKey(i.name))??[]){stage(`recursor rule ${nameToString(rb.rule.ctor)}`,()=>{const got=checker.check(rb.rule.rhs);if(!checker.isDefEq(got,rb.expectedType))throw new KernelError(`recursor rule for '${nameToString(rb.rule.ctor)}' is not type preserving`);});}}
   validateInstalledRecursorsByReduction(work,d);
 });
 commit(work,env,original);
}

/** Public ordinary-inductive admission is deliberately fail-closed. */
export function addOrdinaryInductive(env:Environment,d:InductiveDecl):void{
 addOrdinaryInductiveInternal(env,d);
}
