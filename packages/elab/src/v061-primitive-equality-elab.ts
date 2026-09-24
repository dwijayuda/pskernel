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
  requireV061NotationConstant,
  type V061TermElaborator,
} from './v061-notation-support.js';

function boolType(context:V061CoreElabContext):Expr {
  return constant(requireV061NotationConstant(context,'Bool'));
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

function requirePrimitiveEqualityOperandType(
  type:Expr,
  context:V061CoreElabContext,
  checker:TypeChecker,
  operator:string,
):{
  readonly kind:'nat'|'bool'|'char'|'string';
  readonly type:Expr;
  readonly equalityName?:'Nat.beq';
} {
  const natType=constant(requireV061NotationConstant(context,'Nat'));
  const expectedBool=boolType(context);
  if(checker.isDefEq(type,natType)){
    return {kind:'nat',type:natType,equalityName:'Nat.beq'};
  }
  if(checker.isDefEq(type,expectedBool)){
    return {kind:'bool',type:expectedBool};
  }
  const charType=constant(requireV061NotationConstant(context,'Char'));
  if(checker.isDefEq(type,charType)){
    return {kind:'char',type:charType};
  }
  const stringType=constant(requireV061NotationConstant(context,'String'));
  if(checker.isDefEq(type,stringType)){
    return {kind:'string',type:stringType};
  }
  throw new Error(
    "PS_ELAB_EQUALITY_OPERAND_TYPE: operator '"+operator+
    "' currently supports Nat, Bool, Char, or String operands",
  );
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

  let equality:Expr;
  if(operand.kind==='nat'){
    equality=mkAppN(
      constant(requireV061NotationConstant(context,operand.equalityName!)),
      [left.term,right.term],
    );
  }else if(operand.kind==='bool'){
    equality=mkAppN(
      constant(requireV061NotationConstant(context,'Bool.or')),
      [
        mkAppN(
          constant(requireV061NotationConstant(context,'Bool.and')),
          [left.term,right.term],
        ),
        mkAppN(
          constant(requireV061NotationConstant(context,'Bool.and')),
          [
            mkAppN(
              constant(requireV061NotationConstant(context,'Bool.not')),
              [left.term],
            ),
            mkAppN(
              constant(requireV061NotationConstant(context,'Bool.not')),
              [right.term],
            ),
          ],
        ),
      ],
    );
  }else if(operand.kind==='char'){
    const toNat=constant(
      requireV061NotationConstant(context,'Char.toNat'),
    );
    equality=mkAppN(
      constant(requireV061NotationConstant(context,'Nat.beq')),
      [mkAppN(toNat,[left.term]),mkAppN(toNat,[right.term])],
    );
  }else{
    const proposition=mkAppN(
      constant(
        requireV061NotationConstant(context,'Eq'),
        [levelSucc(levelZero)],
      ),
      [operand.type,left.term,right.term],
    );
    const decider=mkAppN(
      constant(requireV061NotationConstant(context,'String.decEq')),
      [left.term,right.term],
    );
    checker.check(decider);
    equality=mkAppN(
      constant(
        requireV061NotationConstant(context,'ite'),
        [checker.getSortLevel(expectedBool)],
      ),
      [
        expectedBool,
        proposition,
        decider,
        constant(requireV061NotationConstant(context,'Bool.true')),
        constant(requireV061NotationConstant(context,'Bool.false')),
      ],
    );
  }

  const equalityType=checker.check(equality);
  if(!checker.isDefEq(equalityType,expectedBool)){
    throw new Error(
      "PS_ELAB_EQUALITY_RESULT: bounded "+operand.kind+
      " equality did not produce Bool",
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
