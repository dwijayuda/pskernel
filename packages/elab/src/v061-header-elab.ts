import type {
  V061ValueDeclaration,
} from '@proofscript/syntax';
import {
  Environment,
  LocalContext,
  TypeChecker,
  type BinderInfo,
  type Expr,
  nameFromDotted,
} from 'lean-ts-kernel';
import {ExprMetaContext} from '@proofscript/meta';
import type {CheckedCoreStructure} from '@proofscript/checked-core';
import type {V061CoreElabContext} from './v061-context.js';
import {elaborateV061Type} from './v061-type-elab.js';

export interface V061ElaboratedParameter {
  readonly sourceName:string;
  readonly id:string;
  readonly name:ReturnType<typeof nameFromDotted>;
  readonly type:Expr;
  readonly binderInfo:BinderInfo;
}

export interface V061ElaboratedHeader {
  readonly context:V061CoreElabContext;
  readonly parameters:readonly V061ElaboratedParameter[];
  readonly resultType:Expr;
}

export function elaborateV061ValueHeader(
  source:V061ValueDeclaration,
  environment:Environment,
  structures:ReadonlyMap<string,CheckedCoreStructure>=new Map(),
):V061ElaboratedHeader {
  let context:V061CoreElabContext={
    environment,
    localContext:new LocalContext(),
    locals:new Map(),
    metaContext:new ExprMetaContext(environment),
    structures,
  };
  const parameters:V061ElaboratedParameter[]=[];

  for(const parameter of source.params){
    if(context.locals.has(parameter.name)){
      throw new Error(
        "PS_ELAB_DUPLICATE_PARAM: duplicate parameter '"+parameter.name+"'",
      );
    }

    const type=elaborateV061Type(parameter.type,context);
    const checker=new TypeChecker(
      environment,
      context.localContext.clone(),
    );
    checker.ensureSort(checker.check(type),type);

    const userName=nameFromDotted(parameter.name);
    const next=context.localContext.clone();
    const id=next.fresh(parameter.name);
    const binderInfo=parameter.binderInfo??'default';
    next.addLocal(id,userName,type,binderInfo);

    const locals=new Map(context.locals);
    locals.set(parameter.name,id);
    context={...context,localContext:next,locals};
    parameters.push({
      sourceName:parameter.name,
      id,
      name:userName,
      type,
      binderInfo,
    });
  }

  const resultType=elaborateV061Type(source.resultType,context);
  const checker=new TypeChecker(
    environment,
    context.localContext.clone(),
  );
  checker.ensureSort(checker.check(resultType),resultType);

  return {context,parameters,resultType};
}
