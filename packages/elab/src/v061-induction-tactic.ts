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
  lam,
  mkAppN,
  nameFromDotted,
  nameToString,
  strName,
  type Expr,
  type Name,
} from 'lean-ts-kernel';
import {
  abstractV061InductionBranch,
  buildV061InductionBranch,
} from './v061-induction-branch.js';
import {assertInductionContextIndependent} from './v061-cases-context.js';
import type {ElaboratedCoreTerm} from './v061-context.js';
import {V061TacticRuntime} from './v061-tactic-runtime.js';

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
    'PS_ELAB_TACTIC_INDUCTION_RECURSOR_LEVELS: multi-universe recursor unsupported',
  );
}

export function inductionV061Tactic(
  runtime:V061TacticRuntime,
  sourceName:string,
):void {
  const goal=getMainGoal(runtime.state);
  const entry=runtime.entry(goal);
  const majorId=entry.context.locals.get(sourceName);
  if(majorId===undefined){
    throw new Error(
      "PS_ELAB_TACTIC_INDUCTION_UNKNOWN: unknown local '"+sourceName+"'",
    );
  }
  const majorDecl=entry.context.localContext.get(majorId);
  if(majorDecl?.kind!=='local'){
    throw new Error(
      'PS_ELAB_TACTIC_INDUCTION_UNSUPPORTED: induction requires a local variable',
    );
  }
  assertInductionContextIndependent(entry.context,majorId);

  const checker=new TypeChecker(
    entry.context.environment,
    entry.context.localContext.clone(),
  );
  const majorType=checker.whnf(majorDecl.type);
  const typeView=appView(majorType);
  if(typeView.fn.kind!=='const'){
    throw new Error(
      'PS_ELAB_TACTIC_INDUCTION_TARGET: local is not an inductive datatype',
    );
  }
  const inductive=entry.context.environment.find(typeView.fn.name);
  if(
    inductive?.kind!=='inductive'
    ||inductive.numIndices!==0
  ){
    throw new Error(
      'PS_ELAB_TACTIC_INDUCTION_UNSUPPORTED: induction currently requires '+
      'an unindexed inductive',
    );
  }
  if(typeView.args.length!==inductive.numParams){
    throw new Error(
      'PS_ELAB_TACTIC_INDUCTION_PARAMETER_ARITY: inductive parameter mismatch',
    );
  }

  const parameterArgs=typeView.args.slice(0,inductive.numParams);
  const target=runtime.expected(goal);
  const motiveBody=abstractFVar(target,majorId);
  const motive=lam(
    nameFromDotted('_induction'),
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
      "PS_ELAB_TACTIC_INDUCTION_RECURSOR: unsupported recursor for '"+
      nameToString(inductive.name)+"'",
    );
  }

  const branches=inductive.ctors.map((ctor,index)=>
    buildV061InductionBranch(
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
      abstractV061InductionBranch(proofs[index]!,branch)
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
        'PS_ELAB_TACTIC_INDUCTION_RESULT: recursor proof does not match the goal',
      );
    }
    runtime.completeGoal(goal,{term,type});
  };

  const branchGoals=branches.map((branch,index)=>
    runtime.createGoal(
      branch.context,
      branch.target,
      (proof)=>{
        proofs[index]=proof;
        finalize();
      },
    )
  );
  runtime.state=replaceMainGoal(runtime.state,branchGoals);
  if(branchGoals.length===0)finalize();
}
