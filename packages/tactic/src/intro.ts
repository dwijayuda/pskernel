import {
  getMainGoal,
  replaceMainGoal,
  type TacticGoal,
  type TacticState,
} from './state.js';

export interface IntroAdapter<Term> {
  /**
   * Introduce one binder from the goal.
   *
   * The adapter owns proof/metavariable assignment for the parent goal and
   * returns the single child goal. Returning undefined means the target is
   * not introducible.
   */
  intro(
    goal:TacticGoal<Term>,
    userName:string,
  ):TacticGoal<Term>|undefined;
}

export function intro<Term>(
  state:TacticState<Term>,
  userName:string,
  adapter:IntroAdapter<Term>,
):TacticState<Term> {
  const goal=getMainGoal(state);
  const next=adapter.intro(goal,userName);
  if(next===undefined){
    throw new Error('intro: target is not a function type');
  }
  return replaceMainGoal(state,[next]);
}
