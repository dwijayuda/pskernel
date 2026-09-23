import type {
  V061Module,
  V061ValueDeclaration,
} from '@proofscript/syntax';
import {
  Environment,
  Kernel,
  LocalContext,
  TypeChecker,
  type DefinitionInfo,
  type TheoremInfo,
  type Expr,
  abstractFVar,
  exprToString,
  forallE,
  hasMVar,
  lam,
  nameFromDotted,
} from 'lean-ts-kernel';
import {ExprMetaContext} from '@proofscript/meta';
import {elaborateV061Type} from './v061-type-elab.js';
import {
  checkElaboratedTerm,
  elaborateV061Term,
} from './v061-term-elab.js';
import type {V061CoreElabContext} from './v061-context.js';

function maxRegularHeight(environment:Environment,expr:Expr):bigint {
  let max=0n;
  const visit=(value:Expr):void=>{
    switch(value.kind){
      case 'const':{
        const info=environment.find(value.name);
        if(
          info?.kind==='definition'
          &&info.hints.kind==='regular'
          &&info.hints.height>max
        )max=info.hints.height;
        return;
      }
      case 'app':
        visit(value.fn);
        visit(value.arg);
        return;
      case 'lam':
      case 'forall':
        visit(value.type);
        visit(value.body);
        return;
      case 'let':
        visit(value.type);
        visit(value.value);
        visit(value.body);
        return;
      case 'mdata':
      case 'proj':
        visit(value.expr);
        return;
      default:
        return;
    }
  };
  visit(expr);
  return max;
}

function elaborateValueDeclaration(
  source:V061ValueDeclaration,
  environment:Environment,
):DefinitionInfo|TheoremInfo {
  if((source.whereDeclarations??[]).length>0){
    throw new Error(
      'PS_ELAB_WHERE_UNSUPPORTED: kernel-facing where elaboration requires recursion/termination predefinition processing',
    );
  }

  let context:V061CoreElabContext={
    environment,
    localContext:new LocalContext(),
    locals:new Map(),
    metaContext:new ExprMetaContext(environment),
  };
  const parameters:{
    readonly id:string;
    readonly name:ReturnType<typeof nameFromDotted>;
    readonly type:Expr;
    readonly binderInfo:import('lean-ts-kernel').BinderInfo;
  }[]=[];

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
    parameters.push({id,name:userName,type,binderInfo});
  }

  const resultType=elaborateV061Type(source.resultType,context);
  const checker=new TypeChecker(environment,context.localContext.clone());
  checker.ensureSort(checker.check(resultType),resultType);

  const body=elaborateV061Term(source.body,context);
  checkElaboratedTerm(body,resultType,context);
  context.metaContext.validateGroundAssignments();
  let value=context.metaContext.instantiate(body.term);
  let type=context.metaContext.instantiate(resultType);
  if(hasMVar(value)||hasMVar(type)){
    throw new Error(
      'PS_ELAB_UNSOLVED_METAVARS: declaration contains unresolved metavariables',
    );
  }

  for(let index=parameters.length-1;index>=0;index-=1){
    const parameter=parameters[index]!;
    value=lam(
      parameter.name,
      parameter.type,
      abstractFVar(value,parameter.id),
      parameter.binderInfo,
    );
    type=forallE(
      parameter.name,
      parameter.type,
      abstractFVar(type,parameter.id),
      parameter.binderInfo,
    );
  }

  if(source.kind==='theorem'){
    return {
      kind:'theorem',
      name:nameFromDotted(source.name),
      levelParams:[],
      type,
      value,
    };
  }

  return {
    kind:'definition',
    name:nameFromDotted(source.name),
    levelParams:[],
    type,
    value,
    hints:{
      kind:'regular',
      height:maxRegularHeight(environment,value)+1n,
    },
    safety:'safe',
  };
}

export interface ElaboratedV061Module {
  readonly environment:Environment;
  readonly declarations:readonly (DefinitionInfo|TheoremInfo)[];
  readonly definitions:readonly DefinitionInfo[];
  readonly theorems:readonly TheoremInfo[];
}

export function elaborateV061Definitions(
  module:V061Module,
  environment=new Environment(),
):ElaboratedV061Module {
  const declarations:(DefinitionInfo|TheoremInfo)[]=[];
  const definitions:DefinitionInfo[]=[];
  const theorems:TheoremInfo[]=[];
  const kernel=new Kernel(environment);

  for(const declaration of module.declarations){
    if(
      declaration.kind==='structure'
      ||declaration.kind==='class'
      ||declaration.kind==='inductive'
    ){
      throw new Error(
        "PS_ELAB_DECL_UNSUPPORTED: declaration kind '"+declaration.kind+
        "' requires dedicated Lean-compatible declaration elaboration",
      );
    }

    let info:DefinitionInfo|TheoremInfo;
    try{
      info=elaborateValueDeclaration(declaration,environment);
    }catch(error){
      const detail=error instanceof Error?error.message:String(error);
      throw new Error(
        "PS_ELAB_DECL_FAILED: '"+declaration.name+"': "+detail,
      );
    }
    if(info.kind==='theorem'){
      kernel.addTheorem(info);
      theorems.push(info);
    }else{
      kernel.addDefinition(info);
      definitions.push(info);
    }
    declarations.push(info);
  }

  return {environment,declarations,definitions,theorems};
}


/** Preferred name now that the kernel-facing path also admits theorem proof terms. */
export const elaborateV061Declarations=elaborateV061Definitions;
