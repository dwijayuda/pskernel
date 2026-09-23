import type {V061Expr} from '@proofscript/syntax';
import {
  TypeChecker,
  constant,
  levelSucc,
  levelZero,
  mkAppN,
  type Expr,
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
  requireV061NotationConstant,
  type V061TermElaborator,
} from './v061-notation-support.js';

export type {V061TermElaborator} from './v061-notation-support.js';

const boolBinary=new Map<string,string>([
  ['&&','Bool.and'],
  ['||','Bool.or'],
]);

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

function elaboratePrimitiveBooleanEquality(
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

export function elaborateV061Condition(
  expr:V061Expr,
  context:V061CoreElabContext,
  elaborate:V061TermElaborator,
):ElaboratedNatCondition {
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

export function elaborateV061BinaryNotation(
  expr:Extract<V061Expr,{kind:'binary'}>,
  context:V061CoreElabContext,
  expected:Expr|undefined,
  elaborate:V061TermElaborator,
):ElaboratedCoreTerm {
  const boolConstant=boolBinary.get(expr.operator);
  if(boolConstant!==undefined){
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

  if(expr.operator==='=='||expr.operator==='!='){
    const equality=elaboratePrimitiveBooleanEquality(
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
