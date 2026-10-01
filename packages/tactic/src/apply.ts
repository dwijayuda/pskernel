import {
  getMainGoal,
  replaceMainGoal,
  type TacticGoal,
  type TacticState,
} from './state.js';

export interface ApplyAdapter<Term> {
  /**
   * Apply candidate to the main goal.
   *
   * The adapter owns all semantic work: elaboration/unification, creation of
   * fresh metavariables, assignment of the parent goal, and filtering solved
   * metavariables. The returned goals are the remaining ordered subgoals.
   */
  apply(
    goal:TacticGoal<Term>,
    candidate:Term,
  ):readonly TacticGoal<Term>[];
}

export function apply<Term>(
  state:TacticState<Term>,
  candidate:Term,
  adapter:ApplyAdapter<Term>,
):TacticState<Term> {
  const goal=getMainGoal(state);
  return replaceMainGoal(state,adapter.apply(goal,candidate));
}
