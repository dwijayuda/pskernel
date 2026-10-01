import {ExprMetaContext} from '@proofscript/meta';
import type {TacticGoal} from '@proofscript/tactic';
import {
  TypeChecker,
  appView,
  hasMVar,
  mkAppN,
  nameEq,
  nameFromDotted,
  type Expr,
} from 'lean-ts-kernel';
import {elaborateApplication} from './application.js';
import {elaborateV061Constant} from './v061-constant-elab.js';
import type {V061CoreElabContext} from './v061-context.js';
import {V061TacticRuntime} from './v061-tactic-runtime.js';

function isolatedContext(
  context:V061CoreElabContext,
):V061CoreElabContext {
  return {
    ...context,
    metaContext:new ExprMetaContext(context.environment),
  };
}

export function symmetricEqualityTarget(
  context:V061CoreElabContext,
  target:Expr,
):Expr|undefined {
  const checker=new TypeChecker(
    context.environment,
    context.localContext.clone(),
  );
  const view=appView(checker.whnf(target));
  if(
    view.fn.kind!=='const'
    ||!nameEq(view.fn.name,nameFromDotted('Eq'))
    ||view.args.length!==3
  )return undefined;
  return mkAppN(
    view.fn,
    [view.args[0]!,view.args[2]!,view.args[1]!],
  );
}

export function wrapSymmetricEqualityProof(
  runtime:V061TacticRuntime,
  goal:TacticGoal<Expr>,
  proof:Expr,
):Expr|undefined {
  const parent=runtime.entry(goal).context;
  const context=isolatedContext(parent);
  const checker=new TypeChecker(
    context.environment,
    context.localContext.clone(),
  );
  try{
    const applied=elaborateApplication({
      environment:context.environment,
      metaContext:context.metaContext,
      fn:elaborateV061Constant(
        nameFromDotted('Eq.symm'),
        context,
      ),
      args:[proof],
      expectedType:runtime.expected(goal),
      localContext:context.localContext,
      globalInstances:context.globalInstances,
      classNames:context.classes,
    });
    if(applied.pendingInstances.length!==0)return undefined;
    context.metaContext.validateGroundAssignments();
    const term=context.metaContext.instantiate(applied.term);
    const type=context.metaContext.instantiate(applied.type);
    if(
      hasMVar(term)
      ||hasMVar(type)
      ||context.metaContext.levels.hasUnresolvedExpr(term)
      ||context.metaContext.levels.hasUnresolvedExpr(type)
    )return undefined;
    const checkedType=checker.check(term);
    return checker.isDefEq(
      checkedType,
      runtime.expected(goal),
    )?term:undefined;
  }catch{
    return undefined;
  }
}
