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
  fvar,
} from 'lean-ts-kernel';
import {
  ExprMetaContext,
  type ExprMetavarKind,
} from '@proofscript/meta';
import {trySynthesizeLocalInstance} from './application-instances.js';

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

export interface ApplicationArgument {
  readonly term:Expr;
  readonly type?:Expr;
  readonly allowUnresolvedMVar?:boolean;
}

export interface ApplicationArgumentSource {
  readonly length:number;
  elaborate(index:number,expectedType:Expr):ApplicationArgument;
}

export type ApplicationArguments=
  | readonly Expr[]
  | ApplicationArgumentSource;

export interface ElaborateApplicationOptions {
  readonly environment:Environment;
  readonly metaContext:ExprMetaContext;
  readonly fn:Expr;
  readonly args:ApplicationArguments;
  readonly expectedType?:Expr;
  readonly localContext?:LocalContext;
  readonly localInstances?:readonly Expr[];
  readonly globalInstances?:readonly Expr[]|undefined;
  readonly classNames?:ReadonlySet<string>|undefined;
}

function implicitKind(info:BinderInfo):ExprMetavarKind {
  return info==='instImplicit'?'synthetic':'natural';
}

function isArgumentSource(
  args:ApplicationArguments,
):args is ApplicationArgumentSource {
  return !Array.isArray(args);
}

function hasExprMVar(expr:Expr):boolean {
  const todo:Expr[]=[expr];
  while(todo.length>0){
    const current=todo.pop()!;
    switch(current.kind){
      case 'mvar':
        return true;
      case 'app':
        todo.push(current.fn,current.arg);
        break;
      case 'lam':
      case 'forall':
        todo.push(current.type,current.body);
        break;
      case 'let':
        todo.push(current.type,current.value,current.body);
        break;
      case 'mdata':
      case 'proj':
        todo.push(current.expr);
        break;
      default:
        break;
    }
  }
  return false;
}

function explicitArgument(
  args:ApplicationArguments,
  index:number,
  expectedType:Expr,
):ApplicationArgument {
  if(isArgumentSource(args))return args.elaborate(index,expectedType);
  return {term:args[index]!};
}


function preconstrainRemainingApplicationResult(
  checker:TypeChecker,
  metaContext:ExprMetaContext,
  type:Expr,
  remainingExplicitArgs:number,
  expectedType:Expr,
  localContext:LocalContext,
):void {
  let cursor=type;
  let remaining=remainingExplicitArgs;
  while(true){
    const current=checker.whnf(metaContext.instantiate(cursor));
    if(current.kind!=='forall'){
      try{
        metaContext.unify(
          current,
          metaContext.instantiate(expectedType),
          localContext,
        );
      }catch{
        // This is only an early constraint pass. The ordinary application
        // checks below remain authoritative and will report any real mismatch.
      }
      return;
    }

    if(current.binderInfo==='default'){
      if(remaining===0){
        try{
          metaContext.unify(
            current,
            metaContext.instantiate(expectedType),
            localContext,
          );
        }catch{
          // Defer mismatch reporting to the normal application result check.
        }
        return;
      }
      const placeholder=metaContext.mkFresh(
        metaContext.instantiate(current.type),
        localContext,
        'natural',
      );
      cursor=instantiate1(current.body,placeholder);
      remaining-=1;
      continue;
    }

    if(current.binderInfo==='strictImplicit'&&remaining===0){
      try{
        metaContext.unify(
          current,
          metaContext.instantiate(expectedType),
          localContext,
        );
      }catch{
        // Defer mismatch reporting to the normal application result check.
      }
      return;
    }

    const placeholder=metaContext.mkFresh(
      metaContext.instantiate(current.type),
      localContext,
      implicitKind(current.binderInfo),
    );
    cursor=instantiate1(current.body,placeholder);
  }
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
  if(hasExprMVar(metaContext.instantiate(fn))){
    throw new Error(
      'PS_ELAB_APP_FUNCTION_STUCK: function expression contains unresolved expression metavariables',
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
      const expectedArgumentType=metaContext.instantiate(functionType.type);
      const supplied=explicitArgument(
        args,
        explicitIndex++,
        expectedArgumentType,
      );
      const sourceArg=supplied.term;
      const argument=metaContext.instantiate(sourceArg);

      let actualType:Expr;
      if(hasExprMVar(argument)){
        if(!supplied.allowUnresolvedMVar){
          throw new Error(
            'PS_ELAB_APP_ARGUMENT_STUCK: explicit argument contains unresolved expression metavariables',
          );
        }
        if(supplied.type!==undefined){
          actualType=metaContext.instantiate(supplied.type);
        }else if(argument.kind==='mvar'){
          actualType=metaContext.instantiate(
            metaContext.getDecl(argument).type,
          );
        }else{
          throw new Error(
            'PS_ELAB_APP_ARGUMENT_STUCK: postponed compound argument requires its elaborated type',
          );
        }
      }else{
        actualType=supplied.type===undefined
          ?checker.check(argument)
          :metaContext.instantiate(supplied.type);
      }

      if(
        !metaContext.unify(
          actualType,
          expectedArgumentType,
          localContext,
        )
      ){
        throw new Error(
          'PS_ELAB_APP_TYPE_MISMATCH: expected '+
          exprToString(expectedArgumentType)+
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
    if(expectedType!==undefined){
      preconstrainRemainingApplicationResult(
        checker,
        metaContext,
        type,
        args.length-explicitIndex,
        expectedType,
        localContext,
      );
      term=metaContext.instantiate(term);
      type=metaContext.instantiate(type);
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
