import {
  Environment,
  LocalContext,
  TypeChecker,
  type BinderInfo,
  type Expr,
  app,
  exprToString,
  hasMVar,
  instantiate1,
  appView,
  fvar,
  nameToString,
} from 'lean-ts-kernel';
import {
  ExprMetaContext,
  type ExprMetavarKind,
} from '@proofscript/meta';

export interface InsertedApplicationArgument {
  readonly binderInfo:BinderInfo;
  readonly argument:Expr;
}

export interface ElaboratedApplication {
  readonly term:Expr;
  readonly type:Expr;
  readonly inserted:readonly InsertedApplicationArgument[];
  readonly pendingInstances:readonly Expr[];
  readonly consumedExplicitArgs:number;
}

export interface ElaborateApplicationOptions {
  readonly environment:Environment;
  readonly metaContext:ExprMetaContext;
  readonly fn:Expr;
  readonly args:readonly Expr[];
  readonly expectedType?:Expr;
  readonly localContext?:LocalContext;
  readonly localInstances?:readonly Expr[];
  readonly globalInstances?:readonly Expr[];
  readonly classNames?:ReadonlySet<string>;
}

function implicitKind(info:BinderInfo):ExprMetavarKind {
  return info==='instImplicit'?'synthetic':'natural';
}

function targetClassName(
  type:Expr,
  checker:TypeChecker,
):string|undefined {
  const view=appView(checker.whnf(type));
  return view.fn.kind==='const'
    ?nameToString(view.fn.name)
    :undefined;
}

function trySynthesizeLocalInstance(
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

export function elaborateApplication({
  environment,
  metaContext,
  fn,
  args,
  expectedType,
  localContext=new LocalContext(),
  localInstances=[],
  globalInstances=[],
  classNames=new Set(),
}:ElaborateApplicationOptions):ElaboratedApplication {
  const checker=new TypeChecker(environment,localContext.clone());
  if(hasMVar(metaContext.instantiate(fn))){
    throw new Error(
      'PS_ELAB_APP_FUNCTION_STUCK: function expression contains unresolved metavariables',
    );
  }

  let term=fn;
  let type=checker.check(metaContext.instantiate(fn));
  let explicitIndex=0;
  const inserted:InsertedApplicationArgument[]=[];
  const pendingInstances:Expr[]=[];

  while(true){
    const instantiatedType=metaContext.instantiate(type);
    const functionType=checker.whnf(instantiatedType);

    if(functionType.kind!=='forall'){
      if(explicitIndex<args.length){
        throw new Error(
          'PS_ELAB_APP_EXTRA_ARGUMENT: expression of type '+
          exprToString(instantiatedType)+' is not a function',
        );
      }
      break;
    }

    if(functionType.binderInfo==='default'){
      if(explicitIndex>=args.length)break;
      const sourceArg=args[explicitIndex++]!;
      const argument=metaContext.instantiate(sourceArg);
      if(hasMVar(argument)){
        throw new Error(
          'PS_ELAB_APP_ARGUMENT_STUCK: explicit argument contains unresolved metavariables',
        );
      }

      const actualType=checker.check(argument);
      const expectedType=metaContext.instantiate(functionType.type);
      if(!metaContext.unify(actualType,expectedType,localContext)){
        throw new Error(
          'PS_ELAB_APP_TYPE_MISMATCH: expected '+exprToString(expectedType)+
          ', got '+exprToString(actualType),
        );
      }

      term=app(term,sourceArg);
      type=instantiate1(functionType.body,sourceArg);
      continue;
    }

    if(
      functionType.binderInfo==='strictImplicit'
      &&explicitIndex>=args.length
    )break;

    const expectedType=metaContext.instantiate(functionType.type);
    const implicit=metaContext.mkFresh(
      expectedType,
      localContext,
      implicitKind(functionType.binderInfo),
    );
    term=app(term,implicit);
    type=instantiate1(functionType.body,implicit);
    inserted.push({
      binderInfo:functionType.binderInfo,
      argument:implicit,
    });
    if(functionType.binderInfo==='instImplicit'){
      const target=metaContext.instantiate(expectedType);
      const synthesized=hasMVar(target)
        ?undefined
        :trySynthesizeLocalInstance(
          target,
          [...localInstances,...globalInstances],
          classNames,
          metaContext,
          checker,
          localContext,
        );
      if(synthesized===undefined){
        pendingInstances.push(implicit);
      }else{
        metaContext.assign(implicit,synthesized);
        term=metaContext.instantiate(term);
        type=metaContext.instantiate(type);
      }
    }
  }

  if(expectedType!==undefined){
    const actual=metaContext.instantiate(type);
    const expected=metaContext.instantiate(expectedType);
    if(!metaContext.unify(actual,expected,localContext)){
      throw new Error(
        'PS_ELAB_APP_RESULT_TYPE_MISMATCH: expected '+
        exprToString(expected)+', got '+exprToString(actual),
      );
    }
  }

  const unresolvedInstances:Expr[]=[];
  for(const pending of pendingInstances){
    if(metaContext.isAssigned(pending))continue;
    const target=metaContext.instantiate(
      metaContext.getDecl(pending).type,
    );
    if(hasMVar(target)){
      unresolvedInstances.push(pending);
      continue;
    }
    const synthesized=trySynthesizeLocalInstance(
      target,
      [...localInstances,...globalInstances],
      classNames,
      metaContext,
      checker,
      localContext,
    );
    if(synthesized===undefined){
      unresolvedInstances.push(pending);
      continue;
    }
    metaContext.assign(pending,synthesized);
  }

  return {
    term:metaContext.instantiate(term),
    type:metaContext.instantiate(type),
    inserted,
    pendingInstances:unresolvedInstances,
    consumedExplicitArgs:explicitIndex,
  };
}
