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

export type V061TermElaborator=(
  expr:V061Expr,
  context:V061CoreElabContext,
  expected?:Expr,
)=>ElaboratedCoreTerm;

const natArithmetic=new Map<string,string>([
  ['+','Nat.add'],
  ['-','Nat.sub'],
  ['*','Nat.mul'],
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

function requireConstant(
  context:V061CoreElabContext,
  name:string,
):ReturnType<typeof nameFromDotted> {
  const parsed=nameFromDotted(name);
  if(context.environment.find(parsed)===undefined){
    throw new Error(
      "PS_ELAB_NAT_ENVIRONMENT: '"+name+
      "' is unavailable in the elaboration environment",
    );
  }
  return parsed;
}

function elaborateNatOperands(
  expr:Extract<V061Expr,{kind:'binary'}>,
  context:V061CoreElabContext,
  elaborate:V061TermElaborator,
){
  const natName=requireConstant(context,'Nat');
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

export interface ElaboratedNatCondition extends ElaboratedCoreTerm {
  readonly decider:Expr;
}

export function elaborateV061NatCondition(
  expr:Extract<V061Expr,{kind:'binary'}>,
  context:V061CoreElabContext,
  elaborate:V061TermElaborator,
):ElaboratedNatCondition {
  const relation=natRelations.get(expr.operator);
  if(relation===undefined){
    throw new Error(
      "PS_ELAB_CONDITION_UNSUPPORTED: operator '"+expr.operator+
      "' is not a supported Nat proposition",
    );
  }
  const {checker,natType,left,right}=elaborateNatOperands(
    expr,
    context,
    elaborate,
  );
  const first=relation.reverse?right.term:left.term;
  const second=relation.reverse?left.term:right.term;

  const relationClass=relation.kind==='le'?'LE.le':'LT.lt';
  const instance=relation.kind==='le'?'instLENat':'instLTNat';
  const deciderName=relation.kind==='le'?'Nat.decLe':'Nat.decLt';
  const term=mkAppN(
    constant(requireConstant(context,relationClass),[levelZero]),
    [
      natType,
      constant(requireConstant(context,instance)),
      first,
      second,
    ],
  );
  const type=checker.check(term);
  const decider=mkAppN(
    constant(requireConstant(context,deciderName)),
    [first,second],
  );
  checker.check(decider);
  return {term,type,decider};
}

export function elaborateV061BinaryNotation(
  expr:Extract<V061Expr,{kind:'binary'}>,
  context:V061CoreElabContext,
  expected:Expr|undefined,
  elaborate:V061TermElaborator,
):ElaboratedCoreTerm {
  if(natRelations.has(expr.operator)){
    const condition=elaborateV061NatCondition(expr,context,elaborate);
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

  const constantName=natArithmetic.get(expr.operator);
  if(constantName===undefined){
    throw new Error(
      "PS_ELAB_NOTATION_UNSUPPORTED: operator '"+expr.operator+
      "' requires Lean-compatible notation/typeclass elaboration",
    );
  }

  const {checker,natType,left,right}=elaborateNatOperands(
    expr,
    context,
    elaborate,
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

  const operationName=requireConstant(context,constantName);
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
