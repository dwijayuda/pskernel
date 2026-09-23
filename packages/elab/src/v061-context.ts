import {
  Environment,
  LocalContext,
  type Expr,
} from 'lean-ts-kernel';
import type {CheckedCoreStructure} from '@proofscript/checked-core';
import {ExprMetaContext} from '@proofscript/meta';

export interface V061StructuralRecursion {
  readonly functionName:string;
  readonly calls:ReadonlyMap<string,string>;
  readonly explicitParameterIds:readonly string[];
  readonly recursiveParameterIndex:number;
}

export interface V061CoreElabContext {
  readonly environment:Environment;
  readonly localContext:LocalContext;
  readonly locals:ReadonlyMap<string,string>;
  readonly metaContext:ExprMetaContext;
  readonly structures:ReadonlyMap<string,CheckedCoreStructure>;
  readonly classes?:ReadonlySet<string>;
  readonly globalInstances?:readonly Expr[];
  readonly structuralRecursion?:V061StructuralRecursion;
}

export function withLocalName(
  context:V061CoreElabContext,
  name:string,
  id:string,
):V061CoreElabContext {
  const locals=new Map(context.locals);
  locals.set(name,id);
  return {...context,locals};
}

export interface ElaboratedCoreTerm {
  readonly term:Expr;
  readonly type:Expr;
}


export function v061LocalInstanceTerms(
  context:V061CoreElabContext,
):readonly Expr[] {
  const ids=[...context.locals.values()].reverse();
  const instances:Expr[]=[];
  for(const id of ids){
    const declaration=context.localContext.get(id);
    if(
      declaration?.kind==='local'
      &&declaration.binderInfo==='instImplicit'
    ){
      instances.push({kind:'fvar',id});
    }
  }
  return instances;
}
