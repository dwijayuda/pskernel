import type {V061Expr} from '@proofscript/syntax';
import {
  TypeChecker,
  constant,
  mkAppN,
  type Expr,
} from 'lean-ts-kernel';
import type {
  ElaboratedCoreTerm,
  V061CoreElabContext,
} from './v061-context.js';
import {
  requireV061NotationConstant,
  type V061TermElaborator,
} from './v061-notation-support.js';

const boolBinary=new Map<string,string>([
  ['&&','Bool.and'],
  ['||','Bool.or'],
]);

export function isV061BoolBinary(operator:string):boolean {
  return boolBinary.has(operator);
}

function elaborateBoolOperands(
  expr:Extract<V061Expr,{kind:'binary'}>,
  context:V061CoreElabContext,
  elaborate:V061TermElaborator,
){
  const boolType=constant(requireV061NotationConstant(context,'Bool'));
  const checker=new TypeChecker(
    context.environment,
    context.localContext.clone(),
  );
  const left=elaborate(expr.left,context,boolType);
  const right=elaborate(expr.right,context,boolType);
  if(
    !checker.isDefEq(left.type,boolType)
    ||!checker.isDefEq(right.type,boolType)
  ){
    throw new Error(
      "PS_ELAB_BOOL_NOTATION_OPERAND_TYPE: operator '"+expr.operator+
      "' requires Bool operands",
    );
  }
  return {checker,boolType,left,right};
}

export function elaborateV061PrimitiveBooleanEquality(
  expr:Extract<V061Expr,{kind:'binary'}>,
  context:V061CoreElabContext,
  elaborate:V061TermElaborator,
):ElaboratedCoreTerm {
  const checker=new TypeChecker(
    context.environment,
    context.localContext.clone(),
  );
  const left=elaborate(expr.left,context);
  const natType=constant(requireV061NotationConstant(context,'Nat'));
  const boolType=constant(requireV061NotationConstant(context,'Bool'));
  let operandType:Expr;
  let equalityName:string;
  if(checker.isDefEq(left.type,natType)){
    operandType=natType;
    equalityName='Nat.beq';
  }else if(checker.isDefEq(left.type,boolType)){
    operandType=boolType;
    equalityName='Bool.beq';
  }else{
    throw new Error(
      "PS_ELAB_EQUALITY_OPERAND_TYPE: operator '"+expr.operator+
      "' currently supports Nat or Bool operands",
    );
  }
  const right=elaborate(expr.right,context,operandType);
  if(!checker.isDefEq(right.type,operandType)){
    throw new Error(
      "PS_ELAB_EQUALITY_OPERAND_TYPE: operator '"+expr.operator+
      "' requires matching primitive operands",
    );
  }
  const equality=mkAppN(
    constant(requireV061NotationConstant(context,equalityName)),
    [left.term,right.term],
  );
  const equalityType=checker.check(equality);
  if(!checker.isDefEq(equalityType,boolType)){
    throw new Error(
      "PS_ELAB_EQUALITY_RESULT: '"+equalityName+"' did not produce Bool",
    );
  }
  if(expr.operator==='=='){
    return {term:equality,type:equalityType};
  }
  if(expr.operator==='!='){
    const term=mkAppN(
      constant(requireV061NotationConstant(context,'Bool.not')),
      [equality],
    );
    const type=checker.check(term);
    if(!checker.isDefEq(type,boolType)){
      throw new Error(
        "PS_ELAB_INEQUALITY_RESULT: 'Bool.not' did not produce Bool",
      );
    }
    return {term,type};
  }
  throw new Error(
    "PS_ELAB_EQUALITY_OPERATOR: unsupported operator '"+expr.operator+"'",
  );
}

export function elaborateV061BoolBinaryNotation(
  expr:Extract<V061Expr,{kind:'binary'}>,
  context:V061CoreElabContext,
  expected:Expr|undefined,
  elaborate:V061TermElaborator,
):ElaboratedCoreTerm {
  const boolConstant=boolBinary.get(expr.operator);
  if(boolConstant===undefined){
    throw new Error(
      "PS_ELAB_BOOL_NOTATION_OPERATOR: unsupported operator '"+expr.operator+"'",
    );
  }
  const {checker,boolType,left,right}=elaborateBoolOperands(
    expr,
    context,
    elaborate,
  );
  if(
    expected!==undefined
    &&!checker.isDefEq(
      context.metaContext.instantiate(expected),
      boolType,
    )
  ){
    throw new Error(
      "PS_ELAB_BOOL_NOTATION_EXPECTED_TYPE: operator '"+expr.operator+
      "' produces Bool",
    );
  }
  const term=mkAppN(
    constant(requireV061NotationConstant(context,boolConstant)),
    [left.term,right.term],
  );
  const type=checker.check(term);
  if(!checker.isDefEq(type,boolType)){
    throw new Error(
      "PS_ELAB_BOOL_NOTATION_RESULT: '"+boolConstant+
      "' did not produce Bool",
    );
  }
  return {term,type};
}

export function elaborateV061UnaryNotation(
  expr:Extract<V061Expr,{kind:'unary'}>,
  context:V061CoreElabContext,
  expected:Expr|undefined,
  elaborate:V061TermElaborator,
):ElaboratedCoreTerm {
  const boolType=constant(requireV061NotationConstant(context,'Bool'));
  const checker=new TypeChecker(
    context.environment,
    context.localContext.clone(),
  );
  const operand=elaborate(expr.operand,context,boolType);
  if(!checker.isDefEq(operand.type,boolType)){
    throw new Error(
      "PS_ELAB_BOOL_NOTATION_OPERAND_TYPE: operator '!' requires Bool",
    );
  }
  if(
    expected!==undefined
    &&!checker.isDefEq(
      context.metaContext.instantiate(expected),
      boolType,
    )
  ){
    throw new Error(
      "PS_ELAB_BOOL_NOTATION_EXPECTED_TYPE: operator '!' produces Bool",
    );
  }
  const term=mkAppN(
    constant(requireV061NotationConstant(context,'Bool.not')),
    [operand.term],
  );
  const type=checker.check(term);
  if(!checker.isDefEq(type,boolType)){
    throw new Error(
      "PS_ELAB_BOOL_NOTATION_RESULT: 'Bool.not' did not produce Bool",
    );
  }
  return {term,type};
}
