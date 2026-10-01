import {
  Environment,
  nameKey,
  nameToString,
  type Expr,
} from 'lean-ts-kernel';
import type {VerifiedIrExpr} from '@proofscript/compiler-ir/verified';
import type {ErasureScope} from './model.js';
import {tryEraseRawPosProjection} from './raw-pos-erasure.js';

type RuntimeExprEraser=(
  expr:Expr,
  scope:ErasureScope,
  environment:Environment,
)=>VerifiedIrExpr;

export function eraseRuntimeProjection(
  expr:Extract<Expr,{kind:'proj'}>,
  scope:ErasureScope,
  environment:Environment,
  erase:RuntimeExprEraser,
):VerifiedIrExpr {
  const rawPos=tryEraseRawPosProjection(
    expr,
    scope,
    environment,
    erase,
  );
  if(rawPos!==undefined)return rawPos;

  const structure=scope.structuresByType.get(nameKey(expr.typeName));
  if(structure===undefined){
    throw new Error(
      "PS_ERASE_PROJECTION_STRUCTURE_UNSUPPORTED: '"+
      nameToString(expr.typeName)+"'",
    );
  }
  const field=structure.fields.find(
    (item)=>item.projectionIndex===expr.index,
  );
  if(field===undefined){
    throw new Error(
      "PS_ERASE_PROJECTION_FIELD_UNSUPPORTED: structure '"+
      structure.name+"' field index "+expr.index,
    );
  }
  return {
    kind:'projection',
    target:erase(expr.expr,scope,environment),
    field:field.name,
  };
}
