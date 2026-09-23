import type {V061TypeExpr} from '@proofscript/syntax';
import {
  type Expr,
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
import {elaborateV061Constant} from './v061-constant-elab.js';
import type {V061CoreElabContext} from './v061-context.js';
import {v061LocalInstanceTerms} from './v061-context.js';

function elaborateTypePositionApplication(
  fn:Expr,
  args:readonly Expr[],
  context:V061CoreElabContext,
):Expr {
  const applied=elaborateApplication({
    environment:context.environment,
    metaContext:context.metaContext,
    fn,
    args,
    localContext:context.localContext,
    localInstances:v061LocalInstanceTerms(context),
    globalInstances:context.globalInstances,
    classNames:context.classes,
  });
  const term=context.metaContext.instantiate(applied.term);
  const resultType=context.metaContext.instantiate(applied.type);
  if(hasMVar(term)||hasMVar(resultType)){
    throw new Error(
      'PS_ELAB_TYPE_APPLICATION_STUCK: unresolved implicit/instance '+
      'arguments in '+exprToString(term),
    );
  }
  return term;
}

function elaborateV061TypePositionTerm(
  syntax:V061TypeExpr,
  context:V061CoreElabContext,
):Expr {
  switch(syntax.kind){
    case 'group':
      return elaborateV061TypePositionTerm(syntax.value,context);
    case 'named':{
      if(syntax.name==='Prop')return sort(levelZero);
      if(syntax.name==='Type')return sort(levelSucc(levelZero));
      const local=context.locals.get(syntax.name);
      if(local!==undefined)return fvar(local);
      const name=nameFromDotted(syntax.name);
      if(context.environment.find(name)===undefined){
        throw new Error(
          "PS_ELAB_UNKNOWN_TYPE_TERM: unknown name '"+syntax.name+"'",
        );
      }
      return elaborateV061Constant(name,context);
    }
    case 'application':
      return elaborateTypePositionApplication(
        elaborateV061TypePositionTerm(syntax.fn,context),
        syntax.args.map(
          (arg)=>elaborateV061TypePositionTerm(arg,context),
        ),
        context,
      );
    case 'equality':
      return elaborateTypePositionApplication(
        elaborateV061Constant(nameFromDotted('Eq'),context),
        [
          elaborateV061TypePositionTerm(syntax.left,context),
          elaborateV061TypePositionTerm(syntax.right,context),
        ],
        context,
      );
    case 'arrow':{
      const domain=elaborateV061Type(syntax.domain,context);
      const codomain=elaborateV061Type(syntax.codomain,context);
      return forallE(
        nameFromDotted('_'),
        domain,
        codomain,
        'default',
      );
    }
  }
}

export function elaborateV061Type(
  syntax:V061TypeExpr,
  context:V061CoreElabContext,
):Expr {
  const term=context.metaContext.instantiate(
    elaborateV061TypePositionTerm(syntax,context),
  );
  if(hasMVar(term)){
    throw new Error(
      'PS_ELAB_TYPE_STUCK: type contains unresolved expression metavariables',
    );
  }
  const checker=new TypeChecker(
    context.environment,
    context.localContext.clone(),
  );
  checker.ensureSort(checker.check(term),term);
  return term;
}
