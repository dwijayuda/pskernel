import type {V061Expr} from '@proofscript/syntax';
import {
  nameFromDotted,
  type Expr,
} from 'lean-ts-kernel';
import type {
  ElaboratedCoreTerm,
  V061CoreElabContext,
} from './v061-context.js';

export type V061TermElaborator=(
  expr:V061Expr,
  context:V061CoreElabContext,
  expected?:Expr,
)=>ElaboratedCoreTerm;

export function requireV061NotationConstant(
  context:V061CoreElabContext,
  name:string,
):ReturnType<typeof nameFromDotted> {
  const parsed=nameFromDotted(name);
  if(context.environment.find(parsed)===undefined){
    throw new Error(
      "PS_ELAB_NAT_ENVIRONMENT: '"+name+
      "' is unavailable in the elaboration environment",
    );
  }
  return parsed;
}
