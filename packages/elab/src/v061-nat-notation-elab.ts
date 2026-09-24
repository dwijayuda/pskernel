import type {V061Expr} from '@proofscript/syntax';
import {
  TypeChecker,
  constant,
  levelZero,
  mkAppN,
  nameFromDotted,
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

const natArithmetic=new Map<string,string>([
  ['+','Nat.add'],
  ['-','Nat.sub'],
  ['*','Nat.mul'],
  ['/','Nat.div'],
  ['%','Nat.mod'],
]);

const fixedUIntAddition=new Map<string,string>([
  ['UInt8','UInt8.add'],
  ['UInt16','UInt16.add'],
  ['UInt32','UInt32.add'],
  ['UInt64','UInt64.add'],
]);

type NatRelationKind='le'|'lt';
const natRelations=new Map<
  string,
  {readonly kind:NatRelationKind;readonly reverse:boolean}
>([
  ['<=',{kind:'le',reverse:false}],
  ['>=',{kind:'le',reverse:true}],
  ['<',{kind:'lt',reverse:false}],
  ['>',{kind:'lt',reverse:true}],
]);

function elaborateNatOperands(
  expr:Extract<V061Expr,{kind:'binary'}>,
  context:V061CoreElabContext,
  elaborate:V061TermElaborator,
){
  const natName=requireV061NotationConstant(context,'Nat');
  const natType=constant(natName);
  const checker=new TypeChecker(
    context.environment,
    context.localContext.clone(),
  );
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
  return {checker,natType,left,right};
}

export function elaborateV061NatArithmeticTerms(
  operator:string,
  left:ElaboratedCoreTerm,
  right:ElaboratedCoreTerm,
  context:V061CoreElabContext,
  expected?:Expr,
):ElaboratedCoreTerm {
  const constantName=natArithmetic.get(operator);
  if(constantName===undefined){
    throw new Error(
      "PS_ELAB_NOTATION_UNSUPPORTED: operator '"+operator+
      "' requires Lean-compatible notation/typeclass elaboration",
    );
  }
  const natType=constant(requireV061NotationConstant(context,'Nat'));
  const checker=new TypeChecker(
    context.environment,
    context.localContext.clone(),
  );
  if(
    !checker.isDefEq(left.type,natType)
    ||!checker.isDefEq(right.type,natType)
  ){
    throw new Error(
      "PS_ELAB_NAT_NOTATION_OPERAND_TYPE: operator '"+operator+
      "' currently supports Nat operands only",
    );
  }
  if(
    expected!==undefined
    &&!checker.isDefEq(
      context.metaContext.instantiate(expected),
      natType,
    )
  ){
    throw new Error(
      "PS_ELAB_NAT_NOTATION_EXPECTED_TYPE: operator '"+operator+
      "' currently supports Nat results only",
    );
  }
  const term=mkAppN(
    constant(requireV061NotationConstant(context,constantName)),
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

export function elaborateV061NatArithmeticExpression(
  expr:Extract<V061Expr,{kind:'binary'}>,
  context:V061CoreElabContext,
  expected:Expr|undefined,
  elaborate:V061TermElaborator,
):ElaboratedCoreTerm {
  if(expr.operator==='+'&&expected!==undefined){
    const checker=new TypeChecker(
      context.environment,
      context.localContext.clone(),
    );
    const expectedType=context.metaContext.instantiate(expected);
    for(const [typeName,constantName] of fixedUIntAddition){
      const runtimeName=nameFromDotted(typeName);
      if(context.environment.find(runtimeName)===undefined)continue;
      const runtimeType=constant(runtimeName);
      if(!checker.isDefEq(expectedType,runtimeType))continue;
      const left=elaborate(expr.left,context,runtimeType);
      const right=elaborate(expr.right,context,runtimeType);
      if(
        !checker.isDefEq(left.type,runtimeType)
        ||!checker.isDefEq(right.type,runtimeType)
      ){
        throw new Error(
          "PS_ELAB_UINT_ADD_OPERAND_TYPE: operator '+' at "+typeName+
          ' requires matching fixed-width operands',
        );
      }
      const term=mkAppN(
        constant(
          requireV061NotationConstant(context,constantName),
        ),
        [left.term,right.term],
      );
      const type=checker.check(term);
      if(!checker.isDefEq(type,runtimeType)){
        throw new Error(
          "PS_ELAB_UINT_ADD_RESULT: '"+constantName+
          "' did not produce "+typeName,
        );
      }
      return {term,type};
    }
  }

  const {left,right}=elaborateNatOperands(expr,context,elaborate);
  return elaborateV061NatArithmeticTerms(
    expr.operator,
    left,
    right,
    context,
    expected,
  );
}

export interface ElaboratedNatRelation extends ElaboratedCoreTerm {
  readonly first:Expr;
  readonly second:Expr;
  readonly deciderName:string;
}

export interface ElaboratedNatCondition extends ElaboratedNatRelation {
  readonly decider:Expr;
}

export function isV061NatRelation(operator:string):boolean {
  return natRelations.has(operator);
}

export function elaborateV061NatRelationTerms(
  operator:string,
  left:ElaboratedCoreTerm,
  right:ElaboratedCoreTerm,
  context:V061CoreElabContext,
):ElaboratedNatRelation {
  const relation=natRelations.get(operator);
  if(relation===undefined){
    throw new Error(
      "PS_ELAB_CONDITION_UNSUPPORTED: operator '"+operator+
      "' is not a supported Nat proposition relation",
    );
  }
  const natType=constant(requireV061NotationConstant(context,'Nat'));
  const checker=new TypeChecker(
    context.environment,
    context.localContext.clone(),
  );
  if(
    !checker.isDefEq(left.type,natType)
    ||!checker.isDefEq(right.type,natType)
  ){
    throw new Error(
      "PS_ELAB_NAT_NOTATION_OPERAND_TYPE: operator '"+operator+
      "' currently supports Nat operands only",
    );
  }
  const first=relation.reverse?right.term:left.term;
  const second=relation.reverse?left.term:right.term;
  const relationClass=relation.kind==='le'?'LE.le':'LT.lt';
  const instance=relation.kind==='le'?'instLENat':'instLTNat';
  const deciderName=relation.kind==='le'?'Nat.decLe':'Nat.decLt';
  const term=mkAppN(
    constant(
      requireV061NotationConstant(context,relationClass),
      [levelZero],
    ),
    [
      natType,
      constant(requireV061NotationConstant(context,instance)),
      first,
      second,
    ],
  );
  return {
    term,
    type:checker.check(term),
    first,
    second,
    deciderName,
  };
}

export function elaborateV061NatCondition(
  expr:Extract<V061Expr,{kind:'binary'}>,
  context:V061CoreElabContext,
  elaborate:V061TermElaborator,
):ElaboratedNatCondition {
  const {left,right}=elaborateNatOperands(expr,context,elaborate);
  const relation=elaborateV061NatRelationTerms(
    expr.operator,
    left,
    right,
    context,
  );
  const checker=new TypeChecker(
    context.environment,
    context.localContext.clone(),
  );
  const decider=mkAppN(
    constant(requireV061NotationConstant(context,relation.deciderName)),
    [relation.first,relation.second],
  );
  checker.check(decider);
  return {...relation,decider};
}
