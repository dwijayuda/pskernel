import type {V061Expr} from '@proofscript/syntax';
import {
  TypeChecker,
  type Expr,
  fvar,
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

export function elaborateV061ByExpression(
  expr:Extract<V061Expr,{kind:'by'}>,
  context:V061CoreElabContext,
  expected:Expr|undefined,
  elaborate:V061TermElaborator,
):ElaboratedCoreTerm {
  if(expected===undefined){
    throw new Error(
      'PS_ELAB_TACTIC_EXPECTED_TYPE: tactic blocks require an expected goal type',
    );
  }
  const checker=new TypeChecker(
    context.environment,
    context.localContext.clone(),
  );

  if(expr.tactic.kind==='exact'){
    const proof=elaborate(expr.tactic.proof,context,expected);
    if(
      !checker.isDefEq(
        context.metaContext.instantiate(proof.type),
        context.metaContext.instantiate(expected),
      )
    ){
      throw new Error(
        'PS_ELAB_TACTIC_EXACT: proof term does not match the goal',
      );
    }
    return proof;
  }

  const candidates=[...context.locals.entries()].reverse();
  for(const [,id] of candidates){
    const declaration=context.localContext.get(id);
    if(
      declaration!==undefined
      &&checker.isDefEq(
        context.metaContext.instantiate(declaration.type),
        context.metaContext.instantiate(expected),
      )
    ){
      return {term:fvar(id),type:declaration.type};
    }
  }
  throw new Error(
    'PS_ELAB_TACTIC_ASSUMPTION: no local hypothesis matches the goal',
  );
}
