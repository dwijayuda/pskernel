import {
  assumption,
  exact,
} from '@proofscript/tactic';
import {
  constant,
  type Expr,
} from 'lean-ts-kernel';
import {V061TacticRuntime} from './v061-tactic-runtime.js';

const MAX_BOUNDED_EXACT_SEARCH_CANDIDATES=4096;

export function exactSearchV061Tactic(
  runtime:V061TacticRuntime,
):void {
  try{
    runtime.state=assumption(runtime.state,runtime.kernel);
    return;
  }catch{
    // Continue with already-admitted environment constants.
  }

  const goal=runtime.state.goals[0];
  if(goal===undefined){
    throw new Error('PS_ELAB_TACTIC_EXACT_SEARCH: no goal');
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

    try{
      runtime.state=exact(
        runtime.state,
        constant(info.name),
        runtime.kernel,
      );
      return;
    }catch{
      // A failed exact candidate cannot mutate the goal state.
    }
  }

  throw new Error(
    'PS_ELAB_TACTIC_EXACT_SEARCH: bounded exact? found no '+
    'zero-subgoal local/environment candidate',
  );
}
