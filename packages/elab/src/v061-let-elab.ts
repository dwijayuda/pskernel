import type {V061Expr} from '@proofscript/syntax';
import {
  TypeChecker,
  abstractFVar,
  nameFromDotted,
  type Expr,
} from 'lean-ts-kernel';
import type {
  ElaboratedCoreTerm,
  V061CoreElabContext,
} from './v061-context.js';
import {elaborateV061Type} from './v061-type-elab.js';

export type LetTermElaborator=(
  expr:V061Expr,
  context:V061CoreElabContext,
  expected?:Expr,
)=>ElaboratedCoreTerm;

export function elaborateV061LetExpression(
  expr:Extract<V061Expr,{kind:'let'}>,
  context:V061CoreElabContext,
  expected:Expr|undefined,
  elaborate:LetTermElaborator,
):ElaboratedCoreTerm {
  const checker=new TypeChecker(
    context.environment,
    context.localContext.clone(),
  );
  const declaredType=expr.declaredType===undefined
    ?undefined
    :elaborateV061Type(expr.declaredType,context);
  const value=elaborate(expr.value,context,declaredType);
  const bindingType=declaredType??value.type;
  if(
    declaredType!==undefined
    &&!checker.isDefEq(
      context.metaContext.instantiate(value.type),
      context.metaContext.instantiate(declaredType),
    )
  ){
    throw new Error(
      'PS_ELAB_LET_TYPE: let value does not match its declared type',
    );
  }

  const next=context.localContext.clone();
  const id=next.fresh(expr.name);
  const userName=nameFromDotted(expr.name);
  next.addLet(id,userName,bindingType,value.term);
  const locals=new Map(context.locals);
  locals.set(expr.name,id);
  const bodyContext={...context,localContext:next,locals};
  const body=elaborate(expr.body,bodyContext,expected);
  const term={
    kind:'let' as const,
    name:userName,
    type:bindingType,
    value:value.term,
    body:abstractFVar(body.term,id),
  };
  const resultType=checker.check(term);
  if(
    expected!==undefined
    &&!checker.isDefEq(
      context.metaContext.instantiate(resultType),
      context.metaContext.instantiate(expected),
    )
  ){
    throw new Error(
      'PS_ELAB_LET_RESULT_TYPE: let expression does not match expected type',
    );
  }
  return {term,type:resultType};
}
