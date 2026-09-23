import type {
  V061InductiveDeclaration,
  V061Parameter,
} from '@proofscript/syntax';
import {
  Environment,
  LocalContext,
  TypeChecker,
  abstractFVar,
  constant,
  forallE,
  fvar,
  levelSucc,
  levelZero,
  mkAppN,
  nameFromDotted,
  sort,
  type BinderInfo,
  type Expr,
  type InductiveDecl,
} from 'lean-ts-kernel';
import {ExprMetaContext} from '@proofscript/meta';
import type {V061CoreElabContext} from './v061-context.js';
import {elaborateV061Type} from './v061-type-elab.js';

interface SharedParameter {
  readonly source:V061Parameter;
  readonly id:string;
  readonly name:ReturnType<typeof nameFromDotted>;
  readonly type:Expr;
  readonly binderInfo:BinderInfo;
}

function baseContext(environment:Environment):V061CoreElabContext {
  return {
    environment,
    localContext:new LocalContext(),
    locals:new Map(),
    metaContext:new ExprMetaContext(environment),
    structures:new Map(),
  };
}

function elaborateSharedParameters(
  source:V061InductiveDeclaration,
  environment:Environment,
):{
  readonly context:V061CoreElabContext;
  readonly parameters:readonly SharedParameter[];
} {
  let context=baseContext(environment);
  const parameters:SharedParameter[]=[];

  for(const parameter of source.params){
    if(context.locals.has(parameter.name)){
      throw new Error(
        "PS_ELAB_DUPLICATE_PARAM: duplicate inductive parameter '"+
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

  return {context,parameters};
}

function closeSharedParameters(
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

export function elaborateV061InductiveDeclaration(
  source:V061InductiveDeclaration,
  environment:Environment,
):InductiveDecl {
  const typeName=nameFromDotted(source.name);
  const shared=elaborateSharedParameters(source,environment);
  const resultSort=source.resultType===undefined
    ?sort(levelSucc(levelZero))
    :elaborateV061Type(source.resultType,shared.context);
  const resultChecker=new TypeChecker(
    environment,
    shared.context.localContext.clone(),
  );
  resultChecker.ensureSort(resultChecker.check(resultSort),resultSort);

  const inductiveType=closeSharedParameters(
    resultSort,
    shared.parameters,
    false,
  );
  const appliedInductive=mkAppN(
    constant(typeName),
    shared.parameters.map((parameter)=>fvar(parameter.id)),
  );

  const constructors=source.constructors.map((constructor)=>{
    let context=shared.context;
    const fields:{
      readonly id:string;
      readonly name:ReturnType<typeof nameFromDotted>;
      readonly type:Expr;
      readonly binderInfo:BinderInfo;
    }[]=[];

    for(const parameter of constructor.params){
      let type:Expr;
      try{
        type=elaborateV061Type(parameter.type,context);
      }catch(error){
        const detail=error instanceof Error?error.message:String(error);
        if(detail.includes("unknown type '"+source.name+"'")){
          throw new Error(
            'PS_ELAB_RECURSIVE_INDUCTIVE_UNSUPPORTED: '+
            "'"+source.name+"'",
          );
        }
        throw error;
      }

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
      fields.push({id,name,type,binderInfo});
    }

    let constructorType:Expr=appliedInductive;
    for(let index=fields.length-1;index>=0;index-=1){
      const field=fields[index]!;
      constructorType=forallE(
        field.name,
        field.type,
        abstractFVar(constructorType,field.id),
        field.binderInfo,
      );
    }
    constructorType=closeSharedParameters(
      constructorType,
      shared.parameters,
      true,
    );

    return {
      name:nameFromDotted(source.name+'.'+constructor.name),
      type:constructorType,
    };
  });

  return {
    levelParams:[],
    numParams:shared.parameters.length,
    types:[{
      name:typeName,
      type:inductiveType,
      ctors:constructors,
    }],
  };
}
