import {
  Environment,
  appView,
  exprEq,
  nameToString,
  type Expr,
} from 'lean-ts-kernel';
import type {VerifiedIrExpr} from '@proofscript/compiler-ir/verified';
import type {ErasureScope} from './model.js';

import {tryEraseTextPrimitiveApplication} from './text-primitive-erasure.js';
import {tryEraseCheckedControlApplication} from './condition-erasure.js';
import {tryEraseArrayPrimitiveApplication} from './array-primitive-erasure.js';

type RuntimeExprEraser=(
  expr:Expr,
  scope:ErasureScope,
  environment:Environment,
)=>VerifiedIrExpr;

const natIntrinsics=new Map<
  string,
  'nat.add'|'nat.sub'|'nat.mul'|'nat.div'|'nat.mod'|'nat.eq'
>([
  ['Nat.add','nat.add'],
  ['Nat.sub','nat.sub'],
  ['Nat.mul','nat.mul'],
  ['Nat.div','nat.div'],
  ['Nat.mod','nat.mod'],
  ['Nat.beq','nat.eq'],
]);

function namedApplication(
  expr:Expr,
  name:string,
  arity:number,
):ReturnType<typeof appView>|undefined {
  const view=appView(expr);
  return view.fn.kind==='const'
    &&nameToString(view.fn.name)===name
    &&view.args.length===arity
    ?view
    :undefined;
}

function synthesizedBoolEqualityOperands(
  expr:Expr,
):readonly [Expr,Expr]|undefined {
  const disjunction=namedApplication(expr,'Bool.or',2);
  if(disjunction===undefined)return undefined;
  const direct=namedApplication(disjunction.args[0]!,'Bool.and',2);
  const negated=namedApplication(disjunction.args[1]!,'Bool.and',2);
  if(direct===undefined||negated===undefined)return undefined;
  const leftNot=namedApplication(negated.args[0]!,'Bool.not',1);
  const rightNot=namedApplication(negated.args[1]!,'Bool.not',1);
  if(leftNot===undefined||rightNot===undefined)return undefined;
  if(
    !exprEq(direct.args[0]!,leftNot.args[0]!)
    ||!exprEq(direct.args[1]!,rightNot.args[0]!)
  )return undefined;
  return [direct.args[0]!,direct.args[1]!];
}

export function tryErasePrimitiveRuntimeApplication(
  expr:Extract<Expr,{kind:'app'}>,
  scope:ErasureScope,
  environment:Environment,
  erase:RuntimeExprEraser,
):VerifiedIrExpr|undefined {
  const view=appView(expr);
  const control=tryEraseCheckedControlApplication(
    expr,
    scope,
    environment,
    erase,
  );
  if(control!==undefined)return control;

  if(
    view.fn.kind==='const'
    &&nameToString(view.fn.name)==='Char.ofNat'
  ){
    if(view.args.length!==1){
      throw new Error(
        "PS_ERASE_INTRINSIC_ARITY: 'char.ofNat' expects one argument",
      );
    }
    return {
      kind:'intrinsic',
      operation:'char.ofNat',
      args:[erase(view.args[0]!,scope,environment)],
    };
  }

  const textPrimitive=tryEraseTextPrimitiveApplication(
    expr,
    scope,
    environment,
    erase,
  );
  if(textPrimitive!==undefined)return textPrimitive;

  const arrayPrimitive=tryEraseArrayPrimitiveApplication(
    expr,
    scope,
    environment,
    erase,
  );
  if(arrayPrimitive!==undefined)return arrayPrimitive;

  if(
    view.fn.kind==='const'
    &&nameToString(view.fn.name)==='Bool.not'
    &&view.args.length===1
  ){
    const equality=appView(view.args[0]!);
    if(
      equality.fn.kind==='const'
      &&nameToString(equality.fn.name)==='Nat.beq'
      &&equality.args.length===2
    ){
      return {
        kind:'intrinsic',
        operation:'nat.ne',
        args:equality.args.map((arg)=>erase(arg,scope,environment)),
      };
    }
    const boolEquality=synthesizedBoolEqualityOperands(view.args[0]!);
    if(boolEquality!==undefined){
      return {
        kind:'intrinsic',
        operation:'bool.ne',
        args:boolEquality.map((arg)=>erase(arg,scope,environment)),
      };
    }
    return {
      kind:'intrinsic',
      operation:'bool.not',
      args:[erase(view.args[0]!,scope,environment)],
    };
  }

  const boolEquality=synthesizedBoolEqualityOperands(expr);
  if(boolEquality!==undefined){
    return {
      kind:'intrinsic',
      operation:'bool.eq',
      args:boolEquality.map((arg)=>erase(arg,scope,environment)),
    };
  }

  if(
    view.fn.kind==='const'
    &&(nameToString(view.fn.name)==='Bool.and'
      ||nameToString(view.fn.name)==='Bool.or')
    &&view.args.length===2
  ){
    return {
      kind:'intrinsic',
      operation:nameToString(view.fn.name)==='Bool.and'
        ?'bool.and'
        :'bool.or',
      args:view.args.map((arg)=>erase(arg,scope,environment)),
    };
  }

  if(view.fn.kind==='const'){
    const intrinsic=natIntrinsics.get(nameToString(view.fn.name));
    if(intrinsic!==undefined){
      if(view.args.length!==2){
        throw new Error(
          "PS_ERASE_INTRINSIC_ARITY: '"+intrinsic+
          "' expects two arguments",
        );
      }
      return {
        kind:'intrinsic',
        operation:intrinsic,
        args:view.args.map((arg)=>erase(arg,scope,environment)),
      };
    }
  }
  return undefined;
}
