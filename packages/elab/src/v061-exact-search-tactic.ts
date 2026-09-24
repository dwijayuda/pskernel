import {
  exact,
  type TacticGoal,
} from '@proofscript/tactic';
import {ExprMetaContext} from '@proofscript/meta';
import {
  TypeChecker,
  appView,
  hasMVar,
  instantiate1,
  mkAppN,
  nameEq,
  nameFromDotted,
  type Expr,
} from 'lean-ts-kernel';
import type {
  ElaboratedCoreTerm,
  V061CoreElabContext,
} from './v061-context.js';
import {elaborateApplication} from './application.js';
import {elaborateV061Constant} from './v061-constant-elab.js';
import {V061TacticRuntime} from './v061-tactic-runtime.js';

const MAX_BOUNDED_EXACT_SEARCH_CANDIDATES=4096;
const MAX_BOUNDED_EXACT_SEARCH_ARGUMENTS=64;

function closeWithCandidate(
  runtime:V061TacticRuntime,
  term:Expr,
):void {
  runtime.state=exact(
    runtime.state,
    term,
    runtime.kernel,
  );
}

function isolatedContext(
  context:V061CoreElabContext,
):V061CoreElabContext {
  return {
    ...context,
    metaContext:new ExprMetaContext(context.environment),
  };
}

function tryZeroSubgoalApplication(
  context:V061CoreElabContext,
  target:Expr,
  candidate:ElaboratedCoreTerm,
):Expr|undefined {
  const meta=context.metaContext;
  const checker=new TypeChecker(
    context.environment,
    context.localContext.clone(),
  );
  const args:Expr[]=[];
  const placeholders:Expr[]=[];
  let currentType=meta.instantiate(candidate.type);

  for(let index=0;index<=MAX_BOUNDED_EXACT_SEARCH_ARGUMENTS;index+=1){
    if(meta.unify(currentType,target,context.localContext)){
      if(placeholders.some((placeholder)=>!meta.isAssigned(placeholder))){
        return undefined;
      }
      try{
        meta.validateGroundAssignments();
      }catch{
        return undefined;
      }
      const term=meta.instantiate(mkAppN(candidate.term,args));
      if(
        hasMVar(term)
        ||meta.levels.hasUnresolvedExpr(term)
      )return undefined;
      try{
        const type=checker.check(term);
        return checker.isDefEq(type,target)?term:undefined;
      }catch{
        return undefined;
      }
    }

    if(index===MAX_BOUNDED_EXACT_SEARCH_ARGUMENTS)return undefined;
    const reduced=checker.whnf(meta.instantiate(currentType));
    if(reduced.kind!=='forall')return undefined;
    if(
      reduced.binderInfo==='strictImplicit'
      ||reduced.binderInfo==='instImplicit'
    )return undefined;

    const placeholder=meta.mkFresh(
      meta.instantiate(reduced.type),
      context.localContext,
      'natural',
    );
    placeholders.push(placeholder);
    args.push(placeholder);
    currentType=instantiate1(reduced.body,placeholder);
  }
  return undefined;
}

function tryLocalCandidate(
  runtime:V061TacticRuntime,
  goal:TacticGoal<Expr>,
  term:Expr,
  target:Expr,
):Expr|undefined {
  const parent=runtime.entry(goal).context;
  const context=isolatedContext(parent);
  const checker=new TypeChecker(
    context.environment,
    context.localContext.clone(),
  );
  try{
    return tryZeroSubgoalApplication(
      context,
      target,
      {term,type:checker.check(term)},
    );
  }catch{
    return undefined;
  }
}

function tryEnvironmentCandidate(
  runtime:V061TacticRuntime,
  goal:TacticGoal<Expr>,
  name:import('lean-ts-kernel').Name,
  target:Expr,
):Expr|undefined {
  const parent=runtime.entry(goal).context;
  const context=isolatedContext(parent);
  const checker=new TypeChecker(
    context.environment,
    context.localContext.clone(),
  );
  try{
    const term=elaborateV061Constant(name,context);
    return tryZeroSubgoalApplication(
      context,
      target,
      {term,type:checker.check(term)},
    );
  }catch{
    return undefined;
  }
}

function symmetricEqualityTarget(
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

function wrapSymmetricEqualityProof(
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

export function exactSearchV061Tactic(
  runtime:V061TacticRuntime,
):void {
  const goal=runtime.state.goals[0];
  if(goal===undefined){
    throw new Error('PS_ELAB_TACTIC_EXACT_SEARCH: no goal');
  }

  const target=runtime.expected(goal);
  const entry=runtime.entry(goal);
  const symmetricTarget=symmetricEqualityTarget(entry.context,target);

  for(let index=goal.locals.length-1;index>=0;index-=1){
    const local=goal.locals[index]!;
    if(local.value===undefined)continue;

    const direct=tryLocalCandidate(
      runtime,
      goal,
      local.value,
      target,
    );
    if(direct!==undefined){
      closeWithCandidate(runtime,direct);
      return;
    }

    if(symmetricTarget===undefined)continue;
    const symmetric=tryLocalCandidate(
      runtime,
      goal,
      local.value,
      symmetricTarget,
    );
    if(symmetric===undefined)continue;
    const wrapped=wrapSymmetricEqualityProof(
      runtime,
      goal,
      symmetric,
    );
    if(wrapped===undefined)continue;
    closeWithCandidate(runtime,wrapped);
    return;
  }

  const constants=entry.context.environment.entries();
  let visited=0;

  for(let index=constants.length-1;index>=0;index-=1){
    const info=constants[index]!;
    visited+=1;
    if(visited>MAX_BOUNDED_EXACT_SEARCH_CANDIDATES){
      throw new Error(
        'PS_ELAB_TACTIC_EXACT_SEARCH_FUEL: bounded exact? exceeded '+
        String(MAX_BOUNDED_EXACT_SEARCH_CANDIDATES)+
        ' environment candidates',
      );
    }

    const direct=tryEnvironmentCandidate(
      runtime,
      goal,
      info.name,
      target,
    );
    if(direct!==undefined){
      closeWithCandidate(runtime,direct);
      return;
    }

    if(symmetricTarget===undefined)continue;
    const symmetric=tryEnvironmentCandidate(
      runtime,
      goal,
      info.name,
      symmetricTarget,
    );
    if(symmetric===undefined)continue;
    const wrapped=wrapSymmetricEqualityProof(
      runtime,
      goal,
      symmetric,
    );
    if(wrapped===undefined)continue;
    closeWithCandidate(runtime,wrapped);
    return;
  }

  throw new Error(
    'PS_ELAB_TACTIC_EXACT_SEARCH: bounded exact? found no '+
    'zero-subgoal local/environment candidate, including Eq symmetry',
  );
}
