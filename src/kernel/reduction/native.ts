import { Environment, KernelError } from '../../core/environment.js';
import { Expr, appView, constant, natLit } from '../../core/expr.js';
import { Name, nameEq, nameToString } from '../../core/name.js';
import { N } from '../names.js';

export type NativeReductionKind='bool'|'nat';
export type NativeEvaluationResult=
  | {readonly kind:'bool';readonly value:boolean}
  | {readonly kind:'nat';readonly value:bigint};

/**
 * Optional extension of the kernel TCB used to model Lean 4.34 in-kernel native
 * reduction.
 *
 * Lean's official kernel calls the compiler IR interpreter for
 * `Lean.reduceBool c` / `Lean.reduceNat c`. That evaluation observes
 * `[implemented_by]`, `[extern]`, and compiled implementations, so ordinary
 * kernel normalization of `c` is not a behaviorally equivalent substitute.
 * External checkers should therefore leave this provider unset and fail closed.
 */
export interface NativeEvaluator {
  evaluate(env:Environment,request:{readonly kind:NativeReductionKind;readonly constant:Name}):NativeEvaluationResult|null;
}

/** Parse and execute a Lean 4.34 native-reduction marker through an explicitly
 * trusted provider. Returns null when `e` is not a native-reduction marker. */
export function reduceNative(env:Environment,e:Expr,evaluator?:NativeEvaluator):Expr|null {
  const {fn,args}=appView(e);
  if(fn.kind!=='const'||args.length!==1||args[0]!.kind!=='const')return null;
  const isBool=nameEq(fn.name,N.LeanReduceBool),isNat=nameEq(fn.name,N.LeanReduceNat);
  if(!isBool&&!isNat)return null;
  const kind:NativeReductionKind=isBool?'bool':'nat';
  if(!evaluator)throw new KernelError(`${isBool?'Lean.reduceBool':'Lean.reduceNat'} requires compiler-IR evaluation; no native evaluator is configured`);
  const result=evaluator.evaluate(env,{kind,constant:args[0]!.name});
  if(result===null)throw new KernelError(`${isBool?'Lean.reduceBool':'Lean.reduceNat'} native evaluator has no result for '${nameToString(args[0]!.name)}'`);
  if(result.kind!==kind)throw new KernelError(`${isBool?'Lean.reduceBool':'Lean.reduceNat'} native evaluator returned the wrong result kind for '${nameToString(args[0]!.name)}'`);
  if(result.kind==='bool')return constant(result.value?N.BoolTrue:N.BoolFalse);
  if(result.value<0n)throw new KernelError(`Lean.reduceNat native evaluator returned a negative value for '${nameToString(args[0]!.name)}'`);
  return natLit(result.value);
}
