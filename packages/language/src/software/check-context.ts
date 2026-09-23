import type {V061Expr} from '@proofscript/syntax';
import type {
  CheckedSoftwareConstructorRef,
  CheckedSoftwareExpr,
  CheckedSoftwareInductive,
  CheckedSoftwareStructure,
  SoftwareSignature,
  SoftwareType,
} from './types.js';

export interface SoftwareExpressionContext {
  readonly locals:ReadonlyMap<string,SoftwareType>;
  readonly signatures:ReadonlyMap<string,SoftwareSignature>;
  readonly structures:ReadonlyMap<string,CheckedSoftwareStructure>;
  readonly inductives:ReadonlyMap<string,CheckedSoftwareInductive>;
  readonly constructors:ReadonlyMap<string,CheckedSoftwareConstructorRef>;
}

export type CheckSoftwareExpr=(
  expr:V061Expr,
  context:SoftwareExpressionContext,
  expected?:SoftwareType,
)=>CheckedSoftwareExpr;

export function nominalTypeNames(context:SoftwareExpressionContext):ReadonlySet<string> {
  return new Set([
    ...context.structures.keys(),
    ...context.inductives.keys(),
  ]);
}

export function withSoftwareLocal(
  context:SoftwareExpressionContext,
  name:string,
  type:SoftwareType,
):SoftwareExpressionContext {
  const locals=new Map(context.locals);
  locals.set(name,type);
  return {...context,locals};
}
