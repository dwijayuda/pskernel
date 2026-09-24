import {
  exact,
  type TacticGoal,
} from '@proofscript/tactic';
import {ExprMetaContext} from '@proofscript/meta';
import {
  TypeChecker,
  hasMVar,
  instantiate1,
  mkAppN,
  type Expr,
} from 'lean-ts-kernel';
import type {
  ElaboratedCoreTerm,
  V061CoreElabContext,
} from './v061-context.js';
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
      runtime.expected(goal),
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
      runtime.expected(goal),
      {term,type:checker.check(term)},
    );
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

  for(let index=goal.locals.length-1;index>=0;index-=1){
    const local=goal.locals[index]!;
    if(local.value===undefined)continue;
    const candidate=tryLocalCandidate(runtime,goal,local.value);
    if(candidate===undefined)continue;
    closeWithCandidate(runtime,candidate);
    return;
  }

  const entry=runtime.entry(goal);
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

    const candidate=tryEnvironmentCandidate(
      runtime,
      goal,
      info.name,
    );
    if(candidate===undefined)continue;
    closeWithCandidate(runtime,candidate);
    return;
  }

  throw new Error(
    'PS_ELAB_TACTIC_EXACT_SEARCH: bounded exact? found no '+
    'zero-subgoal local/environment candidate',
  );
}
