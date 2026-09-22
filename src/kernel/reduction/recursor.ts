import { RecursorInfo } from '../../core/declaration.js';
import { Environment } from '../../core/environment.js';
import { Expr, appView, constant, getAppFn, mkAppN } from '../../core/expr.js';
import { instantiateExprLevels } from '../../core/expr.js';
import { nameEq, Name } from '../../core/name.js';
import { stringLitToConstructor } from './literals.js';
import { natToCtor } from './nat.js';

function firstCtor(env:Environment,inductName:RecursorInfo['all'][number]){const i=env.find(inductName);return i?.kind==='inductive'?i.ctors[0]:undefined;}
function majorInduct(ri:RecursorInfo):Name|null{
 let t=ri.type;const majorIdx=ri.numParams+ri.numMotives+ri.numMinors+ri.numIndices;
 for(let i=0;i<majorIdx;i++){if(t.kind!=='forall')return null;t=t.body;}
 if(t.kind!=='forall')return null;const h=getAppFn(t.type);return h.kind==='const'?h.name:null;
}
function isCtorApp(env:Environment,e:Expr):boolean{const h=getAppFn(e);return h.kind==='const'&&env.find(h.name)?.kind==='constructor';}
function toCtorWhenStructure(env:Environment,ri:RecursorInfo,e:Expr,whnf:(x:Expr)=>Expr,infer:(x:Expr)=>Expr,isProp:(x:Expr)=>boolean):Expr{
 const ind=majorInduct(ri);if(!ind||isCtorApp(env,e))return e;const ii=env.find(ind);if(ii?.kind!=='inductive'||ii.isRec||ii.numIndices!==0||ii.ctors.length!==1)return e;
 const eType=whnf(infer(e)),tv=appView(eType);if(tv.fn.kind!=='const'||!nameEq(tv.fn.name,ind)||isProp(eType))return e;
 const ci=env.find(ii.ctors[0]!);if(ci?.kind!=='constructor'||tv.args.length<ci.numParams)return e;
 const params=tv.args.slice(0,ci.numParams),fields:Array<Expr>=[];for(let i=0;i<ci.numFields;i++)fields.push({kind:'proj',typeName:ind,index:i,expr:e});
 return mkAppN(constant(ci.name,tv.fn.levels),[...params,...fields]);
}

export function reduceRecursor(env:Environment,e:Expr,whnf:(x:Expr)=>Expr,infer:(x:Expr)=>Expr,isDefEq:(a:Expr,b:Expr)=>boolean,isProp:(x:Expr)=>boolean):Expr|null{
 const {fn,args}=appView(e);if(fn.kind!=='const')return null;const ri=env.find(fn.name);if(!ri||ri.kind!=='recursor')return null;
 const majorIdx=ri.numParams+ri.numMotives+ri.numMinors+ri.numIndices;if(args.length<=majorIdx)return null;const major=args[majorIdx]!;
 let mw=major;
 if(ri.k){const ty=whnf(infer(major));const tv=appView(ty);if(tv.fn.kind==='const'){const tvName=tv.fn.name;if(ri.all.some(n=>nameEq(n,tvName))){const ctor=firstCtor(env,tvName);if(ctor){const ci=env.find(ctor);if(ci?.kind==='constructor'){const candidate=mkAppN(constant(ctor,tv.fn.levels),tv.args.slice(0,ci.numParams));if(isDefEq(ty,infer(candidate)))mw=candidate;}}}}}
 mw=whnf(mw);
 if(mw.kind==='lit'&&mw.literal.kind==='nat')mw=natToCtor(mw.literal.value);
 else if(mw.kind==='lit'&&mw.literal.kind==='string')mw=whnf(stringLitToConstructor(mw));
 else mw=toCtorWhenStructure(env,ri,mw,whnf,infer,isProp);
 const mv=appView(mw);if(mv.fn.kind!=='const')return null;const mvName=mv.fn.name;const rule=ri.rules.find(r=>nameEq(r.ctor,mvName));if(!rule||mv.args.length<rule.nFields)return null;
 let rhs=instantiateExprLevels(rule.rhs,ri.levelParams,fn.levels);const firstIndex=ri.numParams+ri.numMotives+ri.numMinors;rhs=mkAppN(rhs,args.slice(0,firstIndex));
 // Nested inductives can make constructor and recursor parameter counts differ, so derive
 // the constructor parameter prefix from the actual major application as Lean does.
 const nparams=mv.args.length-rule.nFields;rhs=mkAppN(rhs,mv.args.slice(nparams));rhs=mkAppN(rhs,args.slice(majorIdx+1));return rhs;
}
