import type {
  V061Expr,
  V061WhereDeclaration,
} from '@proofscript/syntax';
import {
  TypeChecker,
  abstractFVar,
  forallE,
  lam,
  nameFromDotted,
  type Expr,
} from 'lean-ts-kernel';
import type {
  ElaboratedCoreTerm,
  V061CoreElabContext,
} from './v061-context.js';
import {elaborateV061Type} from './v061-type-elab.js';
import {orderedV061WhereDeclarations} from './v061-where-dependencies.js';

export type WhereTermElaborator=(
  expr:V061Expr,
  context:V061CoreElabContext,
  expected?:Expr,
)=>ElaboratedCoreTerm;

interface ElaboratedWhereHelper {
  readonly id:string;
  readonly name:ReturnType<typeof nameFromDotted>;
  readonly type:Expr;
  readonly value:Expr;
}

function elaborateHelper(
  source:V061WhereDeclaration,
  context:V061CoreElabContext,
  elaborate:WhereTermElaborator,
):{
  readonly type:Expr;
  readonly value:Expr;
} {
  let helperContext=context;
  const parameters:{
    readonly id:string;
    readonly name:ReturnType<typeof nameFromDotted>;
    readonly type:Expr;
  }[]=[];
  const parameterNames=new Set<string>();

  for(const parameter of source.params){
    if(parameterNames.has(parameter.name)){
      throw new Error(
        "PS_ELAB_DUPLICATE_PARAM: duplicate where parameter '"+
        parameter.name+"'",
      );
    }
    parameterNames.add(parameter.name);
    const type=elaborateV061Type(parameter.type,helperContext);
    const checker=new TypeChecker(
      context.environment,
      helperContext.localContext.clone(),
    );
    checker.ensureSort(checker.check(type),type);

    const localContext=helperContext.localContext.clone();
    const id=localContext.fresh(parameter.name);
    const name=nameFromDotted(parameter.name);
    localContext.addLocal(id,name,type,'default');
    const locals=new Map(helperContext.locals);
    locals.set(parameter.name,id);
    helperContext={...helperContext,localContext,locals};
    parameters.push({id,name,type});
  }

  const resultType=elaborateV061Type(
    source.resultType,
    helperContext,
  );
  const checker=new TypeChecker(
    context.environment,
    helperContext.localContext.clone(),
  );
  checker.ensureSort(checker.check(resultType),resultType);
  const body=elaborate(source.body,helperContext,resultType);
  if(!checker.isDefEq(body.type,resultType)){
    throw new Error(
      "PS_ELAB_WHERE_TYPE: local declaration '"+source.name+
      "' body does not match its result type",
    );
  }

  let type=resultType;
  let value=body.term;
  for(let index=parameters.length-1;index>=0;index-=1){
    const parameter=parameters[index]!;
    value=lam(
      parameter.name,
      parameter.type,
      abstractFVar(value,parameter.id),
      'default',
    );
    type=forallE(
      parameter.name,
      parameter.type,
      abstractFVar(type,parameter.id),
      'default',
    );
  }
  return {type,value};
}

export function elaborateV061WhereBody(
  declarations:readonly V061WhereDeclaration[],
  body:V061Expr,
  context:V061CoreElabContext,
  expected:Expr,
  elaborate:WhereTermElaborator,
):ElaboratedCoreTerm {
  let active=context;
  const helpers:ElaboratedWhereHelper[]=[];

  for(const source of orderedV061WhereDeclarations(declarations)){
    if(active.locals.has(source.name)){
      throw new Error(
        "PS_ELAB_WHERE_SHADOW_LOCAL: local declaration '"+
        source.name+"' conflicts with an enclosing local",
      );
    }
    const helper=elaborateHelper(source,active,elaborate);
    const localContext=active.localContext.clone();
    const id=localContext.fresh(source.name);
    const name=nameFromDotted(source.name);
    localContext.addLet(id,name,helper.type,helper.value);
    const locals=new Map(active.locals);
    locals.set(source.name,id);
    active={...active,localContext,locals};
    helpers.push({id,name,...helper});
  }

  const result=elaborate(body,active,expected);
  let term=result.term;
  for(let index=helpers.length-1;index>=0;index-=1){
    const helper=helpers[index]!;
    term={
      kind:'let',
      name:helper.name,
      type:helper.type,
      value:helper.value,
      body:abstractFVar(term,helper.id),
    };
  }

  const checker=new TypeChecker(
    context.environment,
    context.localContext.clone(),
  );
  const type=checker.check(term);
  if(!checker.isDefEq(type,expected)){
    throw new Error(
      'PS_ELAB_WHERE_RESULT_TYPE: where body does not match expected type',
    );
  }
  return {term,type};
}
