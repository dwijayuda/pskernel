import {
  Environment,
  LocalContext,
  type Expr,
} from 'lean-ts-kernel';
import type {CheckedCoreStructure} from '@proofscript/checked-core';
import {ExprMetaContext} from '@proofscript/meta';

export interface V061CoreElabContext {
  readonly environment:Environment;
  readonly localContext:LocalContext;
  readonly locals:ReadonlyMap<string,string>;
  readonly metaContext:ExprMetaContext;
  readonly structures:ReadonlyMap<string,CheckedCoreStructure>;
}

export function withLocalName(
  context:V061CoreElabContext,
  name:string,
  id:string,
):V061CoreElabContext {
  const locals=new Map(context.locals);
  locals.set(name,id);
  return {...context,locals};
}

export interface ElaboratedCoreTerm {
  readonly term:Expr;
  readonly type:Expr;
}
