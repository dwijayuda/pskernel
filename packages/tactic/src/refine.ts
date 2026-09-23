import {
  getMainGoal,
  replaceMainGoal,
  type TacticGoal,
  type TacticState,
} from './state.js';

export interface RefineAdapter<Term> {
  /**
   * Refine the main goal with a partial proof term.
   *
   * The adapter owns term elaboration/metavariable assignment. The returned
   * goals are exactly the remaining ordered holes in the partial proof.
   */
  refine(
    goal:TacticGoal<Term>,
    candidate:Term,
  ):readonly TacticGoal<Term>[];
}

export function refine<Term>(
  state:TacticState<Term>,
  candidate:Term,
  adapter:RefineAdapter<Term>,
):TacticState<Term> {
  const goal=getMainGoal(state);
  return replaceMainGoal(state,adapter.refine(goal,candidate));
}
