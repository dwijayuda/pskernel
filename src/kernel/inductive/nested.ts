import { ensureClosed } from '../../core/checks.js';
import { ConstantInfo, ConstructorInfo, InductiveInfo, RecursorInfo, RecursorRule } from '../../core/declaration.js';
import { Environment, KernelError } from '../../core/environment.js';
import { BinderInfo, Expr, app, appView, constant, exprKey, exprLeanEq, fvar, forallE, instantiateExprLevels, lam, mkAppN } from '../../core/expr.js';
import { abstractFVar, instantiate1 } from '../../core/instantiate.js';
import { LocalContext, LocalDecl } from '../../core/local-context.js';
import { Name, nameAppendIndexAfter, nameEq, nameFromDotted, nameKey, nameToString, strName } from '../../core/name.js';
import { TypeChecker } from '../type-checker.js';
import { addOrdinaryInductive, addOrdinaryInductiveInternal, checkNoReservedNestedAux, checkUniformInductiveOccurrences, validateInstalledRecursorsByReduction, ConstructorDecl, InductiveDecl, InductiveTypeDecl } from './ordinary.js';

interface OpenParam { readonly id:string; readonly expr:Expr; readonly decl:Extract<LocalDecl,{kind:'local'}> }
interface AuxFamily { readonly auxName:Name; readonly outerName:Name; readonly outerLevels:readonly import('../../core/level.js').Level[]; readonly fixedParams:readonly Expr[]; readonly nestedTemplate:Expr; readonly ctorMap:Map<string,Name> }
interface Preprocess { readonly decl:InductiveDecl; readonly params:readonly OpenParam[]; readonly aux:readonly AuxFamily[] }
function checker(env:Environment,d:InductiveDecl,lparams?:readonly Name[]):TypeChecker{return new TypeChecker(env,new LocalContext(),undefined,undefined,d.isUnsafe?'unsafe':'safe',lparams);}

function addParam(lctx:LocalContext,name:Name,type:Expr,bi:BinderInfo):OpenParam{const id=lctx.fresh(nameToString(name));lctx.addLocal(id,name,type,bi);const d=lctx.get(id);if(!d||d.kind!=='local')throw new Error('local invariant');return {id,expr:fvar(id),decl:d};}
function close(kind:'forall'|'lam',params:readonly OpenParam[],body:Expr):Expr{let r=body;for(let i=params.length-1;i>=0;i--){const p=params[i]!;const b=abstractFVar(r,p.id);r=kind==='forall'?forallE(p.decl.userName,p.decl.type,b,p.decl.binderInfo):lam(p.decl.userName,p.decl.type,b,p.decl.binderInfo);}return r;}
function hasNew(e:Expr,names:readonly Name[]):boolean{
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
function instFirstParams(e:Expr,args:readonly Expr[]):Expr{let t=e;for(const a of args){if(t.kind!=='forall')throw new KernelError('ill-formed nested inductive parameter instantiation');t=instantiate1(t.body,a);}return t;}
function openShared(e:Expr,params:readonly OpenParam[]):{kind:'forall'|'lam';body:Expr}|null{if(params.length===0)return {kind:'forall',body:e};let t=e;let k:'forall'|'lam'|null=null;for(const p of params){if(t.kind!=='forall'&&t.kind!=='lam')return null;if(k===null)k=t.kind;else if(k!==t.kind)return null;t=instantiate1(t.body,p.expr);}return k?{kind:k,body:t}:null;}
/** Re-open constructor parameters in a fresh local context. Lean does this per constructor
 * during nested-inductive elimination specifically to preserve constructor BinderInfo. */
function openConstructorParams(e:Expr,n:number):{params:readonly OpenParam[];body:Expr}{
 const lctx=new LocalContext();const ps:OpenParam[]=[];let t=e;
 for(let i=0;i<n;i++){if(t.kind!=='forall')throw new KernelError('nested preprocessing constructor parameter mismatch');const p=addParam(lctx,t.name,t.type,t.binderInfo);ps.push(p);t=instantiate1(t.body,p.expr);}
 return {params:ps,body:t};
}
function openRestorationParams(e:Expr,n:number):{kind:'forall'|'lam';params:readonly OpenParam[];body:Expr}{
 const lctx=new LocalContext();const ps:OpenParam[]=[];let t=e;let kind:'forall'|'lam'|null=null;
 for(let i=0;i<n;i++){
   if(t.kind!=='forall'&&t.kind!=='lam')throw new KernelError('failed to restore nested inductive types, fewer binders than parameters');
   if(kind===null)kind=t.kind;
   const p=addParam(lctx,t.name,t.type,t.binderInfo);ps.push(p);t=instantiate1(t.body,p.expr);
 }
 return {kind:kind??'forall',params:ps,body:t};
}
function rebaseParams(e:Expr,from:readonly OpenParam[],to:readonly OpenParam[]):Expr{
 if(from.length!==to.length)throw new KernelError('nested preprocessing parameter arity mismatch');
 const byId=new Map<string,Expr>();for(let i=0;i<from.length;i++)byId.set(from[i]!.id,to[i]!.expr);
 return mapExpr(e,x=>x.kind==='fvar'?(byId.get(x.id)??null):null);
}
function mapExpr(e:Expr,f:(x:Expr)=>Expr|null):Expr{
 type Frame={e:Expr;done:boolean};
 const todo:Frame[]=[{e,done:false}],out:Expr[]=[];
 while(todo.length){
   const frame=todo.pop()!,x=frame.e;
   if(!frame.done){
     const r=f(x);if(r){out.push(r);continue;}
     switch(x.kind){
       case'app':todo.push({e:x,done:true},{e:x.arg,done:false},{e:x.fn,done:false});break;
       case'lam':case'forall':todo.push({e:x,done:true},{e:x.body,done:false},{e:x.type,done:false});break;
       case'let':todo.push({e:x,done:true},{e:x.body,done:false},{e:x.value,done:false},{e:x.type,done:false});break;
       case'mdata':case'proj':todo.push({e:x,done:true},{e:x.expr,done:false});break;
       default:out.push(x);break;
     }
     continue;
   }
   switch(x.kind){
     case'app':{const arg=out.pop()!,fn=out.pop()!;out.push({...x,fn,arg});break;}
     case'lam':case'forall':{const body=out.pop()!,type=out.pop()!;out.push({...x,type,body});break;}
     case'let':{const body=out.pop()!,value=out.pop()!,type=out.pop()!;out.push({...x,type,value,body});break;}
     case'mdata':case'proj':out.push({...x,expr:out.pop()!});break;
     default:throw new Error('internal nested map frame');
   }
 }
 if(out.length!==1)throw new Error('internal nested map result');
 return out[0]!;
}
function appendUnique(base:Name,used:Set<string>,counter:{n:number}):Name{while(true){const n=strName(base,String(counter.n++));const k=nameKey(n);if(!used.has(k)){used.add(k);return n;}}}

function preprocess(env:Environment,d:InductiveDecl):Preprocess{
 if(d.types.length===0)throw new KernelError('empty nested inductive declaration');
 const lctx=new LocalContext();const params:OpenParam[]=[];let t=d.types[0]!.type;for(let i=0;i<d.numParams;i++){if(t.kind!=='forall')throw new KernelError('incorrect number of inductive parameters');const p=addParam(lctx,t.name,t.type,t.binderInfo);params.push(p);t=instantiate1(t.body,p.expr);}
 const names=d.types.map(x=>x.name);const used=new Set([...env.entries().map(x=>nameKey(x.name)),...names.map(nameKey)]);const counter={n:1};const aux:AuxFamily[]=[];const auxByNested=new Map<string,AuxFamily[]>();const outTypes:InductiveTypeDecl[]=d.types.map(x=>({name:x.name,type:x.type,ctors:x.ctors.map(c=>({...c}))}));
 const findAux=(template:Expr):AuxFamily|undefined=>auxByNested.get(exprKey(template))?.find(f=>exprLeanEq(f.nestedTemplate,template));
 const addAux=(template:Expr,fam:AuxFamily):void=>{const k=exprKey(template),bucket=auxByNested.get(k);if(bucket)bucket.push(fam);else auxByNested.set(k,[fam]);};
 const lvls=d.levelParams.map(n=>({kind:'param',name:n} as const));
 function ensureFamily(nested:Expr,currentParams:readonly OpenParam[]):AuxFamily{
   const av=appView(nested);if(av.fn.kind!=='const')throw new KernelError('internal nested head');const outer=env.find(av.fn.name);if(!outer||outer.kind!=='inductive')throw new KernelError('internal nested family');if(av.args.length<outer.numParams)throw new KernelError('nested application has too few parameters');
   const fixed=av.args.slice(0,outer.numParams);
   // Lean canonicalizes constructor-local parameters back to the declaration parameters
   // before looking up an existing nested auxiliary family.
   const canonicalFixed=fixed.map(a=>rebaseParams(a,currentParams,params));
   const canonical=mkAppN(av.fn,canonicalFixed),old=findAux(canonical);if(old)return old;
   let selected:AuxFamily|null=null;
   for(const familyName of outer.all){const oi=env.get(familyName);if(oi.kind!=='inductive')throw new KernelError('invalid outer mutual inductive metadata');const auxName=appendUnique(strName(nameFromDotted('_nested'),nameToString(familyName)),used,counter);const template=mkAppN(constant(familyName,av.fn.levels),canonicalFixed);const ctorMap=new Map<string,Name>();const fam:AuxFamily={auxName,outerName:familyName,outerLevels:av.fn.levels,fixedParams:canonicalFixed,nestedTemplate:template,ctorMap};aux.push(fam);addAux(template,fam);if(nameEq(familyName,av.fn.name))selected=fam;
     let auxType=instantiateExprLevels(oi.type,oi.levelParams,av.fn.levels);auxType=instFirstParams(auxType,fixed);const auxCtors:ConstructorDecl[]=[];
     for(const ocn of oi.ctors){const oc=env.get(ocn);if(oc.kind!=='constructor')throw new KernelError('outer constructor metadata mismatch');const acn=appendUnique(strName(auxName,nameToString(ocn)),used,counter);ctorMap.set(nameKey(acn),ocn);let act=instantiateExprLevels(oc.type,oc.levelParams,av.fn.levels);act=instFirstParams(act,fixed);auxCtors.push({name:acn,type:close('forall',currentParams,act)});}
     outTypes.push({name:auxName,type:close('forall',currentParams,auxType),ctors:auxCtors});
   }
   if(!selected)throw new KernelError('nested family selection failed');return selected;
 }
 function replacement(x:Expr,currentParams:readonly OpenParam[]):Expr|null{
   const av=appView(x);if(av.fn.kind!=='const')return null;const oi=env.find(av.fn.name);if(!oi||oi.kind!=='inductive'||av.args.length<oi.numParams)return null;const fixed=av.args.slice(0,oi.numParams);if(!fixed.some(a=>hasNew(a,names)))return null;const fam=ensureFamily(mkAppN(av.fn,fixed),currentParams);return mkAppN(constant(fam.auxName,lvls),[...currentParams.map(p=>p.expr),...av.args.slice(oi.numParams)]);
 }
 // Fixed point: auxiliary constructor types can themselves contain nested occurrences.
 // Re-open the shared parameters from EACH constructor. This mirrors Lean 4.34's
 // get_params(cnstr_type, ...) step and preserves constructor-specific BinderInfo.
 for(let i=0;i<outTypes.length;i++){
   const it=outTypes[i]!;const ctors=it.ctors.map(c=>{const opened=openConstructorParams(c.type,d.numParams);const body=mapExpr(opened.body,x=>replacement(x,opened.params));return {name:c.name,type:close('forall',opened.params,body)};});outTypes[i]={...it,ctors};
 }
 return {decl:{...d,types:outTypes,numNested:aux.length},params,aux};
}

function restoreExpression(e:Expr,d:InductiveDecl,p:Preprocess,recRename:Map<string,Name>):Expr{
 if(p.params.length===0)return restoreOpen(e,d,p,recRename,p.params);
 // Lean restore_nested recreates the leading binders from the expression being restored,
 // preserving their BinderInfo, then substitutes those fresh locals for the canonical
 // declaration parameters used by the nested templates.
 const opened=openRestorationParams(e,p.params.length);
 const body=restoreOpen(opened.body,d,p,recRename,opened.params);
 return close(opened.kind,opened.params,body);
}
function restoreOpen(e:Expr,d:InductiveDecl,p:Preprocess,recRename:Map<string,Name>,currentParams:readonly OpenParam[]):Expr{
 const byAux=new Map(p.aux.map(a=>[nameKey(a.auxName),a]));const ctorEntries=new Map<string,{fam:AuxFamily;outerCtor:Name}>();for(const fam of p.aux)for(const [ak,oc] of fam.ctorMap)ctorEntries.set(ak,{fam,outerCtor:oc});
 return mapExpr(e,x=>{
   if(x.kind==='proj'){const fam=byAux.get(nameKey(x.typeName));if(fam)return {kind:'proj',typeName:fam.outerName,index:x.index,expr:restoreOpen(x.expr,d,p,recRename,currentParams)};}
   const av=appView(x);if(av.fn.kind!=='const')return null;const rn=recRename.get(nameKey(av.fn.name));if(rn)return mkAppN(constant(rn,av.fn.levels),av.args);
   const fam=byAux.get(nameKey(av.fn.name));if(fam){if(av.args.length<d.numParams)return null;const nested=rebaseParams(fam.nestedTemplate,p.params,currentParams);return mkAppN(nested,av.args.slice(d.numParams));}
   const cm=ctorEntries.get(nameKey(av.fn.name));if(cm){if(av.args.length<d.numParams)return null;const fixed=cm.fam.fixedParams.map(a=>rebaseParams(a,p.params,currentParams));return mkAppN(constant(cm.outerCtor,cm.fam.outerLevels),[...fixed,...av.args.slice(d.numParams)]);}
   return null;
 });
}
function copyOriginalInductive(transformed:Environment,finalEnv:Environment,d:InductiveDecl,p:Preprocess,recRename:Map<string,Name>):void{
 const originals=d.types.map(x=>x.name);
 for(const it of d.types){const ii=transformed.get(it.name);if(ii.kind!=='inductive')throw new KernelError('missing transformed inductive');finalEnv.add({...ii,all:originals,numNested:p.aux.length});for(const cn of ii.ctors){const ci=transformed.get(cn);if(ci.kind!=='constructor')throw new KernelError('missing transformed constructor');const type=restoreExpression(ci.type,d,p,recRename);finalEnv.add({...ci,type});}
   const oldRec=transformed.get(strName(it.name,'rec'));if(oldRec.kind!=='recursor')throw new KernelError('missing transformed recursor');const rules=oldRec.rules.map(r=>({ctor:r.ctor,nFields:r.nFields,rhs:restoreExpression(r.rhs,d,p,recRename)}));finalEnv.add({...oldRec,all:originals,type:restoreExpression(oldRec.type,d,p,recRename),rules});
 }
}
function copyAuxRecursors(transformed:Environment,finalEnv:Environment,d:InductiveDecl,p:Preprocess,recRename:Map<string,Name>):void{
 for(const fam of p.aux){const oldName=strName(fam.auxName,'rec'),newName=recRename.get(nameKey(oldName));if(!newName)throw new KernelError('missing auxiliary recursor rename');const ri=transformed.get(oldName);if(ri.kind!=='recursor')throw new KernelError('missing auxiliary recursor');const rules:RecursorRule[]=ri.rules.map(r=>{let ctor=r.ctor;if(nameToString(r.ctor).startsWith('_nested')){for(const af of p.aux){const oc=af.ctorMap.get(nameKey(r.ctor));if(oc){ctor=oc;break;}}}return {ctor,nFields:r.nFields,rhs:restoreExpression(r.rhs,d,p,recRename)};});finalEnv.add({...ri,name:newName,all:d.types.map(x=>x.name),type:restoreExpression(ri.type,d,p,recRename),rules});}
}

/** Lean-style nested-inductive preprocessing -> ordinary mutual induction -> restoration/hardening. */
export function addInductive(env:Environment,d:InductiveDecl):void{
 checkNoReservedNestedAux(d);
 // Final Lean 4.34 #14607: reject FVars/MVars before nested preprocessing can
 // erase or rewrite the part of a declaration that contains them.
 for(const it of d.types){
   ensureClosed(it.type,`inductive type ${nameToString(it.name)}`);
   for(const ctor of it.ctors)ensureClosed(ctor.type,`constructor ${nameToString(ctor.name)}`);
 }
 checkUniformInductiveOccurrences(d);
 const p=preprocess(env,d);if(p.aux.length===0){addOrdinaryInductive(env,{...d,numNested:0});return;}
 const transformed=env.clone();addOrdinaryInductiveInternal(transformed,{...p.decl,numNested:0},{allowReservedNestedAux:true});
 const recRename=new Map<string,Name>();let idx=1;const mainRec=strName(d.types[0]!.name,'rec');for(const fam of p.aux)recRename.set(nameKey(strName(fam.auxName,'rec')),nameAppendIndexAfter(mainRec,idx++));
 const finalEnv=env.clone();copyOriginalInductive(transformed,finalEnv,d,p,recRename);copyAuxRecursors(transformed,finalEnv,d,p,recRename);

 // Final Lean 4.34 #14577: nested fixed parameters are removed from the
 // auxiliary declarations. Re-check each original nested application in a
 // context declaring the source parameters so an ill-typed fixed argument
 // cannot disappear during preprocessing.
 {
   const paramsLctx=new LocalContext();
   for(const p0 of p.params)paramsLctx.addLocal(p0.id,p0.decl.userName,p0.decl.type,p0.decl.binderInfo);
   const ntc=new TypeChecker(finalEnv,paramsLctx,undefined,undefined,d.isUnsafe?'unsafe':'safe',d.levelParams);
   for(const fam of p.aux)ntc.check(fam.nestedTemplate);
 }

 // 4.34 hardening analogue: recheck restored constructor/recursor types and rule RHS type preservation by restoring the transformed inferred type.
 const compareRestoredRules=(oldName:Name,newName:Name)=>{
   const old=transformed.get(oldName),neu=finalEnv.get(newName);if(old.kind!=='recursor'||neu.kind!=='recursor'||old.rules.length!==neu.rules.length)throw new KernelError('restored recursor rule metadata mismatch');
   const oldTc=checker(transformed,d,old.levelParams),newTc=checker(finalEnv,d,neu.levelParams);
   for(let i=0;i<old.rules.length;i++){const expected=restoreExpression(oldTc.check(old.rules[i]!.rhs),d,p,recRename);const got=newTc.check(neu.rules[i]!.rhs);if(!newTc.isDefEq(got,expected))throw new KernelError(`restored recursor rule for '${nameToString(neu.rules[i]!.ctor)}' is not type preserving`);}
 };
 for(const it of d.types)compareRestoredRules(strName(it.name,'rec'),strName(it.name,'rec'));
 for(const fam of p.aux)compareRestoredRules(strName(fam.auxName,'rec'),recRename.get(nameKey(strName(fam.auxName,'rec')))!);
 for(const it of d.types){for(const cn of it.ctors.map(c=>c.name)){const ci=finalEnv.get(cn);if(ci.kind!=='constructor')throw new KernelError('restored constructor missing');checker(finalEnv,d,d.levelParams).check(ci.type);}const rn=strName(it.name,'rec');const ri=finalEnv.get(rn);if(ri.kind!=='recursor')throw new KernelError('restored recursor missing');const rtc=checker(finalEnv,d,ri.levelParams);rtc.ensureSort(rtc.check(ri.type),ri.type);}
 for(const fam of p.aux){const rn=recRename.get(nameKey(strName(fam.auxName,'rec')))!;const ri=finalEnv.get(rn);if(ri.kind!=='recursor')throw new KernelError('restored auxiliary recursor missing');const rtc=checker(finalEnv,d,ri.levelParams);rtc.ensureSort(rtc.check(ri.type),ri.type);for(const rule of ri.rules)rtc.check(rule.rhs);}
 validateInstalledRecursorsByReduction(finalEnv,d);
 const originalKeys=new Set(env.entries().map(x=>nameKey(x.name)));for(const i of finalEnv.entries())if(!originalKeys.has(nameKey(i.name)))env.add(i);
}
