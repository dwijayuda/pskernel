import type {
  V061Expr,
  V061TypeExpr,
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

function collectTypeDependencies(
  type:V061TypeExpr,
  names:ReadonlySet<string>,
  out:Set<string>,
):void {
  switch(type.kind){
    case 'named':
      if(names.has(type.name))out.add(type.name);
      return;
    case 'group':
      collectTypeDependencies(type.value,names,out);
      return;
    case 'application':
      collectTypeDependencies(type.fn,names,out);
      for(const arg of type.args)collectTypeDependencies(arg,names,out);
      return;
    case 'arrow':
      collectTypeDependencies(type.domain,names,out);
      collectTypeDependencies(type.codomain,names,out);
      return;
  }
}

function collectExprDependencies(
  expr:V061Expr,
  names:ReadonlySet<string>,
  bound:ReadonlySet<string>,
  out:Set<string>,
):void {
  const use=(name:string):void=>{
    if(names.has(name)&&!bound.has(name))out.add(name);
  };
  switch(expr.kind){
    case 'nat':
    case 'string':
    case 'bool':
    case 'unit':
      return;
    case 'reference':
      use(expr.name);
      return;
    case 'group':
      collectExprDependencies(expr.value,names,bound,out);
      return;
    case 'call':
      use(expr.callee);
      for(const arg of expr.args){
        collectExprDependencies(arg,names,bound,out);
      }
      return;
    case 'unary':
      collectExprDependencies(expr.operand,names,bound,out);
      return;
    case 'binary':
      collectExprDependencies(expr.left,names,bound,out);
      collectExprDependencies(expr.right,names,bound,out);
      return;
    case 'if':
      collectExprDependencies(expr.condition,names,bound,out);
      collectExprDependencies(expr.thenBranch,names,bound,out);
      collectExprDependencies(expr.elseBranch,names,bound,out);
      return;
    case 'lambda':{
      const next=new Set(bound);
      for(const binder of expr.binders)next.add(binder.name);
      collectExprDependencies(expr.body,names,next,out);
      return;
    }
    case 'by':
      // Current where helpers are software terms; tactic-local dependency
      // discovery can be added with the broader tactic goal engine.
      return;
    case 'record':
      for(const field of expr.fields){
        collectExprDependencies(field.value,names,bound,out);
      }
      return;
    case 'match':
      collectExprDependencies(expr.scrutinee,names,bound,out);
      for(const alternative of expr.alternatives){
        const next=new Set(bound);
        if(alternative.pattern.kind==='constructor'){
          for(const binder of alternative.pattern.binders)next.add(binder);
        }
        collectExprDependencies(alternative.body,names,next,out);
      }
      return;
    case 'let':{
      collectExprDependencies(expr.value,names,bound,out);
      const next=new Set(bound);
      next.add(expr.name);
      collectExprDependencies(expr.body,names,next,out);
      return;
    }
  }
}

function orderedWhereDeclarations(
  declarations:readonly V061WhereDeclaration[],
):readonly V061WhereDeclaration[] {
  const byName=new Map<string,V061WhereDeclaration>();
  for(const declaration of declarations){
    if(byName.has(declaration.name)){
      throw new Error(
        "PS_ELAB_DUPLICATE_WHERE: duplicate local declaration '"+
        declaration.name+"'",
      );
    }
    byName.set(declaration.name,declaration);
  }

  const names=new Set(byName.keys());
  const deps=new Map<string,Set<string>>();
  for(const declaration of declarations){
    const refs=new Set<string>();
    for(const parameter of declaration.params){
      collectTypeDependencies(parameter.type,names,refs);
    }
    collectTypeDependencies(declaration.resultType,names,refs);
    collectExprDependencies(
      declaration.body,
      names,
      new Set(declaration.params.map((parameter)=>parameter.name)),
      refs,
    );
    deps.set(declaration.name,refs);
  }

  const visiting=new Set<string>();
  const visited=new Set<string>();
  const order:V061WhereDeclaration[]=[];
  const visit=(name:string,stack:readonly string[]):void=>{
    if(visited.has(name))return;
    if(visiting.has(name)){
      throw new Error(
        'PS_ELAB_WHERE_RECURSION_UNSUPPORTED: recursive where cycle '+
        [...stack,name].join(' -> ')+
        ' requires Lean-compatible termination elaboration',
      );
    }
    visiting.add(name);
    for(const dependency of deps.get(name)??[]){
      visit(dependency,[...stack,name]);
    }
    visiting.delete(name);
    visited.add(name);
    order.push(byName.get(name)!);
  };

  for(const declaration of declarations)visit(declaration.name,[]);
  return order;
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

  for(const source of orderedWhereDeclarations(declarations)){
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
