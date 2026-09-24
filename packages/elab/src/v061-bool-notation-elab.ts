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

function boolType(
  context:V061CoreElabContext,
):Expr {
  return constant(requireV061NotationConstant(context,'Bool'));
}

function requirePrimitiveEqualityOperandType(
  type:Expr,
  context:V061CoreElabContext,
  checker:TypeChecker,
  operator:string,
):{readonly type:Expr;readonly equalityName:string} {
  const natType=constant(requireV061NotationConstant(context,'Nat'));
  const expectedBool=boolType(context);
  if(checker.isDefEq(type,natType)){
    return {type:natType,equalityName:'Nat.beq'};
  }
  if(checker.isDefEq(type,expectedBool)){
    return {type:expectedBool,equalityName:'Bool.beq'};
  }
  throw new Error(
    "PS_ELAB_EQUALITY_OPERAND_TYPE: operator '"+operator+
    "' currently supports Nat or Bool operands",
  );
}

function requireExpectedBool(
  expected:Expr|undefined,
  context:V061CoreElabContext,
  checker:TypeChecker,
  message:string,
):Expr {
  const expectedBool=boolType(context);
  if(
    expected!==undefined
    &&!checker.isDefEq(
      context.metaContext.instantiate(expected),
      expectedBool,
    )
  ){
    throw new Error(message);
  }
  return expectedBool;
}

export function elaborateV061BoolBinaryTerms(
  operator:string,
  left:ElaboratedCoreTerm,
  right:ElaboratedCoreTerm,
  context:V061CoreElabContext,
  expected?:Expr,
):ElaboratedCoreTerm {
  const boolConstant=boolBinary.get(operator);
  if(boolConstant===undefined){
    throw new Error(
      "PS_ELAB_BOOL_NOTATION_OPERATOR: unsupported operator '"+operator+"'",
    );
  }
  const checker=new TypeChecker(
    context.environment,
    context.localContext.clone(),
  );
  const expectedBool=requireExpectedBool(
    expected,
    context,
    checker,
    "PS_ELAB_BOOL_NOTATION_EXPECTED_TYPE: operator '"+operator+
      "' produces Bool",
  );
  if(
    !checker.isDefEq(left.type,expectedBool)
    ||!checker.isDefEq(right.type,expectedBool)
  ){
    throw new Error(
      "PS_ELAB_BOOL_NOTATION_OPERAND_TYPE: operator '"+operator+
      "' requires Bool operands",
    );
  }
  const term=mkAppN(
    constant(requireV061NotationConstant(context,boolConstant)),
    [left.term,right.term],
  );
  const type=checker.check(term);
  if(!checker.isDefEq(type,expectedBool)){
    throw new Error(
      "PS_ELAB_BOOL_NOTATION_RESULT: '"+boolConstant+
      "' did not produce Bool",
    );
  }
  return {term,type};
}

export function elaborateV061PrimitiveBooleanEqualityTerms(
  operator:string,
  left:ElaboratedCoreTerm,
  right:ElaboratedCoreTerm,
  context:V061CoreElabContext,
  expected?:Expr,
):ElaboratedCoreTerm {
  const checker=new TypeChecker(
    context.environment,
    context.localContext.clone(),
  );
  const expectedBool=requireExpectedBool(
    expected,
    context,
    checker,
    "PS_ELAB_EQUALITY_EXPECTED_TYPE: operator '"+operator+
      "' produces Bool",
  );
  const operand=requirePrimitiveEqualityOperandType(
    left.type,
    context,
    checker,
    operator,
  );
  if(!checker.isDefEq(right.type,operand.type)){
    throw new Error(
      "PS_ELAB_EQUALITY_OPERAND_TYPE: operator '"+operator+
      "' requires matching primitive operands",
    );
  }
  const equality=mkAppN(
    constant(requireV061NotationConstant(context,operand.equalityName)),
    [left.term,right.term],
  );
  const equalityType=checker.check(equality);
  if(!checker.isDefEq(equalityType,expectedBool)){
    throw new Error(
      "PS_ELAB_EQUALITY_RESULT: '"+operand.equalityName+
      "' did not produce Bool",
    );
  }
  if(operator==='==')return {term:equality,type:equalityType};
  if(operator==='!='){
    const term=mkAppN(
      constant(requireV061NotationConstant(context,'Bool.not')),
      [equality],
    );
    const type=checker.check(term);
    if(!checker.isDefEq(type,expectedBool)){
      throw new Error(
        "PS_ELAB_INEQUALITY_RESULT: 'Bool.not' did not produce Bool",
      );
    }
    return {term,type};
  }
  throw new Error(
    "PS_ELAB_EQUALITY_OPERATOR: unsupported operator '"+operator+"'",
  );
}

export function elaborateV061BoolNotTerm(
  operand:ElaboratedCoreTerm,
  context:V061CoreElabContext,
  expected?:Expr,
):ElaboratedCoreTerm {
  const checker=new TypeChecker(
    context.environment,
    context.localContext.clone(),
  );
  const expectedBool=requireExpectedBool(
    expected,
    context,
    checker,
    "PS_ELAB_BOOL_NOTATION_EXPECTED_TYPE: operator '!' produces Bool",
  );
  if(!checker.isDefEq(operand.type,expectedBool)){
    throw new Error(
      "PS_ELAB_BOOL_NOTATION_OPERAND_TYPE: operator '!' requires Bool",
    );
  }
  const term=mkAppN(
    constant(requireV061NotationConstant(context,'Bool.not')),
    [operand.term],
  );
  const type=checker.check(term);
  if(!checker.isDefEq(type,expectedBool)){
    throw new Error(
      "PS_ELAB_BOOL_NOTATION_RESULT: 'Bool.not' did not produce Bool",
    );
  }
  return {term,type};
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
  const operand=requirePrimitiveEqualityOperandType(
    left.type,
    context,
    checker,
    expr.operator,
  );
  const right=elaborate(expr.right,context,operand.type);
  return elaborateV061PrimitiveBooleanEqualityTerms(
    expr.operator,
    left,
    right,
    context,
  );
}

export function elaborateV061BoolBinaryNotation(
  expr:Extract<V061Expr,{kind:'binary'}>,
  context:V061CoreElabContext,
  expected:Expr|undefined,
  elaborate:V061TermElaborator,
):ElaboratedCoreTerm {
  const expectedBool=boolType(context);
  const left=elaborate(expr.left,context,expectedBool);
  const right=elaborate(expr.right,context,expectedBool);
  return elaborateV061BoolBinaryTerms(
    expr.operator,
    left,
    right,
    context,
    expected,
  );
}

export function elaborateV061UnaryNotation(
  expr:Extract<V061Expr,{kind:'unary'}>,
  context:V061CoreElabContext,
  expected:Expr|undefined,
  elaborate:V061TermElaborator,
):ElaboratedCoreTerm {
  const operand=elaborate(expr.operand,context,boolType(context));
  return elaborateV061BoolNotTerm(
    operand,
    context,
    expected,
  );
}
