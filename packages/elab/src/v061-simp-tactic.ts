import {getMainGoal} from '@proofscript/tactic';
import type {V061Tactic} from '@proofscript/syntax';
import {TypeChecker} from 'lean-ts-kernel';
import {
  exactRewritePatternsOverlap,
  rewriteExprSize,
} from './v061-rewrite-occurrence.js';
import {
  equalityView,
  rewriteV061Equality,
  tryCloseV061CheapEqRfl,
} from './v061-rewrite-tactic.js';
import type {V061TermElaborator} from './v061-tactic-elab.js';
import {V061TacticRuntime} from './v061-tactic-runtime.js';

const MAX_BOUNDED_SIMP_STEPS=64;
type SimpRule=Extract<V061Tactic,{kind:'simp'}>['rules'][number];

interface ElaboratedSimpRule {
  readonly equality:ReturnType<V061TermElaborator>;
  readonly symm:boolean;
  readonly pattern:import('lean-ts-kernel').Expr;
  readonly replacement:import('lean-ts-kernel').Expr;
}

function elaborateRules(
  runtime:V061TacticRuntime,
  rules:readonly SimpRule[],
  elaborate:V061TermElaborator,
):readonly ElaboratedSimpRule[] {
  const goal=getMainGoal(runtime.state);
  const entry=runtime.entry(goal);
  const checker=new TypeChecker(
    entry.context.environment,
    entry.context.localContext.clone(),
  );
  const result=rules.map((source)=>{
    const equality=elaborate(source.proof,entry.context);
    const rule=equalityView(
      checker,
      entry.context.metaContext.instantiate(equality.type),
    );
    const pattern=source.symm?rule.rhs:rule.lhs;
    const replacement=source.symm?rule.lhs:rule.rhs;
    if(rewriteExprSize(pattern)<=rewriteExprSize(replacement)){
      throw new Error(
        'PS_ELAB_TACTIC_SIMP_ORIENTATION: bounded simp only requires every '+
        'selected rewrite direction to strictly decrease structural expression size',
      );
    }
    return {
      equality,
      symm:source.symm,
      pattern,
      replacement,
    };
  });

  for(let left=0;left<result.length;left+=1){
    for(let right=left+1;right<result.length;right+=1){
      if(
        exactRewritePatternsOverlap(
          result[left]!.pattern,
          result[right]!.pattern,
        )
      ){
        throw new Error(
          'PS_ELAB_TACTIC_SIMP_OVERLAP: bounded multi-rule simp only requires '+
          'pairwise non-overlapping rewrite patterns until Lean priority/index '+
          'selection is modeled',
        );
      }
    }
  }
  return result;
}

export function simpOnlyV061Tactic(
  runtime:V061TacticRuntime,
  rules:readonly SimpRule[],
  elaborate:V061TermElaborator,
):void {
  const elaborated=elaborateRules(runtime,rules,elaborate);
  let steps=0;

  while(steps<MAX_BOUNDED_SIMP_STEPS){
    if(runtime.state.goals.length===0)return;
    let changedInPass=false;
    for(const rule of elaborated){
      if(runtime.state.goals.length===0)return;
      const changed=rewriteV061Equality(
        runtime,
        rule.equality,
        rule.symm,
        {failIfNoOccurrence:false},
      );
      if(changed){
        changedInPass=true;
        steps+=1;
        if(steps>=MAX_BOUNDED_SIMP_STEPS)break;
      }
    }
    if(!changedInPass){
      tryCloseV061CheapEqRfl(runtime);
      return;
    }
  }

  throw new Error(
    'PS_ELAB_TACTIC_SIMP_FUEL: bounded simp exceeded '+
    String(MAX_BOUNDED_SIMP_STEPS)+' rewrite steps',
  );
}
