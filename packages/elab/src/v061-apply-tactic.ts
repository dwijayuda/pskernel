import {
  apply as applyTransition,
  type TacticGoal,
} from '@proofscript/tactic';
import {
  TypeChecker,
  hasMVar,
  instantiate1,
  mkAppN,
  type Expr,
} from 'lean-ts-kernel';
import type {ElaboratedCoreTerm} from './v061-context.js';
import {V061TacticRuntime} from './v061-tactic-runtime.js';

const MAX_BOUNDED_APPLY_ARGUMENTS=64;

export function applyV061Tactic(
  runtime:V061TacticRuntime,
  candidate:ElaboratedCoreTerm,
):void {
  runtime.state=applyTransition(
    runtime.state,
    candidate.term,
    {
      apply:(goal)=>prepareApplyGoals(runtime,goal,candidate),
    },
  );
}

function prepareApplyGoals(
  runtime:V061TacticRuntime,
  goal:TacticGoal<Expr>,
  candidate:ElaboratedCoreTerm,
):readonly TacticGoal<Expr>[] {
  const parent=runtime.entry(goal);
  const context=parent.context;
  const meta=context.metaContext;
  const checker=new TypeChecker(
    context.environment,
    context.localContext.clone(),
  );
  const target=runtime.expected(goal);
  const args:Expr[]=[];
  const placeholders:Expr[]=[];
  let currentType=meta.instantiate(candidate.type);
  let matched=false;

  for(let index=0;index<=MAX_BOUNDED_APPLY_ARGUMENTS;index+=1){
    if(meta.unify(currentType,target,context.localContext)){
      matched=true;
      break;
    }
    if(index===MAX_BOUNDED_APPLY_ARGUMENTS)break;

    const reduced=checker.whnf(meta.instantiate(currentType));
    if(reduced.kind!=='forall')break;
    if(reduced.binderInfo!=='default'){
      throw new Error(
        'PS_ELAB_TACTIC_APPLY: bounded multi-goal apply currently '+
        'supports explicit binders only',
      );
    }

    const placeholder=meta.mkFresh(
      meta.instantiate(reduced.type),
      context.localContext,
      'natural',
    );
    placeholders.push(placeholder);
    args.push(placeholder);
    currentType=instantiate1(reduced.body,placeholder);
  }

  if(!matched){
    throw new Error(
      'PS_ELAB_TACTIC_APPLY: candidate conclusion does not match the goal',
    );
  }

  const open=placeholders.filter(
    (placeholder)=>!meta.isAssigned(placeholder),
  );

  const finalize=():void=>{
    if(open.some((placeholder)=>!meta.isAssigned(placeholder)))return;
    const term=meta.instantiate(mkAppN(candidate.term,args));
    if(hasMVar(term)){
      throw new Error(
        'PS_ELAB_TACTIC_APPLY: candidate leaves unresolved metavariables',
      );
    }
    const type=checker.check(term);
    if(!checker.isDefEq(type,target)){
      throw new Error(
        'PS_ELAB_TACTIC_APPLY: constructed proof does not match the goal',
      );
    }
    runtime.completeGoal(goal,{term,type});
  };

  if(open.length===0){
    finalize();
    return [];
  }

  return open.map((placeholder)=>{
    const declaration=meta.getDecl(placeholder);
    return runtime.createGoal(
      context,
      declaration.type,
      (proof)=>{
        meta.assign(placeholder,proof.term);
        finalize();
      },
    );
  });
}
