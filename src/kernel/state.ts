import { Expr, exprLeanEq } from '../core/expr.js';
import { Level } from '../core/level.js';
import { LocalContext } from '../core/local-context.js';
import { nameKey } from '../core/name.js';

function mix(h:number,x:number):number{
  h^=x>>>0;
  return Math.imul(h,0x01000193)>>>0;
}
function hashString(s:string):number{
  let h=0x811c9dc5;
  for(let i=0;i<s.length;i++)h=mix(h,s.charCodeAt(i));
  return h>>>0;
}

class LeanExprHasher {
  private readonly exprHashes=new WeakMap<object,number>();
  private readonly levelHashes=new WeakMap<object,number>();

  private levelHash(root:Level):number{
    const cached=this.levelHashes.get(root as object);if(cached!==undefined)return cached;
    const todo:{l:Level;done:boolean}[]=[{l:root,done:false}];
    while(todo.length){
      const f=todo.pop()!,l=f.l;
      if(this.levelHashes.has(l as object))continue;
      if(!f.done){
        todo.push({l,done:true});
        if(l.kind==='succ')todo.push({l:l.of,done:false});
        else if(l.kind==='max'||l.kind==='imax')todo.push({l:l.right,done:false},{l:l.left,done:false});
        continue;
      }
      let h=hashString(l.kind);
      switch(l.kind){
        case'zero':break;
        case'param':case'mvar':h=mix(h,hashString(nameKey(l.name)));break;
        case'succ':h=mix(h,this.levelHashes.get(l.of as object)!);break;
        case'max':case'imax':
          h=mix(h,this.levelHashes.get(l.left as object)!);
          h=mix(h,this.levelHashes.get(l.right as object)!);
          break;
      }
      this.levelHashes.set(l as object,h>>>0);
    }
    return this.levelHashes.get(root as object)!;
  }

  hash(root:Expr):number{
    const cached=this.exprHashes.get(root as object);if(cached!==undefined)return cached;
    const todo:{e:Expr;done:boolean}[]=[{e:root,done:false}];
    while(todo.length){
      const f=todo.pop()!,e=f.e;
      if(this.exprHashes.has(e as object))continue;
      if(!f.done){
        todo.push({e,done:true});
        switch(e.kind){
          case'app':todo.push({e:e.arg,done:false},{e:e.fn,done:false});break;
          case'lam':case'forall':todo.push({e:e.body,done:false},{e:e.type,done:false});break;
          case'let':todo.push({e:e.body,done:false},{e:e.value,done:false},{e:e.type,done:false});break;
          case'mdata':case'proj':todo.push({e:e.expr,done:false});break;
          default:break;
        }
        continue;
      }
      let h=hashString(e.kind);
      switch(e.kind){
        case'bvar':h=mix(h,e.index);break;
        case'fvar':case'mvar':h=mix(h,hashString(e.id));break;
        case'sort':h=mix(h,this.levelHash(e.level));break;
        case'const':
          h=mix(h,hashString(nameKey(e.name)));h=mix(h,e.levels.length);
          for(const l of e.levels)h=mix(h,this.levelHash(l));
          break;
        case'app':h=mix(mix(h,this.exprHashes.get(e.fn as object)!),this.exprHashes.get(e.arg as object)!);break;
        case'lam':case'forall':
          // Lean kernel structural equality intentionally ignores binder display names/info.
          h=mix(mix(h,this.exprHashes.get(e.type as object)!),this.exprHashes.get(e.body as object)!);
          break;
        case'let':
          // Lean structural equality ignores the display name but keeps let_nondep.
          h=mix(h,e.nondep?1:0);
          h=mix(h,this.exprHashes.get(e.type as object)!);
          h=mix(h,this.exprHashes.get(e.value as object)!);
          h=mix(h,this.exprHashes.get(e.body as object)!);
          break;
        case'lit':
          h=mix(h,hashString(e.literal.kind));
          h=mix(h,hashString(e.literal.kind==='nat'?e.literal.value.toString():e.literal.value));
          break;
        case'mdata':
          // Metadata participates in equality. A coarse metadata hash is deliberate:
          // exact ordered-payload equality is checked by exprLeanEq on bucket hits.
          h=mix(h,this.exprHashes.get(e.expr as object)!);
          break;
        case'proj':
          h=mix(h,hashString(nameKey(e.typeName)));h=mix(h,e.index);
          h=mix(h,this.exprHashes.get(e.expr as object)!);
          break;
      }
      this.exprHashes.set(e as object,h>>>0);
    }
    return this.exprHashes.get(root as object)!;
  }
}

export class LeanExprMap<V>{
  private readonly buckets=new Map<number,{key:Expr;value:V}[]>();
  private readonly identity=new WeakMap<object,{key:Expr;value:V}>();
  private count=0;
  constructor(private readonly hasher:LeanExprHasher){}
  get size():number{return this.count;}
  get(e:Expr):V|undefined{
    const fast=this.identity.get(e as object);if(fast)return fast.value;
    const h=this.hasher.hash(e),bucket=this.buckets.get(h);if(!bucket)return undefined;
    for(const x of bucket)if(exprLeanEq(x.key,e)){this.identity.set(e as object,x);return x.value;}
    return undefined;
  }
  has(e:Expr):boolean{return this.get(e)!==undefined;}
  set(e:Expr,value:V):this{
    const h=this.hasher.hash(e),bucket=this.buckets.get(h);
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
  constructor(private readonly hasher:LeanExprHasher){}
  get size():number{return this.count;}
  private pairHash([a,b]:ExprPair):number{
    const x=this.hasher.hash(a),y=this.hasher.hash(b);
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
  private readonly hasher=new LeanExprHasher();
  readonly infer=new LeanExprMap<Expr>(this.hasher);
  readonly checkedInfer=new LeanExprMap<Expr>(this.hasher);
  readonly whnfCore=new LeanExprMap<Expr>(this.hasher);
  readonly whnf=new LeanExprMap<Expr>(this.hasher);
  readonly unfold=new LeanExprMap<Expr>(this.hasher);
  readonly success=new LeanExprPairSet(this.hasher);
  readonly failure=new LeanExprPairSet(this.hasher);

  /** Shared Lean-style kernel recursion depth across local-context child checkers. */
  recDepth=0;

  /** Lean's type_checker::state owns the name generator shared by all local scopes. */
  private nextLocalId=0;
  freshLocal(prefix:string,lctx:LocalContext):string{
    let id:string;
    do{id=`${prefix}@${this.nextLocalId++}`;}while(lctx.get(id)!==undefined);
    return id;
  }

  pair(a:Expr,b:Expr):ExprPair{return [a,b];}
}
