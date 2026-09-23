import {
  getMainGoal,
  replaceMainGoal,
} from '@proofscript/tactic';
import type {V061Expr} from '@proofscript/syntax';
import {
  TypeChecker,
  appView,
  constant,
  instantiate1,
  lam,
  mkAppN,
  nameEq,
  nameFromDotted,
  type Expr,
} from 'lean-ts-kernel';
import type {V061TermElaborator} from './v061-tactic-elab.js';
import {abstractExactRewriteOccurrences} from './v061-rewrite-occurrence.js';
import {V061TacticRuntime} from './v061-tactic-runtime.js';

interface EqualityView {
  readonly alpha:Expr;
  readonly lhs:Expr;
  readonly rhs:Expr;
}

function equalityView(
  checker:TypeChecker,
  proofType:Expr,
):EqualityView {
  const view=appView(checker.whnf(proofType));
  if(
    view.fn.kind!=='const'
    ||!nameEq(view.fn.name,nameFromDotted('Eq'))
    ||view.args.length!==3
  ){
    throw new Error(
      'PS_ELAB_TACTIC_RW_EQUALITY: rewrite rule must prove Eq lhs rhs',
    );
  }
  return {
    alpha:view.args[0]!,
    lhs:view.args[1]!,
    rhs:view.args[2]!,
  };
}

function transportName(symm:boolean):ReturnType<typeof nameFromDotted> {
  return nameFromDotted(symm?'Eq.ndrec':'Eq.ndrec_symm');
}

export function rewriteV061Tactic(
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
  const target=runtime.expected(goal);
  const abstraction=abstractExactRewriteOccurrences(target,pattern);
  if(!abstraction.found){
    throw new Error(
      'PS_ELAB_TACTIC_RW_OCCURRENCE: rewrite pattern does not occur structurally in the goal',
    );
  }

  const motive=lam(
    nameFromDotted('_rw'),
    rule.alpha,
    abstraction.body,
  );
  checker.check(motive);
  const rewrittenTarget=instantiate1(abstraction.body,replacement);
  checker.ensureSort(
    checker.check(rewrittenTarget),
    rewrittenTarget,
  );

  const child=runtime.createGoal(
    entry.context,
    rewrittenTarget,
    (proof)=>{
      const transport=transportName(symm);
      const info=entry.context.environment.find(transport);
      if(info===undefined||info.levelParams.length!==2){
        throw new Error(
          'PS_ELAB_TACTIC_RW_TRANSPORT: expected Lean Prelude '+
          (symm?'Eq.ndrec':'Eq.ndrec_symm'),
        );
      }
      const resultLevel=checker.ensureSort(
        checker.check(target),
        target,
      ).level;
      const alphaLevel=checker.ensureSort(
        checker.check(rule.alpha),
        rule.alpha,
      ).level;
      const term=mkAppN(
        constant(transport,[resultLevel,alphaLevel]),
        [
          rule.alpha,
          replacement,
          motive,
          proof.term,
          pattern,
          equality.term,
        ],
      );
      const type=checker.check(term);
      if(!checker.isDefEq(type,target)){
        throw new Error(
          'PS_ELAB_TACTIC_RW_RESULT: equality transport does not reconstruct the parent goal',
        );
      }
      runtime.completeGoal(goal,{term,type});
    },
  );
  runtime.state=replaceMainGoal(runtime.state,[child]);
}
