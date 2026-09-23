import { ConstantInfo, DefinitionInfo, DefinitionSafety, ReducibilityHints, isUnsafeConstant } from '../core/declaration.js';
import { Environment, KernelError } from '../core/environment.js';
import { Expr, app, appView, constant, exprEq, exprToString, forallE, fvar, getAppArgs, getAppFn, hasFVar, instantiateExprLevels, lam, mkAppN, natLit, sort, stripMData } from '../core/expr.js';
import { abstractFVar, instantiate1 } from '../core/instantiate.js';
import { Level, levelEquivalent, levelParamNames, levelSucc, levelToString, mkIMax, normalizesToZero } from '../core/level.js';
import { LocalContext } from '../core/local-context.js';
import { nameEq, nameToString } from '../core/name.js';
import { N } from './names.js';
import { checkNatSize, LEAN_NAT_MAX_SIZE_DEFAULT, reduceNatApp } from './reduction/nat.js';
import { stringLitToConstructor } from './reduction/literals.js';
import { NativeEvaluator, reduceNative } from './reduction/native.js';
import { reduceQuot } from './reduction/quot.js';
import { reduceRecursor } from './reduction/recursor.js';
import { KernelState } from './state.js';

export interface KernelLimits { readonly maxRecDepth:number; readonly maxNatBytes:bigint; }
const DEFAULT_LIMITS:KernelLimits={maxRecDepth:4096,maxNatBytes:LEAN_NAT_MAX_SIZE_DEFAULT};

function deltaInfo(i:ConstantInfo|undefined): DefinitionInfo|null {
  // Lean 4.34: only DefinitionVal has a delta-reducible value. Theorems and opaque constants do not.
  return i?.kind==='definition'?i:null;
}
function hint(i:DefinitionInfo):ReducibilityHints { return i.hints; }
function cmpHint(a:ReducibilityHints,b:ReducibilityHints):number{
  const rank=(h:ReducibilityHints)=>h.kind==='abbrev'?0:h.kind==='regular'?1:2; const ra=rank(a),rb=rank(b); if(ra!==rb)return ra-rb;
  if(a.kind==='regular'&&b.kind==='regular'){if(a.height!==b.height)return a.height>b.height?-1:1;}return 0;
}

export class TypeChecker {
  readonly state:KernelState;
  private depth=0;
  constructor(readonly env:Environment,readonly lctx=new LocalContext(),state?:KernelState,readonly limits:KernelLimits=DEFAULT_LIMITS,readonly definitionSafety:DefinitionSafety='safe',readonly allowedLevelParams?:readonly import('../core/name.js').Name[],private eagerReduce=false,readonly nativeEvaluator?:NativeEvaluator){this.state=state??new KernelState();}
  private rec<T>(f:()=>T):T{if(++this.depth>this.limits.maxRecDepth){this.depth--;throw new KernelError('deep recursion');}try{return f();}finally{this.depth--;}}
  private checkLevel(l:Level):void{if(!this.allowedLevelParams)return;for(const p of levelParamNames(l))if(!this.allowedLevelParams.some(q=>nameEq(p,q)))throw new KernelError(`invalid reference to undefined universe level parameter '${nameToString(p)}'`);}
  private withLocal<T>(name:string,type:Expr,k:(id:string,tc:TypeChecker)=>T):T{const c=this.lctx.clone(),id=c.fresh(name);c.addLocal(id,{kind:'str',prefix:{kind:'anonymous'},value:name},type);return k(id,new TypeChecker(this.env,c,this.state,this.limits,this.definitionSafety,this.allowedLevelParams,this.eagerReduce,this.nativeEvaluator));}
  private withLet<T>(name:string,type:Expr,value:Expr,k:(id:string,tc:TypeChecker)=>T):T{const c=this.lctx.clone(),id=c.fresh(name);c.addLet(id,{kind:'str',prefix:{kind:'anonymous'},value:name},type,value);return k(id,new TypeChecker(this.env,c,this.state,this.limits,this.definitionSafety,this.allowedLevelParams,this.eagerReduce,this.nativeEvaluator));}
  private isEagerReduceExpr(e:Expr):boolean{const v=appView(e);return v.fn.kind==='const'&&nameEq(v.fn.name,N.EagerReduce)&&v.args.length===2;}
  private withEagerReduction<T>(k:()=>T):T{const old=this.eagerReduce;this.eagerReduce=true;try{return k();}finally{this.eagerReduce=old;}}

  check(e:Expr):Expr { if(this.hasLoose(e))throw new KernelError('type checker does not support loose bound variables'); return this.infer(e,false); }
  infer(e:Expr,inferOnly=true):Expr{return this.rec(()=>this.inferCore(e,inferOnly));}
  private hasLoose(e:Expr):boolean{const go=(x:Expr,d:number):boolean=>{switch(x.kind){case'bvar':return x.index>=d;case'app':return go(x.fn,d)||go(x.arg,d);case'lam':case'forall':return go(x.type,d)||go(x.body,d+1);case'let':return go(x.type,d)||go(x.value,d)||go(x.body,d+1);case'mdata':return go(x.expr,d);case'proj':return go(x.expr,d);default:return false;}};return go(e,0);}

  private inferCore(e:Expr,inferOnly:boolean):Expr{
    const key=this.state.exprId(e),cache=inferOnly?this.state.infer:this.state.checkedInfer,cached=cache.get(key);if(cached)return cached;
    let r:Expr;
    switch(e.kind){
      case'bvar':throw new KernelError('loose bound variable in type checker');
      case'mvar':throw new KernelError('kernel type checker does not support metavariables');
      case'fvar':{const d=this.lctx.get(e.id);if(!d)throw new KernelError(`unknown free variable ${e.id}`);r=d.type;break;}
      case'sort':if(!inferOnly)this.checkLevel(e.level);r=sort(levelSucc(e.level));break;
      case'const':{const i=this.env.get(e.name);if(e.levels.length!==i.levelParams.length)throw new KernelError(`incorrect number of universe levels at ${nameToString(e.name)}`);if(!inferOnly){if(isUnsafeConstant(i)&&this.definitionSafety!=='unsafe')throw new KernelError(`invalid declaration, it uses unsafe declaration '${nameToString(e.name)}'`);if(i.kind==='definition'&&i.safety==='partial'&&this.definitionSafety==='safe')throw new KernelError(`invalid declaration, safe declaration must not contain partial declaration '${nameToString(e.name)}'`);for(const l of e.levels)this.checkLevel(l);}r=instantiateExprLevels(i.type,i.levelParams,e.levels);break;}
      case'lit':{if(e.literal.kind==='nat')checkNatSize(e.literal.value,this.limits.maxNatBytes,'Nat');const n=e.literal.kind==='nat'?N.Nat:N.String;if(!inferOnly)this.env.get(n);r=constant(n);break;}
      case'mdata':r=this.infer(e.expr,inferOnly);break;
      case'app':{
        const ft=this.ensureForall(this.infer(e.fn,inferOnly),e);const at=this.infer(e.arg,inferOnly);
        if(!inferOnly){const ok=this.isEagerReduceExpr(e.arg)?this.withEagerReduction(()=>this.isDefEq(ft.type,at)):this.isDefEq(ft.type,at);if(!ok){const ef=ft.type.kind==='sort'?` Sort.${levelToString(ft.type.level)}`:'';const af=at.kind==='sort'?` Sort.${levelToString(at.level)}`:'';throw new KernelError(`application type mismatch in ${exprToString(e)}: expected ${exprToString(ft.type)}${ef}, got ${exprToString(at)}${af} for argument ${exprToString(e.arg)}`);}}
        r=instantiate1(ft.body,e.arg);break;
      }
      case'lam':{
        try{if(!inferOnly)this.ensureSort(this.infer(e.type,inferOnly),e.type);
        r=this.withLocal('x',e.type,(id,tc)=>{const bt=tc.infer(instantiate1(e.body,fvar(id)),inferOnly);return forallE(e.name,e.type,abstractFVar(bt,id),e.binderInfo);});}catch(err){const msg=err instanceof Error?err.message:String(err);throw new KernelError(`lambda binder ${nameToString(e.name)} : ${exprToString(e.type)}: ${msg}`);}break;
      }
      case'forall':{
        try{const s1=this.ensureSort(this.infer(e.type,inferOnly),e.type);
        const s2=this.withLocal('x',e.type,(id,tc)=>tc.ensureSort(tc.infer(instantiate1(e.body,fvar(id)),inferOnly),e.body));
        r=sort(mkIMax(s1.level,s2.level));}catch(err){const msg=err instanceof Error?err.message:String(err);throw new KernelError(`forall binder ${nameToString(e.name)} : ${exprToString(e.type)}: ${msg}`);}break;
      }
      case'let':{
        if(!inferOnly)this.ensureSort(this.infer(e.type,inferOnly),e.type);const vt=this.infer(e.value,inferOnly);if(!inferOnly&&!this.isDefEq(vt,e.type))throw new KernelError('let value type mismatch');
        // Instantiating the value is definitionally equal to retaining the local let and avoids leaking an fvar.
        r=this.infer(instantiate1(e.body,e.value),inferOnly);break;
      }
      case'proj':r=this.inferProj(e,inferOnly);break;
    }
    cache.set(key,r);return r;
  }

  ensureSort(t:Expr,origin=t):Extract<Expr,{kind:'sort'}>{const w=this.whnf(t);if(w.kind!=='sort')throw new KernelError(`expected sort at ${exprToString(origin)}, got ${exprToString(w)}`);return w;}
  ensureForall(t:Expr,origin=t):Extract<Expr,{kind:'forall'}>{const w=this.whnf(t);if(w.kind!=='forall')throw new KernelError(`expected function type at ${exprToString(origin)}, got ${exprToString(w)}`);return w;}
  getSortLevel(e:Expr):Level{return this.ensureSort(this.whnf(this.infer(e)),e).level;}
  isProp(e:Expr):boolean{return normalizesToZero(this.getSortLevel(e));}

  private validProjIndex(index:number):boolean{return Number.isInteger(index)&&index>=0&&index<=0xffff_ffff;}
  private inferProj(e:Extract<Expr,{kind:'proj'}>,inferOnly:boolean):Expr{
    if(!this.validProjIndex(e.index))throw new KernelError('invalid projection index');
    const st=this.whnf(this.infer(e.expr,inferOnly));const av=appView(st);if(av.fn.kind!=='const'||!nameEq(av.fn.name,e.typeName))throw new KernelError('invalid projection: structure type mismatch');
    const ii=this.env.get(e.typeName);if(ii.kind!=='inductive'||ii.ctors.length!==1||av.args.length!==ii.numParams+ii.numIndices)throw new KernelError('invalid projection: not a fully applied structure');
    const ci=this.env.get(ii.ctors[0]!);if(ci.kind!=='constructor'||e.index>=ci.numFields)throw new KernelError('invalid projection index');
    let ct=instantiateExprLevels(ci.type,ci.levelParams,av.fn.levels);
    for(let i=0;i<ci.numParams;i++){const p=this.ensureForall(this.whnf(ct));ct=instantiate1(p.body,av.args[i]!);}
    const propStructure=this.isProp(st);
    for(let i=0;i<e.index;i++){
      const p=this.ensureForall(this.whnf(ct));
      // Lean only substitutes a previous projection when the remaining constructor type depends on it.
      const dependent=this.hasLoose(p.body);
      if(dependent){if(propStructure&&!this.isProp(p.type))throw new KernelError('invalid projection: cannot eliminate proof into data');ct=instantiate1(p.body,{kind:'proj',typeName:e.typeName,index:i,expr:e.expr});}
      else ct=p.body;
    }
    const field=this.ensureForall(this.whnf(ct)).type;if(propStructure&&!this.isProp(field))throw new KernelError('invalid projection: cannot eliminate proof into data');return field;
  }

  unfold(e:Expr):Expr|null{
    const av=appView(e);if(av.fn.kind!=='const')return null;const i=deltaInfo(this.env.find(av.fn.name));if(!i||av.fn.levels.length!==i.levelParams.length)return null;
    const value=instantiateExprLevels(i.value,i.levelParams,av.fn.levels);return mkAppN(value,av.args);
  }

  whnfCore(e:Expr,cheapRec=false,cheapProj=false):Expr{return this.rec(()=>{
    const key=this.state.exprId(e);
    // Lean 4.34 deliberately bypasses the shared whnfCore cache in cheap-rec/proj mode.
    // A full-mode result may have unfolded a recursor major or projection structure that
    // a cheap call is specifically required to leave opaque.
    if(!cheapRec&&!cheapProj){const cached=this.state.whnfCore.get(key);if(cached)return cached;}
    let x=e,cacheOriginal=true;
    const done=(r:Expr):Expr=>{if(!cheapRec&&!cheapProj&&cacheOriginal)this.state.whnfCore.set(key,r);return r;};
    while(true){
      if(x.kind==='mdata'){x=x.expr;continue;}
      if(x.kind==='let'){x=instantiate1(x.body,x.value);continue;}
      if(x.kind==='fvar'){const d=this.lctx.get(x.id);if(d?.kind==='let'){x=d.value;continue;}return done(x);}
      if(x.kind==='app'){
        const f=this.whnfCore(x.fn,cheapRec,cheapProj);if(f.kind==='lam'){x=instantiate1(f.body,x.arg);continue;} // overwritten below
        if(!exprEq(f,x.fn))x=app(f,x.arg);
        const q=this.env.quotInitialized?reduceQuot(x,y=>this.whnf(y)):null;if(q){if(exprEq(x,e))cacheOriginal=false;x=q;continue;}
        const rr=reduceRecursor(this.env,x,y=>cheapRec?this.whnfCore(y,cheapRec,cheapProj):this.whnf(y),y=>this.infer(y),(a,b)=>this.isDefEq(a,b),y=>this.isProp(y));if(rr){if(exprEq(x,e))cacheOriginal=false;x=rr;continue;}
        return done(x);
      }
      if(x.kind==='proj'){
        const s=cheapProj?this.whnfCore(x.expr,cheapRec,cheapProj):this.whnf(x.expr);const v=this.reduceProjCore(s,x.typeName,x.index);
        if(v){x=v;continue;}return done({...x,expr:s});
      }
      return done(x);
    }
  });}

  whnf(e:Expr):Expr{return this.rec(()=>{
    const k=this.state.exprId(e),c=this.state.whnf.get(k);if(c)return c;let x=e;
    for(let fuel=0;fuel<100000;fuel++){
      const c0=this.whnfCore(x);if(!exprEq(c0,x)){x=c0;continue;}
      const native=reduceNative(this.env,x,this.nativeEvaluator);if(native){x=native;continue;}
      const nr=reduceNatApp(this.env,x,y=>this.whnf(y),this.limits.maxNatBytes);if(nr){x=nr;continue;}
      const u=this.unfold(x);if(u){x=u;continue;}
      this.state.whnf.set(k,x);return x;
    }
    throw new KernelError('WHNF fuel exhausted');
  });}

  private quick(a:Expr,b:Expr):boolean|null{
    if(exprEq(a,b)||this.state.success.has(this.state.pair(a,b)))return true;
    if(a.kind===b.kind){switch(a.kind){
      case'sort':return b.kind==='sort'&&levelEquivalent(a.level,b.level);
      case'lit':return b.kind==='lit'&&exprEq(a,b);
      case'mdata':return b.kind==='mdata'?this.isDefEq(a.expr,b.expr):null;
      case'lam':case'forall':if(b.kind===a.kind)return this.defEqBinder(a,b);break;
    }}return null;
  }
  private defEqBinder(a:Extract<Expr,{kind:'lam'|'forall'}>,b:Extract<Expr,{kind:'lam'|'forall'}>):boolean{
    if(!this.isDefEq(a.type,b.type))return false;
    return this.withLocal('x',b.type,(id,tc)=>tc.isDefEq(instantiate1(a.body,fvar(id)),instantiate1(b.body,fvar(id))));
  }
  private proofIrrel(a:Expr,b:Expr):boolean|null{
    // Lean proof irrelevance applies when the *type* of a is a proposition.
    // `ta` itself is the proposition expression (e.g. `Eq Nat 0 0`), not `Sort 0`,
    // so asking whether `whnf(ta)` is a Sort incorrectly misses ordinary propositions.
    const ta=this.infer(a);
    if(this.isProp(ta)){const tb=this.infer(b);return this.isDefEq(ta,tb);}
    return null;
  }
  private tryEta(a:Expr,b:Expr):boolean{
    if(a.kind!=='lam'||b.kind==='lam')return false;
    const bt=this.whnf(this.infer(b));
    // Lean 4.34's eta probe is optional: a non-function type means "not eta-equal",
    // not a kernel type error.
    if(bt.kind!=='forall')return false;
    const eta=lam(bt.name,bt.type,app(b,{kind:'bvar',index:0}),bt.binderInfo);return this.isDefEq(a,eta);
  }
  /** Lean 4.34 structure eta: if s is the unique constructor application, compare its fields with projections of t. */
  private tryStructEtaCore(t:Expr,s:Expr):boolean{
    const av=appView(s);if(av.fn.kind!=='const')return false;const ci=this.env.find(av.fn.name);if(ci?.kind!=='constructor'||av.args.length!==ci.numParams+ci.numFields)return false;
    const ii=this.env.find(ci.induct);if(ii?.kind!=='inductive'||ii.isRec||ii.numIndices!==0||ii.ctors.length!==1)return false;
    if(!this.isDefEq(this.infer(t),this.infer(s)))return false;
    for(let i=0;i<ci.numFields;i++)if(!this.isDefEq({kind:'proj',typeName:ci.induct,index:i,expr:t},av.args[ci.numParams+i]!))return false;
    return true;
  }
  private tryStructEta(a:Expr,b:Expr):boolean{return this.tryStructEtaCore(a,b)||this.tryStructEtaCore(b,a);}
  private tryStringLitExpansionCore(t:Expr,s:Expr):boolean|null{
    if(t.kind!=='lit'||t.literal.kind!=='string'||s.kind!=='app')return null;
    const sf=getAppFn(s);if(sf.kind!=='const'||!nameEq(sf.name,N.StringOfList))return null;
    return this.isDefEq(this.whnf(stringLitToConstructor(t)),s);
  }
  private tryStringLitExpansion(t:Expr,s:Expr):boolean|null{
    const r=this.tryStringLitExpansionCore(t,s);return r!==null?r:this.tryStringLitExpansionCore(s,t);
  }
  private isDefEqUnitLike(t:Expr,s:Expr):boolean{
    const ty=this.whnf(this.infer(t)),head=getAppFn(ty);if(head.kind!=='const')return false;
    const ii=this.env.find(head.name);if(ii?.kind!=='inductive'||ii.isRec||ii.numIndices!==0||ii.ctors.length!==1)return false;
    const ci=this.env.find(ii.ctors[0]!);if(ci?.kind!=='constructor'||ci.numFields!==0)return false;
    return this.isDefEq(ty,this.infer(s));
  }
  private isNatZeroExpr(e:Expr):boolean{return (e.kind==='const'&&nameEq(e.name,N.NatZero))||(e.kind==='lit'&&e.literal.kind==='nat'&&e.literal.value===0n);}
  private natPredExpr(e:Expr):Expr|null{
    if(e.kind==='lit'&&e.literal.kind==='nat'&&e.literal.value>0n)return natLit(e.literal.value-1n);
    const av=appView(e);return av.fn.kind==='const'&&nameEq(av.fn.name,N.NatSucc)&&av.args.length===1?av.args[0]!:null;
  }
  private defEqOffset(a:Expr,b:Expr):boolean|null{
    if(this.isNatZeroExpr(a)&&this.isNatZeroExpr(b))return true;const pa=this.natPredExpr(a),pb=this.natPredExpr(b);return pa&&pb?this.isDefEq(pa,pb):null;
  }
  private tryUnfoldProjApp(e:Expr):Expr|null{const f=getAppFn(e);if(f.kind!=='proj')return null;const n=this.whnfCore(e,false,false);return exprEq(n,e)?null:n;}
  private reduceProjCore(e:Expr,typeName:import('../core/name.js').Name,index:number):Expr|null{
    if(!this.validProjIndex(index))return null;
    if(e.kind==='lit'&&e.literal.kind==='string')e=this.whnf(stringLitToConstructor(e));
    const av=appView(e);if(av.fn.kind!=='const')return null;
    const ci=this.env.find(av.fn.name);if(ci?.kind!=='constructor'||!nameEq(ci.induct,typeName)||index>=ci.numFields)return null;
    return av.args[ci.numParams+index]??null;
  }
  /** Lean 4.34 `lazy_delta_proj_reduction`: unfold the structure values lazily before comparing a field. */
  private lazyDeltaProjReduction(a:Expr,b:Expr,typeName:import('../core/name.js').Name,index:number):boolean{
    let x=a,y=b;
    const finish=()=>{const px=this.reduceProjCore(x,typeName,index),py=this.reduceProjCore(y,typeName,index);return px&&py?this.isDefEq(px,py):this.isDefEq(x,y);};
    for(let i=0;i<512;i++){
      const d=this.deltaStep(x,y);if(!d)return finish();if(d.equal)return true;x=d.a;y=d.b;
      const q=this.quick(x,y);if(q===true)return true;if(q===false)return finish();
    }
    return finish();
  }
  private isDefEqArgs(a:Expr,b:Expr):boolean{
    let x=a,y=b;while(x.kind==='app'&&y.kind==='app'){if(!this.isDefEq(x.arg,y.arg))return false;x=x.fn;y=y.fn;}return x.kind!=='app'&&y.kind!=='app';
  }
  private defEqApp(a:Expr,b:Expr):boolean{
    const av=appView(a),bv=appView(b);
    // Match Lean 4.34 evaluation order exactly: compare heads before rejecting arity mismatch.
    // Defeq is intentionally incomplete, so observable cache/evaluation history is part of parity.
    if(!this.isDefEq(av.fn,bv.fn))return false;if(av.args.length!==bv.args.length)return false;for(let i=0;i<av.args.length;i++)if(!this.isDefEq(av.args[i]!,bv.args[i]!))return false;return true;
  }
  private deltaStep(a:Expr,b:Expr):{a:Expr;b:Expr;equal?:boolean}|null{
    const af=getAppFn(a),bf=getAppFn(b);const ai=af.kind==='const'?deltaInfo(this.env.find(af.name)):null,bi=bf.kind==='const'?deltaInfo(this.env.find(bf.name)):null;
    if(!ai&&!bi)return null;
    if(ai&&!bi){const bp=this.tryUnfoldProjApp(b);if(bp)return {a,b:bp};const u=this.unfold(a);return u?{a:this.whnfCore(u,false,true),b}:null;}
    if(!ai&&bi){const ap=this.tryUnfoldProjApp(a);if(ap)return {a:ap,b};const u=this.unfold(b);return u?{a,b:this.whnfCore(u,false,true)}:null;}
    const c=cmpHint(hint(ai!),hint(bi!));if(c<0){const u=this.unfold(a)!;return {a:this.whnfCore(u,false,true),b};}if(c>0){const u=this.unfold(b)!;return {a,b:this.whnfCore(u,false,true)};}
    if(a.kind==='app'&&b.kind==='app'&&nameEq(ai!.name,bi!.name)&&hint(ai!).kind==='regular'){
      const pair=this.state.pair(a,b);if(!this.state.failure.has(pair)){
        const al=af.kind==='const'?af.levels:[],bl=bf.kind==='const'?bf.levels:[];
        if(al.length===bl.length&&al.every((l,i)=>levelEquivalent(l,bl[i]!))&&this.isDefEqArgs(a,b))return {a,b,equal:true};
        this.state.failure.add(pair);
      }
    }
    const ua=this.unfold(a),ub=this.unfold(b);return ua&&ub?{a:this.whnfCore(ua,false,true),b:this.whnfCore(ub,false,true)}:null;
  }

  private isDefEqCore(a:Expr,b:Expr):boolean{return this.rec(()=>{
    const q=this.quick(a,b);if(q!==null)return q;
    // Lean 4.34 reflection fast path: fully reduce a closed lhs when rhs is Bool.true.
    if((!hasFVar(a)||this.eagerReduce)&&b.kind==='const'&&nameEq(b.name,N.BoolTrue)){const w=this.whnf(a);if(w.kind==='const'&&nameEq(w.name,N.BoolTrue)){this.state.success.add(this.state.pair(a,b));return true;}}
    let x=this.whnfCore(a,false,true),y=this.whnfCore(b,false,true);const q2=this.quick(x,y);if(q2!==null)return q2;
    const pi=this.proofIrrel(x,y);if(pi!==null)return pi;
    for(let i=0;i<512;i++){
      const off=this.defEqOffset(x,y);if(off!==null)return off;
      if(((!hasFVar(x)&&!hasFVar(y))||this.eagerReduce)){const rx=reduceNatApp(this.env,x,z=>this.whnf(z),this.limits.maxNatBytes);if(rx)return this.isDefEq(rx,y);const ry=reduceNatApp(this.env,y,z=>this.whnf(z),this.limits.maxNatBytes);if(ry)return this.isDefEq(x,ry);}
      // Lean 4.34 checks native reduction after Nat reduction and before lazy delta, regardless of fvars.
      const nx=reduceNative(this.env,x,this.nativeEvaluator);if(nx)return this.isDefEq(nx,y);const ny=reduceNative(this.env,y,this.nativeEvaluator);if(ny)return this.isDefEq(x,ny);
      const d=this.deltaStep(x,y);if(!d)break;if(d.equal){this.state.success.add(this.state.pair(a,b));return true;}x=d.a;y=d.b;const z=this.quick(x,y);if(z!==null)return z;
    }
    if(x.kind==='const'&&y.kind==='const'&&nameEq(x.name,y.name)&&x.levels.length===y.levels.length&&x.levels.every((l,i)=>levelEquivalent(l,y.levels[i]!))){this.state.success.add(this.state.pair(a,b));return true;}
    if(x.kind==='fvar'&&y.kind==='fvar'&&x.id===y.id)return true;
    if(x.kind==='proj'&&y.kind==='proj'&&nameEq(x.typeName,y.typeName)&&x.index===y.index&&this.lazyDeltaProjReduction(x.expr,y.expr,x.typeName,x.index))return true;
    const xx=this.whnfCore(x,false,false),yy=this.whnfCore(y,false,false);if(!exprEq(xx,x)||!exprEq(yy,y))return this.isDefEq(xx,yy);
    if(x.kind==='app'&&y.kind==='app'&&this.defEqApp(x,y)){this.state.success.add(this.state.pair(a,b));return true;}
    if(this.tryEta(x,y)||this.tryEta(y,x)||this.tryStructEta(x,y)){this.state.success.add(this.state.pair(a,b));return true;}
    const str=this.tryStringLitExpansion(x,y);if(str!==null){if(str)this.state.success.add(this.state.pair(a,b));return str;}
    if(this.isDefEqUnitLike(x,y)){this.state.success.add(this.state.pair(a,b));return true;}
    return false;
  });}

  isDefEq(a:Expr,b:Expr):boolean{
    const r=this.isDefEqCore(a,b);
    // Lean 4.34 caches every successful public defeq query at the original pair,
    // independent of which internal path (delta, proof irrelevance, eta, etc.) proved it.
    if(r)this.state.success.add(this.state.pair(a,b));
    return r;
  }
}
