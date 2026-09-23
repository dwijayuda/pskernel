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

export type V061TermElaborator=(
  expr:V061Expr,
  context:V061CoreElabContext,
  expected?:Expr,
)=>ElaboratedCoreTerm;

const natOperators=new Map<string,string>([
  ['+','Nat.add'],
  ['-','Nat.sub'],
  ['*','Nat.mul'],
]);

export function elaborateV061BinaryNotation(
  expr:Extract<V061Expr,{kind:'binary'}>,
  context:V061CoreElabContext,
  expected:Expr|undefined,
  elaborate:V061TermElaborator,
):ElaboratedCoreTerm {
  const constantName=natOperators.get(expr.operator);
  if(constantName===undefined){
    throw new Error(
      "PS_ELAB_NOTATION_UNSUPPORTED: operator '"+expr.operator+
      "' requires Lean-compatible notation/typeclass elaboration",
    );
  }

  const natName=nameFromDotted('Nat');
  const nat=context.environment.find(natName);
  if(nat===undefined){
    throw new Error(
      'PS_ELAB_NAT_ENVIRONMENT: Nat is unavailable in the elaboration environment',
    );
  }
  const operationName=nameFromDotted(constantName);
  if(context.environment.find(operationName)===undefined){
    throw new Error(
      "PS_ELAB_NAT_ENVIRONMENT: '"+constantName+
      "' is unavailable in the elaboration environment",
    );
  }

  const natType=constant(natName);
  const checker=new TypeChecker(
    context.environment,
    context.localContext.clone(),
  );
  if(
    expected!==undefined
    &&!checker.isDefEq(
      context.metaContext.instantiate(expected),
      natType,
    )
  ){
    throw new Error(
      "PS_ELAB_NAT_NOTATION_EXPECTED_TYPE: operator '"+expr.operator+
      "' currently supports Nat results only",
    );
  }

  const left=elaborate(expr.left,context,natType);
  const right=elaborate(expr.right,context,natType);
  if(
    !checker.isDefEq(left.type,natType)
    ||!checker.isDefEq(right.type,natType)
  ){
    throw new Error(
      "PS_ELAB_NAT_NOTATION_OPERAND_TYPE: operator '"+expr.operator+
      "' currently supports Nat operands only",
    );
  }

  const term=mkAppN(
    constant(operationName),
    [left.term,right.term],
  );
  const type=checker.check(term);
  if(!checker.isDefEq(type,natType)){
    throw new Error(
      "PS_ELAB_NAT_NOTATION_RESULT: '"+constantName+
      "' did not produce Nat",
    );
  }
  return {term,type};
}
