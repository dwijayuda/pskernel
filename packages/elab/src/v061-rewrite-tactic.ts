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
  levelZero,
  mkAppN,
  nameEq,
  nameFromDotted,
  hasMVar,
  sort,
  type Expr,
} from 'lean-ts-kernel';
import type {
  ElaboratedCoreTerm,
  V061CoreElabContext,
} from './v061-context.js';
import type {V061TermElaborator} from './v061-tactic-elab.js';
import {abstractExactRewriteOccurrences} from './v061-rewrite-occurrence.js';
import {
  tryCompleteV061EqRfl,
} from './v061-rfl-tactic.js';
import {V061TacticRuntime} from './v061-tactic-runtime.js';

export interface EqualityView {
  readonly alpha:Expr;
  readonly lhs:Expr;
  readonly rhs:Expr;
}

export function equalityView(
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

export interface RewriteV061Options {
  readonly failIfNoOccurrence?:boolean;
}

export function elaborateV061RewriteProof(
  proofExpr:V061Expr,
  context:V061CoreElabContext,
  elaborate:V061TermElaborator,
):ElaboratedCoreTerm {
  const expected=context.metaContext.mkFresh(
    sort(levelZero),
    context.localContext,
  );
  return elaborate(proofExpr,context,expected);
}

function trySpecializeRewritePattern(
  value:Expr,
  pattern:Expr,
  context:V061CoreElabContext,
):boolean {
  if(context.metaContext.unify(
    pattern,
    value,
    context.localContext,
  ))return true;

  switch(value.kind){
    case 'app':
      return trySpecializeRewritePattern(value.fn,pattern,context)
        ||trySpecializeRewritePattern(value.arg,pattern,context);
    case 'lam':
    case 'forall':
      return trySpecializeRewritePattern(value.type,pattern,context)
        ||trySpecializeRewritePattern(value.body,pattern,context);
    case 'let':
      return trySpecializeRewritePattern(value.type,pattern,context)
        ||trySpecializeRewritePattern(value.value,pattern,context)
        ||trySpecializeRewritePattern(value.body,pattern,context);
    case 'mdata':
    case 'proj':
      return trySpecializeRewritePattern(value.expr,pattern,context);
    default:
      return false;
  }
}

export function rewriteV061Equality(
  runtime:V061TacticRuntime,
  equality:ElaboratedCoreTerm,
  symm:boolean,
  options:RewriteV061Options={},
):boolean {
  const goal=getMainGoal(runtime.state);
  const entry=runtime.entry(goal);
  const checker=new TypeChecker(
    entry.context.environment,
    entry.context.localContext.clone(),
  );
  let rule=equalityView(
    checker,
    entry.context.metaContext.instantiate(equality.type),
  );
  let pattern=symm?rule.rhs:rule.lhs;
  const target=runtime.expected(goal);
  let abstraction=abstractExactRewriteOccurrences(target,pattern);

  if(!abstraction.found){
    if(trySpecializeRewritePattern(target,pattern,entry.context)){
      rule=equalityView(
        checker,
        entry.context.metaContext.instantiate(equality.type),
      );
      pattern=symm?rule.rhs:rule.lhs;
      abstraction=abstractExactRewriteOccurrences(target,pattern);
    }
  }
  if(!abstraction.found){
    if(options.failIfNoOccurrence===false)return false;
    throw new Error(
      'PS_ELAB_TACTIC_RW_OCCURRENCE: rewrite pattern does not occur structurally in the goal',
    );
  }

  const replacement=symm?rule.lhs:rule.rhs;
  const proofTerm=entry.context.metaContext.instantiate(equality.term);
  const proofType=entry.context.metaContext.instantiate(equality.type);
  if(hasMVar(proofTerm)||hasMVar(proofType)){
    throw new Error(
      'PS_ELAB_TACTIC_RW_UNSOLVED: rewrite rule remains underconstrained after matching',
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
          proofTerm,
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
  if(tryCompleteV061EqRfl(runtime,child)){
    runtime.state=replaceMainGoal(runtime.state,[]);
    return true;
  }
  runtime.state=replaceMainGoal(runtime.state,[child]);
  return true;
}

export function rewriteV061Tactic(
  runtime:V061TacticRuntime,
  proofExpr:V061Expr,
  symm:boolean,
  elaborate:V061TermElaborator,
):void {
  const goal=getMainGoal(runtime.state);
  const entry=runtime.entry(goal);
  const equality=elaborateV061RewriteProof(
    proofExpr,
    entry.context,
    elaborate,
  );
  rewriteV061Equality(runtime,equality,symm);
}
