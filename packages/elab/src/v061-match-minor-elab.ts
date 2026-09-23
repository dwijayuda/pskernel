import type {
  V061Expr,
  V061Pattern,
} from '@proofscript/syntax';
import {
  TypeChecker,
  abstractFVar,
  fvar,
  instantiate1,
  lam,
  nameFromDotted,
  nameToString,
  type Expr,
  type Name,
} from 'lean-ts-kernel';
import type {
  ElaboratedCoreTerm,
  V061CoreElabContext,
} from './v061-context.js';

export type MatchTermElaborator=(
  expr:V061Expr,
  context:V061CoreElabContext,
  expected?:Expr,
)=>ElaboratedCoreTerm;

export function elaborateV061MatchMinor(
  alternative:Extract<
    Extract<V061Expr,{kind:'match'}>['alternatives'][number],
    {pattern:V061Pattern}
  >,
  constructorName:Name,
  parameterArgs:readonly Expr[],
  context:V061CoreElabContext,
  expected:Expr,
  elaborate:MatchTermElaborator,
):Expr {
  const pattern=alternative.pattern;
  if(pattern.kind!=='constructor')throw new Error('unreachable');
  const constructor=context.environment.find(constructorName);
  if(constructor?.kind!=='constructor'){
    throw new Error(
      "PS_ELAB_MATCH_CONSTRUCTOR: unknown constructor '"+
      nameToString(constructorName)+"'",
    );
  }
  if(constructor.numParams!==parameterArgs.length){
    throw new Error(
      "PS_ELAB_MATCH_PARAMETER_ARITY: constructor '"+
      nameToString(constructorName)+"' expects "+
      constructor.numParams+' shared parameters, got '+
      parameterArgs.length,
    );
  }
  if(pattern.binders.length!==constructor.numFields){
    throw new Error(
      "PS_ELAB_MATCH_ARITY: constructor '"+
      nameToString(constructorName)+"' binds "+
      constructor.numFields+' fields, got '+pattern.binders.length,
    );
  }

  let cursor=constructor.type;
  for(const parameter of parameterArgs){
    const checker=new TypeChecker(
      context.environment,
      context.localContext.clone(),
    );
    const binder=checker.ensureForall(checker.whnf(cursor));
    cursor=instantiate1(binder.body,parameter);
  }

  let branchContext=context;
  const fields:{
    readonly id:string;
    readonly name:Name;
    readonly type:Expr;
    readonly binderInfo:import('lean-ts-kernel').BinderInfo;
  }[]=[];

  for(let index=0;index<constructor.numFields;index+=1){
    const checker=new TypeChecker(
      context.environment,
      branchContext.localContext.clone(),
    );
    const binder=checker.ensureForall(checker.whnf(cursor));
    const sourceName=pattern.binders[index]!;
    if(branchContext.locals.has(sourceName)){
      throw new Error(
        "PS_ELAB_MATCH_BINDER_DUPLICATE: '"+sourceName+"'",
      );
    }

    const localContext=branchContext.localContext.clone();
    const id=localContext.fresh(sourceName);
    const userName=nameFromDotted(sourceName);
    localContext.addLocal(
      id,
      userName,
      binder.type,
      binder.binderInfo,
    );
    const locals=new Map(branchContext.locals);
    locals.set(sourceName,id);
    branchContext={...branchContext,localContext,locals};
    fields.push({
      id,
      name:userName,
      type:binder.type,
      binderInfo:binder.binderInfo,
    });
    cursor=instantiate1(binder.body,fvar(id));
  }

  const branch=elaborate(
    alternative.body,
    branchContext,
    expected,
  );
  let result=branch.term;
  for(let index=fields.length-1;index>=0;index-=1){
    const field=fields[index]!;
    result=lam(
      field.name,
      field.type,
      abstractFVar(result,field.id),
      field.binderInfo,
    );
  }
  return result;
}
