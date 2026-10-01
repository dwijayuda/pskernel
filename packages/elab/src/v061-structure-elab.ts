import type {
  V061Parameter,
  V061StructureDeclaration,
} from '@proofscript/syntax';
import {
  Environment,
  LocalContext,
  TypeChecker,
  abstractFVar,
  constant,
  forallE,
  fvar,
  levelZero,
  mkAppN,
  mkMax,
  nameFromDotted,
  nameToString,
  sort,
  type BinderInfo,
  type Expr,
  type InductiveDecl,
} from 'lean-ts-kernel';
import {ExprMetaContext} from '@proofscript/meta';
import type {CheckedCoreStructure} from '@proofscript/checked-core';
import type {V061CoreElabContext} from './v061-context.js';
import {elaborateV061Type} from './v061-type-elab.js';

interface SharedParameter {
  readonly source:V061Parameter;
  readonly id:string;
  readonly name:ReturnType<typeof nameFromDotted>;
  readonly type:Expr;
  readonly binderInfo:BinderInfo;
}

function fieldBinderInfo(
  kind:V061StructureDeclaration['fields'][number]['binderKind'],
):BinderInfo {
  if(kind==='implicit')return 'implicit';
  if(kind==='instance')return 'instImplicit';
  return 'default';
}

function closeParameters(
  expr:Expr,
  parameters:readonly SharedParameter[],
  constructorCopy:boolean,
):Expr {
  let result=expr;
  for(let index=parameters.length-1;index>=0;index-=1){
    const parameter=parameters[index]!;
    result=forallE(
      parameter.name,
      parameter.type,
      abstractFVar(result,parameter.id),
      constructorCopy?'implicit':parameter.binderInfo,
    );
  }
  return result;
}

export interface ElaboratedV061Structure {
  readonly declaration:InductiveDecl;
  readonly structure:CheckedCoreStructure;
}

export function elaborateV061StructureDeclaration(
  source:V061StructureDeclaration,
  environment:Environment,
):ElaboratedV061Structure {
  const structureName=nameFromDotted(source.name);
  const constructorName=nameFromDotted(source.name+'.mk');
  let context:V061CoreElabContext={
    environment,
    localContext:new LocalContext(),
    locals:new Map(),
    metaContext:new ExprMetaContext(environment),
    structures:new Map(),
  };
  const parameters:SharedParameter[]=[];

  for(const parameter of source.params){
    if(context.locals.has(parameter.name)){
      throw new Error(
        "PS_ELAB_DUPLICATE_PARAM: duplicate structure parameter '"+
        parameter.name+"'",
      );
    }
    const type=elaborateV061Type(parameter.type,context);
    const checker=new TypeChecker(
      environment,
      context.localContext.clone(),
    );
    checker.ensureSort(checker.check(type),type);

    const localContext=context.localContext.clone();
    const id=localContext.fresh(parameter.name);
    const name=nameFromDotted(parameter.name);
    const binderInfo=parameter.binderInfo??'default';
    localContext.addLocal(id,name,type,binderInfo);
    const locals=new Map(context.locals);
    locals.set(parameter.name,id);
    context={...context,localContext,locals};
    parameters.push({
      source:parameter,
      id,
      name,
      type,
      binderInfo,
    });
  }

  const fields:{
    readonly id:string;
    readonly name:ReturnType<typeof nameFromDotted>;
    readonly type:Expr;
    readonly binderInfo:BinderInfo;
  }[]=[];
  let resultLevel=levelZero;

  for(const field of source.fields){
    if(context.locals.has(field.name)){
      throw new Error(
        "PS_ELAB_DUPLICATE_FIELD: duplicate structure field '"+
        field.name+"'",
      );
    }
    const type=elaborateV061Type(field.type,context);
    const checker=new TypeChecker(
      environment,
      context.localContext.clone(),
    );
    resultLevel=mkMax(resultLevel,checker.getSortLevel(type));

    const userName=nameFromDotted(field.name);
    const localContext=context.localContext.clone();
    const id=localContext.fresh(field.name);
    const binderInfo=fieldBinderInfo(field.binderKind);
    localContext.addLocal(id,userName,type,binderInfo);
    const locals=new Map(context.locals);
    locals.set(field.name,id);
    context={...context,localContext,locals};
    fields.push({id,name:userName,type,binderInfo});
  }

  const appliedStructure=mkAppN(
    constant(structureName),
    parameters.map((parameter)=>fvar(parameter.id)),
  );
  let constructorType:Expr=appliedStructure;
  for(let index=fields.length-1;index>=0;index-=1){
    const field=fields[index]!;
    constructorType=forallE(
      field.name,
      field.type,
      abstractFVar(constructorType,field.id),
      field.binderInfo,
    );
  }
  constructorType=closeParameters(
    constructorType,
    parameters,
    true,
  );
  const structureType=closeParameters(
    sort(resultLevel),
    parameters,
    false,
  );

  const declaration:InductiveDecl={
    levelParams:[],
    numParams:parameters.length,
    types:[{
      name:structureName,
      type:structureType,
      ctors:[{
        name:constructorName,
        type:constructorType,
      }],
    }],
  };

  if(source.fields.length===0){
    throw new Error(
      "PS_ELAB_EMPTY_STRUCTURE: '"+nameToString(structureName)+
      "' must have at least one field",
    );
  }
  return {
    declaration,
    structure:{
      name:structureName,
      constructor:constructorName,
      fields:fields.map((field,index)=>({
        name:nameToString(field.name),
        index,
        binderInfo:field.binderInfo,
      })),
    },
  };
}
