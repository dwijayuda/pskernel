import type {V061TypeExpr} from '@proofscript/syntax';
import {
  type Expr,
  constant,
  forallE,
  fvar,
  levelSucc,
  levelZero,
  nameFromDotted,
  sort,
  TypeChecker,
} from 'lean-ts-kernel';
import type {V061CoreElabContext} from './v061-context.js';

export function elaborateV061Type(
  type:V061TypeExpr,
  context:V061CoreElabContext,
):Expr {
  switch(type.kind){
    case 'group':
      return elaborateV061Type(type.value,context);
    case 'named':{
      if(type.name==='Prop')return sort(levelZero);
      if(type.name==='Type')return sort(levelSucc(levelZero));
      const local=context.locals.get(type.name);
      if(local!==undefined)return fvar(local);
      const name=nameFromDotted(type.name);
      if(context.environment.find(name)===undefined){
        throw new Error("PS_ELAB_UNKNOWN_TYPE: unknown type '"+type.name+"'");
      }
      return constant(name);
    }
    case 'application':
      throw new Error(
        'PS_ELAB_TYPE_APPLICATION_UNSUPPORTED: type applications require dependent application elaboration',
      );
    case 'arrow':{
      const domain=elaborateV061Type(type.domain,context);
      new TypeChecker(context.environment,context.localContext.clone())
        .ensureSort(
          new TypeChecker(context.environment,context.localContext.clone()).check(domain),
          domain,
        );
      const codomain=elaborateV061Type(type.codomain,context);
      return forallE(nameFromDotted('_'),domain,codomain,'default');
    }
  }
}
