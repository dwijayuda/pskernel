export interface LocalHypothesis<Term> {
  readonly name:string;
  readonly type:Term;
  readonly value?:Term;
}

export interface TacticGoal<Term> {
  readonly id:string;
  readonly target:Term;
  readonly locals:readonly LocalHypothesis<Term>[];
}

export interface TacticState<Term> {
  readonly goals:readonly TacticGoal<Term>[];
}

export function getMainGoal<Term>(
  state:TacticState<Term>,
):TacticGoal<Term> {
  const goal=state.goals[0];
  if(goal===undefined)throw new Error('no goals');
  return goal;
}

export function replaceMainGoal<Term>(
  state:TacticState<Term>,
  replacements:readonly TacticGoal<Term>[],
):TacticState<Term> {
  getMainGoal(state);
  return {
    goals:[
      ...replacements,
      ...state.goals.slice(1),
    ],
  };
}
