import {getMainGoal} from '@proofscript/tactic';
import type {V061Expr} from '@proofscript/syntax';
import {TypeChecker} from 'lean-ts-kernel';
import {rewriteExprSize} from './v061-rewrite-occurrence.js';
import {
  equalityView,
  rewriteV061Equality,
  tryCloseV061CheapEqRfl,
} from './v061-rewrite-tactic.js';
import type {V061TermElaborator} from './v061-tactic-elab.js';
import {V061TacticRuntime} from './v061-tactic-runtime.js';

const MAX_BOUNDED_SIMP_STEPS=64;

export function simpOnlyV061Tactic(
  runtime:V061TacticRuntime,
  proofExpr:V061Expr,
  symm:boolean,
  elaborate:V061TermElaborator,
):void {
  const goal=getMainGoal(runtime.state);
  const entry=runtime.entry(goal);
  const checker=new TypeChecker(
    entry.context.environment,
    entry.context.localContext.clone(),
  );
  const equality=elaborate(proofExpr,entry.context);
  const rule=equalityView(
    checker,
    entry.context.metaContext.instantiate(equality.type),
  );
  const pattern=symm?rule.rhs:rule.lhs;
  const replacement=symm?rule.lhs:rule.rhs;

  if(rewriteExprSize(pattern)<=rewriteExprSize(replacement)){
    throw new Error(
      'PS_ELAB_TACTIC_SIMP_ORIENTATION: bounded simp only requires the selected '+
      'rewrite direction to strictly decrease structural expression size',
    );
  }

  for(let step=0;step<MAX_BOUNDED_SIMP_STEPS;step+=1){
    if(runtime.state.goals.length===0)return;
    const changed=rewriteV061Equality(
      runtime,
      equality,
      symm,
      {failIfNoOccurrence:false},
    );
    if(!changed){
      tryCloseV061CheapEqRfl(runtime);
      return;
    }
  }
  throw new Error(
    'PS_ELAB_TACTIC_SIMP_FUEL: bounded simp exceeded '+
    String(MAX_BOUNDED_SIMP_STEPS)+' rewrite steps',
  );
}
