import type {V061Expr} from '@proofscript/syntax';
import {
  TypeChecker,
  constant,
  levelSucc,
  levelZero,
  mkAppN,
} from 'lean-ts-kernel';
import type {
  ElaboratedCoreTerm,
  V061CoreElabContext,
} from './v061-context.js';
import {
  elaborateV061NatArithmeticExpression,
  elaborateV061NatCondition,
  isV061NatRelation,
  type ElaboratedNatCondition,
} from './v061-nat-notation-elab.js';
import {
  elaborateV061BoolBinaryNotation,
  isV061BoolBinary,
} from './v061-bool-notation-elab.js';
import {
  elaborateV061PrimitiveBooleanEquality,
} from './v061-primitive-equality-elab.js';
import {
  requireV061NotationConstant,
  type V061TermElaborator,
} from './v061-notation-support.js';

export type {V061TermElaborator} from './v061-notation-support.js';
export {elaborateV061UnaryNotation} from './v061-bool-notation-elab.js';

export function elaborateV061Condition(
  expr:V061Expr,
  context:V061CoreElabContext,
  elaborate:V061TermElaborator,
):ElaboratedCoreTerm&{readonly decider:import('lean-ts-kernel').Expr} {
  if(expr.kind==='binary'&&isV061NatRelation(expr.operator)){
    return elaborateV061NatCondition(expr,context,elaborate);
  }
  const boolType=constant(requireV061NotationConstant(context,'Bool'));
  const checked=elaborate(expr,context,boolType);
  const checker=new TypeChecker(
    context.environment,
    context.localContext.clone(),
  );
  if(!checker.isDefEq(checked.type,boolType)){
    throw new Error(
      'PS_ELAB_IF_CONDITION_BOOL: condition did not elaborate to Bool',
    );
  }
  const trueTerm=constant(requireV061NotationConstant(context,'Bool.true'));
  const term=mkAppN(
    constant(
      requireV061NotationConstant(context,'Eq'),
      [levelSucc(levelZero)],
    ),
    [boolType,checked.term,trueTerm],
  );
  const type=checker.check(term);
  const decider=mkAppN(
    constant(requireV061NotationConstant(context,'Bool.decEq')),
    [checked.term,trueTerm],
  );
  checker.check(decider);
  return {term,type,decider};
}

export function elaborateV061BinaryNotation(
  expr:Extract<V061Expr,{kind:'binary'}>,
  context:V061CoreElabContext,
  expected:import('lean-ts-kernel').Expr|undefined,
  elaborate:V061TermElaborator,
):ElaboratedCoreTerm {
  if(isV061BoolBinary(expr.operator)){
    return elaborateV061BoolBinaryNotation(
      expr,
      context,
      expected,
      elaborate,
    );
  }

  if(expr.operator==='=='||expr.operator==='!='){
    const equality=elaborateV061PrimitiveBooleanEquality(
      expr,
      context,
      elaborate,
    );
    const checker=new TypeChecker(
      context.environment,
      context.localContext.clone(),
    );
    if(
      expected!==undefined
      &&!checker.isDefEq(
        context.metaContext.instantiate(expected),
        equality.type,
      )
    ){
      throw new Error(
        "PS_ELAB_EQUALITY_EXPECTED_TYPE: operator '"+expr.operator+
        "' produces Bool",
      );
    }
    return equality;
  }

  if(isV061NatRelation(expr.operator)){
    const condition=elaborateV061NatCondition(
      expr,
      context,
      elaborate,
    );
    const checker=new TypeChecker(
      context.environment,
      context.localContext.clone(),
    );
    if(
      expected!==undefined
      &&!checker.isDefEq(condition.type,expected)
    ){
      throw new Error(
        "PS_ELAB_NAT_RELATION_EXPECTED_TYPE: operator '"+expr.operator+
        "' produces a proposition",
      );
    }
    return {term:condition.term,type:condition.type};
  }

  return elaborateV061NatArithmeticExpression(
    expr,
    context,
    expected,
    elaborate,
  );
}
