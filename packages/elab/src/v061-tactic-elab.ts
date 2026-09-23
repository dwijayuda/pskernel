import {
  assumption,
  exact,
  getMainGoal,
  intro,
  type TacticGoal,
} from '@proofscript/tactic';
import type {V061Expr,V061Tactic} from '@proofscript/syntax';
import {
  TypeChecker,
  type Expr,
  abstractFVar,
  fvar,
  instantiate1,
  lam,
  nameFromDotted,
} from 'lean-ts-kernel';
import type {
  ElaboratedCoreTerm,
  V061CoreElabContext,
} from './v061-context.js';
import {applyV061Tactic} from './v061-apply-tactic.js';
import {refineV061Tactic} from './v061-refine-tactic.js';
import {V061TacticRuntime} from './v061-tactic-runtime.js';

export type V061TermElaborator=(
  expr:V061Expr,
  context:V061CoreElabContext,
  expected?:Expr,
)=>ElaboratedCoreTerm;

function currentGoal(
  runtime:V061TacticRuntime,
):TacticGoal<Expr> {
  try{
    return getMainGoal(runtime.state);
  }catch{
    throw new Error('PS_ELAB_TACTIC_NO_GOALS: no goals to be solved');
  }
}

function runTactic(
  tactic:V061Tactic,
  runtime:V061TacticRuntime,
  elaborate:V061TermElaborator,
):void {
  const goal=currentGoal(runtime);
  const entry=runtime.entry(goal);

  if(tactic.kind==='exact'){
    const proof=elaborate(
      tactic.proof,
      entry.context,
      runtime.expected(goal),
    );
    try{
      runtime.state=exact(runtime.state,proof.term,runtime.kernel);
    }catch(error){
      throw new Error(
        'PS_ELAB_TACTIC_EXACT: '+
        (error instanceof Error?error.message:String(error)),
      );
    }
    return;
  }

  if(tactic.kind==='assumption'){
    try{
      runtime.state=assumption(runtime.state,runtime.kernel);
    }catch(error){
      throw new Error(
        'PS_ELAB_TACTIC_ASSUMPTION: '+
        (error instanceof Error?error.message:String(error)),
      );
    }
    return;
  }

  if(tactic.kind==='apply'){
    const candidate=elaborate(tactic.proof,entry.context);
    applyV061Tactic(runtime,candidate);
    return;
  }

  if(tactic.kind==='refine'){
    refineV061Tactic(runtime,tactic.proof,elaborate);
    return;
  }

  runtime.state=intro(
    runtime.state,
    tactic.name,
    {
      intro:(parentGoal,userName)=>{
        const parent=runtime.entry(parentGoal);
        const checker=new TypeChecker(
          parent.context.environment,
          parent.context.localContext.clone(),
        );
        const functionType=checker.whnf(
          parent.context.metaContext.instantiate(parentGoal.target),
        );
        if(functionType.kind!=='forall')return undefined;

        const nextLocalContext=parent.context.localContext.clone();
        const id=nextLocalContext.fresh(userName);
        const leanName=nameFromDotted(userName);
        nextLocalContext.addLocal(
          id,
          leanName,
          functionType.type,
          functionType.binderInfo,
        );
        const locals=new Map(parent.context.locals);
        locals.set(userName,id);
        const nextContext={
          ...parent.context,
          localContext:nextLocalContext,
          locals,
        };
        const nextExpected=instantiate1(functionType.body,fvar(id));

        return runtime.createGoal(
          nextContext,
          nextExpected,
          (body)=>{
            const term=lam(
              leanName,
              functionType.type,
              abstractFVar(body.term,id),
              functionType.binderInfo,
            );
            const type=checker.check(term);
            if(
              !checker.isDefEq(
                parent.context.metaContext.instantiate(type),
                parent.context.metaContext.instantiate(parentGoal.target),
              )
            ){
              throw new Error(
                'PS_ELAB_TACTIC_INTRO: generated lambda does not match the goal',
              );
            }
            runtime.completeGoal(parentGoal,{term,type});
          },
        );
      },
    },
  );
}

export function elaborateV061ByExpression(
  expr:Extract<V061Expr,{kind:'by'}>,
  context:V061CoreElabContext,
  expected:Expr|undefined,
  elaborate:V061TermElaborator,
):ElaboratedCoreTerm {
  if(expected===undefined){
    throw new Error(
      'PS_ELAB_TACTIC_EXPECTED_TYPE: tactic blocks require an expected goal type',
    );
  }

  const runtime=new V061TacticRuntime(context,expected);
  for(const tactic of expr.tactics){
    runTactic(tactic,runtime,elaborate);
  }
  return runtime.result();
}
