import type {V061Expr} from '@proofscript/syntax';
import {
  TypeChecker,
  fvar,
  type Expr,
} from 'lean-ts-kernel';
import type {
  ElaboratedCoreTerm,
  V061CoreElabContext,
} from './v061-context.js';

function structuralArgumentName(expr:V061Expr):string|undefined {
  if(expr.kind==='reference')return expr.name;
  if(expr.kind==='group')return structuralArgumentName(expr.value);
  return undefined;
}

export function tryElaborateStructuralSelfCall(
  expr:Extract<V061Expr,{kind:'call'}>,
  context:V061CoreElabContext,
  expected:Expr|undefined,
):ElaboratedCoreTerm|undefined {
  const recursion=context.structuralRecursion;
  if(recursion===undefined||expr.callee!==recursion.functionName){
    return undefined;
  }
  if(expr.args.length!==1){
    throw new Error(
      'PS_ELAB_STRUCTURAL_RECURSION_ARITY: recursive call must have exactly one explicit decreasing argument',
    );
  }
  const argumentName=structuralArgumentName(expr.args[0]!);
  if(argumentName===undefined){
    throw new Error(
      'PS_ELAB_STRUCTURAL_RECURSION_ARGUMENT: recursive call must target a directly bound recursive field',
    );
  }
  const argumentId=context.locals.get(argumentName);
  const ihId=argumentId===undefined
    ?undefined
    :recursion.calls.get(argumentId);
  if(ihId===undefined){
    throw new Error(
      "PS_ELAB_STRUCTURAL_RECURSION_NOT_DECREASING: recursive call '"+
      expr.callee+"("+argumentName+")' is not on a direct recursive field",
    );
  }

  const checker=new TypeChecker(
    context.environment,
    context.localContext.clone(),
  );
  const term=fvar(ihId);
  const type=checker.check(term);
  if(
    expected!==undefined
    &&!checker.isDefEq(
      context.metaContext.instantiate(type),
      context.metaContext.instantiate(expected),
    )
  ){
    throw new Error(
      'PS_ELAB_STRUCTURAL_RECURSION_RESULT: induction hypothesis does not match expected result type',
    );
  }
  return {term,type};
}
