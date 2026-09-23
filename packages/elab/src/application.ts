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
  readonly localContext?:LocalContext;
}

function implicitKind(info:BinderInfo):ExprMetavarKind {
  return info==='instImplicit'?'synthetic':'natural';
}

export function elaborateApplication({
  environment,
  metaContext,
  fn,
  args,
  localContext=new LocalContext(),
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
      pendingInstances.push(implicit);
    }
  }

  return {
    term:metaContext.instantiate(term),
    type:metaContext.instantiate(type),
    inserted,
    pendingInstances,
    consumedExplicitArgs:explicitIndex,
  };
}
