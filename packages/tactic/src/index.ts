export interface LocalHypothesis<Term> { readonly name:string; readonly type:Term; readonly value?:Term; }
export interface TacticGoal<Term> { readonly target:Term; readonly locals:readonly LocalHypothesis<Term>[]; }
export interface TacticState<Term> { readonly goals:readonly TacticGoal<Term>[]; readonly proofs:readonly Term[]; }
export interface TacticKernel<Term> {
  inferType(term:Term):Term;
  isDefEq(left:Term,right:Term):boolean;
}
export interface IntroAdapter<Term> {
  intro(target:Term):{readonly name:string;readonly type:Term;readonly body:Term}|undefined;
}
function replaceFirst<Term>(state:TacticState<Term>,goals:readonly TacticGoal<Term>[],proof?:Term):TacticState<Term>{
  return {goals,proofs:proof===undefined?[...state.proofs]:[...state.proofs,proof]};
}
export function exact<Term>(state:TacticState<Term>,proof:Term,kernel:TacticKernel<Term>):TacticState<Term>{
  const goal=state.goals[0];
  if(goal===undefined)throw new Error('no goals');
  if(!kernel.isDefEq(kernel.inferType(proof),goal.target))throw new Error('exact: proof type does not match target');
  return replaceFirst(state,state.goals.slice(1),proof);
}
export function assumption<Term>(state:TacticState<Term>,kernel:TacticKernel<Term>):TacticState<Term>{
  const goal=state.goals[0];
  if(goal===undefined)throw new Error('no goals');
  const local=goal.locals.find(h=>h.value!==undefined&&kernel.isDefEq(h.type,goal.target));
  if(local?.value===undefined)throw new Error('assumption: no matching local hypothesis');
  return replaceFirst(state,state.goals.slice(1),local.value);
}
export function intro<Term>(state:TacticState<Term>,adapter:IntroAdapter<Term>):TacticState<Term>{
  const goal=state.goals[0];
  if(goal===undefined)throw new Error('no goals');
  const introduced=adapter.intro(goal.target);
  if(introduced===undefined)throw new Error('intro: target is not a function type');
  const next:TacticGoal<Term>={target:introduced.body,locals:[...goal.locals,{name:introduced.name,type:introduced.type}]};
  return replaceFirst(state,[next,...state.goals.slice(1)]);
}
