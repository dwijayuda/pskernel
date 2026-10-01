import type {
  LocalHypothesis,
  TacticGoal,
  TacticKernel,
  TacticState,
} from '@proofscript/tactic';
import {
  TypeChecker,
  fvar,
  type Expr,
} from 'lean-ts-kernel';
import type {
  ElaboratedCoreTerm,
  V061CoreElabContext,
} from './v061-context.js';

interface GoalEntry {
  readonly goal:TacticGoal<Expr>;
  readonly context:V061CoreElabContext;
  readonly complete:(proof:ElaboratedCoreTerm)=>void;
}

export class V061TacticRuntime {
  private nextGoal=0;
  private readonly entries=new Map<string,GoalEntry>();
  private rootResult:ElaboratedCoreTerm|undefined;
  state:TacticState<Expr>;

  constructor(
    context:V061CoreElabContext,
    expected:Expr,
  ){
    const root=this.createGoal(
      context,
      expected,
      (proof)=>{this.rootResult=proof;},
    );
    this.state={goals:[root]};
  }

  private locals(
    context:V061CoreElabContext,
  ):readonly LocalHypothesis<Expr>[] {
    const locals:LocalHypothesis<Expr>[]=[];
    for(const [name,id] of context.locals){
      const declaration=context.localContext.get(id);
      if(declaration===undefined)continue;
      locals.push({
        name,
        type:declaration.type,
        value:fvar(id),
      });
    }
    return locals;
  }

  createGoal(
    context:V061CoreElabContext,
    target:Expr,
    complete:(proof:ElaboratedCoreTerm)=>void,
  ):TacticGoal<Expr> {
    const goal:TacticGoal<Expr>={
      id:'tactic.'+this.nextGoal++,
      target,
      locals:this.locals(context),
    };
    this.entries.set(goal.id,{goal,context,complete});
    return goal;
  }

  entry(goal:TacticGoal<Expr>):GoalEntry {
    const entry=this.entries.get(goal.id);
    if(entry===undefined){
      throw new Error(
        "PS_ELAB_TACTIC_GOAL_STATE: unknown tactic goal '"+goal.id+"'",
      );
    }
    return entry;
  }

  checker(goal:TacticGoal<Expr>):TypeChecker {
    const entry=this.entry(goal);
    return new TypeChecker(
      entry.context.environment,
      entry.context.localContext.clone(),
    );
  }

  expected(goal:TacticGoal<Expr>):Expr {
    const entry=this.entry(goal);
    return entry.context.metaContext.instantiate(goal.target);
  }

  completeGoal(
    goal:TacticGoal<Expr>,
    proof:ElaboratedCoreTerm,
  ):void {
    const entry=this.entry(goal);
    this.entries.delete(goal.id);
    entry.complete(proof);
  }

  readonly kernel:TacticKernel<Expr>={
    inferType:(term,goal)=>{
      const entry=this.entry(goal);
      return this.checker(goal).check(
        entry.context.metaContext.instantiate(term),
      );
    },
    isDefEq:(left,right,goal)=>{
      const entry=this.entry(goal);
      const meta=entry.context.metaContext;
      return this.checker(goal).isDefEq(
        meta.instantiate(left),
        meta.instantiate(right),
      );
    },
    assign:(goal,proof)=>{
      const entry=this.entry(goal);
      const checker=this.checker(goal);
      const term=entry.context.metaContext.instantiate(proof);
      const type=checker.check(term);
      if(!checker.isDefEq(type,this.expected(goal))){
        throw new Error('tactic assignment does not match goal target');
      }
      this.completeGoal(goal,{term,type});
    },
  };

  result():ElaboratedCoreTerm {
    if(this.state.goals.length!==0){
      throw new Error(
        'PS_ELAB_TACTIC_UNSOLVED_GOALS: '+
        String(this.state.goals.length)+' goal(s) remain',
      );
    }
    if(this.rootResult===undefined){
      throw new Error(
        'PS_ELAB_TACTIC_GOAL_STATE: tactic state closed without a root proof',
      );
    }
    return this.rootResult;
  }
}
