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

const textIntrinsics=new Map<
  string,
  {
    readonly operation:
      |'char.toNat'
      |'string.push'
      |'string.singleton'
      |'string.length'
      |'string.append';
    readonly arity:1|2;
  }
>([
  ['Char.toNat',{operation:'char.toNat',arity:1}],
  ['String.push',{operation:'string.push',arity:2}],
  ['String.singleton',{operation:'string.singleton',arity:1}],
  ['String.Internal.length',{operation:'string.length',arity:1}],
  ['String.Internal.append',{operation:'string.append',arity:2}],
]);

export function tryEraseTextPrimitiveApplication(
  expr:Extract<Expr,{kind:'app'}>,
  scope:ErasureScope,
  environment:Environment,
  erase:RuntimeExprEraser,
):VerifiedIrExpr|undefined {
  const view=appView(expr);
  if(view.fn.kind!=='const')return undefined;
  const intrinsic=textIntrinsics.get(nameToString(view.fn.name));
  if(intrinsic===undefined)return undefined;
  if(view.args.length!==intrinsic.arity){
    throw new Error(
      "PS_ERASE_INTRINSIC_ARITY: '"+intrinsic.operation+
      "' expects "+intrinsic.arity+" argument"+
      (intrinsic.arity===1?'':'s'),
    );
  }
  return {
    kind:'intrinsic',
    operation:intrinsic.operation,
    args:view.args.map((arg)=>erase(arg,scope,environment)),
  };
}
