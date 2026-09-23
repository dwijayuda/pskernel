import {
  exact,
  type TacticGoal,
} from '@proofscript/tactic';
import {
  constant,
  type Expr,
} from 'lean-ts-kernel';
import {V061TacticRuntime} from './v061-tactic-runtime.js';

const MAX_BOUNDED_EXACT_SEARCH_CANDIDATES=4096;

function candidateMatches(
  runtime:V061TacticRuntime,
  goal:TacticGoal<Expr>,
  term:Expr,
):boolean {
  try{
    return runtime.kernel.isDefEq(
      runtime.kernel.inferType(term,goal),
      goal.target,
      goal,
    );
  }catch{
    return false;
  }
}

function closeWithCandidate(
  runtime:V061TacticRuntime,
  term:Expr,
):void {
  runtime.state=exact(
    runtime.state,
    term,
    runtime.kernel,
  );
}

export function exactSearchV061Tactic(
  runtime:V061TacticRuntime,
):void {
  const goal=runtime.state.goals[0];
  if(goal===undefined){
    throw new Error('PS_ELAB_TACTIC_EXACT_SEARCH: no goal');
  }

  for(let index=goal.locals.length-1;index>=0;index-=1){
    const local=goal.locals[index]!;
    if(
      local.value!==undefined
      &&candidateMatches(runtime,goal,local.value)
    ){
      closeWithCandidate(runtime,local.value);
      return;
    }
  }

  const entry=runtime.entry(goal);
  const constants=entry.context.environment.entries();
  let visited=0;

  for(let index=constants.length-1;index>=0;index-=1){
    const info=constants[index]!;
    if(info.levelParams.length!==0)continue;
    visited+=1;
    if(visited>MAX_BOUNDED_EXACT_SEARCH_CANDIDATES){
      throw new Error(
        'PS_ELAB_TACTIC_EXACT_SEARCH_FUEL: bounded exact? exceeded '+
        String(MAX_BOUNDED_EXACT_SEARCH_CANDIDATES)+
        ' zero-universe candidates',
      );
    }

    const candidate=constant(info.name);
    if(!candidateMatches(runtime,goal,candidate))continue;
    closeWithCandidate(runtime,candidate);
    return;
  }

  throw new Error(
    'PS_ELAB_TACTIC_EXACT_SEARCH: bounded exact? found no '+
    'zero-subgoal local/environment candidate',
  );
}
