import type {
  V061InductiveDeclaration,
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
  nameFromDotted,
  sort,
  type Expr,
  type InductiveDecl,
} from 'lean-ts-kernel';
import {ExprMetaContext} from '@proofscript/meta';
import type {V061CoreElabContext} from './v061-context.js';
import {elaborateV061Type} from './v061-type-elab.js';

function baseContext(environment:Environment):V061CoreElabContext {
  return {
    environment,
    localContext:new LocalContext(),
    locals:new Map(),
    metaContext:new ExprMetaContext(environment),
    structures:new Map(),
  };
}

export function elaborateV061InductiveDeclaration(
  source:V061InductiveDeclaration,
  environment:Environment,
):InductiveDecl {
  if(source.params.length!==0){
    throw new Error(
      'PS_ELAB_PARAMETERIZED_INDUCTIVE_UNSUPPORTED: '+
      "'"+source.name+"'",
    );
  }

  const typeName=nameFromDotted(source.name);
  const resultType=source.resultType===undefined
    ?sort(levelSucc(levelZero))
    :elaborateV061Type(source.resultType,baseContext(environment));
  const resultChecker=new TypeChecker(environment,new LocalContext());
  resultChecker.ensureSort(resultChecker.check(resultType),resultType);

  const constructors=source.constructors.map((constructor)=>{
    let context=baseContext(environment);
    const fields:{
      readonly id:string;
      readonly name:ReturnType<typeof nameFromDotted>;
      readonly type:Expr;
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
      localContext.addLocal(
        id,
        name,
        type,
        parameter.binderInfo??'default',
      );
      const locals=new Map(context.locals);
      locals.set(parameter.name,id);
      context={...context,localContext,locals};
      fields.push({id,name,type});
    }

    let type:Expr=constant(typeName);
    for(let index=fields.length-1;index>=0;index-=1){
      const field=fields[index]!;
      type=forallE(
        field.name,
        field.type,
        abstractFVar(type,field.id),
        'default',
      );
    }
    return {
      name:nameFromDotted(source.name+'.'+constructor.name),
      type,
    };
  });

  return {
    levelParams:[],
    numParams:0,
    types:[{
      name:typeName,
      type:resultType,
      ctors:constructors,
    }],
  };
}
