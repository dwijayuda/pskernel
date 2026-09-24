import { Environment, KernelError } from '../core/environment.js';
import { Expr, exprLeanEq, exprLeanHash } from '../core/expr.js';
import { LocalContext, LocalDecl } from '../core/local-context.js';
import { Name, nameKey } from '../core/name.js';

function mix(h:number,x:number):number{
  h^=x>>>0;
  return Math.imul(h,0x01000193)>>>0;
}
export class LeanExprMap<V>{
  private readonly buckets=new Map<number,{key:Expr;value:V}[]>();
  private readonly identity=new WeakMap<object,{key:Expr;value:V}>();
  private count=0;
  get size():number{return this.count;}
  get(e:Expr):V|undefined{
    const fast=this.identity.get(e as object);if(fast)return fast.value;
    const h=exprLeanHash(e),bucket=this.buckets.get(h);if(!bucket)return undefined;
    for(const x of bucket)if(exprLeanEq(x.key,e)){this.identity.set(e as object,x);return x.value;}
    return undefined;
  }
  has(e:Expr):boolean{return this.get(e)!==undefined;}
  set(e:Expr,value:V):this{
    const h=exprLeanHash(e),bucket=this.buckets.get(h);
    if(bucket){
      for(const x of bucket)if(exprLeanEq(x.key,e)){x.value=value;this.identity.set(e as object,x);return this;}
      const x={key:e,value};bucket.push(x);this.identity.set(e as object,x);this.count++;return this;
    }
    const x={key:e,value};this.buckets.set(h,[x]);this.identity.set(e as object,x);this.count++;return this;
  }
}

export type ExprPair=readonly [Expr,Expr];

export class LeanExprPairSet{
  private readonly buckets=new Map<number,ExprPair[]>();
  private count=0;
  get size():number{return this.count;}
  private pairHash([a,b]:ExprPair):number{
    const x=exprLeanHash(a),y=exprLeanHash(b);
    return mix(mix(0x811c9dc5,x<y?x:y),x<y?y:x);
  }
  has(pair:ExprPair):boolean{
    const bucket=this.buckets.get(this.pairHash(pair));if(!bucket)return false;
    const [a,b]=pair;
    return bucket.some(([x,y])=>(exprLeanEq(a,x)&&exprLeanEq(b,y))||(exprLeanEq(a,y)&&exprLeanEq(b,x)));
  }
  add(pair:ExprPair):this{
    const h=this.pairHash(pair),bucket=this.buckets.get(h);
    if(bucket){if(this.has(pair))return this;bucket.push(pair);}
    else this.buckets.set(h,[pair]);
    this.count++;return this;
  }
}

/**
 * Per-type-checker memo state.
 *
 * Lean 4.34's expr_map and defeq pair sets use kernel structural Expr equality,
 * not object identity. These tables retain a WeakMap identity fast path, then
 * fall back to cached structural hashes plus exprLeanEq collision checks.
 */
export class KernelState {
  private boundEnvironment:Environment|undefined;
  private boundRevision=0;
  private readonly localDecls=new Map<string,LocalDecl>();
  private checkerConfigKey:string|undefined;
  private checkerNativeEvaluator:unknown=undefined;
  readonly infer=new LeanExprMap<Expr>();
  readonly checkedInfer=new LeanExprMap<Expr>();
  readonly whnfCore=new LeanExprMap<Expr>();
  readonly whnf=new LeanExprMap<Expr>();
  readonly unfold=new LeanExprMap<Expr>();
  readonly success=new LeanExprPairSet();
  readonly failure=new LeanExprPairSet();

  /** Shared Lean-style kernel recursion depth across local-context child checkers. */
  recDepth=0;

  /**
   * Lean's type_checker::state owns an environment value. TS Environment is
   * mutable, so bind the state to the exact identity/revision and fail closed
   * instead of letting old memo entries observe later declarations.
   */
  bindEnvironment(env:Environment):void{
    if(this.boundEnvironment===undefined){
      this.boundEnvironment=env;this.boundRevision=env.revision;return;
    }
    if(this.boundEnvironment!==env||this.boundRevision!==env.revision)
      throw new KernelError('type checker environment changed; create a new checker state');
  }

  /**
   * Memoized checked inference / WHNF / defeq results depend on more than the
   * environment and local context. Public TypeChecker callers may supply an
   * existing state, so fail closed if one state is reused under incompatible
   * safety, universe-policy, resource-limit, or native-evaluator settings.
   *
   * Lean's own state-sharing is internal and preserves these invariants; this
   * guard makes the same assumption explicit at the public TypeScript boundary.
   */
  bindCheckerConfig(config:{
    readonly definitionSafety:string;
    readonly allowedLevelParams:readonly Name[]|undefined;
    readonly maxRecDepth:number;
    readonly maxNatBytes:bigint;
    readonly nativeEvaluator:unknown|undefined;
  }):void{
    const lps=config.allowedLevelParams===undefined
      ? '<ignore-undefined-universes>'
      : [...config.allowedLevelParams].map(nameKey).sort().join('|');
    const key=`${config.definitionSafety}\0${config.maxRecDepth}\0${config.maxNatBytes}\0${lps}`;
    if(this.checkerConfigKey===undefined){
      this.checkerConfigKey=key;this.checkerNativeEvaluator=config.nativeEvaluator;return;
    }
    if(this.checkerConfigKey!==key||this.checkerNativeEvaluator!==config.nativeEvaluator)
      throw new KernelError('type checker state reused with incompatible checker configuration');
  }

  /**
   * Shared caches are sound only when an FVar id has one declaration throughout
   * the checker state, matching Lean's globally unique free-variable names.
   */
  bindLocalContext(lctx:LocalContext):void{
    for(const d of lctx.entries()){
      const old=this.localDecls.get(d.id);
      if(old===undefined){this.localDecls.set(d.id,d);continue;}
      if(old.kind!==d.kind||!exprLeanEq(old.type,d.type))
        throw new KernelError(`free variable '${d.id}' was rebound incompatibly in one checker state`);
      if(old.kind==='local'&&d.kind==='local'&&old.binderInfo!==d.binderInfo)
        throw new KernelError(`free variable '${d.id}' changed binder information in one checker state`);
      if(old.kind==='let'&&d.kind==='let'&&!exprLeanEq(old.value,d.value))
        throw new KernelError(`let variable '${d.id}' was rebound incompatibly in one checker state`);
    }
  }

  /** Lean's type_checker::state owns the name generator shared by all local scopes. */
  private nextLocalId=0;
  freshLocal(_prefix:string,lctx:LocalContext):string{
    let id:string;
    do{id=`_kernel_fresh@${this.nextLocalId++}`;}while(lctx.get(id)!==undefined||this.localDecls.has(id));
    return id;
  }

  pair(a:Expr,b:Expr):ExprPair{return [a,b];}
}
