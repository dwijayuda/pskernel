import {
  constant,
  type Expr,
  type Name,
  nameToString,
} from 'lean-ts-kernel';
import type {V061CoreElabContext} from './v061-context.js';

export function elaborateV061Constant(
  name:Name,
  context:V061CoreElabContext,
):Expr {
  const info=context.environment.find(name);
  if(info===undefined){
    throw new Error("PS_ELAB_UNKNOWN_CONSTANT: '"+nameToString(name)+"'");
  }
  return constant(
    name,
    info.levelParams.map(()=>context.metaContext.mkFreshLevel()),
  );
}
