import { Expr } from '../core/expr.js';

/**
 * Per-type-checker memo state.
 *
 * Lean keys these caches by expression objects/hashes.  Using recursively
 * serialized structural strings here caused quadratic allocation on large
 * replay corpora.  Expressions are immutable, so object identity is a safe
 * memoization key: an identity miss only loses a cache hit; it cannot change
 * kernel semantics.
 */
export class KernelState {
  readonly infer=new Map<number,Expr>();
  readonly checkedInfer=new Map<number,Expr>();
  readonly whnfCore=new Map<number,Expr>();
  readonly whnf=new Map<number,Expr>();
  readonly unfold=new Map<number,Expr>();
  readonly success=new Set<string>();
  readonly failure=new Set<string>();

  /** Shared Lean-style kernel recursion depth across local-context child checkers. */
  recDepth=0;

  private readonly ids=new WeakMap<object,number>();
  private nextId=1;

  exprId(e:Expr):number {
    const old=this.ids.get(e);
    if(old!==undefined)return old;
    const id=this.nextId++;
    this.ids.set(e,id);
    return id;
  }

  pair(a:Expr,b:Expr):string {
    const x=this.exprId(a),y=this.exprId(b);
    return x<y?`${x}:${y}`:`${y}:${x}`;
  }
}
