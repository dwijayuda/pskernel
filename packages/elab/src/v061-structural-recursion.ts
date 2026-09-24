import type {V061Expr,V061ValueDeclaration} from '@proofscript/syntax';
import {
  TypeChecker,
  fvar,
  type Expr,
} from 'lean-ts-kernel';
import type {
  ElaboratedCoreTerm,
  V061CoreElabContext,
} from './v061-context.js';


export function withStructuralRecursionContext(
  source:V061ValueDeclaration,
  context:V061CoreElabContext,
):V061CoreElabContext {
  if(source.kind==='theorem'||source.body.kind!=='match')return context;
  const body=source.body;
  if(body.scrutinee.kind!=='reference')return context;
  const scrutineeName=body.scrutinee.name;

  const explicit=source.params.filter(
    (parameter)=>(parameter.binderInfo??'default')==='default',
  );
  const recursiveParameterIndex=explicit.findIndex(
    (parameter)=>parameter.name===scrutineeName,
  );
  if(recursiveParameterIndex<0)return context;

  const explicitParameterIds=explicit.map((parameter)=>{
    const id=context.locals.get(parameter.name);
    if(id===undefined){
      throw new Error(
        "PS_ELAB_STRUCTURAL_RECURSION_INTERNAL: missing parameter local '"+
        parameter.name+"'",
      );
    }
    return id;
  });

  return {
    ...context,
    structuralRecursion:{
      functionName:source.name,
      calls:new Map(),
      explicitParameterIds,
      recursiveParameterIndex,
    },
  };
}

function structuralArgumentName(expr:V061Expr):string|undefined {
  if(expr.kind==='reference')return expr.name;
  if(expr.kind==='group')return structuralArgumentName(expr.value);
  return undefined;
}

export function tryElaborateStructuralSelfCall(
  expr:Extract<V061Expr,{kind:'call'}>,
  context:V061CoreElabContext,
  expected:Expr|undefined,
):ElaboratedCoreTerm|undefined {
  const recursion=context.structuralRecursion;
  if(recursion===undefined||expr.callee!==recursion.functionName){
    return undefined;
  }
  if(expr.args.length!==recursion.explicitParameterIds.length){
    throw new Error(
      'PS_ELAB_STRUCTURAL_RECURSION_ARITY: recursive call must pass every explicit parameter exactly once',
    );
  }

  let ihId:string|undefined;
  for(let index=0;index<expr.args.length;index+=1){
    const argumentName=structuralArgumentName(expr.args[index]!);
    const argumentId=argumentName===undefined
      ?undefined
      :context.locals.get(argumentName);

    if(index===recursion.recursiveParameterIndex){
      ihId=argumentId===undefined
        ?undefined
        :recursion.calls.get(argumentId);
      if(ihId===undefined){
        throw new Error(
          'PS_ELAB_STRUCTURAL_RECURSION_NOT_DECREASING: recursive argument '+
          index+' must be a directly bound recursive field',
        );
      }
      continue;
    }

    if(argumentId!==recursion.explicitParameterIds[index]){
      throw new Error(
        'PS_ELAB_STRUCTURAL_RECURSION_INVARIANT_ARGUMENT: explicit argument '+
        index+' must be passed unchanged in a recursive call',
      );
    }
  }
  if(ihId===undefined){
    throw new Error(
      'PS_ELAB_STRUCTURAL_RECURSION_INTERNAL: decreasing induction hypothesis missing',
    );
  }

  const checker=new TypeChecker(
    context.environment,
    context.localContext.clone(),
  );
  const term=fvar(ihId);
  const type=checker.check(term);
  if(
    expected!==undefined
    &&!checker.isDefEq(
      context.metaContext.instantiate(type),
      context.metaContext.instantiate(expected),
    )
  ){
    throw new Error(
      'PS_ELAB_STRUCTURAL_RECURSION_RESULT: induction hypothesis does not match expected result type',
    );
  }
  return {term,type};
}
