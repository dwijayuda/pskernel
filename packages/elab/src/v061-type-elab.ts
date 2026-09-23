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
  hasMVar,
  exprToString,
} from 'lean-ts-kernel';
import {elaborateApplication} from './application.js';
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
    case 'application':{
      const fn=elaborateV061Type(type.fn,context);
      const args=type.args.map((arg)=>elaborateV061Type(arg,context));
      const applied=elaborateApplication({
        environment:context.environment,
        metaContext:context.metaContext,
        fn,
        args,
        localContext:context.localContext,
      });
      const term=context.metaContext.instantiate(applied.term);
      const resultType=context.metaContext.instantiate(applied.type);
      if(hasMVar(term)||hasMVar(resultType)){
        throw new Error(
          'PS_ELAB_TYPE_APPLICATION_STUCK: unresolved implicit/instance arguments in '+
          exprToString(term),
        );
      }
      new TypeChecker(context.environment,context.localContext.clone())
        .ensureSort(resultType,term);
      return term;
    }
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
