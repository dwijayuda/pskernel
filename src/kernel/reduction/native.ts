import { Environment, KernelError } from '../../core/environment.js';
import { Expr, appView, constant, natLit } from '../../core/expr.js';
import { nameEq } from '../../core/name.js';
import { N } from '../names.js';
import { asNat } from './nat.js';

/**
 * Lean 4.34 evaluates `Lean.reduceBool c` / `Lean.reduceNat c` by running the
 * compiled kernel IR for the closed constant `c`.
 *
 * This checker supports a deliberately conservative first tier: if ordinary
 * kernel reduction can already normalize `c` to a concrete Bool/Nat, returning
 * that value is compiler-independent and therefore does not enlarge the TCB.
 * Cases that require compiler IR (partial definitions, implementation overrides,
 * externs, etc.) still fail closed instead of guessing.
 */
export function reduceNative(_env:Environment,e:Expr,whnfClosed?:(x:Expr)=>Expr):Expr|null {
  const {fn,args}=appView(e);
  if(fn.kind!=='const'||args.length!==1||args[0]!.kind!=='const')return null;
  const isBool=nameEq(fn.name,N.LeanReduceBool),isNat=nameEq(fn.name,N.LeanReduceNat);
  if(!isBool&&!isNat)return null;
  if(!whnfClosed)throw new KernelError('native reduction requires a closed-term evaluator');
  const value=whnfClosed(args[0]!);
  if(isBool&&value.kind==='const'&&(nameEq(value.name,N.BoolTrue)||nameEq(value.name,N.BoolFalse)))return constant(value.name,value.levels);
  if(isNat){const n=asNat(value);if(n!==null)return natLit(n);}
  throw new KernelError(`${isBool?'Lean.reduceBool':'Lean.reduceNat'} requires compiler-IR evaluation for this constant; refusing to guess its result`);
}
