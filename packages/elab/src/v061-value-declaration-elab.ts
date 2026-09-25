import type {V061ValueDeclaration} from '@proofscript/syntax';
import {
  Environment,
  type DefinitionInfo,
  type TheoremInfo,
  type Expr,
  abstractFVar,
  forallE,
  hasMVar,
  lam,
  nameFromDotted,
} from 'lean-ts-kernel';
import type {CheckedCoreStructure} from '@proofscript/checked-core';
import {elaborateV061ValueHeader} from './v061-header-elab.js';
import {withStructuralRecursionContext} from './v061-structural-recursion.js';
import {
  checkElaboratedTerm,
  elaborateV061Term,
} from './v061-term-elab.js';
import {elaborateV061WhereBody} from './v061-where-elab.js';

function maxRegularHeight(
  environment:Environment,
  expr:Expr,
):bigint {
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

export function elaborateV061ValueDeclaration(
  source:V061ValueDeclaration,
  environment:Environment,
  structures:ReadonlyMap<string,CheckedCoreStructure>,
  classes:ReadonlySet<string>,
  globalInstances:readonly Expr[],
):DefinitionInfo|TheoremInfo {
  const header=elaborateV061ValueHeader(
    source,
    environment,
    structures,
    classes,
    globalInstances,
  );
  const context=header.context;
  const parameters=header.parameters;
  const resultType=header.resultType;

  const bodyContext=withStructuralRecursionContext(source,context);
  const whereDeclarations=source.whereDeclarations??[];
  const body=whereDeclarations.length===0
    ?elaborateV061Term(source.body,bodyContext,resultType)
    :elaborateV061WhereBody(
        whereDeclarations,
        source.body,
        bodyContext,
        resultType,
        elaborateV061Term,
      );
  checkElaboratedTerm(body,resultType,bodyContext);
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
    safety:source.partial?'partial':'safe',
  };
}
