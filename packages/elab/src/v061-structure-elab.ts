import type {V061StructureDeclaration} from '@proofscript/syntax';
import {
  Environment,
  LocalContext,
  TypeChecker,
  abstractFVar,
  constant,
  forallE,
  levelZero,
  mkMax,
  nameFromDotted,
  nameToString,
  sort,
  type BinderInfo,
  type Expr,
  type InductiveDecl,
} from 'lean-ts-kernel';
import {ExprMetaContext} from '@proofscript/meta';
import type {V061CoreElabContext} from './v061-context.js';
import {elaborateV061Type} from './v061-type-elab.js';

function fieldBinderInfo(
  kind:V061StructureDeclaration['fields'][number]['binderKind'],
):BinderInfo {
  if(kind==='implicit')return 'implicit';
  if(kind==='instance')return 'instImplicit';
  return 'default';
}

export function elaborateV061StructureDeclaration(
  source:V061StructureDeclaration,
  environment:Environment,
):InductiveDecl {
  const structureName=nameFromDotted(source.name);
  const constructorName=nameFromDotted(source.name+'.mk');
  let context:V061CoreElabContext={
    environment,
    localContext:new LocalContext(),
    locals:new Map(),
    metaContext:new ExprMetaContext(environment),
  };
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

  let constructorType:Expr=constant(structureName);
  for(let index=fields.length-1;index>=0;index-=1){
    const field=fields[index]!;
    constructorType=forallE(
      field.name,
      field.type,
      abstractFVar(constructorType,field.id),
      field.binderInfo,
    );
  }

  const declaration:InductiveDecl={
    levelParams:[],
    numParams:0,
    types:[{
      name:structureName,
      type:sort(resultLevel),
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
  return declaration;
}
