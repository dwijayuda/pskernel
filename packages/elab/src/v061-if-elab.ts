import type {V061Expr} from '@proofscript/syntax';
import {
  TypeChecker,
  constant,
  mkAppN,
  nameFromDotted,
  type Expr,
} from 'lean-ts-kernel';
import type {
  ElaboratedCoreTerm,
  V061CoreElabContext,
} from './v061-context.js';
import {
  elaborateV061NatCondition,
  type V061TermElaborator,
} from './v061-notation-elab.js';

export function elaborateV061IfExpression(
  expr:Extract<V061Expr,{kind:'if'}>,
  context:V061CoreElabContext,
  expected:Expr|undefined,
  elaborate:V061TermElaborator,
):ElaboratedCoreTerm {
  if(expr.condition.kind!=='binary'){
    throw new Error(
      'PS_ELAB_IF_CONDITION_UNSUPPORTED: verified if currently requires '+
      'a decidable Nat comparison (<, <=, >, >=)',
    );
  }
  const condition=elaborateV061NatCondition(
    expr.condition,
    context,
    elaborate,
  );
  const thenBranch=elaborate(
    expr.thenBranch,
    context,
    expected,
  );
  const resultType=expected??thenBranch.type;
  const checker=new TypeChecker(
    context.environment,
    context.localContext.clone(),
  );
  if(!checker.isDefEq(thenBranch.type,resultType)){
    throw new Error(
      'PS_ELAB_IF_THEN_TYPE: then branch does not match expected type',
    );
  }
  const elseBranch=elaborate(
    expr.elseBranch,
    context,
    resultType,
  );
  if(!checker.isDefEq(elseBranch.type,resultType)){
    throw new Error(
      'PS_ELAB_IF_ELSE_TYPE: branches have different types',
    );
  }

  const ite=nameFromDotted('ite');
  if(context.environment.find(ite)===undefined){
    throw new Error(
      "PS_ELAB_IF_ENVIRONMENT: 'ite' is unavailable in the elaboration environment",
    );
  }
  const universe=checker.getSortLevel(resultType);
  const term=mkAppN(
    constant(ite,[universe]),
    [
      resultType,
      condition.term,
      condition.decider,
      thenBranch.term,
      elseBranch.term,
    ],
  );
  const type=checker.check(term);
  if(!checker.isDefEq(type,resultType)){
    throw new Error(
      'PS_ELAB_IF_RESULT_TYPE: elaborated ite has unexpected type',
    );
  }
  return {term,type};
}
