import {
  getMainGoal,
  replaceMainGoal,
} from '@proofscript/tactic';
import {
  TypeChecker,
  abstractFVar,
  appView,
  constant,
  fvar,
  instantiate1,
  lam,
  mkAppN,
  nameFromDotted,
  nameToString,
  strName,
  type BinderInfo,
  type Expr,
  type Name,
} from 'lean-ts-kernel';
import type {
  ElaboratedCoreTerm,
  V061CoreElabContext,
} from './v061-context.js';
import {assertCasesContextIndependent} from './v061-cases-context.js';
import {V061TacticRuntime} from './v061-tactic-runtime.js';

interface CaseField {
  readonly id:string;
  readonly name:Name;
  readonly type:Expr;
  readonly binderInfo:BinderInfo;
}

interface CaseBranch {
  readonly fields:readonly CaseField[];
  readonly context:V061CoreElabContext;
  readonly target:Expr;
}

function recursorLevels(
  checker:TypeChecker,
  target:Expr,
  levelParams:readonly Name[],
):readonly import('lean-ts-kernel').Level[] {
  const resultSort=checker.ensureSort(
    checker.check(target),
    target,
  ).level;
  if(levelParams.length===0)return [];
  if(levelParams.length===1)return [resultSort];
  throw new Error(
    'PS_ELAB_TACTIC_CASES_RECURSOR_LEVELS: multi-universe recursor unsupported',
  );
}

function branchForConstructor(
  branchIndex:number,
  constructorName:Name,
  parameterArgs:readonly Expr[],
  constructorLevels:readonly import('lean-ts-kernel').Level[],
  majorName:string,
  motiveBody:Expr,
  baseContext:V061CoreElabContext,
):CaseBranch {
  const constructor=baseContext.environment.find(constructorName);
  if(constructor?.kind!=='constructor'){
    throw new Error(
      "PS_ELAB_TACTIC_CASES_CONSTRUCTOR: unknown constructor '"+
      nameToString(constructorName)+"'",
    );
  }
  if(constructor.numParams!==parameterArgs.length){
    throw new Error(
      'PS_ELAB_TACTIC_CASES_PARAMETER_ARITY: constructor parameter mismatch',
    );
  }

  const branchLocals=new Map(baseContext.locals);
  branchLocals.delete(majorName);
  let branchContext:V061CoreElabContext={
    ...baseContext,
    localContext:baseContext.localContext.clone(),
    locals:branchLocals,
  };

  let cursor=constructor.type;
  for(const parameter of parameterArgs){
    const checker=new TypeChecker(
      branchContext.environment,
      branchContext.localContext.clone(),
    );
    const binder=checker.ensureForall(checker.whnf(cursor));
    cursor=instantiate1(binder.body,parameter);
  }

  const fields:CaseField[]=[];
  const fieldTerms:Expr[]=[];
  for(let index=0;index<constructor.numFields;index+=1){
    const checker=new TypeChecker(
      branchContext.environment,
      branchContext.localContext.clone(),
    );
    const binder=checker.ensureForall(checker.whnf(cursor));
    let sourceName='_case_'+branchIndex+'_'+index;
    while(branchContext.locals.has(sourceName))sourceName+='x';

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

    const term=fvar(id);
    fields.push({
      id,
      name:userName,
      type:binder.type,
      binderInfo:binder.binderInfo,
    });
    fieldTerms.push(term);
    cursor=instantiate1(binder.body,term);
  }

  const constructorTerm=mkAppN(
    constant(constructorName,constructorLevels),
    [...parameterArgs,...fieldTerms],
  );
  return {
    fields,
    context:branchContext,
    target:instantiate1(motiveBody,constructorTerm),
  };
}

function abstractBranch(
  proof:ElaboratedCoreTerm,
  fields:readonly CaseField[],
):Expr {
  let result=proof.term;
  for(let index=fields.length-1;index>=0;index-=1){
    const field=fields[index]!;
    result=lam(
      field.name,
      field.type,
      abstractFVar(result,field.id),
      field.binderInfo,
    );
  }
  return result;
}

export function casesV061Tactic(
  runtime:V061TacticRuntime,
  sourceName:string,
):void {
  const goal=getMainGoal(runtime.state);
  const entry=runtime.entry(goal);
  const majorId=entry.context.locals.get(sourceName);
  if(majorId===undefined){
    throw new Error(
      "PS_ELAB_TACTIC_CASES_UNKNOWN: unknown local '"+sourceName+"'",
    );
  }
  const majorDecl=entry.context.localContext.get(majorId);
  if(majorDecl===undefined){
    throw new Error(
      "PS_ELAB_TACTIC_CASES_UNKNOWN: missing local '"+sourceName+"'",
    );
  }
  if(majorDecl.kind!=='local'){
    throw new Error(
      'PS_ELAB_TACTIC_CASES_UNSUPPORTED: cases on local let bindings is not yet supported',
    );
  }
  assertCasesContextIndependent(entry.context,majorId);

  const checker=new TypeChecker(
    entry.context.environment,
    entry.context.localContext.clone(),
  );
  const majorType=checker.whnf(majorDecl.type);
  const typeView=appView(majorType);
  if(typeView.fn.kind!=='const'){
    throw new Error(
      'PS_ELAB_TACTIC_CASES_TARGET: local is not an inductive datatype',
    );
  }
  const inductive=entry.context.environment.find(typeView.fn.name);
  if(
    inductive?.kind!=='inductive'
    ||inductive.numIndices!==0
    ||inductive.isRec
  ){
    throw new Error(
      'PS_ELAB_TACTIC_CASES_UNSUPPORTED: cases currently requires '+
      'an unindexed, non-recursive inductive',
    );
  }
  if(typeView.args.length!==inductive.numParams){
    throw new Error(
      'PS_ELAB_TACTIC_CASES_PARAMETER_ARITY: inductive parameter mismatch',
    );
  }

  const parameterArgs=typeView.args.slice(0,inductive.numParams);
  const target=runtime.expected(goal);
  const motiveBody=abstractFVar(target,majorId);
  const motive=lam(
    nameFromDotted('_cases'),
    majorType,
    motiveBody,
  );

  const recursorName=strName(inductive.name,'rec');
  const recursor=entry.context.environment.find(recursorName);
  if(
    recursor?.kind!=='recursor'
    ||recursor.numParams!==inductive.numParams
    ||recursor.numIndices!==0
    ||recursor.numMotives!==1
    ||recursor.numMinors!==inductive.ctors.length
  ){
    throw new Error(
      "PS_ELAB_TACTIC_CASES_RECURSOR: unsupported recursor for '"+
      nameToString(inductive.name)+"'",
    );
  }

  const branches=inductive.ctors.map((ctor,index)=>
    branchForConstructor(
      index,
      ctor,
      parameterArgs,
      typeView.fn.kind==='const'?typeView.fn.levels:[],
      sourceName,
      motiveBody,
      entry.context,
    )
  );
  const proofs:(ElaboratedCoreTerm|undefined)[]=branches.map(()=>undefined);

  const finalize=():void=>{
    if(proofs.some((proof)=>proof===undefined))return;
    const minors=branches.map((branch,index)=>
      abstractBranch(proofs[index]!,branch.fields)
    );
    const term=mkAppN(
      constant(
        recursorName,
        recursorLevels(checker,target,recursor.levelParams),
      ),
      [...parameterArgs,motive,...minors,fvar(majorId)],
    );
    const type=checker.check(term);
    if(!checker.isDefEq(type,target)){
      throw new Error(
        'PS_ELAB_TACTIC_CASES_RESULT: recursor proof does not match the goal',
      );
    }
    runtime.completeGoal(goal,{term,type});
  };

  const caseGoals=branches.map((branch,index)=>
    runtime.createGoal(
      branch.context,
      branch.target,
      (proof)=>{
        proofs[index]=proof;
        finalize();
      },
    )
  );
  runtime.state=replaceMainGoal(runtime.state,caseGoals);
  if(caseGoals.length===0)finalize();
}
