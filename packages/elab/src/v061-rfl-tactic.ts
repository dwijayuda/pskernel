import {
  getMainGoal,
  replaceMainGoal,
  type TacticGoal,
} from '@proofscript/tactic';
import {
  TypeChecker,
  appView,
  constant,
  mkAppN,
  nameEq,
  nameFromDotted,
  type Expr,
} from 'lean-ts-kernel';
import {V061TacticRuntime} from './v061-tactic-runtime.js';

export function tryCompleteV061EqRfl(
  runtime:V061TacticRuntime,
  goal:TacticGoal<Expr>,
):boolean {
  const entry=runtime.entry(goal);
  const checker=new TypeChecker(
    entry.context.environment,
    entry.context.localContext.clone(),
  );
  const target=checker.whnf(runtime.expected(goal));
  const view=appView(target);
  if(
    view.fn.kind!=='const'
    ||!nameEq(view.fn.name,nameFromDotted('Eq'))
    ||view.args.length!==3
  )return false;

  const alpha=view.args[0]!;
  const lhs=view.args[1]!;
  const rhs=view.args[2]!;
  if(!checker.isDefEq(lhs,rhs))return false;

  const reflName=nameFromDotted('Eq.refl');
  const reflInfo=entry.context.environment.find(reflName);
  if(reflInfo===undefined||reflInfo.levelParams.length!==1)return false;
  const alphaLevel=checker.ensureSort(
    checker.check(alpha),
    alpha,
  ).level;
  const term=mkAppN(
    constant(reflName,[alphaLevel]),
    [alpha,lhs],
  );
  const type=checker.check(term);
  if(!checker.isDefEq(type,target))return false;
  runtime.completeGoal(goal,{term,type});
  return true;
}

export function tryCloseV061EqRfl(
  runtime:V061TacticRuntime,
):boolean {
  if(runtime.state.goals.length===0)return true;
  const goal=getMainGoal(runtime.state);
  if(!tryCompleteV061EqRfl(runtime,goal))return false;
  runtime.state=replaceMainGoal(runtime.state,[]);
  return true;
}

export function rflV061Tactic(
  runtime:V061TacticRuntime,
):void {
  if(tryCloseV061EqRfl(runtime))return;
  throw new Error(
    'PS_ELAB_TACTIC_RFL: bounded rfl requires an Eq goal whose sides are definitionally equal',
  );
}
