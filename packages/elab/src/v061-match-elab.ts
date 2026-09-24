import type {
  V061Expr,
  V061Pattern,
} from '@proofscript/syntax';
import {
  TypeChecker,
  appView,
  constant,
  lam,
  mkAppN,
  nameEq,
  nameFromDotted,
  nameToString,
  strName,
  type Expr,
  type Name,
} from 'lean-ts-kernel';
import type {
  ElaboratedCoreTerm,
  V061CoreElabContext,
} from './v061-context.js';
import {
  elaborateV061MatchMinor,
  type MatchTermElaborator,
} from './v061-match-minor-elab.js';

function patternConstructorName(
  pattern:V061Pattern,
  inductive:Name,
):Name {
  if(pattern.kind!=='constructor'){
    throw new Error(
      'PS_ELAB_MATCH_PATTERN_UNSUPPORTED: verified ADT match requires constructor patterns',
    );
  }
  const inductiveText=nameToString(inductive);
  if(pattern.name.startsWith('.')){
    return nameFromDotted(inductiveText+pattern.name);
  }
  if(pattern.name.includes('.')){
    return nameFromDotted(pattern.name);
  }
  return nameFromDotted(inductiveText+'.'+pattern.name);
}

export function elaborateV061MatchExpression(
  expr:Extract<V061Expr,{kind:'match'}>,
  context:V061CoreElabContext,
  expected:Expr|undefined,
  elaborate:MatchTermElaborator,
):ElaboratedCoreTerm {
  if(expected===undefined){
    throw new Error(
      'PS_ELAB_MATCH_EXPECTED_TYPE: verified match currently requires an expected result type',
    );
  }

  const checker=new TypeChecker(
    context.environment,
    context.localContext.clone(),
  );
  const scrutinee=elaborate(expr.scrutinee,context);
  const scrutineeType=checker.whnf(scrutinee.type);
  const typeView=appView(scrutineeType);
  if(typeView.fn.kind!=='const'){
    throw new Error(
      'PS_ELAB_MATCH_SCRUTINEE: verified match requires an inductive application',
    );
  }

  const inductive=context.environment.find(typeView.fn.name);
  if(
    inductive?.kind!=='inductive'
    ||inductive.numIndices!==0
  ){
    throw new Error(
      'PS_ELAB_MATCH_INDUCTIVE_UNSUPPORTED: verified match currently supports unindexed inductives',
    );
  }

  if(typeView.args.length!==inductive.numParams){
    throw new Error(
      "PS_ELAB_MATCH_PARAMETER_ARITY: inductive '"+
      nameToString(inductive.name)+"' expects "+
      inductive.numParams+' parameters, got '+typeView.args.length,
    );
  }
  const parameterArgs=typeView.args.slice(0,inductive.numParams);

  const byConstructor=new Map<string,typeof expr.alternatives[number]>();
  for(const alternative of expr.alternatives){
    const constructorName=patternConstructorName(
      alternative.pattern,
      inductive.name,
    );
    if(!inductive.ctors.some((name)=>nameEq(name,constructorName))){
      throw new Error(
        "PS_ELAB_MATCH_CONSTRUCTOR: pattern '"+
        nameToString(constructorName)+
        "' is not a constructor of '"+nameToString(inductive.name)+"'",
      );
    }
    const key=nameToString(constructorName);
    if(byConstructor.has(key)){
      throw new Error(
        "PS_ELAB_MATCH_DUPLICATE: duplicate constructor pattern '"+key+"'",
      );
    }
    byConstructor.set(key,alternative);
  }

  const missing=inductive.ctors.filter(
    (constructor)=>!byConstructor.has(nameToString(constructor)),
  );
  if(missing.length>0){
    throw new Error(
      'PS_ELAB_MATCH_NONEXHAUSTIVE: missing '+
      missing.map(nameToString).join(', '),
    );
  }

  const motive=lam(
    nameFromDotted('_match'),
    scrutineeType,
    expected,
  );
  const minors=inductive.ctors.map((constructor)=>{
    const alternative=byConstructor.get(nameToString(constructor))!;
    return elaborateV061MatchMinor(
      alternative,
      constructor,
      parameterArgs,
      context,
      expected,
      elaborate,
    );
  });

  const recursorName=strName(inductive.name,'rec');
  const recursor=context.environment.find(recursorName);
  if(
    recursor?.kind!=='recursor'
    ||recursor.numParams!==inductive.numParams
    ||recursor.numIndices!==0
    ||recursor.numMotives!==1
    ||recursor.numMinors!==inductive.ctors.length
  ){
    throw new Error(
      "PS_ELAB_MATCH_RECURSOR: unsupported recursor metadata for '"+
      nameToString(inductive.name)+"'",
    );
  }

  const resultSort=checker.ensureSort(
    checker.check(expected),
    expected,
  ).level;
  let levels:readonly import('lean-ts-kernel').Level[];
  if(recursor.levelParams.length===0){
    levels=[];
  }else if(recursor.levelParams.length===1){
    levels=[resultSort];
  }else{
    throw new Error(
      'PS_ELAB_MATCH_RECURSOR_LEVELS: multi-universe recursor is outside the current verified subset',
    );
  }

  const term=context.metaContext.instantiate(
    mkAppN(
      constant(recursorName,levels),
      [...parameterArgs,motive,...minors,scrutinee.term],
    ),
  );
  const resultType=context.metaContext.instantiate(expected);
  const type=checker.check(term);
  if(!checker.isDefEq(type,resultType)){
    throw new Error(
      'PS_ELAB_MATCH_RESULT_TYPE: generated recursor application does not match expected type',
    );
  }
  return {term,type};
}
