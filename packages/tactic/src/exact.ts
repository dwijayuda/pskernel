import {
  getMainGoal,
  replaceMainGoal,
  type TacticGoal,
  type TacticState,
} from './state.js';

export interface TacticKernel<Term> {
  inferType(term:Term,goal:TacticGoal<Term>):Term;
  isDefEq(left:Term,right:Term,goal:TacticGoal<Term>):boolean;
  assign(goal:TacticGoal<Term>,proof:Term):void;
}

export function exact<Term>(
  state:TacticState<Term>,
  proof:Term,
  kernel:TacticKernel<Term>,
):TacticState<Term> {
  const goal=getMainGoal(state);
  if(!kernel.isDefEq(kernel.inferType(proof,goal),goal.target,goal)){
    throw new Error('exact: proof type does not match target');
  }
  kernel.assign(goal,proof);
  return replaceMainGoal(state,[]);
}

export function assumption<Term>(
  state:TacticState<Term>,
  kernel:TacticKernel<Term>,
):TacticState<Term> {
  const goal=getMainGoal(state);
  for(let index=goal.locals.length-1;index>=0;index-=1){
    const local=goal.locals[index]!;
    if(
      local.value!==undefined
      &&kernel.isDefEq(local.type,goal.target,goal)
    ){
      kernel.assign(goal,local.value);
      return replaceMainGoal(state,[]);
    }
  }
  throw new Error('assumption: no matching local hypothesis');
}
