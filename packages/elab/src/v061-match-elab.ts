import type {
  V061Expr,
  V061Pattern,
} from '@proofscript/syntax';
import {
  TypeChecker,
  abstractFVar,
  appView,
  constant,
  fvar,
  instantiate1,
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

export type MatchTermElaborator=(
  expr:V061Expr,
  context:V061CoreElabContext,
  expected?:Expr,
)=>ElaboratedCoreTerm;

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

function elaborateMinor(
  alternative:Extract<
    Extract<V061Expr,{kind:'match'}>['alternatives'][number],
    {pattern:V061Pattern}
  >,
  constructorName:Name,
  context:V061CoreElabContext,
  expected:Expr,
  elaborate:MatchTermElaborator,
):Expr {
  const pattern=alternative.pattern;
  if(pattern.kind!=='constructor')throw new Error('unreachable');
  const constructor=context.environment.find(constructorName);
  if(constructor?.kind!=='constructor'){
    throw new Error(
      "PS_ELAB_MATCH_CONSTRUCTOR: unknown constructor '"+
      nameToString(constructorName)+"'",
    );
  }
  if(pattern.binders.length!==constructor.numFields){
    throw new Error(
      "PS_ELAB_MATCH_ARITY: constructor '"+
      nameToString(constructorName)+"' binds "+
      constructor.numFields+' fields, got '+pattern.binders.length,
    );
  }

  let cursor=constructor.type;
  let branchContext=context;
  const fields:{
    readonly id:string;
    readonly name:Name;
    readonly type:Expr;
    readonly binderInfo:import('lean-ts-kernel').BinderInfo;
  }[]=[];

  for(let index=0;index<constructor.numFields;index+=1){
    const checker=new TypeChecker(
      context.environment,
      branchContext.localContext.clone(),
    );
    const binder=checker.ensureForall(checker.whnf(cursor));
    const sourceName=pattern.binders[index]!;
    if(branchContext.locals.has(sourceName)){
      throw new Error(
        "PS_ELAB_MATCH_BINDER_DUPLICATE: '"+sourceName+"'",
      );
    }

    const localContext=branchContext.localContext.clone();
    const id=localContext.fresh(sourceName);
    const userName=nameFromDotted(sourceName);
    localContext.addLocal(
      id,
      userName,
      binder.type,
      binder.binderInfo,
    );
    const locals=new Map(branchContext.locals);
    locals.set(sourceName,id);
    branchContext={...branchContext,localContext,locals};
    fields.push({
      id,
      name:userName,
      type:binder.type,
      binderInfo:binder.binderInfo,
    });
    cursor=instantiate1(binder.body,fvar(id));
  }

  const branch=elaborate(
    alternative.body,
    branchContext,
    expected,
  );
  let minor=branch.term;
  for(let index=fields.length-1;index>=0;index-=1){
    const field=fields[index]!;
    minor=lam(
      field.name,
      field.type,
      abstractFVar(minor,field.id),
      field.binderInfo,
    );
  }
  return minor;
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
  if(typeView.fn.kind!=='const'||typeView.args.length!==0){
    throw new Error(
      'PS_ELAB_MATCH_SCRUTINEE: current verified match requires an unparameterized inductive',
    );
  }

  const inductive=context.environment.find(typeView.fn.name);
  if(
    inductive?.kind!=='inductive'
    ||inductive.numParams!==0
    ||inductive.numIndices!==0
    ||inductive.isRec
  ){
    throw new Error(
      'PS_ELAB_MATCH_INDUCTIVE_UNSUPPORTED: verified match currently supports only unparameterized, unindexed, non-recursive inductives',
    );
  }

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
    return elaborateMinor(
      alternative,
      constructor,
      context,
      expected,
      elaborate,
    );
  });

  const recursorName=strName(inductive.name,'rec');
  const recursor=context.environment.find(recursorName);
  if(
    recursor?.kind!=='recursor'
    ||recursor.numParams!==0
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

  const term=mkAppN(
    constant(recursorName,levels),
    [motive,...minors,scrutinee.term],
  );
  const type=checker.check(term);
  if(!checker.isDefEq(type,expected)){
    throw new Error(
      'PS_ELAB_MATCH_RESULT_TYPE: generated recursor application does not match expected type',
    );
  }
  return {term,type};
}
