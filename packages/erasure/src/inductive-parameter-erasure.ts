import {
  LocalContext,
  TypeChecker,
  fvar,
  instantiate1,
  nameToString,
  type Environment,
  type Expr,
  type InductiveInfo,
} from 'lean-ts-kernel';
import type {
  VerifiedIrTypeParameter,
} from '@proofscript/compiler-ir/verified';
import {classifyBinder} from './model.js';

export interface PreparedInductiveParameters {
  readonly localContext:LocalContext;
  readonly typeLocals:ReadonlyMap<string,string>;
  readonly erasedLocals:ReadonlySet<string>;
  readonly typeParameters:readonly VerifiedIrTypeParameter[];
  readonly values:readonly Expr[];
}

export function prepareInductiveParameters(
  inductive:InductiveInfo,
  environment:Environment,
):PreparedInductiveParameters {
  let cursor=inductive.type;
  let localContext=new LocalContext();
  const typeLocals=new Map<string,string>();
  const erasedLocals=new Set<string>();
  const typeParameters:VerifiedIrTypeParameter[]=[];
  const values:Expr[]=[];

  for(let index=0;index<inductive.numParams;index+=1){
    const checker=new TypeChecker(environment,localContext.clone());
    const binder=checker.ensureForall(checker.whnf(cursor));
    if(classifyBinder(binder.type,checker)!=='type'){
      throw new Error(
        "PS_ERASE_INDUCTIVE_PARAMETER_UNSUPPORTED: '"+
        nameToString(inductive.name)+"' parameter "+index+
        ' is not type-level',
      );
    }

    const id=localContext.fresh(nameToString(binder.name)||'param');
    localContext.addLocal(
      id,
      binder.name,
      binder.type,
      binder.binderInfo,
    );
    const typeName='T'+index;
    typeLocals.set(id,typeName);
    erasedLocals.add(id);
    typeParameters.push({name:typeName});
    const value=fvar(id);
    values.push(value);
    cursor=instantiate1(binder.body,value);
  }

  return {
    localContext,
    typeLocals,
    erasedLocals,
    typeParameters,
    values,
  };
}
