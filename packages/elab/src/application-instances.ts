import {
  LocalContext,
  TypeChecker,
  appView,
  nameToString,
  type Expr,
} from 'lean-ts-kernel';
import {ExprMetaContext} from '@proofscript/meta';

function targetClassName(
  type:Expr,
  checker:TypeChecker,
):string|undefined {
  const view=appView(checker.whnf(type));
  return view.fn.kind==='const'
    ?nameToString(view.fn.name)
    :undefined;
}

export function trySynthesizeLocalInstance(
  target:Expr,
  candidates:readonly Expr[],
  classNames:ReadonlySet<string>,
  metaContext:ExprMetaContext,
  checker:TypeChecker,
  localContext:LocalContext,
):Expr|undefined {
  const className=targetClassName(
    metaContext.instantiate(target),
    checker,
  );
  if(className===undefined||!classNames.has(className))return undefined;

  for(const candidate of candidates){
    let candidateType:Expr;
    try{
      candidateType=checker.check(candidate);
    }catch{
      continue;
    }
    if(metaContext.unify(candidateType,target,localContext)){
      return candidate;
    }
  }
  return undefined;
}
