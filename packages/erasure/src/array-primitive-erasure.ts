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

interface ArrayPrimitiveSpec {
  readonly operation:
    |'array.emptyWithCapacity'
    |'array.size'
    |'array.push'
    |'array.get'
    |'array.getD'
    |'array.set'
    |'array.setIfInBounds'
    |'array.map'
    |'array.foldl';
  readonly totalArity:number;
  readonly runtimeIndices:readonly number[];
}

const ARRAY_PRIMITIVES=new Map<string,ArrayPrimitiveSpec>([
  [
    'Array.emptyWithCapacity',
    {
      operation:'array.emptyWithCapacity',
      totalArity:2,
      runtimeIndices:[1],
    },
  ],
  [
    'Array.size',
    {
      operation:'array.size',
      totalArity:2,
      runtimeIndices:[1],
    },
  ],
  [
    'Array.push',
    {
      operation:'array.push',
      totalArity:3,
      runtimeIndices:[1,2],
    },
  ],
  [
    'Array.getInternal',
    {
      operation:'array.get',
      totalArity:4,
      runtimeIndices:[1,2],
    },
  ],
  [
    'Array.getD',
    {
      operation:'array.getD',
      totalArity:4,
      runtimeIndices:[1,2,3],
    },
  ],
  [
    'Array.set',
    {
      operation:'array.set',
      totalArity:5,
      runtimeIndices:[1,2,3],
    },
  ],
  [
    'Array.setIfInBounds',
    {
      operation:'array.setIfInBounds',
      totalArity:4,
      runtimeIndices:[1,2,3],
    },
  ],
  [
    'Array.map',
    {
      operation:'array.map',
      totalArity:4,
      runtimeIndices:[2,3],
    },
  ],
  [
    'Array.foldl',
    {
      operation:'array.foldl',
      totalArity:7,
      runtimeIndices:[2,3,4,5,6],
    },
  ],
]);

export function tryEraseArrayPrimitiveApplication(
  expr:Extract<Expr,{kind:'app'}>,
  scope:ErasureScope,
  environment:Environment,
  erase:RuntimeExprEraser,
):VerifiedIrExpr|undefined {
  const view=appView(expr);
  if(view.fn.kind!=='const')return undefined;
  const name=nameToString(view.fn.name);
  const spec=ARRAY_PRIMITIVES.get(name);
  if(spec===undefined)return undefined;
  if(view.args.length!==spec.totalArity){
    throw new Error(
      "PS_ERASE_ARRAY_INTRINSIC_ARITY: '"+name+"' expected "+
      spec.totalArity+' checked arguments, got '+view.args.length,
    );
  }
  return {
    kind:'intrinsic',
    operation:spec.operation,
    args:spec.runtimeIndices.map(
      (index)=>erase(view.args[index]!,scope,environment),
    ),
  };
}
