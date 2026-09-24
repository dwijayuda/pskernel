import {
  Environment,
  appView,
  nameToString,
  type Expr,
} from 'lean-ts-kernel';
import type {VerifiedIrExpr} from '@proofscript/compiler-ir/verified';
import type {ErasureScope} from './model.js';

type RuntimeExprEraser=(
  expr:Expr,
  scope:ErasureScope,
  environment:Environment,
)=>VerifiedIrExpr;

export function tryEraseRawPosApplication(
  expr:Extract<Expr,{kind:'app'}>,
  scope:ErasureScope,
  environment:Environment,
  erase:RuntimeExprEraser,
):VerifiedIrExpr|undefined {
  const view=appView(expr);
  if(view.fn.kind!=='const')return undefined;
  const name=nameToString(view.fn.name);
  if(
    name!=='String.Pos.Raw.mk'
    &&name!=='String.Pos.Raw.byteIdx'
  )return undefined;
  if(view.args.length!==1){
    throw new Error(
      'PS_ERASE_RAW_POS_ABI_ARITY: expected one byte-index payload',
    );
  }
  return erase(view.args[0]!,scope,environment);
}

export function tryEraseRawPosProjection(
  expr:Extract<Expr,{kind:'proj'}>,
  scope:ErasureScope,
  environment:Environment,
  erase:RuntimeExprEraser,
):VerifiedIrExpr|undefined {
  if(
    nameToString(expr.typeName)!=='String.Pos.Raw'
    ||expr.index!==0
  )return undefined;
  return erase(expr.expr,scope,environment);
}
