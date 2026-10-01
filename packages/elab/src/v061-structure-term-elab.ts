import type {V061Expr} from '@proofscript/syntax';
import {
  TypeChecker,
  app,
  appView,
  constant,
  instantiate1,
  nameToString,
  type Expr,
} from 'lean-ts-kernel';
import type {
  ElaboratedCoreTerm,
  V061CoreElabContext,
} from './v061-context.js';
import {elaborateV061Type} from './v061-type-elab.js';

export type StructureTermElaborator=(
  expr:V061Expr,
  context:V061CoreElabContext,
  expected?:Expr,
)=>ElaboratedCoreTerm;

export function elaborateV061Record(
  expr:Extract<V061Expr,{kind:'record'}>,
  context:V061CoreElabContext,
  expected:Expr|undefined,
  elaborate:StructureTermElaborator,
):ElaboratedCoreTerm {
  const target=elaborateV061Type(expr.type,context);
  const checker=new TypeChecker(
    context.environment,
    context.localContext.clone(),
  );
  if(expected!==undefined&&!checker.isDefEq(target,expected)){
    throw new Error(
      'PS_ELAB_RECORD_EXPECTED_TYPE: record annotation does not match expected type',
    );
  }
  const targetView=appView(checker.whnf(target));
  if(targetView.fn.kind!=='const'){
    throw new Error(
      'PS_ELAB_RECORD_TYPE: structure record target must be an admitted named structure application',
    );
  }
  const structure=context.structures.get(nameToString(targetView.fn.name));
  if(structure===undefined){
    throw new Error(
      "PS_ELAB_UNKNOWN_STRUCTURE: '"+nameToString(targetView.fn.name)+
      "' is not a checked ProofScript structure",
    );
  }

  const provided=new Map<string,V061Expr>();
  for(const field of expr.fields){
    if(provided.has(field.name)){
      throw new Error(
        "PS_ELAB_DUPLICATE_RECORD_FIELD: duplicate field '"+field.name+"'",
      );
    }
    if(!structure.fields.some((item)=>item.name===field.name)){
      throw new Error(
        "PS_ELAB_UNKNOWN_RECORD_FIELD: structure '"+
        nameToString(structure.name)+"' has no field '"+field.name+"'",
      );
    }
    provided.set(field.name,field.value);
  }

  const constructor=context.environment.find(structure.constructor);
  if(constructor?.kind!=='constructor'){
    throw new Error('PS_ELAB_RECORD_CONSTRUCTOR_MISSING');
  }
  if(targetView.args.length!==constructor.numParams){
    throw new Error(
      "PS_ELAB_RECORD_PARAMETER_ARITY: structure '"+
      nameToString(structure.name)+"' expects "+constructor.numParams+
      ' parameters, got '+targetView.args.length,
    );
  }

  let term:Expr=constant(structure.constructor);
  let cursor=checker.check(term);
  for(const parameter of targetView.args){
    const binder=checker.ensureForall(checker.whnf(cursor));
    term=app(term,parameter);
    cursor=instantiate1(binder.body,parameter);
  }
  for(const field of structure.fields){
    const source=provided.get(field.name);
    if(source===undefined){
      throw new Error(
        "PS_ELAB_MISSING_RECORD_FIELD: missing field '"+field.name+"'",
      );
    }
    const binder=checker.ensureForall(checker.whnf(cursor));
    const value=elaborate(source,context,binder.type);
    if(!checker.isDefEq(value.type,binder.type)){
      throw new Error(
        "PS_ELAB_RECORD_FIELD_TYPE: field '"+field.name+
        "' does not match its constructor binder type",
      );
    }
    term=app(term,value.term);
    cursor=instantiate1(binder.body,value.term);
  }

  const type=checker.check(term);
  if(!checker.isDefEq(type,target)){
    throw new Error('PS_ELAB_RECORD_RESULT_TYPE: constructor result mismatch');
  }
  return {term,type};
}
